# Package index

## Discover

Browse the design library.

- [`list_designs()`](https://macartan.github.io/ResearchDesigns/reference/list_designs.md)
  : List designs in the library
- [`design_info()`](https://macartan.github.io/ResearchDesigns/reference/design_info.md)
  : Design metadata (YAML + defaults)

## Build & inspect

Load designs, change parameters, and read code.

- [`make_design()`](https://macartan.github.io/ResearchDesigns/reference/make_design.md)
  : Build a design, optionally with redesigned parameters

- [`get_args()`](https://macartan.github.io/ResearchDesigns/reference/get_args.md)
  : Editable parameters for a design

- [`get_code()`](https://macartan.github.io/ResearchDesigns/reference/get_code.md)
  :

  Code for a design: simple
  [`make_design()`](https://macartan.github.io/ResearchDesigns/reference/make_design.md)
  call and/or full source

- [`design_profile()`](https://macartan.github.io/ResearchDesigns/reference/design_profile.md)
  :

  Character profile for a design (same prose as printing
  [`design_info()`](https://macartan.github.io/ResearchDesigns/reference/design_info.md))

## Shiny

Browse designs interactively and deploy a standalone app folder.

- [`run_shiny()`](https://macartan.github.io/ResearchDesigns/reference/run_shiny.md)
  : Launch the ResearchDesigns Shiny browser
- [`copy_library_shiny()`](https://macartan.github.io/ResearchDesigns/reference/copy_library_shiny.md)
  : Copy the bundled Shiny app to a standalone folder
- [`install_library_dependencies()`](https://macartan.github.io/ResearchDesigns/reference/install_library_dependencies.md)
  : Install ResearchDesigns system dependencies
- [`get_preview()`](https://macartan.github.io/ResearchDesigns/reference/get_preview.md)
  : Load a baked diagnosis preview
- [`has_preview()`](https://macartan.github.io/ResearchDesigns/reference/has_preview.md)
  : Whether a baked preview exists for a design

## Maintain

Index, audit, bake previews, and refresh the library.

- [`refresh_library()`](https://macartan.github.io/ResearchDesigns/reference/refresh_library.md)
  : Refresh the library (maintainer one-stop)
- [`make_index()`](https://macartan.github.io/ResearchDesigns/reference/make_index.md)
  : Build an in-memory index of all designs
- [`audit_designs()`](https://macartan.github.io/ResearchDesigns/reference/audit_designs.md)
  : Audit one or more designs
- [`bake_previews()`](https://macartan.github.io/ResearchDesigns/reference/bake_previews.md)
  : Bake compact diagnosis previews into inst/previews
- [`contributor_checklist()`](https://macartan.github.io/ResearchDesigns/reference/contributor_checklist.md)
  : Contributor checklist for a design
