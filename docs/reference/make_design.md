# Build a design, optionally with redesigned parameters

Loads the declared design at its defaults. Named `...` values are
applied with
[`DeclareDesignZero::redesign()`](https://rdrr.io/pkg/DeclareDesignZero/man/redesign.html).
The design object is the source of truth for which names can be changed;
see
[`get_args()`](https://macartan.github.io/ResearchDesigns/reference/get_args.md).
Vector parameters are wrapped so `redesign()` replaces the whole vector
instead of sweeping. YAML `coupled:` drivers (for example `m_arms`) emit
a [`message()`](https://rdrr.io/r/base/message.html) when dependents do
not match in length; `redesign()` still runs.

## Usage

``` r
make_design(
  design = c("two_arm_trial", "two_arm", "multiarm_trial", "two_arm_with_blocks",
    "block_cluster_two_arm", "two_arm_attrition", "two_by_two", "factorial_2x2x2",
    "pretest_posttest", "randomized_response", "mediation_analysis", "audit_experiment",
    "audit_intervention", "bare_bones_two_arm", "baseline_over_N",
    "block_randomized_trial", "blocked_and_clustered", "bootstrapped",
    "cluster_random_sampling", "conditional_expectation", "conjoint",
    "covariate_adjustment", "declaration_using_declare", "design_10_2", "design_10_4", 

    "diff_in_diff", "encouragement", "example_declaration", "factorial_2x2",
    "instrumental_variables", "italian_village", "italian_village_bayes",
    "italian_village_continued", "latent_variables", "lin_estimator",
    "linear_regression", "list_experiment", "list_or_direct_questions",
    "logit_probit_ols", "matching", "multi_site_studies", "multilevel",
    "multilevel_answer_strategies", "network_experiment", "pate_with_sampling",
    "population_estimands", "process_tracing", "random_forests",
    "randomization_inference", 
 "randomized_saturation", "regression_discontinuity",
    "regression_discontinuity_fuzzy", "simple_random_sampling", "single_period_two_arm",
    "stepped_wedge", "structural_estimation", "subgroup_effects", "survey_nonresponse",
    "trust_game", "two_arm_randomized_experiment", "two_arm_trial_library",
    "two_arm_trial_rdss", "two_arm_with_blocks_rdss", "two_outcome_model_a",
    "two_outcome_model_b", "uncertainty_over_effect_size", "village_campaign", "17.1",
    "17.2", "11.3", "11.1", "18.4", "18.5", "9.5", "15.3", 
 "11.4", "17.5", "18.2",
    "10.1", "10.2", "10.4", "16.3", "18.8", "5.1", "18.7", "16.4", "9.1", "9.3", "9.2",
    "15.6", "18.3", "13.1", "17.3", "17.4", "11.5", "16.2", "19.4", "15.4", "15.5",
    "18.13", "4.1", "7.1", "16.1b", "19.1", "9.7", "18.12", "16.5", "16.6", "15.1",
    "18.11", "18.10", "19.2", "18.6", "15.2", "17.6", "13.2", "18.1", "2.1", "2.2",
    "10.3a", "10.3b", "11.2", "12.1a"),
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
