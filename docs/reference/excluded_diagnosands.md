# Diagnosands excluded from display by YAML

Tokens like `-bias` in `diagnosands:` remove that name from the Shiny
diagnosand list for the design.

## Usage

``` r
excluded_diagnosands(design)
```

## Arguments

- design:

  Design id or book alias.

## Value

Character vector (possibly empty).
