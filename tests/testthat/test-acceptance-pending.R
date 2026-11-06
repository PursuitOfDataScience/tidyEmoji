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
# emoji_identical(), all now in test-regression-0.6.0.R; 0.7.0 moved
# emoji_skin_tone()'s and emoji_runs()'s to test-regression-0.7.0.R.

smile <- intToUtf8(0x1F600)
party <- intToUtf8(0x1F389)

has_verb <- function(nm) {
  nm %in% getNamespaceExports("tidyEmoji")
}


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
