#' Resolve a design id or book alias to a parsed file
#' @noRd
resolve_design <- function(design) {
  key <- normalize_design_key(design)
  files <- design_files()
  if (!length(files)) {
    stop("No designs found in ", designs_dir(), call. = FALSE)
  }

  parsed_all <- lapply(files, parse_design_file)
  ids <- vapply(parsed_all, function(x) x$meta$id, character(1))
  aliases <- vapply(parsed_all, function(x) {
    a <- x$meta$alias
    if (is.null(a) || (length(a) == 1L && is.na(a))) "" else as.character(a)[[1]]
  }, character(1))

  hit <- which(ids == key | aliases == key | basename_id(files) == key)
  if (!length(hit)) {
    stop(
      "Unknown design '", key, "'. ",
      "See list_designs() for ids and aliases.",
      call. = FALSE
    )
  }
  if (length(hit) > 1L) {
    stop(
      "Design key '", key, "' matches multiple files: ",
      paste(basename(files[hit]), collapse = ", "),
      call. = FALSE
    )
  }
  parsed_all[[hit[[1]]]]
}

#' @noRd
basename_id <- function(paths) {
  sub("\\.[Rr]$", "", basename(paths))
}

#' @noRd
normalize_design_key <- function(design) {
  if (is.null(design)) stop("design id/alias is required", call. = FALSE)
  if (is.symbol(design) || is.name(design)) {
    return(as.character(design))
  }
  if (is.character(design) && length(design) >= 1L && nzchar(design[[1]])) {
    return(as.character(design[[1]]))
  }
  # Allow declaration_2.1 style names passed unquoted via substitute in wrappers
  stop("design must be a character id/alias (e.g. \"two_arm_trial\" or \"2.1\")", call. = FALSE)
}

#' Source a parsed design file and return the design object
#' @noRd
eval_design <- function(parsed) {
  pkgs <- unique(c(core_packages(), parsed$meta$packages %||% character(0)))
  missing <- ensure_packages_attached(pkgs)
  if (length(missing)) {
    stop(
      "Design '", parsed$meta$id, "' needs packages not installed: ",
      paste(missing, collapse = ", "),
      call. = FALSE
    )
  }

  env <- new.env(parent = globalenv())
  expr <- parse(text = parsed$code, keep.source = TRUE)
  eval(expr, envir = env)

  obj_name <- parsed$meta$object %||% "design"
  if (!exists(obj_name, envir = env, inherits = FALSE)) {
    # Fallbacks: id, then sole design-looking object
    if (exists(parsed$meta$id, envir = env, inherits = FALSE)) {
      obj_name <- parsed$meta$id
    } else {
      stop(
        "Object '", parsed$meta$object, "' not found after sourcing ",
        basename(parsed$path), ". Set `object:` in YAML or name it `design`.",
        call. = FALSE
      )
    }
  }

  design <- get(obj_name, envir = env, inherits = FALSE)
  attr(design, "research_designs_id") <- parsed$meta$id
  attr(design, "research_designs_alias") <- parsed$meta$alias
  attr(design, "research_designs_path") <- parsed$path
  design
}

#' List designs in the library
#'
#' Returns a data frame of design metadata. Printing shows a compact summary
#' (`id`, `alias`, modifiable parameters). Use [design_info()], [get_args()],
#' or `as.data.frame()` / `print(as.data.frame(x))` for the full table.
#'
#' @param shiny_only If `TRUE`, only designs with `include_in_shiny: true`
#'   (the default when the field is omitted).
#' @param discover_params If `TRUE` (default), load each design once to list
#'   redesignable parameters. Set `FALSE` for a metadata-only scan.
#' @return A data frame with class `research_designs_list`.
#' @export
list_designs <- function(shiny_only = FALSE, discover_params = TRUE) {
  files <- design_files()
  empty <- data.frame(
    id = character(0),
    alias = character(0),
    params = character(0),
    packages = character(0),
    label = character(0),
    category = character(0),
    keywords = character(0),
    include_in_shiny = logical(0),
    functional = logical(0),
    file = character(0),
    stringsAsFactors = FALSE
  )
  if (!length(files)) {
    return(structure(empty, class = c("research_designs_list", "data.frame")))
  }

  rows <- lapply(files, function(path) {
    parsed <- parse_design_file(path)
    m <- parsed$meta
    alias <- if (is.null(m$alias) || (length(m$alias) == 1L && is.na(m$alias))) {
      NA_character_
    } else {
      as.character(m$alias)[[1]]
    }

    params <- NA_character_
    if (isTRUE(discover_params) && isTRUE(m$functional)) {
      params <- tryCatch({
        design <- eval_design(parsed)
        pnames <- discover_design_params(design)$name
        if (!length(pnames)) "" else paste(pnames, collapse = ", ")
      }, error = function(e) NA_character_)
    }

    pkgs <- m$packages %||% character(0)
    pkgs <- pkgs[nzchar(as.character(pkgs))]

    data.frame(
      id = m$id,
      alias = alias,
      params = params,
      packages = if (!length(pkgs)) "" else paste(pkgs, collapse = ", "),
      label = as.character(m$label)[[1]],
      category = as.character(m$category %||% "Other")[[1]],
      keywords = paste(m$keywords %||% character(0), collapse = ", "),
      include_in_shiny = isTRUE(m$include_in_shiny),
      functional = isTRUE(m$functional),
      file = basename(path),
      stringsAsFactors = FALSE
    )
  })
  out <- do.call(rbind, rows)
  if (isTRUE(shiny_only)) {
    out <- out[out$include_in_shiny, , drop = FALSE]
    rownames(out) <- NULL
  }
  if (nrow(out)) {
    # Template category first, then other categories / label
    is_template <- tolower(trimws(as.character(out$category %||% ""))) %in%
      c("template", "templates")
    o <- order(!is_template, as.character(out$category), as.character(out$label), as.character(out$id))
    out <- out[o, , drop = FALSE]
    rownames(out) <- NULL
  }
  structure(out, class = c("research_designs_list", "data.frame"))
}

#' @export
print.research_designs_list <- function(x, ..., n = 5L) {
  n_all <- nrow(x)
  cat(
    "ResearchDesigns library: ", n_all, " design",
    if (n_all == 1L) "" else "s", "\n\n",
    sep = ""
  )
  if (n_all > 0L) {
    alias <- as.character(x$alias)
    alias[is.na(alias)] <- ""

    params_chr <- if ("params" %in% names(x)) as.character(x$params) else rep(NA_character_, n_all)
    show_params <- any(!is.na(params_chr) & nzchar(trimws(params_chr)))

    pkgs <- if ("packages" %in% names(x)) as.character(x$packages) else rep("", n_all)
    pkgs[is.na(pkgs)] <- ""
    has_pkg <- nzchar(trimws(pkgs))

    summary <- data.frame(
      id = as.character(x$id),
      alias = alias,
      label = as.character(x$label),
      stringsAsFactors = FALSE
    )
    if (show_params) summary$params <- params_chr

    n_show <- max(1L, as.integer(n)[1])
    print(utils::head(summary, n_show), row.names = FALSE, right = FALSE, ...)
    if (n_all > n_show) {
      cat("\n... and ", n_all - n_show, " more.\n", sep = "")
    }
    if (any(has_pkg)) {
      cat(
        "\nPackages: ",
        paste(sprintf("%s (%s)", x$id[has_pkg], trimws(pkgs[has_pkg])), collapse = "; "),
        "\n",
        sep = ""
      )
    }
  }
  cat(
    "\nSee design_info(\"id\") or get_args(\"id\") for details;\n",
    "as.data.frame(list_designs()) for the full table.\n",
    sep = ""
  )
  invisible(x)
}

#' Design metadata (YAML + defaults)
#'
#' Printing uses short English prose. The underlying list is unchanged for
#' programmatic use (`info$id`, `info$params`, `info$diagnosands`, etc.).
#'
#' @param design Design id or book alias.
#' @return A named list of metadata with class `research_designs_info`.
#' @export
design_info <- function(design) {
  if (length(design) > 1L) design <- design[[1L]]
  meta <- resolve_design(design)$meta
  structure(meta, class = c("research_designs_info", "list"))
}

#' Preferred diagnosands declared in a design's YAML
#'
#' Reads optional `diagnosands:` from the design frontmatter (for example
#' `diagnosands: [rmse, bias]` or `diagnosands: rmse, -bias, power`).
#' Positive names are preferred defaults for diagnosis and redesign display.
#' Names prefixed with `-` (e.g. `-bias`) are exclusions and are omitted here;
#' see [excluded_diagnosands()].
#'
#' @param design Design id or book alias.
#' @return Character vector (possibly empty).
#' @export
#' @examples
#' \dontrun{
#' preferred_diagnosands("two_arm_trial")
#' }
preferred_diagnosands <- function(design) {
  if (length(design) > 1L) design <- design[[1L]]
  meta <- resolve_design(design)$meta
  split_diagnosand_tokens(meta$diagnosands)$prefer
}

#' Diagnosands excluded from display by YAML
#'
#' Tokens like `-bias` in `diagnosands:` remove that name from the Shiny
#' diagnosand list for the design.
#'
#' @param design Design id or book alias.
#' @return Character vector (possibly empty).
#' @export
excluded_diagnosands <- function(design) {
  if (length(design) > 1L) design <- design[[1L]]
  meta <- resolve_design(design)$meta
  split_diagnosand_tokens(meta$diagnosands)$exclude
}

#' @export
print.research_designs_info <- function(x, ...) {
  id <- as.character(x$id %||% "")[[1]]
  alias <- x$alias
  has_alias <- !is.null(alias) && length(alias) && !is.na(alias) && nzchar(as.character(alias)[[1]])
  label <- as.character(x$label %||% humanize_id(id))[[1]]

  if (has_alias) {
    cat(sprintf('%s (alias "%s") declares a %s.\n', id, as.character(alias)[[1]], label))
  } else {
    cat(sprintf("%s declares a %s.\n", id, label))
  }

  desc <- x$description
  if (!is.null(desc) && length(desc) && !is.na(desc) && nzchar(trimws(as.character(desc)[[1]]))) {
    cat("\nThe design description is:\n")
    wrapped <- strwrap(trimws(as.character(desc)[[1]]), width = 72, prefix = "  ", initial = "  ")
    cat(paste(wrapped, collapse = "\n"), "\n", sep = "")
  }

  args <- tryCatch(get_args(id), error = function(e) NULL)
  cat("\nThe modifiable parameters are:\n")
  if (is.null(args) || !nrow(args)) {
    cat("  (none found)\n")
  } else {
    for (i in seq_len(nrow(args))) {
      tip <- args$tip[[i]]
      val <- args$value_str[[i]] %||% ""
      line <- sprintf("  %s = %s", args$name[[i]], val)
      if (!is.null(tip) && length(tip) && !is.na(tip) && nzchar(tip)) {
        line <- paste0(line, " — ", tip)
      }
      cat(line, "\n", sep = "")
    }
  }

  cat_bits <- character(0)
  catg <- x$category %||% "Other"
  if (!is.null(catg) && nzchar(as.character(catg)[[1]])) {
    cat_bits <- c(cat_bits, paste0("category ", as.character(catg)[[1]]))
  }
  kw <- x$keywords %||% character(0)
  if (length(kw) && any(nzchar(kw))) {
    cat_bits <- c(cat_bits, paste0("keywords ", paste(kw[nzchar(kw)], collapse = ", ")))
  }
  if (length(cat_bits)) {
    cat("\nIt is filed under ", paste(cat_bits, collapse = "; "), ".\n", sep = "")
  }

  pkgs <- x$packages %||% character(0)
  pkgs <- pkgs[nzchar(as.character(pkgs))]
  if (length(pkgs)) {
    cat("\nExtra packages required:\n  ", paste(pkgs, collapse = ", "), "\n", sep = "")
  }

  dgs <- x$diagnosands %||% character(0)
  dgs <- dgs[nzchar(as.character(dgs))]
  if (length(dgs)) {
    parts <- split_diagnosand_tokens(dgs)
    if (length(parts$prefer)) {
      cat("\nPreferred diagnosands:\n  ", paste(parts$prefer, collapse = ", "), "\n", sep = "")
    }
    if (length(parts$exclude)) {
      cat("\nExcluded diagnosands:\n  ", paste(parts$exclude, collapse = ", "), "\n", sep = "")
    }
  }

  link <- x$book_link
  if (!is.null(link) && length(link) && !is.na(link) && nzchar(as.character(link)[[1]])) {
    cat("\nBook reference:\n  ", as.character(link)[[1]], "\n", sep = "")
  }

  cat(
    "\nSee make_design(\"", id, "\"), get_args(\"", id, "\"), ",
    "or get_code(\"", id, "\") for more.\n",
    sep = ""
  )
  invisible(x)
}

#' Build a design, optionally with redesigned parameters
#'
#' Loads the declared design at its defaults. Named `...` values are applied
#' with [DeclareDesignZero::redesign()]. The design object is the source of
#' truth for which names can be changed; see [get_args()].
#'
#' In RStudio, Positron, and other tools that complete from formals, typing
#' `make_design("` and pressing Tab lists installed design ids (and aliases).
#' See [list_designs()] for the same catalogue in the console.
#'
#' @param design Design id or book alias. Defaults to `"two_arm_trial"` (or the
#'   first installed design). Tab-completion offers the full library list.
#' @param ... Named parameter values passed to `redesign()`.
#' @return A design object (or a list of designs if a parameter is a vector
#'   and `redesign()` expands).
#' @export
#' @examples
#' \dontrun{
#' make_design()
#' make_design("two_arm_trial", b = 0.5)
#' make_design("2.1", b = 0.5)  # book alias
#' }
make_design <- function(design = "two_arm_trial", ...) {
  # When formals are the full library vector (set in .onLoad for IDE completion),
  # a bare make_design() call receives that vector — use the first id.
  if (length(design) > 1L) design <- design[[1L]]
  d <- eval_design(resolve_design(design))
  dots <- list(...)
  if (!length(dots)) return(d)
  unknown <- setdiff(names(dots), discover_design_params(d)$name)
  unknown <- unknown[nzchar(unknown %||% "")]
  if (length(unknown)) {
    stop(
      "Unknown parameter(s) for '", normalize_design_key(design), "': ",
      paste(unknown, collapse = ", "),
      ". Use get_args(\"", normalize_design_key(design), "\").",
      call. = FALSE
    )
  }
  do.call(DeclareDesignZero::redesign, c(list(design = d), dots))
}

#' Editable parameters for a design
#'
#' Reads parameters from the design object. Optional YAML `params:` entries
#' only add tips (and never invent new parameter names).
#'
#' @param design Design id or book alias.
#' @return A data frame with `name`, `default`, `value_str`, and `tip`.
#' @export
get_args <- function(design) {
  if (length(design) > 1L) design <- design[[1L]]
  parsed <- resolve_design(design)
  d <- eval_design(parsed)
  build_args_table(parsed$meta, d)
}

#' Code for a design: simple `make_design()` call and/or full source
#'
#' @param design Design id or book alias.
#' @param style `"simple"`, `"full"`, or `"both"`.
#' @param ... Optional parameter values included in the simple snippet.
#' @return Character string (or named list if `style = "both"`).
#' @export
get_code <- function(design, style = c("both", "simple", "full"), ...) {
  style <- match.arg(style)
  if (length(design) > 1L) design <- design[[1L]]
  key <- normalize_design_key(design)
  parsed <- resolve_design(design)
  dots <- list(...)

  simple <- paste0("make_design(\"", key, "\"")
  if (length(dots)) {
    args <- vapply(names(dots), function(nm) {
      paste0(nm, " = ", deparse1(dots[[nm]]))
    }, character(1))
    simple <- paste0(simple, ", ", paste(args, collapse = ", "))
  }
  simple <- paste0(simple, ")")

  full <- parsed$code

  if (identical(style, "simple")) return(simple)
  if (identical(style, "full")) return(full)
  list(simple = simple, full = full)
}
