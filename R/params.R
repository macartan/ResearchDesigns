#' Discover modifiable parameters from a design object
#'
#' Uses DeclareDesignZero's object finder. The design is the source of truth.
#'
#' @param design A DeclareDesignZero `design` object.
#' @return Data frame with `name`, `value_str`, `value`, `step`.
#' @noRd
discover_design_params <- function(design) {
  objs <- DeclareDesignZero:::find_all_objects(design)
  filter_modifiable_params(objs)
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
validate_params_against_design <- function(meta, design) {
  in_design <- discover_design_params(design)$name
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

#' Build get_args() table: design values + optional YAML tips
#' @noRd
build_args_table <- function(meta, design) {
  params <- discover_design_params(design)
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
