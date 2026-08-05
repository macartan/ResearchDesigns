# Audit one or more designs

Checks that each file loads, exposes a design object, and that any YAML
`params:` names are a subset of the design's modifiable parameters. Also
records pre-design objects that are used by the design but missing from
the redesignable parameter list (see
[`param_coverage_report()`](https://macartan.github.io/ResearchDesigns/reference/param_coverage_report.md)).

## Usage

``` r
audit_designs(
  designs = NULL,
  sims = NULL,
  write_report = TRUE,
  report_dir = NULL
)
```

## Arguments

- designs:

  Character vector of ids/aliases, or `NULL` for all.

- sims:

  If not `NULL`, run a short `diagnose_design()` with this many sims.

- write_report:

  If `TRUE` (default), write CSV + markdown under `tools/`.

- report_dir:

  Directory for reports; default `tools/` under package root.

## Value

An object of class `research_designs_audit`.

## Details

Failures are collected per design and (by default) written to
`tools/audit_report.csv`, `tools/audit_report.md`, and
`tools/audit_report.txt` (FAIL/SKIP first, then OK) under the package
root via
[`write_audit_report()`](https://macartan.github.io/ResearchDesigns/reference/write_audit_report.md).
Soft notes (undocumented params, coverage gaps) do not mark a design as
failed.
