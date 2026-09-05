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
  qualified <- "\u270C\uFE0F"
  unqualified <- "\u270C"
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


# ---------------------------------------------------------------------------
# Column resolution. Every verb takes its column as an unquoted name, and each
# one used to resolve it with dplyr::pull(), whose errors name `var` -- a
# formal of pull() that appears in no tidyEmoji signature. The shared resolver
# names the user's own argument instead, and grouped input no longer trips the
# "Adding missing grouping variables" behaviour of dplyr::select().
# ---------------------------------------------------------------------------

test_that("an omitted text column names `text`, not `var`", {
  df <- data.frame(text = c(laugh, rage))
  expect_error(emoji_sentiment(df), "`text` is required")
  expect_error(emoji_summary(df), "`text` is required")
  expect_error(emoji_frequency(df), "`text` is required")
  expect_error(emoji_position(df), "`text` is required")
  expect_error(emoji_dfm(df), "`text` is required")
  expect_error(emoji_ngrams(df), "`text` is required")
  expect_error(emoji_to_text(df), "`text` is required")
})

test_that("an omitted time column names `time`, not `var`", {
  df <- data.frame(text = c(laugh, rage),
                   when = as.Date(c("2020-01-01", "2020-02-01")))
  expect_error(emoji_trend(df, text), "`time` is required")
  expect_error(emoji_turnover(df, text), "`time` is required")
  expect_error(emoji_seasonality(df, text), "`time` is required")
  expect_error(emoji_adoption_lag(df, text), "`time` is required")
})

test_that("a text selection of two columns names `text`", {
  df <- data.frame(a = "x", text = laugh)
  expect_error(emoji_sentiment(df, c(a, text)),
               "`text` must select exactly one column")
  expect_error(emoji_ratio(df, c(a, text)),
               "`text` must select exactly one column")
})

test_that("a misspelled column is reported by name", {
  df <- data.frame(text = c(laugh, rage))
  expect_error(emoji_sentiment(df, txet), "txet")
  expect_error(emoji_summary(df, txet), "txet")
  expect_error(emoji_frequency(df, txet), "txet")
})

test_that("emoji_extract_nest rejects a missing text column", {
  # it resolved `{{ text }}` in the data mask, so emoji_extract_nest(df)
  # silently returned an empty list-column instead of erroring
  df <- data.frame(text = c(laugh, rage))
  expect_error(emoji_extract_nest(df), "`text` is required")
  expect_error(emoji_extract_nest(df, txet), "txet")
})

test_that("grouped input does not trip the column resolver", {
  # dplyr::select() re-adds the grouping columns, which made the selection
  # return two names and these six verbs error out on grouped data
  df <- dplyr::group_by(
    data.frame(g = c("a", "b"), text = c(paste("hi", laugh), "plain")),
    g
  )
  expect_equal(nrow(emoji_to_text(df, text)), 2L)
  expect_equal(nrow(text_to_emoji(df, text)), 2L)
  expect_equal(nrow(emoji_sanitize(df, text, policy = "strip")), 2L)
  expect_equal(nrow(emoji_context(df, text)), 1L)
  expect_s3_class(suppressWarnings(emoji_collocations(df, text)), "tbl_df")
})


# ---------------------------------------------------------------------------
# Grouping must survive the row-preserving verbs. tibble::as_tibble() dropped
# the grouped_df class, so a later summarise() silently produced one
# corpus-wide row instead of one row per group.
# ---------------------------------------------------------------------------

test_that("the row-preserving verbs keep the input's grouping", {
  df <- dplyr::group_by(
    data.frame(g = c("a", "a", "b"), text = c(laugh, rage, party)),
    g
  )
  keeps_groups <- function(out) {
    dplyr::is_grouped_df(out) && identical(dplyr::group_vars(out), "g")
  }
  expect_true(keeps_groups(emoji_sentiment(df, text)))
  expect_true(keeps_groups(emoji_emotion(df, text)))
  expect_true(keeps_groups(emoji_position(df, text)))
  expect_true(keeps_groups(emoji_ratio(df, text)))
  expect_true(keeps_groups(emoji_density(df, text)))
  expect_true(keeps_groups(emoji_type(df, text)))
  expect_true(keeps_groups(emoji_faceness(df, text)))
  expect_true(keeps_groups(emoji_risk(df, text)))
  expect_true(keeps_groups(emoji_token_cost(df, text)))
  expect_true(keeps_groups(emoji_extract_nest(df, text)))
  expect_true(keeps_groups(emoji_filter(df, text)))
  expect_true(keeps_groups(emoji_tokens(df, text)))
  expect_true(keeps_groups(emoji_categorize(df, text)))
  expect_true(keeps_groups(emoji_sanitize(df, text, policy = "strip")))
  expect_true(keeps_groups(emoji_to_text(df, text)))
})

test_that("a grouped summarise() after a row verb answers per group", {
  df <- dplyr::group_by(
    data.frame(g = c("a", "a", "b"), text = c(laugh, laugh, rage)),
    g
  )
  out <- dplyr::summarise(emoji_sentiment(df, text),
                          n = dplyr::n(), .groups = "drop")
  expect_equal(nrow(out), 2L)
  expect_equal(out$n, c(2L, 1L))
})

test_that("ungrouped input still returns a plain tibble", {
  df <- data.frame(text = c(laugh, rage))
  expect_identical(class(emoji_sentiment(df, text)),
                   c("tbl_df", "tbl", "data.frame"))
  expect_false(dplyr::is_grouped_df(emoji_sentiment(df, text)))
})

test_that("rewriting a grouping column re-derives the groups", {
  # emoji_sanitize(policy = "strip") rewrites the text column; if the user
  # grouped by it, the stale indices would still describe the old values
  df <- dplyr::group_by(
    data.frame(text = c(paste("hi", laugh), paste("hi", rage), "hi")),
    text
  )
  out <- emoji_sanitize(df, text, policy = "strip")
  expect_equal(dplyr::n_groups(out), 1L)
  expect_equal(dplyr::group_data(out)$text, "hi")
})


# ---------------------------------------------------------------------------
# The grouped-input guard on the cross-row aggregators. Seven of them had no
# guard at all, and the two that delegate warned under the name of the verb
# they delegated to. Each expect_warning() below is its own call site, because
# lifecycle deduplicates and a loop would report only the first as warning.
# ---------------------------------------------------------------------------

grouped_fixture <- function() {
  dplyr::group_by(
    data.frame(
      g = c("a", "a", "b"),
      text = c(paste("one", laugh, "two"), paste("three", rage, "four"),
               paste("five", party, "six")),
      when = as.Date(c("2020-01-01", "2020-02-01", "2020-03-01")),
      sc = c(1, 0, -1)
    ),
    g
  )
}

test_that("every cross-row aggregator warns about ignored groups", {
  df <- grouped_fixture()
  cls <- "lifecycle_warning_deprecated"
  expect_warning(emoji_summary(df, text), class = cls)
  expect_warning(emoji_frequency(df, text), class = cls)
  expect_warning(top_n_emojis(df, text), class = cls)
  expect_warning(emoji_dfm(df, text), class = cls)
  expect_warning(emoji_pairs(df, text), class = cls)
  expect_warning(emoji_cooccurrence(df, text), class = cls)
  expect_warning(emoji_flag_ambiguous(df, text), class = cls)
  expect_warning(emoji_version_profile(df, text), class = cls)
  expect_warning(emoji_trend(df, text, when), class = cls)
  expect_warning(emoji_turnover(df, text, when), class = cls)
  expect_warning(emoji_seasonality(df, text, when), class = cls)
  expect_warning(emoji_adoption_lag(df, text, when), class = cls)
  expect_warning(emoji_collocations(df, text, min_n = 1), class = cls)
  expect_warning(
    emoji_incongruity_profile(df, text, text_score = sc, scale = "none",
                              min_n = 1),
    class = cls
  )
})

test_that("a delegating aggregator warns under its own name", {
  # emoji_cooccurrence() used to warn about emoji_pairs(), and
  # emoji_flag_ambiguous() about emoji_frequency() -- verbs the user never
  # called, and which lifecycle then deduplicated into silence
  df <- grouped_fixture()
  expect_warning(emoji_cooccurrence(df, text), "emoji_cooccurrence")
  expect_warning(emoji_flag_ambiguous(df, text), "emoji_flag_ambiguous")
})

test_that("the guard does not blame the tidyEmoji package for the warning", {
  # lifecycle's default env/user_env are the helper's own frames, which made it
  # append "Please report the issue at ..." to a warning about the user's data
  df <- grouped_fixture()
  msg <- tryCatch(emoji_version_profile(df, text),
                  warning = function(w) conditionMessage(w))
  expect_false(grepl("report the issue", msg, fixed = TRUE))
})

test_that("the row-at-a-time verbs stay silent on grouped input", {
  # grouping cannot change their answer, and they now carry it through
  df <- grouped_fixture()
  expect_no_warning(emoji_sentiment(df, text))
  expect_no_warning(emoji_position(df, text))
  expect_no_warning(emoji_ngrams(df, text))
  expect_no_warning(emoji_categorize(df, text))
  expect_no_warning(emoji_context(df, text))
  expect_no_warning(emoji_extract_unnest(df, text))
})


# ---------------------------------------------------------------------------
# emoji_position()'s relative position counted code points, so a
# multi-code-point emoji inflated the denominator and an emoji that was
# genuinely the last thing in the message came back well short of 1.
# ---------------------------------------------------------------------------

test_that("a sentence-final emoji scores 1 whatever it is built from", {
  family <- "\U0001F468\u200D\U0001F469\u200D\U0001F467\u200D\U0001F466"
  flag <- "\U0001f1fa\U0001f1f8"
  smile <- "\U0001f600"
  df <- data.frame(text = c(paste0("hi ", smile),
                            paste0("hi ", flag),
                            paste0("hi ", family)))
  out <- emoji_position(df, text)
  # nchar() is 4 / 5 / 10 for these three; the old denominator gave
  # 1.000 / 0.750 / 0.333
  expect_equal(out$.emoji_rel_position, c(1, 1, 1))
  # the raw offsets stay in code points, so substr() still works with them
  expect_equal(out$.emoji_first, c(4L, 4L, 4L))
  expect_equal(substr(df$text[3], out$.emoji_first[3], nchar(df$text[3])),
               family)
})

test_that("a leading emoji scores 0 and two emoji average correctly", {
  family <- "\U0001F468\u200D\U0001F469\u200D\U0001F467\u200D\U0001F466"
  smile <- "\U0001f600"
  df <- data.frame(text = c(paste0(smile, " hi"),
                            paste0(smile, " hi ", family),
                            smile))
  out <- emoji_position(df, text)
  expect_equal(out$.emoji_rel_position, c(0, 0.5, 0))
  expect_equal(out$.emoji_n, c(1L, 2L, 1L))
})

test_that("emoji_position still returns NA for rows with no emoji", {
  df <- data.frame(text = c("plain text", NA))
  out <- emoji_position(df, text)
  expect_equal(out$.emoji_n, c(0L, 0L))
  expect_true(all(is.na(out$.emoji_rel_position)))
  expect_true(all(is.na(out$.emoji_first)))
})


# ---------------------------------------------------------------------------
# "Empty input returns a typed zero-row tibble" is one of the package's stated
# invariants, and five verbs broke it: they built columns with ifelse(), which
# takes the result's type from its arguments and so returned logical(0) where
# the populated call returns double, integer or character.
# ---------------------------------------------------------------------------

test_that("zero-row output has the same column types as populated output", {
  empty <- data.frame(text = character())
  full <- data.frame(text = c(paste("hi", laugh, "there"), "plain"))
  same_types <- function(f) {
    e <- f(empty)
    p <- f(full)
    common <- base::intersect(names(e), names(p))
    identical(vapply(e[common], function(x) class(x)[1], character(1)),
              vapply(p[common], function(x) class(x)[1], character(1)))
  }
  expect_true(same_types(function(d) emoji_density(d, text)))
  expect_true(same_types(function(d) emoji_ratio(d, text)))
  expect_true(same_types(function(d) emoji_faceness(d, text)))
  expect_true(same_types(function(d) emoji_risk(d, text)))
  expect_true(same_types(function(d) emoji_tokens(d, text)))
  expect_true(same_types(function(d) emoji_position(d, text)))
  expect_true(same_types(function(d) emoji_sentiment(d, text)))
})

test_that("the zero-row types are the documented ones, not just consistent", {
  empty <- data.frame(text = character())
  expect_type(emoji_density(empty, text)$.emoji_per_char, "double")
  expect_type(emoji_density(empty, text)$.emoji_per_token, "double")
  expect_type(emoji_ratio(empty, text)$.emoji_ratio, "double")
  expect_type(emoji_ratio(empty, text)$.emoji_only, "logical")
  expect_type(emoji_faceness(empty, text)$.emoji_n_typed, "integer")
  expect_type(emoji_faceness(empty, text)$.emoji_faceness, "double")
  expect_type(emoji_risk(empty, text)$.emoji_n_scored, "integer")
  expect_type(emoji_tokens(empty, text)$.emoji, "character")
})

test_that("the ifelse rewrite did not change any value", {
  df <- data.frame(text = c(paste("hi", laugh, "there"), laugh, "plain", "",
                            "   ", NA, paste0(laugh, laugh)))
  d <- emoji_density(df, text)
  expect_equal(d$.emoji_per_char, c(0.1, 1, 0, NA, 0, NA, 1))
  expect_equal(d$.emoji_per_token, c(1 / 3, 1, 0, NA, 0, NA, 2))
  r <- emoji_ratio(df, text)
  expect_equal(r$.emoji_ratio, c(0.1, 1, 0, NA, 0, NA, 1))
  f <- emoji_faceness(df, text)
  expect_equal(f$.emoji_n_typed, c(1L, 1L, NA, NA, NA, NA, 2L))
  expect_equal(f$.emoji_faceness, c(1, 1, NA, NA, NA, NA, 1))
})


# ---------------------------------------------------------------------------
# Count-like arguments were absorbed rather than rejected when fractional:
# head(n = 2.5) returns two rows, as.integer(window = 2.7) is a window of two.
# Same failure mode as the head(n = -1) the 0.4.0 audit caught.
# ---------------------------------------------------------------------------

test_that("a fractional count errors instead of being truncated", {
  df <- data.frame(text = c(paste0(laugh, rage, party), paste0(laugh, laugh)),
                   when = as.Date(c("2020-01-01", "2020-02-01")))
  expect_error(top_n_emojis(df, text, n = 1.9), "whole number")
  expect_error(emoji_ngrams(df, text, n = 2.9), "whole number")
  expect_error(emoji_context(df, text, window = 2.7), "whole number")
  expect_error(emoji_collocations(df, text, min_n = 1.5), "whole number")
  expect_error(emoji_trend(df, text, when, top_n = 2.5), "whole number")
  expect_error(emoji_flag_ambiguous(df, text, top_n = 0.5), "whole number")
})

test_that("whole numbers, NULL and Inf are still accepted", {
  df <- data.frame(text = c(paste0(laugh, rage, party), paste0(laugh, laugh)),
                   when = as.Date(c("2020-01-01", "2020-02-01")))
  expect_equal(nrow(top_n_emojis(df, text, n = 0)), 0L)
  expect_equal(nrow(top_n_emojis(df, text, n = Inf)), 3L)
  expect_equal(nrow(emoji_context(df, text, window = 0)), 5L)
  expect_s3_class(emoji_trend(df, text, when, top_n = NULL), "tbl_df")
  expect_equal(emoji_ngrams(df, text, n = 2)$.emoji_ngram,
               c(paste(laugh, rage), paste(rage, party),
                 paste(laugh, laugh)))
})

test_that("emoji_ngrams(sep = ) must be a single string", {
  # sep reached paste(collapse = ), which errored with "invalid 'collapse'
  # argument" from inside an internal vapply for NA and for a number, and
  # silently used only the first element of a longer vector
  df <- data.frame(text = paste0(laugh, rage))
  expect_error(emoji_ngrams(df, text, sep = NA), "`sep` must be a single")
  expect_error(emoji_ngrams(df, text, sep = 1), "`sep` must be a single")
  expect_error(emoji_ngrams(df, text, sep = c("-", "+")),
               "`sep` must be a single")
  expect_equal(emoji_ngrams(df, text, sep = "-")$.emoji_ngram,
               paste0(laugh, "-", rage))
})

test_that("emoji_sanitize(placeholder = ) must be a single string", {
  df <- data.frame(text = paste("hi", laugh))
  expect_error(emoji_sanitize(df, text, policy = "placeholder",
                              placeholder = 1),
               "`placeholder` must be a single")
})


# ---------------------------------------------------------------------------
# The detection contract the help page now states, pinned so a change to it is
# a deliberate one. Bare (text-presentation) code points are not detected;
# the U+FE0F-stripped join is unaffected by that.
# ---------------------------------------------------------------------------

test_that("the qualified/unqualified split is detection-only", {
  qualified <- "\u2764\uFE0F"
  bare <- "\u2764"
  df <- data.frame(text = c(paste("love", qualified), paste("love", bare)))
  # detection: only the qualified form is seen
  expect_equal(emoji_summary(df, text)$n_with_emoji, 1L)
  # the join: both resolve to the same metadata
  expect_equal(as_emoji_name(bare), as_emoji_name(qualified))
  expect_equal(as_emoji_shortcode(bare), as_emoji_shortcode(qualified))
  expect_false(is.na(as_emoji_name(bare)))
})

test_that("the two forms are one item once detected", {
  # a text carrying the qualified form twice counts as one emoji type
  qualified <- "\u2764\uFE0F"
  df <- data.frame(text = c(qualified, paste("x", qualified)))
  freq <- emoji_frequency(df, text)
  expect_equal(nrow(freq), 1L)
  expect_equal(freq$n, 2L)
})


# ---------------------------------------------------------------------------
# The lexicon registry accepted two registrations it could never honour:
# one under a bundled lexicon's name (resolved before the registry is
# consulted, so the entry was unreachable), and one with no score column
# (which only failed later, from inside emoji_score()).
# ---------------------------------------------------------------------------

test_that("registering under a bundled lexicon's name is refused", {
  tbl <- data.frame(emoji = c(laugh, rage), score = c(99, -99))
  for (nm in c("novak2015", "emoji_sentiment_lexicon", "sentiment",
               "emotag1200", "emoji_emotion_lexicon", "emotion")) {
    expect_error(register_emoji_lexicon(nm, tbl), "Reserved")
  }
  # and the bundled lexicon is untouched by the attempt
  df <- data.frame(text = paste("hi", laugh))
  expect_equal(emoji_score(df, text, lexicon = "novak2015")$.emoji_score,
               emoji_score(df, text)$.emoji_score)
})

test_that("a lexicon with no score column is refused at registration", {
  expect_error(register_emoji_lexicon("no-score", data.frame(emoji = laugh)),
               "no score column")
  # an emotion-shaped lexicon has no `score` column and must still register
  expect_s3_class(
    register_emoji_lexicon("emo-shaped",
                           data.frame(emoji = laugh, joy = 1, anger = 0)),
    "data.frame"
  )
})

test_that("emoji_lexicons() names stay unique and usable", {
  tbl <- data.frame(emoji = c(laugh, rage), score = c(99, -99))
  register_emoji_lexicon("unique-name-check", tbl)
  lex <- emoji_lexicons()
  expect_false(anyDuplicated(lex$name) > 0)
  df <- data.frame(text = paste("hi", laugh))
  expect_equal(emoji_score(df, text, lexicon = "unique-name-check")$.emoji_score,
               99)
})

test_that("register_emoji_lexicon rejects an NA name", {
  tbl <- data.frame(emoji = laugh, score = 1)
  expect_error(register_emoji_lexicon(NA, tbl), "non-empty string")
  expect_error(register_emoji_lexicon(NA_character_, tbl), "non-empty string")
})


# ---------------------------------------------------------------------------
# A time column of strings loses every value that will not parse, and the row
# is then dropped -- indistinguishable in the result from a genuinely missing
# date. Say how many.
# ---------------------------------------------------------------------------

test_that("unparseable dates warn before they are dropped", {
  df <- data.frame(text = rep(laugh, 4),
                   when = c("2020-01-01", "not a date", "2020-02-01",
                            "2020-13-45"))
  expect_warning(out <- emoji_trend(df, text, when),
                 "could not be read as a date")
  expect_equal(nrow(out), 2L)
  expect_warning(emoji_turnover(df, text, when), "could not be read")
  expect_warning(emoji_adoption_lag(df, text, when), "could not be read")
  expect_warning(emoji_seasonality(df, text, when), "could not be read")
})

test_that("a genuinely missing date does not warn", {
  expect_no_warning(
    emoji_trend(data.frame(text = rep(laugh, 3),
                           when = c("2020-01-01", NA, "2020-02-01")),
                text, when)
  )
  expect_no_warning(
    emoji_trend(data.frame(text = rep(laugh, 2),
                           when = as.Date(c("2020-01-01", NA))),
                text, when)
  )
})

test_that("a wholly unparseable time column still errors", {
  expect_error(
    emoji_trend(data.frame(text = c(laugh, rage), when = c("x", "y")),
                text, when),
    "must be a Date"
  )
})


# ---------------------------------------------------------------------------
# The emoji_sanitize() loss ladder that ?emoji_sanitize now documents. Pinned
# so a change to which policies are reversible is a deliberate one.
# ---------------------------------------------------------------------------

test_that("shortcode is the only lossy-looking policy that round-trips", {
  src <- paste0("great ", laugh, " work ", rage, " today")
  df <- data.frame(text = src)
  restores <- function(policy) {
    out <- emoji_sanitize(df, text, policy = policy)$text
    identical(text_to_emoji(data.frame(text = out), text)$text, src)
  }
  expect_true(restores("keep"))
  expect_true(restores("shortcode"))
  expect_false(restores("name"))
  expect_false(restores("placeholder"))
  expect_false(restores("strip"))
})

test_that("the shortcode round-trip survives the awkward glyphs", {
  hard <- c(
    "\U0001F44D\U0001F3FD",                                        # skin tone
    "\U0001F1FA\U0001F1F8",                                        # flag
    "\U0001F468\u200D\U0001F469\u200D\U0001F467\u200D\U0001F466",  # ZWJ family
    "1\uFE0F\u20E3",                                               # keycap
    "\u2764\uFE0F"                                                 # qualified
  )
  for (h in hard) {
    src <- paste("x", h, "y")
    out <- emoji_sanitize(data.frame(text = src), text,
                          policy = "shortcode")$text
    expect_identical(text_to_emoji(data.frame(text = out), text)$text, src)
  }
})

test_that("placeholder keeps where but not which", {
  src <- paste0("a ", laugh, " b ", rage, " c")
  out <- emoji_sanitize(data.frame(text = src), text,
                        policy = "placeholder")$text
  expect_identical(out, "a [emoji] b [emoji] c")
})


# ---------------------------------------------------------------------------
# The bundled data's own arithmetic, pinned. These are the columns every
# affect verb reads, and a rebuild of data-raw/ that quietly changed one of
# them would otherwise show up only as slightly wrong scores.
# ---------------------------------------------------------------------------

test_that("the sentiment lexicon is internally consistent", {
  L <- emoji_sentiment_lexicon
  expect_equal(L$negative + L$neutral + L$positive, L$occurrences)
  expect_equal(L$sentiment_score,
               (L$positive - L$negative) / L$occurrences)
  expect_equal(
    L$sentiment_label,
    ifelse(L$sentiment_score > 0, "positive",
           ifelse(L$sentiment_score < 0, "negative", "neutral"))
  )
  expect_true(all(L$occurrences > 0))
  expect_true(all(L$position >= 0 & L$position <= 1))
  expect_true(all(L$sentiment_score >= -1 & L$sentiment_score <= 1))
})

test_that("both lexicons have unique, non-missing join keys", {
  kL <- tidyEmoji:::emoji_key(emoji_sentiment_lexicon$emoji)
  expect_false(anyNA(kL))
  expect_equal(anyDuplicated(kL), 0L)
  E <- emoji_emotion_lexicon
  expect_identical(as.character(E$key), tidyEmoji:::emoji_key(E$emoji))
  expect_equal(anyDuplicated(E$key), 0L)
})

test_that("emotion scores stay in the documented [0, 1] range", {
  dims <- c("anger", "anticipation", "disgust", "fear",
            "joy", "sadness", "surprise", "trust")
  m <- as.matrix(emoji_emotion_lexicon[, dims])
  expect_false(anyNA(m))
  expect_true(all(m >= 0 & m <= 1))
})

test_that("emoji_ambiguity's shares and counts come from the lexicon", {
  L <- emoji_sentiment_lexicon
  a <- emoji_ambiguity()
  expect_equal(nrow(a), nrow(L))
  expect_true(all(abs(a$p_neg + a$p_neu + a$p_pos - 1) < 1e-9))
  # n_annotations is the lexicon's occurrences, not a separate figure
  k <- tidyEmoji:::emoji_key(L$emoji)
  i <- match(k, a$key)
  expect_equal(a$n_annotations[i], L$occurrences)
  # entropy cannot exceed log(3) for a three-class distribution
  expect_true(all(a$ambiguity >= 0 & a$ambiguity <= log(3) + 1e-9))
})

test_that("the category crosswalk matches the reference table's groups", {
  expect_setequal(category_unicode_crosswalk$category,
                  unique(tidyEmoji:::emoji_reference()$group))
  expect_false(anyNA(category_unicode_crosswalk))
  expect_false(anyNA(emoji_unicode_crosswalk))
})


# ---------------------------------------------------------------------------
# The strongest form of the reversibility claim ?emoji_sanitize makes, run
# over the whole reference table rather than a handful of examples. Identity
# is preserved for every glyph; the byte-level exceptions are U+FE0F only.
# ---------------------------------------------------------------------------

test_that("the shortcode round trip is byte-exact for canonical spellings", {
  # the strong form of the claim, and the one that stops moving every time
  # detection improves: over the spelling real text holds, nothing changes
  ref <- tidyEmoji:::emoji_reference()
  canonical <- ref$emoji[!duplicated(ref$key) & !is.na(ref$shortcode)]
  expect_gt(length(canonical), 3000L)
  src <- paste0("x ", canonical, " y")
  out <- emoji_sanitize(data.frame(text = src), text,
                        policy = "shortcode")$text
  back <- text_to_emoji(data.frame(text = out), text)$text
  expect_identical(back, src)
})

test_that("an alternate spelling round-trips to the canonical one", {
  ref <- tidyEmoji:::emoji_reference()
  glyphs <- ref$emoji[!is.na(ref$shortcode)]
  src <- paste0("x ", glyphs, " y")
  out <- emoji_sanitize(data.frame(text = src), text,
                        policy = "shortcode")$text
  back <- text_to_emoji(data.frame(text = out), text)$text
  recovered <- sub("^x ", "", sub(" y$", "", back))
  # same codepoint key = the same emoji, whatever its qualification
  expect_equal(tidyEmoji:::emoji_key(recovered),
               tidyEmoji:::emoji_key(glyphs))
  # and the exceptions to byte-identity differ by U+FE0F alone
  differing <- which(back != src)
  strip_vs <- function(x) {
    vapply(x, function(g) {
      cp <- utf8ToInt(g)
      intToUtf8(cp[cp != 0xFE0F])
    }, character(1), USE.NAMES = FALSE)
  }
  expect_equal(strip_vs(back[differing]), strip_vs(src[differing]))
  # The byte-identity rate over *all* spellings is not a fixed property: it
  # falls every time detection improves, because a spelling that used to
  # fragment now merges and resolves to the canonical form. So assert what is
  # actually invariant -- identity is preserved and every difference is U+FE0F
  # alone, both above -- and only sanity-bound the rate.
  expect_gt(mean(back == src), 0.5)
})


# ---------------------------------------------------------------------------
# The engine's own edge cases. Everything in the package goes through these
# three helpers, so a change here moves every count in the package.
# ---------------------------------------------------------------------------

test_that("emoji_key has exactly one no-key sentinel", {
  K <- tidyEmoji:::emoji_key
  # a string of nothing but variation selectors leaves no code points, and
  # used to key on "" -- a second "no key" value beside NA that every consumer
  # then had to filter separately
  expect_true(is.na(K("")))
  expect_true(is.na(K("\uFE0F")))
  expect_true(is.na(K("\uFE0F\uFE0F")))
  expect_true(is.na(K(NA_character_)))
  expect_identical(K(character(0)), character(0))
  # and the qualified / unqualified pair still share one key
  expect_identical(K("\u2764\uFE0F"), K("\u2764"))
})

test_that("a lexicon row with no key is ignored rather than fatal", {
  register_emoji_lexicon("stray-selector",
                         data.frame(emoji = c(laugh, "\uFE0F"),
                                    score = c(1, 9)))
  out <- emoji_score(data.frame(text = c(paste("hi", laugh), "plain")), text,
                     lexicon = "stray-selector")
  expect_equal(out$.emoji_score, c(1, NA))
})

test_that("the ZWJ repair binds only between two emoji", {
  gl <- tidyEmoji:::emoji_glyph_list
  Z <- "\u200D"
  man <- "\U0001F468"
  woman <- "\U0001F469"
  one <- function(s) gl(s)[[1]]
  # UAX #29 GB11: a ZWJ between two emoji binds them into one cluster
  expect_equal(one(paste0(man, Z, woman)), paste0(man, Z, woman))
  expect_equal(one(paste0(man, Z, woman, Z, man)),
               paste0(man, Z, woman, Z, man))
  # and nothing else does
  expect_equal(one(paste0(laugh, Z)), laugh)
  expect_equal(one(paste0(Z, laugh)), laugh)
  expect_equal(one(paste0(laugh, Z, "x")), laugh)
  expect_equal(one(paste0("x", Z, laugh)), laugh)
  expect_equal(one(paste0(man, Z, Z, woman)), c(man, woman))
  expect_equal(one(paste0(man, Z, " ", woman)), c(man, woman))
  expect_equal(one(paste0(man, " ", Z, woman)), c(man, woman))
  expect_equal(one(Z), character(0))
})

test_that("emoji_canonical collapses qualification and passes unknowns", {
  can <- tidyEmoji:::emoji_canonical
  expect_identical(can(character(0)), character(0))
  expect_identical(can(c("\u2764\uFE0F", "\u2764")),
                   rep(can("\u2764\uFE0F"), 2))
  expect_identical(can("\uFFFF"), "\uFFFF")
  expect_true(is.na(can(NA_character_)))
})

test_that("document splitting keeps first-appearance order and NA groups", {
  sp <- tidyEmoji:::.emoji_id_split
  expect_equal(unname(lapply(sp(c("a", "b", "a")), as.integer)),
               list(c(1L, 3L), 2L))
  expect_equal(unname(lapply(sp(c("a", NA, "a", NA)), as.integer)),
               list(c(1L, 3L), c(2L, 4L)))
  expect_equal(unname(lapply(sp(c(NA, NA)), as.integer)), list(c(1L, 2L)))
  expect_length(sp(character(0)), 0L)
  # numeric ids order by appearance, not by value
  expect_equal(unname(lapply(sp(c(2, 1, 2)), as.integer)),
               list(c(1L, 3L), 2L))
})


# ---------------------------------------------------------------------------
# emoji_risk() treated the same row two different ways: .emoji_n_scored was 0
# for a row whose emoji the lexicon cannot score, but .emoji_n_ambiguous was
# NA -- and the @return promised NA only for rows with no emoji at all.
# ---------------------------------------------------------------------------

test_that("emoji_risk's two counts agree about an unscorable row", {
  pleading <- "\U0001F97A"   # Unicode 11.0, post-dates the 2015 lexicon
  df <- data.frame(text = c(paste("hi", laugh), paste("hi", pleading),
                            "plain", paste(pleading, pleading)))
  out <- emoji_risk(df, text)
  expect_equal(out$.emoji_n, c(1L, 1L, 0L, 2L))
  expect_equal(out$.emoji_n_scored, c(1L, 0L, NA, 0L))
  # a count of ambiguous glyphs is 0, not unknown, when nothing was scorable
  expect_equal(out$.emoji_n_ambiguous, c(1L, 0L, NA, 0L))
  # but there is genuinely nothing to average
  expect_true(is.na(out$.emoji_ambiguity_mean[2]))
  expect_true(is.na(out$.emoji_ambiguity_max[4]))
  # NA appears in .emoji_n_ambiguous exactly where the row has no emoji
  expect_identical(is.na(out$.emoji_n_ambiguous), out$.emoji_n == 0L)
})


# ---------------------------------------------------------------------------
# emoji_categorize() filtered on "has a categorisable emoji", not on "has an
# emoji", so a row whose only glyph was absent from the reference table
# vanished. 0.2.1 fixed one instance of this (the U+FE0F-qualified heart) by
# repairing that join; the conflation itself survived.
# ---------------------------------------------------------------------------

test_that("emoji_categorize keeps an emoji-bearing row it cannot categorise", {
  # a ZWJ sequence UAX #29 makes one grapheme but that no catalogue lists --
  # exactly what a corpus newer than the installed {emoji} contains
  novel <- paste0("\U0001F600", "\u200D", "\U0001F600")
  expect_length(tidyEmoji:::emoji_glyph_list(novel)[[1]], 1L)
  expect_false(tidyEmoji:::emoji_key(novel) %in%
                 tidyEmoji:::emoji_reference()$key)

  df <- data.frame(text = c(paste("hi", laugh), paste("hi", novel), "plain",
                            paste(novel, novel), paste(laugh, novel)))
  out <- emoji_categorize(df, text)
  expect_equal(nrow(out), 4L)
  expect_equal(out$.emoji_category,
               c("Smileys & Emotion", NA, NA, "Smileys & Emotion"))
  # and a row with no emoji at all is still dropped
  expect_equal(nrow(emoji_categorize(data.frame(text = c("a", "b")), text)),
               0L)
})

test_that("categorize keeps exactly the rows emoji_filter keeps", {
  novel <- paste0("\U0001F600", "\u200D", "\U0001F600")
  df <- data.frame(text = c(paste("hi", laugh), novel, "plain", rage))
  expect_equal(nrow(emoji_categorize(df, text)),
               nrow(emoji_filter(df, text)))
})

test_that("the other verbs already reported the unknown glyph honestly", {
  # recorded so a future change does not "tidy" these NAs away: reporting the
  # glyph with NA metadata is what tells a user their catalogue is behind
  novel <- paste0("\U0001F600", "\u200D", "\U0001F600")
  df <- data.frame(text = paste("hi", novel))
  expect_equal(emoji_position(df, text)$.emoji_n, 1L)
  expect_true(is.na(emoji_type(df, text)$.emoji_type))
  expect_equal(emoji_faceness(df, text)$.emoji_n_typed, 0L)
  expect_equal(emoji_sentiment(df, text)$.emoji_n_scored, 0L)
  freq <- emoji_frequency(df, text)
  expect_equal(freq$emoji, novel)
  expect_true(is.na(freq$name))
  vp <- emoji_version_profile(df, text)
  expect_true(is.na(vp$version))
  expect_equal(vp$n_tokens, 1L)
  # an unknown glyph is left alone by the rewriting verbs, never dropped
  expect_equal(emoji_to_text(df, text)$text, paste("hi", novel))
  expect_equal(emoji_sanitize(df, text, policy = "placeholder")$text,
               "hi [emoji]")
})


# ---------------------------------------------------------------------------
# The ZWJ repair required the gap between two matches to be exactly one
# joiner, so a sequence whose middle component is a text-presentation code
# point -- undetected, therefore inside the gap -- was not rejoined. The
# result was not a missing count but a wrong one: the sequence arrived as its
# component emoji, none of which the text contains.
# ---------------------------------------------------------------------------

# A joiner left outside every detected span means the segmentation broke a
# sequence in half. It is a sharper test than counting glyphs: a sequence whose
# only detectable component is its first still yields exactly one match, so
# "did it come back as one glyph?" passes while the answer is the wrong emoji.
orphaned_joiners <- function(x) {
  zwj <- "\u200D"
  locs <- tidyEmoji:::.emoji_locations(x)
  vapply(seq_along(x), function(i) {
    s <- x[[i]]
    if (is.na(s) || !grepl(zwj, s, fixed = TRUE)) return(0L)
    m <- locs[[i]]
    inside <- rep(FALSE, nchar(s))
    for (k in seq_len(nrow(m))) inside[m[k, "start"]:m[k, "end"]] <- TRUE
    sum(strsplit(s, "")[[1]] == zwj & !inside)
  }, integer(1))
}

test_that("every canonical spelling segments with no joiner left over", {
  ref <- tidyEmoji:::emoji_reference()
  # the first spelling listed for each codepoint key is the fully-qualified one
  canonical <- ref$emoji[!duplicated(ref$key)]
  expect_gt(length(canonical), 3000L)
  expect_equal(sum(orphaned_joiners(canonical) > 0L), 0L)
  # and each canonical spelling is detected as exactly itself
  found <- tidyEmoji:::emoji_glyph_list(canonical)
  zwj_only <- grepl("\u200D", canonical, fixed = TRUE)
  expect_true(all(vapply(which(zwj_only), function(i)
    length(found[[i]]) == 1L && identical(found[[i]][1], canonical[i]),
    logical(1))))
})

test_that("no catalogued ZWJ sequence is split into several glyphs", {
  ref <- tidyEmoji:::emoji_reference()
  zwj <- ref$emoji[grepl("\u200D", ref$emoji, fixed = TRUE)]
  expect_gt(length(zwj), 2000L)
  n <- lengths(tidyEmoji:::emoji_glyph_list(zwj))
  # 232 of them used to split
  expect_equal(sum(n > 1L), 0L)
  # Exactly two go undetected, and they are these two: unqualified forms whose
  # every component needs U+FE0F, so there is no detectable component to grow
  # from. Asserting the *set* rather than a count matters -- `<= 2` accepted a
  # regression from 0 to 2 silently, and no count can see the set change while
  # its size stays the same.
  undetected <- zwj[n == 0L]
  expect_identical(
    sort(undetected),
    sort(c("\U0001F441\u200D\U0001F5E8", "\U0001F3F3\u200D\u26A7"))
  )
  # neither carries U+FE0F, which is the whole reason they cannot be repaired
  expect_false(any(grepl("\uFE0F", undetected, fixed = TRUE)))
  # and each one's fully-qualified sibling is detected as a single glyph, so
  # the residual is confined to the spelling and never to the emoji itself
  expect_length(tidyEmoji:::emoji_glyph_list("\U0001F441\uFE0F\u200D\U0001F5E8\uFE0F")[[1]], 1L)
  expect_length(tidyEmoji:::emoji_glyph_list("\U0001F3F3\uFE0F\u200D\u26A7\uFE0F")[[1]], 1L)
  for (g in undetected) {
    sibs <- ref$emoji[ref$key == tidyEmoji:::emoji_key(g)]
    expect_true(any(vapply(
      sibs,
      function(s) length(tidyEmoji:::emoji_glyph_list(s)[[1]]) == 1L,
      logical(1)
    )), info = g)
  }
})

test_that("real corpus text leaves no joiner orphaned", {
  # the residual below is confined to non-canonical spellings; this pins that
  # it does not reach text people actually write
  skip_if_not_installed("readr")
  path <- testthat::test_path("..", "..", "vignettes", "ata_tweets.csv")
  skip_if_not(file.exists(path), "vignette corpus not available")
  txt <- readr::read_csv(path, show_col_types = FALSE)$full_text
  expect_gt(sum(grepl("\u200D", txt, fixed = TRUE)), 0L)
  expect_equal(sum(orphaned_joiners(txt) > 0L), 0L)
  # and every glyph the corpus yields resolves to a known emoji
  glyphs <- unique(unlist(tidyEmoji:::emoji_glyph_list(txt), use.names = FALSE))
  expect_false(anyNA(as_emoji_name(glyphs)))
})

test_that("a lone match grows over the joiners the merge rules cannot reach", {
  # a sequence whose only detectable component is one of its parts yields one
  # match, so there is no pair to merge and it used to arrive as that part
  Z <- "\u200D"
  gl <- tidyEmoji:::emoji_glyph_list
  expect_equal(as_emoji_name(gl(paste0("\u2764", Z, "\U0001F525"))[[1]]),
               "heart on fire")
  expect_equal(as_emoji_name(gl(paste0("\U0001F9D4", Z, "\u2642"))[[1]]),
               "man: beard")
  expect_equal(as_emoji_name(gl(paste0("\U0001F636", Z, "\U0001F32B"))[[1]]),
               "face in clouds")
  # Exactly two spellings in the whole catalogue still lose a joiner, and they
  # are the same two that go undetected above -- both have no detectable
  # component, so there is nothing to grow from. Named rather than counted, for
  # the same reason: `<= 2` would accept a regression from 0.
  ref <- tidyEmoji:::emoji_reference()
  zwj <- ref$emoji[grepl(Z, ref$emoji, fixed = TRUE)]
  losing <- zwj[orphaned_joiners(zwj) > 0L]
  expect_identical(
    sort(losing),
    sort(c("\U0001F441\u200D\U0001F5E8", "\U0001F3F3\u200D\u26A7"))
  )
  # the set that loses a joiner is exactly the set that goes undetected
  expect_identical(
    sort(losing),
    sort(zwj[lengths(tidyEmoji:::emoji_glyph_list(zwj)) == 0L])
  )
})

test_that("growing a lone match never swallows a neighbour", {
  Z <- "\u200D"
  gl <- tidyEmoji:::emoji_glyph_list
  # the laugh must not be absorbed into the heart-on-fire beside it
  found <- gl(paste0(laugh, "\u2764", Z, "\U0001F525"))[[1]]
  expect_length(found, 2L)
  expect_equal(found[1], laugh)
  expect_equal(as_emoji_name(found[2]), "heart on fire")
  # and a joiner attached to ordinary text merges nothing
  expect_length(gl(paste0(laugh, Z, "x"))[[1]], 1L)
  expect_length(gl(paste0("x", Z, laugh))[[1]], 1L)
  expect_length(gl(paste0(laugh, Z, "x", Z, rage))[[1]], 2L)
})

test_that("a bare gender sign no longer splits the sequence around it", {
  # U+1F6B6 U+200D U+2640 U+200D U+27A1 U+FE0F -- U+2640 is undetected, so the
  # gap was ZWJ + sign + ZWJ and the old rule declined to merge. The row came
  # back as two emoji, "person walking" and "right arrow", neither of which is
  # what the text says
  walking <- "\U0001F6B6\u200D\u2640\uFE0F\u200D\u27A1\uFE0F"
  df <- data.frame(text = paste("she went", walking))
  expect_equal(emoji_position(df, text)$.emoji_n, 1L)
  freq <- emoji_frequency(df, text)
  expect_equal(nrow(freq), 1L)
  expect_equal(freq$emoji, walking)
  expect_equal(freq$name, "woman walking facing right")
})

test_that("the widened rule does not merge things that are not one emoji", {
  gl <- tidyEmoji:::emoji_glyph_list
  Z <- "\u200D"
  # rule 1 still covers sequences the catalogue has never heard of
  expect_length(gl(paste0("\U0001F600", Z, "\U0001F600"))[[1]], 1L)
  # and nothing else merges
  expect_length(gl(paste0(laugh, " ", rage))[[1]], 2L)
  expect_length(gl(paste0(laugh, Z, "x", Z, rage))[[1]], 2L)
  expect_length(gl(paste0(laugh, rage))[[1]], 2L)
  expect_length(gl(paste0(laugh, "-", rage))[[1]], 2L)
  # plain text is untouched
  expect_length(gl("no emoji here")[[1]], 0L)
})


# ---------------------------------------------------------------------------
# emoji_dfm() names one column per emoji glyph, so a doc_id column named with
# one of those glyphs was overwritten by the count column and the document
# identifiers vanished without a word.
# ---------------------------------------------------------------------------

test_that("a doc_id column named as an emoji is refused, not overwritten", {
  d <- stats::setNames(
    data.frame(c("x", "y"), c(laugh, rage), stringsAsFactors = FALSE),
    c(laugh, "text")
  )
  expect_error(emoji_dfm(d, text, doc_id = !!rlang::sym(laugh)),
               "also an emoji in the corpus")
  # no collision when that glyph is not in the corpus
  d2 <- stats::setNames(
    data.frame(c("x", "y"), c("plain", "words"), stringsAsFactors = FALSE),
    c(laugh, "text")
  )
  expect_equal(names(emoji_dfm(d2, text, doc_id = !!rlang::sym(laugh))), laugh)
})


# ---------------------------------------------------------------------------
# as.Date() on a POSIXct converts in UTC whatever the object's `tzone` says,
# so a late-evening timestamp in a western zone was bucketed into the next
# calendar day -- and disagreed with emoji_seasonality(period = "hour"), which
# reads format(x, "%H") and had always used the object's own zone.
# ---------------------------------------------------------------------------

test_that("a date-time is bucketed by its own timezone, not by UTC", {
  when <- as.POSIXct(c("2020-01-01 23:30", "2020-01-01 05:00",
                       "2020-03-15 22:00"),
                     tz = "America/New_York")
  df <- data.frame(text = rep(laugh, 3), when = when)
  expect_equal(format(emoji_trend(df, text, when, by = "day")$.period),
               c("2020-01-01", "2020-03-15"))
  expect_equal(format(emoji_trend(df, text, when, by = "month")$.period),
               c("2020-01-01", "2020-03-01"))
  # the same rows, read as hours, must agree with the day they were put in
  se <- emoji_seasonality(df, text, when, period = "hour")
  expect_equal(se$.period_label[se$n_emoji > 0], c("05", "22", "23"))
})

test_that("the day/hour views of one timestamp cannot disagree", {
  # 23:30 local: hour 23 of the local day, never hour 23 of the day before
  when <- as.POSIXct("2020-06-30 23:30", tz = "America/New_York")
  df <- data.frame(text = laugh, when = when)
  day <- format(emoji_trend(df, text, when, by = "day")$.period)
  se <- emoji_seasonality(df, text, when, period = "hour")
  expect_equal(day, "2020-06-30")
  expect_equal(se$.period_label[se$n_emoji > 0], "23")
  mn <- emoji_seasonality(df, text, when, period = "month")
  expect_equal(mn$.period_label[mn$n_emoji > 0], "Jun")
})

test_that("the timezone fix left the degenerate cases alone", {
  as_date <- tidyEmoji:::.emoji_as_date
  expect_true(is.na(as_date(as.POSIXct(NA))))
  expect_length(as_date(as.POSIXct(character(0))), 0L)
  expect_s3_class(as_date(as.POSIXct(character(0))), "Date")
  expect_equal(
    format(as_date(as.POSIXct(c("2020-01-01 23:30", NA),
                              tz = "America/New_York"))),
    c("2020-01-01", NA)
  )
  # a Date column passes through untouched, and POSIXlt works too
  expect_identical(as_date(as.Date("2020-01-01")), as.Date("2020-01-01"))
  expect_equal(format(as_date(as.POSIXlt("2020-01-01 23:30",
                                         tz = "America/New_York"))),
               "2020-01-01")
})

test_that("the session timezone does not change any time verb's answer", {
  when <- as.POSIXct(c("2020-01-01 23:30", "2020-06-15 02:15"), tz = "UTC")
  df <- data.frame(text = c(laugh, rage), when = when)
  snapshot <- function() {
    list(day = format(emoji_trend(df, text, when, by = "day")$.period),
         month = format(emoji_trend(df, text, when, by = "month")$.period),
         hour = emoji_seasonality(df, text, when, period = "hour")$n_emoji,
         wday = emoji_seasonality(df, text, when, period = "weekday")$n_emoji,
         lag = format(emoji_adoption_lag(df, text, when)$first_seen))
  }
  old <- Sys.getenv("TZ", unset = NA)
  on.exit({
    if (is.na(old)) Sys.unsetenv("TZ") else Sys.setenv(TZ = old)
  }, add = TRUE)
  Sys.setenv(TZ = "UTC")
  baseline <- snapshot()
  for (tz in c("America/New_York", "Asia/Tokyo")) {
    Sys.setenv(TZ = tz)
    expect_identical(snapshot(), baseline)
  }
})
