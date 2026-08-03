# Build a design, optionally with redesigned parameters

Loads the declared design at its defaults. Named `...` values are
applied with
[`DeclareDesignZero::redesign()`](https://rdrr.io/pkg/DeclareDesignZero/man/redesign.html).
The design object is the source of truth for which names can be changed;
see
[`get_args()`](https://macartan.github.io/ResearchDesigns/reference/get_args.md).

## Usage

``` r
make_design(
  design = c("pate_with_sampling", "two_arm_trial", "two_arm_with_blocks",
    "logit_probit_ols", "two_arm_trial_rdss", "two_arm_with_blocks_rdss", "4.1", "11.5",
    "2.1", "2.2"),
  ...
)
```

## Arguments

- design:

  Design id or book alias. Defaults to `"two_arm_trial"` (or the first
  installed design). Tab-completion offers the full library list.

- ...:

  Named parameter values passed to `redesign()`.

## Value

A design object (or a list of designs if a parameter is a vector and
`redesign()` expands).

## Details

In RStudio, Positron, and other tools that complete from formals, typing
`make_design("` and pressing Tab lists installed design ids (and
aliases). See
[`list_designs()`](https://macartan.github.io/ResearchDesigns/reference/list_designs.md)
for the same catalogue in the console.

## Examples

``` r
if (FALSE) { # \dontrun{
make_design()
make_design("two_arm_trial", b = 0.5)
make_design("2.1", b = 0.5)  # book alias
} # }
```
