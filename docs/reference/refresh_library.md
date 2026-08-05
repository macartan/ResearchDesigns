# Refresh the library (maintainer one-stop)

Runs the contributor-facing checks and refreshes baked artifacts: index,
audits, and diagnosis previews (`sims = 100` by default). Audit and
preview failures are reported at the end; they do not abort the refresh.
See `tools/refresh_report.txt`.

## Usage

``` r
refresh_library(sims = 100, designs = NULL)
```

## Arguments

- sims:

  Preview simulations (default 100).

- designs:

  Optional subset; default all for audit, shiny-on for previews.

## Value

A list with `index`, `audit`, `previews`, `ok_ids`, `preview_failures`,
and `report`.
