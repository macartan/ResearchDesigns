---
id: multiarm_trial
label: Multi-arm trial
category: template
keywords: [experiment, causal, multiarm]
description: >
  Multi-arm experiment with equal assignment probabilities. The outcome
  is a function of the assigned arm: the arm mean plus a shared shock and
  optional per-arm noise. Inquiries are average effects versus arm 1,
  e.g. mean(Y(2) - Y(1)). Estimation is one lm_robust of Y on factor(Z).
  The number of arms is m_arms (default 3). outcome_means, outcome_sds,
  and conditions are length-m_arms vectors.
params:
  "N": "Number of units"
  "m_arms": "Number of arms"
  "sd_i": "Standard deviation of fixed individual-level shock"
  "outcome_means": "Average outcome in each arm"
  "outcome_sds": "Extra standard deviation of additional error in each arm"
  "conditions": "Treatment conditions (length m_arms)"
  "Y": "Outcome function of assigned arm Z, unit shock u, and per-arm unit shock SDs"
coupled:
  m_arms: [outcome_means, outcome_sds, conditions]
include_in_shiny: true
---

N <- 90
m_arms <- 3
outcome_means <- rep(0, m_arms)
outcome_sds <- rep(0, m_arms)
conditions <- seq_len(m_arms)
sd_i <- 1

Y <- function(Z, u, outcome_sds) {
  outcome_means[Z] + u + rnorm(length(u), 0, outcome_sds[Z])
}

design <-
  declare_model(
    N = N,
    u = rnorm(N) * sd_i
  ) +
  declare_inquiry(
    handler = function(data, m_arms, outcome_means) {
      ks <- seq_len(m_arms)[-1]
      data.frame(
        inquiry = paste0("ate_Y_", ks, "_1"),
        estimand = as.numeric(outcome_means[ks] - outcome_means[[1]])
      )
    },
    m_arms = m_arms,
    outcome_means = outcome_means
  ) +
  declare_assignment(
    Z = complete_ra(N, conditions = conditions)
  ) +
  declare_measurement(Y = Y(Z, u, outcome_sds)) +
  declare_estimator(
    Y ~ factor(Z),
    .method = lm_robust,
    term = paste0("factor(Z)", seq_len(m_arms)[-1]),
    inquiry = paste0("ate_Y_", seq_len(m_arms)[-1], "_1")
  )
