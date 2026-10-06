#' Test whether an advanced metric is redundant with traditional stats (H1)
#'
#' Fits two regressions predicting an outcome: a baseline model using only
#' traditional stats, and a full model that adds one advanced metric. If the
#' advanced metric is genuinely adding information, R-squared should rise
#' more than a trivial amount, and the improvement should be statistically
#' significant. If it barely moves, the advanced metric is largely a
#' re-expression of information already contained in the traditional stats.
#'
#' Ideally \code{outcome} is measured in a LATER period than the predictors
#' (e.g. next season's wins, or a held-out set of games), so this tests
#' predictive value rather than concurrent correlation. Concurrent testing
#' still works but will tend to overstate redundancy for any metric that is
#' partly definitionally built from the traditional stats (e.g. box-score-
#' derived advanced stats like NBA BPM, which is itself a regression on box
#' score inputs).
#'
#' @param data A data frame with one row per player (or player-season).
#' @param outcome Character. Column name of the outcome to predict.
#' @param traditional_vars Character vector. Column name(s) of the
#'   traditional stat(s) to use as the baseline predictors.
#' @param advanced_var Character. Column name of the advanced metric being
#'   tested.
#'
#' @return A list with:
#'   \item{baseline_model}{the fitted baseline \code{lm} object}
#'   \item{full_model}{the fitted full \code{lm} object}
#'   \item{baseline_r2}{R-squared of the baseline model}
#'   \item{full_r2}{R-squared of the full model}
#'   \item{delta_r2}{full_r2 - baseline_r2, the incremental predictive value}
#'   \item{f_test}{an \code{anova} object comparing the two models}
#'   \item{p_value}{p-value for whether the improvement is significant}
#'
#' @examples
#' set.seed(1)
#' n <- 200
#' traditional <- rnorm(n)
#' advanced <- 0.9 * traditional + rnorm(n, sd = 0.3) # mostly redundant
#' outcome <- 0.5 * traditional + rnorm(n)
#' df <- data.frame(traditional, advanced, outcome)
#' result <- test_redundancy(df, "outcome", "traditional", "advanced")
#' result$delta_r2
#'
#' @export
test_redundancy <- function(data, outcome, traditional_vars, advanced_var) {
  stopifnot(is.data.frame(data))
  all_vars <- c(outcome, traditional_vars, advanced_var)
  missing_vars <- setdiff(all_vars, names(data))
  if (length(missing_vars) > 0) {
    stop("Column(s) not found in data: ", paste(missing_vars, collapse = ", "))
  }

  baseline_formula <- stats::as.formula(
    paste(outcome, "~", paste(traditional_vars, collapse = " + "))
  )
  full_formula <- stats::as.formula(
    paste(outcome, "~", paste(c(traditional_vars, advanced_var), collapse =
                                " + "))
  )

  baseline_model <- stats::lm(baseline_formula, data = data)
  full_model <- stats::lm(full_formula, data = data)

  baseline_r2 <- summary(baseline_model)$r.squared
  full_r2 <- summary(full_model)$r.squared
  f_test <- stats::anova(baseline_model, full_model)

  list(
    baseline_model = baseline_model,
    full_model = full_model,
    baseline_r2 = baseline_r2,
    full_r2 = full_r2,
    delta_r2 = full_r2 - baseline_r2,
    f_test = f_test,
    p_value = f_test$`Pr(>F)`[2]
  )
}
