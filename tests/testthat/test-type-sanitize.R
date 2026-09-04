# Tests for the functional-type verbs (emoji_type / emoji_faceness /
# as_emoji_type), the LLM-plumbing verbs (emoji_sanitize / emoji_token_cost)
# and emoji_provenance().

grin  <- "\U0001f600"    # Smileys & Emotion / face-smiling
pizza <- "\U0001f355"    # Food & Drink
thumb <- "\U0001f44d"    # People & Body / hand-fingers-closed
flag  <- "\U0001f3c1"    # Flags

test_that("as_emoji_type recodes the Unicode groups", {
  expect_equal(as_emoji_type(grin), "face")
  expect_equal(as_emoji_type(pizza), "food")
  expect_equal(as_emoji_type(thumb), "gesture")
  expect_equal(as_emoji_type(flag), "flag")
  expect_equal(as_emoji_type("\u2764\uFE0F"), "symbol")   # heart, not a face
  expect_true(is.na(as_emoji_type("not an emoji")))
  expect_length(as_emoji_type(character(0)), 0L)
})

test_that("emoji_type lists the distinct types in each row", {
  df <- data.frame(text = c(paste0("yum ", pizza, " ", grin), thumb, "none"))
  out <- emoji_type(df, text)
  expect_equal(nrow(out), 3L)                    # no rows dropped
  expect_equal(out$.emoji_type, c("face|food", "gesture", NA))
  # the order of the levels is fixed, not the order of appearance
  rev_df <- data.frame(text = paste0(grin, pizza))
  expect_equal(emoji_type(rev_df, text)$.emoji_type, "face|food")
})

test_that("emoji_faceness reports the share of faces", {
  df <- data.frame(text = c(paste0(grin, pizza), grin, "none"))
  out <- emoji_faceness(df, text)
  expect_equal(out$.emoji_n, c(2L, 1L, 0L))
  expect_equal(out$.emoji_n_typed, c(2L, 1L, NA_integer_))
  expect_equal(out$.emoji_n_face, c(1L, 1L, NA_integer_))
  expect_equal(out$.emoji_faceness, c(0.5, 1, NA_real_))
})

test_that("emoji_sanitize applies each policy", {
  df <- data.frame(text = c(paste0("ship it ", grin), "no emoji", NA))
  expect_equal(emoji_sanitize(df, text, policy = "keep")$text, df$text)
  expect_equal(emoji_sanitize(df, text, policy = "strip")$text,
               c("ship it", "no emoji", NA))
  expect_equal(emoji_sanitize(df, text, policy = "name")$text,
               c("ship it grinning face", "no emoji", NA))
  expect_equal(emoji_sanitize(df, text, policy = "shortcode")$text,
               c("ship it :grinning:", "no emoji", NA))
  expect_equal(emoji_sanitize(df, text, policy = "placeholder")$text,
               c("ship it [emoji]", "no emoji", NA))
  expect_equal(
    emoji_sanitize(df, text, policy = "placeholder", placeholder = "<E>")$text,
    c("ship it <E>", "no emoji", NA)
  )
})

test_that("emoji_sanitize strip collapses the gap it leaves behind", {
  df <- data.frame(text = paste0("a ", grin, " b"))
  expect_equal(emoji_sanitize(df, text, policy = "strip")$text, "a b")
  expect_equal(emoji_sanitize(data.frame(text = grin), text,
                              policy = "strip")$text, "")
})

test_that("emoji_sanitize keeps the column name and validates its arguments", {
  df <- data.frame(id = 1:2, body = c(paste0("hi ", grin), "plain"))
  out <- emoji_sanitize(df, body, policy = "strip")
  expect_named(out, c("id", "body"))
  expect_equal(out$body, c("hi", "plain"))
  expect_error(emoji_sanitize(df, body, policy = "delete"), "should be one of")
  expect_error(emoji_sanitize(df, body, policy = "placeholder",
                              placeholder = c("a", "b")), "single string")
  expect_error(emoji_sanitize(df, nope, policy = "keep"), "nope")
})

test_that("emoji_sanitize honours the shortcode wrap template", {
  df <- data.frame(text = paste0("hi ", grin))
  expect_equal(emoji_sanitize(df, text, policy = "shortcode",
                              wrap = "<{x}>")$text, "hi <grinning>")
})

test_that("emoji_token_cost measures bytes, code points and graphemes", {
  family <- paste0("\U0001F468\u200d\U0001F469\u200d",
                   "\U0001F467\u200d\U0001F466")
  df <- data.frame(text = c(paste0("hi ", grin), family, "plain", NA))
  out <- emoji_token_cost(df, text)
  expect_named(out, c("text", ".emoji_n", ".emoji_bytes", ".emoji_codepoints",
                      ".emoji_graphemes", ".emoji_token_estimate"))
  expect_equal(out$.emoji_n, c(1L, 1L, 0L, 0L))
  expect_equal(out$.emoji_bytes, c(4L, 25L, 0L, 0L))
  expect_equal(out$.emoji_codepoints, c(1L, 7L, 0L, 0L))
  expect_equal(out$.emoji_graphemes, c(1L, 1L, 0L, 0L))
  expect_equal(out$.emoji_token_estimate, c(2L, 13L, 0L, 0L))
})

test_that("emoji_token_cost accepts a real tokenizer", {
  df <- data.frame(text = c(paste0("hi ", grin), "plain"))
  by_char <- function(x) nchar(x, type = "chars")
  out <- emoji_token_cost(df, text, tokenizer = by_char)
  expect_equal(out$.emoji_token_estimate, c(1L, 0L))
  as_list <- function(x) strsplit(x, "")
  expect_equal(emoji_token_cost(df, text, tokenizer = as_list
                                )$.emoji_token_estimate, c(1L, 0L))
  expect_error(emoji_token_cost(df, text, tokenizer = "gpt"), "function")
  expect_error(emoji_token_cost(df, text, tokenizer = function(x) 1L),
               "one token count")
})

test_that("emoji_provenance reports one row of versions", {
  out <- emoji_provenance()
  expect_equal(nrow(out), 1L)
  expect_named(out, c("tidyEmoji", "emoji_pkg", "unicode_emoji", "n_emoji",
                      "sentiment_lexicon", "emotion_lexicon", "R"))
  expect_gt(out$n_emoji, 1000)
  expect_true(grepl("novak2015", out$sentiment_lexicon))
  expect_true(grepl("emotag1200", out$emotion_lexicon))
})
