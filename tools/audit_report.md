# ResearchDesigns audit report

Summary: **67/67** designs OK.

Issue types: `missing_packages`, `yaml_extra_params`, `param_discovery`, `load_error`, `missing_object`, `diagnose_failed`, `disabled`, `other`.

Soft notes (do not fail the audit):
- `no YAML tip`: redesignable param has no tip string in YAML (optional).
- `assigned before design but not redesignable`: top-level `name <- ...` is used by the design but `redesign()` cannot change it (often a fixed vector/data object).
Design steps (`declare_*` pieces) are not parameters. Functions assigned before `design <-` are R-only parameters.
Parked designs (`functional: false`) are listed under Disabled and do not count as failures.
Plain-text listing (`audit_report.txt`) puts FAIL/SKIP first, then OK.

## Failures

_None._

## Soft notes (OK designs)

- **conjoint**: no YAML tip: conjoint_utility
- **italian_village_bayes**: no YAML tip: summary_fn
- **logit_probit_ols**: no YAML tip: tidy_margins
- **matching**: no YAML tip: exact_matching
- **network_experiment**: no YAML tip: estimator_AS
- **random_forests**: no YAML tip: f_Y, get_best_predictor
- **regression_discontinuity**: no YAML tip: control, treatment
- **regression_discontinuity_fuzzy**: no YAML tip: control, treatment
- **structural_estimation**: no YAML tip: offer, likelihood
- **trust_game**: no YAML tip: invested, average_invested, returned, average_returned

## Full table

See `audit_report.csv` / `audit_report.txt` in this folder (problems first).

