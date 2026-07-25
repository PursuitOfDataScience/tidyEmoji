# Regression tests for the 0.3.0 correctness fixes.

# ---------------------------------------------------------------------------
# Grapheme clusters: ZWJ sequences the upstream regex does not know are
# re-joined, so they count as one emoji everywhere.
# ---------------------------------------------------------------------------

exhaling  <- "\U0001F62E‍\U0001F4A8"                    # face exhaling
spiral    <- "\U0001F635‍\U0001F4AB"                    # face with spiral eyes
heartfire <- "❤️‍\U0001F525"                  # heart on fire
holding   <- "\U0001F9D1‍\U0001F91D‍\U0001F9D1"    # people holding hands
family    <- "\U0001F468‍\U0001F469‍\U0001F467‍\U0001F466"
blondwoman <- "\U0001F471‍♀️"                 # woman: blond hair

test_that("ZWJ sequences count as a single emoji", {
  df <- data.frame(text = c(exhaling, spiral, heartfire, holding, family,
                            blondwoman))
  out <- emoji_extract_unnest(df, text)
  expect_equal(nrow(out), 6L)
  expect_equal(out$.emoji_count, rep(1L, 6))
  expect_identical(out$.emoji_unicode,
                   c(exhaling, spiral, heartfire, holding, family, blondwoman))
})

test_that("ZWJ sequences resolve to their own name, not a component's", {
  expect_equal(as_emoji_name(exhaling), "face exhaling")
  expect_equal(as_emoji_name(holding), "people holding hands")
  expect_equal(as_emoji_name(heartfire), "heart on fire")
  out <- emoji_to_text(data.frame(text = paste0("wow ", exhaling)), text)
  expect_equal(out$text, "wow face exhaling")
})

test_that("distinct adjacent emoji are still kept apart", {
  # no ZWJ between them: two emoji, not one
  df <- data.frame(text = "\U0001F600\U0001F601")
  expect_equal(nrow(emoji_extract_unnest(df, text)), 2L)
  expect_equal(lengths(emoji_extract_nest(df, text)$.emoji_unicode), 2L)
})

test_that("a text made only of a ZWJ emoji is flagged emoji-only", {
  out <- emoji_ratio(data.frame(text = c(exhaling, holding)), text)
  expect_equal(out$.emoji_ratio, c(1, 1))
  expect_equal(out$.emoji_only, c(TRUE, TRUE))
})

test_that("location and extraction never disagree", {
  # every verb slices the same spans, so counts from emoji_position() and
  # emoji_extract_nest() must match, ZWJ sequences included
  df <- data.frame(text = c(exhaling, paste("a", holding, "b", family),
                            "plain", "", NA))
  pos <- emoji_position(df, text)
  nest <- emoji_extract_nest(df, text)
  expect_equal(pos$.emoji_n, as.integer(lengths(nest$.emoji_unicode)))
})

# ---------------------------------------------------------------------------
# text_to_emoji(): an unrelated colon pair must not swallow a real shortcode
# ---------------------------------------------------------------------------

test_that("text_to_emoji finds shortcodes after other colons", {
  out <- text_to_emoji(
    data.frame(text = c("10:30 and :grinning:",
                        "https://example.org :grinning:",
                        "note: this is :grinning:",
                        "ratio 1:2 :+1:")),
    text
  )
  expect_equal(out$text[1], "10:30 and \U0001F600")
  expect_equal(out$text[2], "https://example.org \U0001F600")
  expect_equal(out$text[3], "note: this is \U0001F600")
  expect_equal(out$text[4], "ratio 1:2 \U0001F44D")
})

test_that("text_to_emoji leaves non-shortcode colon text alone", {
  out <- text_to_emoji(data.frame(text = c("time 10:30:45 here",
                                           "a: b: c:",
                                           "::")), text)
  expect_equal(out$text, c("time 10:30:45 here", "a: b: c:", "::"))
})

# ---------------------------------------------------------------------------
# Deterministic, locale-independent ordering
# ---------------------------------------------------------------------------

test_that("emoji_pairs orients pairs by C-locale order, not the session's", {
  a <- "\U0001F602"
  b <- "\U0001F60D"
  out <- emoji_pairs(data.frame(text = paste0(b, a)), text)
  expected <- sort(c(a, b), method = "radix")
  expect_equal(out$item1, expected[1])
  expect_equal(out$item2, expected[2])
  # and the same whatever order they appear in the text
  rev_out <- emoji_pairs(data.frame(text = paste0(a, b)), text)
  expect_identical(out, rev_out)
})

test_that("emoji_dfm column order breaks count ties by C-locale glyph order", {
  a <- "\U0001F602"
  b <- "\U0001F60D"
  out <- emoji_dfm(data.frame(text = paste0(a, b)), text)
  expect_equal(names(out)[-1], sort(c(a, b), method = "radix"))
})

test_that("emoji_ngrams rejects a non-finite n cleanly", {
  df <- data.frame(text = "\U0001F600\U0001F600")
  expect_error(emoji_ngrams(df, text, n = Inf), ">= 1")
  expect_no_warning(try(emoji_ngrams(df, text, n = Inf), silent = TRUE))
})

# ---------------------------------------------------------------------------
# Lexicon registry
# ---------------------------------------------------------------------------

test_that("emoji_lexicons() omits the glyph column from `dimensions`", {
  register_emoji_lexicon("reg_by_glyph",
                         data.frame(glyph = "\U0001F600", score = 0.7),
                         by = "glyph")
  lex <- emoji_lexicons()
  dims <- lex$dimensions[[which(lex$name == "reg_by_glyph")]]
  expect_equal(dims, "score")
})

# ---------------------------------------------------------------------------
# emoji_emotion(long = TRUE) must not clobber user columns
# ---------------------------------------------------------------------------

test_that("emoji_emotion(long = TRUE) keeps a user column named .row_number", {
  df <- data.frame(.row_number = c("keep_a", "keep_b"),
                   text = c("a \U0001F600", "b"))
  out <- emoji_emotion(df, text, long = TRUE)
  expect_true(".row_number" %in% names(out))
  expect_equal(nrow(out), 16L)
  expect_equal(unique(out$.row_number), c("keep_a", "keep_b"))
  expect_named(out, c(".row_number", "text", ".emoji_emotion", ".emoji_score"))
})
