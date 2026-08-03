# Editable parameters for a design

Reads parameters from the design object. Optional YAML `params:` entries
only add tips (and never invent new parameter names).

## Usage

``` r
get_args(
  design = c("pate_with_sampling", "two_arm_trial", "two_arm_with_blocks",
    "logit_probit_ols", "two_arm_trial_rdss", "two_arm_with_blocks_rdss", "4.1", "11.5",
    "2.1", "2.2")
)
```

## Arguments

- design:

  Design id or book alias.

## Value

A data frame with `name`, `default`, `value_str`, and `tip`.
