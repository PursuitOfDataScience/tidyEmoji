# Regression tests for 0.7.0.

# --- M1: the CRAN time budget ------------------------------------------------
#
# Every sweep stands down on CRAN through skip_sweep(twin = ), naming the test
# that runs there in its place (helper-sweep.R). The pairing is only worth
# something while the twin exists, so it is checked here: a twin that is
# renamed or deleted fails this test rather than leaving its sweep's property
# untested on CRAN without a word.

# The problems with the skip_sweep() calls in `files`: a twin that names no
# test, a sweep that names itself, a "no twin:" with no reason after it, or a
# twin that is not a string literal (which nothing could check).
sweep_twin_problems <- function(files) {
  descs <- character()
  calls <- list()
  # the sub-calls of `e`, skipping the empty argument of `x[, 1]`, which
  # cannot even be read into a variable
  sub_calls <- function(e) {
    out <- list()
    for (i in seq_along(e)[-1L]) {
      if (is.symbol(e[[i]]) && !nzchar(as.character(e[[i]]))) next
      if (is.call(e[[i]])) out[[length(out) + 1L]] <- e[[i]]
    }
    out
  }
  walk <- function(e, file) {
    if (!is.call(e)) return(invisible())
    fn <- e[[1L]]
    if (is.name(fn) && identical(as.character(fn), "test_that") &&
        length(e) >= 2L && is.character(e[[2L]])) {
      descs <<- c(descs, e[[2L]])
      calls[[length(calls) + 1L]] <<- list(file = file, desc = e[[2L]],
                                           body = e)
      return(invisible())
    }
    for (a in sub_calls(e)) walk(a, file)
    invisible()
  }
  for (f in files) {
    for (e in parse(f, keep.source = FALSE)) walk(e, basename(f))
  }
  problems <- character()
  n_sweeps <- 0L
  # A sweep says so in a statement of its own at the top level of its block.
  # A call nested in an expectation, as in the tests of skip_sweep() itself
  # below, is an argument to that expectation and not a sweep.
  find_sweeps <- function(e) {
    code <- if (length(e) >= 3L) e[[3L]] else NULL
    if (!is.call(code) || !identical(code[[1L]], as.name("{"))) return(list())
    Filter(function(st) {
      is.call(st) && is.name(st[[1L]]) &&
        identical(as.character(st[[1L]]), "skip_sweep")
    }, sub_calls(code))
  }
  for (cl in calls) {
    for (s in find_sweeps(cl$body)) {
      n_sweeps <- n_sweeps + 1L
      args <- as.list(s)[-1L]
      twin <- if ("twin" %in% names(args)) args$twin else args[[1L]]
      where <- paste0(cl$file, ": ", cl$desc)
      if (!is.character(twin) || length(twin) != 1L || is.na(twin)) {
        problems <- c(problems, paste(where, "names its twin by an expression"))
      } else if (startsWith(twin, "no twin:")) {
        if (!nzchar(trimws(sub("^no twin:", "", twin)))) {
          problems <- c(problems, paste(where, "gives no reason for no twin"))
        }
      } else if (identical(twin, cl$desc)) {
        problems <- c(problems, paste(where, "names itself as its twin"))
      } else if (!twin %in% descs) {
        problems <- c(problems, paste0(where, " names a missing twin: ", twin))
      }
    }
  }
  attr(problems, "n_sweeps") <- n_sweeps
  problems
}

test_that("every sweep skipped on CRAN names a twin that exists", {
  files <- Sys.glob(testthat::test_path("test-*.R"))
  skip_if(!length(files), "test sources not available")
  problems <- sweep_twin_problems(files)
  expect_identical(as.character(problems), character(0))
  # the suite really has sweeps, or the check above asserted nothing
  expect_gt(attr(problems, "n_sweeps"), 30L)

  # and the check can fail: a sweep whose twin was deleted is caught, as is
  # one that names itself or gives no reason
  bad <- tempfile(fileext = ".R")
  on.exit(unlink(bad), add = TRUE)
  writeLines(c(
    'test_that("a sweep", { skip_sweep(twin = "a twin nobody wrote"); expect_true(TRUE) })',
    'test_that("a selfish sweep", { skip_sweep(twin = "a selfish sweep"); expect_true(TRUE) })',
    'test_that("a terse sweep", { skip_sweep(twin = "no twin: "); expect_true(TRUE) })',
    'test_that("a kept sweep", { skip_sweep(twin = "its twin"); expect_true(TRUE) })',
    'test_that("its twin", { expect_true(TRUE) })'
  ), bad)
  caught <- sweep_twin_problems(bad)
  expect_length(caught, 3L)
  expect_match(caught[1L], "names a missing twin: a twin nobody wrote",
               fixed = TRUE)
  expect_match(caught[2L], "names itself", fixed = TRUE)
  expect_match(caught[3L], "no reason", fixed = TRUE)
})

test_that("skip_sweep() stands a sweep down on CRAN and nowhere else", {
  expect_error(skip_sweep(twin = ""), "twin")
  expect_error(skip_sweep(twin = NA_character_), "twin")
  old <- Sys.getenv("NOT_CRAN", unset = NA)
  on.exit(if (is.na(old)) Sys.unsetenv("NOT_CRAN") else
    Sys.setenv(NOT_CRAN = old), add = TRUE)
  Sys.setenv(NOT_CRAN = "true")
  expect_true(skip_sweep(twin = "any"))
  Sys.setenv(NOT_CRAN = "false")
  if (!interactive()) {
    expect_condition(skip_sweep(twin = "the twin's name"),
                     "the twin's name", class = "skip")
  }
})

test_that("the sample a twin draws is deterministic and keeps the hard cases", {
  ref <- tidyEmoji:::emoji_reference()
  a <- sweep_rows(ref$emoji, 200L)
  # the same rows whatever order the glyphs arrive in
  perm <- rev(seq_along(ref$emoji))
  expect_identical(sort(perm[sweep_rows(ref$emoji[perm], 200L)]), a)
  # every hard case the catalogue holds is in, and the draw is near its size
  hard <- which(ref$emoji %in% sweep_hard_cases())
  expect_true(all(hard %in% a))
  expect_gt(length(hard), 20L)
  expect_lt(length(a), 200L + length(hard) + 1L)
})
