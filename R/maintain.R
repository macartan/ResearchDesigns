#' Contributor checklist for a design
#'
#' Used by [audit_designs()] and documented for authors.
#'
#' @return Character vector of checklist items.
#' @export
contributor_checklist <- function() {
  c(
    "File lives in inst/designs/ and is self-contained (no source() of other designs).",
    "Filename matches the substantive id (e.g. two_arm_trial.R).",
    "YAML frontmatter is optional. If present, may set id, alias (book ref), label, category, keywords, packages, include_in_shiny, book_link, params; object: only if the design is not named `design`.",
    "No YAML is fine: id = filename stem, label = humanized id, category = Other, object = design, include_in_shiny = TRUE.",
    "The design object is the source of truth for editable parameters.",
    "YAML params map names to tip strings; always quote keys (e.g. \"N\": \"Sample size\", \"b\": \"Effect size\"); names must match design parameters (no extras).",
    "Extra packages listed under packages: and available to install.",
    "Design evaluates under DeclareDesignZero; redesign() works for documented parameters.",
    "Run refresh_library() from the package source tree after adding or editing designs (or set options(ResearchDesigns.root = \"...\"))."
  )
}

#' Build an in-memory index of all designs
#'
#' @return A data frame (same columns as [list_designs()], plus description).
#' @export
make_index <- function() {
  files <- design_files()
  if (!length(files)) {
    return(data.frame(
      id = character(0),
      alias = character(0),
      label = character(0),
      category = character(0),
      keywords = character(0),
      packages = character(0),
      description = character(0),
      include_in_shiny = logical(0),
      file = character(0),
      stringsAsFactors = FALSE
    ))
  }

  rows <- lapply(files, function(path) {
    m <- parse_design_file(path)$meta
    pkgs <- m$packages %||% character(0)
    pkgs <- pkgs[nzchar(as.character(pkgs))]
    data.frame(
      id = m$id,
      alias = if (is.null(m$alias) || (length(m$alias) == 1L && is.na(m$alias))) {
        NA_character_
      } else {
        as.character(m$alias)[[1]]
      },
      label = as.character(m$label)[[1]],
      category = as.character(m$category %||% "Other")[[1]],
      keywords = paste(m$keywords %||% character(0), collapse = ", "),
      packages = if (!length(pkgs)) "" else paste(pkgs, collapse = ", "),
      description = if (is.null(m$description) || (length(m$description) == 1L && is.na(m$description))) {
        NA_character_
      } else {
        as.character(m$description)[[1]]
      },
      include_in_shiny = isTRUE(m$include_in_shiny),
      file = basename(path),
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}

#' Audit one or more designs
#'
#' Checks that each file loads, exposes a design object, and that any YAML
#' `params:` names are a subset of the design's modifiable parameters.
#'
#' @param designs Character vector of ids/aliases, or `NULL` for all.
#' @param sims If not `NULL`, run a short `diagnose_design()` with this many sims.
#' @return An object of class `research_designs_audit`.
#' @export
audit_designs <- function(designs = NULL, sims = NULL) {
  idx <- make_index()
  if (!is.null(designs)) {
    keys <- vapply(designs, normalize_design_key, character(1))
    keep <- idx$id %in% keys | idx$alias %in% keys | idx$file %in% paste0(keys, ".R")
    idx <- idx[keep, , drop = FALSE]
  }
  if (!nrow(idx)) {
    stop("No designs to audit.", call. = FALSE)
  }

  results <- lapply(seq_len(nrow(idx)), function(i) {
    id <- idx$id[[i]]
    row <- list(
      id = id,
      alias = idx$alias[[i]],
      ok = FALSE,
      error = NA_character_,
      params = character(0),
      missing_docs = character(0),
      extra_docs = character(0),
      checklist = contributor_checklist()
    )
    tryCatch({
      parsed <- resolve_design(id)
      design <- eval_design(parsed)
      v <- validate_params_against_design(parsed$meta, design)
      row$params <- v$in_design
      row$missing_docs <- v$missing_docs
      row$extra_docs <- v$extra_docs
      if (length(v$extra_docs)) {
        stop(
          "YAML params not in design: ",
          paste(v$extra_docs, collapse = ", "),
          call. = FALSE
        )
      }
      if (!is.null(sims)) {
        DeclareDesignZero::diagnose_design(design, sims = as.integer(sims))
      }
      row$ok <- TRUE
    }, error = function(e) {
      row$error <<- conditionMessage(e)
      row$ok <<- FALSE
    })
    row
  })

  structure(
    list(
      results = results,
      n = length(results),
      n_ok = sum(vapply(results, function(r) isTRUE(r$ok), logical(1))),
      checklist = contributor_checklist()
    ),
    class = "research_designs_audit"
  )
}

#' @export
print.research_designs_audit <- function(x, ...) {
  cat("ResearchDesigns audit: ", x$n_ok, "/", x$n, " ok\n", sep = "")
  for (r in x$results) {
    status <- if (isTRUE(r$ok)) "OK" else "FAIL"
    cat(" - ", r$id, ": ", status, sep = "")
    if (!isTRUE(r$ok) && !is.na(r$error)) cat(" — ", r$error, sep = "")
    if (length(r$extra_docs)) {
      cat("\n     extra YAML params: ", paste(r$extra_docs, collapse = ", "), sep = "")
    }
    if (length(r$missing_docs)) {
      cat("\n     undocumented params (ok): ", paste(r$missing_docs, collapse = ", "), sep = "")
    }
    cat("\n")
  }
  invisible(x)
}

#' Bake compact diagnosis previews into inst/previews
#'
#' @param designs Ids/aliases, or `NULL` for shiny-included designs.
#' @param sims Number of simulations (package default is 100).
#' @return Invisibly, paths written.
#' @export
bake_previews <- function(designs = NULL, sims = 100) {
  paths_info <- package_write_paths()
  out_dir <- paths_info$previews
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

  idx <- make_index()
  if (is.null(designs)) {
    idx <- idx[idx$include_in_shiny, , drop = FALSE]
  } else {
    keys <- vapply(designs, normalize_design_key, character(1))
    keep <- idx$id %in% keys | idx$alias %in% keys
    idx <- idx[keep, , drop = FALSE]
  }
  if (!nrow(idx)) {
    warning("No designs selected for previews.", call. = FALSE)
    return(invisible(character(0)))
  }

  paths <- character(0)
  for (i in seq_len(nrow(idx))) {
    id <- idx$id[[i]]
    design <- make_design(id)
    diagnosis <- DeclareDesignZero::diagnose_design(design, sims = as.integer(sims))
    summary <- tryCatch(
      DeclareDesignZero::get_diagnosands(diagnosis),
      error = function(e) NULL
    )
    tidy <- tryCatch({
      if (requireNamespace("generics", quietly = TRUE)) {
        generics::tidy(diagnosis)
      } else {
        summary
      }
    }, error = function(e) summary)
    path <- file.path(out_dir, paste0(id, ".rds"))
    saveRDS(
      list(
        id = id,
        sims = as.integer(sims),
        summary = summary,
        tidy = tidy,
        diagnosis = diagnosis
      ),
      path
    )
    paths <- c(paths, path)
  }
  invisible(paths)
}

#' Write index artifact under inst/library_index
#' @noRd
write_index_artifact <- function(index = make_index()) {
  paths_info <- package_write_paths()
  out_dir <- paths_info$index
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  path <- file.path(out_dir, "designs_index.rds")
  saveRDS(index, path)
  utils::write.csv(index, file.path(out_dir, "designs_index.csv"), row.names = FALSE)
  path
}

#' Refresh the library (maintainer one-stop)
#'
#' Runs the contributor-facing checks and refreshes baked artifacts:
#' index, audits, and diagnosis previews (`sims = 100` by default).
#'
#' @param sims Preview simulations (default 100).
#' @param designs Optional subset; default all for audit, shiny-on for previews.
#' @return A list with `index`, `audit`, and `previews`.
#' @export
refresh_library <- function(sims = 100, designs = NULL) {
  paths_info <- package_write_paths()
  message("ResearchDesigns refresh_library()")
  message("Package root: ", paths_info$root)
  message("Designs dir:  ", designs_dir())
  message("Checklist:")
  for (item in contributor_checklist()) message("  [ ] ", item)

  index <- make_index()
  write_index_artifact(index)
  message("Index: ", nrow(index), " design(s)")
  if (nrow(index)) {
    message("  ", paste(index$id, collapse = ", "))
  }

  audit <- audit_designs(designs = designs, sims = NULL)
  print(audit)
  if (audit$n_ok < audit$n) {
    stop("refresh_library() stopped: audit failures.", call. = FALSE)
  }

  previews <- bake_previews(designs = designs, sims = sims)
  message("Previews written: ", length(previews))

  invisible(list(index = index, audit = audit, previews = previews))
}
