#' Discover modifiable parameters from a design object
#'
#' Uses DeclareDesignZero's object finder. When `code` is supplied, only names
#' that also appear as top-level assignments before `design <-` are kept — so
#' literal step arguments like `se_type = "stata"` are not treated as knobs.
#'
#' @param design A DeclareDesignZero `design` object.
#' @param code Optional design file code (without YAML) used to restrict to
#'   author-assigned knobs.
#' @return Data frame with `name`, `value_str`, `value`, `step`.
#' @noRd
discover_design_params <- function(design, code = NULL) {
  objs <- DeclareDesignZero:::find_all_objects(design)
  params <- filter_modifiable_params(objs)
  if (!is.null(code) && nzchar(trimws(code))) {
    pre <- extract_pre_design_objects(code)
    # Author knobs only: top-level assignments before design <-
    # Literals like declare_model(N = 1000) are not knobs.
    knobs <- if (nrow(pre)) {
      unique(pre$name[!pre$type %in% c("design_piece", "function")])
    } else {
      character(0)
    }
    params <- params[params$name %in% knobs, , drop = FALSE]
    rownames(params) <- NULL
  }
  params
}

#' Drop non-atomic redesign targets; dedupe by name
#' @noRd
filter_modifiable_params <- function(objs) {
  empty <- data.frame(
    name = character(0),
    value_str = character(0),
    value = I(list()),
    step = integer(0),
    stringsAsFactors = FALSE
  )
  if (is.null(objs) || !nrow(objs)) return(empty)

  keep <- logical(nrow(objs))
  values <- vector("list", nrow(objs))

  for (i in seq_len(nrow(objs))) {
    name <- objs$name[[i]]
    # find_all_objects can emit "" (e.g. anonymous formulas); get("") errors
    if (is.null(name) || !nzchar(as.character(name)[[1L]])) {
      keep[[i]] <- FALSE
      next
    }
    env <- objs$env[[i]]
    val <- NULL
    if (!is.null(env)) {
      val <- tryCatch(
        get(name, envir = env, inherits = FALSE),
        error = function(e) NULL
      )
      if (!is.null(val) && (is.symbol(val) || is.name(val))) {
        val <- tryCatch(eval(val, envir = env), error = function(e) NULL)
      }
    }
    if (is.null(val) && nzchar(objs$value_str[[i]] %||% "")) {
      val <- tryCatch(
        eval(parse(text = objs$value_str[[i]]), envir = baseenv()),
        error = function(e) NULL
      )
    }
    values[[i]] <- val
    if (is.null(val)) {
      keep[[i]] <- TRUE
      next
    }
    keep[[i]] <- is.atomic(val) && !is.function(val)
  }

  out <- objs[keep, , drop = FALSE]
  values <- values[keep]
  if (nrow(out) && "name" %in% names(out)) {
    dup <- duplicated(out$name)
    out <- out[!dup, , drop = FALSE]
    values <- values[!dup]
  }

  data.frame(
    name = out$name,
    value_str = out$value_str,
    value = I(values),
    step = out$step,
    stringsAsFactors = FALSE
  )
}

#' Compare YAML-documented params to design params
#' @noRd
validate_params_against_design <- function(meta, design, code = NULL) {
  in_design <- discover_design_params(design, code = code)$name
  documented <- names(meta$params %||% list())
  if (is.null(documented)) documented <- character(0)

  list(
    # Superfluous YAML names are the hard problem; missing tips are soft
    ok = length(setdiff(documented, in_design)) == 0L,
    in_design = in_design,
    documented = documented,
    missing_docs = setdiff(in_design, documented),
    extra_docs = setdiff(documented, in_design)
  )
}

#' Parse an RHS fragment, treating an empty one as incomplete
#'
#' `parse(text = "")` succeeds and returns a zero-length expression, so a
#' fragment that is only whitespace has to read as "not finished yet" or the
#' caller stops accumulating continuation lines the moment it sees a `<-` at
#' the end of a line.
#' @noRd
parse_rhs <- function(rhs) {
  expr <- tryCatch(parse(text = rhs), error = function(e) NULL)
  if (is.null(expr) || !length(expr)) return(NULL)
  expr
}

#' Top-level assignments appearing before `design <-` in a design file
#'
#' @param code Character scalar (R code without YAML).
#' @return Data frame with `name`, `rhs`, `type`, `atomic`.
#' @noRd
extract_pre_design_objects <- function(code) {
  empty <- data.frame(
    name = character(0),
    rhs = character(0),
    type = character(0),
    atomic = logical(0),
    stringsAsFactors = FALSE
  )
  if (!nzchar(trimws(code %||% ""))) return(empty)

  lines <- strsplit(code, "\n", fixed = TRUE)[[1]]
  des_i <- which(grepl("^\\s*design\\s*<-", lines))
  if (!length(des_i)) return(empty)
  head_lines <- lines[seq_len(des_i[[1]] - 1L)]

  names_out <- character(0)
  rhs_out <- character(0)
  type_out <- character(0)
  atomic_out <- logical(0)

  i <- 1L
  n <- length(head_lines)
  while (i <= n) {
    ln <- head_lines[[i]]
    i <- i + 1L
    if (grepl("^\\s*#", ln) || !nzchar(trimws(ln))) next
    # `<-` or a top-level `=`; `==` is a comparison, not an assignment
    if (!grepl("^\\s*[A-Za-z.][A-Za-z0-9._]*\\s*(<-|=(?!=))\\s*", ln, perl = TRUE)) next
    if (grepl("^\\s*(if|for|while)\\b", ln)) next
    nm <- sub("^\\s*([A-Za-z.][A-Za-z0-9._]*)\\s*(<-|=).*$", "\\1", ln)
    rhs <- sub("^\\s*[A-Za-z.][A-Za-z0-9._]*\\s*(<-|=)\\s*", "", ln)

    # Accumulate continuation lines until the RHS parses (multi-line declare_* etc.).
    # An RHS of "" parses to a zero-length expression, so a `name <-` that ends
    # the line has to keep reading or every multi-line assignment reads as empty.
    expr <- parse_rhs(rhs)
    while (is.null(expr) && i <= n) {
      rhs <- paste(rhs, head_lines[[i]], sep = "\n")
      i <- i + 1L
      expr <- parse_rhs(rhs)
    }
    rhs <- trimws(rhs)

    if (grepl("\\bfunction\\s*\\(", rhs)) {
      names_out <- c(names_out, nm)
      rhs_out <- c(rhs_out, rhs)
      type_out <- c(type_out, "function")
      atomic_out <- c(atomic_out, FALSE)
      next
    }

    # Prefer structural cues before eval (eval of declare_* needs the DD stack)
    # Note: do not use \\b after "declare_" — "_" is a word char, so declare_model
    # would not match.
    if (grepl("(declare_|make_model\\(|add_level\\(|as_tibble\\(|fabricate\\()", rhs)) {
      names_out <- c(names_out, nm)
      rhs_out <- c(rhs_out, rhs)
      type_out <- c(type_out, "design_piece")
      atomic_out <- c(atomic_out, FALSE)
      next
    }

    val <- tryCatch(eval(parse(text = rhs), envir = baseenv()), error = function(e) NULL)
    typ <- if (is.null(val)) {
      "other"
    } else if (is.function(val)) {
      "function"
    } else if (is.atomic(val)) {
      paste0(typeof(val), if (length(val) != 1L) paste0("[", length(val), "]") else "")
    } else {
      paste(class(val), collapse = "/")
    }
    is_atom <- !is.null(val) && is.atomic(val) && !is.function(val)
    names_out <- c(names_out, nm)
    rhs_out <- c(rhs_out, rhs)
    type_out <- c(type_out, typ)
    atomic_out <- c(atomic_out, is_atom)
  }

  if (!length(names_out)) return(empty)
  # last assignment wins for duplicates
  keep <- !duplicated(names_out, fromLast = TRUE)
  data.frame(
    name = names_out[keep],
    rhs = rhs_out[keep],
    type = type_out[keep],
    atomic = atomic_out[keep],
    stringsAsFactors = FALSE
  )
}

#' Whether a symbol name appears used in design code (word boundary)
#' @noRd
symbol_used_in_code <- function(name, code) {
  if (!nzchar(name) || !nzchar(code)) return(FALSE)
  grepl(paste0("\\b", gsub("\\.", "\\\\.", name), "\\b"), code, perl = TRUE)
}

#' Objects declared before design, used by it, but missing from design params
#'
#' Runs the design, reads [discover_design_params()], and compares to top-level
#' assignments before `design <-`. Flags names that are used in the design body
#' (or seen by DeclareDesignZero's object finder) but not in the redesignable
#' parameter list.
#'
#' Design steps (MIDA pieces built with `declare_*`, etc.) and helper functions
#' are not parameters and are omitted unless `include_steps = TRUE`.
#'
#' @param design Design id/alias, or a parsed design list from [parse_design_file()].
#' @param include_steps If `TRUE`, also report design pieces and functions.
#'   Default `FALSE` (audit-friendly).
#' @return Data frame of gaps (possibly empty) with columns
#'   `id`, `name`, `type`, `atomic`, `used_in_code`, `in_finder`, `in_params`.
#' @export
param_coverage_gaps <- function(design, include_steps = FALSE) {
  if (is.list(design) && !is.null(design$code) && !is.null(design$meta)) {
    parsed <- design
  } else {
    parsed <- resolve_design(design)
  }
  id <- parsed$meta$id %||% NA_character_
  code <- parsed$code %||% ""
  # design body only (after design <-)
  lines <- strsplit(code, "\n", fixed = TRUE)[[1]]
  des_i <- which(grepl("^\\s*design\\s*<-", lines))
  body <- if (length(des_i)) {
    paste(lines[seq.int(des_i[[1]], length(lines))], collapse = "\n")
  } else {
    code
  }

  pre <- extract_pre_design_objects(code)
  empty <- data.frame(
    id = character(0),
    name = character(0),
    type = character(0),
    atomic = logical(0),
    used_in_code = logical(0),
    in_finder = logical(0),
    in_params = logical(0),
    stringsAsFactors = FALSE
  )
  if (!nrow(pre)) return(empty)

  dobj <- tryCatch(eval_design(parsed), error = function(e) e)
  if (inherits(dobj, "error")) {
    return(data.frame(
      id = id,
      name = NA_character_,
      type = "load_error",
      atomic = NA,
      used_in_code = NA,
      in_finder = NA,
      in_params = NA,
      error = conditionMessage(dobj),
      stringsAsFactors = FALSE
    ))
  }

  finder_names <- character(0)
  objs <- tryCatch(DeclareDesignZero:::find_all_objects(dobj), error = function(e) NULL)
  if (!is.null(objs) && nrow(objs) && "name" %in% names(objs)) {
    finder_names <- unique(as.character(objs$name))
  }
  param_names <- tryCatch(
    discover_design_params(dobj, code = code)$name,
    error = function(e) character(0)
  )

  used_in_code <- vapply(pre$name, symbol_used_in_code, body, FUN.VALUE = logical(1))
  in_finder <- pre$name %in% finder_names
  in_params <- pre$name %in% param_names
  used <- used_in_code | in_finder

  gaps <- pre[used & !in_params, , drop = FALSE]
  if (!nrow(gaps)) return(empty)

  # Steps / helpers are not redesignable params — don't treat as coverage gaps
  if (!isTRUE(include_steps)) {
    step_types <- c("design_piece", "function")
    gaps <- gaps[is.na(gaps$type) | !gaps$type %in% step_types, , drop = FALSE]
    if (!nrow(gaps)) return(empty)
  }

  # Realign logical vectors to remaining gap rows by name
  gap_names <- gaps$name
  data.frame(
    id = id,
    name = gaps$name,
    type = gaps$type,
    atomic = gaps$atomic,
    used_in_code = used_in_code[match(gap_names, pre$name)],
    in_finder = in_finder[match(gap_names, pre$name)],
    in_params = FALSE,
    stringsAsFactors = FALSE
  )
}

#' Report declared-before-design objects missing from design parameters
#'
#' For each library design: evaluate the file, read redesignable parameters from
#' the design object, and list top-level objects that are used by the design but
#' do not appear in that parameter list.
#'
#' @param designs Ids/aliases, or `NULL` for all.
#' @param atomic_only If `TRUE`, only report atomic gaps (likely should be
#'   redesignable). If `FALSE`, also report other non-step gaps (e.g. data frames).
#' @param include_steps If `TRUE`, also report design pieces and helper functions.
#' @return A data frame (class `research_designs_param_coverage`) of gaps.
#' @export
param_coverage_report <- function(designs = NULL, atomic_only = FALSE, include_steps = FALSE) {
  idx <- make_index()
  if (!is.null(designs)) {
    keys <- vapply(designs, normalize_design_key, character(1))
    keep <- idx$id %in% keys | idx$alias %in% keys
    idx <- idx[keep, , drop = FALSE]
  }
  if (!nrow(idx)) {
    stop("No designs to check.", call. = FALSE)
  }

  parts <- lapply(seq_len(nrow(idx)), function(i) {
    id <- idx$id[[i]]
    if ("functional" %in% names(idx) && !isTRUE(idx$functional[[i]])) {
      return(data.frame(
        id = character(0),
        name = character(0),
        type = character(0),
        atomic = logical(0),
        used_in_code = logical(0),
        in_finder = logical(0),
        in_params = logical(0),
        stringsAsFactors = FALSE
      ))
    }
    tryCatch(
      param_coverage_gaps(id, include_steps = include_steps),
      error = function(e) {
        data.frame(
          id = id,
          name = NA_character_,
          type = "check_error",
          atomic = NA,
          used_in_code = NA,
          in_finder = NA,
          in_params = NA,
          error = conditionMessage(e),
          stringsAsFactors = FALSE
        )
      }
    )
  })

  # Drop empty frames; bind remaining (pad missing cols with NA)
  parts <- Filter(function(df) is.data.frame(df) && nrow(df) > 0L, parts)
  if (!length(parts)) {
    out <- data.frame(
      id = character(0),
      name = character(0),
      type = character(0),
      atomic = logical(0),
      used_in_code = logical(0),
      in_finder = logical(0),
      in_params = logical(0),
      stringsAsFactors = FALSE
    )
  } else {
    all_names <- unique(unlist(lapply(parts, names), use.names = FALSE))
    parts <- lapply(parts, function(df) {
      for (nm in setdiff(all_names, names(df))) {
        if (nm %in% c("atomic", "used_in_code", "in_finder", "in_params")) {
          df[[nm]] <- rep(NA, nrow(df))
        } else {
          df[[nm]] <- rep(NA_character_, nrow(df))
        }
      }
      df[all_names]
    })
    out <- do.call(rbind, parts)
  }
  if (is.null(out) || !nrow(out)) {
    out <- data.frame(
      id = character(0),
      name = character(0),
      type = character(0),
      atomic = logical(0),
      used_in_code = logical(0),
      in_finder = logical(0),
      in_params = logical(0),
      stringsAsFactors = FALSE
    )
  }
  if (isTRUE(atomic_only) && nrow(out) && "atomic" %in% names(out)) {
    out <- out[isTRUE(out$atomic) | (!is.na(out$type) & out$type %in% c("load_error", "check_error")), , drop = FALSE]
  }
  rownames(out) <- NULL
  structure(out, class = c("research_designs_param_coverage", "data.frame"), atomic_only = atomic_only, include_steps = include_steps)
}

#' @export
print.research_designs_param_coverage <- function(x, ...) {
  atomic_only <- isTRUE(attr(x, "atomic_only"))
  cat(
    "Param coverage gaps",
    if (atomic_only) " (atomic only)" else "",
    ": ",
    nrow(x),
    " row(s)\n",
    sep = ""
  )
  if (!nrow(x)) {
    cat("All pre-design objects used by designs appear in the parameter list.\n")
    return(invisible(x))
  }
  errs <- x[!is.na(x$type) & x$type %in% c("load_error", "check_error"), , drop = FALSE]
  gaps <- x[is.na(x$type) | !x$type %in% c("load_error", "check_error"), , drop = FALSE]
  if (nrow(errs)) {
    cat("\nLoad / check errors:\n")
    for (i in seq_len(nrow(errs))) {
      msg <- if ("error" %in% names(errs)) errs$error[[i]] else ""
      cat(" - ", errs$id[[i]], ": ", msg, "\n", sep = "")
    }
  }
  if (nrow(gaps)) {
    cat("\nDeclared before design, used, but not in design parameters:\n")
    show <- gaps[, intersect(c("id", "name", "type", "atomic", "used_in_code", "in_finder"), names(gaps)), drop = FALSE]
    print(show, row.names = FALSE)
  }
  invisible(x)
}

#' Build get_args() table: design values + optional YAML tips
#' @noRd
build_args_table <- function(meta, design, code = NULL) {
  params <- discover_design_params(design, code = code)
  tips_map <- normalize_params_map(meta$params %||% list())

  tip_for <- function(name) {
    tip <- tips_map[[name]]
    if (is.null(tip) || (length(tip) == 1L && is.na(tip))) return(NA_character_)
    as.character(tip)[[1]]
  }

  n <- nrow(params)
  if (n == 0L) {
    return(data.frame(
      name = character(0),
      default = I(list()),
      value_str = character(0),
      tip = character(0),
      stringsAsFactors = FALSE
    ))
  }

  defaults <- vector("list", n)
  tips <- character(n)
  for (i in seq_len(n)) {
    nm <- params$name[[i]]
    if (!is.null(params$value[[i]])) {
      defaults[[i]] <- params$value[[i]]
    } else {
      defaults[[i]] <- params$value_str[[i]]
    }
    tips[[i]] <- tip_for(nm)
  }

  data.frame(
    name = params$name,
    default = I(defaults),
    value_str = params$value_str,
    tip = tips,
    stringsAsFactors = FALSE
  )
}
