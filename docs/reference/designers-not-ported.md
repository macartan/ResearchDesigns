# DesignLibrary designers not ported as-is

These names exist so code written for DesignLibrary does not fail with
"object not found". They message with related declarations via
[`make_design()`](https://macartan.github.io/ResearchDesigns/reference/make_design.md),
for example `make_design("encouragement")` or
`make_design("factorial_2x2")`.

## Usage

``` r
binary_iv_designer(...)

cluster_sampling_designer(...)

factorial_designer(...)

process_tracing_designer(...)

regression_discontinuity_designer(...)

spillover_designer(...)

two_arm_covariate_designer(...)
```

## Arguments

- ...:

  Ignored.

## Value

Invisible `NULL`.

## See also

[`make_design()`](https://macartan.github.io/ResearchDesigns/reference/make_design.md)
