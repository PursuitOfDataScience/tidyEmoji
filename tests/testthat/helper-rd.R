# Rd text for one help topic, taken from the *installed* package.
#
# The documentation-pinning tests used to read `../../man/*.Rd`, which only
# exists when the suite runs from the source tree. Inside `R CMD check` the
# tests execute from `<pkg>.Rcheck/tests/testthat/`, which cannot see it, so
# five tests skipped with "man/ not available" on every flavour -- including
# every CRAN flavour. tools::Rd_db() reads the installed help database, so the
# same assertions now run wherever the tests do.
#
# as.character() on a parsed Rd object reconstructs the markup, so
# `\code{...}` matches still work. One difference from reading the .Rd file:
# a literal percent comes back as `%`, not the source's escaped `\%`.
rd_text <- function(topic) {
  db <- tools::Rd_db("tidyEmoji")
  key <- if (topic %in% names(db)) topic else paste0(topic, ".Rd")
  if (!key %in% names(db)) {
    return(NA_character_)
  }
  paste(as.character(db[[key]]), collapse = "")
}

# rd_text() with whitespace collapsed to single spaces.
#
# Rd prose is line-wrapped, so a phrase that reads as "the lexicon could not
# score" in the source arrives as "could not\nscore" here and a fixed = TRUE
# match for the sentence silently fails -- reporting a documentation gap that
# does not exist. Any assertion about a phrase that could straddle a line
# break should use this rather than rd_text().
rd_flat <- function(topic) {
  txt <- rd_text(topic)
  if (length(txt) != 1L || is.na(txt)) {
    return(txt)
  }
  trimws(gsub("[[:space:]]+", " ", txt))
}

# Every topic's Rd text, named by file, for the sweeps that look at all of them.
rd_all <- function() {
  db <- tools::Rd_db("tidyEmoji")
  stats::setNames(
    lapply(db, function(o) paste(as.character(o), collapse = "")),
    names(db)
  )
}

# A packaged text file, from the source tree when the suite runs there and from
# the installed package otherwise. NEWS.md installs to the package root and the
# vignette source to inst/doc/, so both are reachable inside `R CMD check`;
# reading only "../../" meant those tests skipped on every CRAN flavour.
pkg_text_file <- function(rel, installed = rel) {
  src <- testthat::test_path("..", "..", rel)
  if (file.exists(src)) {
    return(src)
  }
  parts <- as.list(strsplit(installed, "/", fixed = TRUE)[[1]])
  p <- do.call(system.file, c(parts, list(package = "tidyEmoji")))
  if (nzchar(p)) p else NA_character_
}

# The package's own code, reachable from an installed package.
#
# Three tests scanned `../../R/*.R` and so skipped inside `R CMD check`, where
# the source tree is not on disk. Everything they look for lives in the
# namespace's function objects: `pkg_exprs()` yields their bodies and formals
# as language objects (for AST walks) and `pkg_code_text()` the deparsed text
# (for pattern scans). Comments are lost, which is fine -- both scans already
# stripped comment lines.
pkg_objects <- function() {
  ns <- asNamespace("tidyEmoji")
  nms <- ls(ns, all.names = TRUE)
  keep <- vapply(nms, function(n) {
    ok <- tryCatch(is.function(get(n, envir = ns)), error = function(e) FALSE)
    isTRUE(ok)
  }, logical(1))
  stats::setNames(lapply(nms[keep], get, envir = ns), nms[keep])
}

pkg_exprs <- function() {
  lapply(pkg_objects(), function(f) {
    as.call(c(list(quote(`{`)), list(body(f)), unname(as.list(formals(f)))))
  })
}

pkg_code_text <- function() {
  vapply(pkg_objects(), function(f) {
    paste(deparse(f, width.cutoff = 500L), collapse = "\n")
  }, character(1))
}
