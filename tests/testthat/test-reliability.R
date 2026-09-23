test_that("test_reliability recovers high reliability for a real, low-noise skill", {
  set.seed(1)
  n_players <- 100
  true_skill <- rnorm(n_players, sd = 3)
  obs <- do.call(rbind, lapply(seq_len(n_players), function(i) {
    data.frame(player = i, value = true_skill[i] + rnorm(30, sd = 0.5))
  }))

  result <- test_reliability(obs, "player", "value", n_splits = 300)

  expect_gt(result$spearman_brown_r, 0.8)
})

test_that("test_reliability recovers low reliability for a mostly-noise stat", {
  set.seed(2)
  n_players <- 100
  obs <- do.call(rbind, lapply(seq_len(n_players), function(i) {
    data.frame(player = i, value = rnorm(30, sd = 3)) # no real player skill at all
  }))

  result <- test_reliability(obs, "player", "value", n_splits = 300)

  expect_lt(abs(result$spearman_brown_r), 0.3)
})

test_that("test_reliability errors with too few eligible players", {
  df <- data.frame(player = rep(1:2, each = 20), value = rnorm(40))
  expect_error(test_reliability(df, "player", "value"), "Fewer than 5")
})
