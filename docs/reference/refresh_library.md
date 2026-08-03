# Refresh the library (maintainer one-stop)

Runs the contributor-facing checks and refreshes baked artifacts: index,
audits, and diagnosis previews (`sims = 100` by default).

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

A list with `index`, `audit`, and `previews`.
