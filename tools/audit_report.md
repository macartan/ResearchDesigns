# ResearchDesigns audit report

Summary: **52/58** designs OK, **1** parked (`functional: false`), **5** failed.

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

### yaml_extra_params

- **simple_random_sampling** (`15.1`)
  - YAML params not in design: portola
  - extra YAML: portola

- **subgroup_effects** (`18.6`)
  - YAML params not in design: fixed_pop, book_link
  - extra YAML: fixed_pop, book_link

## Soft notes (OK designs)

- **cluster_random_sampling**: undocumented: locality_shock, individual_shock, se_type; gaps: budget_function
- **conditional_expectation**: undocumented: N; atomic gaps: polynomial_degrees
- **conjoint**: undocumented: respondent.id; gaps: conjoint_utility
- **diff_in_diff**: undocumented: Y, G, T, D, mode
- **italian_village_continued**: gaps: declaration_9.1
- **matching**: gaps: exact_matching
- **random_forests**: gaps: get_best_predictor
- **regression_discontinuity**: undocumented: N, c
- **regression_discontinuity_fuzzy**: undocumented: N
- **trust_game**: undocumented: id_cols, names_from

## Full table

See `audit_report.csv` / `audit_report.txt` in this folder (problems first).

