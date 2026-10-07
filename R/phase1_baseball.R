# Phase 1 — Baseball pilot
# Runs H1 (redundancy), H2 (reliability)
# and H3 (discriminability) on offense and defense.
#
# How to use: put this file in the
# sportmetrics repo as analysis/phase1_baseball.R,
# open the repo in RStudio, and run it section by section (Ctrl/Cmd + Enter).
# Data is cached in data/ as CSV. Delete a CSV to download it again.
#

devtools::load_all(".")          # the package functions: test_redundancy() etc.
library(baseballr)
library(Lahman)

dir.create("data/gamelogs_2024", recursive = TRUE, showWarnings = FALSE)
SEASONS <- 2022:2025

# Read a cached CSV, or make it with `make` and save it.
cached <- function(path, make) {
  if (file.exists(path)) return(read.csv(path))
  x <- as.data.frame(make())
  write.csv(x, path, row.names = FALSE)
  x
}


# ---- 1. Batter seasons (H1, H3 offense) -------------------------------------
# One call PER SEASON. Two traps in the task sheet's single call
# fg_batter_leaders(startseason = 2022, endseason = 2025, qual = "300"):
#   (a) baseballr 2.0.0 sends the two seasons to FanGraphs in the wrong order,
#       so a multi-season call returns no rows;
#   (b) even when fixed, the default ind = "0" adds the 4 seasons together
#       (one row per player), not one row per player-season.
bat <- cached("data/batters_2022_2025.csv", function() {
  rows <- lapply(SEASONS, function(y) {
    b <- fg_batter_leaders(startseason = y, endseason = y, qual = "300")
    b[, c("playerid", "PlayerName", "Season", "PA", "AVG", "HR", "RBI",
          "wOBA", "wRC_plus")]
  })
  do.call(rbind, rows)
})
table(bat$Season)                 # about 280 qualified hitters per season


# ---- 2. Fielder seasons + Fielding% (H1, H3 defense) ------------------------
fld <- cached("data/fielders_2022_2025.csv", function() {
  rows <- lapply(SEASONS, function(y) {
    f <- fg_fielder_leaders(startseason = y, endseason = y, qual = "800")
    f[, c("playerid", "PlayerName", "Season", "Pos", "Inn", "DRS")]
  })
  do.call(rbind, rows)
})

# The ID bridge: FanGraphs playerid -> Chadwick -> bbrefID -> Lahman playerID
ids <- cached("data/chadwick_fg_bbref.csv", function() {
  ch <- chadwick_player_lu()                              # ~50 s, big download
  ch <- ch[!is.na(ch$key_fangraphs) &
             ch$key_bbref != "", c("key_fangraphs", "key_bbref")]
  ch
})
fld <- merge(fld, ids, by.x = "playerid", by.y = "key_fangraphs")
fld <- merge(fld, People[, c("playerID", "bbrefID")],
             by.x = "key_bbref", by.y = "bbrefID")

# Lahman Fielding: one row per player, year, team stint and position.
# Add them up per player-year.
lf <- Fielding[Fielding$yearID %in% SEASONS, ]
lf <- aggregate(cbind(PO, A, E) ~ playerID + yearID, data = lf, FUN = sum)
lf$fielding_pct <- (lf$PO + lf$A) / (lf$PO + lf$A + lf$E)
head(lf)
fld <- merge(fld, lf, by.x = c("playerID", "Season"),
             by.y = c("playerID", "yearID"))
nrow(fld)                          # fielder-seasons that survived the join
anyDuplicated(fld[, c("playerid", "Season")])   # 0 = one row per player-season


# ---- 3. Next-season pairs (H1 outcome) ---------------------------------------
# Same player, season t and season t + 1.
# Only players qualified in BOTH seasons stay.
next_season <- function(df, col) {
  nxt <- df[, c("playerid", "Season", col)]
  names(nxt)[3] <- paste0("next_", col)
  nxt$Season <- nxt$Season - 1      # the t+1 value, lined up with season t
  merge(df, nxt, by = c("playerid", "Season"))
}
bat_pairs <- next_season(bat, "wRC_plus")
fld_pairs <- next_season(fld, "DRS")
fld_pairs <- next_season(fld_pairs, "fielding_pct")
c(offense_pairs = nrow(bat_pairs), defense_pairs = nrow(fld_pairs))

head(fld_pairs)


# ---- 4. Game logs 2024 (H2 offense) ---------
# ~286 calls. Each player is cached as its own CSV,
# so a crash or a stop loses nothing:
# run the loop again and it continues where it stopped.
ids_2024 <- unique(bat$playerid[bat$Season == 2024])
for (id in ids_2024) {
  f <- file.path("data/gamelogs_2024", paste0(id, ".csv"))
  if (file.exists(f)) next
  gl <- tryCatch(fg_batter_game_logs(playerid = id, year = 2024), error = function(e) NULL)
  if (!is.null(gl) && nrow(gl) > 0) write.csv(gl[, c("playerid", "Date", "PA", "wOBA")], f, row.names = FALSE)
  Sys.sleep(0.5)                   # be polite to FanGraphs
}
games <- do.call(rbind, lapply(list.files("data/gamelogs_2024", full.names = TRUE), read.csv))
games <- games[games$PA > 0 & !is.na(games$wOBA), ]   # drop games with no plate appearance
c(players = length(unique(games$playerid)), games = nrow(games))


# ---- 5. The tests ------------------------------------------------------------
set.seed(2024)                     # the reliability test shuffles: make it repeatable

# H1 offense: does wRC+ (season t) predict next-season wRC+ beyond AVG/HR/RBI?
h1_off <- test_redundancy(bat_pairs, "next_wRC_plus", c("AVG", "HR", "RBI"), "wRC_plus")
# H1 defense: does DRS predict next-season DRS beyond Fielding%?
h1_def <- test_redundancy(fld_pairs, "next_DRS", "fielding_pct", "DRS")

# H2 offense: split-half reliability of wOBA, one value per game, 2024
h2_off <- test_reliability(games, "playerid", "wOBA", n_splits = 500)
# H2 defense: DRS has no game-level data, so use year-over-year correlation instead
h2_def_drs <- cor(fld_pairs$DRS, fld_pairs$next_DRS)
h2_def_fpct <- cor(fld_pairs$fielding_pct, fld_pairs$next_fielding_pct)

# H3: spread, with the H2 reliability for the true-talent part
bat24 <- bat[bat$Season == 2024, ]
h3_off <- test_discriminability(bat24, "wRC_plus", reliability = h2_off$spearman_brown_r)
h3_def <- test_discriminability(fld, "DRS", reliability = max(h2_def_drs, 0))
h3_fpct <- test_discriminability(fld, "fielding_pct", reliability = max(h2_def_fpct, 0))


# ---- 6. Summary ---------------------------------------------------------------
results <- data.frame(
  test   = c("H1 offense", "H1 defense", "H2 offense", "H2 defense (DRS)", "H2 defense (Fld%)",
             "H3 offense", "H3 defense (DRS)", "H3 defense (Fld%)"),
  metric = c("wRC+ vs AVG/HR/RBI", "DRS vs Fielding%", "wOBA (per game, 2024)", "DRS year-to-year",
             "Fielding% year-to-year", "wRC+ (2024)", "DRS", "Fielding%"),
  result = c(
    sprintf("R2 %.2f -> %.2f, delta_r2 = %.3f, p = %.3g (n = %d)", h1_off$baseline_r2, h1_off$full_r2, h1_off$delta_r2, h1_off$p_value, nrow(bat_pairs)),
    sprintf("R2 %.2f -> %.2f, delta_r2 = %.3f, p = %.3g (n = %d)", h1_def$baseline_r2, h1_def$full_r2, h1_def$delta_r2, h1_def$p_value, nrow(fld_pairs)),
    sprintf("spearman_brown_r = %.2f (%d players)", h2_off$spearman_brown_r, h2_off$n_players),
    sprintf("r = %.2f", h2_def_drs),
    sprintf("r = %.2f", h2_def_fpct),
    sprintf("sd = %.1f, true_sd = %.1f, cv = %.2f", h3_off$sd, h3_off$true_sd, h3_off$cv),
    sprintf("mean = %.1f, sd = %.1f, true_sd = %.1f, cv = %.2f", h3_def$mean, h3_def$sd, h3_def$true_sd, h3_def$cv),
    sprintf("sd = %.4f, true_sd = %.4f, cv = %.3f", h3_fpct$sd, h3_fpct$true_sd, h3_fpct$cv)
  )
)
print(results, right = FALSE)
write.csv(results, "data/phase1_results.csv", row.names = FALSE)
