# Cross-verb invariants.
#
# Every check here relates two or more verbs on one fixture, so it fails when
# the shared engine drifts even if each verb's own tests still pass. That is
# the gap the per-verb files leave: they each pin one function's output, and
# none of them notices when emoji_frequency() and emoji_tokens() start
# disagreeing about how many emoji a corpus holds.
#
# The fixture is written out rather than sampled: sample() changed its
# algorithm in R 3.6.0 and the package supports R >= 3.5.0, so an RNG-built
# fixture would not be the same corpus everywhere.

laugh  <- "\U0001F602"
heart_eyes <- "\U0001F60D"
party  <- "\U0001F389"
tone   <- "\U0001F44D\U0001F3FD"                    # thumbs up + skin tone
flag   <- "\U0001F1FA\U0001F1F8"                    # regional indicator pair
family <- "\U0001F468\u200D\U0001F469\u200D\U0001F467\u200D\U0001F466"
qheart <- "\u2764\uFE0F"                            # qualified heart
keycap <- "1\uFE0F\u20E3"                           # keycap digit one
poop   <- "\U0001F4A9"
new    <- "\U0001F97A"                              # pleading face (11.0)

fixture <- function() {
  data.frame(
    id = 1:24,
    text = c(
      "no emoji at all",
      "",
      NA,
      "   ",
      laugh,
      paste0(laugh, laugh),
      paste("great", laugh),
      paste(laugh, "great"),
      paste("mid", laugh, "text"),
      paste0(heart_eyes, party),
      paste("hello", tone),
      paste("flag", flag),
      paste("our", family),
      paste("love", qheart),
      paste("first", keycap),
      paste0(laugh, " ", family, " ", flag),
      paste("plain words only here"),
      paste0(poop, new),
      paste("mixed", laugh, "and", tone, "and", party),
      paste0(family, family),
      paste("trailing spaces", laugh, "  "),
      paste0("  ", laugh, " leading"),
      paste(new, "is newer than", laugh),
      paste0(keycap, keycap, keycap)
    ),
    when = as.Date("2021-01-01") + c(0:11, 40:51),
    sc = seq(-1, 1, length.out = 24),
    stringsAsFactors = FALSE
  )
}

df <- fixture()
pos <- emoji_position(df, text)
total <- sum(pos$.emoji_n)

test_that("the fixture is the corpus these tests assume", {
  # if this changes, every count below has to be re-derived deliberately
  expect_equal(nrow(df), 24L)
  expect_equal(total, 30L)
  expect_equal(sum(pos$.emoji_n > 0), 19L)
})

test_that("every verb that reports .emoji_n reports the same .emoji_n", {
  expect_identical(emoji_density(df, text)$.emoji_n, pos$.emoji_n)
  expect_identical(emoji_sentiment(df, text)$.emoji_n, pos$.emoji_n)
  expect_identical(emoji_faceness(df, text)$.emoji_n, pos$.emoji_n)
  expect_identical(emoji_risk(df, text)$.emoji_n, pos$.emoji_n)
  expect_identical(emoji_token_cost(df, text)$.emoji_n, pos$.emoji_n)
  expect_identical(emoji_score(df, text)$.emoji_n, pos$.emoji_n)
  # .emoji_graphemes is the same count under another name
  tc <- emoji_token_cost(df, text)
  expect_identical(tc$.emoji_graphemes, tc$.emoji_n)
})

test_that("six independent paths agree on the corpus total", {
  expect_equal(nrow(emoji_tokens(df, text)), total)
  expect_equal(sum(emoji_extract_unnest(df, text)$.emoji_count), total)
  expect_equal(nrow(emoji_context(df, text)), total)
  expect_equal(sum(emoji_frequency(df, text)$n), total)
  expect_equal(sum(emoji_dfm(df, text)[, -1]), total)
  expect_equal(nrow(emoji_ngrams(df, text, n = 1)), total)
  expect_equal(sum(emoji_version_profile(df, text)$n_tokens), total)
  expect_equal(sum(emoji_trend(df, text, when, top_n = NULL)$n), total)
  expect_equal(sum(emoji_seasonality(df, text, when)$n_emoji), total)
})

test_that("the per-row counts nest correctly", {
  h <- pos$.emoji_n > 0
  expect_true(all(pos$.emoji_first[h] <= pos$.emoji_last[h]))
  expect_true(all(pos$.emoji_rel_position[h] >= 0 &
                    pos$.emoji_rel_position[h] <= 1))
  sen <- emoji_sentiment(df, text)
  expect_true(all(sen$.emoji_n_scored[h] <= sen$.emoji_n[h]))
  fac <- emoji_faceness(df, text)
  expect_true(all(fac$.emoji_n_face[h] <= fac$.emoji_n_typed[h]))
  expect_true(all(fac$.emoji_n_typed[h] <= fac$.emoji_n[h]))
  expect_true(all(fac$.emoji_faceness[h] >= 0 & fac$.emoji_faceness[h] <= 1))
  rsk <- emoji_risk(df, text)
  expect_true(all(rsk$.emoji_n_ambiguous[h] <= rsk$.emoji_n[h]))
  rat <- emoji_ratio(df, text)
  expect_true(all(rat$.emoji_ratio >= 0 & rat$.emoji_ratio <= 1, na.rm = TRUE))
  den <- emoji_density(df, text)
  expect_true(all(den$.emoji_per_char >= 0 & den$.emoji_per_char <= 1,
                  na.rm = TRUE))
})

test_that(".emoji_n_scored is NA exactly when the row has no emoji", {
  # the invariant the whole affect surface rests on: NA means "no emoji",
  # 0 means "emoji the lexicon cannot score"
  sen <- emoji_sentiment(df, text)
  expect_identical(is.na(sen$.emoji_n_scored), pos$.emoji_n == 0L)
  sc <- emoji_score(df, text)
  expect_identical(is.na(sc$.emoji_n_scored), pos$.emoji_n == 0L)
  em <- emoji_emotion(df, text)
  expect_identical(is.na(em$.emoji_n_scored), pos$.emoji_n == 0L)
})

test_that("the relational verbs agree with each other and with the dfm", {
  expect_identical(emoji_pairs(df, text), emoji_cooccurrence(df, text))
  cod <- emoji_cooccurrence(df, text, diagonal = TRUE)
  diag_rows <- cod[cod$item1 == cod$item2, ]
  binary <- emoji_dfm(df, text, weighting = "binary")
  docfreq <- colSums(binary[, -1, drop = FALSE])
  expect_gt(nrow(diag_rows), 0L)
  expect_equal(unname(diag_rows$n), unname(docfreq[diag_rows$item1]))
  # the dfm's columns are exactly the corpus's distinct emoji
  expect_setequal(names(emoji_dfm(df, text))[-1],
                  emoji_frequency(df, text)$emoji)
})

test_that("the aggregate shares are shares", {
  vp <- emoji_version_profile(df, text)
  expect_equal(sum(vp$share_tokens), 1)
  se <- emoji_seasonality(df, text, when)
  expect_equal(sum(se$share), 1)
  expect_equal(sum(se$n_texts), nrow(df))
})

test_that("detection agrees across the summarise / filter / categorise trio", {
  expect_equal(emoji_summary(df, text)$n_with_emoji,
               nrow(emoji_filter(df, text)))
  expect_equal(nrow(emoji_filter(df, text)), sum(pos$.emoji_n > 0))
  # categorize keeps exactly the emoji-bearing rows -- it used to keep only
  # the ones whose emoji it could also categorise
  cat_rows <- emoji_categorize(df, text)
  expect_equal(nrow(cat_rows), sum(pos$.emoji_n > 0))
  expect_false(anyNA(cat_rows$.emoji_category))
})

test_that("a multi-code-point emoji is one emoji everywhere", {
  # the fixture's family (7 code points) and flag (2) must count as one each.
  # which() rather than a logical index: the fixture has an NA text, and
  # df[NA, ] would silently add an all-NA row to the subset
  one_family <- df[which(df$text == paste("our", family)), , drop = FALSE]
  expect_equal(emoji_position(one_family, text)$.emoji_n, 1L)
  expect_equal(nrow(emoji_tokens(one_family, text)), 1L)
  expect_equal(sum(emoji_frequency(one_family, text)$n), 1L)
  expect_equal(emoji_token_cost(one_family, text)$.emoji_graphemes, 1L)
  # and it is at the end of its text, so rel_position is 1
  expect_equal(emoji_position(one_family, text)$.emoji_rel_position, 1)
})


# ---------------------------------------------------------------------------
# Everything positional derives from the spans the ZWJ repair produces, so a
# change to the repair can silently break offset arithmetic in five verbs at
# once. These pin the newly-merged sequences specifically: they are the longest
# glyphs the engine emits, and the ones the repair invented.
# ---------------------------------------------------------------------------

merged_cases <- function() {
  Z <- "\u200D"
  c(heart_on_fire = paste0("\u2764", Z, "\U0001F525"),
    man_beard     = paste0("\U0001F9D4", Z, "\u2642"),
    walking       = "\U0001F6B6\u200D\u2640\uFE0F\u200D\u27A1\uFE0F",
    family_zwj    = "\U0001F468\u200D\U0001F469\u200D\U0001F467\u200D\U0001F466")
}

test_that("a repaired span slices back to exactly its glyph", {
  for (g in merged_cases()) {
    s <- paste("a", g, "b")
    m <- tidyEmoji:::.emoji_locations(s)[[1]]
    expect_equal(nrow(m), 1L)
    expect_identical(substring(s, m[1, "start"], m[1, "end"]), g)
  }
})

test_that("emoji_context masking keeps offsets exact around a repaired glyph", {
  for (g in merged_cases()) {
    s <- paste("one two", g, "three four")
    ctx <- emoji_context(data.frame(text = s), text, window = 2)
    expect_equal(nrow(ctx), 1L)
    expect_identical(ctx$.emoji_context_left, "one two")
    expect_identical(ctx$.emoji_context_right, "three four")
    expect_identical(ctx$.emoji, g)
    expect_identical(substr(s, ctx$.position,
                            ctx$.position + nchar(g) - 1L), g)
  }
})

test_that("token_cost separates code points from graphemes on repaired glyphs", {
  gs <- merged_cases()
  d <- data.frame(text = paste("x", gs))
  tc <- emoji_token_cost(d, text)
  expect_identical(tc$.emoji_graphemes, rep(1L, length(gs)))
  expect_identical(tc$.emoji_codepoints,
                   vapply(gs, function(g) length(utf8ToInt(g)), integer(1),
                          USE.NAMES = FALSE))
  expect_true(all(tc$.emoji_codepoints >= tc$.emoji_graphemes))
})

test_that("a repaired glyph is one position, wherever it sits", {
  for (g in merged_cases()) {
    # sentence-final: rel = 1 whatever the glyph is built from
    p <- emoji_position(data.frame(text = paste("hi", g)), text)
    expect_equal(p$.emoji_n, 1L)
    expect_equal(p$.emoji_rel_position, 1)
    # leading, with text after it: rel = 0
    p2 <- emoji_position(data.frame(text = paste(g, "hi")), text)
    expect_equal(p2$.emoji_rel_position, 0)
    # and a row that is only the emoji is a single-unit text, documented as 0
    p3 <- emoji_position(data.frame(text = g), text)
    expect_equal(p3$.emoji_rel_position, 0)
  }
})

test_that("a repaired glyph survives strip and the shortcode round trip", {
  for (g in merged_cases()) {
    s <- paste("a", g, "b")
    expect_identical(
      emoji_sanitize(data.frame(text = s), text, policy = "strip")$text,
      "a b"
    )
    out <- emoji_sanitize(data.frame(text = s), text,
                          policy = "shortcode")$text
    back <- text_to_emoji(data.frame(text = out), text)$text
    recovered <- sub("^a ", "", sub(" b$", "", back))
    expect_identical(tidyEmoji:::emoji_key(recovered),
                     tidyEmoji:::emoji_key(g))
  }
})

test_that("a repaired glyph is one emoji to every counting verb", {
  gs <- merged_cases()
  d <- data.frame(text = paste("x", gs, "y"))
  expect_equal(emoji_position(d, text)$.emoji_n, rep(1L, length(gs)))
  expect_equal(nrow(emoji_tokens(d, text)), length(gs))
  expect_equal(nrow(emoji_context(d, text)), length(gs))
  expect_equal(sum(emoji_frequency(d, text)$n), length(gs))
  expect_equal(sum(emoji_dfm(d, text)[, -1]), length(gs))
  expect_equal(nrow(emoji_categorize(d, text)), length(gs))
  # and each resolves to a real name, not to a component
  expect_false(anyNA(emoji_frequency(d, text)$name))
})


# ---------------------------------------------------------------------------
# No user-visible ordering may depend on the session's collation. This has
# bitten twice (emoji_to_text()'s shortcode choice in 0.3.0, emoji_dfm(doc_id)'s
# row order in 0.4.0), so the guard is a test over every ordered output rather
# than a convention to remember.
# ---------------------------------------------------------------------------

test_that("no ordered output depends on LC_COLLATE", {
  A <- laugh
  B <- heart_eyes
  C <- party
  d <- data.frame(text = c(A, B, C))
  snapshot <- function() {
    list(
      search     = emoji_search("hand")$emoji,
      search_sc  = emoji_search("hand")$shortcode,
      topn       = top_n_emojis(d, text)$unicode,
      topn_dup   = top_n_emojis(d, text, duplicated = TRUE)$emoji_name,
      frequency  = emoji_frequency(d, text)$emoji,
      ambiguity  = head(emoji_ambiguity()$emoji, 30),
      flagged    = emoji_flag_ambiguous(d, text)$emoji,
      lexicons   = emoji_lexicons()$name,
      releases   = emoji_unicode_releases()$version,
      categories = emoji_categorize(d, text)$.emoji_category,
      pairs      = paste(emoji_pairs(d, text)$item1, emoji_pairs(d, text)$item2),
      dfm_cols   = names(emoji_dfm(d, text)),
      dfm_rows   = as.character(emoji_dfm(
        data.frame(author = c("zoe", "Adam", "ubu"), text = c(A, B, C)),
        text, doc_id = author)[[1]]),
      ngrams     = emoji_ngrams(data.frame(text = paste0(A, B, C)), text)$.emoji_ngram,
      shortcodes = emoji_to_text(d, text, format = "shortcode")$text,
      collocs    = emoji_collocations(
        data.frame(text = paste("good", c(A, B, C))), text, min_n = 1)$word
    )
  }
  old <- Sys.getlocale("LC_COLLATE")
  on.exit(suppressWarnings(Sys.setlocale("LC_COLLATE", old)), add = TRUE)
  baseline <- snapshot()
  tried <- 0L
  for (loc in c("C", "en_US.UTF-8")) {
    available <- tryCatch({
      suppressWarnings(Sys.setlocale("LC_COLLATE", loc))
      identical(Sys.getlocale("LC_COLLATE"), loc)
    }, error = function(e) FALSE)
    if (!available) next
    tried <- tried + 1L
    expect_identical(snapshot(), baseline)
  }
  skip_if(tried == 0L, "no alternative collation available")
})

test_that("tied counts break deterministically and not by input order", {
  forwards <- emoji_frequency(data.frame(text = c(laugh, heart_eyes, party)),
                              text)$emoji
  backwards <- emoji_frequency(data.frame(text = c(party, heart_eyes, laugh)),
                               text)$emoji
  expect_identical(forwards, backwards)
  expect_identical(forwards, emoji_frequency(
    data.frame(text = c(heart_eyes, party, laugh)), text)$emoji)
})


# ---------------------------------------------------------------------------
# Four verbs compute `.emoji_sentiment` / `.emoji_n_scored` from the same
# lexicon by four separate code paths. Nothing forces them to agree, so a
# change to one can silently make the package contradict itself -- which is
# how the timezone defect surfaced. Pin the agreement.
# ---------------------------------------------------------------------------

test_that("the four sentiment code paths agree exactly", {
  pleading <- "\U0001F97A"   # in no lexicon: exercises the 0 / NA distinction
  df <- data.frame(
    text = c(paste("great", laugh), paste0(laugh, heart_eyes), "plain", NA,
             paste("x", pleading)),
    sc = c(1, 0, -1, 0, 1)
  )
  a <- emoji_sentiment(df, text)
  b <- emoji_incongruity(df, text, sc, scale = "none", where = "all")
  d <- emoji_score(df, text, lexicon = "novak2015")
  r <- emoji_risk(df, text)
  expect_equal(b$.emoji_sentiment, a$.emoji_sentiment)
  expect_equal(d$.emoji_score, a$.emoji_sentiment)
  expect_identical(b$.emoji_n_scored, a$.emoji_n_scored)
  expect_identical(d$.emoji_n_scored, a$.emoji_n_scored)
  expect_identical(r$.emoji_n_scored, a$.emoji_n_scored)
  expect_identical(b$.emoji_n, a$.emoji_n)
  expect_identical(d$.emoji_n, a$.emoji_n)
  expect_identical(r$.emoji_n, a$.emoji_n)
  # emoji_tokens' per-glyph score is the lexicon value for that glyph
  tk <- emoji_tokens(df, text)
  expect_equal(
    tk$.emoji_sentiment,
    unname(tidyEmoji:::emoji_sentiment_map()[tidyEmoji:::emoji_key(tk$.emoji)])
  )
})

test_that("emoji_context and emoji_density tokenise identically", {
  # ?emoji_context claims "the same definition emoji_density() uses"; these are
  # separate implementations ([[:space:]] vs \\s, trimws or not), so the claim
  # needs a test rather than a comment
  density_tokens <- function(s) sum(nzchar(strsplit(trimws(s), "\\s+")[[1]]))
  context_tokens <- function(s) length(tidyEmoji:::.emoji_words(s))
  cases <- c(
    "one two three",
    paste0("one", "\u00A0", "two three"),   # no-break space: not whitespace
    paste0("one", "\u2003", "two three"),   # em space: is whitespace
    paste0("one", "\u3000", "two three"),   # ideographic space
    paste0("one", "\u1680", "two three"),   # ogham space mark
    paste0("one", "\u200B", "two three"),   # zero-width space: not whitespace
    "one\ttwo", "one\ntwo", "  one two  ", "\u00A0", ""
  )
  for (s in cases) expect_equal(context_tokens(s), density_tokens(s))
})

test_that("emoji_trend returns a complete period-by-emoji grid", {
  df <- data.frame(
    text = c(paste0(laugh, heart_eyes), laugh, paste0(heart_eyes, party),
             party, paste0(laugh, party), "plain"),
    when = as.Date(c("2021-01-05", "2021-01-20", "2021-02-10",
                     "2021-02-25", "2021-03-03", "2021-03-15"))
  )
  tr <- emoji_trend(df, text, when, by = "month", top_n = NULL)
  expect_equal(nrow(tr),
               length(unique(tr$.period)) * length(unique(tr$emoji)))
  expect_gt(sum(tr$n == 0L), 0L)          # the zeros a trend line needs
  expect_equal(as.numeric(tapply(tr$share, tr$.period, sum)),
               rep(1, length(unique(tr$.period))))
  expect_equal(sum(tr$n), sum(emoji_frequency(df, text)$n))
  # measure = "share" changes the emphasis, not the shape
  trs <- emoji_trend(df, text, when, by = "month", top_n = NULL,
                     measure = "share")
  expect_identical(names(trs), names(tr))
  expect_equal(nrow(trs), nrow(tr))
})

test_that("emoji_turnover agrees with set arithmetic and with itself", {
  df <- data.frame(
    text = c(paste0(laugh, heart_eyes), laugh, paste0(heart_eyes, party),
             party, paste0(laugh, party), "plain"),
    when = as.Date(c("2021-01-05", "2021-01-20", "2021-02-10",
                     "2021-02-25", "2021-03-03", "2021-03-15"))
  )
  all_m <- c("jaccard", "new", "lost", "core")
  full <- emoji_turnover(df, text, when, measure = all_m)
  # every subset of `measure` yields a subset of the full column set, and the
  # values do not depend on which subset was asked for
  for (k in seq_along(all_m)) {
    for (cmb in utils::combn(all_m, k, simplify = FALSE)) {
      part <- emoji_turnover(df, text, when, measure = cmb)
      expect_true(all(names(part) %in% names(full)))
      expect_equal(nrow(part), nrow(full))
      for (col in base::intersect(names(part), names(full))) {
        expect_equal(part[[col]], full[[col]])
      }
    }
  }
  # and the first period pair matches set arithmetic done by hand
  vocab <- lapply(
    split(df$text, format(df$when, "%Y-%m")),
    function(v) unique(unlist(tidyEmoji:::emoji_glyph_list(v)))
  )
  expect_equal(full$jaccard[1],
               length(base::intersect(vocab[[1]], vocab[[2]])) /
                 length(base::union(vocab[[1]], vocab[[2]])))
  expect_equal(full$n_new[1], length(base::setdiff(vocab[[2]], vocab[[1]])))
  expect_equal(full$n_lost[1], length(base::setdiff(vocab[[1]], vocab[[2]])))
  expect_equal(full$n_core[1], length(base::intersect(vocab[[1]], vocab[[2]])))
})


# ---------------------------------------------------------------------------
# emoji_incongruity(where = "final") rests on a helper that decides what
# "ends the text" means. The definition is a research choice, so pin it: a
# change here silently redefines the variable a user is modelling.
# ---------------------------------------------------------------------------

test_that("the trailing run is whitespace-tolerant and punctuation-strict", {
  fg <- tidyEmoji:::.emoji_final_glyphs
  n_final <- function(s) length(fg(s)[[1]])
  # only whitespace may follow the last glyph
  expect_equal(n_final(paste("great", laugh)), 1L)
  expect_equal(n_final(paste0("great ", laugh, "   ")), 1L)
  expect_equal(n_final(paste0("great ", laugh, "\n")), 1L)
  expect_equal(n_final(paste0("great ", laugh, "\t")), 1L)
  # anything else does not
  expect_equal(n_final(paste0("great ", laugh, ".")), 0L)
  expect_equal(n_final(paste0("great (", laugh, ")")), 0L)
  expect_equal(n_final(paste("mid", laugh, "text")), 0L)
  # the run extends back over whitespace-separated glyphs, and stops at text
  expect_equal(n_final(paste0("great ", laugh, " ", heart_eyes)), 2L)
  expect_equal(n_final(paste0("great ", laugh, heart_eyes)), 2L)
  expect_equal(n_final(paste0("x ", laugh, " ", heart_eyes, " ", party)), 3L)
  expect_equal(n_final(paste0("great ", laugh, " ok ", heart_eyes)), 1L)
  # degenerate rows
  expect_equal(n_final(laugh), 1L)
  expect_equal(n_final(paste0("  ", laugh, "  ")), 1L)
  expect_equal(n_final("plain text"), 0L)
  expect_equal(n_final(""), 0L)
  # a multi-code-point glyph is one final glyph
  expect_equal(n_final(paste("family", family)), 1L)
})

test_that("where = 'final' scores exactly the trailing run", {
  txt <- c(paste("great", laugh), paste("mid", laugh, "text"),
           paste0("great ", laugh, "."), paste0("x ", laugh, " ", heart_eyes),
           laugh, "plain")
  df <- data.frame(text = txt, sc = 0)
  fin <- emoji_incongruity(df, text, sc, scale = "none", where = "final")
  all_ <- emoji_incongruity(df, text, sc, scale = "none", where = "all")
  expect_equal(fin$.emoji_n_scored, c(1L, NA, NA, 2L, 1L, NA))
  # never more than `where = "all"`, and .emoji_n is untouched by `where`
  expect_true(all(fin$.emoji_n_scored <= all_$.emoji_n_scored, na.rm = TRUE))
  expect_identical(fin$.emoji_n, all_$.emoji_n)
})


# ---------------------------------------------------------------------------
# Directed and undirected pairs must describe the same co-occurrences.
# ---------------------------------------------------------------------------

test_that("directed pairs are a re-orientation, not a different count", {
  d <- data.frame(text = c(paste0(laugh, heart_eyes),
                           paste0(heart_eyes, laugh),
                           paste0(laugh, heart_eyes, party)))
  und <- emoji_pairs(d, text)
  dir <- emoji_pairs(d, text, directed = TRUE)
  expect_equal(sum(dir$n), sum(und$n))
  # a pair is two distinct emoji, in either orientation
  expect_false(any(dir$item1 == dir$item2))
  expect_false(any(und$item1 == und$item2))
  # the same emoji twice in one document is not a pair
  expect_equal(nrow(emoji_pairs(data.frame(text = paste0(laugh, laugh)),
                                text, directed = TRUE)), 0L)
  # undirected collapses the two orientations of the same unordered pair
  expect_lte(nrow(und), nrow(dir))
})

test_that("emoji_ngrams positions index the row's emoji sequence", {
  d <- data.frame(text = c(paste0(laugh, heart_eyes, party), laugh, "plain",
                           paste0(laugh, laugh, laugh, laugh)))
  bi <- emoji_ngrams(d, text, n = 2)
  expect_equal(bi$.row_number, c(1L, 1L, 4L, 4L, 4L))
  expect_equal(bi$.position, c(1L, 2L, 1L, 2L, 3L))
  # a window wider than the row contributes nothing
  expect_equal(nrow(emoji_ngrams(d, text, n = 5)), 0L)
  # n = 1 is one row per occurrence
  expect_equal(nrow(emoji_ngrams(d, text, n = 1)),
               sum(emoji_position(d, text)$.emoji_n))
})


# ---------------------------------------------------------------------------
# emoji_dfm()'s weightings over *aggregated* documents. The count path was
# tested with one document per row; tfidf's denominator is the document count,
# so aggregating with doc_id changes N and df together.
# ---------------------------------------------------------------------------

test_that("tfidf over aggregated documents is count * log(N/df)", {
  d <- data.frame(who = c("a", "a", "b", "c"),
                  text = c(laugh, paste0(laugh, heart_eyes), heart_eyes,
                           paste0(heart_eyes, party)))
  cnt <- emoji_dfm(d, text, doc_id = who)
  tf <- emoji_dfm(d, text, doc_id = who, weighting = "tfidf")
  bin <- emoji_dfm(d, text, doc_id = who, weighting = "binary")
  expect_equal(nrow(cnt), 3L)
  expect_equal(sum(cnt[, -1]), sum(emoji_frequency(d, text)$n))
  n_docs <- nrow(cnt)
  for (g in names(cnt)[-1]) {
    doc_freq <- sum(cnt[[g]] > 0)
    expect_equal(tf[[g]], cnt[[g]] * log(n_docs / doc_freq))
  }
  expect_equal(as.matrix(bin[, -1]) > 0, as.matrix(cnt[, -1]) > 0)
  # the documented consequence: an emoji in every document carries no weight
  everywhere <- names(cnt)[-1][vapply(names(cnt)[-1],
                                      function(g) all(cnt[[g]] > 0),
                                      logical(1))]
  for (g in everywhere) expect_true(all(tf[[g]] == 0))
})

test_that("emoji_emotion(long = TRUE) is the wide form, reshaped", {
  dims <- c("anger", "anticipation", "disgust", "fear",
            "joy", "sadness", "surprise", "trust")
  df <- data.frame(text = c(paste("love", heart_eyes), "plain",
                            paste("x", laugh)))
  lg <- emoji_emotion(df, text, long = TRUE)
  wd <- emoji_emotion(df, text, long = FALSE)
  expect_equal(nrow(lg), nrow(df) * length(dims))
  # Plutchik order, repeated once per input row, rows kept in order
  expect_identical(lg$.emoji_emotion, rep(dims, times = nrow(df)))
  expect_identical(lg$text, rep(df$text, each = length(dims)))
  expect_equal(lg$.emoji_score,
               as.numeric(t(as.matrix(wd[, paste0(".emoji_", dims)]))))
})

test_that("emoji_emotion_label picks the first argmax in Plutchik order", {
  dims <- c("anger", "anticipation", "disgust", "fear",
            "joy", "sadness", "surprise", "trust")
  df <- data.frame(text = c(paste("x", laugh), paste("y", heart_eyes),
                            "plain"))
  wd <- emoji_emotion(df, text, long = FALSE)
  lab <- emoji_emotion_label(df, text)$.emoji_emotion
  for (i in seq_len(nrow(df))) {
    scores <- unlist(wd[i, paste0(".emoji_", dims)])
    if (all(is.na(scores))) {
      expect_true(is.na(lab[i]))
    } else {
      expect_identical(lab[i], dims[which.max(scores)])
    }
  }
})

test_that("the functional-type taxonomy is total and its levels are all used", {
  ref <- tidyEmoji:::emoji_reference()
  types <- as_emoji_type(ref$emoji)
  expect_false(anyNA(types))
  levels <- tidyEmoji:::emoji_type_levels()
  expect_true(all(unique(types) %in% levels))
  expect_true(all(levels %in% unique(types)))
})


# ---------------------------------------------------------------------------
# The affect statistics, against their definitions. Round 3 pinned tfidf, the
# rank/z-score rescalings, PMI and entropy; these are the four that were left.
# A data-raw rebuild or a formula "simplification" would otherwise change
# published numbers silently.
# ---------------------------------------------------------------------------

test_that("the ambiguity measures match their definitions", {
  L <- emoji_sentiment_lexicon
  a <- tidyEmoji:::emoji_ambiguity_table()
  i <- match(a$key, tidyEmoji:::emoji_key(L$emoji))
  n <- L$negative[i] + L$neutral[i] + L$positive[i]
  p_neg <- L$negative[i] / n
  p_neu <- L$neutral[i] / n
  p_pos <- L$positive[i] / n
  expect_equal(a$p_neg, p_neg)
  expect_equal(a$p_neu, p_neu)
  expect_equal(a$p_pos, p_pos)
  # Shannon entropy in nats, with 0 log 0 taken as its limit
  plogp <- function(p) ifelse(p > 0, p * log(p), 0)
  expect_equal(a$entropy, -(plogp(p_neg) + plogp(p_neu) + plogp(p_pos)))
  expect_equal(a$gini, 1 - (p_neg^2 + p_neu^2 + p_pos^2))
  expect_equal(a$neutral_share, p_neu)
  # bounds a three-class distribution cannot exceed
  expect_lte(max(a$entropy), log(3) + 1e-9)
  expect_lte(max(a$gini), 2 / 3 + 1e-9)
})

test_that("the glyph standard error is a real variance over {-1, 0, 1}", {
  L <- emoji_sentiment_lexicon
  a <- tidyEmoji:::emoji_ambiguity_table()
  i <- match(a$key, tidyEmoji:::emoji_key(L$emoji))
  n <- L$negative[i] + L$neutral[i] + L$positive[i]
  p_neg <- L$negative[i] / n
  p_pos <- L$positive[i] / n
  # X in {-1, 0, 1}: E[X] = p_pos - p_neg, E[X^2] = p_pos + p_neg
  variance <- pmax((p_pos + p_neg) - (p_pos - p_neg)^2, 0)
  expect_equal(a$se, sqrt(variance / n))
  expect_equal(a$ci_width, 2 * stats::qnorm(0.975) * a$se)
  expect_true(all(variance >= 0))
  # the lexicon's own score is the same expectation
  expect_equal(L$sentiment_score[i], p_pos - p_neg)
  # and more annotations means a tighter estimate
  expect_lt(stats::cor(a$se, n, method = "spearman"), 0)
})

test_that("emoji_risk(threshold = NULL) is the measure's upper quartile", {
  tbl <- tidyEmoji:::emoji_ambiguity_table()
  for (m in c("entropy", "gini", "neutral_share", "ci_width")) {
    q <- unname(stats::quantile(tbl[[m]], 0.75, na.rm = TRUE))
    df <- data.frame(text = head(tbl$emoji[!is.na(tbl[[m]])], 40))
    expect_identical(
      emoji_risk(df, text, measure = m)$.emoji_n_ambiguous,
      emoji_risk(df, text, measure = m, threshold = q)$.emoji_n_ambiguous
    )
  }
})

test_that("emoji_sentiment(se = TRUE) propagates as documented", {
  a <- tidyEmoji:::emoji_ambiguity_table()
  # pick glyphs the engine can actually see: the lexicon's leading rows include
  # text-presentation forms (the bare U+2764) that are deliberately undetected,
  # and a row containing one scores fewer glyphs than it looks like
  detectable <- a$emoji[lengths(tidyEmoji:::emoji_glyph_list(a$emoji)) == 1L]
  g1 <- detectable[1]
  g2 <- detectable[2]
  se <- stats::setNames(a$se, a$key)
  s1 <- se[[tidyEmoji:::emoji_key(g1)]]
  s2 <- se[[tidyEmoji:::emoji_key(g2)]]
  out <- emoji_sentiment(data.frame(text = c(g1, paste0(g1, g2), "plain")),
                         text, se = TRUE)
  expect_equal(out$.emoji_n_scored, c(1L, 2L, NA))
  expect_equal(out$.emoji_sentiment_se[1], s1)
  expect_equal(out$.emoji_sentiment_se[2], sqrt(s1^2 + s2^2) / 2)
  expect_true(is.na(out$.emoji_sentiment_se[3]))
  expect_true(all(out$.emoji_sentiment_se >= 0, na.rm = TRUE))
})


# ---------------------------------------------------------------------------
# emoji_unicode_releases() is the version-to-date lookup behind
# emoji_version_profile() and emoji_adoption_lag(). Emoji versions 0.6-5.0 and
# Unicode versions 6.0-10.0 ran in *parallel* until they unified at 11.0, so
# the table holds two series and its dates are not monotonic when read as one
# list. That structure is easy to "tidy" into a single sorted column and break.
# ---------------------------------------------------------------------------

test_that("the releases table has two internally consistent series", {
  rel <- emoji_unicode_releases()
  expect_true(all(c("version", "version_num", "series", "release_date") %in%
                    names(rel)))
  expect_equal(anyDuplicated(rel$version), 0L)
  expect_equal(rel$version_num, as.numeric(rel$version))
  expect_false(anyNA(rel$release_date))
  # each series is monotonic in its own numbering
  for (s in unique(rel$series)) {
    sub <- rel[rel$series == s, ]
    expect_true(all(diff(sub$release_date[order(sub$version_num)]) > 0))
  }
  # and the two series agree where they describe the same release
  same_day <- function(a, b) {
    expect_identical(rel$release_date[rel$version == a],
                     rel$release_date[rel$version == b])
  }
  same_day("0.7", "7.0")
  same_day("3.0", "9.0")
  same_day("5.0", "10.0")
})

test_that("the catalogue's versions all resolve, and only via the emoji series", {
  ref <- tidyEmoji:::emoji_reference()
  rel <- emoji_unicode_releases()
  labels <- unique(tidyEmoji:::.emoji_version_label(ref$version))
  known <- labels[!is.na(labels)]
  expect_gt(length(known), 10L)
  expect_true(all(known %in% rel$version[rel$series == "emoji"]))
  # version_num is what orders them: numeric and lexical order genuinely differ
  expect_false(identical(known[order(tidyEmoji:::.emoji_version_num(known))],
                         known[order(known)]))
  # Every catalogue version now resolves. This assertion used to be the
  # opposite -- it required some labels to be NA -- which only held because
  # emoji::emojis records the introducing version on the unqualified member of
  # a variation pair and leaves it NA on the fully-qualified one, so 1252 rows
  # (U+2764 U+FE0F among them) had no version. emoji_reference() now fills
  # version within a codepoint key, so the old assertion was encoding a defect.
  expect_false(anyNA(labels))
})

test_that("a glyph whose version is unknown is reported, not dropped", {
  # The catalogue no longer contains an unknown version, so drive the path
  # directly rather than relying on a gap in the upstream data.
  expect_true(is.na(tidyEmoji:::.emoji_version_label(NA_character_)))
  expect_true(is.na(tidyEmoji:::.emoji_version_num(NA_character_)))
  expect_identical(tidyEmoji:::.emoji_version_label(c("0.6", NA)),
                   c("0.6", NA_character_))

  cache <- asNamespace("tidyEmoji")$.tidyEmoji_cache
  ref <- tidyEmoji:::emoji_reference()
  on.exit(assign("reference", ref, envir = cache), add = TRUE)
  hacked <- ref
  hacked$version[1:3] <- NA_character_
  assign("reference", hacked, envir = cache)

  d <- data.frame(text = ref$emoji[1:6], stringsAsFactors = FALSE)
  vp <- emoji_version_profile(d, text)
  expect_true(anyNA(vp$version))
  # nothing is lost: every glyph is still counted somewhere
  expect_identical(sum(vp$n_tokens), 6L)
})

test_that("emoji_adoption_lag computes first_seen, release and lag by hand", {
  melting <- "\U0001FAE0"   # Unicode Emoji 14.0
  d <- data.frame(
    text = c(laugh, paste0(laugh, heart_eyes), melting, laugh),
    when = as.Date(c("2020-01-10", "2020-03-05", "2022-06-01", "2019-12-31"))
  )
  al <- emoji_adoption_lag(d, text, when)
  ref <- tidyEmoji:::emoji_reference()
  rel <- emoji_unicode_releases()
  for (k in seq_len(nrow(al))) {
    g <- al$emoji[k]
    seen <- min(d$when[grepl(g, d$text, fixed = TRUE)])
    ver <- tidyEmoji:::.emoji_version_label(
      ref$version[match(tidyEmoji:::emoji_key(g), ref$key)])
    expect_identical(al$first_seen[k], seen)
    expect_identical(al$release_date[k], rel$release_date[match(ver, rel$version)])
    expect_identical(al$lag_days[k], as.integer(seen - al$release_date[k]))
  }
  expect_type(al$lag_days, "integer")
  # n counts occurrences, not rows
  expect_equal(al$n[al$emoji == laugh], 3L)
})

test_that("a glyph used before its release date gets a negative lag", {
  # documented as "usually a vendor shipping early" -- it must not be clamped,
  # because it is also how a corpus with wrong dates announces itself
  melting <- "\U0001FAE0"
  al <- emoji_adoption_lag(
    data.frame(text = melting, when = as.Date("2015-01-01")), text, when)
  expect_lt(al$lag_days, 0L)
  expect_identical(al$first_seen, as.Date("2015-01-01"))
})

test_that("adoption_lag and version_profile are collation-invariant", {
  # both split() by glyph, whose factor levels come from sort() -- these two
  # verbs were not in the collation sweep the other sixteen outputs are in
  melting <- "\U0001FAE0"
  d <- data.frame(text = c(laugh, heart_eyes, melting,
                           paste0(laugh, heart_eyes, melting), party),
                  when = as.Date("2020-01-01") + 0:4)
  snapshot <- function() {
    al <- emoji_adoption_lag(d, text, when)
    vp <- emoji_version_profile(d, text)
    list(emoji = al$emoji, lag = al$lag_days, first = al$first_seen,
         version = vp$version, tokens = vp$n_tokens, types = vp$n_types,
         releases = emoji_unicode_releases()$version)
  }
  old <- Sys.getlocale("LC_COLLATE")
  on.exit(suppressWarnings(Sys.setlocale("LC_COLLATE", old)), add = TRUE)
  baseline <- snapshot()
  tried <- 0L
  for (loc in c("C", "en_US.UTF-8")) {
    available <- tryCatch({
      suppressWarnings(Sys.setlocale("LC_COLLATE", loc))
      identical(Sys.getlocale("LC_COLLATE"), loc)
    }, error = function(e) FALSE)
    if (!available) next
    tried <- tried + 1L
    expect_identical(snapshot(), baseline)
  }
  skip_if(tried == 0L, "no alternative collation available")
})


# ---------------------------------------------------------------------------
# emoji_collocations()'s PMI. The earlier check used a symmetric fixture where
# every marginal was equal, so any formula of roughly that shape would have
# passed. This one is deliberately asymmetric: the six values come out as
# log(2), log(1.5) and log(0.5), which pin the numerator and both marginals.
# ---------------------------------------------------------------------------

collocation_fixture <- function() {
  data.frame(text = c(
    paste("good great fine", laugh),
    paste("good great", laugh),
    paste("good", laugh),
    paste("good bad", heart_eyes),
    paste("bad awful", heart_eyes),
    paste("bad", heart_eyes),
    paste("bad", heart_eyes)
  ))
}

test_that("pmi is log(n * N / (n_emoji * n_word))", {
  d <- collocation_fixture()
  co <- emoji_collocations(d, text, window = 5, min_n = 1)
  # rebuild the table independently from emoji_context()
  ctx <- emoji_context(d, text, window = 5, unit = "word")
  words <- lapply(ctx$.emoji_context, function(s) {
    w <- tidyEmoji:::.emoji_words(tolower(s))
    w <- gsub("^[^[:alnum:]]+|[^[:alnum:]]+$", "", w)
    unique(w[nzchar(w)])
  })
  pairs <- data.frame(
    emoji = rep(tidyEmoji:::emoji_canonical(ctx$.emoji), lengths(words)),
    word = unlist(words, use.names = FALSE),
    stringsAsFactors = FALSE
  )
  tab <- dplyr::count(pairs, emoji, word, name = "n")
  total <- sum(tab$n)
  # as.numeric(), not unname(): tapply() returns a 1-d array and subsetting it
  # keeps the dim attribute, which propagates through the arithmetic
  e_tot <- as.numeric(tapply(tab$n, tab$emoji, sum)[tab$emoji])
  w_tot <- as.numeric(tapply(tab$n, tab$word, sum)[tab$word])
  tab$expected <- log(tab$n * total / (e_tot * w_tot))
  m <- merge(as.data.frame(co), as.data.frame(tab), by = c("emoji", "word"))
  expect_equal(nrow(m), nrow(co))
  expect_equal(as.numeric(m$pmi), as.numeric(m$expected))
  expect_equal(sum(co$n), total)
  # the fixture's marginals are genuinely unequal, so the test has teeth
  expect_gt(length(unique(w_tot)), 1L)
})

test_that("pmi signs mean what they should, and stay finite", {
  co <- emoji_collocations(collocation_fixture(), text, window = 5, min_n = 1)
  expect_true(all(is.finite(co$pmi)))
  # a word used with only one emoji is positively associated with it
  expect_true(all(co$pmi[co$word %in% c("great", "fine", "awful")] > 0))
  # a word shared between both emoji must be negative for at least one
  expect_true(any(co$pmi[co$word == "good"] < 0))
})

test_that("min_n is inclusive and prunes after the marginals", {
  d <- collocation_fixture()
  full <- emoji_collocations(d, text, window = 5, min_n = 1)
  for (k in 1:4) {
    part <- emoji_collocations(d, text, window = 5, min_n = k)
    if (nrow(part)) expect_gte(min(part$n), k)
    expect_true(all(part$n >= k))
  }
  # pruning must not change the pmi of the rows that survive: the marginals
  # are corpus-level, so a pruned table still describes the whole corpus
  part <- emoji_collocations(d, text, window = 5, min_n = 3)
  idx <- match(paste(part$emoji, part$word), paste(full$emoji, full$word))
  expect_equal(part$pmi, full$pmi[idx])
})

test_that("measure changes the ordering, not the rows", {
  d <- collocation_fixture()
  by_pmi <- emoji_collocations(d, text, min_n = 1, measure = "pmi")
  by_n <- emoji_collocations(d, text, min_n = 1, measure = "count")
  expect_identical(names(by_pmi), names(by_n))
  expect_equal(nrow(by_pmi), nrow(by_n))
  expect_setequal(paste(by_pmi$emoji, by_pmi$word),
                  paste(by_n$emoji, by_n$word))
  expect_false(is.unsorted(-by_pmi$pmi))
  expect_false(is.unsorted(-by_n$n))
})

test_that("a wider context window cannot lose collocations", {
  d <- collocation_fixture()
  narrow <- emoji_collocations(d, text, window = 1, min_n = 1)
  wide <- emoji_collocations(d, text, window = 20, min_n = 1)
  expect_gte(nrow(wide), nrow(narrow))
  expect_true(all(paste(narrow$emoji, narrow$word) %in%
                    paste(wide$emoji, wide$word)))
})


# ---------------------------------------------------------------------------
# NEWS.md is parsed by utils::news() and rendered on the CRAN package page, so
# a malformed heading is a user-visible break that R CMD check does not catch.
# ---------------------------------------------------------------------------

# The version headings, checked without parsing Markdown at all, so the
# invariant holds even where the reader's dependencies are absent.
test_that("NEWS.md has a well-formed heading for every released version", {
  path <- testthat::test_path("..", "..", "NEWS.md")
  skip_if_not(file.exists(path), "NEWS.md not available")
  headings <- grep("^# ", readLines(path, warn = FALSE), value = TRUE)
  expect_gt(length(headings), 0L)
  # every top-level heading is "# tidyEmoji <version>"
  expect_true(all(grepl("^# tidyEmoji [0-9]+([.][0-9]+)+$", headings)))
  versions <- sub("^# tidyEmoji ", "", headings)
  expect_equal(anyDuplicated(versions), 0L)
  # newest first, and the version under development leads
  expect_identical(versions, as.character(sort(package_version(versions),
                                               decreasing = TRUE)))
  desc <- read.dcf(testthat::test_path("..", "..", "DESCRIPTION"))
  expect_identical(versions[1], unname(desc[1, "Version"]))
})

test_that("NEWS.md parses into news() entries for every released version", {
  # utils::news() reads a Markdown NEWS.md through commonmark and xml2, and
  # tools:::.build_news_db_from_package_NEWS_md calls both unguarded. Neither
  # was a dependency of this package -- they were present here only because
  # roxygen2 and testthat pull them in -- so this test passed locally and
  # errored on every CI platform. Both are now in Suggests so CI runs it.
  #
  # Two things this cost, worth remembering: _R_CHECK_DEPENDS_ONLY_ cannot
  # catch it, because it masks Suggests and these were in neither field; and
  # declaring only commonmark just moved the error to xml2, because a missing
  # dependency stops at the first one.
  skip_if_not_installed("commonmark")
  skip_if_not_installed("xml2")
  db <- suppressWarnings(utils::news(package = "tidyEmoji"))
  expect_s3_class(db, "news_db")
  expect_gt(nrow(db), 0L)
  expect_false(any(is.na(db$Version) | !nzchar(db$Version)))
  expect_true("0.4.0" %in% db$Version)
  # the version under development must have entries in both usual categories
  this_release <- db[db$Version == "0.4.0", ]
  expect_true(all(c("New features", "Improvements and fixes") %in%
                    this_release$Category))
})


# ---------------------------------------------------------------------------
# Row-order independence. Collation invariance is covered elsewhere; this is
# the other half of reproducibility, and it is what emoji_dfm()'s glyph
# tiebreak actually protects: without it, tied columns fall back to the order
# the glyphs happen to appear in the data, so the same corpus sorted
# differently yields a differently-ordered feature matrix. Found by mutation
# testing -- deleting the tiebreak passed the entire suite.
# ---------------------------------------------------------------------------

test_that("a row permutation cannot reorder any aggregate output", {
  # every emoji has the same total count, so every ordering is a pure tie and
  # only the tiebreak decides
  glyphs <- c(laugh, heart_eyes, party, poop)
  forwards <- data.frame(text = glyphs)
  backwards <- data.frame(text = rev(glyphs))
  shuffled <- data.frame(text = glyphs[c(3, 1, 4, 2)])
  cols <- function(d) names(emoji_dfm(d, text))
  expect_identical(cols(backwards), cols(forwards))
  expect_identical(cols(shuffled), cols(forwards))
  expect_identical(names(emoji_dfm(backwards, text, weighting = "binary")),
                   cols(forwards))
  # the other ordered aggregates, on the same all-tied corpus
  expect_identical(emoji_frequency(backwards, text)$emoji,
                   emoji_frequency(forwards, text)$emoji)
  expect_identical(top_n_emojis(backwards, text)$unicode,
                   top_n_emojis(forwards, text)$unicode)
  expect_identical(emoji_version_profile(backwards, text)$version,
                   emoji_version_profile(forwards, text)$version)
})

test_that("a row permutation cannot reorder the relational verbs", {
  docs <- c(paste0(laugh, heart_eyes), paste0(heart_eyes, party),
            paste0(party, laugh))
  forwards <- data.frame(text = docs)
  backwards <- data.frame(text = rev(docs))
  expect_identical(emoji_pairs(backwards, text), emoji_pairs(forwards, text))
  expect_identical(emoji_cooccurrence(backwards, text, diagonal = TRUE),
                   emoji_cooccurrence(forwards, text, diagonal = TRUE))
  # collocations: same pairs and values, ordering independent of row order
  cf <- emoji_collocations(
    data.frame(text = paste(c("good", "bad", "fine"), docs)), text, min_n = 1)
  cb <- emoji_collocations(
    data.frame(text = rev(paste(c("good", "bad", "fine"), docs))), text,
    min_n = 1)
  expect_identical(cf, cb)
})

test_that("dfm columns are ordered by count then glyph, not by appearance", {
  # laugh is commonest, so it leads; the two singletons tie and must come back
  # in glyph order whichever way round the data has them
  d1 <- data.frame(text = c(paste0(laugh, laugh), party, heart_eyes))
  d2 <- data.frame(text = c(heart_eyes, party, paste0(laugh, laugh)))
  expect_identical(names(emoji_dfm(d1, text)), names(emoji_dfm(d2, text)))
  expect_equal(names(emoji_dfm(d1, text))[2], laugh)
  tied <- names(emoji_dfm(d1, text))[3:4]
  expect_identical(tied, sort(tied, method = "radix"))
})


# ---------------------------------------------------------------------------
# emoji_search() is documented to match against keywords, name *and*
# shortcodes. Nothing tested the three fields separately, so deleting the alias
# term from `kw_hit | nm_hit | al_hit` passed the whole suite -- found by
# mutation testing. Some queries match on one field only.
# ---------------------------------------------------------------------------

test_that("emoji_search matches on each of its three fields", {
  # alias-only: "thumbsup" and "grinning_face" appear in no name (which has
  # spaces, not underscores) and in no keyword
  e <- emoji::emojis
  alias_only <- function(q) {
    kw <- vapply(e$keywords, function(k) any(grepl(q, tolower(k), fixed = TRUE)),
                 logical(1))
    nm <- grepl(q, tolower(e$name), fixed = TRUE)
    al <- vapply(e$aliases, function(a) any(grepl(q, tolower(a), fixed = TRUE)),
                 logical(1))
    sum(al & !kw & !nm)
  }
  expect_gt(alias_only("grinning_face"), 0L)
  expect_gt(nrow(emoji_search("grinning_face")), 0L)
  expect_gt(nrow(emoji_search("thumbsup")), 0L)
  # "+1" is a shortcode whose regex metacharacter must also survive
  expect_equal(nrow(emoji_search("+1")), 1L)

  # name-only and keyword-only queries also return hits
  expect_gt(nrow(emoji_search("with tears of joy")), 0L)   # a name substring
  expect_gt(nrow(emoji_search("happy")), 0L)               # a keyword

  # the union is at least as large as any single field
  expect_gte(nrow(emoji_search("smiley")),
             max(nrow(emoji_search("grinning_face")), 1L))
})

test_that("emoji_search returns the documented columns and is case-blind", {
  out <- emoji_search("grin")
  expect_identical(names(out),
                   c("emoji", "name", "shortcode", "group", "keyword"))
  expect_gt(nrow(out), 0L)
  expect_identical(out, emoji_search("GRIN"))
  expect_identical(out, emoji_search("Grin"))
  # a query that matches nothing gives a typed zero-row tibble, not an error
  none <- emoji_search("zzzzznotanemoji")
  expect_equal(nrow(none), 0L)
  expect_identical(names(none), names(out))
  expect_type(none$emoji, "character")
})


# ---------------------------------------------------------------------------
# as_emoji() and text_to_emoji() accept *every* GitHub alias, not just the
# primary one each emoji is listed under. The reference table keeps only the
# first alias as `shortcode`, so 751 of the 4698 resolve solely through
# as_emoji()'s third-tier fallback to emoji::emoji_name -- and deleting that
# fallback passed the whole suite. Found by mutation testing.
# ---------------------------------------------------------------------------

test_that("as_emoji resolves every alias, primary or not", {
  ref <- tidyEmoji:::emoji_reference()
  aliases <- unique(unlist(emoji::emojis$aliases, use.names = FALSE))
  aliases <- aliases[!is.na(aliases) & nzchar(aliases)]
  primary <- unique(ref$shortcode[!is.na(ref$shortcode)])
  secondary <- base::setdiff(aliases, primary)
  # the fallback is load-bearing: hundreds of aliases are not any emoji's first
  expect_gt(length(secondary), 100L)
  expect_false(anyNA(as_emoji(aliases)))
  expect_false(anyNA(as_emoji(secondary)))
  # named examples, so a failure says which lookup broke
  expect_equal(as_emoji("joy"), "\U0001F602")             # primary shortcode
  expect_equal(as_emoji("grinning_face"), "\U0001F600")   # third tier only
  expect_equal(as_emoji("satisfied"), "\U0001F606")       # third tier only
  # reference names and shortcodes also resolve, and an unknown gives NA
  expect_false(anyNA(as_emoji(ref$name)))
  expect_true(is.na(as_emoji("definitely_not_an_emoji_name")))
})

test_that("text_to_emoji converts every alias token, primary or not", {
  ref <- tidyEmoji:::emoji_reference()
  aliases <- unique(unlist(emoji::emojis$aliases, use.names = FALSE))
  aliases <- aliases[!is.na(aliases) & nzchar(aliases)]
  secondary <- base::setdiff(aliases, unique(ref$shortcode[!is.na(ref$shortcode)]))
  tokens <- paste0(":", secondary, ":")
  out <- text_to_emoji(data.frame(text = tokens), text)$text
  # every token must have been rewritten
  expect_false(any(out == tokens))
  expect_equal(text_to_emoji(data.frame(text = "hi :grinning_face: bye"),
                             text)$text,
               "hi \U0001F600 bye")
  # an unknown shortcode is left alone rather than blanked
  expect_equal(text_to_emoji(data.frame(text = ":not_a_shortcode:"),
                             text)$text,
               ":not_a_shortcode:")
})


# ---------------------------------------------------------------------------
# emoji_incongruity(threshold =) is documented as the gap "at or above which"
# .emoji_incongruent is TRUE. Nothing tested the boundary, so flipping >= to >
# passed the suite -- it would silently reclassify every row sitting exactly on
# the threshold.
# ---------------------------------------------------------------------------

test_that("the incongruity threshold is inclusive at the boundary", {
  # with scale = "none" and text_score 0, the gap is exactly the emoji score,
  # so setting threshold to that same double puts the row precisely on the line
  score <- tidyEmoji:::emoji_sentiment_map()[[tidyEmoji:::emoji_key(laugh)]]
  df <- data.frame(text = paste("x", laugh), sc = 0)
  on_line <- emoji_incongruity(df, text, sc, scale = "none",
                               threshold = score)
  expect_equal(on_line$.emoji_incongruity, score)
  expect_true(on_line$.emoji_incongruent)
  # just above the line is FALSE, just below is TRUE
  just_above <- emoji_incongruity(df, text, sc, scale = "none",
                                  threshold = score + 1e-9)
  expect_false(just_above$.emoji_incongruent)
  just_below <- emoji_incongruity(df, text, sc, scale = "none",
                                  threshold = score - 1e-9)
  expect_true(just_below$.emoji_incongruent)
  # a row with no comparable pair stays NA rather than FALSE
  none <- emoji_incongruity(data.frame(text = "plain", sc = 0), text, sc,
                            scale = "none", threshold = 1)
  expect_true(is.na(none$.emoji_incongruent))
})


# ---------------------------------------------------------------------------
# Source encoding. 0.4.0 made R/ pure ASCII so the PDF reference manual builds
# on every CRAN flavour, and that has been checked by hand every round since.
# Automate it -- and cover the test files too, whose string literals must be
# written as escapes rather than literal glyphs so the suite passes in a
# non-UTF-8 locale.
# ---------------------------------------------------------------------------

non_ascii_bytes <- function(path) {
  raw <- readBin(path, "raw", file.info(path)$size)
  any(raw > as.raw(127L))
}

test_that("R/ sources are pure ASCII", {
  # a literal glyph in R/ reaches the Rd files, and pdfLaTeX has no glyph for it
  files <- list.files(testthat::test_path("..", "..", "R"),
                      pattern = "[.]R$", full.names = TRUE)
  skip_if(length(files) == 0L, "package sources not available")
  expect_identical(basename(files[vapply(files, non_ascii_bytes, logical(1))]),
                   character())
})

test_that("test sources keep non-ASCII out of their string literals", {
  # R parses a source literal byte-wise under a non-UTF-8 locale, so a literal
  # zero-width joiner becomes three replacement characters and every detection
  # fixture built from it silently tests the wrong string. Comment prose is
  # exempt: it is never parsed as data.
  files <- list.files(testthat::test_path("."), pattern = "^test.*[.]R$",
                      full.names = TRUE)
  skip_if(length(files) == 0L, "test sources not available")
  offenders <- character()
  for (f in files) {
    for (line in readLines(f, warn = FALSE, encoding = "UTF-8")) {
      code <- sub("#.*$", "", line)
      quotes <- gregexpr('"', code, fixed = TRUE)[[1]]
      if (quotes[1] == -1L) next
      inner <- substr(code, quotes[1], quotes[length(quotes)])
      if (any(utf8ToInt(inner) > 127L)) {
        offenders <- c(offenders, paste0(basename(f), ": ", trimws(line)))
      }
    }
  }
  expect_identical(offenders, character())
})


# ---------------------------------------------------------------------------
# Documented behaviour that no test exercised. Found by line coverage, not by
# mutation testing: mutation only probes paths you already thought about,
# whereas coverage names the code nothing runs. At 96.59% the gaps were mostly
# error branches, but four were documented features.
# ---------------------------------------------------------------------------

test_that("emoji_score() with the emotion lexicon averages the eight dims", {
  # ?emoji_score: "For the multi-dimensional emotag1200 lexicon the score is
  # the mean over its eight emotion dimensions"
  df <- data.frame(text = c(paste("hi", laugh), "plain"))
  out <- emoji_score(df, text, lexicon = "emotag1200")
  dims <- tidyEmoji:::emoji_emotion_map()
  expected <- mean(dims[tidyEmoji:::emoji_key(laugh), ])
  expect_equal(out$.emoji_score, c(expected, NA_real_))
  expect_equal(out$.emoji_n_scored, c(1L, NA))
  # and it is genuinely the emotion lexicon, not the sentiment one
  expect_false(isTRUE(all.equal(out$.emoji_score[1],
                                emoji_score(df, text)$.emoji_score[1])))
})

test_that("emoji_sentiment() accepts a data frame and a registered lexicon", {
  df <- data.frame(text = c(paste("hi", laugh), "plain"))
  lex <- data.frame(emoji = c(laugh, heart_eyes), score = c(0.5, -0.5))
  expect_equal(emoji_sentiment(df, text, lexicon = lex)$.emoji_sentiment,
               c(0.5, NA_real_))
  register_emoji_lexicon("coverage-lex", lex)
  expect_equal(
    emoji_sentiment(df, text, lexicon = "coverage-lex")$.emoji_sentiment,
    c(0.5, NA_real_)
  )
  # a lexicon that is neither errors rather than falling through
  expect_error(emoji_sentiment(df, text, lexicon = 42), "must be")
})

test_that("emoji_trend(by = 'quarter') buckets to quarter starts", {
  df <- data.frame(
    text = rep(laugh, 4),
    when = as.Date(c("2021-01-15", "2021-04-02", "2021-08-30", "2021-12-31"))
  )
  expect_equal(format(emoji_trend(df, text, when, by = "quarter")$.period),
               c("2021-01-01", "2021-04-01", "2021-07-01", "2021-10-01"))
  # every documented bucket returns Date periods and the full corpus total
  for (unit in c("day", "week", "month", "quarter", "year")) {
    tr <- emoji_trend(df, text, when, by = unit, top_n = NULL)
    expect_s3_class(tr$.period, "Date")
    expect_equal(sum(tr$n), 4L)
  }
})

test_that("sort = FALSE orders the relational verbs by item, not by count", {
  d <- data.frame(text = c(paste0(laugh, heart_eyes), paste0(heart_eyes, party),
                           paste0(laugh, party), paste0(laugh, heart_eyes)))
  sorted <- emoji_pairs(d, text)
  unsorted <- emoji_pairs(d, text, sort = FALSE)
  # same edges either way
  expect_setequal(paste(sorted$item1, sorted$item2),
                  paste(unsorted$item1, unsorted$item2))
  # sort = TRUE leads with the commonest pair; sort = FALSE is in item order
  expect_false(is.unsorted(-sorted$n))
  expect_identical(unsorted$item1, sort(unsorted$item1, method = "radix"))
  co <- emoji_cooccurrence(d, text, sort = FALSE)
  expect_identical(co$item1, sort(co$item1, method = "radix"))
})

test_that("the rescalings collapse to zero when there is nothing to rank", {
  # .emoji_rank_scale and .emoji_zscore both have a degenerate branch: one
  # non-NA value, or zero variance. Verified in a round-3 probe and never
  # written down.
  df <- data.frame(text = paste("hi", laugh), sc = 0.5)
  expect_equal(emoji_incongruity(df, text, sc, scale = "rank")$.emoji_incongruity, 0)
  expect_equal(emoji_incongruity(df, text, sc, scale = "zscore")$.emoji_incongruity, 0)
  # all-identical scores have zero variance, so the z-scores are all zero
  tied <- data.frame(text = rep(paste("hi", laugh), 3), sc = rep(0.5, 3))
  expect_equal(emoji_incongruity(tied, text, sc, scale = "zscore")$.emoji_incongruity,
               rep(0, 3))
})

test_that("a factor time column is read as dates", {
  df <- data.frame(text = rep(laugh, 2),
                   when = factor(c("2020-01-01", "2020-02-01")))
  expect_equal(format(emoji_trend(df, text, when)$.period),
               c("2020-01-01", "2020-02-01"))
})

test_that("emoji_incongruity_profile returns a typed zero-row tibble", {
  df <- data.frame(text = c("plain", "no emoji"), sc = c(0, 0))
  out <- emoji_incongruity_profile(df, text, sc, scale = "none", min_n = 1)
  expect_equal(nrow(out), 0L)
  expect_identical(names(out), c("emoji", "name", "n", "mean_incongruity",
                                 "sd_incongruity", "n_flips", "flip_rate"))
  expect_type(out$emoji, "character")
  expect_type(out$n, "integer")
})


# ---------------------------------------------------------------------------
# The argument-validation errors. Every one of these was checked by hand in an
# earlier round and none was written as a test, so removing a validation would
# have passed the suite.
# ---------------------------------------------------------------------------

test_that("the lexicon surface rejects what it cannot use", {
  df <- data.frame(text = paste("hi", laugh))
  expect_error(emoji_score(df, text, lexicon = "no-such-lexicon"),
               "Unknown lexicon")
  expect_error(emoji_score(df, text, lexicon = 42), "must be a name")
  expect_error(emoji_emotion(df, text, lexicon = "novak2015"),
               "requires an emotion lexicon")
  expect_error(register_emoji_lexicon("bad-tbl", "not a data frame"),
               "must be a data frame")
  expect_error(register_emoji_lexicon("bad-col", data.frame(x = 1, score = 2)),
               "has no column")
  # a data-frame lexicon with no usable score column, used directly
  expect_error(emoji_score(df, text, lexicon = data.frame(emoji = laugh)),
               "No score column")
  # and a named score column that is not there
  expect_error(
    emoji_score(df, text, lexicon = data.frame(emoji = laugh, s = 1),
                score = "nope"),
    "no score column"
  )
})

test_that("a registered lexicon resolves through its stored key column", {
  # .emoji_lexicon_keys falls back to the `key` column when the glyph column
  # is named something else -- the path register_emoji_lexicon() sets up
  lex <- data.frame(glyph = c(laugh, heart_eyes), score = c(1, -1))
  register_emoji_lexicon("keyed-lex", lex, by = "glyph")
  out <- emoji_score(data.frame(text = c(paste("hi", laugh), "plain")), text,
                     lexicon = "keyed-lex")
  expect_equal(out$.emoji_score, c(1, NA_real_))
})

test_that("data and query arguments are validated", {
  expect_error(emoji_search(NA), "single non-empty string")
  expect_error(emoji_search(character(0)), "single non-empty string")
  expect_error(emoji_summary("not a data frame", text), "must be a data frame")
  expect_error(emoji_position(list(text = "x"), text), "must be a data frame")
})


test_that("the bundled lexicon's aliases resolve like its canonical name", {
  # emoji_sentiment() has a fast path for "novak2015"; the aliases that
  # .emoji_lexicon_lookup() also accepts take a different branch, which no
  # test reached
  df <- data.frame(text = c(paste("hi", laugh), "plain"))
  canonical <- emoji_sentiment(df, text)$.emoji_sentiment
  for (alias in c("sentiment", "emoji_sentiment_lexicon")) {
    expect_equal(emoji_sentiment(df, text, lexicon = alias)$.emoji_sentiment,
                 canonical)
  }
  expect_equal(emoji_score(df, text, lexicon = "sentiment")$.emoji_score,
               canonical)
})

test_that("a data-frame lexicon whose glyph column is misnamed errors", {
  df <- data.frame(text = paste("hi", laugh))
  expect_error(
    emoji_score(df, text, lexicon = data.frame(g = laugh, score = 1),
                by = "nope"),
    "no column"
  )
})

test_that("cooccurrence honours sort = FALSE with the diagonal included", {
  pleading <- "\U0001F97A"
  d <- data.frame(text = c(paste0(laugh, pleading), pleading))
  out <- emoji_cooccurrence(d, text, diagonal = TRUE, sort = FALSE)
  expect_gt(nrow(out), 0L)
  expect_identical(out$item1, sort(out$item1, method = "radix"))
  # the same edges as the sorted call, just ordered differently
  expect_setequal(paste(out$item1, out$item2),
                  paste(emoji_cooccurrence(d, text, diagonal = TRUE)$item1,
                        emoji_cooccurrence(d, text, diagonal = TRUE)$item2))
})

test_that("se = TRUE is NA for a row whose emoji carry no annotation counts", {
  pleading <- "\U0001F97A"   # post-2015, so no counts behind it
  out <- emoji_sentiment(data.frame(text = paste("x", pleading)), text,
                         se = TRUE)
  expect_equal(out$.emoji_n, 1L)
  expect_equal(out$.emoji_n_scored, 0L)
  expect_true(is.na(out$.emoji_sentiment_se))
  # and se = TRUE is refused for a lexicon that has no counts at all
  register_emoji_lexicon("no-counts", data.frame(emoji = laugh, score = 1))
  expect_error(
    emoji_sentiment(data.frame(text = laugh), text, lexicon = "no-counts",
                    se = TRUE),
    "annotation counts"
  )
})


# ---------------------------------------------------------------------------
# The output-contract invariant, asserted over every verb at once.
# `?tidyEmoji` promises "every verb ... returns a tibble", and
# emoji_extract_nest() was the one row verb that did not go through
# .emoji_as_tibble(), so it handed back a plain data.frame for a plain
# data.frame input. Nothing compared the verbs to each other, so it stood.
# ---------------------------------------------------------------------------

data_first_verbs <- function() {
  ns <- asNamespace("tidyEmoji")
  Filter(function(n) {
    f <- get(n, envir = ns)
    is.function(f) && identical(head(names(formals(f)), 2L), c("data", "text"))
  }, sort(getNamespaceExports("tidyEmoji")))
}

call_verb <- function(name, d) {
  f <- get(name, envir = asNamespace("tidyEmoji"))
  if (name %in% c("emoji_trend", "emoji_turnover", "emoji_seasonality",
                  "emoji_adoption_lag")) {
    f(d, text, when)
  } else if (name %in% c("emoji_incongruity", "emoji_congruence",
                         "emoji_incongruity_profile")) {
    f(d, text, sc, scale = "none")
  } else {
    f(d, text)
  }
}

contract_fixture <- function() {
  data.frame(
    text = c(paste("hi", laugh), "plain"),
    sc = c(1, 0),
    when = as.Date(c("2020-01-01", "2020-02-01")),
    stringsAsFactors = FALSE
  )
}

test_that("every data-first verb returns a tibble", {
  d <- contract_fixture()
  verbs <- data_first_verbs()
  expect_gt(length(verbs), 30L)
  offenders <- character()
  for (n in verbs) {
    out <- suppressWarnings(call_verb(n, d))
    if (!inherits(out, "tbl_df")) offenders <- c(offenders, n)
  }
  expect_identical(offenders, character())
})

test_that("a grouped input keeps its grouping through the row verbs", {
  d <- dplyr::group_by(cbind(contract_fixture(), g = c("a", "b")), g)
  row_verbs <- c("emoji_sentiment", "emoji_position", "emoji_ratio",
                 "emoji_density", "emoji_type", "emoji_faceness",
                 "emoji_risk", "emoji_token_cost", "emoji_score",
                 "emoji_extract_nest", "emoji_filter", "emoji_categorize",
                 "emoji_tokens")
  for (n in row_verbs) {
    out <- suppressWarnings(call_verb(n, d))
    expect_true(dplyr::is_grouped_df(out), info = n)
    expect_identical(dplyr::group_vars(out), "g", info = n)
  }
})

test_that("row verbs add only dotted columns and summaries use bare names", {
  d <- contract_fixture()
  for (n in c("emoji_sentiment", "emoji_position", "emoji_ratio",
              "emoji_density", "emoji_type", "emoji_faceness", "emoji_risk",
              "emoji_token_cost", "emoji_score", "emoji_emotion",
              "emoji_extract_nest")) {
    added <- setdiff(names(call_verb(n, d)), names(d))
    expect_true(all(grepl("^[.]", added)), info = n)
  }
  for (n in c("emoji_summary", "emoji_frequency", "top_n_emojis",
              "emoji_version_profile")) {
    out <- suppressWarnings(call_verb(n, d))
    expect_length(grep("^[.]", names(out)), 0L)
  }
})

# ---------------------------------------------------------------------------
# Cost invariants. Two hot paths took character substrings at a growing offset,
# which rescans a multi-byte string from its first byte every time and made
# emoji-dense rows quadratic. Both now switch to code-point indexing past a
# threshold, and emoji_context() reads a bounded slice anchored at the glyph
# instead of the whole prefix. Timing assertions would be flaky on CI, so what
# is pinned here is the thing that could actually break: the fast paths must
# return exactly what the slow paths returned.
# ---------------------------------------------------------------------------

test_that(".emoji_slice agrees with substring() on both sides of the threshold", {
  unit <- paste0("w ", "\U0001F602", " x ",
                 "\U0001F468\u200D\U0001F469\u200D\U0001F467", " y ",
                 "\U0001F1EC\U0001F1E7", " z 1\uFE0F\u20E3 ")
  thr <- tidyEmoji:::.emoji_cp_threshold
  for (k in c(4L, 100L, thr %/% 4L, thr %/% 4L + 1L, thr)) {
    s <- strrep(unit, k)
    m <- tidyEmoji:::.emoji_locations(s)[[1L]]
    expect_identical(
      tidyEmoji:::.emoji_slice(m, s),
      substring(s, m[, "start"], m[, "end"]),
      info = paste("k =", k, "glyphs =", nrow(m))
    )
  }
  # the threshold really is crossed by the fixtures above, or this proves nothing
  expect_gte(nrow(tidyEmoji:::.emoji_locations(strrep(unit, thr))[[1L]]), thr)
})

test_that(".emoji_slice falls back when utf8ToInt() cannot represent the string", {
  l1 <- "caf\xe9 na\xefve"
  Encoding(l1) <- "latin1"
  m <- tidyEmoji:::.emoji_locations(l1)[[1L]]
  expect_identical(tidyEmoji:::.emoji_slice(m, l1), character(0))
  # a latin1 string cannot carry emoji, but the verbs must still read it
  d <- data.frame(text = c(l1, paste("hi", "\U0001F602")), stringsAsFactors = FALSE)
  expect_identical(emoji_sentiment(d, text)$.emoji_n, c(0L, 1L))
  expect_true(grepl("caf", emoji_sanitize(d, text)$text[1], fixed = TRUE))
})

test_that(".emoji_window_at equals the window taken from the whole side", {
  A <- "\U0001F602"
  fixtures <- c(
    paste("aaa", A, "bbb", A, "ccc"),
    paste0(A, strrep(" ", 400L), "tail"),
    paste0("lead", strrep(" ", 400L), A),
    paste0("alpha beta", strrep(" ", 2000L), A, " tail"),
    strrep(A, 40L),
    paste(rep(paste("word", A), 60L), collapse = " "),
    paste0("   ", A, "   "),
    A
  )
  for (s in fixtures) {
    locs <- tidyEmoji:::.emoji_locations(s)
    masked <- tidyEmoji:::.emoji_mask(s, locs)
    occ <- tidyEmoji:::.emoji_occurrences(s)
    for (unit in c("word", "char")) {
      for (window in c(0L, 1L, 2L, 5L, 13L)) {
        for (i in seq_len(nrow(occ))) {
          expect_identical(
            tidyEmoji:::.emoji_window_at(
              masked[1L], 1L, occ$.position[i] - 1L, window, unit, "left"
            ),
            tidyEmoji:::.emoji_window(
              substr(masked[1L], 1L, occ$.position[i] - 1L), window, unit, "left"
            )
          )
          expect_identical(
            tidyEmoji:::.emoji_window_at(
              masked[1L], occ$.end[i] + 1L, nchar(masked[1L]), window, unit,
              "right"
            ),
            tidyEmoji:::.emoji_window(
              substr(masked[1L], occ$.end[i] + 1L, nchar(masked[1L])), window,
              unit, "right"
            )
          )
        }
      }
    }
  }
})

test_that("verb output does not depend on which slicing path ran", {
  unit <- paste0("w ", "\U0001F602", " x ",
                 "\U0001F468\u200D\U0001F469\u200D\U0001F467", " y ",
                 "\U0001F1EC\U0001F1E7", " z ")
  thr <- tidyEmoji:::.emoji_cp_threshold
  below <- strrep(unit, 8L)                    # substring path
  above <- strrep(unit, thr %/% 3L + 4L)       # code-point path
  d_lo <- data.frame(text = below, stringsAsFactors = FALSE)
  d_hi <- data.frame(text = above, stringsAsFactors = FALSE)
  expect_lt(length(tidyEmoji:::emoji_glyph_list(below)[[1L]]), thr)
  expect_gte(length(tidyEmoji:::emoji_glyph_list(above)[[1L]]), thr)

  # the glyph sequence is the same unit repeated, so the distinct glyphs and
  # their cycle must match whichever path produced them
  expect_identical(
    unique(tidyEmoji:::emoji_glyph_list(below)[[1L]]),
    unique(tidyEmoji:::emoji_glyph_list(above)[[1L]])
  )
  # and every repetition must translate to the same text
  tr <- function(x) {
    parts <- strsplit(emoji_to_text(x, text)$text, "w ", fixed = TRUE)[[1L]]
    unique(parts[nzchar(parts)])
  }
  expect_length(tr(d_lo), 1L)
  expect_length(tr(d_hi), 1L)
  expect_identical(tr(d_lo), tr(d_hi))

  # counts stay exactly proportional to the number of repetitions
  n_lo <- emoji_sentiment(d_lo, text)$.emoji_n
  n_hi <- emoji_sentiment(d_hi, text)$.emoji_n
  expect_identical(n_lo, 3L * 8L)
  expect_identical(n_hi, 3L * (thr %/% 3L + 4L))
})

test_that("an emoji-dense row is handled exactly, not just quickly", {
  A <- "\U0001F602"
  m <- 2000L
  d <- data.frame(text = paste(rep(paste("word", A), m), collapse = " "),
                  stringsAsFactors = FALSE)
  expect_identical(emoji_sentiment(d, text)$.emoji_n, m)
  ctx <- emoji_context(d, text, window = 1L)
  expect_identical(nrow(ctx), as.integer(m))
  # every window is the neighbouring word, never a fragment of a masked glyph
  expect_true(all(ctx$.emoji_context_right[-m] == "word"))
  expect_true(all(ctx$.emoji_context_left == "word"))
  expect_identical(unique(ctx$.emoji), A)
})

test_that(".emoji_gaps cuts the same stretches its three callers used to cut", {
  A <- "\U0001F602"
  fixtures <- c(
    paste("aaa", A, "bbb", A, "ccc"),
    paste0(A, "x", A),
    A,
    paste0("  ", A, "  "),
    strrep(A, 3L),
    paste("caf\u00E9 na\u00EFve", A, "end")
  )
  for (s in fixtures) {
    m <- tidyEmoji:::.emoji_locations(s)[[1L]]
    if (!nrow(m)) next
    gaps <- tidyEmoji:::.emoji_gaps(s, m)
    # the reference is the per-gap substr() each caller used before
    ref <- c(
      substr(s, 1L, m[1L, "start"] - 1L),
      if (nrow(m) > 1L) {
        vapply(2:nrow(m),
               function(k) substr(s, m[k - 1L, "end"] + 1L, m[k, "start"] - 1L),
               character(1))
      } else {
        character(0)
      },
      substr(s, m[nrow(m), "end"] + 1L, nchar(s))
    )
    expect_identical(gaps, ref, info = s)
    expect_length(gaps, nrow(m) + 1L)
    # gaps interleaved with glyphs must rebuild the string exactly
    glyphs <- tidyEmoji:::.emoji_slice(m, s)
    expect_identical(
      paste0(as.vector(rbind(gaps, c(glyphs, ""))), collapse = ""), s
    )
  }
})

test_that(".emoji_gaps agrees with substring() past the threshold", {
  unit <- paste0("w ", "\U0001F602", " x ", "\U0001F1EC\U0001F1E7", " y ")
  thr <- tidyEmoji:::.emoji_cp_threshold
  for (k in c(8L, thr %/% 2L + 4L)) {
    s <- strrep(unit, k)
    m <- tidyEmoji:::.emoji_locations(s)[[1L]]
    expect_identical(
      tidyEmoji:::.emoji_gaps(s, m),
      substring(s, c(1L, m[, "end"] + 1L), c(m[, "start"] - 1L, nchar(s))),
      info = paste("glyphs =", nrow(m))
    )
  }
  expect_gte(nrow(tidyEmoji:::.emoji_locations(strrep(unit, thr %/% 2L + 4L))[[1L]]), thr)
})

test_that("the trailing-emoji run is unchanged by the shared gap helper", {
  A <- "\U0001F602"
  H <- "\U0001F621"
  v <- c(paste("great news", A, H), paste("great", A, "news"),
         paste("mixed", A, "x", H), paste0("only ", A), "no emoji",
         paste("three", A, H, A))
  # a run is the trailing emoji separated from each other only by whitespace;
  # "mixed" stops the walk at the last glyph because "x" separates the pair
  expect_identical(lengths(tidyEmoji:::.emoji_final_glyphs(v)),
                   c(2L, 0L, 1L, 1L, 0L, 3L))
})

# ---------------------------------------------------------------------------
# Composition invariants. Every earlier round tested verbs one at a time; these
# compose two and assert an algebraic property of the pair. The shortcode round
# trip is the strongest one available: it runs over the entire catalogue, and
# what it must preserve is the code-point key, not the bytes.
# ---------------------------------------------------------------------------

test_that("the shortcode round trip preserves every emoji in the catalogue", {
  ref <- tidyEmoji:::emoji_reference()
  d <- data.frame(text = ref$emoji, stringsAsFactors = FALSE)
  sc <- emoji_to_text(d, text, format = "shortcode")$text
  back <- text_to_emoji(data.frame(text = sc, stringsAsFactors = FALSE), text)$text

  # the key is preserved for every single entry -- no glyph becomes a
  # different emoji, which byte comparison alone would not distinguish from
  # the U+FE0F normalisation below
  expect_identical(tidyEmoji:::emoji_key(back), tidyEmoji:::emoji_key(ref$emoji))
  expect_false(anyNA(tidyEmoji:::emoji_key(back)))

  # the only byte-level difference anywhere is the presence of U+FE0F: strip
  # it from both sides and the round trip is the identity on all 5042 entries
  strip <- function(x) gsub("\uFE0F", "", x, fixed = TRUE)
  expect_identical(strip(back), strip(ref$emoji))
  expect_gt(mean(back == ref$emoji), 0.75)

  # and the result is a fixed point: a second round trip changes nothing
  sc2 <- emoji_to_text(data.frame(text = back, stringsAsFactors = FALSE), text,
                       format = "shortcode")$text
  back2 <- text_to_emoji(data.frame(text = sc2, stringsAsFactors = FALSE), text)$text
  expect_identical(back2, back)
})

test_that("colliding names and shortcodes only ever share a code-point key", {
  ref <- tidyEmoji:::emoji_reference()
  d <- data.frame(text = ref$emoji, stringsAsFactors = FALSE)
  for (fmt in c("name", "shortcode")) {
    lab <- emoji_to_text(d, text, format = fmt)$text
    dup <- unique(lab[duplicated(lab)])
    # two glyphs may share a label, but only if they are the same emoji
    for (x in dup) {
      expect_length(unique(tidyEmoji:::emoji_key(ref$emoji[lab == x])), 1L)
    }
  }
})

test_that("the text-rewriting verbs are idempotent", {
  ref <- tidyEmoji:::emoji_reference()
  mix <- data.frame(
    text = c(paste("hi", ref$emoji[1], "there"), "plain text",
             paste0(ref$emoji[2], ref$emoji[3]),
             paste("mixed :smile: and", ref$emoji[9]),
             NA_character_, ""),
    stringsAsFactors = FALSE
  )
  for (v in c("emoji_sanitize", "emoji_to_text", "text_to_emoji")) {
    f <- get(v, envir = asNamespace("tidyEmoji"))
    once <- f(mix, text)
    expect_identical(f(once, text)$text, once$text, info = v)
  }
})

test_that("emoji_dfm folds presentation variants into one column", {
  ref <- tidyEmoji:::emoji_reference()
  pair <- ref$emoji[tidyEmoji:::emoji_key(ref$emoji) == "2764"]
  skip_if(length(pair) < 2L, "catalogue has no U+2764 variant pair")
  d <- data.frame(id = seq_along(pair[1:2]), text = pair[1:2],
                  stringsAsFactors = FALSE)
  w <- emoji_dfm(d, text, id)
  # one id column plus exactly one emoji column, not two
  expect_identical(ncol(w), 2L)
  expect_false(any(duplicated(names(w))))
})

test_that("relational verbs agree arithmetically with the per-row count", {
  A <- "\U0001F602"
  B <- "\U0001F621"
  C <- "\U0001F60D"
  d <- data.frame(
    id = 1:6,
    text = c(paste("a", A, "b", B, "c"), paste(A, A, A), paste("only", C),
             "no emoji here", paste(A, B, C), NA_character_),
    stringsAsFactors = FALSE
  )
  k <- emoji_sentiment(d, text)$.emoji_n

  # emoji_dfm(): the row sums are the row's emoji count, variants folded
  w <- emoji_dfm(d, text, id)
  rs <- as.integer(rowSums(as.matrix(w[, setdiff(names(w), "id"), drop = FALSE])))
  expect_identical(rs, as.integer(k[match(w$id, d$id)]))

  # emoji_pairs(): a document with j distinct emoji contributes choose(j, 2)
  glyphs <- tidyEmoji:::emoji_glyph_list(d$text)
  j <- vapply(glyphs,
              function(g) length(unique(tidyEmoji:::emoji_canonical(g))),
              integer(1))
  pr <- emoji_pairs(d, text, doc_id = id)
  expect_identical(sum(pr$n), as.integer(sum(choose(j, 2))))

  # emoji_ngrams(): max(k - n + 1, 0) per row, and no n-gram spans two rows
  for (nn in 2:4) {
    ng <- emoji_ngrams(d, text, n = nn)
    expect_identical(nrow(ng), sum(pmax(k - (nn - 1L), 0L)),
                     info = paste("n =", nn))
    if (nrow(ng)) {
      own <- vapply(seq_len(nrow(ng)), function(i) {
        parts <- strsplit(ng$.emoji_ngram[i], " ", fixed = TRUE)[[1L]]
        all(parts %in% tidyEmoji:::emoji_canonical(glyphs[[ng$.row_number[i]]]))
      }, logical(1))
      expect_true(all(own), info = paste("n =", nn))
    }
  }
})

test_that("every policy that rewrites emoji away composes to zero emoji", {
  A <- "\U0001F602"
  d <- data.frame(
    text = c(paste("a", A, "b"), paste(A, A), "no emoji", "", NA_character_),
    stringsAsFactors = FALSE
  )
  before <- emoji_sentiment(d, text)$.emoji_n
  expect_true(any(before > 0L))

  # "keep" is the default and must leave the text -- and so the count -- alone
  expect_identical(emoji_sanitize(d, text, policy = "keep")$text, d$text)
  expect_identical(emoji_sentiment(emoji_sanitize(d, text, policy = "keep"),
                                   text)$.emoji_n, before)

  for (pol in c("strip", "name", "placeholder", "shortcode")) {
    out <- emoji_sanitize(d, text, policy = pol)
    expect_identical(emoji_sentiment(out, text)$.emoji_n,
                     rep(0L, nrow(d)), info = pol)
  }
  for (fmt in c("name", "shortcode")) {
    out <- emoji_to_text(d, text, format = fmt)
    expect_identical(emoji_sentiment(out, text)$.emoji_n,
                     rep(0L, nrow(d)), info = fmt)
  }
})

test_that("every ratio column stays inside its documented range", {
  ref <- tidyEmoji:::emoji_reference()
  d <- data.frame(
    text = c(ref$emoji[1:300],
             paste(ref$emoji[1:150], ref$emoji[151:300]),
             "plain", "", NA_character_,
             paste0(ref$emoji[5], " x"), paste0("x ", ref$emoji[5])),
    stringsAsFactors = FALSE
  )
  in_range <- function(x, lo, hi) {
    x <- x[!is.na(x)]
    expect_true(length(x) > 0L)
    expect_gte(min(x), lo)
    expect_lte(max(x), hi)
  }
  in_range(emoji_ratio(d, text)$.emoji_ratio, 0, 1)
  in_range(emoji_position(d, text)$.emoji_rel_position, 0, 1)
  dens <- emoji_density(d, text)
  in_range(dens$.emoji_per_char, 0, 1)
  in_range(dens$.emoji_per_token, 0, 1)
  in_range(emoji_faceness(d, text)$.emoji_faceness, 0, 1)
  in_range(emoji_sentiment(d, text)$.emoji_sentiment, -1, 1)
  # entropy is in nats, so its ceiling is log(3) -- not 1
  risk <- emoji_risk(d, text)
  in_range(risk$.emoji_ambiguity_mean, 0, log(3))
  in_range(risk$.emoji_ambiguity_max, 0, log(3))
})

test_that("as_emoji() resolves an undelimited string by Unicode name first", {
  ref <- tidyEmoji:::emoji_reference()
  both <- intersect(ref$name, ref$shortcode[!is.na(ref$shortcode)])
  # the two namespaces genuinely overlap, or this test proves nothing
  expect_gt(length(both), 100L)

  by_name <- ref$emoji[match(both, ref$name)]
  by_short <- ref$emoji[match(both, ref$shortcode)]
  disagree <- tidyEmoji:::emoji_key(by_name) != tidyEmoji:::emoji_key(by_short)

  # documented precedence: an exact name match wins over a shortcode alias
  expect_identical(tidyEmoji:::emoji_key(as_emoji(both)),
                   tidyEmoji:::emoji_key(by_name))

  # the worked example from the documentation
  expect_identical(tidyEmoji:::emoji_key(as_emoji("dog")), "1F415")
  expect_identical(
    tidyEmoji:::emoji_key(
      text_to_emoji(data.frame(text = ":dog:", stringsAsFactors = FALSE),
                    text)$text
    ),
    "1F436"
  )

  # where the namespaces agree -- the large majority -- both paths must too
  agree <- both[!disagree]
  via_verb <- text_to_emoji(
    data.frame(text = paste0(":", agree, ":"), stringsAsFactors = FALSE), text
  )$text
  expect_identical(tidyEmoji:::emoji_key(as_emoji(agree)),
                   tidyEmoji:::emoji_key(via_verb))
})

test_that("every shortcode and name in the catalogue emojizes to the right emoji", {
  ref <- tidyEmoji:::emoji_reference()

  # names: all 5042, exactly
  gn <- as_emoji(ref$name)
  expect_false(anyNA(gn))
  expect_identical(tidyEmoji:::emoji_key(gn), ref$key)

  # shortcodes through the data-frame verb, which reads them unambiguously as
  # shortcodes -- including the 175 alternate aliases emoji_to_text() never
  # emits, so this covers ground the round-trip test cannot reach
  has_sc <- !is.na(ref$shortcode)
  out <- text_to_emoji(
    data.frame(text = paste0(":", ref$shortcode[has_sc], ":"),
               stringsAsFactors = FALSE), text
  )$text
  expect_false(any(grepl("^:.*:$", out)))
  expect_identical(tidyEmoji:::emoji_key(out), ref$key[has_sc])
})

test_that("the declared R minimum is one the package can actually be installed on", {
  # A declared minimum below what the hard dependencies require is a promise
  # the package cannot keep: install.packages() serves only current versions,
  # so the resolver fetches a dplyr/tidyr that refuses to install and the user
  # gets an opaque dependency failure rather than a clear R-version message.
  # CI cannot catch this -- its oldest job is oldrel-1, far above the floor.
  skip_on_cran()
  r_floor <- function(p) {
    d <- tryCatch(utils::packageDescription(p), error = function(e) NULL)
    if (is.null(d)) return(NULL)
    txt <- paste(stats::na.omit(c(d$Depends, d$Imports)), collapse = ", ")
    m <- regmatches(txt, regexpr("R \\(>=[^)]*\\)", txt))
    if (!length(m)) return(NULL)
    sub(".*>=[[:space:]]*", "", sub("\\)$", "", m))
  }
  declared <- r_floor("tidyEmoji")
  expect_false(is.null(declared))

  hard <- c("dplyr", "emoji", "lifecycle", "rlang", "tibble", "tidyr")
  floors <- unlist(lapply(hard, r_floor))
  skip_if(length(floors) == 0L, "no dependency declares an R floor")

  worst <- floors[order(package_version(floors), decreasing = TRUE)][1L]
  # expect_gte() would try to subtract the two, and `-` is not defined for
  # numeric_version, so compare directly and carry the diagnosis in the message
  expect_true(
    package_version(declared) >= package_version(worst),
    info = paste0("DESCRIPTION declares R >= ", declared,
                  " but the hard dependencies need R >= ", worst)
  )
})

# ---------------------------------------------------------------------------
# State invariants. Every earlier round ran verbs on fresh data in isolation,
# so nothing checked that one call leaves state affecting the next. The package
# keeps a session cache (reference, sentiment, ref_keys, emotion, ambiguity,
# type, lexicons) and a user-writable lexicon registry, so both the cache and
# the registry can in principle make an answer depend on call order.
#
# These tests mutate the registry, which is exactly the leakage they are about,
# so each restores it on exit.
# ---------------------------------------------------------------------------

with_clean_registry <- function(code) {
  cache <- asNamespace("tidyEmoji")$.tidyEmoji_cache
  saved <- cache$lexicons
  on.exit(assign("lexicons", saved, envir = cache), add = TRUE)
  force(code)
}

test_that("a warm cache gives the same answer as a cold one", {
  A <- "\U0001F602"
  B <- "\U0001F621"
  d <- data.frame(
    id = 1:4, text = c(paste("a", A), paste(A, B), "plain", NA_character_),
    sc = c(0.5, -0.5, 0, 0.1), when = as.Date("2020-01-01") + 0:3,
    stringsAsFactors = FALSE
  )
  calls <- list(
    function() emoji_sentiment(d, text), function() emoji_score(d, text),
    function() emoji_emotion(d, text), function() emoji_emotion_label(d, text),
    function() emoji_risk(d, text), function() emoji_ambiguity(),
    function() emoji_type(d, text), function() emoji_faceness(d, text),
    function() emoji_summary(d, text), function() emoji_frequency(d, text),
    function() emoji_tokens(d, text), function() emoji_dfm(d, text, id),
    function() emoji_pairs(d, text, doc_id = id),
    function() emoji_context(d, text), function() emoji_categorize(d, text),
    function() emoji_to_text(d, text), function() emoji_version_profile(d, text),
    function() emoji_trend(d, text, when), function() emoji_search("cat")
  )
  for (i in seq_along(calls)) {
    once <- calls[[i]]()
    expect_identical(calls[[i]](), once, info = paste("call", i))
  }
})

test_that("emoji_ambiguity() does not cache one measure's values for another", {
  # the cached table holds every measure and `measure` selects a column, so
  # asking for two measures in either order must give the same two answers
  g1 <- emoji_ambiguity(measure = "gini")$ambiguity
  e1 <- emoji_ambiguity(measure = "entropy")$ambiguity
  n1 <- emoji_ambiguity(measure = "neutral_share")$ambiguity
  expect_false(identical(g1, e1))
  expect_false(identical(e1, n1))
  expect_false(identical(g1, n1))
  # reverse the order; the values must not move
  expect_identical(emoji_ambiguity(measure = "entropy")$ambiguity, e1)
  expect_identical(emoji_ambiguity(measure = "gini")$ambiguity, g1)
})

test_that("emoji_lexicons() columns carry no element names after registration", {
  with_clean_registry({
    A <- "\U0001F602"
    B <- "\U0001F621"
    own <- data.frame(emoji = c(A, B), score = c(0.9, -0.9),
                      stringsAsFactors = FALSE)
    register_emoji_lexicon("zz_test_lex", own)
    lx <- emoji_lexicons()
    # vapply()/lapply() over the named registry used to return named results,
    # which bind_rows() padded with "" for the bundled rows, so
    # emoji_lexicons()$n printed a stray name header
    for (cc in names(lx)) {
      expect_null(names(lx[[cc]]), info = cc)
    }
    expect_identical(sum(lx$name == "zz_test_lex"), 1L)
  })
})

test_that("no verb returns a column carrying element names", {
  with_clean_registry({
    A <- "\U0001F602"
    B <- "\U0001F621"
    register_emoji_lexicon(
      "zz_test_lex",
      data.frame(emoji = c(A, B), score = c(0.9, -0.9), stringsAsFactors = FALSE)
    )
    d <- data.frame(
      id = 1:4, text = c(paste("a", A), paste(A, B), "plain", NA_character_),
      sc = c(0.5, -0.5, 0, 0.1), when = as.Date("2020-01-01") + 0:3,
      stringsAsFactors = FALSE
    )
    outs <- list(
      emoji_sentiment(d, text), emoji_score(d, text), emoji_emotion(d, text),
      emoji_risk(d, text), emoji_type(d, text), emoji_faceness(d, text),
      emoji_summary(d, text), emoji_frequency(d, text), emoji_tokens(d, text),
      emoji_dfm(d, text, id), emoji_pairs(d, text, doc_id = id),
      emoji_ngrams(d, text), emoji_context(d, text),
      emoji_collocations(d, text), emoji_categorize(d, text),
      emoji_to_text(d, text), text_to_emoji(d, text), emoji_sanitize(d, text),
      emoji_position(d, text), emoji_ratio(d, text), emoji_density(d, text),
      emoji_token_cost(d, text), emoji_extract_nest(d, text),
      emoji_extract_unnest(d, text), emoji_filter(d, text),
      emoji_version_profile(d, text), emoji_unicode_releases(),
      emoji_trend(d, text, when), emoji_turnover(d, text, when),
      emoji_seasonality(d, text, when), emoji_adoption_lag(d, text, when),
      emoji_cooccurrence(d, text, doc_id = id),
      emoji_search("cat"), emoji_lexicons(), emoji_provenance(),
      top_n_emojis(d, text), emoji_flag_ambiguous(d, text), emoji_ambiguity()
    )
    for (i in seq_along(outs)) {
      for (cc in names(outs[[i]])) {
        expect_null(names(outs[[i]][[cc]]),
                    info = paste("output", i, "column", cc))
      }
    }
  })
})

test_that("registering a lexicon leaves every other verb untouched", {
  with_clean_registry({
    A <- "\U0001F602"
    B <- "\U0001F621"
    d <- data.frame(
      text = c(paste("a", A), paste(A, B), "plain", NA_character_),
      stringsAsFactors = FALSE
    )
    snap <- function() {
      list(emoji_sentiment(d, text), emoji_score(d, text),
           emoji_emotion(d, text), emoji_risk(d, text),
           emoji_summary(d, text), emoji_provenance(),
           emoji_tokens(d, text), emoji_ambiguity())
    }
    before <- snap()
    register_emoji_lexicon(
      "zz_test_lex",
      data.frame(emoji = c(A, B), score = c(0.9, -0.9), stringsAsFactors = FALSE)
    )
    expect_identical(snap(), before)
  })
})

test_that("re-registering a name replaces it rather than duplicating it", {
  with_clean_registry({
    A <- "\U0001F602"
    B <- "\U0001F621"
    d <- data.frame(text = paste("a", A), stringsAsFactors = FALSE)
    register_emoji_lexicon(
      "zz_test_lex",
      data.frame(emoji = c(A, B), score = c(0.9, -0.9), stringsAsFactors = FALSE)
    )
    second <- data.frame(emoji = c(A, B), score = c(-0.1, 0.2),
                         stringsAsFactors = FALSE)
    register_emoji_lexicon("zz_test_lex", second)
    expect_identical(sum(emoji_lexicons()$name == "zz_test_lex"), 1L)
    # the replacement's scores are the ones in force
    expect_equal(emoji_score(d, text, lexicon = "zz_test_lex")$.emoji_score,
                 -0.1, tolerance = 1e-12)
    # and naming it is equivalent to passing the same table inline
    expect_identical(emoji_score(d, text, lexicon = "zz_test_lex")$.emoji_score,
                     emoji_score(d, text, lexicon = second)$.emoji_score)
  })
})

test_that("a bundled lexicon name cannot be overridden by registration", {
  with_clean_registry({
    A <- "\U0001F602"
    own <- data.frame(emoji = A, score = 0.9, stringsAsFactors = FALSE)
    for (reserved in c("novak2015", "emotag1200")) {
      expect_error(register_emoji_lexicon(reserved, own), reserved, fixed = TRUE)
    }
  })
})

test_that("a zero-row lexicon behaves exactly like one that matches nothing", {
  with_clean_registry({
    A <- "\U0001F602"
    d <- data.frame(text = c(paste("a", A), "plain"), stringsAsFactors = FALSE)
    register_emoji_lexicon(
      "zz_empty",
      data.frame(emoji = character(0), score = numeric(0),
                 stringsAsFactors = FALSE)
    )
    register_emoji_lexicon(
      "zz_nomatch",
      data.frame(emoji = "\U0001F996", score = 0.5, stringsAsFactors = FALSE)
    )
    a <- emoji_score(d, text, lexicon = "zz_empty")
    b <- emoji_score(d, text, lexicon = "zz_nomatch")
    expect_identical(a$.emoji_score, b$.emoji_score)
    expect_identical(a$.emoji_n_scored, b$.emoji_n_scored)
    # documented convention: 0 scored where there were emoji, NA where none
    expect_identical(a$.emoji_n_scored, c(0L, NA_integer_))
    expect_identical(a$.emoji_n, c(1L, 0L))
  })
})

# ---------------------------------------------------------------------------
# Documentation-surface invariants. R CMD check passes an example that runs,
# whatever it returns, and never executes a \dontrun block at all -- so example
# quality and example coverage are both invisible to a green check.
# ---------------------------------------------------------------------------

test_that("every export is documented with examples, and none are unexecuted", {
  man <- list.files("../../man", pattern = "[.]Rd$", full.names = TRUE)
  skip_if(length(man) == 0L, "man/ not available")
  # \dontrun / \donttest blocks never run under R CMD check, so they rot
  # silently; the package deliberately has none
  for (f in man) {
    txt <- paste(readLines(f, warn = FALSE), collapse = "\n")
    expect_false(grepl("\\dontrun", txt, fixed = TRUE), info = basename(f))
    expect_false(grepl("\\donttest", txt, fixed = TRUE), info = basename(f))
  }
  # and every exported object has an Rd carrying examples
  ns <- asNamespace("tidyEmoji")
  exports <- getNamespaceExports(ns)
  aliases <- unlist(lapply(man, function(f) {
    txt <- readLines(f, warn = FALSE)
    m <- regmatches(txt, regexpr("^\\\\alias\\{[^}]*\\}", txt))
    sub("^\\\\alias\\{", "", sub("\\}$", "", m[nzchar(m)]))
  }))
  has_ex <- unlist(lapply(man, function(f) {
    txt <- readLines(f, warn = FALSE)
    if (!any(grepl("\\examples", txt, fixed = TRUE))) return(character(0))
    m <- regmatches(txt, regexpr("^\\\\alias\\{[^}]*\\}", txt))
    sub("^\\\\alias\\{", "", sub("\\}$", "", m[nzchar(m)]))
  }))
  expect_true(all(exports %in% aliases),
              info = paste("undocumented:",
                           paste(setdiff(exports, aliases), collapse = ", ")))
  expect_true(all(exports %in% has_ex),
              info = paste("no examples:",
                           paste(setdiff(exports, has_ex), collapse = ", ")))
})

test_that("no exported vector or list helper returns a named result", {
  A <- "\U0001F602"
  B <- "\U0001F621"
  # round 38 swept data-frame columns; these return bare vectors and lists,
  # which that sweep could not see. vapply() over a character vector names its
  # result by default, so this is the same defect class one step out.
  expect_null(names(as_emoji_name(c(A, B))))
  expect_null(names(as_emoji_shortcode(c(A, B))))
  expect_null(names(as_emoji(c("grinning", "heart"))))
  expect_null(names(as_emoji_type(c(A, B))))
  expect_null(names(emoji_unicode_version()))
  # list-columns: neither the column nor its elements carry names
  d <- data.frame(text = c(paste("a", A), paste(A, B), "plain"),
                  stringsAsFactors = FALSE)
  nest <- emoji_extract_nest(d, text)$.emoji_unicode
  expect_null(names(nest))
  expect_false(any(vapply(nest, function(x) !is.null(names(x)), logical(1))))
  dims <- emoji_lexicons()$dimensions
  expect_null(names(dims))
  expect_false(any(vapply(dims, function(x) !is.null(names(x)), logical(1))))
})

test_that("emoji_search() agrees with the rest of the package", {
  ref <- tidyEmoji:::emoji_reference()
  res <- do.call(rbind, lapply(c("cat", "heart", "flag", "hand", "dog", "+1"),
                               emoji_search))
  expect_gt(nrow(res), 100L)

  # every glyph search returns is one the rest of the package recognises, and
  # its name is the name the package would give it
  expect_true(all(tidyEmoji:::emoji_key(res$emoji) %in% ref$key))
  expect_identical(tolower(as_emoji_name(res$emoji)), tolower(res$name))

  # the documented way back from `shortcode` recovers every row exactly ...
  sc <- res[!is.na(res$shortcode), ]
  back <- text_to_emoji(
    data.frame(text = paste0(":", sc$shortcode, ":"), stringsAsFactors = FALSE),
    text
  )$text
  expect_identical(tidyEmoji:::emoji_key(back),
                   tidyEmoji:::emoji_key(sc$emoji))

  # ... while as_emoji() differs on exactly the dual-namespace strings, which
  # is documented behaviour rather than a defect
  both <- intersect(ref$name, ref$shortcode[!is.na(ref$shortcode)])
  disagreeing <- both[
    tidyEmoji:::emoji_key(ref$emoji[match(both, ref$name)]) !=
      tidyEmoji:::emoji_key(ref$emoji[match(both, ref$shortcode)])
  ]
  via_as_emoji <- as_emoji(sc$shortcode)
  off <- sc$shortcode[tidyEmoji:::emoji_key(via_as_emoji) !=
                        tidyEmoji:::emoji_key(sc$emoji)]
  expect_true(all(off %in% disagreeing))

  # keyword is "" rather than NA when the match was a name or a shortcode
  expect_false(anyNA(res$keyword))
  expect_true(any(res$keyword == ""))
})

test_that("a version recorded on only one spelling reaches both", {
  ref <- tidyEmoji:::emoji_reference()
  # upstream attaches the introducing version to the unqualified member of a
  # variation pair; the version belongs to the emoji, not to one spelling
  expect_false(anyNA(ref$version))
  qualified_heart <- "\U00002764\U0000FE0F"
  unqualified_heart <- "\U00002764"
  expect_identical(
    ref$version[match(qualified_heart, ref$emoji)],
    ref$version[match(unqualified_heart, ref$emoji)]
  )
  # and generally: every key resolves to exactly one version
  per_key <- tapply(ref$version, ref$key, function(v) length(unique(v)))
  expect_true(all(as.integer(per_key) == 1L))

  # the filler preserves the column's own spelling rather than reformatting
  expect_true(is.character(ref$version))
  expect_true("12.1" %in% ref$version)

  # emoji_version_profile() therefore has no unknown bucket, and still
  # accounts for exactly the glyphs detection found
  d <- data.frame(text = ref$emoji, stringsAsFactors = FALSE)
  vp <- emoji_version_profile(d, text)
  expect_false(anyNA(vp$version))
  expect_identical(sum(vp$n_tokens), sum(emoji_sentiment(d, text)$.emoji_n))
  expect_true(all(vp$version %in% emoji_unicode_releases()$version))
})

test_that(".emoji_fill_by_key only fills gaps and never overwrites", {
  f <- tidyEmoji:::.emoji_fill_by_key
  # a gap is filled from a sibling under the same key
  expect_identical(f(c("0.6", NA), c("2764", "2764")), c("0.6", "0.6"))
  # existing values are left exactly as they are
  expect_identical(f(c("0.6", "1.0"), c("a", "b")), c("0.6", "1.0"))
  # unrelated keys do not donate
  expect_identical(f(c("0.6", NA), c("a", "b")), c("0.6", NA))
  # all-NA key groups stay NA rather than erroring
  expect_identical(f(c(NA_character_, NA_character_), c("a", "a")),
                   c(NA_character_, NA_character_))
  # with nothing missing the input comes back untouched
  expect_identical(f(c("1.0", "2.0"), c("a", "a")), c("1.0", "2.0"))
  # the earliest version wins if a key ever carries two
  expect_identical(f(c("13.1", "5.0", NA), c("k", "k", "k")),
                   c("13.1", "5.0", "5.0"))
})

# ---------------------------------------------------------------------------
# Ordering invariants. Several verbs order by a count or a score, and CI runs
# five platforms without ever comparing their outputs to each other -- so a
# tie order that fell back on input order, a hash, or the session's collation
# would let every job pass while producing different results on each. Round 33
# checked that output is independent of input row order; these check the harder
# case, ties *within* an equal key, and that the tie is settled by a stable
# documented secondary key rather than by accident.
# ---------------------------------------------------------------------------

# five emoji, each appearing exactly twice, so `n` is a five-way tie
.tie_glyphs <- c("\U0001F602", "\U0001F60D", "\U0001F621", "\U0001F44D",
                 "\U0001F525")
.tie_data <- function(perm) {
  txt <- unlist(lapply(perm, function(i) {
    c(paste("a", .tie_glyphs[i]), paste("b", .tie_glyphs[i]))
  }))
  data.frame(id = seq_along(txt), text = txt, stringsAsFactors = FALSE)
}

test_that("counting verbs settle ties by the glyph, in the C locale", {
  d1 <- .tie_data(1:5)
  d2 <- .tie_data(c(5L, 3L, 1L, 4L, 2L))
  d3 <- .tie_data(c(2L, 4L, 5L, 1L, 3L))

  f1 <- emoji_frequency(d1, text)
  expect_identical(f1$n, rep(2L, 5L))
  # documented: descending n, ties broken by the glyph. With every n equal the
  # whole order is the tie-break, so this pins the rule exactly.
  expect_identical(f1$emoji, sort(.tie_glyphs, method = "radix"))
  # and it does not move when the input rows are permuted
  expect_identical(emoji_frequency(d2, text), f1)
  expect_identical(emoji_frequency(d3, text), f1)

  # emoji_dfm(): descending column total, ties by glyph, C locale
  w1 <- emoji_dfm(d1, text, id)
  glyph_cols <- setdiff(names(w1), "id")
  totals <- colSums(as.matrix(w1[, glyph_cols, drop = FALSE]))
  expect_identical(unname(totals), rep(2, 5))
  expect_identical(glyph_cols, sort(.tie_glyphs, method = "radix"))
  expect_identical(names(emoji_dfm(d2, text, id)), names(w1))
})

test_that("top_n_emojis cuts a straddling tie by the glyph and never pads", {
  d1 <- .tie_data(1:5)
  d2 <- .tie_data(c(5L, 3L, 1L, 4L, 2L))
  ordered <- sort(.tie_glyphs, method = "radix")
  for (k in c(1L, 2L, 3L, 5L)) {
    t1 <- top_n_emojis(d1, text, n = k)
    expect_identical(nrow(t1), k, info = paste("n =", k))
    # the cut falls where the glyph order says it does
    expect_identical(t1$unicode, ordered[seq_len(k)], info = paste("n =", k))
    expect_identical(top_n_emojis(d2, text, n = k), t1, info = paste("n =", k))
  }
  # fewer distinct emoji than asked for: return them all, do not pad
  wide <- top_n_emojis(d1, text, n = 7L)
  expect_identical(nrow(wide), 5L)
  expect_identical(wide$unicode, ordered)
})

test_that("emoji_ambiguity ranks ties with the minimum and skips accordingly", {
  a <- emoji_ambiguity()
  scorable <- a[!is.na(a$ambiguity), ]
  expect_gt(nrow(scorable), 900L)

  # documented: rank 1 is most ambiguous, tied glyphs share the lowest rank of
  # their group, and the next distinct value skips by the group's size
  expect_identical(min(scorable$rank), 1L)
  expect_false(is.unsorted(scorable$rank))
  tab <- table(scorable$rank)
  groups <- as.integer(names(tab)[tab > 1L])
  expect_gt(length(groups), 10L)
  for (r in groups) {
    later <- scorable$rank[scorable$rank > r]
    if (!length(later)) next
    expect_identical(min(later), r + as.integer(tab[as.character(r)]),
                     info = paste("rank", r))
  }
  # a shared rank means ranks are not consecutive -- the ties.method = "min"
  # tell, and the thing "average" or "first" would change
  expect_false(identical(sort(unique(scorable$rank)),
                         seq_along(unique(scorable$rank))))

  # within one tie group the glyph order is the C-locale one
  biggest <- groups[which.max(tab[as.character(groups)])]
  grp <- scorable$emoji[scorable$rank == biggest]
  expect_identical(grp, sort(grp, method = "radix"))

  # and the whole table is reproducible call to call
  expect_identical(emoji_ambiguity(), a)
})

test_that("relational and ambiguity verbs hold their order under permutation", {
  E <- .tie_glyphs
  d <- data.frame(
    id = 1:6,
    text = c(paste(E[1], E[2]), paste(E[2], E[3]), paste(E[3], E[1]),
             paste(E[4], E[5]), paste(E[5], E[4]), paste(E[1], E[3])),
    stringsAsFactors = FALSE
  )
  shuffled <- d[c(6L, 1L, 4L, 2L, 5L, 3L), , drop = FALSE]

  for (verb in c("emoji_pairs", "emoji_cooccurrence")) {
    f <- get(verb, envir = asNamespace("tidyEmoji"))
    o <- f(d, text, doc_id = id)
    expect_gt(nrow(o), 0L)
    expect_identical(f(shuffled, text, doc_id = id), o, info = verb)
    # documented tie-break on the `sort` argument: descending n, then item1,
    # item2 -- so equal-n blocks are in C-locale item order
    ties <- o$n == o$n[1]
    expect_identical(o$item1[ties], sort(o$item1[ties], method = "radix"),
                     info = verb)
  }

  fa <- emoji_flag_ambiguous(.tie_data(1:5), text)
  expect_identical(emoji_flag_ambiguous(.tie_data(c(5L, 3L, 1L, 4L, 2L)), text),
                   fa)
  # documented: descending ambiguity, then descending n, then the glyph
  expect_false(is.unsorted(rev(fa$ambiguity)))
  expect_false(anyNA(fa$rank))
})

# ---------------------------------------------------------------------------
# Locale invariants for case folding. Round 33 established that ordering does
# not depend on LC_COLLATE; nothing varied LC_CTYPE, which governs case
# conversion. tolower() honours it, and under a Turkish or Azerbaijani locale
# maps "I" to a dotless i (U+0131), so every case-insensitive comparison in the
# package could change answer with the session locale rather than the data.
#
# The contract tests below always run. The cross-locale ones need tr_TR
# installed, which not every CI platform has, so they skip when it cannot be
# set rather than passing vacuously.
# ---------------------------------------------------------------------------

with_ctype <- function(loc, code) {
  old <- Sys.getlocale("LC_CTYPE")
  ok <- suppressWarnings(Sys.setlocale("LC_CTYPE", loc))
  if (!nzchar(ok)) {
    return(structure(list(), class = "ctype_unavailable"))
  }
  on.exit(Sys.setlocale("LC_CTYPE", old), add = TRUE)
  force(code)
}

test_that(".emoji_fold folds ASCII deterministically and non-ASCII like tolower", {
  f <- tidyEmoji:::.emoji_fold
  expect_identical(f("I"), "i")
  expect_identical(f("SMILING"), "smiling")
  expect_identical(f("Smiling"), "smiling")
  expect_identical(f("smiling"), "smiling")
  expect_identical(f("+1"), "+1")
  # non-ASCII is still folded, so a query matching a catalogue name that
  # carries a tilde or a typographic apostrophe keeps working
  expect_identical(f("VICU\u00D1A"), "vicu\u00F1a")
  expect_identical(f("O\u2019CLOCK"), "o\u2019clock")
  # NA in, NA out
  expect_identical(f(NA_character_), NA_character_)
  expect_identical(f(character(0)), character(0))

  # and over the whole catalogue it agrees with tolower() in this locale, so
  # the switch is not a behaviour change for ASCII/Western sessions
  e <- emoji::emojis
  expect_identical(f(e$name), tolower(e$name))
  expect_identical(f(unlist(e$keywords)), tolower(unlist(e$keywords)))
  expect_identical(f(unlist(e$aliases)), tolower(unlist(e$aliases)))
})

test_that(".emoji_fold does not depend on LC_CTYPE", {
  probe <- c("I", "SMILING", "FIRE", "INDIA", "VICU\u00D1A", "O\u2019CLOCK",
             "\u0130stanbul")
  here <- tidyEmoji:::.emoji_fold(probe)
  there <- with_ctype("tr_TR.utf8", tidyEmoji:::.emoji_fold(probe))
  skip_if(inherits(there, "ctype_unavailable"), "tr_TR.utf8 not available")

  # the mechanism really is live on this machine, or the test proves nothing
  turkish_tolower <- with_ctype("tr_TR.utf8", tolower("I"))
  expect_false(identical(turkish_tolower, "i"))

  expect_identical(there, here)
  expect_identical(there[1], "i")
})

test_that("emoji_search() returns the same rows whatever LC_CTYPE is", {
  queries <- c("I", "SMILING", "FIRE", "INDIA", "VIOLIN", "HEART", "smiling")
  here <- lapply(queries, emoji_search)
  there <- with_ctype("tr_TR.utf8", lapply(queries, emoji_search))
  skip_if(inherits(there, "ctype_unavailable"), "tr_TR.utf8 not available")
  for (i in seq_along(queries)) {
    expect_identical(there[[i]], here[[i]], info = queries[i])
    expect_gt(nrow(here[[i]]), 0L)
  }
})

test_that("emoji_collocations() unifies case the same way in every locale", {
  A <- "\U0001F602"
  d <- data.frame(
    text = c(paste("BIG win", A), paste("big WIN", A),
             paste("India", A, "trip")),
    stringsAsFactors = FALSE
  )
  here <- emoji_collocations(d, text, min_n = 1)
  there <- with_ctype("tr_TR.utf8", emoji_collocations(d, text, min_n = 1))
  skip_if(inherits(there, "ctype_unavailable"), "tr_TR.utf8 not available")
  # "BIG" and "big" must be one word, not two spellings
  expect_identical(sort(here$word), c("big", "india", "trip", "win"))
  expect_identical(there, here)
})

test_that("nothing in R/ folds case with tolower() outside .emoji_fold", {
  files <- list.files("../../R", pattern = "[.]R$", full.names = TRUE)
  skip_if(length(files) == 0L, "package sources not available")
  offenders <- character(0)
  for (f in files) {
    lines <- readLines(f, warn = FALSE)
    code <- lines[!grepl("^\\s*#", lines)]
    hits <- grep("tolower\\(|toupper\\(|casefold\\(|ignore\\.case", code)
    for (i in hits) {
      # the single legitimate call is the one inside .emoji_fold()
      if (grepl("chartr", code[i], fixed = TRUE)) next
      offenders <- c(offenders, paste0(basename(f), ": ", trimws(code[i])))
    }
  }
  expect_identical(offenders, character(0))
})
