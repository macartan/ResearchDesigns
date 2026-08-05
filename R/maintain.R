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
    "YAML frontmatter is optional. If present, may set id, alias (book ref), label, category, keywords, packages, diagnosands, include_in_shiny, functional, book_link, params; object: only if the design is not named `design`.",
    "No YAML is fine: id = filename stem, label = humanized id, category = Other, object = design, include_in_shiny = TRUE, functional = TRUE.",
    "Set functional: false to park a design (e.g. unavailable dependencies). Skipped by audit, smoke tests, and dependency install; forces include_in_shiny: false.",
    "The design object is the source of truth for editable parameters.",
    "YAML params map names to tip strings; always quote keys (e.g. \"N\": \"Sample size\", \"b\": \"Effect size\"); names must match design parameters (no extras).",
    "Optional diagnosands: preferred display diagnosands (e.g. diagnosands: rmse, bias or [rmse, bias]); prefix with - to exclude (rmse, -bias, power). Shiny Diagnosis and Redesign use these defaults.",
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
      functional = logical(0),
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
      functional = isTRUE(m$functional),
      file = basename(path),
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}

#' Classify an audit error message into a coarse issue type
#' @noRd
classify_audit_issue <- function(msg) {
  if (is.null(msg) || length(msg) == 0L || is.na(msg) || !nzchar(msg)) {
    return(NA_character_)
  }
  msg <- as.character(msg)[[1]]
  if (grepl("needs packages not installed", msg, fixed = TRUE)) return("missing_packages")
  if (grepl("YAML params not in design", msg, fixed = TRUE)) return("yaml_extra_params")
  if (grepl("zero-length variable name", msg, fixed = TRUE)) return("param_discovery")
  if (grepl("not found after sourcing|Object '.*' not found", msg)) return("missing_object")
  if (grepl("object '.*' not found", msg, ignore.case = TRUE)) return("load_error")
  if (grepl("there is no package called", msg, fixed = TRUE)) return("missing_packages")
  "other"
}

#' Audit one or more designs
#'
#' Checks that each file loads, exposes a design object, and that any YAML
#' `params:` names are a subset of the design's modifiable parameters. Also
#' records pre-design objects that are used by the design but missing from the
#' redesignable parameter list (see [param_coverage_report()]).
#'
#' Failures are collected per design and (by default) written to
#' `tools/audit_report.csv`, `tools/audit_report.md`, and
#' `tools/audit_report.txt` (FAIL/SKIP first, then OK) under the package root
#' via [write_audit_report()]. Soft notes (undocumented params, coverage gaps)
#' do not mark a design as failed.
#'
#' @param designs Character vector of ids/aliases, or `NULL` for all.
#' @param sims If not `NULL`, run a short `diagnose_design()` with this many sims.
#' @param write_report If `TRUE` (default), write CSV + markdown under `tools/`.
#' @param report_dir Directory for reports; default `tools/` under package root.
#' @return An object of class `research_designs_audit`.
#' @export
audit_designs <- function(
  designs = NULL,
  sims = NULL,
  write_report = TRUE,
  report_dir = NULL
) {
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
      file = idx$file[[i]],
      packages = idx$packages[[i]],
      ok = FALSE,
      skipped = FALSE,
      issue = NA_character_,
      error = NA_character_,
      load_ok = FALSE,
      params_ok = FALSE,
      yaml_ok = FALSE,
      sims_ok = NA,
      params = character(0),
      missing_docs = character(0),
      extra_docs = character(0),
      coverage_gaps = character(0),
      coverage_gaps_atomic = character(0),
      checklist = contributor_checklist()
    )

    # Parked designs (functional: false) - do not fail audit
    if ("functional" %in% names(idx) && !isTRUE(idx$functional[[i]])) {
      row$ok <- TRUE
      row$skipped <- TRUE
      row$issue <- "disabled"
      row$error <- "functional: false (parked; skipped by audit)"
      return(row)
    }

    parsed <- tryCatch(resolve_design(id), error = function(e) e)
    if (inherits(parsed, "error")) {
      row$error <- conditionMessage(parsed)
      row$issue <- classify_audit_issue(row$error)
      return(row)
    }

    design <- tryCatch(eval_design(parsed), error = function(e) e)
    if (inherits(design, "error")) {
      row$error <- conditionMessage(design)
      row$issue <- classify_audit_issue(row$error)
      return(row)
    }
    row$load_ok <- TRUE

    v <- tryCatch(
      validate_params_against_design(parsed$meta, design),
      error = function(e) e
    )
    if (inherits(v, "error")) {
      row$error <- conditionMessage(v)
      row$issue <- classify_audit_issue(row$error)
      # still try coverage from parsed code only
      gaps <- tryCatch(param_coverage_gaps(parsed), error = function(e) NULL)
      if (!is.null(gaps) && nrow(gaps) && !("error" %in% names(gaps) && !is.na(gaps$error[[1]]))) {
        row$coverage_gaps <- gaps$name
        row$coverage_gaps_atomic <- gaps$name[isTRUE(gaps$atomic) | gaps$atomic %in% TRUE]
      }
      return(row)
    }
    row$params_ok <- TRUE
    row$params <- v$in_design
    row$missing_docs <- v$missing_docs
    row$extra_docs <- v$extra_docs

    gaps <- tryCatch(param_coverage_gaps(parsed), error = function(e) NULL)
    if (!is.null(gaps) && nrow(gaps) && !("error" %in% names(gaps) && !is.na(gaps$error[[1]]))) {
      row$coverage_gaps <- gaps$name
      row$coverage_gaps_atomic <- gaps$name[isTRUE(gaps$atomic) | gaps$atomic %in% TRUE]
    }

    if (length(v$extra_docs)) {
      row$yaml_ok <- FALSE
      row$error <- paste0("YAML params not in design: ", paste(v$extra_docs, collapse = ", "))
      row$issue <- "yaml_extra_params"
      return(row)
    }
    row$yaml_ok <- TRUE

    if (!is.null(sims)) {
      sim_res <- tryCatch(
        DeclareDesignZero::diagnose_design(design, sims = as.integer(sims)),
        error = function(e) e
      )
      if (inherits(sim_res, "error")) {
        row$sims_ok <- FALSE
        row$error <- conditionMessage(sim_res)
        row$issue <- "diagnose_failed"
        return(row)
      }
      row$sims_ok <- TRUE
    }

    row$ok <- TRUE
    row
  })

  out <- structure(
    list(
      results = results,
      n = length(results),
      n_ok = sum(vapply(results, function(r) isTRUE(r$ok) && !isTRUE(r$skipped), logical(1))),
      n_skipped = sum(vapply(results, function(r) isTRUE(r$skipped), logical(1))),
      n_fail = sum(vapply(results, function(r) !isTRUE(r$ok), logical(1))),
      checklist = contributor_checklist(),
      report_paths = character(0)
    ),
    class = "research_designs_audit"
  )

  if (isTRUE(write_report)) {
    paths <- tryCatch(
      write_audit_report(out, dir = report_dir),
      error = function(e) {
        warning("Could not write audit report: ", conditionMessage(e), call. = FALSE)
        character(0)
      }
    )
    out$report_paths <- paths
  }
  out
}
#' Order audit results: FAIL, then SKIP, then OK-with-notes, then clean OK
#' @noRd
order_audit_results <- function(results) {
  rank <- vapply(results, function(r) {
    if (!isTRUE(r$ok)) return(1L)
    if (isTRUE(r$skipped)) return(2L)
    has_notes <- length(r$missing_docs) ||
      length(r$coverage_gaps) ||
      length(r$coverage_gaps_atomic) ||
      length(r$extra_docs)
    if (has_notes) return(3L)
    4L
  }, integer(1))
  results[order(rank, vapply(results, function(r) r$id %||% "", character(1)))]
}

#' One-line status string for an audit result
#' @noRd
format_audit_result_line <- function(r) {
  status <- if (isTRUE(r$skipped)) {
    "SKIP"
  } else if (isTRUE(r$ok)) {
    "OK"
  } else {
    "FAIL"
  }
  line <- paste0(" - ", r$id, ": ", status)
  if (!isTRUE(r$ok) || isTRUE(r$skipped)) {
    if (!is.null(r$issue) && length(r$issue) && !is.na(r$issue) && nzchar(r$issue)) {
      line <- paste0(line, " [", r$issue, "]")
    }
    if (!is.null(r$error) && length(r$error) && !is.na(r$error) && nzchar(r$error)) {
      line <- paste0(line, " - ", r$error)
    }
  }
  extras <- character(0)
  if (length(r$extra_docs)) {
    extras <- c(extras, paste0("     extra YAML params: ", paste(r$extra_docs, collapse = ", ")))
  }
  if (length(r$missing_docs)) {
    extras <- c(extras, paste0("     undocumented params (ok): ", paste(r$missing_docs, collapse = ", ")))
  }
  if (length(r$coverage_gaps_atomic)) {
    extras <- c(
      extras,
      paste0(
        "     declared+used but not in design params (atomic): ",
        paste(r$coverage_gaps_atomic, collapse = ", ")
      )
    )
  } else if (length(r$coverage_gaps)) {
    extras <- c(
      extras,
      paste0(
        "     declared+used but not in design params: ",
        paste(r$coverage_gaps, collapse = ", ")
      )
    )
  }
  if (length(extras)) paste(c(line, extras), collapse = "\n") else line
}

#' Write audit results to CSV, markdown, and plain text under `tools/`
#'
#' @param x A `research_designs_audit` object from [audit_designs()].
#' @param dir Output directory. Default: `tools/` under the package root.
#' @return Character vector of paths written (invisibly).
#' @export
write_audit_report <- function(x, dir = NULL) {
  if (!inherits(x, "research_designs_audit")) {
    stop("x must be a research_designs_audit object from audit_designs().", call. = FALSE)
  }
  if (is.null(dir)) {
    root <- tryCatch(find_package_root(), error = function(e) getwd())
    dir <- file.path(root, "tools")
  }
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)

  collapse <- function(v) {
    if (is.null(v) || length(v) == 0L) return("")
    paste(as.character(v), collapse = ", ")
  }

  ordered <- order_audit_results(x$results)

  rows <- lapply(ordered, function(r) {
    data.frame(
      id = r$id %||% "",
      alias = if (is.null(r$alias) || length(r$alias) == 0L || is.na(r$alias)) "" else as.character(r$alias)[[1]],
      file = r$file %||% "",
      ok = isTRUE(r$ok),
      skipped = isTRUE(r$skipped),
      issue = if (is.null(r$issue) || length(r$issue) == 0L || is.na(r$issue)) "" else as.character(r$issue)[[1]],
      error = if (is.null(r$error) || length(r$error) == 0L || is.na(r$error)) "" else as.character(r$error)[[1]],
      load_ok = isTRUE(r$load_ok),
      params_ok = isTRUE(r$params_ok),
      yaml_ok = isTRUE(r$yaml_ok),
      packages = r$packages %||% "",
      params = collapse(r$params),
      extra_yaml = collapse(r$extra_docs),
      missing_docs = collapse(r$missing_docs),
      coverage_gaps_atomic = collapse(r$coverage_gaps_atomic),
      coverage_gaps = collapse(r$coverage_gaps),
      stringsAsFactors = FALSE
    )
  })
  df <- do.call(rbind, rows)
  csv_path <- file.path(dir, "audit_report.csv")
  utils::write.csv(df, csv_path, row.names = FALSE)

  md_path <- file.path(dir, "audit_report.md")
  lines <- c(
    "# ResearchDesigns audit report",
    "",
    paste0(
      "Summary: **", x$n_ok %||% sum(vapply(x$results, function(r) isTRUE(r$ok) && !isTRUE(r$skipped), logical(1))),
      "/", x$n, "** designs OK",
      if (!is.null(x$n_skipped) && x$n_skipped > 0) paste0(", **", x$n_skipped, "** parked (`functional: false`)") else "",
      if (!is.null(x$n_fail) && x$n_fail > 0) paste0(", **", x$n_fail, "** failed") else "",
      "."
    ),
    "",
    "Issue types: `missing_packages`, `yaml_extra_params`, `param_discovery`, `load_error`, `missing_object`, `diagnose_failed`, `disabled`, `other`.",
    "",
    "Soft notes (do not fail the audit): undocumented params, coverage gaps.",
    "Parked designs (`functional: false`) are listed under Disabled and do not count as failures.",
    "Plain-text listing (`audit_report.txt`) puts FAIL/SKIP first, then OK.",
    ""
  )

  disabled <- Filter(function(r) isTRUE(r$skipped), ordered)
  if (length(disabled)) {
    lines <- c(lines, "## Disabled (`functional: false`)", "")
    for (r in disabled) {
      lines <- c(lines, paste0("- **", r$id, "** - ", r$error %||% "parked"))
    }
    lines <- c(lines, "")
  }

  failed <- Filter(function(r) !isTRUE(r$ok), ordered)
  if (!length(failed)) {
    lines <- c(lines, "## Failures", "", "_None._", "")
  } else {
    lines <- c(lines, "## Failures", "")
    by_issue <- split(failed, vapply(failed, function(r) {
      iss <- r$issue %||% "other"
      if (is.null(iss) || length(iss) == 0L || is.na(iss) || !nzchar(iss)) "other" else iss
    }, character(1)))
    for (iss in sort(names(by_issue))) {
      lines <- c(lines, paste0("### ", iss), "")
      for (r in by_issue[[iss]]) {
        lines <- c(
          lines,
          paste0("- **", r$id, "**", if (!is.null(r$alias) && length(r$alias) && !is.na(r$alias)) paste0(" (`", r$alias, "`)") else ""),
          paste0("  - ", r$error %||% "(no message)"),
          if (length(r$extra_docs)) paste0("  - extra YAML: ", paste(r$extra_docs, collapse = ", ")) else NULL,
          if (length(r$coverage_gaps_atomic)) {
            paste0("  - atomic coverage gaps: ", paste(r$coverage_gaps_atomic, collapse = ", "))
          } else {
            NULL
          },
          ""
        )
      }
    }
  }

  notes <- Filter(function(r) {
    isTRUE(r$ok) && !isTRUE(r$skipped) &&
      (length(r$missing_docs) || length(r$coverage_gaps) || length(r$coverage_gaps_atomic))
  }, ordered)
  if (length(notes)) {
    lines <- c(lines, "## Soft notes (OK designs)", "")
    for (r in notes) {
      bits <- character(0)
      if (length(r$missing_docs)) bits <- c(bits, paste0("undocumented: ", paste(r$missing_docs, collapse = ", ")))
      if (length(r$coverage_gaps_atomic)) {
        bits <- c(bits, paste0("atomic gaps: ", paste(r$coverage_gaps_atomic, collapse = ", ")))
      } else if (length(r$coverage_gaps)) {
        bits <- c(bits, paste0("gaps: ", paste(r$coverage_gaps, collapse = ", ")))
      }
      lines <- c(lines, paste0("- **", r$id, "**: ", paste(bits, collapse = "; ")))
    }
    lines <- c(lines, "")
  }

  lines <- c(
    lines,
    "## Full table",
    "",
    "See `audit_report.csv` / `audit_report.txt` in this folder (problems first).",
    ""
  )
  writeLines(lines, md_path)

  # Plain text: problems at top, OK designs later
  txt_path <- file.path(dir, "audit_report.txt")
  header <- paste0(
    "ResearchDesigns audit: ",
    x$n_ok %||% sum(vapply(x$results, function(r) isTRUE(r$ok) && !isTRUE(r$skipped), logical(1))),
    "/", x$n, " ok",
    if (!is.null(x$n_skipped) && x$n_skipped > 0) paste0(", ", x$n_skipped, " parked") else "",
    if (!is.null(x$n_fail) && x$n_fail > 0) paste0(", ", x$n_fail, " failed") else "",
    "\n(Order: FAIL, SKIP/parked, OK-with-notes, OK)\n"
  )
  body <- vapply(ordered, format_audit_result_line, character(1))
  writeLines(c(header, body), txt_path)

  legacy <- file.path(dir, "audit_failures.txt")
  if (file.exists(legacy)) unlink(legacy)

  paths <- c(csv = csv_path, md = md_path, txt = txt_path)
  message("Audit report written:\n  ", paste(paths, collapse = "\n  "))
  invisible(paths)
}

#' @export
print.research_designs_audit <- function(x, ...) {
  cat(
    "ResearchDesigns audit: ", x$n_ok, "/", x$n, " ok",
    if (!is.null(x$n_skipped) && x$n_skipped > 0) paste0(", ", x$n_skipped, " parked") else "",
    if (!is.null(x$n_fail) && x$n_fail > 0) paste0(", ", x$n_fail, " failed") else "",
    "\n",
    sep = ""
  )
  if (length(x$report_paths)) {
    cat("Report: ", paste(x$report_paths, collapse = ", "), "\n", sep = "")
  }
  for (r in order_audit_results(x$results)) {
    cat(format_audit_result_line(r), "\n", sep = "")
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

  audit <- audit_designs(designs = designs, sims = NULL, write_report = TRUE)
  print(audit)

  # Only bake designs that fully passed (not parked skips)
  ok_ids <- vapply(audit$results, function(r) {
    if (isTRUE(r$ok) && !isTRUE(r$skipped)) r$id else NA_character_
  }, character(1))
  ok_ids <- ok_ids[!is.na(ok_ids)]
  if (!is.null(audit$n_fail) && audit$n_fail > 0) {
    failed <- vapply(
      Filter(function(r) !isTRUE(r$ok), audit$results),
      function(r) r$id,
      character(1)
    )
    warning(
      "audit_designs(): ", audit$n_fail, "/", audit$n,
      " failed. Baking previews only for OK designs.\nFailed: ",
      paste(failed, collapse = ", "),
      if (length(audit$report_paths)) {
        paste0("\nSee report: ", paste(audit$report_paths, collapse = ", "))
      } else {
        ""
      },
      call. = FALSE
    )
  }
  if (!length(ok_ids)) {
    stop("refresh_library() stopped: no designs passed audit.", call. = FALSE)
  }

  bake_ids <- if (is.null(designs)) {
    # default bake: shiny-included âˆ© audit OK
    idx_ok <- index[index$id %in% ok_ids & index$include_in_shiny, , drop = FALSE]
    idx_ok$id
  } else {
    intersect(ok_ids, {
      keys <- vapply(designs, normalize_design_key, character(1))
      index$id[index$id %in% keys | index$alias %in% keys]
    })
  }
  previews <- bake_previews(designs = bake_ids, sims = sims)
  message("Previews written: ", length(previews), " (of ", length(bake_ids), " OK targets)")

  invisible(list(index = index, audit = audit, previews = previews, ok_ids = ok_ids))
}

#' Copy directory contents (Dropbox-friendly retries)
#' @noRd
copy_dir_contents <- function(from, to, tries = 6L, sleep = 1) {
  from <- normalizePath(from, winslash = "/", mustWork = TRUE)
  to <- normalizePath(to, winslash = "/", mustWork = FALSE)
  dir.create(to, recursive = TRUE, showWarnings = FALSE)

  last_err <- NULL
  for (i in seq_len(tries)) {
    ok <- tryCatch({
      old <- list.files(to, full.names = TRUE, all.files = TRUE, no.. = TRUE)
      if (length(old)) unlink(old, recursive = TRUE, force = TRUE)
      items <- list.files(from, full.names = TRUE, all.files = TRUE, no.. = TRUE)
      if (!length(items)) stop("Build directory is empty: ", from, call. = FALSE)
      copied <- vapply(
        items,
        function(it) isTRUE(file.copy(it, to, recursive = TRUE, overwrite = TRUE)),
        logical(1)
      )
      if (!all(copied)) stop("Some files failed to copy into ", to, call. = FALSE)
      TRUE
    }, error = function(e) {
      last_err <<- e
      FALSE
    })
    if (isTRUE(ok)) return(invisible(to))
    Sys.sleep(sleep)
  }
  stop(
    "Could not refresh ", to, " after ", tries, " tries",
    if (!is.null(last_err)) paste0(": ", conditionMessage(last_err)) else ".",
    "\nIf the path is under Dropbox, pause sync briefly and retry.",
    call. = FALSE
  )
}

#' Build the pkgdown site (Dropbox-safe)
#'
#' On Windows Dropbox folders, `pkgdown::build_site()` / `build_article()` often
#' fail in `xml2::write_html()` with "Invalid argument" / "Error closing file"
#' when writing directly into `docs/`. This helper builds into a local temp
#' directory, then copies the result into `docs/`.
#'
#' @param pkg Package root. Default: [find_package_root()] via
#'   `options(ResearchDesigns.root=...)` or the current working directory.
#' @param ... Passed to [pkgdown::build_site()] (for example `devel = TRUE`).
#' @return Invisibly, the path to `docs/`.
#' @export
#' @examples
#' \dontrun{
#' options(ResearchDesigns.root = "C:/path/to/ResearchDesigns")
#' build_docs()
#' }
build_docs <- function(pkg = NULL, ...) {
  if (!requireNamespace("pkgdown", quietly = TRUE)) {
    stop('Install pkgdown first: install.packages("pkgdown")', call. = FALSE)
  }
  if (is.null(pkg)) {
    pkg <- tryCatch(find_package_root(), error = function(e) getwd())
  }
  pkg <- normalizePath(pkg, winslash = "/", mustWork = TRUE)
  dest <- file.path(pkg, "docs")

  tmp_root <- tempfile("ResearchDesigns-docs-")
  dir.create(tmp_root, recursive = TRUE)
  on.exit(unlink(tmp_root, recursive = TRUE, force = TRUE), add = TRUE)

  # Keep knit/pandoc intermediates off the synced drive too
  old_tmpdir <- Sys.getenv("TMPDIR", unset = "")
  old_tmp <- Sys.getenv("TMP", unset = "")
  old_temp <- Sys.getenv("TEMP", unset = "")
  Sys.setenv(TMPDIR = tmp_root, TMP = tmp_root, TEMP = tmp_root)
  on.exit({
    if (nzchar(old_tmpdir)) Sys.setenv(TMPDIR = old_tmpdir) else Sys.unsetenv("TMPDIR")
    if (nzchar(old_tmp)) Sys.setenv(TMP = old_tmp) else Sys.unsetenv("TMP")
    if (nzchar(old_temp)) Sys.setenv(TEMP = old_temp) else Sys.unsetenv("TEMP")
  }, add = TRUE)

  message("Building pkgdown site under ", tmp_root)
  pkgdown::build_site(
    pkg = pkg,
    override = list(destination = tmp_root),
    ...
  )

  message("Copying into ", dest)
  copy_dir_contents(tmp_root, dest)
  writeLines(character(0), file.path(dest, ".nojekyll"))
  message("Done. Commit docs/ and push for GitHub Pages.")
  invisible(dest)
}
