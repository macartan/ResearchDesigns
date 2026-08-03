# Editable parameters for a design

Reads parameters from the design object. Optional YAML `params:` entries
only add tips (and never invent new parameter names).

## Usage

``` r
get_args(design)
```

## Arguments

- design:

  Design id or book alias.

## Value

A data frame with `name`, `default`, `value_str`, and `tip`.
