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


# The emoji release every catalogue figure in this package was derived from.
# Defined here rather than in a test file so the gate below is available to
# every file, and so `R CMD check` cannot reach a count assertion before the
# helper exists.
doc_emoji_version <- function() "16.0.0"

# Roughly seventy figures in the documentation and in these tests are counts
# taken from `emoji::emojis` -- 5042 rows, 3790 keys, 212 undetectable
# spellings, and so on. They are pinned deliberately, because the pinning is
# what catches doc-vs-data drift. But `DESCRIPTION` declares `emoji
# (>= 16.0.0)` with no upper bound, and the emoji package's version tracks the
# Unicode emoji version: the day 17.0.0 lands, every one of those figures
# moves at once and this suite would go red on all 13 CRAN flavours
# simultaneously, for a reason the maintainer did not cause and cannot
# schedule. CRAN archives packages whose checks stay broken.
#
# So: loud everywhere the maintainer can act on it, silent where they cannot.
# On the checking machine the figures are simply not the subject any more, and
# the version-identity test below says so in one place instead of seventy.
skip_if_catalogue_moved <- function() {
  have <- as.character(utils::packageVersion("emoji"))
  testthat::skip_if_not(
    identical(have, doc_emoji_version()),
    paste0("catalogue figures were derived from emoji ", doc_emoji_version(),
           "; installed is ", have))
  invisible(TRUE)
}


# Restore the lexicon registry when the CALLING frame exits.
#
# register_emoji_lexicon() writes into the package's session cache and there is
# no public counterpart that removes an entry, so a test that registers leaves
# the entry behind for every test that runs after it -- across files, since
# test-emotion.R sorts before test-invariants.R. Measured before this helper
# existed: eleven lexicons were still registered when the suite finished, and
# one test coped by wiping the registry outright, which then hid every
# registration made before it. That makes results depend on file order and on
# line order within a file.
#
# with_clean_registry() (in test-invariants.R) wraps an expression; this wraps
# a test. Call it as the first line of any test_that() that registers.
#
# The saved value and the cache environment are substituted into the exit
# expression as values, so nothing has to resolve in the caller's frame, and
# no withr dependency is needed -- `::` on an undeclared package is itself an
# R CMD check WARNING.
local_clean_registry <- function(env = parent.frame()) {
  cache <- asNamespace("tidyEmoji")$.tidyEmoji_cache
  expr <- substitute(base::assign("lexicons", SAVED, envir = CACHE),
                     list(SAVED = cache$lexicons, CACHE = cache))
  do.call(base::on.exit, list(expr, add = TRUE), envir = env)
  invisible(TRUE)
}
