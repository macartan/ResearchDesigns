# Create a one-level two-arm design

Routes to
[`make_design()`](https://macartan.github.io/ResearchDesigns/reference/make_design.md)
with id `"two_arm"`:
`make_design("two_arm", N = N, assignment_prob = assignment_prob, ...)`.

## Usage

``` r
two_arm_designer(
  N = 100,
  assignment_prob = 0.5,
  control_mean = 0,
  control_sd = 1,
  ate = 1,
  treatment_mean = NULL,
  treatment_sd = NULL,
  rho = 1,
  args_to_fix = NULL
)
```

## Arguments

- N:

  Sample size.

- assignment_prob:

  Probability of assignment to treatment.

- control_mean:

  Average outcome in control.

- control_sd:

  Standard deviation in control.

- ate:

  Average treatment effect.

- treatment_mean:

  Average outcome in treatment. If supplied, overrides `ate` (`ate`
  becomes `treatment_mean - control_mean`).

- treatment_sd:

  Standard deviation in treatment. Defaults to `control_sd`.

- rho:

  Correlation between treatment and control potential outcomes.

- args_to_fix:

  Ignored. Present for DesignLibrary compatibility.

## Value

A design object.

## Details

Builds a design with one treatment and one control arm. Treatment
effects can be specified by `ate` or by `treatment_mean` (which
overrides `ate`). Argument names match DesignLibrary `two_arm_designer`.

## See also

[`make_design()`](https://macartan.github.io/ResearchDesigns/reference/make_design.md)

## Examples

``` r
if (FALSE) { # \dontrun{
make_design("two_arm", N = 40, ate = 0.2)
two_arm_designer(N = 40, ate = 0.2)
} # }
```
