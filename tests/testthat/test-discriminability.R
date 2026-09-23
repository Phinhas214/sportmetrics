test_that("test_discriminability flags low spread", {
  set.seed(1)
  df <- data.frame(metric = rnorm(200, mean = 50, sd = 0.5))
  result <- test_discriminability(df, "metric")
  expect_lt(result$cv, 0.05)
})

test_that("test_discriminability flags high spread", {
  set.seed(1)
  df <- data.frame(metric = rnorm(200, mean = 50, sd = 15))
  result <- test_discriminability(df, "metric")
  expect_gt(result$cv, 0.2)
})

test_that("test_discriminability decomposes signal vs noise when reliability given", {
  df <- data.frame(metric = rnorm(200, mean = 10, sd = 2))
  result <- test_discriminability(df, "metric", reliability = 0.7)
  expect_true(!is.null(result$true_sd))
  expect_lt(result$true_sd, result$sd)
})

test_that("test_discriminability errors on missing column", {
  df <- data.frame(a = 1:5)
  expect_error(test_discriminability(df, "b"), "not found")
})
