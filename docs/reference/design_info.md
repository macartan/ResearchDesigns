# Design metadata (YAML + defaults)

Printing uses short English prose. The underlying list is unchanged for
programmatic use (`info$id`, `info$params`, etc.).

## Usage

``` r
design_info(
  design = c("pate_with_sampling", "two_arm_trial", "two_arm_with_blocks",
    "logit_probit_ols", "two_arm_trial_rdss", "two_arm_with_blocks_rdss", "4.1", "11.5",
    "2.1", "2.2")
)
```

## Arguments

- design:

  Design id or book alias.

## Value

A named list of metadata with class `research_designs_info`.
