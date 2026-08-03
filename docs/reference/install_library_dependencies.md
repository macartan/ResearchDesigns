# Install ResearchDesigns system dependencies

Installs package Imports (and, by default, Suggests needed for the Shiny
browser), plus any extra packages declared in design YAML `packages:`
fields. GitHub-only stack packages (`DeclareDesignZero`,
`fabricatrZero`) are installed via
[`remotes::install_github()`](https://remotes.r-lib.org/reference/install_github.html).

## Usage

``` r
install_library_dependencies(
  include_shiny = TRUE,
  include_suggests = FALSE,
  ask = FALSE,
  upgrade = "never",
  verbose = TRUE
)
```

## Arguments

- include_shiny:

  If `TRUE` (default), also install Shiny Suggests (`shiny`, `bslib`,
  `htmltools`, `markdown`).

- include_suggests:

  If `TRUE`, install all DESCRIPTION Suggests. Ignored when
  `include_shiny` already covers the Shiny set unless you want test/doc
  packages too.

- ask:

  Passed through to install helpers when supported.

- upgrade:

  Passed to
  [`remotes::install_github()`](https://remotes.r-lib.org/reference/install_github.html)
  /
  [`install.packages()`](https://rdrr.io/r/utils/install.packages.html).

- verbose:

  Print progress messages.

## Value

Invisibly, a list with `installed`, `already_ok`, and `failed`.

## Details

Typical server workflow:

    remotes::install_github("macartan/ResearchDesigns")
    ResearchDesigns::install_library_dependencies()
    ResearchDesigns::copy_library_shiny("/path/to/shiny-app")
