# Regression tests for the 0.4.0 correctness fixes.

laugh <- "\U0001f602"
rage  <- "\U0001f621"
party <- "\U0001f389"

# ---------------------------------------------------------------------------
# Document order must not depend on the session's collation. factor(ids)
# ordered the levels with sort(), so the rows of a dfm built with doc_id came
# out in a locale-dependent order.
# ---------------------------------------------------------------------------

test_that("emoji_dfm keeps documents in first-appearance order of the id", {
  df <- data.frame(author = c("zoe", "adam", "zoe"),
                   text = c(laugh, rage, laugh))
  out <- emoji_dfm(df, text, doc_id = author)
  expect_equal(out$author, c("zoe", "adam"))
  expect_equal(out[[laugh]], c(2L, 0L))
  expect_equal(out[[rage]], c(0L, 1L))
})

test_that("emoji_dfm gives an NA doc_id its own document", {
  df <- data.frame(author = c("a", NA, "a"), text = c(laugh, rage, party))
  out <- emoji_dfm(df, text, doc_id = author)
  expect_equal(nrow(out), 2L)
  expect_equal(out$author, c("a", NA))
  expect_equal(out[[rage]], c(0L, 1L))
})

test_that("emoji_dfm doc_id keeps the id's own type", {
  df <- data.frame(day = as.Date(c("2024-01-02", "2024-01-01")),
                   text = c(laugh, rage))
  out <- emoji_dfm(df, text, doc_id = day)
  expect_s3_class(out$day, "Date")
  expect_equal(out$day, as.Date(c("2024-01-02", "2024-01-01")))
})

test_that("emoji_pairs is unaffected by document order", {
  df <- data.frame(id = c("zoe", "adam", "zoe"),
                   text = c(laugh, rage, party))
  out <- emoji_pairs(df, text, doc_id = id)
  expect_equal(nrow(out), 1L)
  expect_setequal(c(out$item1, out$item2), c(laugh, party))
})

# ---------------------------------------------------------------------------
# The new verbs share the engine's conventions: tibbles in, tibbles out; NA
# text is not an emoji; every glyph-to-metadata join goes through the
# codepoint key.
# ---------------------------------------------------------------------------

test_that("every new row-wise verb accepts NA text without erroring", {
  df <- data.frame(text = c(NA_character_, paste0("hi ", laugh)),
                   score = c(0.1, 0.2),
                   when = as.Date(c("2024-01-01", "2024-01-02")))
  expect_equal(emoji_risk(df, text)$.emoji_n, c(0L, 1L))
  expect_equal(emoji_type(df, text)$.emoji_type[1], NA_character_)
  expect_equal(emoji_faceness(df, text)$.emoji_n, c(0L, 1L))
  expect_equal(emoji_token_cost(df, text)$.emoji_bytes[1], 0L)
  expect_true(is.na(emoji_incongruity(df, text, score,
                                      scale = "none")$.emoji_incongruity[1]))
  expect_equal(nrow(emoji_context(df, text)), 1L)
  expect_equal(nrow(emoji_trend(df, text, when)), 1L)
})

test_that("the new verbs return tibbles and keep the original columns", {
  df <- tibble::tibble(id = 1:2, body = c(paste0("hi ", laugh), "plain"))
  for (out in list(emoji_risk(df, body), emoji_type(df, body),
                   emoji_faceness(df, body), emoji_token_cost(df, body),
                   emoji_sanitize(df, body, policy = "strip"))) {
    expect_s3_class(out, "tbl_df")
    expect_true(all(c("id", "body") %in% names(out)))
    expect_equal(nrow(out), 2L)
  }
})

test_that("qualified and unqualified twins resolve identically everywhere", {
  qualified <- "✌️"
  unqualified <- "✌"
  expect_equal(as_emoji_type(qualified), as_emoji_type(unqualified))
  df <- data.frame(text = c(qualified, unqualified))
  # the relational-style verbs canonicalise, so both rows are one series
  expect_equal(nrow(emoji_version_profile(df, text)), 1L)
  expect_equal(emoji_version_profile(df, text)$n_types, 1L)
})

# ---------------------------------------------------------------------------
# Argument validation on the older verbs: three arguments could previously be
# given nonsense and return a quietly wrong answer instead of erroring.
# ---------------------------------------------------------------------------

test_that("emoji_to_text rejects a wrap template with no placeholder", {
  df <- data.frame(text = paste0("hi ", laugh))
  expect_error(emoji_to_text(df, text, format = "shortcode", wrap = "none"),
               "\\{x\\}")
  # the placeholder is still honoured when it is there
  expect_equal(emoji_to_text(df, text, format = "shortcode",
                             wrap = "<{x}>")$text,
               paste0("hi <", as_emoji_shortcode(laugh), ">"))
  # and `wrap` is irrelevant to format = "name"
  expect_no_error(emoji_to_text(df, text, format = "name", wrap = "none"))
})

test_that("top_n_emojis rejects a negative n instead of dropping rows", {
  df <- data.frame(text = c(laugh, laugh, rage))
  expect_error(top_n_emojis(df, text, n = -1), "non-negative")
  expect_equal(nrow(top_n_emojis(df, text, n = 0)), 0L)
  expect_equal(nrow(top_n_emojis(df, text, n = Inf)), 2L)
})

test_that("emoji_score defaults to the bundled sentiment lexicon", {
  df <- data.frame(text = c(paste0("love ", laugh), "plain"))
  out <- emoji_score(df, text)
  expect_true(".emoji_score" %in% names(out))
  expect_equal(out$.emoji_score,
               emoji_score(df, text, lexicon = "novak2015")$.emoji_score)
})

test_that("logical arguments reject values that are not TRUE or FALSE", {
  # isTRUE() reads every non-TRUE value as FALSE, so an unchecked flag turned a
  # typo into a different, silently wrong result
  df <- data.frame(text = c(paste0(laugh, rage), laugh))
  expect_error(emoji_pairs(df, text, directed = "yes"), "TRUE or FALSE")
  expect_error(emoji_pairs(df, text, sort = "yes"), "TRUE or FALSE")
  expect_error(emoji_cooccurrence(df, text, diagonal = "yes"), "TRUE or FALSE")
  expect_error(emoji_emotion(df, text, long = "yes"), "TRUE or FALSE")
  expect_error(emoji_context(df, text, keep_text = "yes"), "TRUE or FALSE")
  expect_error(top_n_emojis(df, text, duplicated = "yes"), "TRUE or FALSE")
  expect_error(emoji_sentiment(df, text, se = NA), "TRUE or FALSE")
})

test_that("the deprecated duplicated_unicode = \"yes\" still works", {
  # the legacy argument documented the string "yes", so the new check has to
  # run after the lifecycle conversion, not before it
  df <- data.frame(text = c(laugh, laugh, rage))
  expect_warning(out <- top_n_emojis(df, text, duplicated_unicode = "yes"),
                 class = "lifecycle_warning_deprecated")
  expect_gt(nrow(out), 0L)
  expect_true("emoji_name" %in% names(out))
})
