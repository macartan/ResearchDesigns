# Report declared-before-design objects missing from design parameters

For each library design: evaluate the file, read redesignable parameters
from the design object, and list top-level objects that are used by the
design but do not appear in that parameter list.

## Usage

``` r
param_coverage_report(designs = NULL, atomic_only = FALSE)
```

## Arguments

- designs:

  Ids/aliases, or `NULL` for all.

- atomic_only:

  If `TRUE`, only report atomic gaps (likely should be redesignable). If
  `FALSE`, also report helpers, models, etc.

## Value

A data frame (class `research_designs_param_coverage`) of gaps.
