# No library(dplyr) here: attaching a package inside one test file leaks into
# every alphabetically-later file in the same testthat session, masking
# filter(), lag(), intersect(), setdiff(), setequal(), union() and testthat's
# matches() for all of them. That makes the suite's behaviour depend on file
# order. Qualify instead.

df <- data.frame(tweets = c("I love tidyverse \U0001f600\U0001f603\U0001f603",
                            "R is my language! \U0001f601\U0001f606\U0001f605",
                            "This Tweet does not have Emoji!",
                            "Wearing a mask\U0001f637\U0001f637\U0001f637.",
                            "Emoji does not appear in all Tweets"))

test_that("emoji_summary counts emoji and total entries", {
  s <- emoji_summary(df, tweets)
  expect_s3_class(s, "tbl_df")
  expect_equal(dplyr::pull(s, n_with_emoji), 3)
  expect_equal(dplyr::pull(s, n_total), 5)
})

test_that("emoji_filter keeps only emoji rows, and its old name is defunct", {
  expect_equal(nrow(emoji_filter(df, tweets)), 3)
  expect_s3_class(emoji_filter(df, tweets), "tbl_df")
  # 0.6.0: emoji_tweets() warned and returned emoji_filter()'s answer
  expect_error(emoji_tweets(df, tweets), class = "defunctError")
})

test_that("top_n_emojis returns the most frequent emoji by canonical shortcode", {
  expect_identical(
    dplyr::pull(top_n_emojis(df, tweets, n = 1), emoji_name),
    "mask"
  )
  expect_equal(dplyr::pull(top_n_emojis(df, tweets, n = 1), n), 3L)
  expect_no_warning(top_n_emojis(df, tweets, n = 1))
})
