# Regression tests for the 0.2.1 correctness patch
# See next_release.md §4 for the full audit.

# ---------------------------------------------------------------------------
# 4.1: Key-normalisation asymmetry
# ---------------------------------------------------------------------------

test_that("emoji_tokens resolves qualified emoji (U+FE0F) to non-NA name/category", {
  # The qualified heart carries U+FE0F; the reference stores the unqualified
  # form. The name/category lookup must normalise the key first.
  out <- emoji_tokens(data.frame(text = "❤️"), text)
  expect_false(is.na(out$.emoji_name))
  expect_false(is.na(out$.emoji_category))
})

test_that("emoji_frequency resolves qualified emoji (U+FE0F) to non-NA metadata", {
  out <- emoji_frequency(data.frame(text = "❤️"), text)
  expect_false(is.na(out$name))
  expect_false(is.na(out$group))
})

test_that("emoji_categorize keeps qualified emoji (U+FE0F) rather than dropping the row", {
  out <- emoji_categorize(data.frame(text = "❤️"), text)
  expect_equal(nrow(out), 1)
  expect_false(is.na(out$.emoji_category))
})

test_that("top_n_emojis(duplicated = TRUE) keeps qualified emoji via key join", {
  out <- top_n_emojis(data.frame(text = "❤️"), text, duplicated = TRUE)
  expect_gt(nrow(out), 0)
})

# ---------------------------------------------------------------------------
# 4.2: Unified detection — summary/filter agree with extraction verbs
# ---------------------------------------------------------------------------

test_that("emoji_summary and emoji_tokens agree on what 'has an emoji' means", {
  df <- data.frame(text = c("hi \U0001f600", "plain", "❤️", ""))
  s <- emoji_summary(df, text)
  tokens <- emoji_tokens(df, text)
  n_distinct_emoji_rows <- nrow(tokens)
  expect_equal(s$n_with_emoji, n_distinct_emoji_rows)
})

# ---------------------------------------------------------------------------
# 4.3: Grouped data frames warn
# ---------------------------------------------------------------------------

test_that("emoji_summary warns when given a grouped data frame", {
  df <- data.frame(g = c("a", "a", "b"), text = c("\U0001f600", "", "\U0001f621"))
  expect_warning(emoji_summary(dplyr::group_by(df, g), text),
                 class = "lifecycle_warning_deprecated")
})

test_that("emoji_frequency warns when given a grouped data frame", {
  df <- data.frame(g = c("a", "a", "b"), text = c("\U0001f600", "", "\U0001f621"))
  expect_warning(emoji_frequency(dplyr::group_by(df, g), text),
                 class = "lifecycle_warning_deprecated")
})

test_that("top_n_emojis warns when given a grouped data frame", {
  df <- data.frame(g = c("a", "a", "b"), text = c("\U0001f600", "", "\U0001f621"))
  expect_warning(top_n_emojis(dplyr::group_by(df, g), text),
                 class = "lifecycle_warning_deprecated")
})

# ---------------------------------------------------------------------------
# 4.6: top_n_emojis n semantics and tie-breaking
# ---------------------------------------------------------------------------

test_that("top_n_emojis n counts distinct emoji, not rows in duplicated mode", {
  df <- data.frame(text = c("\U0001f600", "\U0001f600", "\U0001f621"))
  dup <- top_n_emojis(df, text, n = 1, duplicated = TRUE)
  expect_equal(nrow(dup), 2)   # 1 emoji, 2 names -> 2 rows
  expect_equal(unique(dup$unicode), "\U0001f600")
})
test_that("top_n_emojis(duplicated = TRUE) preserves the exact glyph (no NA unicode)", {
  # The unicode column must be the glyph the extractor actually returned, never
  # NA and never a differently-qualified twin pulled from the crosswalk.
  df <- data.frame(text = c("\U0001f600\U0001f600", "\U0001f621", "\U0001f3c1",
                            "\u2764\ufe0f"))
  dup <- top_n_emojis(df, text, n = 10, duplicated = TRUE)
  expect_false(any(is.na(dup$unicode)))
  freq <- emoji_frequency(df, text)
  expect_true(all(dup$unicode %in% freq$emoji))
  # each (glyph, alias) pair appears at most once (no qualified/unqualified twins)
  expect_equal(nrow(dplyr::distinct(dup, unicode, emoji_name)), nrow(dup))
})

test_that("top_n_emojis(duplicated = TRUE) keeps a qualified (U+FE0F) glyph", {
  out <- top_n_emojis(data.frame(text = "\u2764\ufe0f"), text, duplicated = TRUE)
  expect_gt(nrow(out), 0)
  expect_false(any(is.na(out$unicode)))
})

test_that("grouped top_n_emojis warns only once (not via emoji_frequency too)", {
  df <- data.frame(g = c("a", "a", "b"), text = c("\U0001f600", "", "\U0001f621"))
  warns <- list()
  withCallingHandlers(
    top_n_emojis(dplyr::group_by(df, g), text),
    warning = function(w) {
      warns <<- c(warns, list(w))
      rlang::cnd_muffle(w)
    }
  )
  lifecycle_warns <- Filter(
    function(w) inherits(w, "lifecycle_warning_deprecated"), warns
  )
  expect_length(lifecycle_warns, 1)
})


# ---------------------------------------------------------------------------
# 4.7: emoji_sentiment gains .emoji_n_scored
# ---------------------------------------------------------------------------

test_that("emoji_sentiment reports .emoji_n and .emoji_n_scored", {
  out <- emoji_sentiment(data.frame(text = c("\U0001f60d", "\U0001f621", "meh")), text)
  expect_true(".emoji_n_scored" %in% names(out))
  expect_equal(out$.emoji_n, c(1L, 1L, 0L))
  expect_true(all(out$.emoji_n_scored[1:2] >= 1L))
  expect_equal(out$.emoji_n_scored[3], NA_integer_)
})

# ---------------------------------------------------------------------------
# 4.10: .row_number naming (was row_number)
# ---------------------------------------------------------------------------

test_that("emoji_extract_unnest uses .row_number (dotted) to avoid collision", {
  out <- emoji_extract_unnest(data.frame(text = c("\U0001f600", "plain")), text)
  expect_true(".row_number" %in% names(out))
  expect_false("row_number" %in% names(out))
})
