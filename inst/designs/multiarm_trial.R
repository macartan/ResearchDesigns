---
id: multiarm_trial
label: Multi-arm trial
category: template
keywords: [experiment, causal, multiarm]
description: >
  Multi-arm experiment with equal assignment probabilities. The outcome
  is a function of the assigned arm: the arm mean plus a shared shock and
  optional per-arm noise. The per-arm noise is drawn when the outcome is
  measured, so a unit has no fixed potential outcome under an arm it was not
  assigned to, and the inquiries are population contrasts of arm means,
  outcome_means[k] - outcome_means[1], rather than sample average effects.
  Estimation is one lm_robust of Y on factor(Z).
  The number of arms is m_arms (default 3). outcome_means, outcome_sds,
  and conditions are length-m_arms vectors.
params:
  "N": "Number of units"
  "m_arms": "Number of arms"
  "sd_i": "Standard deviation of fixed individual-level shock"
  "outcome_means": "Average outcome in each arm"
  "outcome_sds": "Extra standard deviation of additional error in each arm"
  "conditions": "Treatment conditions (length m_arms)"
  "Y": "Outcome function of assigned arm Z, unit shock u, per-arm SDs, and arm means"
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

# `outcome_means` is an argument rather than something read from the file's
# environment: a function carries its own environment, and `redesign()` rebinds
# the design's expressions, not the insides of a function it was handed. Read
# from the environment, `outcome_means[Z]` is `NA` for any arm the file did not
# declare, which drops that arm's rows and quietly costs a contrast.
Y <- function(Z, u, outcome_sds, outcome_means) {
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
  declare_measurement(Y = Y(Z, u, outcome_sds, outcome_means)) +
  declare_estimator(
    Y ~ factor(Z),
    .method = lm_robust,
    term = paste0("factor(Z)", seq_len(m_arms)[-1]),
    inquiry = paste0("ate_Y_", seq_len(m_arms)[-1], "_1")
  )
