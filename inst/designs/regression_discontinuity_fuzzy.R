---
id: regression_discontinuity_fuzzy
alias: "16.6"
label: regression discontinuity fuzzy
category: rdss
keywords: [observational, causal]
description: >
  Regression discontinuity designs with varying bandwidths (chapter 16).
packages: [rdss, rdrobust]
params:
  "bandwidth": "RDD estimation bandwidth"
  "cutoff": "Regression discontinuity cutoff"
book_link: https://book.declaredesign.org/library/observational-causal.html#def-ch16num6
include_in_shiny: true
---

bandwidth <- 0.2
cutoff <- 0.5
control <- function(X) {
  as.vector(poly(X - cutoff, 4, raw = TRUE) %*% c(.7, -.8, .5, 1))}
treatment <- function(X) {
  as.vector(poly(X - cutoff, 4, raw = TRUE) %*% c(0, -1.5, .5, .8)) + .15}

design <-
  declare_model(
    N = 500,
    U = rnorm(N, 0, 0.1),
    X = runif(N, 0, 1) + U,
    D = 1 * (X > cutoff),
    Y_D_0 = control(X) + U,
    Y_D_1 = treatment(X) + U
  ) +
  declare_inquiry(LATE = treatment(cutoff) - control(cutoff)) +
  declare_measurement(Y = reveal_outcomes(Y ~ D)) +
  declare_estimator(
    Y, X, c = cutoff,
    term = "Bias-Corrected",
    .method = rdrobust_helper,
    inquiry = "LATE",
    label = "optimal"
  )  +
  declare_measurement(X_c = X - cutoff) +
  declare_estimator(
    Y ~ X_c * D,
    subset = X_c > -1*bandwidth & X_c < bandwidth,
    .method = lm_robust,
    inquiry = "LATE",
    label = "linear"
  )
