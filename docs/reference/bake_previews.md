# Bake compact diagnosis previews into inst/previews

Each design is baked independently. Failures are collected and returned;
they do not abort the rest of the bake.

## Usage

``` r
bake_previews(designs = NULL, sims = 100)
```

## Arguments

- designs:

  Ids/aliases, or `NULL` for shiny-included designs.

- sims:

  Number of simulations (package default is 100).

## Value

Invisibly, a list with `paths` (character) and `failures` (data frame
with `id` and `error`).
