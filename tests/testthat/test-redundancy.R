test_that("test_redundancy detects a genuinely redundant metric", {
  set.seed(1)
  n <- 300
  traditional <- rnorm(n)
  advanced <- 0.95 * traditional + rnorm(n, sd = 0.1) # near-perfect proxy
  outcome <- 0.6 * traditional + rnorm(n)
  df <- data.frame(traditional, advanced, outcome)

  result <- test_redundancy(df, "outcome", "traditional", "advanced")

  expect_lt(result$delta_r2, 0.02) # should add almost nothing
  expect_gt(result$p_value, 0.05)  # improvement not significant
})

test_that("test_redundancy detects a genuinely additive metric", {
  set.seed(2)
  n <- 300
  traditional <- rnorm(n)
  advanced <- rnorm(n) # independent of traditional
  outcome <- 0.5 * traditional + 0.5 * advanced + rnorm(n, sd = 0.3)
  df <- data.frame(traditional, advanced, outcome)

  result <- test_redundancy(df, "outcome", "traditional", "advanced")

  expect_gt(result$delta_r2, 0.05)
  expect_lt(result$p_value, 0.05)
})

test_that("test_redundancy errors on missing columns", {
  df <- data.frame(a = 1:5, b = 1:5)
  expect_error(test_redundancy(df, "c", "a", "b"), "not found")
})
