# ResearchDesigns: a library of declared designs

## The idea

To contribute a design to **ResearchDesigns** you just have to place a
self-contained `.R` file in `inst/designs/`. That file declares a design
and, optionally, a short YAML header. Once it is there, the design can
be loaded, modified, diagnosed, and browsed in the bundled Shiny app.

For the contribution workflow (fork, add file, refresh, check, pull
request), see the vignette *Contributing a design* or the Shiny
**Contribute** tab.

## What a design file looks like

Here is the starter design `two_arm_trial`.

`inst/designs/two_arm_trial.R`

``` r
---
id: two_arm_trial
label: Simple two-arm trial
category: template
keywords: [experiment, two-arm]
description: >
  Simple two-arm trial with complete random assignment.
params:
  "N": "Number of units (sample or population size)"
  "b": "Treatment effect (outcome scale)"
diagnosands: [bias, power]
include_in_shiny: true
---


N <- 1000
b <- 0.2

design <-
  
  declare_model(
    N = N,
    potential_outcomes(Y ~ b * Z + rnorm(N))
  ) +

  declare_inquiry(ATE = mean(Y_Z_1) - mean(Y_Z_0)) +
  
  declare_assignment(Z = complete_ra(N)) +
  
  declare_measurement(Y = reveal_outcomes(Y ~ Z)) +
  
  declare_estimator(Y ~ Z, .method = difference_in_means, inquiry = "ATE")
```

The header is optional. At minimum you need a design object (by default
named `design`). Parameter tips are plain strings under `params:`; quote
keys such as `"N"` and `"b"`.

As soon as that file sits in `inst/designs/`, it is available to
[`make_design()`](https://macartan.github.io/ResearchDesigns/reference/make_design.md),
[`get_args()`](https://macartan.github.io/ResearchDesigns/reference/get_args.md),
[`get_code()`](https://macartan.github.io/ResearchDesigns/reference/get_code.md),
the maintainer audits, and
[`run_shiny()`](https://macartan.github.io/ResearchDesigns/reference/run_shiny.md).

## What designs are included?

``` r

list_designs()
#> ResearchDesigns library: 67 designs
#> 
#> * Getting started
#>   two_arm_trial (Simple two-arm trial)
#>   two_arm (Flexible two-arm trial (library))
#>   multiarm_trial (Multi-arm trial)
#>   two_arm_with_blocks (Two-arm trial with blocks)
#>   block_cluster_two_arm (Two arm trial with blocks and clusters)
#>   two_arm_attrition (Two-arm trial with attrition)
#>   two_by_two (2x2 factorial (library))
#>   factorial_2x2x2 (2x2x2 factorial)
#>   pretest_posttest (Pretest-posttest design)
#>   randomized_response (Randomized response)
#>   mediation_analysis (Mediation analysis)
#> 
#> * Other RDSS designs
#>   audit_experiment (audit experiment)
#>   audit_intervention (audit intervention)
#>   bare_bones_two_arm (Bare-bones two-arm trial)
#>   baseline_over_N (A baseline declaration intended to be reed over $N$.)
#>   block_randomized_trial (block randomized trial)
#>   blocked_and_clustered (blocked and clustered)
#>   bootstrapped (bootstrapped)
#>   cluster_random_sampling (cluster random sampling)
#>   conditional_expectation (Conditional expectation function)
#>   conjoint (conjoint)
#>   ... and 46 more
#> 
#> print(list_designs(), list_all = TRUE) lists every design.
#> 
#> See design_info("id") or get_args("id") for details;
#> as.data.frame(list_designs(discover_params = TRUE)) for parameters.
```

Call
[`list_designs()`](https://macartan.github.io/ResearchDesigns/reference/list_designs.md)
to see ids and labels. Use `design_info("two_arm_trial")` or
`get_args("two_arm_trial")` for one design, or
`as.data.frame(list_designs(discover_params = TRUE))` for the table
including redesignable parameters.

## Use ResearchDesigns to make a design

``` r

my_design <- make_design("two_arm_trial")
my_design
#> Research design with 5 step(s):
#>   [model] model (dgp)
#>   [inquiry] ATE (inquiry)
#>   [assignment] assignment (dgp)
#>   [measurement] measurement (dgp)
#>   [estimator] estimator (estimator)
```

## Change parameters and simulate

Parameters are taken from the design itself. Pass new values to
[`make_design()`](https://macartan.github.io/ResearchDesigns/reference/make_design.md);
under the hood this uses DeclareDesign’s `redesign()`. A core set of
designs also keep DesignLibrary names, so
`two_arm_designer(N = 40, ate = 0.2)` is the same idea as
`make_design("two_arm", N = 40, ate = 0.2)`.

``` r

make_design("two_arm_trial", b = 0.3) |>
  simulate_design(sims = 2)
#> # A tibble: 2 × 14
#>   sim_ID term  estimate std.error statistic     p.value conf.low conf.high    df
#>    <int> <chr>    <dbl>     <dbl>     <dbl>       <dbl>    <dbl>     <dbl> <dbl>
#> 1      1 Z        0.344    0.0617      5.58     3.15e-8    0.223     0.465  998.
#> 2      2 Z        0.343    0.0631      5.44     6.81e-8    0.219     0.467  993.
#> # ℹ 5 more variables: outcome <chr>, estimator <chr>, inquiry <chr>,
#> #   estimand <dbl>, b <dbl>
```

You can now change all parameters in one go.

``` r

make_design("two_arm_trial", b = c(0, .3, .6), N = c(20, 1000)) |>
  simulate_design(sims = 100) |>
  ggplot(aes(estimate, p.value, color = factor(b))) + 
  geom_point()  + facet_grid(N~.)
```

![](ResearchDesigns_files/figure-html/make-and-simulate-grid-1.png)

## Browse in Shiny

``` r

run_shiny()
```

The app opens on a searchable library table. Click a row to open the
design, expand its profile, run it once, diagnose it, or redesign
parameters. For a server deploy: install the package, run
[`install_library_dependencies()`](https://macartan.github.io/ResearchDesigns/reference/install_library_dependencies.md),
then `copy_library_shiny(dest)`.

## Maintainer tools

A short set of helpers keeps the library honest:

- [`contributor_checklist()`](https://macartan.github.io/ResearchDesigns/reference/contributor_checklist.md)
  — what a design file should satisfy
- [`audit_designs()`](https://macartan.github.io/ResearchDesigns/reference/audit_designs.md)
  — load each design and check that YAML `params:` names match
  redesignable objects
- [`bake_previews()`](https://macartan.github.io/ResearchDesigns/reference/bake_previews.md)
  — write compact diagnosis previews (`sims = 100` by default) into
  `inst/previews/`
- [`refresh_library()`](https://macartan.github.io/ResearchDesigns/reference/refresh_library.md)
  — index, audit, and bake in one step

Run maintainer helpers from the package source tree, or set:

``` r

options(ResearchDesigns.root = "C:/path/to/ResearchDesigns")
refresh_library()
```

That is the whole loop: drop in a design file, use it from R or Shiny,
and refresh the library when you change the set. Step-by-step
contribution guidance is in
[`vignette("contributing", package = "ResearchDesigns")`](https://macartan.github.io/ResearchDesigns/articles/contributing.md).
