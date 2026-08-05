---
id: structural_estimation
alias: "19.2"
label: structural estimation
category: rdss
keywords: [complex]
description: >
  Structural estimation declaration. (chapter 19). The design shows how
  to use maximum likelihood techniques to estimate parameters of a formal
  model from data.
packages: [bbmle]
params:
  "n": "Sample size drawn from the population (when N is population size)"
  "alpha": "Utility or structural intercept parameter"
  "delta": "Effect shift or discounting parameter"
  "kappa": "Structural / scale parameter"
  "method": "Estimator or modeling method label"
book_link: https://book.declaredesign.org/library/complex.html#def-ch19num2
include_in_shiny: true
---

offer <- function(n, d){
  sum(sapply(2:n[1], function(t) ((-1)^t)*(d^{t-1})))
}

# Likelihood function
likelihood  <- function(n){
  function(k, d, a) {
    m <- Z * offer(n, d) + (1 - Z) * (1 - offer(n, d))
    R <- a * dbeta(y, k * .75, k * .25) + 
      (1 - a) * dbeta(y, k * m, k * (1 - m))
    return(-sum(log(R)))
  }
}

n <- 2        # Number of rounds bargaining (design choice)
delta <- 0.8  # True discount factor (unknown)
kappa <- 2    # Parameter to govern error in offers (unknown)
alpha <- 0.5  # Share of behavioral types in the population (unknown)

design <- 
  declare_model(
    # Define the population: indicator for behavioral type (norm = 1)
    N = 200, 
    type = rbinom(N, 1, alpha),
    n = n) +
  declare_inquiry(kappa = kappa,     
                  delta = delta,     
                  alpha = alpha) +   
  declare_assignment(Z = complete_ra(N)) +
  declare_measurement(
    # Equilibrium payoff
    pi = type * .75 + 
      (1 - type) * (Z * offer(n, delta) + (1 - Z) * (1 -offer(n, delta))), 
    # Actual payoff (stochastic)
    y = rbeta(N, pi * kappa, (1 - pi) * kappa))+
  # Estimation via maximum likelihood
  declare_estimator(.method = mle2,
                    minuslogl = likelihood(n),
                    start = list(k = 2, d = 0.50, a = 0.50),
                    lower = list(k = 0.10, d = 0.01, a = 0.01),
                    upper = list(k = 100, d = 0.99, a = 0.99),
                    method = "L-BFGS-B",
                    term = c("k", "d", "a"),
                    inquiry = c("kappa","delta", "alpha"), 
                    label = "Structural model")
