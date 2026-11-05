# Acceptance criteria for verbs the package does not have yet.
#
# Each test states what the verb must do and stands down by name until it
# exists, so `testthat` reports what is outstanding instead of a planning
# document no test runner reads. Nothing here fails: a skip is the whole point.
#
# Deliberately not named for a version. These lived in test-regression-0.5.0.R
# and skipped with "is a 0.5.0 target", which read as a contradiction in the
# release that shipped 0.5.0 and would have to be rewritten at every release
# whether or not the verb had landed. When one does land, move its test into
# the regression file for the version that shipped it and delete the guard.
# 0.6.0 moved six out this way: emoji_country(), emoji_coverage(),
# presentation = "any", emoji_keywords(), as_emoji_canonical() and
# emoji_identical(), all now in test-regression-0.6.0.R.

smile <- intToUtf8(0x1F600)
party <- intToUtf8(0x1F389)

has_verb <- function(nm) {
  nm %in% getNamespaceExports("tidyEmoji")
}


test_that("an orphan skin-tone modifier is accounted for, not counted", {
  skip_if_not(has_verb("emoji_skin_tone"),
              "emoji_skin_tone() is not implemented yet")
  # A tone modifier on a base that cannot take one. 0.6.0 stopped counting
  # the swatch as an emoji; the identity verbs still have to report it.
  orphan <- paste0(smile, intToUtf8(0x1F3FB))
  out <- emoji_skin_tone(tibble::tibble(text = paste("a", orphan, "b")), text)
  expect_equal(out$.emoji_n_orphan_modifiers[1], 1L)
  expect_equal(out$.emoji_n_modified[1], 0L)
})

test_that("emoji_runs() segments spans and flags reduplication", {
  skip_if_not(has_verb("emoji_runs"), "emoji_runs() is not implemented yet")
  d <- tibble::tibble(text = c(
    paste0("wow ", smile, smile, smile),   # one run, length 3, reduplication
    paste0(smile, " ok ", party),          # two runs, length 1 each
    paste0(smile, party)                   # one run, length 2, not reduplication
  ))
  out <- emoji_runs(d, text)
  expect_equal(nrow(out), 4L)
  expect_equal(out$.run_length, c(3L, 1L, 1L, 2L))
  expect_equal(out$.run_is_reduplication, c(TRUE, FALSE, FALSE, FALSE))
  expect_equal(out$.run_position[1], "END")
})

test_that("emoji_sentiment_role() classifies a mitigation", {
  skip_if_not(has_verb("emoji_sentiment_role"),
              "emoji_sentiment_role() is not implemented yet")
  d <- tibble::tibble(text = paste("great, another delay", intToUtf8(0x1F621)))
  out <- emoji_sentiment_role(d, text,
                              text_score = 0.6,           # with the emoji
                              text_score_without = 0.8)   # without it
  expect_equal(out$.emoji_role[1], "mitigation")
  expect_true(out$.emoji_state[1] %in% c("keep", "add_negative"))
})
