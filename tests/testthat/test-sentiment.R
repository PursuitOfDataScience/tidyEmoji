test_that("emoji_sentiment scores rows from the lexicon", {
  df <- data.frame(text = c("love it \U0001f60d", "awful \U0001f621", "meh"))
  out <- emoji_sentiment(df, text)
  expect_named(out, c("text", ".emoji_n", ".emoji_sentiment"))
  expect_gt(out$.emoji_sentiment[1], 0)           # positive
  expect_lt(out$.emoji_sentiment[2], 0)           # negative
  expect_true(is.na(out$.emoji_sentiment[3]))     # no emoji -> NA
  expect_equal(out$.emoji_n, c(1L, 1L, 0L))
})

test_that("qualified emoji with U+FE0F resolve to the lexicon's unqualified entry", {
  # The lexicon stores the unqualified heart (U+2764); modern text carries the
  # emoji variation selector (U+2764 U+FE0F). The qualified glyph must still
  # resolve to the lexicon score via codepoint normalisation.
  qualified <- emoji_sentiment(data.frame(text = "❤️"), text)$.emoji_sentiment
  expect_false(is.na(qualified))
  expect_gt(qualified, 0)
})

test_that("emoji_sentiment averages multiple emoji in a row", {
  out <- emoji_sentiment(data.frame(text = "\U0001f60d\U0001f621"), text)
  expect_equal(out$.emoji_n, 2L)
  expect_false(is.na(out$.emoji_sentiment))
})
