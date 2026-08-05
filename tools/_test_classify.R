`%||%` <- function(x, y) if (is.null(x)) y else x

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
    if (!grepl("^\\s*[A-Za-z.][A-Za-z0-9._]*\\s*<-\\s*", ln)) next
    if (grepl("^\\s*(if|for|while)\\b", ln)) next
    nm <- sub("^\\s*([A-Za-z.][A-Za-z0-9._]*)\\s*<-.*$", "\\1", ln)
    rhs <- sub("^\\s*[A-Za-z.][A-Za-z0-9._]*\\s*<-\\s*", "", ln)

    expr <- tryCatch(parse(text = rhs), error = function(e) NULL)
    while (is.null(expr) && i <= n) {
      rhs <- paste(rhs, head_lines[[i]], sep = "\n")
      i <- i + 1L
      expr <- tryCatch(parse(text = rhs), error = function(e) NULL)
    }
    rhs <- trimws(rhs)

    if (grepl("\\bfunction\\s*\\(", rhs)) {
      names_out <- c(names_out, nm)
      rhs_out <- c(rhs_out, rhs)
      type_out <- c(type_out, "function")
      atomic_out <- c(atomic_out, FALSE)
      next
    }

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
  keep <- !duplicated(names_out, fromLast = TRUE)
  data.frame(
    name = names_out[keep],
    rhs = rhs_out[keep],
    type = type_out[keep],
    atomic = atomic_out[keep],
    stringsAsFactors = FALSE
  )
}

raw <- readLines("C:/WZB Dropbox/Macartan Humphreys/5_github/ResearchDesigns/inst/designs/village_campaign.R", warn = FALSE)
code <- paste(raw, collapse = "\n")
code <- sub("(?s)^---.*?---\\s*", "", code, perl = TRUE)
pre <- extract_pre_design_objects(code)
print(pre[, c("name", "type", "atomic")])
cat("steps:", paste(pre$name[pre$type %in% c("design_piece", "function")], collapse = ", "), "\n")
