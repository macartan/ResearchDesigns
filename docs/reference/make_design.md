# Build a design, optionally with redesigned parameters

Loads the declared design at its defaults. Named `...` values are
applied with
[`DeclareDesignZero::redesign()`](https://rdrr.io/pkg/DeclareDesignZero/man/redesign.html).
The design object is the source of truth for which names can be changed;
see
[`get_args()`](https://macartan.github.io/ResearchDesigns/reference/get_args.md).

## Usage

``` r
make_design(design = "two_arm_trial", ...)
```

## Arguments

- design:

  Design id or book alias. Defaults to `"two_arm_trial"`.

- ...:

  Named parameter values passed to `redesign()`.

## Value

A design object (or a list of designs if a parameter is a vector and
`redesign()` expands).

## Examples

``` r
if (FALSE) { # \dontrun{
make_design()
make_design("two_arm_trial", b = 0.5)
make_design("2.1", b = 0.5)  # book alias
} # }
```
