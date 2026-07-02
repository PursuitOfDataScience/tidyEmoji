# Tests for the 0.3.0 affect / translation / search features.

# ---------------------------------------------------------------------------
# emoji_emotion() + emoji_emotion_label()
# ---------------------------------------------------------------------------

test_that("emoji_emotion adds 8 emotion columns + counts", {
  df <- data.frame(text = c("love \U0001f60d", "scary \U0001f628", "meh"))
  out <- emoji_emotion(df, text)
  expect_true(all(paste0(".emoji_", c("anger","anticipation","disgust","fear",
        "joy","sadness","surprise","trust")) %in% names(out)))
  expect_true(all(c(".emoji_n", ".emoji_n_scored") %in% names(out)))
  expect_equal(out$.emoji_n, c(1L, 1L, 0L))
  expect_equal(out$.emoji_n_scored[3], NA_integer_)
  expect_gt(out$.emoji_joy[1], 0.5)   # heart-eyes is joyful
  expect_gt(out$.emoji_fear[2], 0.5)  # fearful face is fearful
})

test_that("emoji_emotion resolves a qualified (U+FE0F) glyph via key", {
  out <- emoji_emotion(data.frame(text = "\u2764\ufe0f"), text)
  expect_false(is.na(out$.emoji_joy))
  expect_gt(out$.emoji_joy, 0.5)
})

test_that("emoji_emotion long form has one row per (row, emotion)", {
  df <- data.frame(text = c("a \U0001f600", "b \U0001f621"))
  out <- emoji_emotion(df, text, long = TRUE)
  expect_equal(nrow(out), 16L)   # 2 rows x 8 emotions
  expect_named(out, c("text", ".emoji_emotion", ".emoji_score"))
  expect_equal(sort(unique(out$.emoji_emotion)),
               c("anger","anticipation","disgust","fear",
                 "joy","sadness","surprise","trust"))
})

test_that("emoji_emotion_label returns the dominant emotion", {
  df <- data.frame(text = c("love \U0001f60d", "scary \U0001f628", "meh"))
  out <- emoji_emotion_label(df, text)
  expect_equal(out$.emoji_emotion[1], "joy")
  expect_equal(out$.emoji_emotion[2], "fear")
  expect_true(is.na(out$.emoji_emotion[3]))
})

# ---------------------------------------------------------------------------
# lexicon API: emoji_lexicons / register_emoji_lexicon / emoji_score
# ---------------------------------------------------------------------------

test_that("emoji_lexicons lists the two bundled lexicons", {
  lex <- emoji_lexicons()
  expect_true("novak2015" %in% lex$name)
  expect_true("emotag1200" %in% lex$name)
  expect_equal(lex$type[lex$name == "emotag1200"], "emotion")
})

test_that("register_emoji_lexicon + emoji_score with a custom lexicon", {
  own <- data.frame(emoji = c("\U0001f600", "\U0001f621"),
                    score = c(0.9, -0.8))
  register_emoji_lexicon("my_test_lex", own)
  lex <- emoji_lexicons()
  expect_true("my_test_lex" %in% lex$name)
  out <- emoji_score(data.frame(text = c("good \U0001f600", "bad \U0001f621")),
                     text, lexicon = "my_test_lex")
  expect_equal(out$.emoji_score, c(0.9, -0.8))
  expect_equal(out$.emoji_n_scored, c(1L, 1L))
})

test_that("emoji_score accepts a data frame lexicon directly", {
  out <- emoji_score(data.frame(text = "\U0001f600"), text,
                     lexicon = data.frame(emoji = "\U0001f600", score = 0.5))
  expect_equal(out$.emoji_score, 0.5)
})

test_that("emoji_emotion works with a registered custom emotion lexicon", {
  own <- data.frame(emoji = c("\U0001f600", "\U0001f62d"),
                    joy = c(1, 0), sadness = c(0, 1))
  register_emoji_lexicon("test_emotions", own)
  df <- data.frame(text = c("yay \U0001f600", "boo \U0001f62d", "meh"))
  out <- emoji_emotion(df, text, lexicon = "test_emotions")
  expect_equal(out$.emoji_joy, c(1, 0, NA))
  expect_equal(out$.emoji_sadness, c(0, 1, NA))
  lab <- emoji_emotion_label(df, text, lexicon = "test_emotions")
  expect_equal(lab$.emoji_emotion, c("joy", "sadness", NA))
})

test_that("emoji_emotion handles a single-emotion custom lexicon", {
  register_emoji_lexicon("test_joy_only",
                         data.frame(emoji = "\U0001f600", joy = 1))
  out <- emoji_emotion(data.frame(text = c("yay \U0001f600", "meh")), text,
                       lexicon = "test_joy_only")
  expect_equal(out$.emoji_joy, c(1, NA))
})

test_that("emoji_emotion rejects a lexicon without emotion columns", {
  expect_error(
    emoji_emotion(data.frame(text = "\U0001f600"), text,
                  lexicon = data.frame(emoji = "\U0001f600", score = 1)),
    "emotion column"
  )
})

test_that("emoji_score with a bundled named lexicon works", {
  out <- emoji_score(data.frame(text = "love \U0001f60d"), text,
                     lexicon = "novak2015")
  expect_gt(out$.emoji_score, 0)
})

test_that("emoji_sentiment still works with default lexicon (back-compat)", {
  out <- emoji_sentiment(data.frame(text = "love \U0001f60d"), text)
  expect_gt(out$.emoji_sentiment, 0)
  expect_true(".emoji_n_scored" %in% names(out))
})

# ---------------------------------------------------------------------------
# translation: emoji_to_text / text_to_emoji / as_emoji*
# ---------------------------------------------------------------------------

test_that("emoji_to_text replaces emoji with Unicode names", {
  df <- data.frame(text = "great \U0001f600 love \u2764\ufe0f")
  out <- emoji_to_text(df, text, format = "name")
  expect_match(out$text, "grinning face")
  expect_match(out$text, "red heart")
  expect_false(grepl("\U0001f600", out$text, fixed = TRUE))
})

test_that("emoji_to_text replaces emoji with shortcodes", {
  out <- emoji_to_text(data.frame(text = "hi \U0001f600"), text,
                       format = "shortcode")
  # emoji::emoji_replace_name wraps a known shortcode in colons
  expect_match(out$text, "^hi :[a-z_]+:$")
  expect_false(grepl("\U0001f600", out$text, fixed = TRUE))
})

test_that("emoji_to_text resolves qualified emoji (U+FE0F)", {
  out <- emoji_to_text(data.frame(text = "\u2764\ufe0f"), text, format = "name")
  expect_match(out$text, "red heart")
})

test_that("emoji_to_text honours a custom wrap template", {
  out <- emoji_to_text(data.frame(text = "hi \U0001f600"), text,
                       format = "shortcode", wrap = "<<{x}>>")
  expect_equal(out$text, "hi <<grinning>>")
})

test_that("emoji_to_text and text_to_emoji keep NA entries as NA", {
  out <- emoji_to_text(data.frame(text = c(NA, "hi \U0001f600")), text)
  expect_true(is.na(out$text[1]))
  expect_match(out$text[2], "grinning face")
  back <- text_to_emoji(data.frame(text = c(NA, ":grinning:")), text)
  expect_true(is.na(back$text[1]))
  expect_equal(back$text[2], "\U0001f600")
})

test_that("text_to_emoji inverts emoji_to_text(shortcode)", {
  df <- data.frame(text = "hi \U0001f600 bye \U0001f44b")
  demo <- emoji_to_text(df, text, format = "shortcode")
  back <- text_to_emoji(demo, text)
  expect_equal(back$text, df$text)
})

test_that("text_to_emoji leaves unknown shortcodes unchanged", {
  out <- text_to_emoji(data.frame(text = ":not_a_real_emoji:"), text)
  expect_equal(out$text, ":not_a_real_emoji:")
})

test_that("as_emoji_name / as_emoji_shortcode resolve qualified emoji", {
  expect_equal(as_emoji_name("\u2764\ufe0f"), "red heart")
  expect_equal(as_emoji_shortcode("\u2764\ufe0f"), "heart")
  expect_true(is.na(as_emoji_name("not an emoji")))
})

test_that("as_emoji maps shortcodes to glyphs", {
  expect_equal(as_emoji("grinning"), "\U0001f600")
  expect_true(is.na(as_emoji("not_a_real_shortcode")))
})

# ---------------------------------------------------------------------------
# emoji_search
# ---------------------------------------------------------------------------

test_that("emoji_search finds emoji by keyword", {
  out <- emoji_search("happy")
  expect_gt(nrow(out), 0)
  expect_true(all(c("emoji","name","shortcode","group","keyword") %in% names(out)))
  expect_true(all(grepl("happy", out$keyword, ignore.case = TRUE)))
})

test_that("emoji_search finds emoji by name", {
  out <- emoji_search("heart")
  expect_gt(nrow(out), 0)
  expect_true(any(grepl("heart", out$name, ignore.case = TRUE)))
})

test_that("emoji_search returns an empty typed tibble on no match", {
  out <- emoji_search("zzzznotarealquery")
  expect_equal(nrow(out), 0)
  expect_named(out, c("emoji","name","shortcode","group","keyword"))
})

test_that("emoji_search is safe for regex metacharacters", {
  # "+1" is a real GitHub-style alias (thumbs up); "(" appears in some
  # keywords. Neither may error, and matching must be literal.
  plus1 <- emoji_search("+1")
  expect_gt(nrow(plus1), 0)
  expect_true("\U0001f44d" %in% plus1$emoji)
  expect_no_error(emoji_search("("))
  expect_equal(nrow(emoji_search("a[b")), 0)
})
