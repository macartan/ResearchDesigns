---
id: design_10_4
alias: "10.4"
label: design 10 4
category: rdss
description: >
  10.4 (chapter 10).
params:
  "effect_size": "Treatment effect size"
include_in_shiny: false
---

effect_size <- 0.1
design <-
  declare_model(
    N = 100,
    U = rnorm(N),
    X = rnorm(N),
    potential_outcomes(Y ~ effect_size * Z + X + U)
  ) +
  declare_inquiry(ATE = mean(Y_Z_1 - Y_Z_0)) +
  declare_assignment(Z = complete_ra(N)) +
  declare_measurement(Y = reveal_outcomes(Y ~ Z)) +
  declare_estimator(Y ~ Z, inquiry = "ATE", label = "unadjusted") + 
  declare_estimator(Y ~ Z + X, inquiry = "ATE", label = "adjusted")
