# ResearchDesigns audit report

Summary: **54/58** designs OK, **1** parked (`functional: false`), **3** failed.

Issue types: `missing_packages`, `yaml_extra_params`, `param_discovery`, `load_error`, `missing_object`, `diagnose_failed`, `disabled`, `other`.

Soft notes (do not fail the audit): undocumented params, coverage gaps.
Parked designs (`functional: false`) are listed under Disabled and do not count as failures.
Plain-text listing (`audit_report.txt`) puts FAIL/SKIP first, then OK.

## Disabled (`functional: false`)

- **network_experiment** - functional: false (parked; skipped by audit)

## Failures

### param_discovery

- **latent_variables** (`15.6`)
  - attempt to use zero-length variable name
  - atomic coverage gaps: N

- **multilevel** (`15.4`)
  - attempt to use zero-length variable name

- **multilevel_answer_strategies** (`15.5`)
  - attempt to use zero-length variable name

## Soft notes (OK designs)

- **blocked_and_clustered**: undocumented: N, individual_shock
- **cluster_random_sampling**: undocumented: locality_shock, individual_shock, se_type; gaps: budget_function
- **conditional_expectation**: undocumented: N; atomic gaps: polynomial_degrees
- **conjoint**: undocumented: N, respondent.id; gaps: conjoint_utility
- **diff_in_diff**: undocumented: N, Y, G, T, D, mode
- **italian_village_continued**: gaps: declaration_9.1
- **logit_probit_ols**: gaps: tidy_margins
- **matching**: gaps: exact_matching
- **multi_site_studies**: undocumented: N
- **process_tracing**: gaps: causal_model
- **random_forests**: gaps: f_Y, get_best_predictor
- **randomized_saturation**: undocumented: N, individual_shock
- **regression_discontinuity**: undocumented: N, c; gaps: control, treatment
- **regression_discontinuity_fuzzy**: undocumented: N; gaps: control, treatment
- **simple_random_sampling**: undocumented: N; gaps: portola
- **stepped_wedge**: undocumented: N
- **structural_estimation**: gaps: offer, likelihood
- **subgroup_effects**: gaps: fixed_pop
- **survey_nonresponse**: undocumented: N
- **trust_game**: undocumented: id_cols, names_from; gaps: invested, average_invested, returned, average_returned
- **two_arm_randomized_experiment**: gaps: model, inquiry, sampling, assignment, measurement, answer_strategy
- **two_arm_with_blocks**: undocumented: N
- **two_outcome_model_a**: gaps: M1, IDA
- **two_outcome_model_b**: gaps: M2, IDA
- **village_campaign**: undocumented: N; gaps: model_12.1, inquiry_12.1, data_strategy_12.1, answer_strategy_12.1

## Full table

See `audit_report.csv` / `audit_report.txt` in this folder (problems first).

