#' Test whether a metric has enough spread to discriminate between players (H3)
#'
#' Even a metric that is neither redundant (H1) nor unreliable (H2) can fail
#' to be useful if it barely varies across players -- everyone looks about
#' the same, so ranking is meaningless. This function reports basic spread
#' statistics and, optionally, decomposes observed variance into an
#' estimated "true" (signal) component and a "noise" component when a
#' reliability estimate is supplied (e.g. from \code{test_reliability}).
#'
#' @param data A data frame with one row per player (or player-season).
#' @param metric Character. Column name of the metric to test.
#' @param reliability Optional numeric between 0 and 1. If supplied
#'   (e.g. the Spearman-Brown reliability from \code{test_reliability}),
#'   the function also reports the estimated TRUE variance across players
#'   (signal) versus the variance attributable to measurement noise, using
#'   true_var = reliability * observed_var.
#'
#' @return A list with:
#'   \item{mean}{mean of the metric}
#'   \item{sd}{standard deviation of the metric}
#'   \item{cv}{coefficient of variation (sd / mean) -- unitless, comparable
#'     across metrics measured on different scales}
#'   \item{range}{min and max}
#'   \item{true_sd}{(if reliability supplied) estimated signal-only standard
#'     deviation -- the spread that reflects real talent differences}
#'   \item{noise_sd}{(if reliability supplied) the spread attributable to
#'     measurement noise}
#'
#' @examples
#' set.seed(1)
#' df <- data.frame(metric = rnorm(200, mean = 50, sd = 1)) # low real spread
#' test_discriminability(df, "metric")
#'
#' @export
test_discriminability <- function(data, metric, reliability = NULL) {
  stopifnot(is.data.frame(data))
  if (!metric %in% names(data)) stop("metric column not found in data")

  x <- data[[metric]]
  x <- x[!is.na(x)]

  result <- list(
    mean = mean(x),
    sd = stats::sd(x),
    cv = stats::sd(x) / mean(x),
    range = range(x)
  )

  if (!is.null(reliability)) {
    if (reliability < 0 || reliability > 1) {
      stop("reliability must be between 0 and 1")
    }
    observed_var <- stats::var(x)
    true_var <- reliability * observed_var
    result$true_sd <- sqrt(true_var)
    result$noise_sd <- sqrt(observed_var - true_var)
  }

  result
}
