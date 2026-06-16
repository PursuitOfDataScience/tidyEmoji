# Robustness on awkward but legal inputs: NA, empty frames, tibble input.

test_that("NA text is handled without error and counts as no emoji", {
  df <- data.frame(text = c(NA_character_, "hi \U0001f600", NA))
  expect_equal(emoji_summary(df, text)$emoji_tweets, 1)
  expect_equal(nrow(emoji_filter(df, text)), 1)
  expect_true(is.na(emoji_sentiment(df, text)$.emoji_sentiment[1]))
  expect_equal(emoji_sentiment(df, text)$.emoji_n[1], 0L)
})

test_that("empty data frames return empty, well-typed output", {
  df <- data.frame(text = character(0))
  expect_equal(emoji_summary(df, text)$total_tweets, 0)
  expect_equal(nrow(emoji_frequency(df, text)), 0)
  expect_equal(nrow(emoji_extract_unnest(df, text)), 0)
  expect_equal(nrow(emoji_tokens(df, text)), 0)
})

test_that("tibble input is accepted and column selection is tidy-eval", {
  tb <- tibble::tibble(body = c("yo \U0001f44b", "plain"))
  expect_equal(emoji_summary(tb, body)$emoji_tweets, 1)
  expect_equal(emoji_frequency(tb, body)$emoji, "\U0001f44b")
})
