# ResearchDesigns Shiny browser
# Deploy: remotes::install_github(...); install_library_dependencies(); copy_library_shiny(dest)
# Flow: Library (searchable table) -> Design / Diagnosis / Redesign

library(shiny)

`%||%` <- function(x, y) {
  if (is.null(x) || length(x) == 0L || (length(x) == 1L && is.na(x))) y else x
}

.app_dir <- if (nzchar(Sys.getenv("SHINY_APP_DIR", ""))) {
  Sys.getenv("SHINY_APP_DIR")
} else {
  getwd()
}
for (cfg in c("deploy-options.R", "local.R")) {
  path <- file.path(.app_dir, cfg)
  if (file.exists(path)) source(path, local = FALSE)
}

PKGDOWN_URL <- "https://macartan.github.io/ResearchDesigns/"
GITHUB_URL <- "https://github.com/macartan/ResearchDesigns"

has_bslib <- requireNamespace("bslib", quietly = TRUE)
has_dt <- requireNamespace("DT", quietly = TRUE)
has_ggplot2 <- requireNamespace("ggplot2", quietly = TRUE)

app_css <- "
.rd-wrap { width: 90%; max-width: 1600px; margin: 0 auto; padding: 1rem 1.25rem 2rem; }
.rd-wrap-library { width: 94%; max-width: none; }
.rd-hero h1 { font-size: 1.75rem; margin-bottom: 0.25rem; }
.rd-hero p { color: #5c6b73; margin-bottom: 1rem; }
.rd-card {
  background: #fff; border: 1px solid #e6ebe8; border-radius: 12px;
  padding: 1rem 1.15rem; margin-bottom: 1rem;
  box-shadow: 0 1px 2px rgba(16, 40, 36, 0.04);
}
.rd-muted { color: #6c757d; font-size: 0.92rem; }
.rd-code {
  background: #f4f7f5; border-radius: 8px; padding: 0.85rem 1rem;
  font-size: 0.85rem; white-space: pre-wrap; overflow-x: auto;
}
.rd-profile {
  background: #f8faf9; border-left: 4px solid #2c6e63; border-radius: 0 8px 8px 0;
  padding: 0.85rem 1rem; white-space: pre-wrap; font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
  font-size: 0.84rem; line-height: 1.45;
}
.rd-chip {
  display: inline-block; background: #e8f2ef; color: #1f4f47;
  border-radius: 999px; padding: 0.15rem 0.55rem; margin: 0.1rem 0.2rem 0.1rem 0;
  font-size: 0.78rem; font-weight: 600;
}
details.rd-details {
  border: 1px solid #d9e3df; border-radius: 10px; padding: 0.65rem 0.9rem; background: #fff;
}
details.rd-details > summary {
  cursor: pointer; font-weight: 600; list-style: none;
}
details.rd-details > summary::-webkit-details-marker { display: none; }
details.rd-details > summary::before {
  content: '\\25B8  ';
  display: inline-block;
  margin-right: 0.15rem;
  color: #2c6e63;
}
details.rd-details[open] > summary::before { content: '\\25BE  '; }
details.rd-details[open] > summary { margin-bottom: 0.65rem; }
.rd-selected-banner {
  display: flex; flex-wrap: wrap; gap: 0.75rem; align-items: center;
  justify-content: space-between; margin-bottom: 1rem;
}
.rd-param-grid {
  display: grid;
  grid-template-columns: minmax(6rem, 14%) minmax(1.25rem, 1.75rem) 1fr;
  gap: 0.15rem 0.45rem;
  align-items: center;
  margin: 0.35rem 0 0.5rem;
}
.rd-param-grid .form-group,
.rd-param-grid .shiny-input-container {
  margin-bottom: 0 !important;
  padding-bottom: 0 !important;
}
.rd-param-grid .form-control {
  padding-top: 0.25rem;
  padding-bottom: 0.25rem;
  min-height: calc(1.4em + 0.5rem);
}
.rd-param-name { font-weight: 650; color: #1f4f47; font-size: 0.92rem; }
.rd-tip {
  display: inline-flex; align-items: center; justify-content: center;
  width: 1.05rem; height: 1.05rem; border-radius: 999px;
  background: #e8f2ef; color: #2c6e63; font-size: 0.68rem; font-weight: 700;
  cursor: help; user-select: none;
}
.rd-tip-empty { visibility: hidden; }
.rd-help-box {
  background: #f7faf8; border: 1px solid #dde8e3; border-radius: 8px;
  padding: 0.45rem 0.7rem; font-size: 0.86rem; color: #445;
  margin-bottom: 0.45rem;
}
.rd-help-box code { background: #eef3f1; padding: 0.05rem 0.3rem; border-radius: 4px; }
.rd-error { color: #833; font-size: 0.9rem; margin: 0.35rem 0; }
#library_table table.dataTable tbody tr { cursor: pointer; }
#library_table table.dataTable tbody tr:hover { background-color: #eef6f3 !important; }
"

theme_obj <- if (has_bslib) {
  bslib::bs_theme(
    version = 5,
    bootswatch = "flatly",
    primary = "#2c6e63",
    "font-size-base" = "0.98rem"
  )
} else {
  NULL
}

library_panel <- function() {
  div(
    class = "rd-card",
    fluidRow(
      column(
        6,
        textInput(
          "lib_search",
          NULL,
          placeholder = "Search id, alias, label, params, keywords…",
          width = "100%"
        )
      ),
      column(
        6,
        selectInput(
          "lib_category",
          NULL,
          choices = c("All categories" = "all"),
          selected = "all",
          width = "100%"
        )
      )
    ),
    if (has_dt) {
      DT::DTOutput("library_table")
    } else {
      tagList(
        helpText("Install DT for a searchable table; showing a basic table instead."),
        tableOutput("library_table_basic")
      )
    }
  )
}

design_panel <- function() {
  tagList(
    uiOutput("selected_header"),
    div(
      class = "rd-card",
      tags$details(
        class = "rd-details",
        tags$summary("Design profile"),
        verbatimTextOutput("design_profile_text")
      )
    ),
    div(
      class = "rd-card",
      h4("One-line"),
      tags$pre(class = "rd-code", textOutput("simple_code", inline = TRUE)),
      h4("Full declaration"),
      tags$pre(class = "rd-code", textOutput("full_code", inline = TRUE)),
      h4("Editable parameters"),
      tableOutput("args_table"),
      br(),
      actionButton("run_once", "Run this design once", class = "btn-secondary btn-sm"),
      verbatimTextOutput("run_once_out")
    )
  )
}

diagnosis_panel <- function() {
  tagList(
    uiOutput("selected_header_diag"),
    div(
      class = "rd-card",
      p(class = "rd-muted", "Baked preview from the package when available; otherwise run a live diagnosis."),
      uiOutput("preview_status"),
      numericInput("diag_sims", "Simulations", value = 100, min = 1, step = 10, width = "140px"),
      actionButton("run_diagnosis", "Run diagnosis", class = "btn-primary"),
      br(), br(),
      h4("Diagnosands"),
      tableOutput("diagnosis_table"),
      if (has_ggplot2) plotOutput("diagnosis_plot", height = "320px") else NULL
    )
  )
}

redesign_panel <- function() {
  tagList(
    uiOutput("redesign_top"),
    uiOutput("mod_error"),
    # Keep plot/table outside renderUI so ggplot binds reliably
    conditionalPanel(
      condition = "output.mod_show_results == true",
      div(
        class = "rd-card",
        fluidRow(
          column(5, uiOutput("mod_diagnosand_ui")),
          column(7, uiOutput("mod_plot_controls"))
        ),
        if (has_ggplot2) plotOutput("mod_plot", height = "380px") else NULL,
        tags$details(
          class = "rd-details",
          style = "margin-top: 0.75rem;",
          tags$summary("Diagnosand table"),
          tableOutput("mod_table")
        )
      )
    )
  )
}

about_panel <- function() {
  div(
    class = "rd-card",
    h3("About ResearchDesigns"),
    p("A library of declared designs built on DeclareDesignZero. Designs are self-contained R files; editable parameters come from the design object."),
    tags$ul(
      tags$li(tags$a(href = PKGDOWN_URL, target = "_blank", "Package documentation (pkgdown)")),
      tags$li(tags$a(href = GITHUB_URL, target = "_blank", "GitHub repository")),
      tags$li(tags$a(href = "https://declaredesign.org/", target = "_blank", "DeclareDesign"))
    ),
    p(class = "rd-muted",
      paste0(
        "Package version ",
        tryCatch(as.character(utils::packageVersion("ResearchDesigns")), error = function(e) "?"),
        "."
      )
    )
  )
}

ui_body <- if (has_bslib) {
  bslib::page_navbar(
    title = "ResearchDesigns",
    id = "main_nav",
    theme = theme_obj,
    header = tags$style(HTML(app_css)),
    bslib::nav_panel("Library", div(class = "rd-wrap rd-wrap-library", library_panel())),
    bslib::nav_panel("Design", div(class = "rd-wrap", design_panel())),
    bslib::nav_panel("Diagnosis", div(class = "rd-wrap", diagnosis_panel())),
    bslib::nav_panel("Redesign", div(class = "rd-wrap", redesign_panel())),
    bslib::nav_spacer(),
    bslib::nav_panel("About", div(class = "rd-wrap", about_panel())),
    bslib::nav_item(tags$a(href = PKGDOWN_URL, target = "_blank", "Docs"))
  )
} else {
  fluidPage(
    tags$style(HTML(app_css)),
    titlePanel("ResearchDesigns"),
    tabsetPanel(
      id = "main_nav",
      tabPanel("Library", div(class = "rd-wrap rd-wrap-library", library_panel())),
      tabPanel("Design", div(class = "rd-wrap", design_panel())),
      tabPanel("Diagnosis", div(class = "rd-wrap", diagnosis_panel())),
      tabPanel("Redesign", div(class = "rd-wrap", redesign_panel())),
      tabPanel("About", div(class = "rd-wrap", about_panel()))
    )
  )
}

ui <- ui_body

server <- function(input, output, session) {
  idx_all <- ResearchDesigns::list_designs(shiny_only = TRUE)
  if (!nrow(idx_all)) idx_all <- ResearchDesigns::list_designs()

  selected_id <- reactiveVal(NA_character_)
  live_diag <- reactiveVal(NULL)
  mod_diag <- reactiveVal(NULL)
  mod_status <- reactiveVal("")
  run_once_txt <- reactiveVal("")
  mod_last_ranges <- reactiveVal(character(0))

  # Comma/space-separated values -> c(...) for eval; leave single values alone
  normalize_value_expression <- function(str) {
    str <- trimws(str %||% "")
    if (!nzchar(str)) return(str)
    if (grepl("^c\\s*\\(", str) || grepl("^seq\\s*\\(", str)) return(str)
    parts <- strsplit(str, "[,;\\s]+")[[1]]
    parts <- trimws(parts)
    parts <- parts[nzchar(parts)]
    if (length(parts) < 2L) return(str)
    parses_ok <- vapply(parts, function(p) {
      tryCatch({
        eval(parse(text = p), envir = baseenv())
        TRUE
      }, error = function(e) FALSE)
    }, logical(1L))
    if (all(parses_ok)) paste0("c(", paste(parts, collapse = ", "), ")") else str
  }

  format_arg_default <- function(value_str) {
    vs <- trimws(value_str %||% "")
    if (!nzchar(vs)) return("")
    # Prefer a scalar display when default was already a vector/c(...)
    parsed <- tryCatch(eval(parse(text = vs), envir = baseenv()), error = function(e) NULL)
    if (is.numeric(parsed) && length(parsed) >= 1L) {
      v <- parsed[[1L]]
      if (abs(v - round(v)) < 1e-6) return(as.character(as.integer(round(v))))
      return(as.character(round(v, 4)))
    }
    if (is.atomic(parsed) && length(parsed) >= 1L) return(as.character(parsed[[1L]]))
    vs
  }

  tip_title <- function(tip) {
    tip <- trimws(tip %||% "")
    ex <- "Range example: 0, 10, 20"
    if (nzchar(tip) && !is.na(tip)) paste0(tip, "\n", ex) else ex
  }

  collect_mod_dots <- function(id) {
    args <- ResearchDesigns::get_args(id)
    if (!nrow(args)) {
      return(list(dots = list(), exprs = list(), lengths = integer(0), range_params = character(0)))
    }
    dots <- list()
    exprs <- list()
    lengths <- integer(0)
    for (i in seq_len(nrow(args))) {
      nm <- args$name[[i]]
      raw <- trimws(input[[paste0("mod_val_", nm)]] %||% "")
      if (!nzchar(raw)) next
      def <- format_arg_default(args$value_str[[i]])
      # Skip unchanged scalars to keep code preview tidy
      if (identical(raw, def) || identical(raw, trimws(args$value_str[[i]] %||% ""))) next
      expr <- normalize_value_expression(raw)
      val <- tryCatch(
        eval(parse(text = expr), envir = baseenv()),
        error = function(e) e
      )
      if (inherits(val, "error")) {
        return(list(error = paste0("Could not parse ", nm, ": ", conditionMessage(val))))
      }
      dots[[nm]] <- val
      exprs[[nm]] <- if (length(val) > 1L && !grepl("^c\\s*\\(", raw) && !grepl("^seq\\s*\\(", raw)) {
        paste0("c(", paste(as.character(val), collapse = ", "), ")")
      } else {
        expr
      }
      lengths[[nm]] <- length(val)
    }
    range_params <- names(lengths)[lengths > 1L]
    list(dots = dots, exprs = exprs, lengths = lengths, range_params = range_params)
  }

  is_template_category <- function(cat) {
    tolower(trimws(as.character(cat %||% ""))) %in% c("template", "templates")
  }

  cats <- sort(unique(as.character(idx_all$category %||% "Other")))
  cats <- c(cats[is_template_category(cats)], cats[!is_template_category(cats)])
  updateSelectInput(
    session, "lib_category",
    choices = c("All categories" = "all", stats::setNames(cats, cats)),
    selected = "all"
  )

  filtered_idx <- reactive({
    df <- as.data.frame(idx_all)
    cat_sel <- input$lib_category %||% "all"
    if (!identical(cat_sel, "all")) {
      df <- df[df$category == cat_sel, , drop = FALSE]
    }
    q <- trimws(input$lib_search %||% "")
    if (nzchar(q)) {
      hay <- tolower(paste(
        df$id, df$alias %||% "", df$label %||% "", df$params %||% "",
        df$packages %||% "", df$keywords %||% "", df$category %||% "",
        sep = " "
      ))
      df <- df[grepl(tolower(q), hay, fixed = TRUE), , drop = FALSE]
    }
    # Template category first, then other categories, then label
    if (nrow(df)) {
      o <- order(
        !is_template_category(df$category),
        as.character(df$category),
        as.character(df$label)
      )
      df <- df[o, , drop = FALSE]
      rownames(df) <- NULL
    }
    df
  })

  library_display <- reactive({
    df <- filtered_idx()
    data.frame(
      label = df$label,
      id = df$id,
      alias = df$alias,
      category = df$category,
      params = df$params,
      packages = df$packages,
      stringsAsFactors = FALSE
    )
  })

  go_to_design <- function(id) {
    if (is.null(id) || is.na(id) || !nzchar(id)) return()
    selected_id(id)
    live_diag(NULL)
    mod_diag(NULL)
    mod_last_ranges(character(0))
    mod_status("")
    run_once_txt("")
    if (has_bslib) {
      bslib::nav_select("main_nav", selected = "Design", session = session)
    } else {
      updateTabsetPanel(session, "main_nav", selected = "Design")
    }
  }

  if (has_dt) {
    output$library_table <- DT::renderDT({
      DT::datatable(
        library_display(),
        selection = "single",
        rownames = FALSE,
        class = "display nowrap",
        options = list(
          pageLength = 100,
          lengthChange = FALSE,
          autoWidth = FALSE,
          scrollX = TRUE,
          order = list(),  # keep template-first row order from filtered_idx()
          ordering = TRUE,
          columnDefs = list(
            list(width = "30%", targets = 0),  # label
            list(width = "14%", targets = 1),  # id
            list(width = "7%", targets = 2),   # alias
            list(width = "12%", targets = 3),  # category
            list(width = "20%", targets = 4),  # params
            list(width = "17%", targets = 5)   # packages
          ),
          # Hide Previous/Next when everything fits on one page
          drawCallback = DT::JS(
            "function(settings) {",
            "  var api = this.api();",
            "  var pages = api.page.info().pages;",
            "  var $pag = $(api.table().container()).find('.dataTables_paginate');",
            "  if (pages <= 1) { $pag.hide(); } else { $pag.show(); }",
            "}"
          )
        )
      )
    })
  } else {
    output$library_table_basic <- renderTable({
      library_display()
    })
  }

  observeEvent(input$library_table_rows_selected, {
    rows <- input$library_table_rows_selected
    df <- library_display()
    if (length(rows) && rows[[1]] <= nrow(df)) {
      go_to_design(df$id[[rows[[1]]]])
    }
  }, ignoreNULL = TRUE)

  selected_header_ui <- function() {
    id <- selected_id()
    if (is.na(id) || !nzchar(id)) {
      return(div(class = "rd-card", p("Open a design from the Library tab.")))
    }
    info <- ResearchDesigns::design_info(id)
    div(
      class = "rd-selected-banner",
      div(
        h3(style = "margin: 0;", info$label %||% id),
        p(
          class = "rd-muted", style = "margin: 0.2rem 0 0;",
          id,
          if (!is.null(info$alias) && !is.na(info$alias)) paste0(' · alias "', info$alias, '"') else NULL,
          " · ", info$category %||% "Other"
        )
      ),
      actionButton("back_library", "Back to library", class = "btn-outline-secondary btn-sm")
    )
  }

  output$selected_header <- renderUI(selected_header_ui())
  output$selected_header_diag <- renderUI(selected_header_ui())

  go_to_library <- function() {
    if (has_bslib) {
      bslib::nav_select("main_nav", selected = "Library", session = session)
    } else {
      updateTabsetPanel(session, "main_nav", selected = "Library")
    }
  }

  observeEvent(input$back_library, go_to_library())
  observeEvent(input$goto_library_from_mod, go_to_library())

  output$redesign_top <- renderUI({
    id <- selected_id()
    if (is.na(id) || !nzchar(id)) {
      return(div(
        class = "rd-card",
        p(
          "First open a design from the ",
          actionLink("goto_library_from_mod", "Library"),
          ", then come back here to change parameters and re-diagnose."
        )
      ))
    }
    tagList(
      selected_header_ui(),
      div(
        class = "rd-card",
        div(
          class = "rd-help-box",
          HTML(paste0(
            "Edit parameters below. Use a <strong>comma-separated range</strong> ",
            "like <code>0, 10, 20</code> on at most <strong>two</strong> parameters."
          ))
        ),
        uiOutput("mod_param_grid"),
        fluidRow(
          column(3, numericInput("mod_sims", "Simulations", value = 50, min = 1, step = 10, width = "100%")),
          column(
            9,
            div(
              style = "margin-top: 1.7rem; display: flex; gap: 0.5rem; flex-wrap: wrap;",
              actionButton("run_redesign", "Run redesign and diagnosis", class = "btn-primary"),
              actionButton("reset_mods", "Reset", class = "btn-outline-secondary btn-sm")
            )
          )
        )
      )
    )
  })

  output$mod_show_results <- reactive(!is.null(mod_diag()))
  outputOptions(output, "mod_show_results", suspendWhenHidden = FALSE)

  output$design_profile_text <- renderText({
    id <- selected_id()
    req(!is.na(id), nzchar(id))
    ResearchDesigns::design_profile(id)
  })

  output$simple_code <- renderText({
    id <- selected_id()
    req(!is.na(id), nzchar(id))
    ResearchDesigns::get_code(id, style = "simple")
  })

  output$full_code <- renderText({
    id <- selected_id()
    req(!is.na(id), nzchar(id))
    ResearchDesigns::get_code(id, style = "full")
  })

  output$args_table <- renderTable({
    id <- selected_id()
    req(!is.na(id), nzchar(id))
    args <- ResearchDesigns::get_args(id)
    data.frame(name = args$name, default = args$value_str, tip = args$tip, stringsAsFactors = FALSE)
  })

  observeEvent(input$run_once, {
    id <- selected_id()
    req(!is.na(id))
    out <- tryCatch({
      d <- ResearchDesigns::make_design(id)
      run <- DeclareDesignZero::run_design(d)
      paste(utils::capture.output(print(run)), collapse = "\n")
    }, error = function(e) paste("Error:", conditionMessage(e)))
    run_once_txt(out)
  })

  output$run_once_out <- renderText(run_once_txt())

  # ---- Diagnosis ----
  current_diagnosis <- reactive({
    id <- selected_id()
    req(!is.na(id), nzchar(id))
    live <- live_diag()
    if (!is.null(live)) return(live)
    ResearchDesigns::get_preview(id)
  })

  output$preview_status <- renderUI({
    id <- selected_id()
    if (is.na(id) || !nzchar(id)) return(NULL)
    if (!is.null(live_diag())) {
      return(p(tags$strong("Showing: "), "live diagnosis from this session."))
    }
    prev <- ResearchDesigns::get_preview(id)
    if (is.null(prev)) {
      p(class = "rd-muted", "No baked preview yet. Click “Run diagnosis”, or ask a maintainer to run refresh_library().")
    } else {
      p(tags$strong("Showing: "), sprintf("baked preview (%s sims).", prev$sims %||% "?"))
    }
  })

  observeEvent(input$run_diagnosis, {
    id <- selected_id()
    req(!is.na(id))
    sims <- as.integer(input$diag_sims %||% 100)
    withProgress(message = "Diagnosing…", value = 0.3, {
      res <- tryCatch({
        d <- ResearchDesigns::make_design(id)
        diagnosis <- DeclareDesignZero::diagnose_design(d, sims = sims)
        summary <- tryCatch(DeclareDesignZero::get_diagnosands(diagnosis), error = function(e) NULL)
        tidy <- tryCatch(generics::tidy(diagnosis), error = function(e) NULL)
        list(id = id, sims = sims, summary = summary, tidy = tidy, diagnosis = diagnosis, live = TRUE)
      }, error = function(e) e)
      if (inherits(res, "error")) {
        showNotification(conditionMessage(res), type = "error")
      } else {
        live_diag(res)
        showNotification("Diagnosis complete.", type = "message")
      }
    })
  })

  diagnosand_df <- function(obj) {
    if (is.null(obj)) return(NULL)
    if (!is.null(obj$tidy) && is.data.frame(obj$tidy) && nrow(obj$tidy) &&
        "diagnosand" %in% names(obj$tidy)) {
      return(obj$tidy)
    }
    if (!is.null(obj$diagnosis)) {
      tidy <- tryCatch(generics::tidy(obj$diagnosis), error = function(e) NULL)
      if (is.null(tidy)) {
        tidy <- tryCatch(DeclareDesignZero::tidy.diagnosis(obj$diagnosis), error = function(e) NULL)
      }
      if (!is.null(tidy) && is.data.frame(tidy) && nrow(tidy)) return(tidy)
    }
    if (!is.null(obj$summary) && is.data.frame(obj$summary) && nrow(obj$summary) &&
        "diagnosand" %in% names(obj$summary)) {
      return(obj$summary)
    }
    if (!is.null(obj$summary) && is.data.frame(obj$summary) && nrow(obj$summary)) {
      return(obj$summary)
    }
    NULL
  }

  default_diagnosands <- function(all_names) {
    all_names <- unique(as.character(all_names))
    prefer <- c("bias", "power")
    hit <- all_names[tolower(all_names) %in% prefer]
    if (length(hit)) return(hit)
    utils::head(all_names, 2L)
  }

  y_value_col <- function(df) {
    if ("estimate" %in% names(df)) return("estimate")
    if ("mean" %in% names(df)) return("mean")
    if ("estimand" %in% names(df) && is.numeric(df$estimand)) return("estimand")
    NULL
  }

  # DeclareDesignZero tidy() gives estimate + se(<diagnosand>), not conf.low/high
  add_diagnosand_ci <- function(df, z = 1.96) {
    if (is.null(df) || !nrow(df)) return(df)
    if (!"estimate" %in% names(df) && "mean" %in% names(df)) {
      df$estimate <- df$mean
    }
    if (!all(c("diagnosand", "estimate") %in% names(df))) return(df)
    if (all(c("conf.low", "conf.high") %in% names(df))) {
      # Still fill any missing CI from se(...) when possible
      need <- is.na(df$conf.low) | is.na(df$conf.high)
      if (!any(need)) return(df)
    } else {
      df$conf.low <- NA_real_
      df$conf.high <- NA_real_
      need <- rep(TRUE, nrow(df))
    }

    se <- vapply(seq_len(nrow(df)), function(i) {
      if (!isTRUE(need[[i]])) return(NA_real_)
      d <- as.character(df$diagnosand[[i]])
      col <- paste0("se(", d, ")")
      if (col %in% names(df)) {
        v <- suppressWarnings(as.numeric(df[[col]][[i]]))
        if (length(v) && is.finite(v)) return(v)
      }
      for (alt in c("std.error", "se", "std_error")) {
        if (alt %in% names(df)) {
          v <- suppressWarnings(as.numeric(df[[alt]][[i]]))
          if (length(v) && is.finite(v)) return(v)
        }
      }
      NA_real_
    }, numeric(1))

    fill <- need & is.finite(se) & is.finite(df$estimate)
    df$conf.low[fill] <- df$estimate[fill] - z * se[fill]
    df$conf.high[fill] <- df$estimate[fill] + z * se[fill]
    df
  }

  # Forest-style panels (original wizard diagnosis plot) when no parameter ranges
  plot_diagnosand_forest <- function(df) {
    df <- add_diagnosand_ci(df)
    if (!"estimate" %in% names(df) && "mean" %in% names(df)) {
      df$estimate <- df$mean
    }
    if (!"estimate" %in% names(df) || !"diagnosand" %in% names(df)) return(NULL)

    inquiry_col <- if ("inquiry" %in% names(df)) "inquiry" else NULL
    est_col <- if ("estimator" %in% names(df)) {
      "estimator"
    } else if ("estimator_label" %in% names(df)) {
      "estimator_label"
    } else {
      NULL
    }
    term_col <- if ("term" %in% names(df)) "term" else NULL
    n_est <- if (!is.null(est_col)) length(unique(df[[est_col]])) else 0L
    n_term <- if (!is.null(term_col)) length(unique(df[[term_col]])) else 0L

    if (is.null(est_col)) {
      df$.y <- "estimate"
    } else if (n_est > 1L && n_term > 1L && !is.null(term_col)) {
      df$.y <- paste(df[[est_col]], "-", df[[term_col]])
    } else if (n_term > 1L && !is.null(term_col)) {
      df$.y <- as.character(df[[term_col]])
    } else {
      df$.y <- as.character(df[[est_col]])
    }

    has_ci <- all(c("conf.low", "conf.high") %in% names(df)) &&
      any(is.finite(df$conf.low) & is.finite(df$conf.high))
    df$diagnosand <- factor(df$diagnosand, levels = unique(as.character(df$diagnosand)))

    use_color <- !is.null(inquiry_col) && length(unique(df[[inquiry_col]])) > 1L
    # Also dodge when several series share a y-level (e.g. color by inquiry)
    n_per_y <- as.integer(table(paste(df$diagnosand, df$.y, sep = "\r")))
    need_dodge <- use_color || any(n_per_y > 1L)
    pd <- if (need_dodge) ggplot2::position_dodge(width = 0.5) else "identity"

    if (use_color) {
      df$.inquiry <- df[[inquiry_col]]
      p <- ggplot2::ggplot(df, ggplot2::aes(x = estimate, y = .y, color = .inquiry, group = .inquiry))
    } else {
      p <- ggplot2::ggplot(df, ggplot2::aes(x = estimate, y = .y))
    }
    if (has_ci) {
      p <- p + ggplot2::geom_errorbarh(
        ggplot2::aes(xmin = conf.low, xmax = conf.high),
        height = 0.25,
        position = pd,
        na.rm = TRUE
      )
    }
    p <- p +
      ggplot2::geom_point(size = 2.4, position = pd) +
      ggplot2::facet_wrap(~diagnosand, scales = "free_x", ncol = 2) +
      ggplot2::theme_bw(base_size = 12) +
      ggplot2::labs(x = NULL, y = NULL, color = NULL)

    n_y <- length(unique(df$.y))
    if (n_y <= 1L) {
      p <- p + ggplot2::theme(
        axis.text.y = ggplot2::element_blank(),
        axis.ticks.y = ggplot2::element_blank()
      )
    }
    p
  }

  # Dodge width in x-data units when x is numeric; otherwise a fraction of a category
  dodge_width_for_x <- function(x) {
    x <- x[is.finite(as.numeric(x))]
    if (!length(x)) return(0.4)
    if (is.numeric(x) || is.integer(x)) {
      u <- sort(unique(as.numeric(x)))
      if (length(u) >= 2L) return(0.25 * min(diff(u)))
      return(0.1)
    }
    0.4
  }

  output$diagnosis_table <- renderTable({
    diagnosand_df(current_diagnosis())
  })

  if (has_ggplot2) {
    output$diagnosis_plot <- renderPlot({
      df <- diagnosand_df(current_diagnosis())
      if (is.null(df) || !nrow(df)) {
        plot.new()
        text(0.5, 0.5, "No diagnosis to plot yet.")
        return(invisible())
      }
      p <- plot_diagnosand_forest(df)
      if (is.null(p)) {
        plot.new()
        text(0.5, 0.5, "Diagnosis loaded; see table for values.")
        return(invisible())
      }
      p
    })
  }

  # ---- Redesign ----
  output$mod_param_grid <- renderUI({
    id <- selected_id()
    if (is.na(id) || !nzchar(id)) return(NULL)
    args <- ResearchDesigns::get_args(id)
    if (!nrow(args)) return(helpText("No modifiable parameters."))
    rows <- lapply(seq_len(nrow(args)), function(i) {
      nm <- args$name[[i]]
      tip <- tip_title(args$tip[[i]])
      tagList(
        tags$div(class = "rd-param-name", nm),
        tags$span(class = "rd-tip", title = tip, "i"),
        textInput(
          inputId = paste0("mod_val_", nm),
          label = NULL,
          value = format_arg_default(args$value_str[[i]]),
          width = "100%",
          placeholder = "e.g. 100 or 0, 10, 20"
        )
      )
    })
    div(class = "rd-param-grid", rows)
  })

  current_mod_state <- reactive({
    id <- selected_id()
    req(!is.na(id), nzchar(id))
    args <- ResearchDesigns::get_args(id)
    lapply(args$name, function(nm) input[[paste0("mod_val_", nm)]])
    collect_mod_dots(id)
  })

  output$mod_error <- renderUI({
    msg <- mod_status()
    if (!nzchar(msg %||% "")) return(NULL)
    div(class = "rd-error", msg)
  })

  output$mod_diagnosand_ui <- renderUI({
    df <- diagnosand_df(mod_diag())
    if (is.null(df) || !"diagnosand" %in% names(df)) return(NULL)
    all_d <- unique(as.character(df$diagnosand))
    sel <- input$mod_diagnosands
    if (is.null(sel) || !length(intersect(sel, all_d))) sel <- default_diagnosands(all_d)
    selectInput(
      "mod_diagnosands",
      "Diagnosands",
      choices = all_d,
      selected = sel,
      multiple = TRUE,
      width = "100%"
    )
  })

  output$mod_plot_controls <- renderUI({
    st <- tryCatch(current_mod_state(), error = function(e) NULL)
    rp <- mod_last_ranges()
    if (!length(rp)) rp <- st$range_params %||% character(0)
    if (length(rp) != 2L) return(NULL)
    fluidRow(
      column(6, selectInput("mod_plot_x", "X-axis", choices = rp, selected = input$mod_plot_x %||% rp[[1]], width = "100%")),
      column(6, selectInput("mod_plot_group", "Group / color", choices = rp, selected = input$mod_plot_group %||% rp[[2]], width = "100%"))
    )
  })

  observeEvent(input$reset_mods, {
    id <- selected_id()
    req(!is.na(id))
    args <- ResearchDesigns::get_args(id)
    for (i in seq_len(nrow(args))) {
      updateTextInput(
        session,
        paste0("mod_val_", args$name[[i]]),
        value = format_arg_default(args$value_str[[i]])
      )
    }
    mod_diag(NULL)
    mod_last_ranges(character(0))
    mod_status("")
  })

  observeEvent(input$run_redesign, {
    id <- selected_id()
    req(!is.na(id))
    sims <- as.integer(input$mod_sims %||% 50)
    if (is.na(sims) || sims < 1L) sims <- 50L
    st <- collect_mod_dots(id)
    if (!is.null(st$error)) {
      mod_status(st$error)
      return()
    }
    if (length(st$range_params) > 2L) {
      mod_status(paste0(
        "At most two parameters may be given a range. You have ranges for: ",
        paste(st$range_params, collapse = ", "), "."
      ))
      return()
    }
    mod_status("")
    withProgress(message = "Redesign + diagnosis…", value = 0.2, {
      res <- tryCatch({
        design <- do.call(ResearchDesigns::make_design, c(list(design = id), st$dots))
        diagnosis <- DeclareDesignZero::diagnose_design(design, sims = sims)
        tidy <- tryCatch(generics::tidy(diagnosis), error = function(e) NULL)
        if (is.null(tidy)) {
          tidy <- tryCatch(DeclareDesignZero::tidy.diagnosis(diagnosis), error = function(e) NULL)
        }
        summary <- tryCatch(DeclareDesignZero::get_diagnosands(diagnosis), error = function(e) NULL)
        list(
          id = id,
          sims = sims,
          tidy = tidy,
          summary = summary,
          diagnosis = diagnosis,
          range_params = st$range_params,
          plot_x = input$mod_plot_x %||% (st$range_params[1] %||% NA_character_),
          plot_group = input$mod_plot_group %||% (st$range_params[2] %||% NA_character_)
        )
      }, error = function(e) e)

      if (!inherits(res, "error")) {
        mod_diag(res)
        mod_last_ranges(st$range_params)
        mod_status("")
      } else {
        mod_status(paste("Error:", conditionMessage(res)))
      }
    })
  })

  filtered_mod_df <- reactive({
    df <- diagnosand_df(mod_diag())
    if (is.null(df) || !nrow(df)) return(NULL)
    if ("diagnosand" %in% names(df)) {
      all_d <- unique(as.character(df$diagnosand))
      sel <- input$mod_diagnosands
      if (is.null(sel) || !length(sel)) sel <- default_diagnosands(all_d)
      sel <- intersect(sel, all_d)
      if (length(sel)) df <- df[as.character(df$diagnosand) %in% sel, , drop = FALSE]
    }
    df
  })

  output$mod_table <- renderTable({
    filtered_mod_df()
  })

  if (has_ggplot2) {
    output$mod_plot <- renderPlot({
      obj <- mod_diag()
      df <- filtered_mod_df()
      if (is.null(df) || !nrow(df)) {
        plot.new()
        text(0.5, 0.5, "Run redesign and diagnosis to plot.")
        return(invisible())
      }
      if (!"diagnosand" %in% names(df)) {
        plot.new()
        text(0.5, 0.5, "Diagnosis loaded; open the table below.")
        return(invisible())
      }

      ranges <- obj$range_params %||% mod_last_ranges()
      ranges <- ranges[ranges %in% names(df)]

      # No ranges: forest / CI panels like the original diagnosis plot
      if (length(ranges) == 0L) {
        p <- plot_diagnosand_forest(df)
        if (is.null(p)) {
          plot.new()
          text(0.5, 0.5, "Diagnosis loaded; open the table below.")
          return(invisible())
        }
        return(p)
      }

      y_col <- y_value_col(df)
      if (is.null(y_col)) {
        plot.new()
        text(0.5, 0.5, "Diagnosis loaded; open the table below.")
        return(invisible())
      }
      df <- add_diagnosand_ci(df)
      df$.y <- df[[y_col]]
      df$diagnosand <- factor(df$diagnosand)
      has_ci <- all(c("conf.low", "conf.high") %in% names(df)) &&
        any(is.finite(df$conf.low) & is.finite(df$conf.high))

      if (length(ranges) == 1L) {
        xp <- ranges[[1]]
        df$.x <- df[[xp]]
        # Color by estimator when several share an x-value
        est_col <- if ("estimator" %in% names(df)) "estimator" else NULL
        use_color <- !is.null(est_col) && length(unique(df[[est_col]])) > 1L
        if (use_color) {
          df$.series <- factor(df[[est_col]])
          p <- ggplot2::ggplot(df, ggplot2::aes(x = .x, y = .y, color = .series, group = .series))
        } else {
          p <- ggplot2::ggplot(df, ggplot2::aes(x = .x, y = .y, group = 1))
        }
        pd <- if (use_color) {
          ggplot2::position_dodge(width = dodge_width_for_x(df$.x))
        } else {
          "identity"
        }
        if (has_ci) {
          p <- p + ggplot2::geom_errorbar(
            ggplot2::aes(ymin = conf.low, ymax = conf.high),
            width = 0,
            size = 0.5,
            position = pd,
            na.rm = TRUE
          )
        }
        p +
          ggplot2::geom_line(size = 0.8, position = pd) +
          ggplot2::geom_point(size = 2.2, position = pd) +
          ggplot2::facet_wrap(~diagnosand, scales = "free_y") +
          ggplot2::theme_bw(base_size = 12) +
          ggplot2::labs(x = xp, y = y_col, color = if (use_color) "estimator" else NULL)
      } else {
        xp <- input$mod_plot_x %||% obj$plot_x %||% ranges[[1]]
        gp <- input$mod_plot_group %||% obj$plot_group %||% ranges[[2]]
        if (!xp %in% names(df)) xp <- ranges[[1]]
        if (!gp %in% names(df)) gp <- setdiff(ranges, xp)[1]
        if (identical(xp, gp)) gp <- setdiff(ranges, xp)[1]
        df$.x <- df[[xp]]
        df$.g <- factor(df[[gp]])
        pd <- ggplot2::position_dodge(width = dodge_width_for_x(df$.x))
        p <- ggplot2::ggplot(df, ggplot2::aes(x = .x, y = .y, color = .g, group = .g))
        if (has_ci) {
          p <- p + ggplot2::geom_errorbar(
            ggplot2::aes(ymin = conf.low, ymax = conf.high),
            width = 0,
            size = 0.5,
            position = pd,
            na.rm = TRUE
          )
        }
        p +
          ggplot2::geom_line(size = 0.8, position = pd) +
          ggplot2::geom_point(size = 2.2, position = pd) +
          ggplot2::facet_wrap(~diagnosand, scales = "free_y") +
          ggplot2::theme_bw(base_size = 12) +
          ggplot2::labs(x = xp, y = y_col, color = gp)
      }
    })
  }
}

shinyApp(ui, server)
