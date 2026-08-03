# ResearchDesigns: a library of declared designs

Lightweight library of research designs declared with DeclareDesignZero.
Designs live as self-contained R files under `inst/designs/`. Editable
parameters are read from the design object; optional YAML metadata adds
labels, categories, book aliases, and `params:` tip strings.

## Workflow

    list_designs()
    make_design("two_arm_trial", b = 0.5)
    get_args("two_arm_trial")
    get_code("two_arm_trial")
    run_shiny()

## Shiny deploy

    remotes::install_github("macartan/ResearchDesigns")
    install_library_dependencies()
    copy_library_shiny("/path/to/shiny-app")

## See also

Useful links:

- <https://github.com/macartan/ResearchDesigns>

- <https://macartan.github.io/ResearchDesigns/>

- Report bugs at <https://github.com/macartan/ResearchDesigns/issues>

## Author

**Maintainer**: Macartan Humphreys <macartan.humphreys@wzb.eu>

Authors:

- Macartan Humphreys <macartan.humphreys@wzb.eu>
