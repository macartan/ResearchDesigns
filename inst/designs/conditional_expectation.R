---
id: conditional_expectation
alias: "11.4"
label: Conditional expectation function
category: rdss
description: >
  Conditional expectation function design (chapter 11).
packages: [purrr, tibble]
params:
  "x_range": "Support / range of the running covariate X"
book_link: https://book.declaredesign.org/declaration-diagnosis-redesign/redesigning.html#def-ch11num4
include_in_shiny: false
---

dip <- function(x) (x <= 1) * x + (x > 1) * (x - 2) ^ 2 + 0.2

x_range <- seq(from = 0, to = 3, length.out = 50)

# Used inside the estimator handler (not always redesignable via the design finder)
polynomial_degrees <- 1:6

design <-
  declare_model(
    N = 100,
    X = runif(N, 0, 3)) +
  declare_inquiry(
    X = x_range, inquiry = str_c("X_", X), estimand = dip(X),
    data = NULL, handler = tibble
  ) +
  declare_measurement(Y = dip(X) + rnorm(N, 0, .5)) +
  declare_estimator(handler = function(data) {
    map(polynomial_degrees, ~lm(Y ~ poly(X, .), data = data)) |> 
      set_names(nm = str_c("A", polynomial_degrees)) |> 
      map_dfc(~predict(., newdata = tibble(X = x_range))) |> 
      bind_cols(tibble(X = x_range)) |> 
      mutate(inquiry = str_c("X_", X)) |> 
      pivot_longer(cols = starts_with("A"),
                   names_to = "estimator",
                   values_to = "estimate")
  })
