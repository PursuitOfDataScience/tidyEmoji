# Tests for the interpretation-risk verbs: emoji_ambiguity / emoji_risk /
# emoji_flag_ambiguous, and emoji_sentiment(se = TRUE).

heart_eyes <- "\U0001f60d"   # in the Novak lexicon (see test-sentiment.R)
rage       <- "\U0001f621"   # likewise

test_that("emoji_ambiguity returns the documented shape", {
  out <- emoji_ambiguity()
  expect_named(out, c("emoji", "key", "n_annotations", "p_neg", "p_neu",
                      "p_pos", "ambiguity", "rank"))
  expect_gt(nrow(out), 100)
  expect_equal(nrow(out), length(unique(out$key)))
})

test_that("annotation shares sum to one and entropy is bounded by log(3)", {
  out <- emoji_ambiguity()
  p <- out$p_neg + out$p_neu + out$p_pos
  p <- p[!is.na(p)]
  expect_true(all(abs(p - 1) < 1e-8))
  amb <- out$ambiguity[!is.na(out$ambiguity)]
  expect_true(all(amb >= 0))
  expect_true(all(amb <= log(3) + 1e-8))
})

test_that("rows come back most ambiguous first, with rank 1 at the top", {
  out <- emoji_ambiguity()
  expect_equal(out$rank[1], 1L)
  expect_equal(out$ambiguity[1], max(out$ambiguity, na.rm = TRUE))
  expect_false(is.unsorted(rev(out$ambiguity[!is.na(out$ambiguity)])))
})

test_that("each measure is a different, in-range statistic", {
  gini <- emoji_ambiguity(measure = "gini")
  expect_true(all(gini$ambiguity >= 0 & gini$ambiguity <= 2 / 3 + 1e-8,
                  na.rm = TRUE))
  neu <- emoji_ambiguity(measure = "neutral_share")
  expect_equal(neu$ambiguity, neu$p_neu)
  ci <- emoji_ambiguity(measure = "ci_width")
  expect_true(all(ci$ambiguity >= 0, na.rm = TRUE))
  expect_error(emoji_ambiguity(measure = "nonsense"))
})

test_that("emoji_ambiguity(x) keeps the caller's glyphs and order", {
  out <- emoji_ambiguity(c(rage, heart_eyes, "not an emoji"))
  expect_equal(nrow(out), 3L)
  expect_equal(out$emoji, c(rage, heart_eyes, "not an emoji"))
  expect_false(is.na(out$ambiguity[1]))
  expect_true(is.na(out$ambiguity[3]))
  # ranks stay comparable with the full lexicon
  full <- emoji_ambiguity()
  expect_equal(out$rank[2], full$rank[full$key == emoji_key(heart_eyes)])
})

test_that("a qualified glyph resolves to its unqualified lexicon entry", {
  # the lexicon stores the bare heart U+2764; text carries U+2764 U+FE0F
  out <- emoji_ambiguity("❤️")
  expect_false(is.na(out$ambiguity))
})

test_that("emoji_sentiment(se = TRUE) adds a non-negative standard error", {
  df <- data.frame(text = c(paste0("wow ", heart_eyes), "plain"))
  out <- emoji_sentiment(df, text, se = TRUE)
  expect_true(".emoji_sentiment_se" %in% names(out))
  expect_gt(out$.emoji_sentiment_se[1], 0)
  expect_true(is.na(out$.emoji_sentiment_se[2]))
  # averaging two glyphs shrinks the error below the worse of the two
  one <- emoji_sentiment(data.frame(text = heart_eyes), text, se = TRUE)
  two <- emoji_sentiment(data.frame(text = paste0(heart_eyes, heart_eyes)),
                         text, se = TRUE)
  expect_lt(two$.emoji_sentiment_se, one$.emoji_sentiment_se)
})

test_that("emoji_sentiment(se = TRUE) refuses a lexicon without counts", {
  own <- data.frame(emoji = heart_eyes, score = 0.5)
  expect_error(emoji_sentiment(data.frame(text = heart_eyes), text,
                               lexicon = own, se = TRUE),
               "annotation counts")
  expect_error(emoji_sentiment(data.frame(text = heart_eyes), text, se = "yes"),
               "TRUE or FALSE")
})

test_that("emoji_sentiment(se = FALSE) is unchanged", {
  df <- data.frame(text = c("love it \U0001f60d", "meh"))
  expect_named(emoji_sentiment(df, text),
               c("text", ".emoji_n", ".emoji_n_scored", ".emoji_sentiment"))
})

test_that("emoji_risk summarises a row's interpretation risk", {
  df <- data.frame(text = c(paste0("a ", heart_eyes, " b ", rage),
                            paste0("just ", heart_eyes),
                            "no emoji"))
  out <- emoji_risk(df, text)
  expect_true(all(c(".emoji_n", ".emoji_n_scored", ".emoji_ambiguity_mean",
                    ".emoji_ambiguity_max", ".emoji_n_ambiguous") %in%
                    names(out)))
  expect_equal(out$.emoji_n, c(2L, 1L, 0L))
  expect_equal(out$.emoji_n_scored, c(2L, 1L, NA_integer_))
  expect_true(all(is.na(out[3, c(".emoji_ambiguity_mean",
                                 ".emoji_ambiguity_max",
                                 ".emoji_n_ambiguous")])))
  expect_gte(out$.emoji_ambiguity_max[1], out$.emoji_ambiguity_mean[1])
})

test_that("emoji_risk honours an explicit threshold", {
  df <- data.frame(text = paste0(heart_eyes, rage))
  none <- emoji_risk(df, text, threshold = 99)
  all_of <- emoji_risk(df, text, threshold = -1)
  expect_equal(none$.emoji_n_ambiguous, 0L)
  expect_equal(all_of$.emoji_n_ambiguous, 2L)
  expect_error(emoji_risk(df, text, threshold = "high"), "single number")
})

test_that("emoji_flag_ambiguous ranks the corpus's own emoji", {
  df <- data.frame(text = c(paste0(heart_eyes, " ", rage), heart_eyes))
  out <- emoji_flag_ambiguous(df, text)
  expect_named(out, c("emoji", "name", "n", "n_annotations", "ambiguity",
                      "rank"))
  expect_lte(nrow(out), 2L)
  expect_false(is.unsorted(rev(out$ambiguity)))
  expect_equal(nrow(emoji_flag_ambiguous(df, text, top_n = 1)), 1L)
  expect_equal(nrow(emoji_flag_ambiguous(data.frame(text = "plain"), text)), 0L)
  expect_error(emoji_flag_ambiguous(df, text, top_n = -1), "non-negative")
})
