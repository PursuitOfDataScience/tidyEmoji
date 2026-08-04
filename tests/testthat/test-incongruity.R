# Tests for emoji_incongruity() / emoji_congruence() /
# emoji_incongruity_profile().

heart_eyes <- "\U0001f60d"   # positive in the Novak lexicon
rage       <- "\U0001f621"   # negative

df <- data.frame(
  text = c(paste0("this is wonderful ", rage),
           paste0("awful ", rage),
           paste0("great ", heart_eyes),
           "no emoji here"),
  score = c(0.9, -0.8, 0.7, 0.5)
)

test_that("emoji_incongruity requires an explicit scale", {
  expect_error(emoji_incongruity(df, text, score), "scale")
  expect_error(emoji_congruence(df, text, score), "scale")
  expect_error(emoji_incongruity_profile(df, text, score), "scale")
})

test_that("emoji_incongruity adds the documented columns", {
  out <- emoji_incongruity(df, text, score, scale = "none")
  expect_true(all(c(".emoji_n", ".emoji_n_scored", ".emoji_sentiment",
                    ".emoji_incongruity", ".emoji_polarity_flip",
                    ".emoji_incongruent") %in% names(out)))
  expect_equal(out$.emoji_n, c(1L, 1L, 1L, 0L))
  # emoji minus text: a negative emoji on positive text is a negative gap
  expect_lt(out$.emoji_incongruity[1], 0)
  expect_true(out$.emoji_polarity_flip[1])
  expect_false(out$.emoji_polarity_flip[2])
  expect_false(out$.emoji_polarity_flip[3])
})

test_that("a row with no scorable emoji is NA, never 0", {
  out <- emoji_incongruity(df, text, score, scale = "none")
  expect_true(is.na(out$.emoji_sentiment[4]))
  expect_true(is.na(out$.emoji_incongruity[4]))
  expect_true(is.na(out$.emoji_polarity_flip[4]))
  expect_true(is.na(out$.emoji_incongruent[4]))
  expect_equal(out$.emoji_n_scored[4], NA_integer_)
  # a missing text score propagates the same way
  na_score <- df
  na_score$score[1] <- NA_real_
  out2 <- emoji_incongruity(na_score, text, score, scale = "none")
  expect_true(is.na(out2$.emoji_incongruity[1]))
  expect_false(is.na(out2$.emoji_sentiment[1]))
})

test_that("method = sign_flip flags exactly the polarity flips", {
  out <- emoji_incongruity(df, text, score, scale = "none",
                           method = "sign_flip")
  expect_equal(out$.emoji_incongruent, out$.emoji_polarity_flip)
  expect_equal(out$.emoji_incongruent[1:3], c(TRUE, FALSE, FALSE))
})

test_that("method = difference uses the threshold", {
  loose <- emoji_incongruity(df, text, score, scale = "none", threshold = 0.1)
  tight <- emoji_incongruity(df, text, score, scale = "none", threshold = 99)
  expect_true(loose$.emoji_incongruent[1])
  expect_false(tight$.emoji_incongruent[1])
  expect_error(emoji_incongruity(df, text, score, scale = "none",
                                 threshold = "big"), "single number")
})

test_that("scale = rank puts both sides on [-1, 1]", {
  out <- emoji_incongruity(df, text, score, scale = "rank")
  gaps <- out$.emoji_incongruity[!is.na(out$.emoji_incongruity)]
  expect_true(all(abs(gaps) <= 2 + 1e-8))
  # the sign of the flip is judged on the raw scores, so it is scale-free
  none <- emoji_incongruity(df, text, score, scale = "none")
  expect_equal(out$.emoji_polarity_flip, none$.emoji_polarity_flip)
})

test_that("scale = zscore is finite and NA in the same places", {
  z <- emoji_incongruity(df, text, score, scale = "zscore")
  n <- emoji_incongruity(df, text, score, scale = "none")
  expect_equal(is.na(z$.emoji_incongruity), is.na(n$.emoji_incongruity))
  gaps <- z$.emoji_incongruity[!is.na(z$.emoji_incongruity)]
  expect_true(all(is.finite(gaps)))
  expect_equal(z$.emoji_polarity_flip, n$.emoji_polarity_flip)
})

test_that("where = final only scores emoji that end the text", {
  fin <- data.frame(
    text = c(paste0("great ", heart_eyes),          # ends with an emoji
             paste0("great ", heart_eyes, " ok"),   # does not
             paste0("hmm ", rage, "  ", heart_eyes)),
    score = c(0.5, 0.5, 0.5)
  )
  out <- emoji_incongruity(fin, text, score, scale = "none", where = "final")
  expect_false(is.na(out$.emoji_sentiment[1]))
  expect_true(is.na(out$.emoji_sentiment[2]))
  # a trailing run of two emoji is averaged
  both <- emoji_sentiment(data.frame(text = paste0(rage, heart_eyes)),
                          text)$.emoji_sentiment
  expect_equal(out$.emoji_sentiment[3], both)
})

test_that("emoji_incongruity rejects a non-numeric text score", {
  bad <- data.frame(text = paste0("hi ", heart_eyes), score = "positive")
  expect_error(emoji_incongruity(bad, text, score, scale = "none"),
               "numeric column")
})

test_that("emoji_congruence mirrors emoji_incongruity", {
  inc <- emoji_incongruity(df, text, score, scale = "none")
  con <- emoji_congruence(df, text, score, scale = "none")
  expect_equal(con$.emoji_congruent, !inc$.emoji_incongruent)
  expect_equal(con$.emoji_incongruity, inc$.emoji_incongruity)
})

test_that("emoji_incongruity_profile aggregates by glyph", {
  prof <- emoji_incongruity_profile(df, text, score, scale = "none",
                                    min_n = 1)
  expect_named(prof, c("emoji", "name", "n", "mean_incongruity",
                       "sd_incongruity", "n_flips", "flip_rate"))
  expect_setequal(prof$emoji, c(heart_eyes, rage))
  expect_equal(prof$n[prof$emoji == rage], 2L)
  expect_equal(prof$n_flips[prof$emoji == rage], 1L)
  expect_equal(prof$flip_rate[prof$emoji == rage], 0.5)
  expect_true(is.na(prof$sd_incongruity[prof$emoji == heart_eyes]))
  expect_false(is.unsorted(rev(prof$flip_rate)))
})

test_that("emoji_incongruity_profile filters by min_n", {
  prof <- emoji_incongruity_profile(df, text, score, scale = "none",
                                    min_n = 2)
  expect_equal(prof$emoji, rage)
  empty <- emoji_incongruity_profile(df, text, score, scale = "none",
                                     min_n = 99)
  expect_equal(nrow(empty), 0L)
  expect_error(emoji_incongruity_profile(df, text, score, scale = "none",
                                         min_n = -1), "non-negative")
})
