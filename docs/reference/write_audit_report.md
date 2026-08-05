# Write audit results to CSV, markdown, and plain text under `tools/`

Write audit results to CSV, markdown, and plain text under `tools/`

## Usage

``` r
write_audit_report(x, dir = NULL)
```

## Arguments

- x:

  A `research_designs_audit` object from
  [`audit_designs()`](https://macartan.github.io/ResearchDesigns/reference/audit_designs.md).

- dir:

  Output directory. Default: `tools/` under the package root.

## Value

Character vector of paths written (invisibly).
