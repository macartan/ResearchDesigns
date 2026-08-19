# Package index

## Discover

Browse the design library.

- [`list_designs()`](https://macartan.github.io/ResearchDesigns/reference/list_designs.md)
  : List designs in the library
- [`design_info()`](https://macartan.github.io/ResearchDesigns/reference/design_info.md)
  : Design metadata (YAML + defaults)
- [`preferred_diagnosands()`](https://macartan.github.io/ResearchDesigns/reference/preferred_diagnosands.md)
  : Preferred diagnosands declared in a design's YAML
- [`excluded_diagnosands()`](https://macartan.github.io/ResearchDesigns/reference/excluded_diagnosands.md)
  : Diagnosands excluded from display by YAML

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

Index, audit, bake previews, refresh the library, and build the site.

- [`refresh_library()`](https://macartan.github.io/ResearchDesigns/reference/refresh_library.md)
  : Refresh the library (maintainer one-stop)

- [`make_index()`](https://macartan.github.io/ResearchDesigns/reference/make_index.md)
  : Build an in-memory index of all designs

- [`audit_designs()`](https://macartan.github.io/ResearchDesigns/reference/audit_designs.md)
  : Audit one or more designs

- [`write_audit_report()`](https://macartan.github.io/ResearchDesigns/reference/write_audit_report.md)
  :

  Write audit results to CSV, markdown, and plain text under `tools/`

- [`bake_previews()`](https://macartan.github.io/ResearchDesigns/reference/bake_previews.md)
  : Bake compact diagnosis previews into inst/previews

- [`build_docs()`](https://macartan.github.io/ResearchDesigns/reference/build_docs.md)
  : Build the pkgdown site (Dropbox-safe)

- [`contributor_checklist()`](https://macartan.github.io/ResearchDesigns/reference/contributor_checklist.md)
  : Contributor checklist for a design

- [`param_coverage_report()`](https://macartan.github.io/ResearchDesigns/reference/param_coverage_report.md)
  : Report declared-before-design objects missing from design parameters

- [`param_coverage_gaps()`](https://macartan.github.io/ResearchDesigns/reference/param_coverage_gaps.md)
  : Objects declared before design, used by it, but missing from design
  params

## DesignLibrary designers

DesignLibrary-compatible designer functions. Working ports call
[`make_design()`](https://macartan.github.io/ResearchDesigns/reference/make_design.md);
unported names are stubs that point to related library designs.

### Working designers

- [`two_arm_designer()`](https://macartan.github.io/ResearchDesigns/reference/two_arm_designer.md)
  : Create a one-level two-arm design
- [`two_arm_attrition_designer()`](https://macartan.github.io/ResearchDesigns/reference/two_arm_attrition_designer.md)
  : Create a two-arm design with attrition
- [`pretest_posttest_designer()`](https://macartan.github.io/ResearchDesigns/reference/pretest_posttest_designer.md)
  : Create a pretest-posttest design
- [`randomized_response_designer()`](https://macartan.github.io/ResearchDesigns/reference/randomized_response_designer.md)
  : Create a randomized response design
- [`mediation_analysis_designer()`](https://macartan.github.io/ResearchDesigns/reference/mediation_analysis_designer.md)
  : Create a mediation analysis design
- [`multi_arm_designer()`](https://macartan.github.io/ResearchDesigns/reference/multi_arm_designer.md)
  : Create a multi-arm design
- [`two_by_two_designer()`](https://macartan.github.io/ResearchDesigns/reference/two_by_two_designer.md)
  : Create a two-by-two factorial design
- [`block_cluster_two_arm_designer()`](https://macartan.github.io/ResearchDesigns/reference/block_cluster_two_arm_designer.md)
  : Create a blocked and clustered two-arm design

### Unported stubs

- [`binary_iv_designer()`](https://macartan.github.io/ResearchDesigns/reference/designers-not-ported.md)
  [`cluster_sampling_designer()`](https://macartan.github.io/ResearchDesigns/reference/designers-not-ported.md)
  [`factorial_designer()`](https://macartan.github.io/ResearchDesigns/reference/designers-not-ported.md)
  [`process_tracing_designer()`](https://macartan.github.io/ResearchDesigns/reference/designers-not-ported.md)
  [`regression_discontinuity_designer()`](https://macartan.github.io/ResearchDesigns/reference/designers-not-ported.md)
  [`spillover_designer()`](https://macartan.github.io/ResearchDesigns/reference/designers-not-ported.md)
  [`two_arm_covariate_designer()`](https://macartan.github.io/ResearchDesigns/reference/designers-not-ported.md)
  : DesignLibrary designers not ported as-is
