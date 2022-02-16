library(dplyr)

df <- data.frame(tweets = c("I love tidyverse \U0001f600\U0001f603\U0001f603",
                            "R is my language! \U0001f601\U0001f606\U0001f605",
                            "This Tweet does not have Emoji!",
                            "Wearing a mask\U0001f637\U0001f637\U0001f637.",
                            "Emoji does not appear in all Tweets"))


test_that("emoji_summary dimension", {

  expect_equal(
    df %>%
      emoji_summary(tweets) %>%
      pull(emoji_tweets),
    3
  )

  expect_equal(
    df %>%
      emoji_summary(tweets) %>%
      pull(total_tweets),
    5
  )
})


test_that("emoji_tweets dimension", {
  expect_equal(
    df %>%
    emoji_tweets(tweets) %>%
    dim() %>%
    .[1],
    3
  )
})



test_that("top_n_emojis emoji names", {
  expect_identical(
    df %>%
      top_n_emojis(tweets, n = 1) %>%
      pull(emoji_name),
    "face_with_medical_mask"
  )
})


