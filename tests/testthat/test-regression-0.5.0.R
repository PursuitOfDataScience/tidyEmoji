# Regression tests and target behaviour for the 0.5.0 correctness release.
#
# Two kinds of test live here, and the difference is deliberate:
#
# 1. Tests that run now, pinning behaviour the 0.5.0 planning audit suspected
#    was wrong and measurement found was right. A suspicion that has been
#    checked and not written down gets re-raised by the next audit, at the same
#    cost as the first one.
# 2. Tests for verbs 0.5.0 is meant to add, which skip until the verb exists.
#    They are the acceptance criteria, in the file where they will run, rather
#    than a code block in a planning document that no test runner reads.
#
# Roadmap section numbers refer to next_release.md.

smile  <- intToUtf8(0x1F600)
laugh  <- intToUtf8(0x1F602)
us     <- intToUtf8(c(0x1F1FA, 0x1F1F8))
jp     <- intToUtf8(c(0x1F1EF, 0x1F1F5))

# A verb the release has not added yet must not fail the suite: the tests that
# specify it stand down by name, so `testthat` reports what is outstanding.
has_verb <- function(nm) {
  nm %in% getNamespaceExports("tidyEmoji")
}

grouped_fixture <- function() {
  dplyr::group_by(
    tibble::tibble(
      grp  = c("a", "a", "b", "b"),
      # two emoji in one row of each group, so the n-gram comparison below has
      # something to compare in both: with one emoji per row there are no
      # n-grams at all and the test would pass on an empty tibble.
      text = c(paste("x", smile, laugh), paste("y", laugh),
               paste("p", us, smile), paste("q", jp))
    ),
    grp
  )
}


# ---------------------------------------------------------------------------
# Roadmap 1.5 named three aggregators as pooling grouped data silently. The
# count was wrong three times over: 0.4.0 guarded emoji_version_profile(), and
# the other two were never aggregators at all. Measured 2026-09-17, so the
# audit does not have to re-derive it.
# ---------------------------------------------------------------------------

test_that("emoji_categorize() carries a grouping through instead of pooling it", {
  g <- grouped_fixture()
  out <- emoji_categorize(g, text)
  expect_true(dplyr::is_grouped_df(out))
  expect_equal(dplyr::group_vars(out), "grp")
  # Row-preserving verbs answer per row, so the grouping cannot change the
  # values. That is why silence is right here and a warning would not be.
  expect_equal(as.data.frame(out),
               as.data.frame(emoji_categorize(dplyr::ungroup(g), text)))
})

test_that("emoji_categorize() stays silent on grouped input", {
  expect_no_warning(emoji_categorize(grouped_fixture(), text))
})

test_that("emoji_ngrams() has no grouping to ignore", {
  g <- grouped_fixture()
  out <- emoji_ngrams(g, text)
  # One row per n-gram occurrence, keyed by .row_number, carrying none of the
  # user's columns: there is nothing for a grouping to apply to.
  expect_false(dplyr::is_grouped_df(out))
  expect_named(out, c(".row_number", ".position", ".emoji_ngram"))
  # one n-gram from each group's two-emoji row, so this is not an empty
  # comparison
  expect_equal(nrow(out), 2L)
  expect_equal(sort(out$.row_number), c(1L, 3L))
  expect_equal(as.data.frame(out),
               as.data.frame(emoji_ngrams(dplyr::ungroup(g), text)))
})

test_that("emoji_ngrams() stays silent on grouped input", {
  expect_no_warning(emoji_ngrams(grouped_fixture(), text))
})


# ---------------------------------------------------------------------------
# Roadmap 1.1's other half. The grapheme fix shipped in 0.4.0; what was left
# owed was saying on the help page that positions are logical order, because a
# right-to-left corpus reads "final" the other way round.
# ---------------------------------------------------------------------------

test_that("?emoji_position states that positions are logical, not visual", {
  txt <- rd_text("emoji_position")
  skip_if(is.na(txt), "emoji_position help topic not available")
  # The whole phrase, not the two words apart: "logical" and "visual" each
  # appear elsewhere in R documentation prose often enough that matching them
  # separately would pass on a page that had lost the sentence.
  expect_match(txt, "(storage) order", fixed = TRUE)
  expect_match(txt, "not visual order", fixed = TRUE)
})


# ---------------------------------------------------------------------------
# Target behaviour for the 0.5.0 items that still need code. Each skips until
# its verb exists, and names the roadmap section that specified it.
# ---------------------------------------------------------------------------

test_that("an invalid regional-indicator pair gets no country code (roadmap 1.2)", {
  skip_if_not(has_verb("emoji_country"),
              "emoji_country() is a 0.5.0 target (roadmap 1.2, 4.2)")
  xx <- intToUtf8(c(0x1F1FD, 0x1F1FD))                  # 'XX', not a country
  out <- emoji_country(tibble::tibble(text = paste("a", xx, "b")), text)
  expect_true(is.na(out$.emoji_iso2[1]))
})

test_that("an orphan skin-tone modifier is accounted for, not counted (roadmap 1.2)", {
  skip_if_not(has_verb("emoji_skin_tone"),
              "emoji_skin_tone() is a 0.5.0 target (roadmap 1.2, 4.1)")
  # A tone modifier on a base that cannot take one.
  orphan <- paste0(smile, intToUtf8(0x1F3FB))
  out <- emoji_skin_tone(tibble::tibble(text = paste("a", orphan, "b")), text)
  expect_equal(out$.emoji_n_orphan_modifiers[1], 1L)
  expect_equal(out$.emoji_n_modified[1], 0L)
})

test_that("emoji_coverage() reports what a lexicon could not score (roadmap 1.7)", {
  skip_if_not(has_verb("emoji_coverage"),
              "emoji_coverage() is a 0.5.0 target (roadmap 1.7, 10.7)")
  d <- tibble::tibble(text = c(paste("hi", smile), paste("new", intToUtf8(0x1F97A)), "none"))
  out <- emoji_coverage(d, text, lexicon = "sentiment")
  expect_equal(out$n_occurrences, 2L)
  expect_equal(out$n_scoreable, 1L)
  expect_equal(out$coverage_rate, 0.5)
})

test_that("presentation = 'any' reaches text-presentation glyphs (roadmap 4.7)", {
  skip_if_not("presentation" %in% names(formals(emoji_summary)),
              "presentation = is a 0.5.0 target (roadmap 4.7)")
  bare <- intToUtf8(0x2764)               # U+2764 with no U+FE0F
  d <- tibble::tibble(text = paste("bare", bare, "heart"))
  expect_equal(emoji_summary(d, text, presentation = "emoji")$n_with_emoji, 0L)
  expect_equal(emoji_summary(d, text, presentation = "any")$n_with_emoji, 1L)
})

test_that("emoji_keywords() and emoji_find() search the bundled keyword surface (roadmap 4.6)", {
  skip_if_not(has_verb("emoji_keywords"),
              "emoji_keywords() is a 0.5.0 target (roadmap 4.6)")
  kw <- emoji_keywords(smile)
  expect_s3_class(kw, "tbl_df")
  expect_true(nrow(kw) > 0)
})

test_that("as_emoji_canonical() resolves both spellings to one (roadmap 4.4)", {
  skip_if_not(has_verb("as_emoji_canonical"),
              "as_emoji_canonical() is a 0.5.0 target (roadmap 4.4)")
  expect_identical(as_emoji_canonical(intToUtf8(0x2764)),
                   as_emoji_canonical(intToUtf8(c(0x2764, 0xFE0F))))
})

test_that("emoji_identical() compares glyphs by codepoint identity (roadmap 10.1)", {
  skip_if_not(has_verb("emoji_identical"),
              "emoji_identical() is a 0.5.0 target (roadmap 10.1)")
  expect_true(emoji_identical(intToUtf8(0x2764),
                              intToUtf8(c(0x2764, 0xFE0F))))
  expect_false(emoji_identical(smile, laugh))
})
