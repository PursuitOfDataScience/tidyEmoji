library(dplyr)

df <- data.frame(tweets = c("I love tidyverse \U0001f600\U0001f603\U0001f603",
                            "R is my language! \U0001f601\U0001f606\U0001f605",
                            "This Tweet does not have Emoji!",
                            "Wearing a mask\U0001f637\U0001f637\U0001f637.",
                            "Emoji does not appear in all Tweets"))

test_that("emoji_summary counts emoji and total entries", {
  s <- emoji_summary(df, tweets)
  expect_s3_class(s, "tbl_df")
  expect_equal(pull(s, emoji_tweets), 3)
  expect_equal(pull(s, total_tweets), 5)
})

test_that("emoji_filter / emoji_tweets keep only emoji rows and return a tibble", {
  expect_equal(nrow(emoji_filter(df, tweets)), 3)
  expect_s3_class(emoji_filter(df, tweets), "tbl_df")
  expect_identical(emoji_tweets(df, tweets), emoji_filter(df, tweets))
})

test_that("top_n_emojis returns the most frequent emoji by canonical shortcode", {
  expect_identical(
    df %>% top_n_emojis(tweets, n = 1) %>% pull(emoji_name),
    "mask"
  )
  expect_equal(df %>% top_n_emojis(tweets, n = 1) %>% pull(n), 3L)
  expect_no_warning(top_n_emojis(df, tweets, n = 1))
})
