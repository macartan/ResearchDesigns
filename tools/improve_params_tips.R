# Improve guessed YAML param tips (keep existing non-generic tips)
# Rscript tools/improve_params_tips.R

root <- "C:/WZB Dropbox/Macartan Humphreys/5_github/ResearchDesigns"
dir <- file.path(root, "inst/designs")

TIP <- c(
  N = "Number of units (sample or population size)",
  n = "Sample size drawn from the population (when N is population size)",
  n_units = "Number of units",
  n_pairs = "Number of pairs",
  n_villages = "Number of villages in the sample",
  citizens_per_village = "Citizens sampled per village",
  N_clusters = "Number of clusters",
  N_units = "Number of units (panel cross-section size)",
  N_time_periods = "Number of time periods",
  N_subjects = "Number of subjects",
  N_tasks = "Number of conjoint tasks per subject",
  total_n = "Total sample size",
  n_x1 = "Sample size in subgroup X1 (or size allocated to X1)",
  sample_size = "Sample size",
  block_size = "Units per block",
  block_m = "Number treated per block (for blocked assignment / RI)",
  k = "Number of blocks",
  b = "Treatment effect (outcome scale)",
  a = "First-stage / instrument effect (or intercept; see design)",
  alpha = "Utility or structural intercept parameter",
  beta = "Slope / treatment coefficient",
  tau = "Between-study SD (meta-analysis) or treatment effect",
  mu = "Overall mean effect (meta-analysis)",
  delta = "Effect shift or discounting parameter",
  kappa = "Structural / scale parameter",
  rho = "Correlation between latent utilities or errors",
  ICC = "Intracluster correlation",
  r_sq = "R-squared of covariates with potential outcomes",
  control_slope = "Slope of the control outcome surface on the covariate",
  prob = "Probability of assignment to treatment",
  cluster_prob = "Cluster sampling probability",
  state_mean = "State-level mean of the outcome",
  proportion_hiding = "Share of respondents who hide sensitive traits",
  share_train = "Share of data used for training",
  share_always_takers = "Share of always-takers",
  share_never_takers = "Share of never-takers",
  share_compliers = "Share of compliers",
  share_defiers = "Share of defiers",
  effect_size = "Treatment effect size",
  cutoff = "Regression discontinuity cutoff",
  bandwidth = "RDD estimation bandwidth",
  heteroskedasticity = "Degree of heteroskedasticity in the errors",
  effort = "Survey effort / contact intensity (nonresponse)",
  deceive = "Whether the trust-game design allows deception",
  method = "Estimator or modeling method label",
  se_type = "Standard-error type passed to lm_robust (e.g. stata)",
  query = "Causal query string evaluated by the estimator",
  strategies = "Process-tracing evidence strategies (e.g. X-Y, X-Y-M)",
  covariate_names = "Names of covariates used by the learner",
  linear_hypothesis = "Linear hypothesis tested (lh_robust)",
  polynomial_degrees = "Polynomial degrees for CEF approximation",
  x_range = "Support / range of the running covariate X",
  cuts = "Cut points for stratified or grouped sampling",
  superpopulation_mean = "Superpopulation mean of the estimand",
  CATE_Z1_Z2_0 = "Conditional ATE of Z1 when Z2 = 0",
  CATE_Z2_Z1_0 = "Conditional ATE of Z2 when Z1 = 0",
  interaction = "Interaction effect of Z1 and Z2",
  controlled_direct_effect = "Controlled direct effect size",
  controlled_indirect_effect = "Controlled indirect effect size",
  total_effect = "Total effect size",
  study_sizes = "Sample sizes by study",
  study_intercepts = "Study-specific intercepts",
  study_priors = "Study-specific prior parameters",
  study_coordination = "Cross-study coordination parameter",
  study_assignment_probabilities = "Assignment probabilities by study",
  id_cols = "Identifier columns for reshaping pair-level data",
  names_from = "Column used as names_from in pivoting pair data"
)

is_generic <- function(tip) {
  grepl("^Design parameter`", tip) || grepl("^Design parameter `", tip)
}

yaml_escape <- function(x) {
  x <- gsub("\\", "\\\\", x, fixed = TRUE)
  x <- gsub('"', '\\"', x, fixed = TRUE)
  x
}

split_file <- function(path) {
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  if (!length(lines) || !grepl("^---\\s*$", lines[[1]])) {
    return(NULL)
  }
  end <- which(grepl("^---\\s*$", lines))[-1]
  if (!length(end)) return(NULL)
  list(
    yaml = lines[seq.int(2L, end[[1]] - 1L)],
    code = lines[seq.int(end[[1]] + 1L, length(lines))],
    end = end[[1]]
  )
}

files <- list.files(dir, pattern = "\\.R$", full.names = TRUE)
n_upd <- 0L
for (f in files) {
  parts <- split_file(f)
  if (is.null(parts)) next
  y <- parts$yaml
  # find params block
  p0 <- which(grepl("^params\\s*:", y))
  if (!length(p0)) next
  i <- p0[[1]] + 1L
  changed <- FALSE
  while (i <= length(y) && grepl("^\\s+", y[[i]])) {
    m <- regexec('^\\s*\"([^\"]+)\"\\s*:\\s*\"(.*)\"\\s*$', y[[i]])
    g <- regmatches(y[[i]], m)[[1]]
    if (length(g) >= 3) {
      nm <- g[[2]]
      tip <- g[[3]]
      # unescape minimal
      tip_plain <- gsub('\\"', '"', tip, fixed = TRUE)
      new_tip <- if (nm %in% names(TIP)) unname(TIP[[nm]]) else if (is_generic(tip_plain)) {
        paste0("Modifiable design parameter '", nm, "'")
      } else tip_plain
      # also upgrade if we have a curated tip even when non-generic (prefer curated)
      if (nm %in% names(TIP)) new_tip <- unname(TIP[[nm]])
      if (!identical(new_tip, tip_plain)) {
        y[[i]] <- sprintf('  "%s": "%s"', nm, yaml_escape(new_tip))
        changed <- TRUE
      }
    }
    i <- i + 1L
  }
  if (changed) {
    out <- c("---", y, "---", parts$code)
    writeLines(out, f, useBytes = TRUE)
    n_upd <- n_upd + 1L
  }
}
message("Updated tips in ", n_upd, " files")
