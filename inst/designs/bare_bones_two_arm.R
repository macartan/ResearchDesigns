---
id: bare_bones_two_arm
alias: "11.3"
label: Bare-bones two-arm trial
category: rdss
description: >
  Bare-bones two-arm trial (chapter 11).
params:
  "N": "Number of units (sample or population size)"
book_link: https://book.declaredesign.org/declaration-diagnosis-redesign/redesigning.html#def-ch11num3
include_in_shiny: false
---

N <- 100

design <-
  declare_model(N = N, U = rnorm(N),
                potential_outcomes(Y ~ 0.2 * Z + U)) +
  declare_inquiry(ATE = mean(Y_Z_1 - Y_Z_0)) +
  declare_assignment(Z = complete_ra(N = N, prob = prob)) +
  declare_measurement(Y = reveal_outcomes(Y ~ Z)) +
  declare_estimator(Y ~ Z, inquiry = "ATE")
