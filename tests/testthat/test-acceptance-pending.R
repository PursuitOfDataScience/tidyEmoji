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

smile <- intToUtf8(0x1F600)
laugh <- intToUtf8(0x1F602)

has_verb <- function(nm) {
  nm %in% getNamespaceExports("tidyEmoji")
}


test_that("an invalid regional-indicator pair gets no country code", {
  skip_if_not(has_verb("emoji_country"),
              "emoji_country() is not implemented yet")
  xx <- intToUtf8(c(0x1F1FD, 0x1F1FD))                  # 'XX', not a country
  out <- emoji_country(tibble::tibble(text = paste("a", xx, "b")), text)
  expect_true(is.na(out$.emoji_iso2[1]))
})

test_that("an orphan skin-tone modifier is accounted for, not counted", {
  skip_if_not(has_verb("emoji_skin_tone"),
              "emoji_skin_tone() is not implemented yet")
  # A tone modifier on a base that cannot take one.
  orphan <- paste0(smile, intToUtf8(0x1F3FB))
  out <- emoji_skin_tone(tibble::tibble(text = paste("a", orphan, "b")), text)
  expect_equal(out$.emoji_n_orphan_modifiers[1], 1L)
  expect_equal(out$.emoji_n_modified[1], 0L)
})

test_that("emoji_coverage() reports what a lexicon could not score", {
  skip_if_not(has_verb("emoji_coverage"),
              "emoji_coverage() is not implemented yet")
  d <- tibble::tibble(text = c(paste("hi", smile),
                               paste("new", intToUtf8(0x1F97A)),
                               "none"))
  out <- emoji_coverage(d, text, lexicon = "sentiment")
  expect_equal(out$n_occurrences, 2L)
  expect_equal(out$n_scoreable, 1L)
  expect_equal(out$coverage_rate, 0.5)
})

test_that("presentation = 'any' reaches text-presentation glyphs", {
  skip_if_not("presentation" %in% names(formals(emoji_summary)),
              "a presentation = argument is not implemented yet")
  bare <- intToUtf8(0x2764)               # U+2764 with no U+FE0F
  d <- tibble::tibble(text = paste("bare", bare, "heart"))
  expect_equal(emoji_summary(d, text, presentation = "emoji")$n_with_emoji, 0L)
  expect_equal(emoji_summary(d, text, presentation = "any")$n_with_emoji, 1L)
})

test_that("emoji_keywords() and emoji_find() search the bundled keyword surface", {
  skip_if_not(has_verb("emoji_keywords"),
              "emoji_keywords() is not implemented yet")
  kw <- emoji_keywords(smile)
  expect_s3_class(kw, "tbl_df")
  expect_true(nrow(kw) > 0)
})

test_that("as_emoji_canonical() resolves both spellings to one", {
  skip_if_not(has_verb("as_emoji_canonical"),
              "as_emoji_canonical() is not implemented yet")
  expect_identical(as_emoji_canonical(intToUtf8(0x2764)),
                   as_emoji_canonical(intToUtf8(c(0x2764, 0xFE0F))))
})

test_that("emoji_identical() compares glyphs by codepoint identity", {
  skip_if_not(has_verb("emoji_identical"),
              "emoji_identical() is not implemented yet")
  expect_true(emoji_identical(intToUtf8(0x2764),
                              intToUtf8(c(0x2764, 0xFE0F))))
  expect_false(emoji_identical(smile, laugh))
})
