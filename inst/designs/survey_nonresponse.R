---
id: survey_nonresponse
alias: "15.2"
label: survey nonresponse
category: rdss
keywords: [observational, descriptive, sampling]
description: >
  Survey nonresponse design. (chapter 15).
params:
  "effort": "Survey effort / contact intensity (nonresponse)"
book_link: https://book.declaredesign.org/library/observational-descriptive.html#def-ch15num2
include_in_shiny: true
---

effort <- 0 # baseline of no extra effort

design <- 
  declare_model(data = portola) + 
  declare_measurement(Y = as.numeric(cut(Y_star, 7))) + 
  declare_inquiry(Y_bar = mean(Y)) + 
  declare_sampling(S = complete_rs(N, n = 100)) + 
  declare_measurement(
    R = rbinom(n = N, size = 1, prob = pnorm(Y_star + effort)),
    Y = if_else(R == 1, Y, NA_real_)
  ) +
  declare_estimator(Y ~ 1, inquiry = "Y_bar") +
  declare_estimator(R ~ 1, label = "Response Rate")
