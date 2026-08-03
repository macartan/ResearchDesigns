---
id: two_arm_trial_rdss
alias: "2.1"
label: Two-arm trial from RDSS
category: rdss
keywords: [experiment, two-arm, introduction]
description: >
  Two-arm trial design from RDSS chapter 2. Illustrates MIDA with a simple
  sampling and complete random assignment step.
params:
  "N": "Sample size before sampling"
  "n": "Number sampled"
  "b": "Background effect"
book_link: https://book.declaredesign.org/introduction/what-is-a-research-design.html#def-ch2num1
include_in_shiny: true
---

N <- 1000
b <- 0
n <- 150

design <-
  
  declare_model(
    N = N,
    X = sample(c(0, 1), N, replace = TRUE),
    potential_outcomes(Y ~ b * X + runif(1, 0, 0.5) * Z + rnorm(N))
  ) +

  declare_inquiry(ATE = mean(Y_Z_1) - mean(Y_Z_0)) +
  
  declare_sampling(S = complete_rs(N = N, n = n), filter = S == 1) +
  declare_assignment(Z = complete_ra(N)) +
  declare_measurement(Y = reveal_outcomes(Y ~ Z)) +
  
  declare_estimator(Y ~ Z, .method = difference_in_means, inquiry = "ATE")

