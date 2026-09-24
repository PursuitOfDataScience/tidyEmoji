# Regression tests for the 0.5.0 correctness release.
#
# Every test here runs. They pin behaviour the pre-release audit suspected was
# wrong and measurement found was right: a suspicion that has been checked and
# not written down gets re-raised by the next audit, at the same cost as the
# first one.
#
# Acceptance criteria for verbs that do not exist yet live in
# test-acceptance-pending.R, not here. A file named for a released version
# should describe that version, and a test that skips with "0.5.0 will add
# this" in the release that *is* 0.5.0 says the opposite of what it means.

smile  <- intToUtf8(0x1F600)
laugh  <- intToUtf8(0x1F602)
us     <- intToUtf8(c(0x1F1FA, 0x1F1F8))
jp     <- intToUtf8(c(0x1F1EF, 0x1F1F5))

grouped_fixture <- function() {
  dplyr::group_by(
    tibble::tibble(
      grp  = c("a", "a", "b", "b"),
      # two emoji in one row of each group, so the n-gram comparison below has
      # something to compare in both: with one emoji per row there are no
      # n-grams at all and the test would pass on an empty tibble.
      text = c(paste("x", smile, laugh), paste("y", laugh),
               paste("p", us, smile), paste("q", jp))
    ),
    grp
  )
}


# ---------------------------------------------------------------------------
# The pre-release audit named three aggregators as pooling grouped data
# silently. The count was wrong three times over: 0.4.0 guarded
# emoji_version_profile(), and the other two were never aggregators at all.
# Measured 2026-09-17, so the next audit does not have to re-derive it.
# ---------------------------------------------------------------------------

test_that("emoji_categorize() carries a grouping through instead of pooling it", {
  g <- grouped_fixture()
  out <- emoji_categorize(g, text)
  expect_true(dplyr::is_grouped_df(out))
  expect_equal(dplyr::group_vars(out), "grp")
  # The verb answers per row, so a grouping cannot change what it returns.
  # That is why silence is right here and a warning would not be.
  expect_equal(as.data.frame(out),
               as.data.frame(emoji_categorize(dplyr::ungroup(g), text)))
  # Every row of `g` carries an emoji, so it cannot show what happens to one
  # that does not. `@return` says the result is "filtered to the rows
  # containing at least one emoji", and a NEWS entry described the verb as
  # "row-preserving" instead; pin the fact so the two cannot disagree again.
  # Dropping rows is still not pooling: it cannot merge two groups.
  expect_identical(nrow(out), nrow(g))
  mixed <- dplyr::group_by(
    tibble::tibble(grp = c("a", "a", "b", "b"),
                   text = c(paste("x", smile), "no emoji at all",
                            paste("p", laugh), "none here either")),
    grp)
  dropped <- emoji_categorize(mixed, text)
  expect_identical(nrow(dropped), 2L)
  expect_true(dplyr::is_grouped_df(dropped))
  # both groups survive, so no group was merged away or emptied silently
  expect_identical(sort(unique(dropped$grp)), c("a", "b"))
  expect_identical(nrow(dropped),
                   nrow(emoji_categorize(dplyr::ungroup(mixed), text)))
})

test_that("emoji_categorize() stays silent on grouped input", {
  expect_no_warning(emoji_categorize(grouped_fixture(), text))
})

test_that("emoji_ngrams() has no grouping to ignore", {
  g <- grouped_fixture()
  out <- emoji_ngrams(g, text)
  # One row per n-gram occurrence, keyed by .row_number, carrying none of the
  # user's columns: there is nothing for a grouping to apply to.
  expect_false(dplyr::is_grouped_df(out))
  expect_named(out, c(".row_number", ".position", ".emoji_ngram"))
  # one n-gram from each group's two-emoji row, so this is not an empty
  # comparison
  expect_equal(nrow(out), 2L)
  expect_equal(sort(out$.row_number), c(1L, 3L))
  expect_equal(as.data.frame(out),
               as.data.frame(emoji_ngrams(dplyr::ungroup(g), text)))
})

test_that("emoji_ngrams() stays silent on grouped input", {
  expect_no_warning(emoji_ngrams(grouped_fixture(), text))
})


# ---------------------------------------------------------------------------
# The other half of the grapheme work. The fix itself shipped in 0.4.0; what
# was left owed was saying on the help page that positions are logical order,
# because a right-to-left corpus reads "final" the other way round.
# ---------------------------------------------------------------------------

test_that("?emoji_position states that positions are logical, not visual", {
  txt <- rd_text("emoji_position")
  skip_if(is.na(txt), "emoji_position help topic not available")
  # The whole phrase, not the two words apart: "logical" and "visual" each
  # appear elsewhere in R documentation prose often enough that matching them
  # separately would pass on a page that had lost the sentence.
  expect_match(txt, "(storage) order", fixed = TRUE)
  expect_match(txt, "not visual order", fixed = TRUE)
})


# ---------------------------------------------------------------------------
# The shortcode round trip is faithful only when the text held no shortcode
# tokens of its own. text_to_emoji() cannot tell a token emoji_sanitize()
# wrote from one that was always there, so a Slack or GitHub export where
# people type `:thumbsup:` gains emoji it never contained. The behaviour is
# correct and unavoidable given the design; what was missing was any statement
# of it, in a help page that enumerates every other way the round trip can
# fail. Pinned from both sides: the inflation, and the sentence.
# ---------------------------------------------------------------------------

test_that("a pre-existing shortcode token inflates the count by one, once", {
  d <- tibble::tibble(text = c("nice work :thumbsup:",
                               paste("nice work :thumbsup:", smile)))
  before <- emoji_density(d, text)$.emoji_n
  back <- text_to_emoji(emoji_sanitize(d, text, policy = "shortcode"), text)
  after <- emoji_density(back, text)$.emoji_n
  expect_equal(before, c(0L, 1L))
  expect_equal(after, c(1L, 2L))
  # bounded at one pass: by now the token is a glyph, so nothing else changes
  again <- text_to_emoji(emoji_sanitize(back, text, policy = "shortcode"), text)
  expect_identical(again$text, back$text)
})

test_that("colons that are not shortcode-shaped survive the round trip", {
  d <- tibble::tibble(text = c("meet at 10:30", "ratio 3:4", "http://x.org/a"))
  back <- text_to_emoji(emoji_sanitize(d, text, policy = "shortcode"), text)
  expect_identical(back$text, d$text)
  expect_equal(emoji_density(back, text)$.emoji_n, c(0L, 0L, 0L))
})

test_that("?emoji_sanitize states the assumption about the input text", {
  txt <- rd_flat("emoji_sanitize")
  skip_if(is.na(txt), "emoji_sanitize help topic not available")
  expect_match(txt, "cannot tell a", fixed = TRUE)
  expect_match(txt, "token this verb wrote from one the text already", fixed = TRUE)
})

test_that("?text_to_emoji states the same limitation from its own side", {
  txt <- rd_flat("text_to_emoji")
  skip_if(is.na(txt), "text_to_emoji help topic not available")
  expect_match(txt, "The converse is a limitation, not a feature", fixed = TRUE)
})


# ---------------------------------------------------------------------------
# Whitespace tokenisation and scriptio continua. 0.5.0 fixed the character
# class that dropped non-Latin context words, which makes a CJK corpus a
# supported input; what it does not do is segment one. A Chinese clause has no
# whitespace, so it arrives as one token and emoji_collocations() finds nothing
# at all. Correct, silent, and now stated on both help pages.
# ---------------------------------------------------------------------------

test_that("an unsegmented script yields one token per clause", {
  zh <- tibble::tibble(text = c(
    paste0(intToUtf8(c(0x4ECA, 0x5929, 0x5929, 0x6C14, 0x5F88, 0x597D)), smile),
    paste0(intToUtf8(c(0x4ECA, 0x5929, 0x5FC3, 0x60C5, 0x5F88, 0x597D)), smile),
    paste0(intToUtf8(c(0x660E, 0x5929, 0x53BB, 0x5317, 0x4EAC)), smile)))
  en <- tibble::tibble(text = c(
    paste("the weather is good today", smile),
    paste("my mood is good today", smile),
    paste("going to beijing tomorrow", smile)))
  cz <- emoji_collocations(zh, text, min_n = 1)
  ce <- emoji_collocations(en, text, min_n = 1)
  # every Chinese "word" is a whole clause, so every type occurs exactly once
  expect_equal(nrow(cz), 3L)
  expect_true(all(cz$n == 1L))
  # the same three sentences in English do produce repeated collocates
  expect_true(any(ce$n > 1L))
  # so the default min_n cannot clear anything on the Chinese corpus
  expect_equal(nrow(emoji_collocations(zh, text)), 0L)
  # unit = "char" is the documented way round it
  ctx <- emoji_context(zh, text, window = 3, unit = "char")
  expect_equal(nrow(ctx), 3L)
  expect_true(all(nzchar(ctx$.emoji_context_left)))
})

test_that("both help pages state the scriptio continua consequence", {
  cx <- rd_flat("emoji_context")
  skip_if(is.na(cx), "emoji_context help topic not available")
  expect_match(cx, "does not put spaces between", fixed = TRUE)
  cl <- rd_flat("emoji_collocations")
  skip_if(is.na(cl), "emoji_collocations help topic not available")
  expect_match(cl, "cannot find a collocation at all", fixed = TRUE)
})


# ---------------------------------------------------------------------------
# The 2026-09-23 source-reading sweep. Each block pins a defect found by
# reading the code and confirmed by running it, on a fixture where the old
# behaviour and the fixed one give different answers.
# ---------------------------------------------------------------------------

grin      <- intToUtf8(0x1F600)
rage      <- intToUtf8(0x1F621)
fearful   <- intToUtf8(0x1F628)
heart_q   <- intToUtf8(c(0x2764, 0xFE0F))
heart_b   <- intToUtf8(0x2764)

test_that("emoji_score() refuses a `score` that is not a single string", {
  df <- data.frame(text = paste("great", grin))
  lex <- data.frame(emoji = grin, score = 0.9)
  # a length-2 value used to reach `%in%` and fail as R's "the condition has
  # length > 1", naming neither the argument nor the verb
  for (bad in list(c("score", "x"), 1, NA, NA_character_, character(0))) {
    expect_error(emoji_score(df, text, lexicon = lex, score = bad),
                 "`score` must be a single string", fixed = TRUE)
  }
  expect_equal(emoji_score(df, text, lexicon = lex,
                           score = "score")$.emoji_score, 0.9)
})

test_that("a registered lexicon is read through the column it was registered with", {
  local_clean_registry()
  df <- data.frame(text = c(paste("great", grin), paste("bad", rage), "none"))
  # `emoji` is a label here and `glyph` the glyph column. The verbs used to
  # key the table on their own `by` ("emoji"), so every score came back NA.
  reg <- data.frame(glyph = c(grin, rage), emoji = c("grinning", "enraged"),
                    score = c(0.9, -0.8), joy = c(0.9, 0.1))
  register_emoji_lexicon("by_glyph", reg, by = "glyph")
  expect_equal(emoji_score(df, text, lexicon = "by_glyph")$.emoji_score,
               c(0.9, -0.8, NA))
  expect_equal(emoji_sentiment(df, text, lexicon = "by_glyph")$.emoji_sentiment,
               c(0.9, -0.8, NA))
  expect_equal(emoji_emotion(df, text, lexicon = "by_glyph")$.emoji_joy,
               c(0.9, 0.1, NA))
  # ?emoji_score: `by` is ignored for a registered lexicon, `score` is not
  expect_identical(emoji_score(df, text, lexicon = "by_glyph", by = "emoji"),
                   emoji_score(df, text, lexicon = "by_glyph"))
  expect_equal(emoji_score(df, text, lexicon = "by_glyph",
                           score = "joy")$.emoji_score, c(0.9, 0.1, NA))
  rd <- rd_flat("emoji_score")
  expect_match(rd, "read through the column it was registered with",
               fixed = TRUE)
  expect_match(rd, "whose score is fixed", fixed = TRUE)
})

test_that("a lexicon keyed by its `key` column alone still resolves", {
  # Registered lexicons now resolve through their own glyph column, so the
  # `key` fallback is left serving the case it is documented for: a table
  # carrying only the code-point key, as ?register_emoji_lexicon returns it
  # and ?emoji_emotion_lexicon ships it.
  df <- data.frame(text = c(paste("great", grin), paste("bad", rage), "none"))
  k <- asNamespace("tidyEmoji")$emoji_key(c(grin, rage))
  expect_equal(emoji_score(df, text,
                           lexicon = data.frame(key = k, score = c(0.9, -0.8))
                           )$.emoji_score, c(0.9, -0.8, NA))
  expect_equal(emoji_emotion(df, text,
                             lexicon = data.frame(key = k, joy = c(0.7, 0.1))
                             )$.emoji_joy, c(0.7, 0.1, NA))
})

test_that("two agreeing rows for one key score alike whichever comes first", {
  # The duplicate-key check ignores NA, since an NA is no score and cannot
  # contradict one, but the lookup read the first row of the key: the
  # qualified heart scored 0.5 or nothing depending on the row order.
  df <- data.frame(text = paste("love", heart_q))
  s1 <- data.frame(emoji = c(heart_b, heart_q), score = c(NA, 0.5))
  s2 <- s1[2:1, ]
  expect_equal(emoji_score(df, text, lexicon = s1)$.emoji_score, 0.5)
  expect_equal(emoji_score(df, text, lexicon = s2)$.emoji_score, 0.5)
  expect_identical(emoji_score(df, text, lexicon = s1)$.emoji_n_scored, 1L)
  expect_equal(emoji_sentiment(df, text, lexicon = s1)$.emoji_sentiment, 0.5)
  e1 <- data.frame(emoji = c(heart_b, heart_q), joy = c(NA, 0.5),
                   fear = c(0.2, NA))
  a <- emoji_emotion(df, text, lexicon = e1)
  b <- emoji_emotion(df, text, lexicon = e1[2:1, ])
  expect_identical(a, b)
  expect_equal(c(a$.emoji_joy, a$.emoji_fear), c(0.5, 0.2))
  # a real disagreement is still refused, on both paths
  expect_error(
    emoji_score(df, text, lexicon = data.frame(emoji = c(heart_b, heart_q),
                                               score = c(0.1, 0.5))),
    "more than one score", fixed = TRUE)
  expect_error(
    emoji_emotion(df, text, lexicon = data.frame(emoji = c(heart_b, heart_q),
                                                 joy = c(0.1, 0.5))),
    "more than one score", fixed = TRUE)
})

test_that("emoji_emotion() does not count an emoji it has no usable score for", {
  df <- data.frame(text = c(paste("a", grin), paste("b", rage), "none"))
  out <- emoji_emotion(df, text,
                       lexicon = data.frame(emoji = c(grin, rage),
                                            joy = c(NA, 0.3)))
  expect_identical(out$.emoji_n_scored, c(0L, 1L, NA_integer_))
  expect_equal(out$.emoji_joy, c(NA, 0.3, NA))
  # An infinite value is dropped with a warning saying the emoji carrying it
  # counts as unscored; the emotion path used to count it as scored anyway,
  # where emoji_score() on the same shape of table did not.
  expect_warning(
    o2 <- emoji_emotion(df, text,
                        lexicon = data.frame(emoji = c(grin, rage),
                                             joy = c(Inf, 0.3))),
    "not finite")
  expect_warning(
    o3 <- emoji_score(df, text,
                      lexicon = data.frame(emoji = c(grin, rage),
                                           score = c(Inf, 0.3))),
    "not finite")
  expect_identical(o2$.emoji_n_scored, c(0L, 1L, NA_integer_))
  expect_identical(o2$.emoji_n_scored, o3$.emoji_n_scored)
  # an emoji scored on any one dimension still counts
  part <- data.frame(emoji = c(grin, rage), joy = c(NA, 0.3),
                     fear = c(0.4, NA))
  expect_identical(emoji_emotion(df, text, lexicon = part)$.emoji_n_scored,
                   c(1L, 1L, NA_integer_))
})

test_that("emoji_emotion_label() labels from what it scored, not from stale columns", {
  df <- data.frame(text = paste("scary", fearful))
  full <- emoji_emotion(df, text)
  expect_gt(full$.emoji_fear, full$.emoji_joy)
  sub <- data.frame(emoji = fearful, joy = 0.01)
  expect_identical(emoji_emotion_label(df, text, lexicon = sub)$.emoji_emotion,
                   "joy")
  # Text still carrying the bundled profile gets the same label: the
  # `.emoji_fear` it arrived with was not computed by this call and used to
  # win. The caller's column itself is kept, as the label is only added.
  lab <- emoji_emotion_label(full, text, lexicon = sub)
  expect_identical(lab$.emoji_emotion, "joy")
  expect_equal(lab$.emoji_fear, full$.emoji_fear)
})

test_that("emoji_incongruity_profile() credits only the glyphs a row was scored on", {
  laugh <- intToUtf8(0x1F602)
  df <- data.frame(text = c(paste(rage, "great day", laugh),
                            paste(rage, "lovely", laugh),
                            paste("awful", rage)),
                   score = c(0.8, 0.7, -0.9))
  fin <- emoji_incongruity_profile(df, text, score, scale = "none",
                                   where = "final", min_n = 0)
  all <- emoji_incongruity_profile(df, text, score, scale = "none",
                                   where = "all", min_n = 0)
  # U+1F621 ends only the third row; the first two were scored on U+1F602
  # alone, and the profile used to give it their gaps and count them in `n`
  expect_identical(fin$n[fin$emoji == rage], 1L)
  expect_identical(fin$n[fin$emoji == laugh], 2L)
  expect_identical(all$n[all$emoji == rage], 3L)
  expect_false(identical(fin$n[fin$emoji == rage], all$n[all$emoji == rage]))
  # `n` adds up to the occurrences each call actually scored
  row_fin <- emoji_incongruity(df, text, score, scale = "none",
                               where = "final")
  final_n <- lengths(asNamespace("tidyEmoji")$.emoji_final_glyphs(df$text))
  expect_identical(sum(fin$n),
                   sum(final_n[!is.na(row_fin$.emoji_incongruity)]))
  row_all <- emoji_incongruity(df, text, score, scale = "none")
  expect_identical(sum(all$n),
                   sum(row_all$.emoji_n[!is.na(row_all$.emoji_incongruity)]))
})

test_that("a count past integer range means 'all of it' rather than a crash", {
  # One row with a single emoji (the substring path) and one with two (the
  # indexed path), since the two overflowed in different places.
  df <- data.frame(text = c(paste("a b c", grin, "d e"),
                            paste("a b c", grin, "d", rage, "e")))
  ng <- NULL
  expect_no_warning(ng <- emoji_ngrams(df, text, n = 1e10))
  expect_identical(nrow(ng), 0L)
  for (u in c("word", "char")) {
    ref <- emoji_context(df, text, window = 100, unit = u)
    for (w in c(1e9, .Machine$integer.max, 1e12)) {
      got <- NULL
      expect_no_warning(got <- emoji_context(df, text, window = w, unit = u))
      expect_identical(got, ref, info = paste(u, w))
    }
  }
  expect_no_warning(emoji_collocations(df, text, window = 1e10, min_n = 1))
})

test_that("strip trims the package's own whitespace off the ends", {
  ideo <- intToUtf8(0x3000)
  nbsp <- intToUtf8(0x00A0)
  df <- data.frame(text = c(paste0("hello ", grin, ideo),
                            paste0(nbsp, grin, " hi"),
                            paste0("a ", grin, "\n")))
  expect_identical(emoji_sanitize(df, text, policy = "strip")$text,
                   c("hello", "hi", "a"))
  # only the rows a glyph was removed from are tidied
  plain <- data.frame(text = paste0(nbsp, "plain", ideo))
  expect_identical(emoji_sanitize(plain, text, policy = "strip")$text,
                   plain$text)
})

test_that("emoji_lexicons() lists only the columns a lexicon can be scored on", {
  local_clean_registry()
  register_emoji_lexicon("with_note",
                         data.frame(emoji = grin, score = 1, weight = 2L,
                                    note = "x"))
  lx <- emoji_lexicons()
  dims <- lx$dimensions[[which(lx$name == "with_note")]]
  expect_identical(dims, c("score", "weight"))
  df <- data.frame(text = grin)
  for (d in dims) {
    expect_equal(emoji_score(df, text, lexicon = "with_note",
                             score = d)$.emoji_n_scored, 1L, info = d)
  }
  # the column left out is the one `score =` refuses
  expect_error(emoji_score(df, text, lexicon = "with_note", score = "note"),
               "a score has to be a number", fixed = TRUE)
})

test_that("?emoji_trend keeps the `share` paragraph out of the list above it", {
  # roxygen's markdown folds an unindented line straight after a list item
  # into that item, so the paragraph defining `share` rendered as part of the
  # emoji_seasonality() bullet
  rd <- tools::Rd_db("tidyEmoji")[["emoji_trend.Rd"]]
  tag <- function(x) {
    a <- attr(x, "Rd_tag")
    if (is.null(a)) "" else a
  }
  details <- rd[[which(vapply(rd, tag, character(1)) == "\\details")]]
  dt <- vapply(details, tag, character(1))
  flat <- function(x) paste(unlist(x), collapse = "")
  expect_identical(sum(dt == "\\itemize"), 1L)
  expect_false(grepl("divided by all emoji tokens",
                     flat(details[dt == "\\itemize"]), fixed = TRUE))
  expect_true(grepl("divided by all emoji tokens",
                    flat(details[dt != "\\itemize"]), fixed = TRUE))
})

test_that("no roxygen list item swallows the paragraph after it", {
  # Decide by the .R files found, not by the directory: under covr the tests
  # run from a copy where ../../R exists and holds the lazy-load database, so
  # a directory check passed and the scan then had nothing to read.
  src <- testthat::test_path("..", "..", "R")
  files <- list.files(src, pattern = "[.]R$", full.names = TRUE)
  skip_if(!length(files), "roxygen sources not available")
  expect_gt(length(files), 10L)
  item <- "^#' (\\* |- |[0-9]+\\. )"
  offenders <- character(0)
  for (f in files) {
    l <- readLines(f, warn = FALSE)
    in_item <- FALSE
    for (i in seq_along(l)) {
      if (!startsWith(l[i], "#'")) {
        in_item <- FALSE
        next
      }
      body <- substring(l[i], 3L)
      if (grepl(item, l[i])) {
        in_item <- TRUE
        next
      }
      if (!in_item) next
      if (!nzchar(trimws(body)) || grepl("^ *@", body)) {
        in_item <- FALSE
        next
      }
      # an indented line continues the item, as roxygen intends
      if (startsWith(body, "  ")) next
      offenders <- c(offenders, sprintf("%s:%d", basename(f), i))
      in_item <- FALSE
    }
  }
  expect_identical(offenders, character(0))
})

test_that("?emoji_unicode_releases names the sub-1.0 emoji versions it carries", {
  rel <- emoji_unicode_releases()
  early <- rel$version[rel$series == "emoji" & rel$version_num < 1]
  expect_identical(early, c("0.6", "0.7"))
  expect_match(rd_flat("emoji_unicode_releases"),
               "It also carries 0.6 and 0.7", fixed = TRUE)
})

test_that("the catalogue labels glyphs with the sub-1.0 emoji versions", {
  # why ?emoji_unicode_releases has to name them: they are in use, and every
  # label the catalogue carries has a release date to join to
  ns <- asNamespace("tidyEmoji")
  labs <- unique(ns$.emoji_version_label(ns$emoji_reference()$version))
  expect_true(all(c("0.6", "0.7") %in% labs))
  expect_true(all(stats::na.omit(labs) %in% emoji_unicode_releases()$version))
})

test_that("the CITATION header names every export that reads a bundled lexicon", {
  ns <- asNamespace("tidyEmoji")
  fns <- ls(ns, all.names = TRUE)
  fns <- fns[vapply(fns, function(n) is.function(get(n, envir = ns)),
                    logical(1))]
  calls <- lapply(stats::setNames(fns, fns), function(n) {
    intersect(all.names(body(get(n, envir = ns))), fns)
  })
  reaches <- function(from, target) {
    seen <- character(0)
    todo <- from
    while (length(todo)) {
      cur <- todo[1L]
      todo <- todo[-1L]
      if (cur %in% seen) next
      seen <- c(seen, cur)
      todo <- c(todo, calls[[cur]])
    }
    any(target %in% seen)
  }
  ex <- sort(getNamespaceExports("tidyEmoji"))
  sent <- ex[vapply(ex, reaches, logical(1),
                    target = c("emoji_sentiment_map", "emoji_ambiguity_table"))]
  emo <- ex[vapply(ex, reaches, logical(1), target = "emoji_emotion_map")]
  # pinned, so an empty call graph cannot pass the loops below
  expect_setequal(sent, c("emoji_ambiguity", "emoji_congruence",
                          "emoji_flag_ambiguous", "emoji_incongruity",
                          "emoji_incongruity_profile", "emoji_risk",
                          "emoji_score", "emoji_sentiment", "emoji_tokens"))
  expect_setequal(emo, c("emoji_emotion", "emoji_emotion_label",
                         "emoji_score"))
  hdr <- paste(attr(utils::citation("tidyEmoji"), "mheader"), collapse = " ")
  hdr <- gsub("[[:space:]]+", " ", hdr)
  s_part <- sub(
    ".*(If your analysis used the bundled sentiment.*?)If it used.*",
    "\\1", hdr, perl = TRUE)
  e_part <- sub(".*(If it used the bundled emotion.*)$", "\\1", hdr,
                perl = TRUE)
  expect_false(identical(s_part, e_part))
  for (f in sent) {
    expect_true(grepl(paste0(f, "("), s_part, fixed = TRUE), info = f)
  }
  for (f in emo) {
    expect_true(grepl(paste0(f, "("), e_part, fixed = TRUE), info = f)
  }
})

test_that("glyph-ordered results ignore options(dplyr.legacy_locale)", {
  # arrange() sorts in the C locale unless this global option says otherwise,
  # and every verb documenting a C-locale order sorted through arrange().
  old_coll <- Sys.getlocale("LC_COLLATE")
  on.exit(suppressWarnings(Sys.setlocale("LC_COLLATE", old_coll)), add = TRUE)
  ok <- suppressWarnings(Sys.setlocale("LC_COLLATE", "en_US.UTF-8"))
  skip_if(!nzchar(ok), "en_US.UTF-8 collation not available")
  old_opt <- options(dplyr.legacy_locale = NULL)
  on.exit(options(old_opt), add = TRUE)

  us <- intToUtf8(c(0x1F1FA, 0x1F1F8))
  elan <- intToUtf8(c(0xE9, 0x6C, 0x61, 0x6E))
  df <- data.frame(text = c(paste(elan, heart_q, us),
                            paste("fable", heart_q, us)))
  run <- function() {
    list(emoji_frequency(df, text), emoji_pairs(df, text, sort = FALSE),
         emoji_collocations(df, text, min_n = 1),
         emoji_extract_unnest(df, text))
  }
  in_c <- run()
  options(dplyr.legacy_locale = TRUE)
  # the fixture is one on which the option really moves arrange(): the flag
  # and the accented word sort first under en_US and last under C
  legacy_order <- suppressWarnings(
    dplyr::arrange(tibble::tibble(x = c(heart_q, us, "fable", elan)), x)$x)
  skip_if(identical(legacy_order, sort(c(heart_q, us, "fable", elan),
                                       method = "radix")),
          "this platform's en_US collation agrees with C on the fixture")
  expect_identical(suppressWarnings(run()), in_c)
  expect_identical(in_c[[1]]$emoji, sort(c(heart_q, us), method = "radix"))
})
