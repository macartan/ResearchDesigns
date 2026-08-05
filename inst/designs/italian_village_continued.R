---
id: italian_village_continued
alias: "9.2"
label: Italian village , continued
category: rdss
description: >
  Italian village design, continued (chapter 9).
params:
  "N": "Number of units (sample or population size)"
  "linear_hypothesis": "Linear hypothesis tested (lh_robust)"
book_link: https://book.declaredesign.org/declaration-diagnosis-redesign/choosing-answer-strategy.html#def-ch9num2
include_in_shiny: false
---

declaration_9.1 <-
  declare_model(N = 100, age = sample(0:80, size = N, replace = TRUE)) +
  declare_inquiry(mean_age = mean(age)) +
  declare_sampling(S = complete_rs(N = N, n = 3)) +
  declare_estimator(age ~ 1, .method = lm_robust) 

design <- 
  declaration_9.1 +
  declare_test(age ~ 1, 
               linear_hypothesis = "(Intercept) = 20", 
               .method = lh_robust, label = "test")
