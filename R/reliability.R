#' Test whether a metric is too noisy to trust for ranking (H2)
#'
#' Implements a stabilization-style split-half reliability test, in the
#' spirit of Russell Carleton's sabermetric stabilization work. Each
#' player's repeated observations (e.g. plate appearances, individual games,
#' individual shots) are randomly split into two halves many times. Within
#' each split, the metric is averaged per player in each half, and the two
#' halves are correlated across players. The average of that correlation
#' across many random splits is the split-half reliability estimate; the
#' Spearman-Brown formula projects what the reliability would be for the
#' FULL sample (both halves combined) rather than a half-sized sample.
#'
#' A metric with high reliability captures real, repeatable skill. A metric
#' with low reliability is dominated by random variation and cannot be
#' trusted to rank players even if the underlying concept is sound.
#'
#' @param data A data frame in LONG format: one row per player per
#'   observation unit (e.g. one row per plate appearance, one row per game,
#'   one row per possession).
#' @param id_col Character. Column name identifying the player.
#' @param value_col Character. Column name of the numeric outcome being
#'   tested for reliability (e.g. 1/0 for a hit, points scored in a game).
#' @param n_splits Integer. Number of random splits to average over.
#'   Default 1000.
#' @param min_obs Integer. Minimum observations a player needs to be
#'   included (players with very few observations will pull the estimate
#'   down for the wrong reason -- sample size, not true unreliability).
#'   Default 10.
#'
#' @return A list with:
#'   \item{split_half_r}{mean split-half correlation across n_splits}
#'   \item{spearman_brown_r}{Spearman-Brown-adjusted full-sample reliability}
#'   \item{all_splits}{numeric vector of the correlation from every split,
#'     for plotting a distribution or computing a confidence interval}
#'   \item{n_players}{number of players included after the min_obs filter}
#'
#' @examples
#' set.seed(1)
#' # simulate 150 players with a real-but-noisy skill
#' n_players <- 150
#' true_skill <- rnorm(n_players)
#' obs <- do.call(rbind, lapply(seq_len(n_players), function(i) {
#'   n_obs <- sample(20:40, 1)
#'   data.frame(player = i, value = true_skill[i] + rnorm(n_obs, sd = 2))
#' }))
#' result <- test_reliability(obs, "player", "value", n_splits = 200)
#' result$spearman_brown_r
#'
#' @export
test_reliability <- function(data, id_col, value_col, n_splits = 1000, min_obs = 10) {
  stopifnot(is.data.frame(data))
  if (!all(c(id_col, value_col) %in% names(data))) {
    stop("id_col and value_col must both be columns in data")
  }

  obs_counts <- table(data[[id_col]])
  eligible_ids <- names(obs_counts)[obs_counts >= min_obs]
  data <- data[data[[id_col]] %in% eligible_ids, ]

  if (length(eligible_ids) < 5) {
    stop("Fewer than 5 players meet min_obs -- lower min_obs or check your data")
  }

  split_by_player <- split(data[[value_col]], data[[id_col]])

  one_split <- function() {
    half_means <- lapply(split_by_player, function(vals) {
      n <- length(vals)
      idx <- sample.int(n)
      half1 <- vals[idx[seq_len(floor(n / 2))]]
      half2 <- vals[idx[(floor(n / 2) + 1):n]]
      c(mean(half1), mean(half2))
    })
    m <- do.call(rbind, half_means)
    stats::cor(m[, 1], m[, 2], use = "complete.obs")
  }

  all_splits <- vapply(seq_len(n_splits), function(i) one_split(), numeric(1))
  split_half_r <- mean(all_splits, na.rm = TRUE)
  spearman_brown_r <- (2 * split_half_r) / (1 + split_half_r)

  list(
    split_half_r = split_half_r,
    spearman_brown_r = spearman_brown_r,
    all_splits = all_splits,
    n_players = length(eligible_ids)
  )
}
