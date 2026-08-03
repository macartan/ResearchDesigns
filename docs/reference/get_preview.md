# Load a baked diagnosis preview

Reads `inst/previews/<id>.rds` written by
[`bake_previews()`](https://macartan.github.io/ResearchDesigns/reference/bake_previews.md)
/
[`refresh_library()`](https://macartan.github.io/ResearchDesigns/reference/refresh_library.md).

## Usage

``` r
get_preview(
  design = c("pate_with_sampling", "two_arm_trial", "two_arm_with_blocks",
    "logit_probit_ols", "two_arm_trial_rdss", "two_arm_with_blocks_rdss", "4.1", "11.5",
    "2.1", "2.2")
)
```

## Arguments

- design:

  Design id or book alias.

## Value

A list with at least `id`, `sims`, and `summary`, or `NULL` if missing.
