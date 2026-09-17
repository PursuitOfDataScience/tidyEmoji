# Spell check the help pages, vignettes, README and NEWS. Words that are real
# but not in the dictionary go in inst/WORDLIST.
#
# error = FALSE so a typo never fails someone else's `R CMD check`, and
# skip_on_cran because a dictionary difference on a CRAN flavour is not a
# defect in this package. The weekly `checks` workflow is where a typo is meant
# to be caught, and there it does fail the job.
if (requireNamespace("spelling", quietly = TRUE)) {
  spelling::spell_check_test(vignettes = TRUE, error = FALSE,
                             skip_on_cran = TRUE)
}
