# ResearchDesigns audit report

Summary: **65/65** designs OK.

Issue types: `missing_packages`, `yaml_extra_params`, `param_discovery`, `load_error`, `missing_object`, `diagnose_failed`, `disabled`, `other`.

Soft notes (do not fail the audit):
- `no YAML tip`: redesignable param has no tip string in YAML (optional).
- `assigned before design but not redesignable`: top-level `name <- ...` is used by the design but `redesign()` cannot change it (often a fixed vector/data object).
Design steps (`declare_*` pieces) and helper functions are not parameters and are not listed.
Parked designs (`functional: false`) are listed under Disabled and do not count as failures.
Plain-text listing (`audit_report.txt`) puts FAIL/SKIP first, then OK.

## Failures

_None._

## Soft notes (OK designs)

- **cluster_random_sampling**: no YAML tip: locality_shock, individual_shock
- **conditional_expectation**: assigned but not redesignable: polynomial_degrees
- **network_experiment**: no YAML tip: adjacency, permutations

## Full table

See `audit_report.csv` / `audit_report.txt` in this folder (problems first).

