# Code for a design: simple `make_design()` call and/or full source

Code for a design: simple
[`make_design()`](https://macartan.github.io/ResearchDesigns/reference/make_design.md)
call and/or full source

## Usage

``` r
get_code(
  design = c("pate_with_sampling", "two_arm_trial", "two_arm_with_blocks",
    "logit_probit_ols", "two_arm_trial_rdss", "two_arm_with_blocks_rdss", "4.1", "11.5",
    "2.1", "2.2"),
  style = c("both", "simple", "full"),
  ...
)
```

## Arguments

- design:

  Design id or book alias.

- style:

  `"simple"`, `"full"`, or `"both"`.

- ...:

  Optional parameter values included in the simple snippet.

## Value

Character string (or named list if `style = "both"`).
