# Default metadata when a design file has little or no YAML.
# The design object remains the source of truth for parameters.

#' @noRd
default_meta <- function(id) {
  list(
    id = id,
    alias = NA_character_,
    object = "design",
    label = humanize_id(id),
    description = NA_character_,
    category = "Other",
    keywords = character(0),
    packages = character(0),
    diagnosands = character(0),
    include_in_shiny = TRUE,
    functional = TRUE,
    book_link = NA_character_,
    params = list()
  )
}

#' Coerce YAML truthy / falsey scalars
#' @noRd
yaml_is_true <- function(x, default = FALSE) {
  if (is.null(x) || length(x) == 0L || (length(x) == 1L && is.na(x))) {
    return(isTRUE(default))
  }
  if (is.logical(x)) return(isTRUE(x[[1]]))
  identical(tolower(trimws(as.character(x)[[1]])), "true")
}

#' Split optional YAML frontmatter from an R design file
#'
#' Files may begin with a YAML block delimited by `---` lines. Everything
#' after the closing `---` is R code. Files with no frontmatter are valid.
#'
#' @param path Path to a `.R` design file.
#' @return List with `meta` (list) and `code` (character scalar).
#' @noRd
parse_design_file <- function(path) {
  if (!file.exists(path)) {
    stop("Design file not found: ", path, call. = FALSE)
  }
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  if (length(lines) == 0L) {
    stop("Design file is empty: ", path, call. = FALSE)
  }

  id_guess <- sub("\\.R$", "", basename(path), ignore.case = TRUE)
  meta <- default_meta(id_guess)
  code_lines <- lines

  if (grepl("^---\\s*$", lines[[1]])) {
    end <- which(grepl("^---\\s*$", lines))[-1]
    if (length(end) == 0L) {
      stop("YAML frontmatter opened but not closed in: ", path, call. = FALSE)
    }
    yaml_text <- paste(lines[seq.int(2L, end[[1]] - 1L)], collapse = "\n")
    code_lines <- if (end[[1]] < length(lines)) {
      lines[seq.int(end[[1]] + 1L, length(lines))]
    } else {
      character(0)
    }
    parsed <- tryCatch(
      yaml_load_design_meta(yaml_text),
      error = function(e) {
        stop(
          "Invalid YAML in ", path, ": ", conditionMessage(e),
          "\nTip: always quote parameter names, e.g. \"N\": \"Sample size\" (YAML treats bare N/n/Y/y as booleans).",
          call. = FALSE
        )
      }
    )
    if (!is.null(parsed) && length(parsed)) {
      meta <- merge_meta(meta, parsed, id_guess = id_guess)
    }
  }

  if (is.null(meta$id) || !nzchar(as.character(meta$id)[[1]])) {
    meta$id <- id_guess
  }
  meta$id <- as.character(meta$id)[[1]]

  list(
    path = normalizePath(path, winslash = "/", mustWork = TRUE),
    meta = meta,
    code = paste(code_lines, collapse = "\n")
  )
}

#' Merge user YAML onto defaults
#' @noRd
merge_meta <- function(defaults, parsed, id_guess) {
  out <- defaults
  if (!is.null(parsed$id)) out$id <- as.character(parsed$id)[[1]]
  if (!is.null(parsed$alias)) out$alias <- as.character(parsed$alias)[[1]]
  if (!is.null(parsed$object)) out$object <- as.character(parsed$object)[[1]]
  if (!is.null(parsed$label)) out$label <- as.character(parsed$label)[[1]]
  if (!is.null(parsed$description)) {
    out$description <- as.character(parsed$description)[[1]]
  }
  if (!is.null(parsed$category)) out$category <- as.character(parsed$category)[[1]]
  if (!is.null(parsed$keywords)) out$keywords <- as_chr(parsed$keywords)
  if (!is.null(parsed$packages)) out$packages <- as_chr(parsed$packages)
  if (!is.null(parsed$diagnosands)) out$diagnosands <- normalize_diagnosands(parsed$diagnosands)
  # functional: false parks a design (unavailable deps, WIP). Also accept `function:`.
  if (!is.null(parsed$functional)) {
    out$functional <- yaml_is_true(parsed$functional, default = TRUE)
  } else if (!is.null(parsed[["function"]])) {
    out$functional <- yaml_is_true(parsed[["function"]], default = TRUE)
  }
  if (!is.null(parsed$include_in_shiny)) {
    out$include_in_shiny <- yaml_is_true(parsed$include_in_shiny, default = TRUE)
  }
  # Disabled designs stay out of Shiny even if include_in_shiny was true
  if (!isTRUE(out$functional)) {
    out$include_in_shiny <- FALSE
  }
  if (!is.null(parsed$book_link)) {
    out$book_link <- as.character(parsed$book_link)[[1]]
  }
  if (!is.null(parsed$params) && is.list(parsed$params)) {
    out$params <- normalize_params_map(parsed$params)
  }
  if (is.null(out$label) || !nzchar(as.character(out$label)[[1]])) {
    out$label <- humanize_id(out$id %||% id_guess)
  }
  out
}

#' Load design YAML with safer booleans for param keys like N/n
#' @noRd
yaml_load_design_meta <- function(yaml_text) {
  # YAML 1.1 treats N/n/Y/y as booleans; keep them as strings when possible.
  handlers <- list(
    "bool#yes" = function(x) x,
    "bool#no" = function(x) x
  )
  yaml::yaml.load(yaml_text, handlers = handlers)
}

#' Coerce YAML diagnosands to a character vector
#'
#' Accepts a YAML list (`[bias, power]`), a scalar (`bias`), or a
#' comma/semicolon-separated string (`"rmse, bias"`). Tokens starting with
#' `-` (e.g. `-bias`) are kept as exclusions for the display list.
#' @noRd
normalize_diagnosands <- function(x) {
  if (is.null(x) || (length(x) == 1L && is.na(x))) return(character(0))
  ch <- as_chr(x)
  parts <- unlist(strsplit(ch, "[,;]+"), use.names = FALSE)
  parts <- trimws(as.character(parts))
  parts[nzchar(parts)]
}

#' Split diagnosand tokens into preferred and excluded names
#'
#' Positive tokens (e.g. `rmse`) are preferred defaults. Tokens that start
#' with `-` (e.g. `-bias`) exclude that diagnosand from the display list.
#' @param tokens Character vector from YAML `diagnosands:`.
#' @return List with `prefer` and `exclude` character vectors.
#' @noRd
split_diagnosand_tokens <- function(tokens) {
  tokens <- as.character(tokens %||% character(0))
  tokens <- trimws(tokens)
  tokens <- tokens[nzchar(tokens)]
  is_excl <- startsWith(tokens, "-")
  prefer <- tokens[!is_excl]
  exclude <- sub("^-", "", tokens[is_excl])
  exclude <- exclude[nzchar(exclude)]
  list(prefer = prefer, exclude = unique(exclude))
}

#' Coerce YAML params to a named list of tip strings
#'
#' Preferred form (always quote keys; YAML treats bare N/n/Y/y as booleans):
#' ```yaml
#' params:
#'   "N": "Number of units"
#'   "b": "Treatment effect size"
#' ```
#' Nested `{ tip: "..." }` is also accepted for compatibility.
#' @noRd
normalize_params_map <- function(params) {
  if (is.null(params) || !length(params)) return(list())
  out <- list()
  nms <- names(params)
  if (is.null(nms)) nms <- rep("", length(params))
  # Recover if keys were coerced to logical (FALSE/TRUE from N/n/Y/y)
  if (is.logical(nms)) {
    nms <- ifelse(is.na(nms), "", ifelse(nms, "Y", "N"))
  }
  nms <- as.character(nms)
  for (i in seq_along(params)) {
    nm <- nms[[i]]
    if (!nzchar(nm)) next
    entry <- params[[i]]
    if (is.null(entry)) {
      out[[nm]] <- NA_character_
    } else if (is.character(entry) || is.numeric(entry) || is.logical(entry)) {
      out[[nm]] <- as.character(entry)[[1]]
    } else if (is.list(entry)) {
      tip <- entry$tip %||% entry$tips %||% entry$description %||% entry[[1]]
      out[[nm]] <- if (is.null(tip)) NA_character_ else as.character(tip)[[1]]
    } else {
      out[[nm]] <- as.character(entry)[[1]]
    }
  }
  out
}

#' List design file paths in the package library
#' @noRd
design_files <- function(dir = designs_dir()) {
  if (!dir.exists(dir)) return(character(0))
  sort(list.files(dir, pattern = "\\.[Rr]$", full.names = TRUE))
}
