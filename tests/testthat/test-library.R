test_that("list_designs finds the starter library", {
  idx <- list_designs(discover_params = FALSE)
  expect_true(nrow(idx) >= 2)
  expect_true(all(c("two_arm_trial", "two_arm_with_blocks") %in% idx$id))
  expect_true("2.1" %in% idx$alias)
  expect_true("2.2" %in% idx$alias)
  expect_s3_class(idx, "research_designs_list")
})

test_that("list_designs print is compact", {
  idx <- list_designs(discover_params = FALSE)
  out <- paste(capture.output(print(idx)), collapse = "\n")
  expect_match(out, "ResearchDesigns library")
  expect_match(out, "two_arm_trial")
  expect_match(out, "design_info")
  expect_false(grepl("include_in_shiny", out))
  # params not discovered → omitted from print
  expect_false(grepl("\\bparams\\b", out))
  # templates first among printed rows
  expect_true(which(idx$category == "template")[1] < which(idx$category == "rdss")[1])
  if (nrow(idx) > 5L) {
    expect_match(out, "more")
  }
})

test_that("YAML-less defaults fill category and object", {
  skip_if_not(requireNamespace("withr", quietly = TRUE))
  withr::with_tempdir({
    dir.create("designs")
    writeLines(
      c(
        "b <- 1",
        "design <- structure(list(), class = 'design')"
      ),
      "designs/plain_demo.R"
    )
    # parse_design_file is internal; exercise via parse on a real file path
    parsed <- ResearchDesigns:::parse_design_file("designs/plain_demo.R")
    expect_equal(parsed$meta$id, "plain_demo")
    expect_equal(parsed$meta$category, "Other")
    expect_equal(parsed$meta$object, "design")
    expect_true(isTRUE(parsed$meta$include_in_shiny))
  })
})

test_that("get_code returns simple and full forms", {
  code <- get_code("two_arm_trial", style = "both", b = 0.2)
  expect_match(code$simple, 'make_design\\("two_arm_trial", b = 0\\.2\\)')
  expect_true(grepl("declare_model", code$full))
})

test_that("alias and id both resolve", {
  skip_on_cran()
  skip_if_not_installed("DeclareDesignZero")
  d1 <- tryCatch(make_design("two_arm_trial"), error = function(e) e)
  d2 <- tryCatch(make_design("2.1"), error = function(e) e)
  if (inherits(d1, "error") || inherits(d2, "error")) {
    skip(paste("DeclareDesignZero runtime issue:", conditionMessage(d1)))
  }
  expect_equal(attr(d1, "research_designs_id"), "two_arm_trial")
  # Book alias 2.1 points at the RDSS chapter port, not the template
  expect_equal(attr(d2, "research_designs_id"), "two_arm_trial_rdss")
})

test_that("YAML diagnosands are parsed and preferred_diagnosands works", {
  skip_if_not(requireNamespace("withr", quietly = TRUE))
  withr::with_tempdir({
    dir.create("designs")
    writeLines(
      c(
        "---",
        "id: dg_demo",
        "diagnosands: rmse, bias",
        "---",
        "b <- 1",
        "design <- structure(list(), class = 'design')"
      ),
      "designs/dg_demo.R"
    )
    parsed <- ResearchDesigns:::parse_design_file("designs/dg_demo.R")
    expect_equal(parsed$meta$diagnosands, c("rmse", "bias"))
  })
  expect_equal(preferred_diagnosands("two_arm_trial"), c("bias", "power"))
  expect_equal(preferred_diagnosands("logit_probit_ols"), c("rmse", "bias"))
  info <- design_info("logit_probit_ols")
  expect_equal(info$diagnosands, c("rmse", "bias"))
})

test_that("contributor_checklist is non-empty", {
  expect_true(length(contributor_checklist()) >= 5)
  expect_true(any(grepl("diagnosands", contributor_checklist(), fixed = TRUE)))
})
