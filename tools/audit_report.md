# ResearchDesigns audit report

Summary: **51/58** designs OK, **1** parked (`functional: false`), **6** failed.

Issue types: `missing_packages`, `yaml_extra_params`, `param_discovery`, `load_error`, `missing_object`, `diagnose_failed`, `disabled`, `other`.

Soft notes (do not fail the audit):
- `no YAML tip`: redesignable param has no tip string in YAML (optional).
- `assigned before design but not redesignable`: top-level `name <- ...` is used by the design but `redesign()` cannot change it (often a fixed vector/data object).
Design steps (`declare_*` pieces) and helper functions are not parameters and are not listed.
Parked designs (`functional: false`) are listed under Disabled and do not count as failures.
Plain-text listing (`audit_report.txt`) puts FAIL/SKIP first, then OK.

## Disabled (`functional: false`)

- **network_experiment** - functional: false (parked; skipped by audit)

## Failures

### yaml_extra_params

- **italian_village_continued** (`9.2`)
  - YAML params not in design: linear_hypothesis
  - YAML tip for non-param: linear_hypothesis

- **multi_site_studies** (`19.4`)
  - YAML params not in design: method
  - YAML tip for non-param: method

- **population_estimands** (`7.1`)
  - YAML params not in design: superpopulation_mean
  - YAML tip for non-param: superpopulation_mean

- **process_tracing** (`16.1b`)
  - YAML params not in design: query
  - YAML tip for non-param: query

- **random_forests** (`19.1`)
  - YAML params not in design: share_train
  - YAML tip for non-param: share_train

- **structural_estimation** (`19.2`)
  - YAML params not in design: method
  - YAML tip for non-param: method

## Soft notes (OK designs)

- **cluster_random_sampling**: no YAML tip: locality_shock, individual_shock
- **conditional_expectation**: assigned but not redesignable: polynomial_degrees

## Full table

See `audit_report.csv` / `audit_report.txt` in this folder (problems first).

