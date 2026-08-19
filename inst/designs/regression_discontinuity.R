---
id: regression_discontinuity
alias: "16.5"
label: regression discontinuity
category: rdss
keywords: [observational, causal]
description: >
  Regression discontinuity design (chapter 16).
packages: [rdss, rdrobust]
params:
  "N": "Number of units (sample or population size)"
  "cutoff": "Regression discontinuity cutoff"
book_link: https://book.declaredesign.org/library/observational-causal.html#def-ch16num5
include_in_shiny: false
---

cutoff <- 0.5
control <- function(X) {
  as.vector(poly(X, 4, raw = TRUE) %*% c(.7, -.8, .5, 1))}
treatment <- function(X) {
  as.vector(poly(X, 4, raw = TRUE) %*% c(0, -1.5, .5, .8)) + .15}

N <- 500

design <-
  declare_model(
    N = N,
    U = rnorm(N, 0, 0.1),
    X = runif(N, 0, 1) + U - cutoff,
    D = 1 * (X > 0),
    Y_D_0 = control(X) + U,
    Y_D_1 = treatment(X) + U
  ) +
  declare_inquiry(LATE = treatment(0.5) - control(0.5)) +
  declare_measurement(Y = reveal_outcomes(Y ~ D)) + 
  declare_estimator(
    Y, X, c = 0, 
    term = "Bias-Corrected",
    .method = rdrobust_helper,
    inquiry = "LATE",
    label = "optimal"
  )
