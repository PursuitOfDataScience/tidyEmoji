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

test_that("emoji_sanitize strip leaves no emoji, even a recombined one", {
  # Removing a span makes its neighbours adjacent, and on malformed input the
  # two can spell an emoji the text never held. One pass used to return it.
  snow <- "\u2603"                                  # bare, so undetected
  cases <- c(
    paste0(snow, grin, "\uFE0F"),                   # -> U+2603 U+FE0F
    paste0("#", grin, "\uFE0F\u20E3"),              # -> keycap #
    paste0("\U0001F1FA", grin, "\U0001F1F8"),       # -> flag: US
    paste0("a ", grin, " b")                        # the ordinary case
  )
  out <- emoji_sanitize(data.frame(text = cases), text, policy = "strip")$text
  expect_false(any(tidyEmoji:::emoji_has(out)))
  expect_identical(out[4L], "a b")
  # and it is a fixed point: stripping the result changes nothing
  expect_identical(
    emoji_sanitize(data.frame(text = out), text, policy = "strip")$text, out
  )
  # the other emoji-removing policy never had the problem, because what it
  # substitutes keeps the neighbours apart
  ph <- emoji_sanitize(data.frame(text = cases), text,
                       policy = "placeholder")$text
  expect_false(any(tidyEmoji:::emoji_has(ph)))
  # unless the token is empty, which is a deletion wearing a substitution's
  # name -- so it takes the same repeat pass, and none of the tidying
  empty <- emoji_sanitize(data.frame(text = cases), text,
                          policy = "placeholder", placeholder = "")$text
  expect_false(any(tidyEmoji:::emoji_has(empty)))
  expect_identical(empty[4L], "a  b")

  # ?emoji_sanitize qualifies the placeholder guarantee, so pin both ways it
  # fails: a token that is itself an emoji, and a lone combining character
  # that binds to whatever the removed glyph stood next to. Neither is the
  # package substituting something it chose.
  self <- emoji_sanitize(data.frame(text = paste0("a", grin, "b"),
                                    stringsAsFactors = FALSE),
                         text, policy = "placeholder", placeholder = grin)$text
  expect_identical(self, paste0("a", grin, "b"))
  binds <- emoji_sanitize(data.frame(text = paste0(snow, grin, "x"),
                                     stringsAsFactors = FALSE),
                          text, policy = "placeholder",
                          placeholder = "\uFE0F")$text
  expect_identical(binds, paste0(snow, "\uFE0F", "x"))
  expect_true(tidyEmoji:::emoji_has(binds))
  # strip clears both, which is the asymmetry the page now states
  for (bad in c(paste0("a", grin, "b"), paste0(snow, grin, "x"))) {
    out <- emoji_sanitize(data.frame(text = bad, stringsAsFactors = FALSE),
                          text, policy = "strip")$text
    expect_false(tidyEmoji:::emoji_has(out))
  }
  expect_match(rd_flat("emoji_sanitize"),
               "the one policy whose result is emoji-free whatever you hand it",
               fixed = TRUE)
})

test_that("emoji_sanitize name/shortcode leave an unnameable glyph in place", {
  # ?emoji_sanitize says so, and ?emoji_to_text is where the rule comes from:
  # a ZWJ sequence the catalogue does not know is detected but cannot be
  # named, so these two policies can return a column that still holds emoji.
  zwj <- paste0(grin, "\u200d\U0001F525")       # detected, not catalogued
  expect_true(tidyEmoji:::emoji_has(zwj))
  expect_true(is.na(as_emoji_name(zwj)))
  df <- data.frame(text = zwj)
  expect_identical(emoji_sanitize(df, text, policy = "name")$text, zwj)
  expect_identical(emoji_sanitize(df, text, policy = "shortcode")$text, zwj)
  # while the two that do not need a name still clear it
  expect_identical(emoji_sanitize(df, text, policy = "strip")$text, "")
  expect_identical(emoji_sanitize(df, text, policy = "placeholder")$text,
                   "[emoji]")
})

test_that("emoji_sanitize keeps the column name and validates its arguments", {
  df <- data.frame(id = 1:2, body = c(paste0("hi ", grin), "plain"))
  out <- emoji_sanitize(df, body, policy = "strip")
  expect_named(out, c("id", "body"))
  expect_equal(out$body, c("hi", "plain"))
  expect_error(emoji_sanitize(df, body, policy = "delete"),
               '`policy` has no option "delete"')
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

test_that("emoji_token_cost checks what the tokenizer hands back", {
  # A user's function is the widest surface this verb has, and a wrong
  # answer from it was silent: a negative count went straight into the
  # column, and an infinite or out-of-range one became NA through R's own
  # "NAs introduced by coercion to integer range", which names neither the
  # argument nor the verb.
  df <- data.frame(text = c(paste("a", grin), paste("b", grin, grin), "none"),
                   stringsAsFactors = FALSE)
  for (bad in list(c(-5, 2, 0), c(Inf, 2, 0), c(-Inf, 2, 0), c(1e12, 2, 0))) {
    expect_error(
      emoji_token_cost(df, text, tokenizer = function(x) bad),
      "cannot be a token count", fixed = TRUE)
  }
  # the message names the offending value, not just the shape
  expect_error(emoji_token_cost(df, text, tokenizer = function(x) c(-5, 2, 0)),
               "-5", fixed = TRUE)
  # a data frame is refused rather than read as its column count
  expect_error(
    emoji_token_cost(df, text,
                     tokenizer = function(x) data.frame(a = 1:3, b = 1:3,
                                                        c = 1:3)),
    "counts its columns", fixed = TRUE)
  # NA is a legitimate answer and survives, and 0 is not negative
  na_ok <- emoji_token_cost(df, text,
                            tokenizer = function(x) c(NA_real_, 2, 0))
  expect_identical(na_ok$.emoji_token_estimate, c(NA_integer_, 2L, 0L))
  zero <- emoji_token_cost(df, text, tokenizer = function(x) c(0, 0, 0))
  expect_identical(zero$.emoji_token_estimate, c(0L, 0L, 0L))
  # and a fractional count still rounds up rather than truncating
  frac <- emoji_token_cost(df, text, tokenizer = function(x) c(2.6, 3.2, 0))
  expect_identical(frac$.emoji_token_estimate, c(3L, 4L, 0L))
  # the documented contract says all of this
  rd <- rd_flat("emoji_token_cost")
  expect_match(rd, "finite, not negative", fixed = TRUE)
  expect_match(rd, "counts its columns", fixed = TRUE)
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

test_that("a companion argument belonging to another branch is inert, quietly", {
  # ?emoji_sanitize says placeholder and wrap are ignored by the policies they
  # do not belong to, silently and unvalidated, because `policy` is meant to
  # be a variable. Pin both halves: nothing is said, and nothing changes.
  d <- data.frame(text = c(paste("great", grin), "plain"),
                  stringsAsFactors = FALSE)
  for (p in c("keep", "strip", "name")) {
    expect_silent(
      loud <- emoji_sanitize(d, text, policy = p, wrap = "<{x}>",
                             placeholder = "ZZZ"))
    expect_identical(loud, emoji_sanitize(d, text, policy = p), info = p)
  }
  expect_silent(sc <- emoji_sanitize(d, text, policy = "shortcode",
                                     placeholder = "ZZZ"))
  expect_identical(sc, emoji_sanitize(d, text, policy = "shortcode"))
  expect_silent(ph <- emoji_sanitize(d, text, policy = "placeholder",
                                     wrap = "<{x}>"))
  expect_identical(ph, emoji_sanitize(d, text, policy = "placeholder"))
  # an ignored `wrap` is not even validated, matching emoji_to_text()
  expect_silent(emoji_sanitize(d, text, policy = "name", wrap = "no braces"))
  expect_silent(emoji_to_text(d, text, format = "name", wrap = "no braces"))
  # but it is validated by the policy that uses it
  expect_error(emoji_sanitize(d, text, policy = "shortcode",
                              wrap = "no braces"), "{x}", fixed = TRUE)

  # emoji_score's `by` and `score` are inert for a lexicon named rather than
  # supplied, and say so
  for (nm in c("novak2015", "emotag1200")) {
    expect_silent(o <- emoji_score(d, text, lexicon = nm, by = "nonsense",
                                   score = "nonsense"))
    expect_identical(o, emoji_score(d, text, lexicon = nm), info = nm)
  }

  # the one companion that cannot be ignored is refused instead
  lex <- data.frame(emoji = grin, score = 0.5, stringsAsFactors = FALSE)
  expect_error(emoji_sentiment(d, text, lexicon = lex, se = TRUE),
               "annotation counts", fixed = TRUE)

  expect_match(rd_flat("emoji_sanitize"), "Ignored under the other four",
               fixed = TRUE)
  expect_match(rd_flat("emoji_score"), "Ignored when", fixed = TRUE)
})
