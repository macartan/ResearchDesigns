# Load a baked diagnosis preview

Reads `inst/previews/<id>.rds` written by
[`bake_previews()`](https://macartan.github.io/ResearchDesigns/reference/bake_previews.md)
/
[`refresh_library()`](https://macartan.github.io/ResearchDesigns/reference/refresh_library.md).

## Usage

``` r
get_preview(design)
```

## Arguments

- design:

  Design id or book alias.

## Value

A list with at least `id`, `sims`, and `summary`, or `NULL` if missing.
