# Regression tests for the 0.5.0 correctness release.
#
# Every test here runs. They pin behaviour the pre-release audit suspected was
# wrong and measurement found was right: a suspicion that has been checked and
# not written down gets re-raised by the next audit, at the same cost as the
# first one.
#
# Acceptance criteria for verbs that do not exist yet live in
# test-acceptance-pending.R, not here. A file named for a released version
# should describe that version, and a test that skips with "0.5.0 will add
# this" in the release that *is* 0.5.0 says the opposite of what it means.

smile  <- intToUtf8(0x1F600)
laugh  <- intToUtf8(0x1F602)
us     <- intToUtf8(c(0x1F1FA, 0x1F1F8))
jp     <- intToUtf8(c(0x1F1EF, 0x1F1F5))

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
# The pre-release audit named three aggregators as pooling grouped data
# silently. The count was wrong three times over: 0.4.0 guarded
# emoji_version_profile(), and the other two were never aggregators at all.
# Measured 2026-09-17, so the next audit does not have to re-derive it.
# ---------------------------------------------------------------------------

test_that("emoji_categorize() carries a grouping through instead of pooling it", {
  g <- grouped_fixture()
  out <- emoji_categorize(g, text)
  expect_true(dplyr::is_grouped_df(out))
  expect_equal(dplyr::group_vars(out), "grp")
  # The verb answers per row, so a grouping cannot change what it returns.
  # That is why silence is right here and a warning would not be.
  expect_equal(as.data.frame(out),
               as.data.frame(emoji_categorize(dplyr::ungroup(g), text)))
  # Every row of `g` carries an emoji, so it cannot show what happens to one
  # that does not. `@return` says the result is "filtered to the rows
  # containing at least one emoji", and a NEWS entry described the verb as
  # "row-preserving" instead; pin the fact so the two cannot disagree again.
  # Dropping rows is still not pooling: it cannot merge two groups.
  expect_identical(nrow(out), nrow(g))
  mixed <- dplyr::group_by(
    tibble::tibble(grp = c("a", "a", "b", "b"),
                   text = c(paste("x", smile), "no emoji at all",
                            paste("p", laugh), "none here either")),
    grp)
  dropped <- emoji_categorize(mixed, text)
  expect_identical(nrow(dropped), 2L)
  expect_true(dplyr::is_grouped_df(dropped))
  # both groups survive, so no group was merged away or emptied silently
  expect_identical(sort(unique(dropped$grp)), c("a", "b"))
  expect_identical(nrow(dropped),
                   nrow(emoji_categorize(dplyr::ungroup(mixed), text)))
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
# The other half of the grapheme work. The fix itself shipped in 0.4.0; what
# was left owed was saying on the help page that positions are logical order,
# because a right-to-left corpus reads "final" the other way round.
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
# The shortcode round trip is faithful only when the text held no shortcode
# tokens of its own. text_to_emoji() cannot tell a token emoji_sanitize()
# wrote from one that was always there, so a Slack or GitHub export where
# people type `:thumbsup:` gains emoji it never contained. The behaviour is
# correct and unavoidable given the design; what was missing was any statement
# of it, in a help page that enumerates every other way the round trip can
# fail. Pinned from both sides: the inflation, and the sentence.
# ---------------------------------------------------------------------------

test_that("a pre-existing shortcode token inflates the count by one, once", {
  d <- tibble::tibble(text = c("nice work :thumbsup:",
                               paste("nice work :thumbsup:", smile)))
  before <- emoji_density(d, text)$.emoji_n
  back <- text_to_emoji(emoji_sanitize(d, text, policy = "shortcode"), text)
  after <- emoji_density(back, text)$.emoji_n
  expect_equal(before, c(0L, 1L))
  expect_equal(after, c(1L, 2L))
  # bounded at one pass: by now the token is a glyph, so nothing else changes
  again <- text_to_emoji(emoji_sanitize(back, text, policy = "shortcode"), text)
  expect_identical(again$text, back$text)
})

test_that("colons that are not shortcode-shaped survive the round trip", {
  d <- tibble::tibble(text = c("meet at 10:30", "ratio 3:4", "http://x.org/a"))
  back <- text_to_emoji(emoji_sanitize(d, text, policy = "shortcode"), text)
  expect_identical(back$text, d$text)
  expect_equal(emoji_density(back, text)$.emoji_n, c(0L, 0L, 0L))
})

test_that("?emoji_sanitize states the assumption about the input text", {
  txt <- rd_flat("emoji_sanitize")
  skip_if(is.na(txt), "emoji_sanitize help topic not available")
  expect_match(txt, "cannot tell a", fixed = TRUE)
  expect_match(txt, "token this verb wrote from one the text already", fixed = TRUE)
})

test_that("?text_to_emoji states the same limitation from its own side", {
  txt <- rd_flat("text_to_emoji")
  skip_if(is.na(txt), "text_to_emoji help topic not available")
  expect_match(txt, "The converse is a limitation, not a feature", fixed = TRUE)
})


# ---------------------------------------------------------------------------
# Whitespace tokenisation and scriptio continua. 0.5.0 fixed the character
# class that dropped non-Latin context words, which makes a CJK corpus a
# supported input; what it does not do is segment one. A Chinese clause has no
# whitespace, so it arrives as one token and emoji_collocations() finds nothing
# at all. Correct, silent, and now stated on both help pages.
# ---------------------------------------------------------------------------

test_that("an unsegmented script yields one token per clause", {
  zh <- tibble::tibble(text = c(
    paste0(intToUtf8(c(0x4ECA, 0x5929, 0x5929, 0x6C14, 0x5F88, 0x597D)), smile),
    paste0(intToUtf8(c(0x4ECA, 0x5929, 0x5FC3, 0x60C5, 0x5F88, 0x597D)), smile),
    paste0(intToUtf8(c(0x660E, 0x5929, 0x53BB, 0x5317, 0x4EAC)), smile)))
  en <- tibble::tibble(text = c(
    paste("the weather is good today", smile),
    paste("my mood is good today", smile),
    paste("going to beijing tomorrow", smile)))
  cz <- emoji_collocations(zh, text, min_n = 1)
  ce <- emoji_collocations(en, text, min_n = 1)
  # every Chinese "word" is a whole clause, so every type occurs exactly once
  expect_equal(nrow(cz), 3L)
  expect_true(all(cz$n == 1L))
  # the same three sentences in English do produce repeated collocates
  expect_true(any(ce$n > 1L))
  # so the default min_n cannot clear anything on the Chinese corpus
  expect_equal(nrow(emoji_collocations(zh, text)), 0L)
  # unit = "char" is the documented way round it
  ctx <- emoji_context(zh, text, window = 3, unit = "char")
  expect_equal(nrow(ctx), 3L)
  expect_true(all(nzchar(ctx$.emoji_context_left)))
})

test_that("both help pages state the scriptio continua consequence", {
  cx <- rd_flat("emoji_context")
  skip_if(is.na(cx), "emoji_context help topic not available")
  expect_match(cx, "does not put spaces between", fixed = TRUE)
  cl <- rd_flat("emoji_collocations")
  skip_if(is.na(cl), "emoji_collocations help topic not available")
  expect_match(cl, "cannot find a collocation at all", fixed = TRUE)
})
