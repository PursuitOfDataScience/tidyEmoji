# Robustness on awkward but legal inputs: NA, empty frames, tibble input.

test_that("NA text is handled without error and counts as no emoji", {
  df <- data.frame(text = c(NA_character_, "hi \U0001f600", NA))
  expect_equal(emoji_summary(df, text)$n_with_emoji, 1)
  expect_equal(nrow(emoji_filter(df, text)), 1)
  expect_true(is.na(emoji_sentiment(df, text)$.emoji_sentiment[1]))
  expect_equal(emoji_sentiment(df, text)$.emoji_n[1], 0L)
})

test_that("empty data frames return empty, well-typed output", {
  df <- data.frame(text = character(0))
  expect_equal(emoji_summary(df, text)$n_total, 0)
  expect_equal(nrow(emoji_frequency(df, text)), 0)
  expect_equal(nrow(emoji_extract_unnest(df, text)), 0)
  expect_equal(nrow(emoji_tokens(df, text)), 0)
})

test_that("tibble input is accepted and column selection is tidy-eval", {
  tb <- tibble::tibble(body = c("yo \U0001f44b", "plain"))
  expect_equal(emoji_summary(tb, body)$n_with_emoji, 1)
  expect_equal(emoji_frequency(tb, body)$emoji, "\U0001f44b")
})


# A base data.frame may carry duplicate column names; a tibble may not. The
# conversion is unavoidable, but the message the user saw came from tibble's
# internals and advised `.name_repair`, an argument no verb here has.
test_that("duplicate column names get an authored error naming the fix", {
  smile <- intToUtf8(0x1F600)
  d <- data.frame(a = 1, a = 2, text = paste("hi", smile), check.names = FALSE)
  expect_error(emoji_sentiment(d, text), "more than once", fixed = TRUE)
  # it is no longer tibble's wording, which named an argument no verb has
  msg <- tryCatch(emoji_sentiment(d, text), error = conditionMessage)
  expect_false(grepl("name_repair", msg, fixed = TRUE))
  expect_false(grepl("repaired_names", msg, fixed = TRUE))
  # and it reads like its sibling, the guard on a duplicated *text* column
  expect_match(msg, "Give the columns distinct names", fixed = TRUE)
  expect_error(emoji_sentiment(data.frame(text = 1, text = 2,
                                          check.names = FALSE), text),
               "Give the columns distinct names", fixed = TRUE)
  # the remedy it names works
  d1 <- d
  names(d1) <- make.unique(names(d1))
  expect_true(".emoji_sentiment" %in% names(emoji_sentiment(d1, text)))
})

test_that("verbs that build their own output still accept duplicate names", {
  smile <- intToUtf8(0x1F600)
  d <- data.frame(a = 1, a = 2, text = paste("hi", smile), check.names = FALSE)
  expect_equal(emoji_summary(d, text)$n_with_emoji, 1L)
  expect_equal(nrow(emoji_frequency(d, text)), 1L)
})
