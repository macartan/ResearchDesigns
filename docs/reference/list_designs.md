# List designs in the library

Returns a data frame of design metadata. Printing shows a compact
summary (`id`, `alias`, modifiable parameters). Use
[`design_info()`](https://macartan.github.io/ResearchDesigns/reference/design_info.md),
[`get_args()`](https://macartan.github.io/ResearchDesigns/reference/get_args.md),
or [`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) /
`print(as.data.frame(x))` for the full table.

## Usage

``` r
list_designs(shiny_only = FALSE, discover_params = TRUE)
```

## Arguments

- shiny_only:

  If `TRUE`, only designs with `include_in_shiny: true` (the default
  when the field is omitted).

- discover_params:

  If `TRUE` (default), load each design once to list redesignable
  parameters. Set `FALSE` for a metadata-only scan.

## Value

A data frame with class `research_designs_list`.
