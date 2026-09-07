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
  # Rows holding *two* emoji, because emoji_pairs() and emoji_cooccurrence()
  # pair within a row: over `d`, where every row has one emoji, both return
  # zero rows and the snapshot field was character(0). It compared equal to
  # itself in every locale and so asserted nothing about their ordering.
  dp <- data.frame(text = c(paste0(A, B), paste0(B, C), paste0(A, C),
                            paste0(A, B, C)))
  # Words whose relative order genuinely moves between collations -- the old
  # fixture was `paste("good", ...)`, so the word column was three copies of
  # "good" and no permutation of it could differ either. base::sort() on
  # these six gives aardvark,chleb,hlava,zebra,ase,oun under C and
  # chleb,hlava,oun,zebra,aardvark,ase under da_DK, which is what gives the
  # comparison teeth (asserted below, so a fixture that stops being
  # collation-sensitive fails rather than passing quietly).
  cw <- c("zebra", "\u00e5se", "aardvark", "\u00f5un", "chleb", "hlava")
  dw <- data.frame(text = paste(cw, rep(c(A, B, C), each = 2L)))
  dt <- data.frame(text = d$text,
                   when = as.Date("2024-01-15") + c(0L, 40L, 200L))
  dv <- data.frame(text = c(A, "\U0001F600", "\U0001F97A"))
  # Each verb is called once and several columns read off the result: the
  # previous shape called emoji_search("hand") three times and six other
  # verbs twice, over 9 locales, which is 8.9s of the suite for no extra
  # coverage.
  snapshot <- function() {
    se <- emoji_search("hand")
    fr <- emoji_frequency(d, text)
    pr <- emoji_pairs(dp, text)
    co <- emoji_cooccurrence(dp, text)
    cl <- emoji_collocations(dw, text, min_n = 1)
    tk <- emoji_tokens(d, text)
    tr <- emoji_trend(dt, text, when, by = "month")
    al <- emoji_adoption_lag(dt, text, when)
    list(
      search     = se$emoji,
      search_sc  = se$shortcode,
      search_nm  = se$name,
      topn       = top_n_emojis(d, text)$unicode,
      topn_dup   = top_n_emojis(d, text, duplicated = TRUE)$emoji_name,
      frequency  = fr$emoji,
      freq_group = fr$group,
      ambiguity  = head(emoji_ambiguity()$emoji, 30),
      flagged    = emoji_flag_ambiguous(d, text)$emoji,
      lexicons   = emoji_lexicons()$name,
      releases   = emoji_unicode_releases()$version,
      categories = emoji_categorize(d, text)$.emoji_category,
      pairs      = paste(pr$item1, pr$item2),
      cooc       = paste(co$item1, co$item2),
      dfm_cols   = names(emoji_dfm(d, text)),
      dfm_rows   = as.character(emoji_dfm(
        data.frame(author = c("zoe", "Adam", "ubu"), text = c(A, B, C)),
        text, doc_id = author)[[1]]),
      ngrams     = emoji_ngrams(data.frame(text = paste0(A, B, C)), text)$.emoji_ngram,
      shortcodes = emoji_to_text(d, text, format = "shortcode")$text,
      collocs    = cl$word,
      colloc_emo = cl$emoji,
      tokens     = tk$.emoji,
      tokens_nm  = tk$.emoji_name,
      unnest     = emoji_extract_unnest(d, text)$.emoji_unicode,
      types      = emoji_type(d, text)$.emoji_type,
      # `d`'s three glyphs all shipped in Emoji 0.6, so over `d` this field
      # is a single value and cannot be re-ordered; dv spans 0.6, 1.0 and 11.0
      verprofile = emoji_version_profile(dv, text)$version,
      trend      = tr$emoji,
      trend_per  = as.character(tr$.period),
      turnover   = as.character(emoji_turnover(dt, text, when,
                                               by = "month")$.period),
      season     = emoji_seasonality(dt, text, when,
                                     period = "month")$.period_label,
      adoption   = al$emoji,
      adopt_nm   = al$name
    )
  }
  old <- Sys.getlocale("LC_COLLATE")
  on.exit(suppressWarnings(Sys.setlocale("LC_COLLATE", old)), add = TRUE)
  baseline <- snapshot()
  # No field may be empty or constant: either makes its comparison vacuous,
  # which is exactly how `pairs` and `collocs` went years without testing
  # anything.
  vacuous <- names(baseline)[vapply(
    baseline, function(x) length(x) == 0L || length(unique(x)) == 1L,
    logical(1))]
  expect_identical(vacuous, character())

  tried <- character()
  # C and en_US order these glyphs identically, so the old pair could not
  # have caught a collation bug even in a field that was populated.
  # Danish puts a-ring after z, Czech puts ch after h, Estonian puts z before
  # o-tilde: three genuinely different answers about the fixture words, where
  # C and en_US agree with each other.
  for (loc in c("C", "en_US.UTF-8", "en_US.utf8", "da_DK.utf8", "cs_CZ.utf8",
                "et_EE.utf8")) {
    available <- tryCatch({
      suppressWarnings(Sys.setlocale("LC_COLLATE", loc))
      identical(Sys.getlocale("LC_COLLATE"), loc)
    }, error = function(e) FALSE)
    if (!available) next
    tried <- c(tried, loc)
    expect_identical(snapshot(), baseline)
  }
  skip_if(length(tried) == 0L, "no alternative collation available")

  # The fixture words must actually re-order under some locale we reached,
  # or none of the above proves anything about collation.
  reorders <- FALSE
  for (loc in setdiff(tried, "C")) {
    if (!identical(suppressWarnings(Sys.setlocale("LC_COLLATE", "C")), "C")) break
    ref <- sort(cw)
    if (!identical(suppressWarnings(Sys.setlocale("LC_COLLATE", loc)), loc)) next
    if (!identical(sort(cw), ref)) {
      reorders <- TRUE
      break
    }
  }
  skip_if(!reorders, "no reached locale re-orders the fixture words")
  expect_true(reorders)
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
  # assert the loop has something to iterate over: an empty `everywhere` would
  # skip the body and leave the documented consequence untested while the test
  # still passed -- the shape that left emoji_pairs()'s collation untested for
  # a whole release
  expect_length(everywhere, 1L)
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
  path <- pkg_text_file("NEWS.md")
  skip_if(is.na(path), "NEWS.md not available")
  headings <- grep("^# ", readLines(path, warn = FALSE), value = TRUE)
  expect_gt(length(headings), 0L)
  # every top-level heading is "# tidyEmoji <version>"
  expect_true(all(grepl("^# tidyEmoji [0-9]+([.][0-9]+)+$", headings)))
  versions <- sub("^# tidyEmoji ", "", headings)
  expect_equal(anyDuplicated(versions), 0L)
  # newest first, and the version under development leads
  expect_identical(versions, as.character(sort(package_version(versions),
                                               decreasing = TRUE)))
  desc <- read.dcf(pkg_text_file("DESCRIPTION"))
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
  if (length(files)) {
    expect_identical(basename(files[vapply(files, non_ascii_bytes,
                                           logical(1))]),
                     character())
  }
  # and from the namespace, so this also runs inside R CMD check where the
  # source tree is absent
  code <- pkg_code_text()
  bad <- names(code)[vapply(code, function(x) {
    any(utf8ToInt(enc2utf8(x)) > 127L)
  }, logical(1))]
  expect_identical(bad, character(0))
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
  # the message names what is accepted and what was passed; it used to offer
  # "or NULL for the default", which the same guard rejects (round 82)
  expect_error(emoji_score(df, text, lexicon = 42),
               "must be a single lexicon name or a data frame")
  expect_error(emoji_score(df, text, lexicon = 42), "numeric of length 1")
  # the mirror of emoji_sentiment()'s emotion case: name the shape passed and
  # the verb that takes it, not just what this verb wants (round 82)
  expect_error(emoji_emotion(df, text, lexicon = "novak2015"),
               "is a sentiment lexicon")
  expect_error(emoji_emotion(df, text, lexicon = "novak2015"),
               "emoji_sentiment()", fixed = TRUE)
  # and a data frame with neither emotion columns nor a glyph column still
  # gets the generic requirement message
  expect_error(emoji_emotion(df, text, lexicon = data.frame(x = 1, joy = 1)),
               "needs an `emoji` column")
  expect_error(register_emoji_lexicon("bad-tbl", "not a data frame"),
               "must be a data frame")
  expect_error(register_emoji_lexicon("bad-col", data.frame(x = 1, score = 2)),
               "has no column")
  # a data-frame lexicon with no usable score column, used directly. The
  # message names `lexicon`, the argument the caller typed -- not `tbl`, which
  # is what the shared helper's own formal is called.
  expect_error(emoji_score(df, text, lexicon = data.frame(emoji = laugh)),
               "`lexicon` has no score column")
  # and a named score column that is not there: the message names `lexicon`
  # and the column that is missing
  expect_error(
    emoji_score(df, text, lexicon = data.frame(emoji = laugh, s = 1),
                score = "nope"),
    "`lexicon` has no column `nope` to take the score from"
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
    # as above: no duplicates would mean this test asserted nothing
    expect_gt(length(dup), 100L)
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
  man <- rd_all()
  skip_if(length(man) == 0L, "installed help database not available")
  # \dontrun / \donttest blocks never run under R CMD check, so they rot
  # silently; the package deliberately has none
  for (nm in names(man)) {
    expect_false(grepl("\\dontrun", man[[nm]], fixed = TRUE), info = nm)
    expect_false(grepl("\\donttest", man[[nm]], fixed = TRUE), info = nm)
  }
  # and every exported object has an Rd carrying examples
  ns <- asNamespace("tidyEmoji")
  exports <- getNamespaceExports(ns)
  alias_of <- function(txt) {
    m <- unlist(regmatches(txt, gregexpr("\\\\alias\\{[^}]*\\}", txt)))
    sub("^\\\\alias\\{", "", sub("\\}$", "", m))
  }
  aliases <- unlist(lapply(man, alias_of), use.names = FALSE)
  has_ex <- unlist(lapply(man, function(txt) {
    if (!grepl("\\examples", txt, fixed = TRUE)) return(character(0))
    alias_of(txt)
  }), use.names = FALSE)
  expect_gt(length(aliases), length(exports))
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

# A locale that can be *set* but does not change case folding proves nothing:
# a cross-locale test then compares two identical results and reports a pass.
# Windows accepts "tr_TR.utf8" and goes on folding "I" to "i", so gate on the
# observable behaviour, not on whether the locale is settable. An inert
# platform skips with a stated reason; it never reports a vacuous pass.
skip_unless_dotless_i <- function(loc = "tr_TR.utf8") {
  probe <- with_ctype(loc, tolower("I"))
  skip_if(inherits(probe, "ctype_unavailable"), paste(loc, "cannot be set"))
  skip_if(identical(probe, "i"),
          paste0("this platform's tolower() does not apply the ",
                 "Turkish dotless-i rule"))
  invisible(TRUE)
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
  skip_unless_dotless_i()
  expect_identical(there, here)
  expect_identical(there[1], "i")
})

test_that("emoji_search() returns the same rows whatever LC_CTYPE is", {
  queries <- c("I", "SMILING", "FIRE", "INDIA", "VIOLIN", "HEART", "smiling")
  here <- lapply(queries, emoji_search)
  there <- with_ctype("tr_TR.utf8", lapply(queries, emoji_search))
  skip_unless_dotless_i()
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
  skip_unless_dotless_i()
  # "BIG" and "big" must be one word, not two spellings
  expect_identical(sort(here$word), c("big", "india", "trip", "win"))
  expect_identical(there, here)
})

test_that("nothing in R/ folds case with tolower() outside .emoji_fold", {
  files <- list.files("../../R", pattern = "[.]R$", full.names = TRUE)
  if (!length(files)) {
    # inside R CMD check the sources are gone; scan the namespace instead,
    # which is where the calls actually are
    code <- pkg_code_text()
    hits <- names(code)[vapply(code, function(x) {
      grepl("tolower\\(|toupper\\(|casefold\\(|ignore\\.case", x)
    }, logical(1))]
    expect_identical(setdiff(hits, c(".emoji_fold", "emoji_search",
                                     ".emoji_type_of", "emoji_collocations")),
                     character(0))
    skip("package sources not available; scanned the namespace instead")
  }
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

# ---------------------------------------------------------------------------
# Calendar invariants. Round 33 established that .emoji_as_date() reads POSIXt
# in local time rather than UTC, and that ordering is timezone-invariant.
# Nothing tested the calendar itself: a spring-forward day is 23 hours long, an
# autumn-back day 25 with one local hour occurring twice, and February has 29
# days every fourth year. Those are the classic sources of a dropped or
# duplicated bucket.
#
# Fixtures carry tz = "America/Chicago" explicitly, so they do not depend on
# the ambient TZ, and the gate below skips rather than passing vacuously if a
# platform does not apply DST for that zone.
# ---------------------------------------------------------------------------

skip_unless_dst_live <- function(tz = "America/Chicago") {
  # 2024-11-03 01:30 occurs twice in Chicago: once in CDT, once in CST. If the
  # platform's zoneinfo lacks the rule, both render alike and the test proves
  # nothing.
  a <- as.POSIXct(1730615400, origin = "1970-01-01", tz = tz)
  b <- as.POSIXct(1730619000, origin = "1970-01-01", tz = tz)
  same_hour <- identical(format(a, "%H"), format(b, "%H"))
  differ <- !identical(format(a, "%Z"), format(b, "%Z"))
  skip_if(!(same_hour && differ),
          paste0(tz, ": this platform does not apply the DST rule"))
  invisible(TRUE)
}

test_that("a 23-hour day is still one day", {
  skip_unless_dst_live()
  A <- "\U0001F602"
  tz <- "America/Chicago"
  # 02:00 does not exist on 2024-03-10 in Chicago
  w <- as.POSIXct(c("2024-03-10 00:30:00", "2024-03-10 01:30:00",
                    "2024-03-10 03:30:00", "2024-03-10 13:30:00",
                    "2024-03-11 01:30:00"), tz = tz)
  d <- data.frame(text = paste("x", A), when = w, stringsAsFactors = FALSE)

  tr <- emoji_trend(d, text, when, by = "day")
  expect_identical(sort(unique(as.character(tr$.period))),
                   c("2024-03-10", "2024-03-11"))
  expect_identical(sum(tr$n), nrow(d))

  # the hour grid is complete and holds the true local hours, not UTC ones
  se <- emoji_seasonality(d, text, when, period = "hour")
  expect_identical(nrow(se), 24L)
  expect_identical(sum(se$n_emoji), nrow(d))
  expect_identical(as.integer(se$.period[se$n_emoji > 0]), c(0L, 1L, 3L, 13L))
})

test_that("a 25-hour day is one day, and its repeated hour is one bucket", {
  skip_unless_dst_live()
  A <- "\U0001F602"
  tz <- "America/Chicago"
  # 01:30 CDT and 01:30 CST are different instants with the same local hour
  w <- as.POSIXct(c(1730615400, 1730619000, 1730622600, 1730626200),
                  origin = "1970-01-01", tz = tz)
  d <- data.frame(text = paste("x", A), when = w, stringsAsFactors = FALSE)
  expect_identical(format(w[1], "%H"), format(w[2], "%H"))
  expect_false(identical(format(w[1], "%Z"), format(w[2], "%Z")))

  tr <- emoji_trend(d, text, when, by = "day")
  expect_identical(unique(as.character(tr$.period)), "2024-11-03")
  expect_identical(sum(tr$n), nrow(d))

  se <- emoji_seasonality(d, text, when, period = "hour")
  expect_identical(sum(se$n_emoji), nrow(d))
  # both 01:30s land in hour 1 -- neither dropped nor split
  expect_identical(se$n_emoji[as.integer(se$.period) == 1L], 2L)
})

test_that("emoji_trend() fills a complete grid across calendar boundaries", {
  A <- "\U0001F602"
  tz <- "America/Chicago"
  spans <- list(
    month = c("2024-01-30", "2024-02-02"),
    year  = c("2023-12-30", "2024-01-02"),
    leap  = c("2024-02-27", "2024-03-02"),
    feb   = c("2023-02-26", "2023-03-02")
  )
  for (nm in names(spans)) {
    days <- seq(as.Date(spans[[nm]][1]), as.Date(spans[[nm]][2]), by = "day")
    d <- data.frame(
      text = paste("x", A),
      when = as.POSIXct(paste(days, "12:00:00"), tz = tz),
      stringsAsFactors = FALSE
    )
    for (by in c("day", "week", "month")) {
      tr <- emoji_trend(d, text, when, by = by)
      per <- as.character(tr$.period)
      expect_false(any(duplicated(unique(per))), info = paste(nm, by))
      # no emoji is lost or double-counted by the bucketing
      expect_identical(sum(tr$n), nrow(d), info = paste(nm, by))
    }
    # one bucket per calendar day, so a leap day is neither skipped nor doubled
    tr_day <- emoji_trend(d, text, when, by = "day")
    expect_identical(sort(unique(as.character(tr_day$.period))),
                     as.character(days), info = nm)
  }

  # The real completeness property: every period x emoji cell exists, with an
  # explicit zero where that emoji did not occur, so a caller can plot a series
  # without filling gaps. Periods themselves are the observed ones, not a
  # synthetic calendar sequence.
  B <- "\U0001F621"
  d2 <- data.frame(
    text = c(paste("x", A), paste("y", B), paste("z", A)),
    when = as.Date(c("2024-02-28", "2024-02-29", "2024-03-01")),
    stringsAsFactors = FALSE
  )
  tr2 <- emoji_trend(d2, text, when, by = "day")
  expect_identical(nrow(tr2),
                   length(unique(tr2$.period)) * length(unique(tr2$emoji)))
  expect_identical(sum(tr2$n), 3L)
  expect_identical(sum(tr2$n == 0L), 3L)
  # the leap day is one of the observed periods, carrying its own emoji
  expect_true("2024-02-29" %in% as.character(tr2$.period))
  expect_identical(tr2$n[as.character(tr2$.period) == "2024-02-29" &
                           tr2$emoji == B], 1L)
  # and February 2024 really does have 29 days, or the leap span proves nothing
  expect_true("2024-02-29" %in%
                as.character(seq(as.Date("2024-02-27"),
                                 as.Date("2024-03-02"), by = "day")))
})

test_that("emoji_adoption_lag() counts calendar days, not 365-day years", {
  H <- "\U00002764\U0000FE0F"
  d <- data.frame(text = paste("love", H),
                  when = as.POSIXct("2024-03-01 12:00:00",
                                    tz = "America/Chicago"),
                  stringsAsFactors = FALSE)
  al <- emoji_adoption_lag(d, text, when)
  expect_identical(nrow(al), 1L)
  # the span crosses four leap days, so a 365-based difference would be short
  expect_identical(
    as.numeric(al$lag_days[1]),
    as.numeric(as.Date(al$first_seen[1]) - as.Date(al$release_date[1]))
  )
  expect_false(is.na(al$lag_days[1]))
})

# ---------------------------------------------------------------------------
# Provenance invariants. The package states facts about its bundled data in six
# independent places -- emoji_provenance(), emoji_lexicons(), DESCRIPTION's
# Description field, the roxygen in R/data.R, inst/CITATION and
# cran-comments.md -- and nothing had ever cross-checked them against each
# other or against the data. The numbers below are the ones the documentation
# states, so if the data changes these fail and the prose has to be updated
# with them.
# ---------------------------------------------------------------------------

test_that("the lexicon sizes the documentation states are the data's", {
  # ?emoji_sentiment_lexicon and ?emoji_emotion_lexicon
  expect_identical(nrow(emoji_sentiment_lexicon), 969L)
  expect_identical(nrow(emoji_emotion_lexicon), 150L)
  # "3790 distinct codepoint keys", quoted in both help pages
  expect_identical(length(unique(tidyEmoji:::emoji_reference()$key)), 3790L)
  # ?category_unicode_crosswalk: "The Unicode category (10 categories)"
  expect_identical(nrow(category_unicode_crosswalk), 10L)

  # emoji_lexicons() must not drift from nrow()
  lx <- emoji_lexicons()
  expect_identical(lx$n[lx$name == "novak2015"], nrow(emoji_sentiment_lexicon))
  expect_identical(lx$n[lx$name == "emotag1200"], nrow(emoji_emotion_lexicon))
})

test_that("the documented coverage figures are the ones the data gives", {
  ref <- tidyEmoji:::emoji_reference()
  keys <- unique(ref$key)
  sl_keys <- tidyEmoji:::emoji_key(emoji_sentiment_lexicon$emoji)

  # ?emoji_sentiment_lexicon: 969 rows, 736 resolving, the other 233 not in the
  # reference table. The three have to add up, or the paragraph is wrong -- it
  # was: it read "969 rows, covering about 19%", and 969/3790 is 25.6%.
  expect_identical(sum(sl_keys %in% keys), 736L)
  expect_identical(sum(!(sl_keys %in% keys)), 233L)
  expect_identical(736L + 233L, nrow(emoji_sentiment_lexicon))
  expect_equal(round(100 * 736 / length(keys)), 19)

  # and the verb really scores that many of the detectable emoji
  d <- data.frame(text = ref$emoji[!duplicated(ref$key)],
                  stringsAsFactors = FALSE)
  scored <- emoji_sentiment(d, text)$.emoji_n_scored
  expect_identical(sum(scored > 0, na.rm = TRUE), 736L)

  # ?emoji_emotion_lexicon: "150 glyphs, about 4%" -- every row resolves here,
  # which is why that one needs no 736-style decomposition
  el_keys <- emoji_emotion_lexicon$key
  expect_identical(sum(!(el_keys %in% keys)), 0L)
  expect_equal(round(100 * nrow(emoji_emotion_lexicon) / length(keys)), 4)
})

test_that("DESCRIPTION, emoji_lexicons() and the help pages name one licence each", {
  # DESCRIPTION is available from the installed package, so this genuinely
  # compares two independent sources rather than restating one of them
  desc <- utils::packageDescription("tidyEmoji")$Description
  expect_false(is.null(desc))
  expect_true(nzchar(desc))
  for (claim in c("CC BY-SA 4.0", "10.1371/journal.pone.0144296",
                  "MIT", "2020.emnlp-main.720")) {
    expect_true(grepl(claim, desc, fixed = TRUE), info = claim)
  }

  lx <- emoji_lexicons()
  expect_identical(lx$licence[lx$name == "novak2015"], "CC BY-SA 4.0")
  expect_identical(lx$licence[lx$name == "emotag1200"], "MIT")
  # the citation in emoji_lexicons()$source agrees with DESCRIPTION's
  expect_true(grepl("e0144296", lx$source[lx$name == "novak2015"], fixed = TRUE))
  expect_true(grepl("2015", lx$source[lx$name == "novak2015"], fixed = TRUE))
  expect_true(grepl("2020", lx$source[lx$name == "emotag1200"], fixed = TRUE))
  # only user-registered lexicons may have no licence
  expect_false(anyNA(lx$licence[lx$type != "custom"]))
})

test_that("emoji_provenance() agrees with every source it reports", {
  pv <- emoji_provenance()
  expect_identical(nrow(pv), 1L)
  expect_identical(pv$unicode_emoji, emoji_unicode_version())
  expect_identical(pv$emoji_pkg, as.character(utils::packageVersion("emoji")))
  expect_identical(pv$tidyEmoji,
                   as.character(utils::packageVersion("tidyEmoji")))
  expect_identical(pv$n_emoji, nrow(tidyEmoji:::emoji_reference()))
  # the lexicon strings quote the real row counts, not frozen ones
  expect_true(grepl(nrow(emoji_sentiment_lexicon), pv$sentiment_lexicon,
                    fixed = TRUE))
  expect_true(grepl(nrow(emoji_emotion_lexicon), pv$emotion_lexicon,
                    fixed = TRUE))
})

test_that("the sentiment lexicon's documented formula and ranges hold", {
  sl <- emoji_sentiment_lexicon
  # ?emoji_sentiment_lexicon: "(positive - negative) / occurrences"
  expect_equal(sl$sentiment_score,
               (sl$positive - sl$negative) / sl$occurrences)
  # the annotation counts are a partition of occurrences
  expect_equal(sl$negative + sl$neutral + sl$positive, sl$occurrences)
  # "ranging from -1 (negative) to +1 (positive)"
  expect_gte(min(sl$sentiment_score), -1)
  expect_lte(max(sl$sentiment_score), 1)
  # "position: Mean position of the emoji within its text (0-1)"
  expect_gte(min(sl$position), 0)
  expect_lte(max(sl$position), 1)
  # "sentiment_label is derived from its sign"
  from_sign <- ifelse(sl$sentiment_score > 0, "positive",
                      ifelse(sl$sentiment_score < 0, "negative", "neutral"))
  expect_identical(sl$sentiment_label, from_sign)

  # ?emoji_emotion_lexicon: eight Plutchik dimensions, each 0 to 1
  dims <- c("anger", "anticipation", "disgust", "fear", "joy", "sadness",
            "surprise", "trust")
  expect_true(all(dims %in% names(emoji_emotion_lexicon)))
  vals <- unlist(emoji_emotion_lexicon[dims])
  expect_gte(min(vals), 0)
  expect_lte(max(vals), 1)
  # the documented key column is the package's own codepoint key
  expect_identical(as.character(emoji_emotion_lexicon$key),
                   as.character(tidyEmoji:::emoji_key(emoji_emotion_lexicon$emoji)))
})

test_that("the coverage figures printed in the help pages are the data's", {
  # The round-45 defect went the other way from the tests above: those assert
  # the data has the properties the docs claim, which catches the data
  # drifting. This one builds each figure *from the data* and requires it to
  # appear in the rendered Rd, so editing a number in the help page without
  # the data supporting it fails too. That is the direction the defect took --
  # "969 rows, covering about 19%", where 19% belonged to 736.
  read_rd <- rd_text

  ref <- tidyEmoji:::emoji_reference()
  keys <- length(unique(ref$key))
  sent <- emoji_sentiment_lexicon
  sent_keys <- tidyEmoji:::emoji_key(sent$emoji)
  resolving <- sum(sent_keys %in% ref$key)
  absent <- sum(!(sent_keys %in% ref$key))

  txt <- read_rd("emoji_sentiment_lexicon.Rd")
  for (fig in c(paste(nrow(sent), "rows"),
                paste(resolving, "resolve"),
                paste(absent, "rows"),
                paste(keys, "distinct codepoint keys"))) {
    expect_true(grepl(fig, txt, fixed = TRUE),
                info = paste("not stated in the help page:", fig))
  }
  # the decomposition has to close, or the paragraph contradicts itself
  expect_identical(resolving + absent, nrow(sent))
  # and the percentage quoted is the one the resolving count gives, not the
  # one the row count gives
  expect_identical(round(100 * resolving / keys), 19)
  expect_false(identical(round(100 * nrow(sent) / keys), 19))

  emo <- emoji_emotion_lexicon
  emo_keys <- tidyEmoji:::emoji_key(emo$emoji)
  expect_identical(sum(emo_keys %in% ref$key), nrow(emo))
  expect_true(grepl(paste(nrow(emo), "glyphs"),
                    read_rd("emoji_emotion_lexicon.Rd"), fixed = TRUE))
})

# ---------------------------------------------------------------------------
# Condition invariants. Round 2 established that every verb survives the legal
# but awkward input shapes without erroring. Nobody checked for *warnings*,
# which matters concretely: a user with options(warn = 2) turns any spurious
# warning into an error, and a CRAN reviewer reads them.
#
# Each test below carries a positive control, because a warning collector that
# silently swallows everything reports a clean sweep -- the failure mode this
# loop has now hit six times.
# ---------------------------------------------------------------------------

collect_conditions <- function(f) {
  ws <- character(0)
  res <- withCallingHandlers(
    tryCatch(f(), error = function(e) structure(conditionMessage(e),
                                                class = "collected_error")),
    warning = function(w) {
      ws <<- c(ws, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  list(warnings = ws,
       error = if (inherits(res, "collected_error")) as.character(res) else NULL)
}

test_that("no verb warns on input that is entirely ordinary", {
  A <- "\U0001F602"
  B <- "\U0001F621"
  base <- data.frame(
    id = 1:4,
    text = c(paste("hello", A), "plain words", paste(A, B),
             paste("mix", B, "end")),
    sc = c(0.5, -0.2, 0.1, -0.7),
    dt = as.Date("2024-01-01") + 0:3,
    ts = as.POSIXct("2024-01-01 10:00:00", tz = "America/Chicago") +
      (0:3) * 86400,
    stringsAsFactors = FALSE
  )

  # the collector must be able to see a warning, or a clean sweep proves
  # nothing -- a grouped data frame is documented to warn
  control <- collect_conditions(
    function() emoji_summary(dplyr::group_by(base, id), text)
  )
  expect_length(control$warnings, 1L)

  calls <- function(d) {
    list(
      emoji_summary = function() emoji_summary(d, text),
      emoji_frequency = function() emoji_frequency(d, text),
      emoji_filter = function() emoji_filter(d, text),
      emoji_tokens = function() emoji_tokens(d, text),
      emoji_categorize = function() emoji_categorize(d, text),
      emoji_extract_nest = function() emoji_extract_nest(d, text),
      emoji_extract_unnest = function() emoji_extract_unnest(d, text),
      top_n_emojis = function() top_n_emojis(d, text),
      emoji_sentiment = function() emoji_sentiment(d, text),
      emoji_score = function() emoji_score(d, text),
      emoji_emotion = function() emoji_emotion(d, text),
      emoji_emotion_label = function() emoji_emotion_label(d, text),
      emoji_risk = function() emoji_risk(d, text),
      emoji_flag_ambiguous = function() emoji_flag_ambiguous(d, text),
      emoji_type = function() emoji_type(d, text),
      emoji_faceness = function() emoji_faceness(d, text),
      emoji_sanitize = function() emoji_sanitize(d, text),
      emoji_to_text = function() emoji_to_text(d, text),
      text_to_emoji = function() text_to_emoji(d, text),
      emoji_position = function() emoji_position(d, text),
      emoji_ratio = function() emoji_ratio(d, text),
      emoji_density = function() emoji_density(d, text),
      emoji_token_cost = function() emoji_token_cost(d, text),
      emoji_context = function() emoji_context(d, text),
      emoji_collocations = function() emoji_collocations(d, text),
      emoji_ngrams = function() emoji_ngrams(d, text),
      emoji_pairs = function() emoji_pairs(d, text, doc_id = id),
      emoji_cooccurrence = function() emoji_cooccurrence(d, text, doc_id = id),
      emoji_dfm = function() emoji_dfm(d, text, id),
      emoji_version_profile = function() emoji_version_profile(d, text),
      emoji_incongruity = function() emoji_incongruity(d, text, sc,
                                                       scale = "none"),
      emoji_incongruity_profile = function() emoji_incongruity_profile(
        d, text, sc, scale = "none"),
      emoji_congruence = function() emoji_congruence(d, text, sc,
                                                     scale = "none"),
      emoji_trend_date = function() emoji_trend(d, text, dt),
      emoji_trend_time = function() emoji_trend(d, text, ts),
      emoji_seasonality = function() emoji_seasonality(d, text, ts),
      emoji_turnover = function() emoji_turnover(d, text, dt),
      emoji_adoption_lag = function() emoji_adoption_lag(d, text, dt)
    )
  }
  no_arg <- list(
    emoji_ambiguity = function() emoji_ambiguity(),
    emoji_search = function() emoji_search("cat"),
    emoji_lexicons = function() emoji_lexicons(),
    emoji_provenance = function() emoji_provenance(),
    emoji_unicode_version = function() emoji_unicode_version(),
    emoji_unicode_releases = function() emoji_unicode_releases()
  )

  # every one of these input shapes is legal, so none may warn
  shapes <- list(
    ordinary = base,
    zero_row = base[0, , drop = FALSE],
    all_na = transform(base, text = NA_character_),
    empty_string = transform(base, text = ""),
    factor_text = transform(base, text = factor(base$text)),
    numeric_text = transform(base, text = c(1, 2, 3, 4))
  )
  for (shape in names(shapes)) {
    d <- shapes[[shape]]
    cl <- c(calls(d), if (identical(shape, "ordinary")) no_arg else NULL)
    for (nm in names(cl)) {
      got <- collect_conditions(cl[[nm]])
      expect_identical(got$warnings, character(0),
                       info = paste(shape, nm, paste(got$warnings,
                                                     collapse = " | ")))
      # a verb that errors cannot warn, so "no warnings" would be vacuous
      # without this
      expect_null(got$error, info = paste(shape, nm, got$error))
    }
  }
})

test_that("no deprecation tells the user to report a bug against tidyEmoji", {
  # lifecycle appends "The deprecated feature was likely used in the tidyEmoji
  # package. Please report the issue at ..." whenever it decides the call came
  # from inside the package. For a helper that calls deprecate_warn() on a
  # verb's behalf, the defaults resolve both frames inside tidyEmoji and that
  # line appears -- which is why .emoji_warn_grouped() passes env/user_env.
  # Verified load-bearing: dropping them puts the line back.
  skip_if_not_installed("lifecycle")
  withr_verbose <- options(lifecycle_verbosity = "warning")
  on.exit(options(withr_verbose), add = TRUE)

  A <- "\U0001F602"
  d <- data.frame(id = 1:3,
                  text = c(paste("hi", A), "plain", paste(A, A)),
                  stringsAsFactors = FALSE)

  probes <- list(
    grouped_helper = function() emoji_summary(dplyr::group_by(d, id), text),
    deprecated_arg = function() top_n_emojis(d, text,
                                             duplicated_unicode = TRUE),
    deprecated_verb = function() emoji_tweets(d, text)
  )
  # and the same three reached through a wrapper, which adds a frame between
  # the user and the verb
  wrapped <- list(
    grouped_helper = function() (function(x) emoji_summary(
      dplyr::group_by(x, id), text))(d),
    deprecated_arg = function() (function(x) top_n_emojis(
      x, text, duplicated_unicode = TRUE))(d),
    deprecated_verb = function() (function(x) emoji_tweets(x, text))(d)
  )

  for (set in list(direct = probes, wrapped = wrapped)) {
    for (nm in names(set)) {
      got <- collect_conditions(set[[nm]])
      # the positive control: each of these really does warn, so the
      # absence-of-"report" assertion below is not vacuous
      expect_length(got$warnings, 1L)
      expect_false(grepl("report the issue", got$warnings[1], fixed = TRUE),
                   info = paste(nm, got$warnings[1]))
      expect_false(grepl("likely used in the tidyEmoji package",
                         got$warnings[1], fixed = TRUE), info = nm)
      # it names the user's verb, not an internal helper
      expect_false(grepl(".emoji_warn_grouped", got$warnings[1], fixed = TRUE),
                   info = nm)
    }
  }

  # Whether the "report the issue" line appears depends on the frame stack
  # above the call -- it shows when the verb is reached through a function and
  # not when it is called from globalenv, so the message assertions above
  # cannot be relied on to catch a regression under testthat's own stack.
  # Assert the mechanism instead: a helper calling deprecate_warn() on a
  # verb's behalf must pass both frames explicitly, because lifecycle's
  # defaults would resolve them inside tidyEmoji and blame the package.
  helper <- paste(deparse(body(tidyEmoji:::.emoji_warn_grouped)),
                  collapse = " ")
  expect_true(grepl("deprecate_warn", helper, fixed = TRUE))
  expect_true(grepl("env = verb_env", helper, fixed = TRUE))
  expect_true(grepl("user_env = caller_env", helper, fixed = TRUE))
  # the verbs that call deprecate_warn() directly need no such argument,
  # since lifecycle's defaults already point one frame above the verb
  direct_body <- paste(deparse(body(top_n_emojis)), collapse = " ")
  expect_true(grepl("deprecate_warn", direct_body, fixed = TRUE))
})

test_that("a deprecation warns once per session, not once per call", {
  skip_if_not_installed("lifecycle")
  A <- "\U0001F602"
  d <- data.frame(id = 1:3,
                  text = c(paste("hi", A), "plain", paste(A, A)),
                  stringsAsFactors = FALSE)
  # default verbosity dedups by topic, so a loop over rows cannot spam. Use a
  # unique-enough topic by clearing the option to the default first.
  op <- options(lifecycle_verbosity = NULL)
  on.exit(options(op), add = TRUE)
  got <- collect_conditions(function() {
    for (i in 1:5) top_n_emojis(d, text, duplicated_unicode = TRUE)
    invisible(NULL)
  })
  expect_lte(length(got$warnings), 1L)
})

# ---------------------------------------------------------------------------
# Round 46: the two-namespace figures. Three numbers about the name/shortcode
# overlap appear in the help pages -- 464 strings in both namespaces, 17 where
# they disagree, and the share of the catalogue whose bytes survive an
# emojize/demojize round trip -- and none of them was pinned to the data.
#
# The round-trip one was stated as "identical bytes for the 79% that were
# already fully qualified". The share is right; the reason is not, and the
# wrong reason is the dangerous half, because it invites the number being
# "corrected" to the fully-qualified share (3790 / 5042 = 75%) by anyone who
# checks the explanation instead of the claim. Which spelling comes back is
# decided by the shortcode table, not by the input's selectors, so 212
# unqualified entries keep their bytes and 92 qualified ones do not. Pinned
# below in both directions, the same way round 45 pinned "969 rows, covering
# about 19%": derive each figure from the data, then require the rendered Rd
# to state it. ?emoji_search's list of the 17 is also named in full here -- it
# gave 11 of them, punctuated as if that were the set.

test_that("the name/shortcode overlap is 464, and 17 of them disagree", {
  ref <- tidyEmoji:::emoji_reference()
  both <- intersect(unique(ref$name), unique(ref$shortcode))
  expect_identical(length(both), 464L)

  # the disagreement is behavioural, not a property of a lookup table:
  # as_emoji() resolves by Unicode name first, text_to_emoji() by shortcode
  by_name <- as_emoji(both)
  by_code <- text_to_emoji(
    data.frame(t = paste0(":", both, ":"), stringsAsFactors = FALSE), t
  )$t
  differ <- tidyEmoji:::emoji_key(by_name) != tidyEmoji:::emoji_key(by_code)
  expect_identical(sum(differ), 17L)
  expect_identical(
    sort(both[differ]),
    c("calendar", "camel", "cat", "cow", "dog", "horse", "kiss", "mouse",
      "pig", "rabbit", "satellite", "snowman", "sunglasses", "tiger", "train",
      "umbrella", "whale")
  )
  # and on the other 447 the two agree, so "17" is the whole difference
  expect_true(all(tidyEmoji:::emoji_key(by_name[!differ]) ==
                    tidyEmoji:::emoji_key(by_code[!differ])))
  expect_false(anyNA(by_name))
  expect_false(anyNA(by_code))
})

test_that("the documented round-trip byte share is the catalogue's", {
  ref <- tidyEmoji:::emoji_reference()
  d <- data.frame(text = ref$emoji, stringsAsFactors = FALSE)
  round_trip <- text_to_emoji(
    emoji_to_text(d, text, format = "shortcode"), text
  )$text

  # every entry recovers the same emoji ...
  expect_true(all(tidyEmoji:::emoji_key(round_trip) ==
                    tidyEmoji:::emoji_key(ref$emoji)))
  expect_identical(nrow(ref), 5042L)
  # ... and 79% of them recover the same bytes
  same <- round_trip == ref$emoji
  expect_identical(sum(same), 4002L)
  expect_identical(round(100 * mean(same)), 79)
  expect_identical(sum(!same), 1040L)

  # The claim the help page used to make -- that the 79% are "the ones that
  # were already fully qualified" -- is false, and plausible enough that it
  # invites being "corrected" to the fully-qualified share (75%). Pin the two
  # sets apart so neither reading can come back.
  has_fe0f <- vapply(ref$emoji, function(g) 0xFE0F %in% utf8ToInt(g),
                     logical(1), USE.NAMES = FALSE)
  paired <- ref$key %in% ref$key[duplicated(ref$key)]
  fully_qualified <- has_fe0f | !paired
  expect_false(identical(same, fully_qualified))
  expect_identical(sum(same & !fully_qualified), 212L)
  expect_identical(sum(fully_qualified & !same), 92L)
  expect_identical(round(100 * mean(fully_qualified)), 77)
  # and it is not the canonical-spelling share (3790 / 5042) either
  expect_identical(round(100 * length(unique(ref$key)) / nrow(ref)), 75)

  # the two worked examples the details give
  heart <- "\u2764"
  expect_identical(round_trip[match(heart, ref$emoji)], heart)
  sleuth <- "\U0001F575\uFE0F\u200D\u2642"
  i <- match(sleuth, ref$emoji)
  expect_false(is.na(i))
  expect_false(identical(round_trip[i], sleuth))
  expect_identical(round_trip[i], paste0(sleuth, "\uFE0F"))

  # "by U+FE0F alone, never by more" -- the two spellings must share every
  # other code point, or the round trip is losing something
  drop_fe0f <- function(x) {
    vapply(x, function(g) {
      cp <- utf8ToInt(g)
      paste(sprintf("%X", cp[cp != 0xFE0F]), collapse = " ")
    }, character(1), USE.NAMES = FALSE)
  }
  expect_identical(drop_fe0f(round_trip[!same]),
                   drop_fe0f(ref$emoji[!same]))

  # and the canonical spelling of every emoji is byte-exact, which is the
  # denominator ?emoji_sanitize quotes
  canonical <- ref$emoji[!duplicated(ref$key)]
  expect_identical(length(canonical), 3790L)
  canon_rt <- text_to_emoji(
    emoji_to_text(data.frame(text = canonical, stringsAsFactors = FALSE),
                  text, format = "shortcode"), text
  )$text
  expect_identical(canon_rt, canonical)

  # a second pass changes nothing, as the details claim
  twice <- text_to_emoji(
    emoji_to_text(data.frame(text = round_trip, stringsAsFactors = FALSE),
                  text, format = "shortcode"), text
  )$text
  expect_identical(twice, round_trip)
})

test_that("the help pages state the overlap figures the data gives", {
  read_rd <- rd_text

  ref <- tidyEmoji:::emoji_reference()
  both <- intersect(unique(ref$name), unique(ref$shortcode))

  helpers <- read_rd("as_emoji_name.Rd")
  expect_true(grepl(paste(length(both), "strings"), helpers, fixed = TRUE))
  expect_true(grepl(paste("For 17 of those", length(both)), helpers,
                    fixed = TRUE))

  d <- data.frame(text = ref$emoji, stringsAsFactors = FALSE)
  round_trip <- text_to_emoji(
    emoji_to_text(d, text, format = "shortcode"), text
  )$text
  share <- round(100 * mean(round_trip == ref$emoji))
  emojize <- read_rd("text_to_emoji.Rd")
  expect_true(grepl(paste0(share, "%"), emojize, fixed = TRUE))
  expect_true(grepl(paste("all", nrow(ref), "entries"), emojize, fixed = TRUE))
  expect_true(grepl(paste("other", sum(round_trip != ref$emoji)), emojize,
                    fixed = TRUE))

  # ?emoji_search names the 17 in full, so a reader who searched one of them
  # is not left guessing whether their shortcode is in the sample
  search_rd <- read_rd("emoji_search.Rd")
  expect_true(grepl("17 strings", search_rd, fixed = TRUE))
  for (nm in c("calendar", "camel", "cat", "cow", "dog", "horse", "kiss",
               "mouse", "pig", "rabbit", "satellite", "snowman", "sunglasses",
               "tiger", "train", "umbrella", "whale")) {
    expect_true(grepl(paste0("\\code{", nm, "}"), search_rd, fixed = TRUE),
                info = nm)
  }
})

# Four @return sections were quieter than the behaviour they describe. Each of
# these asserts the sentence that was added, so the docs and the code move
# together from here.

test_that("every scoring verb tells 'no emoji' apart from 'none scorable'", {
  # U+1FAE0 (melting face, Unicode 14.0) is detectable but in no bundled
  # lexicon, so it is the row that must score 0 rather than NA
  d <- data.frame(text = c("hi \U0001F600", "plain", "", NA,
                           "\U0001FAE0 unscorable"),
                  stringsAsFactors = FALSE)
  none <- 2:4          # rows with no emoji at all
  unscorable <- 5L     # a row with an emoji no lexicon carries

  for (out in list(emoji_sentiment(d, text),
                   emoji_score(d, text),
                   emoji_emotion(d, text),
                   emoji_emotion_label(d, text),
                   emoji_risk(d, text))) {
    expect_true(all(is.na(out$.emoji_n_scored[none])))
    expect_identical(out$.emoji_n_scored[unscorable], 0L)
    # .emoji_n counts every emoji either way, so the pair is readable
    expect_identical(out$.emoji_n[none], rep(0L, length(none)))
    expect_identical(out$.emoji_n[unscorable], 1L)
    expect_identical(out$.emoji_n_scored[1L], 1L)
  }

  # emoji_faceness() runs the same convention on .emoji_n_typed
  fc <- emoji_faceness(d, text)
  expect_true(all(is.na(fc$.emoji_n_typed[none])))
  expect_identical(fc$.emoji_n[none], rep(0L, length(none)))
})

test_that("emoji_ratio() treats empty text as unmeasurable, not emoji-only", {
  d <- data.frame(text = c("\U0001F600", "", " ", NA, "no"),
                  stringsAsFactors = FALSE)
  out <- emoji_ratio(d, text)
  expect_identical(out$.emoji_ratio[1L], 1)
  # no characters to take a share of
  expect_true(is.na(out$.emoji_ratio[2L]))
  expect_true(is.na(out$.emoji_ratio[4L]))
  # ... but an empty string is not a row of emoji
  expect_false(out$.emoji_only[2L])
  expect_false(out$.emoji_only[3L])
  expect_true(is.na(out$.emoji_only[4L]))
  expect_true(out$.emoji_only[1L])
  # whitespace-only text has characters, so its ratio is a real 0
  expect_identical(out$.emoji_ratio[3L], 0)
})

test_that("emoji_pairs(sort = FALSE) is ordered, just not by n", {
  A <- "\U0001F600"; B <- "\U0001F525"; C <- "\U0001F389"
  d <- data.frame(text = c(paste0(A, B), paste0(A, B), paste0(B, C)),
                  stringsAsFactors = FALSE)
  unsorted <- emoji_pairs(d, text, sort = FALSE)
  # item1 then item2, in the C locale -- not counting order, and not by n
  expect_identical(unsorted,
                   dplyr::arrange(unsorted, item1, item2))
  expect_false(identical(unsorted$n, sort(unsorted$n, decreasing = TRUE)))
  # and the sorted form leads with the pair seen twice
  expect_identical(emoji_pairs(d, text)$n[1L], 2L)
  # emoji_cooccurrence() inherits the same parameter and the same rule
  expect_identical(emoji_cooccurrence(d, text, sort = FALSE), unsorted)
})

test_that("as_emoji_shortcode() is keyed on the emoji, emoji_search() on the row", {
  ref <- tidyEmoji:::emoji_reference()

  # 344 keys carry a different first alias on each of their two spellings, and
  # the qualified (RGI) spelling wins every time -- which is what makes one
  # shortcode per emoji possible at all
  per_key <- tapply(ref$shortcode, ref$key,
                    function(v) length(unique(v)))
  conflicting <- names(per_key)[!is.na(per_key) & per_key > 1L]
  expect_identical(length(conflicting), 344L)
  winner_is_qualified <- vapply(conflicting, function(k) {
    i <- which(ref$key == k)[1L]
    0xFE0F %in% utf8ToInt(ref$emoji[i])
  }, logical(1), USE.NAMES = FALSE)
  expect_true(all(winner_is_qualified))

  # so for 175 rows the key-collapsed answer is not the row's own first alias
  via_key <- as_emoji_shortcode(ref$emoji)
  differs <- !is.na(ref$shortcode) & !is.na(via_key) &
    ref$shortcode != via_key
  expect_identical(sum(differs), 175L)
  # the worked example the help page gives
  bare <- "\u2764"
  qualified <- "\u2764\uFE0F"
  expect_identical(as_emoji_shortcode(bare), "heart")
  expect_identical(as_emoji_shortcode(qualified), "heart")
  expect_identical(ref$shortcode[match(bare, ref$emoji)], "red_heart")

  # both spellings of a key always agree, which is the property the round trip
  # relies on
  expect_identical(via_key, via_key[match(ref$key, ref$key)])

  # and the disagreement really is cosmetic: every shortcode either verb can
  # report resolves back to the same emoji
  for (sc in list(ref$shortcode[differs], via_key[differs])) {
    back <- text_to_emoji(
      data.frame(t = paste0(":", sc, ":"), stringsAsFactors = FALSE), t
    )$t
    # nothing was left as an unresolved token ...
    expect_false(any(back == paste0(":", sc, ":")))
    # ... and every one lands on the emoji it came from
    expect_identical(tidyEmoji:::emoji_key(back),
                     tidyEmoji:::emoji_key(ref$emoji[differs]))
  }

  # 189 catalogue rows carry no alias at all. emoji_search() reports NA for
  # them -- which is why its details cannot promise that every row's shortcode
  # round trips -- while as_emoji_shortcode() answers for all 189, borrowing
  # the alias of the glyph's other spelling.
  no_alias <- vapply(emoji::emojis$aliases, function(a) !length(a), logical(1))
  expect_identical(sum(no_alias), 189L)
  expect_false(anyNA(as_emoji_shortcode(emoji::emojis$emoji[no_alias])))

  hit <- emoji_search("face")
  expect_gt(nrow(hit), 0L)
  expect_identical(sum(is.na(hit$shortcode)), 7L)
  expect_true(all(hit$emoji[is.na(hit$shortcode)] %in%
                    emoji::emojis$emoji[no_alias]))

  # every non-NA shortcode a search reports is a token text_to_emoji() reads,
  # and it recovers that row's emoji
  named <- hit[!is.na(hit$shortcode), , drop = FALSE]
  recovered <- text_to_emoji(
    data.frame(t = paste0(":", named$shortcode, ":"),
               stringsAsFactors = FALSE), t
  )$t
  expect_false(any(recovered == paste0(":", named$shortcode, ":")))
  expect_identical(tidyEmoji:::emoji_key(recovered),
                   tidyEmoji:::emoji_key(named$emoji))
})

# ---------------------------------------------------------------------------
# Round 47: `scale = "rank"` / `"zscore"` in the mismatch verbs were computed
# over each side's own non-missing rows. `text_score` is normally present on
# every row while the emoji score is missing wherever a row has no scorable
# emoji, so the two percentiles referred to different populations and rows that
# contribute nothing to the result -- their own gap being NA -- moved the
# answer for the rows that do. `scale = "none"` was never affected, which is
# why every existing test passed.

test_that("rows with no scorable emoji cannot move the scaled gap", {
  # 100 rows whose emoji sentiment IS their text score, so the true gap is 0
  # for every one of them under any scale
  lex <- emoji_sentiment_lexicon
  ref <- tidyEmoji:::emoji_reference()
  k <- tidyEmoji:::emoji_key(lex$emoji)
  keep <- k %in% ref$key
  g <- ref$emoji[match(k[keep], ref$key)]
  s <- lex$sentiment_score[keep]
  o <- order(s, method = "radix")
  sel <- round(seq(1, length(g), length.out = 100))
  emo <- g[o][sel]
  emo_s <- s[o][sel]

  scored <- data.frame(text = paste("msg", emo), score = emo_s,
                       stringsAsFactors = FALSE)
  # ... plus 100 rows with no emoji at all, whose text scores sit far above
  # the emoji range, so any leakage shows up as a large offset
  padded <- rbind(scored,
                  data.frame(text = rep("plain text", 100),
                             score = seq(5, 15, length.out = 100),
                             stringsAsFactors = FALSE))

  for (sc in c("none", "rank", "zscore")) {
    alone <- emoji_incongruity(scored, text, score, scale = sc)
    with_pad <- emoji_incongruity(padded, text, score, scale = sc)

    # the truth: emoji and text agree exactly, so the gap is 0
    expect_equal(alone$.emoji_incongruity, rep(0, 100), info = sc)
    expect_equal(with_pad$.emoji_incongruity[1:100], rep(0, 100), info = sc)
    # nothing is flagged as incongruent either way
    expect_false(any(alone$.emoji_incongruent), info = sc)
    expect_false(any(with_pad$.emoji_incongruent[1:100], na.rm = TRUE),
                 info = sc)
    # the unscorable rows stay NA, and the scored rows are untouched by them
    expect_true(all(is.na(with_pad$.emoji_incongruity[101:200])), info = sc)
    expect_identical(with_pad$.emoji_incongruity[1:100],
                     alone$.emoji_incongruity, info = sc)
  }
})

test_that("subsetting to the scored rows gives the same scaled gap", {
  # the general form of the invariant above, on data where the gap is not
  # constant: dropping rows whose gap is NA must not change any other row
  set.seed(11)
  emo <- c("\U0001F600", "\U0001F621", "\U0001F60D", "\U0001F62D")
  txt <- c(paste("a", emo), "plain", paste("b", emo), "nothing here",
           "also plain", paste("c", emo[1:2]))
  d <- data.frame(text = txt,
                  score = seq(-3, 4, length.out = length(txt)),
                  stringsAsFactors = FALSE)

  for (sc in c("none", "rank", "zscore")) {
    for (wh in c("all", "final")) {
      full <- emoji_incongruity(d, text, score, scale = sc, where = wh)
      keep <- !is.na(full$.emoji_incongruity)
      expect_true(any(keep))
      expect_false(all(keep))          # the test would be vacuous otherwise
      sub <- emoji_incongruity(d[keep, , drop = FALSE], text, score,
                               scale = sc, where = wh)
      expect_equal(sub$.emoji_incongruity, full$.emoji_incongruity[keep],
                   info = paste(sc, wh))
      expect_identical(sub$.emoji_incongruent, full$.emoji_incongruent[keep],
                       info = paste(sc, wh))
    }
  }

  # and the profile verb, which credits every glyph with its row's gap
  for (sc in c("rank", "zscore")) {
    full <- emoji_incongruity_profile(d, text, score, scale = sc, min_n = 1)
    keep <- !is.na(emoji_incongruity(d, text, score,
                                     scale = sc)$.emoji_incongruity)
    sub <- emoji_incongruity_profile(d[keep, , drop = FALSE], text, score,
                                     scale = sc, min_n = 1)
    expect_equal(full, sub, info = sc)
  }
})

test_that("the unscaled columns are unaffected by `scale`", {
  d <- data.frame(text = c("great \U0001F621", "plain", "awful \U0001F600"),
                  score = c(0.8, 0.2, -0.9), stringsAsFactors = FALSE)
  base <- emoji_incongruity(d, text, score, scale = "none")
  for (sc in c("rank", "zscore")) {
    o <- emoji_incongruity(d, text, score, scale = sc)
    # .emoji_sentiment and the sign-flip flag are computed on the raw scores,
    # where the sign means something, so `scale` must not touch them
    expect_identical(o$.emoji_sentiment, base$.emoji_sentiment, info = sc)
    expect_identical(o$.emoji_polarity_flip, base$.emoji_polarity_flip,
                     info = sc)
    expect_identical(o$.emoji_n, base$.emoji_n, info = sc)
    expect_identical(o$.emoji_n_scored, base$.emoji_n_scored, info = sc)
    # and method = "sign_flip" ignores `scale` entirely
    expect_identical(
      emoji_incongruity(d, text, score, scale = sc,
                        method = "sign_flip")$.emoji_incongruent,
      base$.emoji_polarity_flip, info = sc)
  }
})

test_that("on the rank scale the mean gap over the scored rows is zero", {
  # A structural consequence of ranking both sides over the same rows: two
  # percentile maps of the same population each average to 0, so their
  # difference does. It is the cheapest possible check on the population being
  # right, and it fails loudly under the pre-0.4.0 scaling.
  emo <- c("\U0001F600", "\U0001F621", "\U0001F60D", "\U0001F62D", "\U0001F615")
  d <- data.frame(
    text = c(paste("a", emo), rep("no emoji here", 40),
             paste("b", emo), "plain", paste("c", emo)),
    score = seq(-4, 6, length.out = 5 + 40 + 5 + 1 + 5),
    stringsAsFactors = FALSE
  )
  out <- emoji_incongruity(d, text, score, scale = "rank")
  gap <- out$.emoji_incongruity[!is.na(out$.emoji_incongruity)]
  expect_gt(length(gap), 1L)
  # the unscored rows must outnumber the scored ones, or the check is weak
  expect_gt(sum(is.na(out$.emoji_incongruity)), length(gap))
  expect_equal(mean(gap), 0)

  # the same holds on the z-score scale, for the same reason
  z <- emoji_incongruity(d, text, score, scale = "zscore")$.emoji_incongruity
  expect_equal(mean(z[!is.na(z)]), 0)

  # and it holds with a word-list text scorer of the kind the vignette uses,
  # where most rows score exactly 0 and the ties matter
  pos <- c("love", "great", "best", "happy", "good", "thanks", "beautiful")
  neg <- c("hate", "worst", "bad", "sad", "awful", "sick", "tired")
  txt <- c(paste("love it", emo), paste("worst thing", emo),
           rep("neither", 30), paste("good", emo[1]))
  corpus <- data.frame(
    text = txt,
    score = vapply(strsplit(tolower(txt), "[^a-z]+"),
                   function(w) sum(w %in% pos) - sum(w %in% neg), numeric(1)),
    stringsAsFactors = FALSE
  )
  g2 <- emoji_incongruity(corpus, text, score,
                          scale = "rank")$.emoji_incongruity
  expect_equal(mean(g2[!is.na(g2)]), 0)
})

test_that("every output column name falls in a documented naming class", {
  # ?tidyEmoji names three shapes and claims the structural-index list is
  # complete. A verb that invents a fourth dotted name would contradict the
  # page users read to know what to expect.
  structural <- c(".row_number", ".position", ".period", ".period_prev",
                  ".period_label")
  d <- data.frame(
    text = c("hi \U0001F600", "p", "\u2764\uFE0F\U0001F525"),
    when = as.Date("2024-01-01") + 0:2,
    sc = c(0.5, -0.2, 0.9),
    stringsAsFactors = FALSE
  )
  outs <- list(
    emoji_summary(d, text), emoji_filter(d, text), emoji_frequency(d, text),
    top_n_emojis(d, text), top_n_emojis(d, text, duplicated = TRUE),
    emoji_extract_nest(d, text), emoji_extract_unnest(d, text),
    emoji_tokens(d, text), emoji_categorize(d, text), emoji_type(d, text),
    emoji_faceness(d, text), emoji_sentiment(d, text, se = TRUE),
    emoji_emotion(d, text), emoji_emotion(d, text, long = TRUE),
    emoji_emotion_label(d, text), emoji_ambiguity(), emoji_risk(d, text),
    emoji_flag_ambiguous(d, text), emoji_lexicons(), emoji_score(d, text),
    emoji_context(d, text), emoji_collocations(d, text, min_n = 1),
    emoji_pairs(d, text), emoji_cooccurrence(d, text, diagonal = TRUE),
    emoji_ngrams(d, text), emoji_position(d, text), emoji_density(d, text),
    emoji_ratio(d, text),
    emoji_incongruity(d, text, sc, scale = "none"),
    emoji_congruence(d, text, sc, scale = "none"),
    emoji_incongruity_profile(d, text, sc, scale = "none", min_n = 1),
    suppressWarnings(emoji_trend(d, text, when)),
    suppressWarnings(emoji_turnover(d, text, when)),
    suppressWarnings(emoji_seasonality(d, text, when)),
    suppressWarnings(emoji_version_profile(d, text)),
    suppressWarnings(emoji_adoption_lag(d, text, when)),
    emoji_dfm(d, text), emoji_sanitize(d, text), emoji_token_cost(d, text),
    emoji_to_text(d, text), text_to_emoji(d, text), emoji_search("fire"),
    emoji_provenance(), emoji_unicode_releases()
  )
  cols <- setdiff(unique(unlist(lapply(outs, names))), names(d))
  dotted <- grep("^\\.", cols, value = TRUE)
  measurement <- grep("^\\.emoji", dotted, value = TRUE)
  expect_gt(length(measurement), 30L)
  # no dotted name outside the two documented dotted classes
  expect_identical(sort(setdiff(dotted, measurement)), sort(structural))
  # and the page really lists them
  page <- rd_flat("tidyEmoji-package")
  skip_if(is.na(page), "installed help database not available")
  for (nm in structural) {
    expect_true(grepl(paste0("\\code{", nm, "}"), page, fixed = TRUE),
                info = nm)
  }
})

# ---------------------------------------------------------------------------
# Round 48: three claimed equivalences that nothing tested, and one value that
# one bad input could destroy.

test_that("a non-finite text_score cannot destroy the other rows", {
  A <- "\U0001F600"
  set.seed(1)
  d <- data.frame(
    text = c(rep(paste("a", A), 60), rep("plain", 40)),
    sc = c(Inf, stats::rnorm(99)),
    stringsAsFactors = FALSE
  )
  for (sc in c("none", "rank", "zscore")) {
    g <- suppressWarnings(
      emoji_incongruity(d, text, sc, scale = sc)$.emoji_incongruity)
    scored <- !is.na(g)
    # the offending row is dropped; every other scorable row survives finite
    expect_identical(sum(scored), 59L, info = sc)
    expect_true(all(is.finite(g[scored])), info = sc)
    expect_true(is.na(g[1L]), info = sc)
  }
  # sd() of a column holding Inf is NaN, which sent the old code down the
  # degenerate branch and subtracted an infinite mean: every row came back
  # Inf or NaN, so a single bad value cost all 60
  expect_identical(sum(is.nan(stats::sd(c(Inf, 1, 2)))), 1L)

  # it warns, once, naming the count -- as the date reader does
  w <- tryCatch(emoji_incongruity(d, text, sc, scale = "zscore"),
                warning = function(w) conditionMessage(w))
  expect_true(grepl("1 value in `text_score` is not finite", w, fixed = TRUE))
  d3 <- d; d3$sc[c(1, 5, 9)] <- c(Inf, -Inf, Inf)
  w3 <- tryCatch(emoji_incongruity(d3, text, sc, scale = "rank"),
                 warning = function(w) conditionMessage(w))
  expect_true(grepl("3 values in `text_score` are not finite", w3, fixed = TRUE))
  # and stays quiet when there is nothing to report
  clean <- data.frame(text = paste("a", A), sc = 1, stringsAsFactors = FALSE)
  expect_silent(emoji_incongruity(clean, text, sc, scale = "none"))

  # NaN was already handled, since na.rm = TRUE drops it; assert it stays that
  # way rather than becoming a warning case
  dn <- data.frame(text = rep(paste("a", A), 3), sc = c(NaN, 0.1, 0.2),
                   stringsAsFactors = FALSE)
  expect_silent(emoji_incongruity(dn, text, sc, scale = "zscore"))
})

test_that("the bounded context window equals reading the whole side", {
  # .emoji_window_at() slices a bounded piece of the masked text instead of the
  # whole prefix/suffix, on the argument that the answer only depends on the
  # `window` tokens nearest the glyph. That is a claimed equivalence; this is
  # the differential test it never had.
  naive <- function(s, from, to, window, unit, side) {
    if (from > to) return("")
    tidyEmoji:::.emoji_window(substr(s, from, to), window, unit, side)
  }
  set.seed(19)
  emo <- c("\U0001F600", "\U0001F525", "\u2764\uFE0F",
           "\U0001F468\u200D\U0001F469\u200D\U0001F467")
  words <- c("a", "bb", "ccc", "hello", "world", "-", "...", "the")
  ws <- c(" ", "  ", "\t", " \t ", "\n")
  n_cmp <- 0L
  for (trial in 1:120) {
    parts <- character(0)
    for (i in seq_len(sample(1:10, 1))) {
      parts <- c(parts, sample(c(words, emo, ws, ".", "()"), 1))
      if (stats::runif(1) < 0.6) parts <- c(parts, sample(ws, 1))
    }
    s <- paste0(parts, collapse = "")
    locs <- tidyEmoji:::.emoji_locations(s)[[1]]
    if (!nrow(locs)) next
    masked <- tidyEmoji:::.emoji_mask(s, list(locs))
    nc <- nchar(masked)
    for (w in c(0L, 1L, 2L, 5L, 13L)) for (u in c("word", "char")) {
      for (k in seq_len(nrow(locs))) {
        expect_identical(
          tidyEmoji:::.emoji_window_at(masked, 1L, locs[k, "start"] - 1L,
                                       w, u, "left"),
          naive(masked, 1L, locs[k, "start"] - 1L, w, u, "left"))
        expect_identical(
          tidyEmoji:::.emoji_window_at(masked, locs[k, "end"] + 1L, nc,
                                       w, u, "right"),
          naive(masked, locs[k, "end"] + 1L, nc, w, u, "right"))
        n_cmp <- n_cmp + 2L
      }
    }
  }
  expect_gt(n_cmp, 1000L)
})

test_that("the trailing-run walk-back matches a direct search", {
  # .emoji_final_glyphs() walks back over blank gaps. The direct statement of
  # the same rule is "the longest suffix of glyphs with nothing but whitespace
  # outside them from its first glyph onwards"; the two must agree.
  ref_final <- function(s) {
    m <- tidyEmoji:::.emoji_locations(s)[[1]]
    n <- nrow(m)
    if (!n) return(character(0))
    cps <- strsplit(s, "")[[1]]
    inside <- rep(FALSE, length(cps))
    for (k in seq_len(n)) inside[m[k, "start"]:m[k, "end"]] <- TRUE
    for (k in seq_len(n)) {
      tail_idx <- m[k, "start"]:length(cps)
      outside <- tail_idx[!inside[tail_idx]]
      if (!length(outside) ||
            all(grepl("^[[:space:]]$", cps[outside]))) {
        return(tidyEmoji:::.emoji_slice(m[seq(k, n), , drop = FALSE], s))
      }
    }
    character(0)
  }
  J <- "\U0001F602"; H <- "\U0001F60D"
  # the cases ?emoji_incongruity spells out
  expect_length(tidyEmoji:::.emoji_final_glyphs(paste0("great ", J))[[1]], 1L)
  expect_length(tidyEmoji:::.emoji_final_glyphs(paste0("great ", J, "."))[[1]], 0L)
  expect_length(tidyEmoji:::.emoji_final_glyphs(paste0("great ", J, ")"))[[1]], 0L)
  expect_length(tidyEmoji:::.emoji_final_glyphs(paste0("great ", J, "\""))[[1]], 0L)
  expect_length(tidyEmoji:::.emoji_final_glyphs(paste0("great ", J, " ", H))[[1]], 2L)
  expect_length(tidyEmoji:::.emoji_final_glyphs(paste0("great ", J, "\n\t "))[[1]], 1L)
  expect_length(tidyEmoji:::.emoji_final_glyphs(paste0(J, " mid ", H))[[1]], 1L)
  expect_length(tidyEmoji:::.emoji_final_glyphs(paste0(J, ", ", H))[[1]], 1L)

  set.seed(23)
  emo <- c(J, H, "\u2764\uFE0F",
           "\U0001F468\u200D\U0001F469\u200D\U0001F467")
  tok <- c("a", "word", ".", ",", ")", "\"", "!", "-", "the")
  ws <- c(" ", "  ", "\t", "\n", " \t")
  for (i in 1:300) {
    parts <- character(0)
    for (j in seq_len(sample(0:8, 1))) {
      parts <- c(parts, sample(c(tok, emo), 1))
      if (stats::runif(1) < 0.5) parts <- c(parts, sample(ws, 1))
    }
    s <- paste0(parts, collapse = "")
    expect_identical(tidyEmoji:::.emoji_final_glyphs(s)[[1]], ref_final(s),
                     info = encodeString(s, quote = "\""))
  }
})

test_that("emoji_emotion(long = TRUE) returns what its @return says", {
  A <- "\U0001F600"
  d <- data.frame(text = c(paste("a", A), "plain"), id = 1:2,
                  stringsAsFactors = FALSE)
  dims <- c("anger", "anticipation", "disgust", "fear", "joy", "sadness",
            "surprise", "trust")
  wide <- emoji_emotion(d, text)
  long <- emoji_emotion(d, text, long = TRUE)

  # the long form drops the two counts -- the @return now says so, because the
  # advice to "read .emoji_n_scored alongside .emoji_n" cannot be followed here
  expect_identical(names(long), c("text", "id", ".emoji_emotion",
                                  ".emoji_score"))
  expect_false(any(c(".emoji_n", ".emoji_n_scored") %in% names(long)))
  expect_true(all(c(".emoji_n", ".emoji_n_scored") %in% names(wide)))

  # and the escape route the @return points at really works: the same rows, in
  # the same order
  expect_identical(nrow(long), nrow(d) * 8L)
  expect_identical(long$.emoji_emotion[seq_len(8L)], dims)
  for (dm in dims) {
    expect_equal(long$.emoji_score[long$.emoji_emotion == dm],
                 wide[[paste0(".emoji_", dm)]], info = dm)
  }
  expect_identical(long$id, rep(d$id, each = 8L))
})

# ---------------------------------------------------------------------------
# Round 49: the systematic exclusion, measured in every direction ?tidyEmoji
# states it. Two of its figures count different things (216 spellings that
# break when the selector is dropped; 212 catalogue rows that are themselves
# undetectable), which is the same trap the 79%/75% round-trip figures set --
# so pin both, and pin that they are not equal.

test_that("the documented undetectable-spelling figures are the data's", {
  ref <- tidyEmoji:::emoji_reference()
  detected <- lengths(tidyEmoji:::emoji_glyph_list(ref$emoji))

  # 212 catalogue rows are spellings detection does not match
  expect_identical(sum(detected == 0L), 212L)
  # ... and nothing is ever split: a catalogued glyph is one emoji or none
  expect_identical(sum(detected > 1L), 0L)

  # 1252 rows carry U+FE0F, and 216 of those break when it is dropped. That is
  # a different question from the 212 above, and the answer is a different
  # number; asserting both stops either being "reconciled" into the other.
  has_fe0f <- vapply(ref$emoji, function(g) 0xFE0F %in% utf8ToInt(g),
                     logical(1), USE.NAMES = FALSE)
  expect_identical(sum(has_fe0f), 1252L)
  stripped <- vapply(ref$emoji[has_fe0f], function(g) {
    cp <- utf8ToInt(g); intToUtf8(cp[cp != 0xFE0F])
  }, character(1), USE.NAMES = FALSE)
  expect_identical(sum(lengths(tidyEmoji:::emoji_glyph_list(stripped)) == 0L),
                   216L)
  expect_false(identical(216L, 212L))

  # and 57 of the scorable sentiment-lexicon glyphs are stored in a spelling
  # detection does not match
  sl <- emoji_sentiment_lexicon
  scorable <- tidyEmoji:::emoji_key(sl$emoji) %in% ref$key
  expect_identical(sum(scorable), 736L)
  expect_identical(
    sum(lengths(tidyEmoji:::emoji_glyph_list(sl$emoji[scorable])) == 0L), 57L)

  # "Detection is the only thing affected -- the join is not."
  undetectable <- ref$emoji[detected == 0L]
  expect_false(anyNA(as_emoji_name(undetectable)))
  expect_false(anyNA(as_emoji_type(undetectable)))
  expect_false(anyNA(tidyEmoji:::emoji_key(undetectable)))
  expect_identical(nrow(emoji_ambiguity(undetectable)),
                   length(undetectable))
})

test_that("the keycap selector goes in the middle, not at the end", {
  ref <- tidyEmoji:::emoji_reference()
  detected <- lengths(tidyEmoji:::emoji_glyph_list(ref$emoji))
  undetectable <- ref$emoji[detected == 0L]

  appended <- paste0(undetectable, "\uFE0F")
  inserted <- vapply(undetectable, function(g) {
    cp <- utf8ToInt(g); intToUtf8(c(cp[1L], 0xFE0F, cp[-1L]))
  }, character(1), USE.NAMES = FALSE)

  # appending repairs 200; inserting after the first code point repairs all 212
  expect_identical(sum(lengths(tidyEmoji:::emoji_glyph_list(appended)) > 0L),
                   200L)
  expect_identical(sum(lengths(tidyEmoji:::emoji_glyph_list(inserted)) > 0L),
                   212L)

  # the 12 that appending cannot repair are exactly the U+20E3 keycaps
  stubborn <- undetectable[lengths(tidyEmoji:::emoji_glyph_list(appended)) == 0L]
  expect_identical(length(stubborn), 12L)
  expect_true(all(vapply(stubborn,
                         function(g) 0x20E3 %in% utf8ToInt(g),
                         logical(1), USE.NAMES = FALSE)))

  # the worked example the page gives
  bare_kc <- "1\u20E3"
  appended_kc <- "1\u20E3\uFE0F"
  inserted_kc <- "1\uFE0F\u20E3"
  expect_identical(lengths(tidyEmoji:::emoji_glyph_list(bare_kc)), 0L)
  expect_identical(lengths(tidyEmoji:::emoji_glyph_list(appended_kc)), 0L)
  expect_identical(lengths(tidyEmoji:::emoji_glyph_list(inserted_kc)), 1L)
  # all three name the same emoji, since the join strips the selector
  expect_identical(as_emoji_name(c(bare_kc, appended_kc, inserted_kc)),
                   rep("keycap: 1", 3L))

  # and the canonical keycaps behave like every other emoji: one glyph, and a
  # byte-exact shortcode round trip -- what ?emoji_sanitize promises
  keycaps <- ref$emoji[grep("^keycap", ref$name)]
  canonical <- keycaps[!duplicated(tidyEmoji:::emoji_key(keycaps))]
  expect_identical(length(canonical), 13L)
  expect_true(all(lengths(tidyEmoji:::emoji_glyph_list(canonical)) == 1L))
  d <- data.frame(text = canonical, stringsAsFactors = FALSE)
  expect_identical(
    text_to_emoji(emoji_sanitize(d, text, policy = "shortcode"), text)$text,
    canonical)
})

test_that("detection of a catalogued glyph does not depend on its context", {
  # Everything in the package rests on .emoji_locations() returning the same
  # spans for a glyph whether it stands alone or sits in a sentence. Tested
  # only on bare glyphs until now.
  ref <- tidyEmoji:::emoji_reference()
  G <- ref$emoji
  alone <- lengths(tidyEmoji:::emoji_glyph_list(G))
  smiley <- "\U0001F600"

  for (ctx in list(c("hi ", " bye"), c("x", "y"), c("", "."), c("(", ")"),
                   c("\u200D", ""), c("", "\u200D"), c("\uFE0F", ""))) {
    expect_identical(
      lengths(tidyEmoji:::emoji_glyph_list(paste0(ctx[1], G, ctx[2]))),
      alone, info = paste0(ctx[1], "_", ctx[2]))
  }

  # next to another emoji, the split is exactly the two of them -- except
  # where one member is one of the 212 undetectable spellings, which
  # contributes nothing
  for (side in c("after", "before")) {
    s <- if (side == "after") paste0(G, smiley) else paste0(smiley, G)
    want <- lapply(seq_along(G), function(i) {
      if (alone[i] == 0L) smiley
      else if (side == "after") c(G[i], smiley) else c(smiley, G[i])
    })
    expect_identical(tidyEmoji:::emoji_glyph_list(s), want, info = side)
  }

  # and every span is well formed: ordered, non-overlapping, inside the
  # string, and slicing it back gives the glyph. Reduced to one assertion per
  # string set rather than per glyph -- 5042 glyphs x 5 sets x 5 expectations
  # is 100k assertions and four minutes of check time for no extra coverage.
  well_formed <- function(strings) {
    locs <- tidyEmoji:::.emoji_locations(strings)
    vapply(seq_along(strings), function(i) {
      m <- locs[[i]]
      if (!nrow(m)) return(TRUE)
      all(m[, "start"] <= m[, "end"]) &&
        m[1L, "start"] >= 1L &&
        m[nrow(m), "end"] <= nchar(strings[i]) &&
        (nrow(m) == 1L || all(m[-1L, "start"] > m[-nrow(m), "end"])) &&
        identical(tidyEmoji:::.emoji_slice(m, strings[i]),
                  substring(strings[i], m[, "start"], m[, "end"]))
    }, logical(1))
  }
  zwj <- "\u200D"
  for (strings in list(G, paste0("hi ", G, " bye"), paste0(G, G),
                       paste0(G, zwj), paste0(zwj, G))) {
    expect_true(all(well_formed(strings)))
  }
})

test_that("entropy is never negative zero", {
  # -sum(1 * log(1)) is -0 for a unanimous glyph: equal to zero, prints as
  # "0", and formats as "-0.000" under sprintf() -- which is how a table
  # reaches a paper. 166 of the 969 rows were affected.
  a <- emoji_ambiguity(measure = "entropy")
  expect_identical(nrow(a), 969L)
  unanimous <- !is.na(a$ambiguity) & a$ambiguity == 0
  expect_gt(sum(unanimous), 100L)
  # 1/-0 is -Inf, which is the only way to tell the two zeros apart
  expect_true(all(sign(1 / a$ambiguity[unanimous]) > 0))
  expect_identical(unique(sprintf("%.3f", a$ambiguity[unanimous])), "0.000")
  # and the fix did not disturb the rest of the column
  expect_equal(max(a$ambiguity, na.rm = TRUE), log(3))
  expect_gte(min(a$ambiguity, na.rm = TRUE), 0)
  tbl <- tidyEmoji:::emoji_ambiguity_table()
  for (cn in c("p_neg", "p_neu", "p_pos", "entropy", "gini", "neutral_share",
               "ci_width", "se")) {
    v <- tbl[[cn]]
    expect_false(any(!is.na(v) & v == 0 & sign(1 / v) < 0), info = cn)
  }
})

test_that("the annotation-count caveat ?emoji_ambiguity states is the data's", {
  a <- emoji_ambiguity()
  # the figures the details paragraph quotes
  expect_identical(stats::median(a$n_annotations), 18L)
  expect_identical(round(100 * mean(a$n_annotations < 50)), 69)
  # five rows tie at rank 1, on 3, 3, 3, 9 and 15 annotations
  tied <- sort(a$n_annotations[a$rank == 1L])
  expect_identical(tied, c(3L, 3L, 3L, 9L, 15L))
  expect_equal(unique(a$ambiguity[a$rank == 1L]), log(3))
  # and 11 of the top 20 have fewer than 50
  expect_identical(sum(a$n_annotations[1:20] < 50), 11L)

  # the escape route the example shows really changes the head of the table
  strong <- a[a$n_annotations >= 500, ]
  expect_gt(nrow(strong), 20L)
  expect_gte(min(strong$n_annotations), 500L)
  expect_false(identical(head(strong$emoji), head(a$emoji)))
  # The trap is at the *top* of the ranking specifically, not across it: a
  # thinly annotated glyph is usually unanimous, so entropy is in fact
  # positively correlated with the annotation count overall. What three
  # annotators can do that thousands cannot is hit the exact maximum.
  expect_gt(stats::cor(a$ambiguity, a$n_annotations,
                       method = "spearman", use = "complete.obs"), 0.4)
  expect_true(all(a$n_annotations[a$ambiguity == log(3)] <= 15L))
  expect_gte(max(a$n_annotations), 500L)
  expect_lt(max(a$ambiguity[a$n_annotations >= 500]), log(3))

  # "ci_width accounts for thin evidence" is a property of its formula, not a
  # marginal correlation (which is only -0.19, because the variance moves too):
  # the interval is a Wald interval on the glyph's score, so it scales as
  # 1 / sqrt(n) at fixed spread
  tbl <- tidyEmoji:::emoji_ambiguity_table()
  score <- tbl$p_pos - tbl$p_neg
  v <- pmax(0, tbl$p_pos + tbl$p_neg - score^2)
  expect_equal(tbl$se, sqrt(v / tbl$n_annotations))
  expect_equal(tbl$ci_width, 2 * stats::qnorm(0.975) * tbl$se)
  # so doubling the evidence at the same spread narrows it by sqrt(2)
  expect_equal(sqrt(v[1] / 100) / sqrt(v[1] / 200), sqrt(2))
})

test_that("emoji_ambiguity(x) returns one row per element, in order", {
  A <- "\U0001F602"        # in the lexicon
  B <- "\U0001F643"        # detectable, not in the lexicon
  full <- emoji_ambiguity()
  for (x in list(c(A, B), c(B, A), c(A, A, B), c(A, NA, B), c(A, "abc", B),
                 c(A, "", B), character(0), NA_character_)) {
    o <- emoji_ambiguity(x)
    expect_identical(nrow(o), length(x))
    expect_identical(o$emoji, x)
  }
  # ranks come from the whole lexicon, so they survive subsetting
  sub <- emoji_ambiguity(c(A, B))
  expect_identical(sub$rank[1L], full$rank[full$emoji == A])
  expect_true(is.na(sub$rank[2L]))
  expect_true(is.na(sub$ambiguity[2L]))
  # the default order is rank then glyph, and ties share the lowest rank
  expect_identical(full$rank,
                   as.integer(rank(-full$ambiguity, ties.method = "min")))
  expect_true(all(abs(full$p_neg + full$p_neu + full$p_pos - 1) < 1e-12))
  # every measure stays inside the range ?emoji_ambiguity claims
  expect_lte(max(emoji_ambiguity(measure = "gini")$ambiguity), 2 / 3 + 1e-12)
  ns <- emoji_ambiguity(measure = "neutral_share")$ambiguity
  expect_gte(min(ns, na.rm = TRUE), 0)
  expect_lte(max(ns, na.rm = TRUE), 1)
})

# ---------------------------------------------------------------------------
# Round 50: the introduction vignette, audited for the first time. It is the
# document a user reads before any help page, and nothing had ever checked its
# prose against the package.

test_that("exactly one time verb runs without a time column", {
  # The vignette said two, having read emoji-time.R's "two of these are almost
  # free" as "two need no timestamp". emoji_adoption_lag() uses the same
  # version lookup but still has to find each glyph's first appearance, so it
  # requires `time` -- as the vignette's own next sentence says.
  time_verbs <- c("emoji_trend", "emoji_turnover", "emoji_seasonality",
                  "emoji_version_profile", "emoji_adoption_lag")
  needs_time <- vapply(time_verbs,
                       function(f) "time" %in% names(formals(get(f))),
                       logical(1))
  expect_identical(sum(!needs_time), 1L)
  expect_identical(names(needs_time)[!needs_time], "emoji_version_profile")

  # and it is an error, not a silent pass, to omit it
  d <- data.frame(text = "hi \U0001F600", stringsAsFactors = FALSE)
  expect_error(emoji_adoption_lag(d, text), "`time` is required")
  expect_error(emoji_trend(d, text), "`time` is required")
  expect_error(emoji_turnover(d, text), "`time` is required")
  expect_error(emoji_seasonality(d, text), "`time` is required")
  expect_s3_class(suppressWarnings(emoji_version_profile(d, text)), "tbl_df")

  vig <- pkg_text_file("vignettes/introduction.Rmd", "doc/introduction.Rmd")
  skip_if(is.na(vig), "vignette source not available")
  txt <- paste(readLines(vig, warn = FALSE), collapse = " ")
  expect_false(grepl("Two of the time verbs need no timestamp", txt,
                     fixed = TRUE))
})

test_that("the vignette names every export, and reaches for nothing superseded", {
  vig <- pkg_text_file("vignettes/introduction.Rmd", "doc/introduction.Rmd")
  skip_if(is.na(vig), "vignette source not available")
  lines <- readLines(vig, warn = FALSE)

  # the overview table is the package's own contents page; a verb missing from
  # it is a verb a reader will not find
  tbl <- lines[grepl("^\\| ", lines) & grepl("`", lines)]
  named <- gsub("[`()]", "",
                unlist(regmatches(tbl,
                  gregexpr("`[A-Za-z_][A-Za-z0-9_]*\\*?\\(\\)`", tbl))))
  wild <- grep("\\*$", named, value = TRUE)
  named <- setdiff(named, wild)
  exports <- getNamespaceExports("tidyEmoji")
  for (w in wild) {
    named <- c(named, grep(paste0("^", sub("\\*$", "", w)), exports,
                           value = TRUE))
  }
  # emoji_tweets() is soft-deprecated, and is mentioned in the prose instead
  expect_identical(sort(setdiff(exports, named)), "emoji_tweets")
  expect_identical(setdiff(named, exports), character(0))
  expect_true(any(grepl("emoji_tweets", lines, fixed = TRUE)))

  # nothing in the package or its prose teaches a superseded tidyverse call.
  # tidyr::separate_rows() was one: tidyr's own help says
  # separate_longer_delim() is "now recommended", which is why DESCRIPTION
  # declares tidyr (>= 1.3.0).
  superseded <- c("separate_rows", "gather", "spread", "top_n", "funs",
                  "mutate_all", "mutate_at", "mutate_if", "summarise_all",
                  "summarise_at", "summarise_if", "data_frame",
                  "nest_legacy", "unnest_legacy")
  # anchored on a non-identifier character, so `igraph::graph_from_data_frame`
  # is not read as `data_frame` and `top_n_emojis` is not read as `top_n`
  patterns <- paste0("(^|[^A-Za-z0-9_.])", superseded, "\\(")
  # the vignette, the README and the package sources -- not the test files,
  # which necessarily contain the very strings being searched for. Inside
  # `R CMD check` only the installed vignette is reachable; from the source
  # tree all of R/ is, and there the count is worth asserting.
  r_files <- Sys.glob("../../R/*.R")
  sources <- c(vig, "../../README.Rmd", r_files)
  sources <- sources[file.exists(sources)]
  expect_gt(length(sources), 0L)
  if (length(r_files)) expect_gt(length(sources), 20L)
  for (f in sources) {
    body <- paste(readLines(f, warn = FALSE), collapse = "\n")
    hit <- superseded[vapply(patterns, grepl, logical(1), x = body)]
    expect_identical(hit, character(0),
                     info = paste(basename(f), "uses", paste(hit, collapse = ", ")))
  }

  # and the floor that switch requires is declared
  imports <- utils::packageDescription("tidyEmoji")$Imports
  expect_true(grepl("tidyr (>= 1.3.0)", imports, fixed = TRUE))
  expect_true(exists("separate_longer_delim", where = asNamespace("tidyr")))
})

test_that("emoji_unicode_crosswalk's row unit is a (name, glyph) pair", {
  # ?emoji_unicode_crosswalk and the vignette both said "one row per emoji
  # name". It is neither one row per name nor one per glyph: the mapping is
  # many-to-many both ways, so a join by emoji_name silently duplicates.
  eu <- emoji_unicode_crosswalk
  expect_identical(nrow(eu), 5761L)
  expect_identical(length(unique(eu$emoji_name)), 4698L)
  expect_identical(length(unique(eu$unicode)), 4853L)

  # the row unit: (name, glyph) pairs are unique, (name, key) pairs are not
  expect_identical(nrow(unique(eu[, c("emoji_name", "unicode")])), nrow(eu))
  expect_identical(nrow(unique(eu[, c("emoji_name", "key")])),
                   length(unique(eu$emoji_name)))

  # a name on several rows means several *spellings* of one emoji, never two
  # different emoji -- which is why joining on `key` is the fix
  repeated <- names(which(table(eu$emoji_name) > 1L))
  expect_identical(length(repeated), 973L)
  keys_per_name <- tapply(eu$key, eu$emoji_name, function(k) length(unique(k)))
  expect_true(all(keys_per_name == 1L))

  # and the worked example the help page gives
  grin <- eu$emoji_name[eu$unicode == "\U0001F600"]
  expect_true(all(c("grinning", "grinning_face") %in% grin))
  ab <- eu[eu$emoji_name == "A_button_blood_type_", ]
  expect_identical(nrow(ab), 2L)
  expect_identical(unique(ab$key), "1F170")
})

# ---------------------------------------------------------------------------
# Round 51: found by running the suite on R 4.1.0, the declared minimum, and on
# R 4.6.0. Two dependency arguments the package relies on did not exist when
# the package was first installable, and neither had a declared floor:
#
#   * lifecycle's `deprecate_warn(env=, user_env=)` -- absent in lifecycle
#     1.0.0, present from 1.0.3, whose release notes are exactly the
#     caller-environment work those arguments exist for. Every grouped-input
#     call goes through .emoji_warn_grouped(), so on an older lifecycle a dozen
#     verbs would fail with "unused argument".
#   * readr's `read_csv(show_col_types=)` -- absent in readr 1.4.0, which is
#     what R 4.1.0 ships here, so the vignette would fail to *build* and the
#     corpus test errored rather than skipping.

test_that("every argument passed to a dependency is one it accepts", {
  # The general form of the bug: an "unused argument" error is invisible until
  # someone runs against the version that lacks it. This catches the call sites
  # at least against the installed versions.
  files <- Sys.glob("../../R/*.R")
  checked <- 0L
  walk <- function(e) {
    if (!is.call(e)) return(invisible())
    f <- e[[1L]]
    if (is.call(f) && identical(as.character(f[[1L]]), "::")) {
      pkg <- as.character(f[[2L]]); fun <- as.character(f[[3L]])
      if (requireNamespace(pkg, quietly = TRUE) &&
            exists(fun, envir = asNamespace(pkg))) {
        target <- get(fun, envir = asNamespace(pkg))
        if (is.function(target)) {
          fm <- names(formals(target))
          nm <- names(e)
          nm <- nm[!is.na(nm) & nzchar(nm)]
          if (length(nm) && !("..." %in% fm)) {
            bad <- setdiff(nm, fm)
            expect_identical(bad, character(0),
                             info = paste0(pkg, "::", fun, "(",
                                           paste(bad, collapse = ", "), ")"))
          }
          checked <<- checked + 1L
        }
      }
    }
    for (i in seq_along(e)) {
      if (!is.null(e[[i]]) && (is.call(e[[i]]) || is.pairlist(e[[i]]))) {
        walk(e[[i]])
      }
    }
    invisible()
  }
  if (length(files)) {
    for (f in files) for (e in parse(f)) walk(e)
  } else {
    # inside R CMD check: walk the namespace's own function bodies, which hold
    # the same calls
    for (e in pkg_exprs()) walk(e)
  }
  expect_gt(checked, 50L)
})

test_that("the declared dependency floors cover the arguments the code uses", {
  # A fixed table, because an argument's introduction version cannot be read
  # off an installed package. Each row is an argument the package would break
  # without, paired with the floor DESCRIPTION has to declare for it.
  needs <- list(
    list(pkg = "lifecycle", fun = "deprecate_warn",
         args = c("env", "user_env"), floor = "1.0.3"),
    list(pkg = "dplyr", fun = "left_join",
         args = "relationship", floor = "1.1.0"),
    list(pkg = "dplyr", fun = "arrange", args = ".locale", floor = "1.1.0"),
    list(pkg = "tidyr", fun = "separate_longer_delim",
         args = "delim", floor = "1.3.0"),
    list(pkg = "readr", fun = "read_csv",
         args = "show_col_types", floor = "2.0.0")
  )
  desc <- utils::packageDescription("tidyEmoji")
  declared <- paste(desc$Imports, desc$Suggests, sep = ", ")

  for (n in needs) {
    # DESCRIPTION declares a floor at least as high as the one required
    m <- regmatches(declared,
                    regexpr(paste0(n$pkg, " \\(>= [0-9.]+\\)"), declared))
    expect_identical(length(m), 1L,
                     info = paste(n$pkg, "has no declared version floor"))
    got <- gsub(".*>= |\\)", "", m)
    # expect_gte() wants numerics, and these are package_version objects
    expect_true(package_version(got) >= package_version(n$floor),
                info = paste0(n$pkg, ": declared >= ", got,
                              ", needs >= ", n$floor, " for ",
                              paste(n$args, collapse = "/")))
    # And the argument really exists -- but only check that where the installed
    # version actually meets the declared floor. skip_if_not_installed() would
    # abandon the whole loop, so a missing or too-old package skips its own row
    # and the others are still checked. (R 4.1.0 here ships readr 1.4.0, which
    # is exactly the case that motivated the floor.)
    if (!requireNamespace(n$pkg, quietly = TRUE)) next
    if (utils::packageVersion(n$pkg) < package_version(n$floor)) next
    ns <- asNamespace(n$pkg)
    fm <- names(formals(get(n$fun, envir = ns)))
    # dplyr's verbs are generics whose formals are just (.data, ...); the
    # arguments live on the data.frame method
    if (!all(n$args %in% fm) && "..." %in% fm) {
      meth <- tryCatch(utils::getS3method(n$fun, "data.frame", envir = ns),
                       error = function(e) NULL)
      if (is.function(meth)) fm <- union(fm, names(formals(meth)))
    }
    expect_true(all(n$args %in% fm),
                info = paste0(n$pkg, "::", n$fun, " lacks ",
                              paste(setdiff(n$args, fm), collapse = ", ")))
  }

  # readr is only used by the vignette and one test, both of which must gate
  # on the version rather than on mere presence
  reg <- readLines("test-regression-0.4.0.R", warn = FALSE)
  readr_lines <- grep("readr", reg, value = TRUE)
  expect_true(any(grepl('minimum_version = "2.0.0"', readr_lines, fixed = TRUE)))
})

# ---------------------------------------------------------------------------
# Round 52: the reproducibility claim, and the last of the roadmap's
# "grep for other nchar() uses on user text" action item.

test_that("the bundled crosswalks are what data-raw/crosswalks.R produces", {
  # Every dataset's @source names the data-raw script that builds it, and the
  # vignette says the datasets "are regenerated from the current Unicode emoji
  # list by the scripts in data-raw/". Nothing checked that. The two crosswalks
  # derive purely from emoji::emojis, so they can be rebuilt here; the two
  # lexicons need the network and are verified out of band.
  skip_on_cran()
  script <- testthat::test_path("..", "..", "data-raw", "crosswalks.R")
  skip_if(!file.exists(script), "data-raw/ not available")
  skip_if_not_installed("dplyr")
  skip_if_not_installed("tidyr")

  wd <- getwd()
  tmp <- file.path(tempdir(), "tidyEmoji-regen")
  dir.create(file.path(tmp, "data"), recursive = TRUE, showWarnings = FALSE)
  on.exit({ setwd(wd); unlink(tmp, recursive = TRUE) }, add = TRUE)
  code <- readLines(script, warn = FALSE)
  setwd(tmp)
  env <- new.env(parent = globalenv())
  suppressMessages(eval(parse(text = paste(code, collapse = "\n")), env))

  for (nm in c("emoji_unicode_crosswalk", "category_unicode_crosswalk")) {
    built <- get(nm, envir = env)
    bundled <- get(nm, envir = asNamespace("tidyEmoji"))
    expect_identical(built, bundled, info = nm)
  }
})

test_that("every nchar() on user text feeds a documented code-point figure", {
  # Roadmap 1.1 fixed .emoji_rel_position's denominator and left an action:
  # "grep for other nchar() uses on user text before assuming these are the
  # only two verbs affected". emoji_ratio() states its code-point basis and
  # emoji_position() states that it counts each emoji as one position;
  # emoji_density() said only "per character", which reads as per-grapheme.
  smiley <- "\U0001F600"
  flag <- "\U0001F1FA\U0001F1F8"                        # 2 code points
  family <- paste0("\U0001F468\u200D\U0001F469\u200D",
                    "\U0001F467\u200D\U0001F466")
  d <- data.frame(text = paste("hi", c(smiley, flag, family)),
                  stringsAsFactors = FALSE)

  # one emoji and four graphemes in every row ...
  expect_identical(nchar(d$text), c(4L, 5L, 10L))
  den <- emoji_density(d, text)
  expect_identical(den$.emoji_n, rep(1L, 3L))

  # ... but .emoji_per_char moves with the emoji's code-point length, which is
  # the figure the help page now quotes
  expect_equal(den$.emoji_per_char, c(0.25, 0.2, 0.1))
  # .emoji_per_token does not
  expect_equal(den$.emoji_per_token, rep(0.5, 3L))
  # and .emoji_rel_position does not, because a proportion of a message cannot
  expect_equal(emoji_position(d, text)$.emoji_rel_position, rep(1, 3L))
  # emoji_ratio() is code-point based and says so
  expect_equal(emoji_ratio(d, text)$.emoji_ratio, c(0.25, 0.4, 0.7))

  # the help pages carry the basis, so a reader cannot mistake one for the other
  read_rd <- rd_text
  dens <- read_rd("emoji_density.Rd")
  expect_true(grepl("code point", dens, fixed = TRUE))
  expect_true(grepl("per code point", dens, fixed = TRUE))
  expect_true(grepl("code points", read_rd("emoji_ratio.Rd"), fixed = TRUE))
  expect_true(grepl("code-point offsets", read_rd("emoji_position.Rd"),
                    fixed = TRUE))
})

# ---------------------------------------------------------------------------
# Round 54: `?emoji_sanitize`'s reversibility table promises that
# policy = "shortcode" restores the original text, and calls it "the only
# policy that permits it". The section never mentioned `wrap`, an argument of
# the same function that silently voids the promise.

test_that("only the default wrap keeps the shortcode round trip reversible", {
  A <- "\U0001F600"
  d <- data.frame(text = paste("hi", A, "bye"), stringsAsFactors = FALSE)
  trip <- function(w) {
    t1 <- emoji_sanitize(d, text, policy = "shortcode", wrap = w)$text
    text_to_emoji(data.frame(text = t1, stringsAsFactors = FALSE), text)$text
  }

  # the default restores the text exactly
  expect_identical(trip(":{x}:"), d$text)

  # a wrap with no `:token:` restores nothing -- the shortcode stays a word.
  # This is the silent case, so assert the shortcode is still there.
  for (w in c("{x}", "<{x}>", "@{x}@", ":{x}", "{x}:", "a{x}b")) {
    got <- trip(w)
    expect_false(grepl(A, got, fixed = TRUE), info = w)
    expect_true(grepl("grinning", got, fixed = TRUE), info = w)
  }

  # a wrap that decorates the token brings the emoji back but not the text
  for (w in c("[:{x}:]", ":{x}:!")) {
    got <- trip(w)
    expect_true(grepl(A, got, fixed = TRUE), info = w)
    expect_false(identical(got, d$text), info = w)
  }

  # "::{x}::" leaves stray colons around the glyph, so it is not even stable
  doubled <- trip("::{x}::")
  expect_identical(doubled, paste0("hi :", A, ": bye"))
  again <- text_to_emoji(
    emoji_sanitize(data.frame(text = doubled, stringsAsFactors = FALSE),
                   text, policy = "shortcode", wrap = "::{x}::"), text)$text
  expect_false(identical(again, doubled))

  # and the help pages now say so
  san <- rd_flat("emoji_sanitize")
  expect_true(grepl("assumes the default", san, fixed = TRUE))
  expect_true(grepl("reversibility contract", san, fixed = TRUE))
  expect_true(grepl("restores nothing", san, fixed = TRUE))
  demoji <- rd_flat("emoji_to_text")
  expect_true(grepl("Only the default is reversible", demoji, fixed = TRUE))
  expect_true(grepl("and its", rd_flat("text_to_emoji"), fixed = TRUE))
})

test_that("every cross-row aggregator warns once, and names itself", {
  A <- "\U0001F600"
  g <- dplyr::group_by(
    data.frame(text = c(paste("a", A), paste("b", A)), grp = c(1, 2),
               when = as.Date("2024-01-01") + 0:1, sc = c(0.5, -0.2),
               stringsAsFactors = FALSE), grp)
  aggs <- list(
    emoji_summary = function() emoji_summary(g, text),
    emoji_frequency = function() emoji_frequency(g, text),
    top_n_emojis = function() top_n_emojis(g, text),
    emoji_pairs = function() emoji_pairs(g, text),
    emoji_cooccurrence = function() emoji_cooccurrence(g, text),
    emoji_collocations = function() emoji_collocations(g, text, min_n = 1),
    emoji_dfm = function() emoji_dfm(g, text),
    emoji_flag_ambiguous = function() emoji_flag_ambiguous(g, text),
    emoji_trend = function() emoji_trend(g, text, when),
    emoji_turnover = function() emoji_turnover(g, text, when),
    emoji_seasonality = function() emoji_seasonality(g, text, when),
    emoji_version_profile = function() emoji_version_profile(g, text),
    emoji_adoption_lag = function() emoji_adoption_lag(g, text, when),
    emoji_incongruity_profile = function() {
      emoji_incongruity_profile(g, text, sc, scale = "none", min_n = 1)
    }
  )
  expect_identical(length(aggs), 14L)
  op <- options(lifecycle_verbosity = "warning")   # force, so it is not deduped
  on.exit(options(op), add = TRUE)
  for (nm in names(aggs)) {
    got <- character(0)
    withCallingHandlers(invisible(aggs[[nm]]()), warning = function(w) {
      got <<- c(got, conditionMessage(w))
      invokeRestart("muffleWarning")
    })
    expect_identical(length(got), 1L, info = nm)
    # the verb names itself, rather than the helper or the verb it delegates to
    expect_true(grepl(paste0(nm, "()"), got[1], fixed = TRUE), info = nm)
    # and it does not tell the user to report a bug in tidyEmoji
    expect_false(grepl("report the issue", got[1], fixed = TRUE), info = nm)
  }
})

# ---------------------------------------------------------------------------
# Round 55: the detection figures NEWS.md and cran-comments.md quote for the
# grapheme repair. Both said "80.1% to 95.8%" and "793 to 2", which pairs a
# no-repair baseline with an after-rules-1-and-2 baseline. No staging of the
# rules produces 80.1%: the no-repair figure is 63.2%, and 793 is what rule 3
# starts from, not what the three rules together start from.

test_that("the staged detection figures are the ones the rules give", {
  ref <- tidyEmoji:::emoji_reference()
  G <- ref$emoji
  Z <- "\u200D"

  # rule 1 on its own: UAX #29 GB11, merging two matches separated by one ZWJ
  merge_gb11 <- function(m, s) {
    repeat {
      n <- nrow(m)
      if (n < 2L) break
      gs <- m[-n, "end"] + 1L
      ge <- m[-1L, "start"] - 1L
      j <- ge == gs & substring(s, gs, ge) == Z
      if (!any(j)) break
      grp <- cumsum(c(TRUE, !j))
      m <- cbind(start = as.integer(tapply(m[, "start"], grp, min)),
                 end = as.integer(tapply(m[, "end"], grp, max)))
    }
    m
  }
  raw <- emoji::emoji_locate_all(G)
  r1 <- lapply(seq_along(G), function(i) {
    m <- raw[[i]]
    if (nrow(m) < 2L) m else merge_gb11(m, G[i])
  })
  now <- tidyEmoji:::.emoji_locations(G)

  exact <- function(locs) {
    sum(vapply(seq_along(G), function(i) {
      m <- locs[[i]]
      nrow(m) == 1L &&
        identical(substring(G[i], m[1L, "start"], m[1L, "end"]), G[i])
    }, logical(1)))
  }
  expect_identical(exact(raw), 3189L)
  expect_identical(exact(r1), 3807L)
  expect_identical(exact(now), 4830L)
  expect_identical(round(100 * 3189 / 5042, 1), 63.2)
  expect_identical(round(100 * 3807 / 5042, 1), 75.5)
  expect_identical(round(100 * 4830 / 5042, 1), 95.8)
  # the figure both documents used to quote is not any staging of the rules
  expect_false(80.1 %in% round(100 * c(3189, 3807, 4830) / 5042, 1))

  orphans <- function(locs) {
    sum(vapply(seq_along(G), function(i) {
      m <- locs[[i]]
      cps <- strsplit(G[i], "")[[1L]]
      inside <- rep(FALSE, length(cps))
      if (nrow(m)) {
        for (k in seq_len(nrow(m))) inside[m[k, "start"]:m[k, "end"]] <- TRUE
      }
      any(cps == Z & !inside)
    }, logical(1)))
  }
  expect_identical(orphans(raw), 1643L)
  expect_identical(orphans(r1), 1025L)
  expect_identical(orphans(now), 2L)

  # and both documents quote the corrected pair. Not asserting the absence of
  # "80.1%": the NEWS entry recording this fix quotes the old figure in order
  # to say what it was, so a negative match would fail on the correction
  # itself. The derived figures above are the guard that matters.
  for (f in c("NEWS.md", "cran-comments.md")) {
    path <- pkg_text_file(f)
    if (is.na(path)) next
    txt <- paste(readLines(path, warn = FALSE), collapse = " ")
    expect_true(grepl("63.2%", txt, fixed = TRUE), info = f)
    expect_true(grepl("95.8%", txt, fixed = TRUE), info = f)
    expect_true(grepl("1643", txt, fixed = TRUE), info = f)
  }
})

test_that("every alias resolves, including the 751 only the fallback knows", {
  # NEWS: "751 of the 4698 aliases resolve solely through as_emoji()'s
  # fallback to emoji::emoji_name", because the reference table keeps only an
  # emoji's first alias as its shortcode.
  ref <- tidyEmoji:::emoji_reference()
  all_alias <- unique(unlist(emoji::emojis$aliases))
  shortcodes <- unique(ref$shortcode[!is.na(ref$shortcode)])
  expect_identical(length(all_alias), 4698L)
  expect_identical(length(shortcodes), 3947L)
  fallback_only <- setdiff(all_alias, shortcodes)
  expect_identical(length(fallback_only), 751L)
  # the three the entry names
  for (a in c("grinning_face", "satisfied", "face_with_tears_of_joy")) {
    expect_true(a %in% fallback_only, info = a)
  }
  # and every one of the 4698 resolves through as_emoji() and text_to_emoji()
  expect_false(anyNA(as_emoji(all_alias)))
  back <- text_to_emoji(
    data.frame(t = paste0(":", all_alias, ":"), stringsAsFactors = FALSE), t
  )$t
  expect_false(any(back == paste0(":", all_alias, ":")))
})

test_that("every exported help topic offers a route onward", {
  # Four topics had no @seealso at all -- and they were the four other pages
  # point *at* (emoji_categorize, emoji_emotion_label, emoji_extract_unnest,
  # emoji_filter), so a reader arriving from the index or a search had nowhere
  # to go while the other 44 exports did.
  db <- tools::Rd_db("tidyEmoji")
  exports <- getNamespaceExports("tidyEmoji")
  bare <- character(0)
  for (nm in names(db)) {
    o <- db[[nm]]
    flat <- paste(as.character(o), collapse = "")
    al <- sub("^\\\\alias\\{", "", sub("\\}$", "",
              unlist(regmatches(flat, gregexpr("\\\\alias\\{[^}]*\\}", flat)))))
    al <- intersect(al, exports)
    if (!length(al)) next
    tg <- vapply(o, function(e) {
      x <- attr(e, "Rd_tag")
      if (is.null(x)) "" else x
    }, character(1))
    see <- paste(unlist(o[tg == "\\seealso"], recursive = TRUE), collapse = " ")
    if (!nzchar(trimws(see))) bare <- c(bare, al)
  }
  expect_identical(sort(bare), character(0))

  # and the four that were bare now point at their pair
  pairs <- list(
    emoji_categorize = "emoji_type",
    emoji_emotion_label = "emoji_emotion",
    emoji_extract_unnest = "emoji_extract_nest",
    emoji_filter = "emoji_summary"
  )
  for (nm in names(pairs)) {
    txt <- rd_text(nm)
    expect_false(is.na(txt), info = nm)
    after <- sub(".*\\\\seealso", "", txt)
    expect_true(grepl(pairs[[nm]], after, fixed = TRUE),
                info = paste(nm, "->", pairs[[nm]]))
  }
})

test_that("README.md has not drifted from README.Rmd's prose", {
  # NEWS says README.md "cannot drift from its source unnoticed", which was
  # only true while someone remembered to re-knit. Rendering here would need
  # pandoc and rmarkdown, so instead: every prose line of the source has to
  # appear verbatim in the output. That catches an edit to one file and not the
  # other, which is the drift that actually happens.
  rmd <- pkg_text_file("README.Rmd")
  md <- pkg_text_file("README.md")
  skip_if(is.na(rmd) || is.na(md), "README sources not available")
  src <- readLines(rmd, warn = FALSE)
  out <- readLines(md, warn = FALSE)

  # drop chunk bodies and headers: their output is what rendering produces
  fence <- grepl("^```", src)
  inside <- cumsum(fence) %% 2L == 1L
  prose <- src[!inside & !fence]
  # and the YAML header, which does not survive into the .md
  yaml_end <- which(prose == "---")
  if (length(yaml_end) >= 2L) prose <- prose[-seq_len(yaml_end[2L])]
  prose <- trimws(prose)
  prose <- prose[nzchar(prose)]
  # knitr wraps long prose lines, so compare on whole paragraphs rather than
  # lines: a line that is not found verbatim must at least have its words in
  # order somewhere in the output
  # pandoc smartens quotes and dashes on the way to github_document, so
  # "row's" arrives as "row\u2019s". Normalise both sides before comparing.
  smart <- function(x) {
    x <- gsub("[\u2018\u2019]", "'", x)
    x <- gsub("[\u201C\u201D]", "\"", x)
    gsub("[\u2013\u2014]", "-", x)
  }
  prose <- smart(prose)
  body <- smart(paste(out, collapse = " "))
  missing <- prose[!vapply(prose, function(l) {
    grepl(l, body, fixed = TRUE) ||
      grepl(paste(strsplit(l, "\\s+")[[1L]], collapse = "\\s+"), body)
  }, logical(1))]
  expect_identical(missing, character(0))
  expect_gt(length(prose), 40L)
})

# ---------------------------------------------------------------------------
# Round 56: `data` validation, swept across every shape a user could pass.
# emoji_tokens() called .emoji_as_tibble() before resolving the column, and
# tibble::as_tibble() converts a bare list or a character matrix -- so the
# is.data.frame() guard the other verbs enforce never saw the original object.

test_that("every verb rejects a `data` that is not a data frame", {
  A <- "\U0001F600"
  wrong <- list(
    "NULL" = NULL,
    list = list(text = c("a", "b")),
    matrix = matrix(c("a", "b"), ncol = 1L,
                    dimnames = list(NULL, "text")),
    vector = c(text = "a"),
    number = 42,
    "function" = mean,
    environment = new.env()
  )
  verbs <- c("emoji_summary", "emoji_filter", "emoji_frequency",
             "emoji_sentiment", "emoji_density", "emoji_tokens",
             "emoji_extract_nest", "emoji_extract_unnest", "emoji_dfm",
             "emoji_context", "emoji_pairs", "emoji_type", "emoji_categorize",
             "emoji_to_text", "text_to_emoji", "emoji_sanitize",
             "emoji_ratio", "emoji_position", "top_n_emojis", "emoji_ngrams",
             "emoji_token_cost", "emoji_score", "emoji_faceness",
             "emoji_risk", "emoji_emotion", "emoji_cooccurrence")
  for (v in verbs) {
    for (nm in names(wrong)) {
      expect_error(
        suppressWarnings(do.call(v, list(wrong[[nm]], rlang::sym("text")))),
        "`data` must be a data frame",
        info = paste0(v, "(", nm, ")")
      )
    }
  }

  # a data frame with no such column is a different error, and is delegated to
  # dplyr::select() on purpose so the message names the column
  for (v in verbs) {
    expect_error(
      suppressWarnings(do.call(v, list(data.frame(), rlang::sym("text")))),
      "text", info = v
    )
  }

  # and the valid shapes still work, including the list-column round trip
  # emoji_tokens() needs
  d <- data.frame(text = paste("hi", A), id = 1L, stringsAsFactors = FALSE)
  expect_s3_class(emoji_tokens(d, text), "tbl_df")
  expect_identical(nrow(emoji_tokens(d, text)), 1L)
  expect_identical(emoji_tokens(d, text)$.emoji, A)
  expect_identical(emoji_tokens(tibble::as_tibble(d), text),
                   emoji_tokens(d, text))
  grouped <- dplyr::group_by(d, id)
  expect_true(dplyr::is_grouped_df(emoji_tokens(grouped, text)))
})

test_that("every export works as the first call in a session", {
  # Several verbs populate a shared cache lazily. If one read an entry another
  # populates, it would work only when something else had been called first --
  # invisible in a suite that runs them in order. Checked here by clearing the
  # cache before each call, which is the same condition as a fresh session.
  A <- "\U0001F600"
  d <- data.frame(text = c(paste("hi", A), "plain"),
                  when = as.Date("2024-01-01") + 0:1,
                  sc = c(0.5, -0.2), stringsAsFactors = FALSE)
  cache <- tidyEmoji:::.tidyEmoji_cache
  saved <- as.list(cache, all.names = TRUE)
  on.exit({
    rm(list = ls(cache, all.names = TRUE), envir = cache)
    for (n in names(saved)) assign(n, saved[[n]], envir = cache)
  }, add = TRUE)

  calls <- list(
    quote(as_emoji("grinning")), quote(as_emoji_name(A)),
    quote(as_emoji_shortcode(A)), quote(as_emoji_type(A)),
    quote(emoji_ambiguity()), quote(emoji_lexicons()),
    quote(emoji_provenance()), quote(emoji_unicode_version()),
    quote(emoji_unicode_releases()), quote(emoji_search("fire")),
    quote(emoji_summary(d, text)), quote(emoji_frequency(d, text)),
    quote(emoji_sentiment(d, text, se = TRUE)), quote(emoji_emotion(d, text)),
    quote(emoji_emotion_label(d, text)), quote(emoji_risk(d, text)),
    quote(emoji_score(d, text)), quote(emoji_type(d, text)),
    quote(emoji_faceness(d, text)), quote(emoji_categorize(d, text)),
    quote(emoji_tokens(d, text)), quote(emoji_dfm(d, text)),
    quote(emoji_pairs(d, text)), quote(emoji_ngrams(d, text)),
    quote(emoji_context(d, text)), quote(emoji_to_text(d, text)),
    quote(emoji_sanitize(d, text, policy = "shortcode")),
    quote(emoji_version_profile(d, text)),
    quote(emoji_trend(d, text, when)), quote(emoji_adoption_lag(d, text, when)),
    quote(emoji_incongruity(d, text, sc, scale = "none"))
  )
  for (e in calls) {
    rm(list = ls(cache, all.names = TRUE), envir = cache)
    expect_no_error(suppressWarnings(eval(e)))
  }
})

# ---------------------------------------------------------------------------
# Round 57: a cross-product sweep of every enum and flag argument -- 182
# combinations across seventeen verbs. One combination did not exist:
# emoji_cooccurrence() has no `directed`, while its own description called it
# "emoji_pairs() under another name, with one addition".

test_that("emoji_cooccurrence differs from emoji_pairs exactly as documented", {
  pairs_args <- names(formals(emoji_pairs))
  cooc_args <- names(formals(emoji_cooccurrence))
  expect_identical(setdiff(pairs_args, cooc_args), "directed")
  expect_identical(setdiff(cooc_args, pairs_args), "diagonal")
  expect_identical(intersect(pairs_args, cooc_args),
                   c("data", "text", "doc_id", "sort"))

  # so this is an error, and the help page now says why
  A <- "\U0001F600"; H <- "\U0001F60D"
  d <- data.frame(text = c(paste(A, H), paste(H, A)),
                  stringsAsFactors = FALSE)
  expect_error(emoji_cooccurrence(d, text, directed = TRUE),
               "unused argument")
  rd <- rd_flat("emoji_cooccurrence")
  expect_true(grepl("no \\code{directed} here", rd, fixed = TRUE))
  expect_true(grepl("symmetric", rd, fixed = TRUE))

  # and the claim the description does make: off the diagonal the two agree
  expect_identical(emoji_cooccurrence(d, text),
                   emoji_pairs(d, text))
  diag_rows <- emoji_cooccurrence(d, text, diagonal = TRUE)
  expect_identical(diag_rows[diag_rows$item1 != diag_rows$item2, ],
                   emoji_pairs(d, text))
})

test_that("every enum and flag combination the verbs accept works", {
  A <- "\U0001F600"; H <- "\U0001F60D"; F1 <- "\U0001F525"
  d <- data.frame(
    text = c(paste("hi", A, H), "plain", paste(F1, "hot", A), paste("wow", H),
             "", NA, paste(A, A)),
    doc = c("x", "x", "y", "y", "z", "z", "x"),
    when = as.Date("2024-01-01") + c(0, 40, 80, 120, 160, 200, 240),
    ts = as.POSIXct("2024-01-01 22:30", tz = "UTC") + (0:6) * 7200,
    sc = c(0.5, -0.2, 0.9, 0, -1, NA, 0.3),
    stringsAsFactors = FALSE
  )
  n <- 0L
  ok <- function(expr) {
    n <<- n + 1L
    v <- suppressWarnings(eval(expr))
    expect_s3_class(v, "data.frame")
    # a returned column must always be nameable
    expect_false(anyNA(names(v)))
    expect_true(all(nzchar(names(v))))
  }
  for (m in c("difference", "sign_flip")) {
    for (s in c("none", "rank", "zscore")) {
      for (w in c("all", "final")) {
        ok(bquote(emoji_incongruity(d, text, sc, method = .(m), scale = .(s),
                                    where = .(w))))
        ok(bquote(emoji_congruence(d, text, sc, method = .(m), scale = .(s),
                                   where = .(w))))
        ok(bquote(emoji_incongruity_profile(d, text, sc, method = .(m),
                                            scale = .(s), where = .(w),
                                            min_n = 1)))
      }
    }
  }
  for (wt in c("count", "binary", "tfidf")) {
    ok(bquote(emoji_dfm(d, text, weighting = .(wt))))
    ok(bquote(emoji_dfm(d, text, doc, weighting = .(wt))))
  }
  for (di in c(TRUE, FALSE)) for (so in c(TRUE, FALSE)) {
    ok(bquote(emoji_pairs(d, text, directed = .(di), sort = .(so))))
    ok(bquote(emoji_pairs(d, text, doc, directed = .(di), sort = .(so))))
    for (dg in c(TRUE, FALSE)) {
      ok(bquote(emoji_cooccurrence(d, text, sort = .(so), diagonal = .(dg))))
      ok(bquote(emoji_cooccurrence(d, text, doc, sort = .(so),
                                   diagonal = .(dg))))
    }
  }
  for (by in c("day", "week", "month", "quarter", "year")) {
    for (ms in c("n", "share")) {
      for (tn in list(1, 20, NULL)) {
        ok(bquote(emoji_trend(d, text, when, by = .(by), measure = .(ms),
                              top_n = .(tn))))
      }
    }
    for (ms in list("jaccard", "new", c("lost", "core"),
                    c("jaccard", "new", "lost", "core"))) {
      ok(bquote(emoji_turnover(d, text, when, by = .(by), measure = .(ms))))
    }
  }
  for (p in c("month", "weekday")) {
    ok(bquote(emoji_seasonality(d, text, when, period = .(p))))
  }
  ok(quote(emoji_seasonality(d, text, ts, period = "hour")))
  for (p in c("keep", "strip", "name", "shortcode", "placeholder")) {
    ok(bquote(emoji_sanitize(d, text, policy = .(p))))
  }
  for (w in c(0, 1, 5)) for (u in c("word", "char")) for (kt in c(TRUE, FALSE)) {
    ok(bquote(emoji_context(d, text, window = .(w), unit = .(u),
                            keep_text = .(kt))))
  }
  for (w in c(1, 5)) for (mn in c(0, 1, 3)) for (ms in c("pmi", "count")) {
    ok(bquote(emoji_collocations(d, text, window = .(w), min_n = .(mn),
                                 measure = .(ms))))
  }
  for (ms in c("entropy", "gini", "neutral_share", "ci_width")) {
    ok(bquote(emoji_ambiguity(measure = .(ms))))
    ok(bquote(emoji_risk(d, text, measure = .(ms))))
    ok(bquote(emoji_flag_ambiguous(d, text, measure = .(ms))))
  }
  for (f in c("name", "shortcode")) {
    ok(bquote(emoji_to_text(d, text, format = .(f))))
  }
  for (lg in c(TRUE, FALSE)) ok(bquote(emoji_emotion(d, text, long = .(lg))))
  for (du in c(TRUE, FALSE)) for (k in c(1, 3, 100)) {
    ok(bquote(top_n_emojis(d, text, n = .(k), duplicated = .(du))))
  }
  for (k in 1:4) for (sp in c(" ", "|")) {
    ok(bquote(emoji_ngrams(d, text, n = .(k), sep = .(sp))))
  }
  for (lx in c("novak2015", "emotag1200")) {
    ok(bquote(emoji_score(d, text, lexicon = .(lx))))
  }
  for (se in c(TRUE, FALSE)) ok(bquote(emoji_sentiment(d, text, se = .(se))))
  expect_gt(n, 170L)
})

# ---------------------------------------------------------------------------
# Round 58: realistic pipelines. Every verb had been tested on its own; the
# package's headline claim is that they "compose naturally with the pipe", and
# nothing had checked a chain. One chain lost data:
# emoji_emotion() |> emoji_emotion_label() dropped all eight emotion scores.

test_that("emoji_emotion_label() drops only the columns it introduced", {
  A <- "\U0001F600"; H <- "\U0001F60D"
  d <- data.frame(text = c(paste("great", A, H), "nothing", paste("meh", H)),
                  author = c("a", "b", "a"), stringsAsFactors = FALSE)
  dims <- paste0(".emoji_", c("anger", "anticipation", "disgust", "fear",
                              "joy", "sadness", "surprise", "trust"))

  # called on plain data it is still the compact form -- unchanged behaviour
  plain <- emoji_emotion_label(d, text)
  expect_identical(names(plain), c("text", "author", ".emoji_n",
                                   ".emoji_n_scored", ".emoji_emotion"))
  expect_false(any(dims %in% names(plain)))

  # but the obvious way to get the profile *and* the label keeps both
  chained <- emoji_emotion_label(emoji_emotion(d, text), text)
  expect_true(all(dims %in% names(chained)))
  expect_identical(chained$.emoji_emotion, plain$.emoji_emotion)
  wide <- emoji_emotion(d, text)
  for (cn in dims) expect_identical(chained[[cn]], wide[[cn]], info = cn)
  expect_identical(nrow(chained), nrow(d))

  # a caller's own column of that name survives the call, overwritten with the
  # computed score as the reserved-prefix rule says -- not deleted
  own <- d
  own$.emoji_joy <- c(9, 9, 9)
  kept <- emoji_emotion_label(own, text)
  expect_true(".emoji_joy" %in% names(kept))
  expect_identical(kept$.emoji_joy, wide$.emoji_joy)
})

test_that("the verbs compose in the chains a user would actually write", {
  A <- "\U0001F600"; H <- "\U0001F60D"; F1 <- "\U0001F525"
  d <- data.frame(
    text = c(paste("great", A, H), "nothing here", paste(F1, "hot", A),
             paste("meh", H), "", NA_character_, paste(A, A)),
    author = c("a", "b", "a", "b", "a", "b", "a"),
    when = as.Date("2024-01-01") + c(0, 20, 40, 60, 80, 100, 120),
    sc = c(0.8, 0.1, 0.5, -0.3, 0, NA, 0.6),
    stringsAsFactors = FALSE
  )
  chains <- list(
    quote(emoji_tokens(emoji_sentiment(emoji_filter(d, text), text), text)),
    quote(emoji_ratio(emoji_density(emoji_position(
      emoji_sentiment(d, text), text), text), text)),
    quote(emoji_risk(emoji_faceness(emoji_type(d, text), text), text)),
    quote(emoji_tokens(emoji_filter(emoji_extract_nest(d, text), text), text)),
    quote(emoji_sentiment(emoji_type(emoji_categorize(d, text), text), text)),
    quote(emoji_sentiment(emoji_sanitize(
      emoji_token_cost(d, text), text, policy = "name"), text)),
    quote(emoji_frequency(text_to_emoji(
      emoji_sanitize(d, text, policy = "shortcode"), text), text)),
    quote(emoji_congruence(emoji_incongruity(d, text, sc, scale = "none"),
                           text, sc, scale = "none")),
    # an aggregator fed a row verb's own output column
    quote(emoji_frequency(emoji_tokens(d, text), .emoji)),
    quote(emoji_frequency(emoji_context(d, text), .emoji)),
    quote(emoji_frequency(emoji_extract_unnest(d, text), .emoji_unicode)),
    quote(emoji_frequency(emoji_ngrams(d, text), .emoji_ngram)),
    quote(emoji_dfm(emoji_filter(d, text), text)),
    quote(emoji_trend(emoji_filter(d, text), text, when))
  )
  for (e in chains) {
    v <- suppressWarnings(eval(e))
    expect_s3_class(v, "data.frame")
    expect_false(anyNA(names(v)))
    expect_true(all(nzchar(names(v))))
  }

  # the grouped contract, end to end as ?tidyEmoji describes it
  g <- dplyr::group_by(d, author)
  per_author <- dplyr::summarise(
    emoji_sentiment(g, text),
    m = mean(.emoji_sentiment, na.rm = TRUE), .groups = "drop")
  expect_identical(nrow(per_author), 2L)
  # the grouping survives a chain of row verbs
  chained <- emoji_position(emoji_density(g, text), text)
  expect_true(dplyr::is_grouped_df(chained))
  expect_identical(dplyr::group_vars(chained), "author")
  # and a verb that rewrites the text column re-derives the groups when the
  # user grouped by that very column
  by_text <- emoji_sanitize(dplyr::group_by(d, text), text, policy = "name")
  expect_true(dplyr::is_grouped_df(by_text))
  expect_identical(dplyr::group_vars(by_text), "text")
  expect_true(all(dplyr::group_keys(by_text)$text %in% by_text$text))

  # re-running a row verb on its own output changes nothing
  for (v in c("emoji_sentiment", "emoji_density", "emoji_position",
              "emoji_ratio", "emoji_type", "emoji_faceness", "emoji_risk",
              "emoji_token_cost", "emoji_extract_nest", "emoji_emotion")) {
    once <- suppressWarnings(do.call(v, list(d, rlang::sym("text"))))
    twice <- suppressWarnings(do.call(v, list(once, rlang::sym("text"))))
    expect_identical(once, twice, info = v)
  }

  # after strip there is nothing left for any verb to find
  stripped <- emoji_sanitize(d, text, policy = "strip")
  expect_identical(sum(lengths(tidyEmoji:::emoji_glyph_list(stripped$text))), 0L)
  expect_identical(emoji_summary(stripped, text)$n_with_emoji, 0L)
  expect_identical(nrow(suppressWarnings(emoji_frequency(stripped, text))), 0L)
  expect_true(all(is.na(emoji_sentiment(stripped, text)$.emoji_sentiment)))
})

# ---------------------------------------------------------------------------
# Round 59: the pluggable-lexicon API, exercised through every consumer rather
# than only through emoji_score(). The one gap: emoji_score() averages emotion
# dimensions for the bundled "emotag1200" but not for a registered or inline
# lexicon of the same shape, and told the user to "supply `score`" -- a dead
# end, since `score` names a single column and they want the mean.

test_that("a registered lexicon reaches every consumer that documents it", {
  A <- "\U0001F600"; H <- "\U0001F60D"
  d <- data.frame(text = c(paste("a", A), "plain", paste("b", H)),
                  stringsAsFactors = FALSE)
  dims <- c("anger", "anticipation", "disgust", "fear", "joy", "sadness",
            "surprise", "trust")
  cache <- tidyEmoji:::.tidyEmoji_cache
  saved <- cache$lexicons
  on.exit(assign("lexicons", saved, envir = cache), add = TRUE)

  # a sentiment-shaped lexicon: emoji_score() and emoji_sentiment() agree
  sent <- data.frame(emoji = c(A, H), score = c(1, -1),
                     stringsAsFactors = FALSE)
  register_emoji_lexicon("mysent", sent)
  expect_equal(emoji_score(d, text, lexicon = "mysent")$.emoji_score,
               c(1, NA, -1))
  expect_equal(emoji_sentiment(d, text, lexicon = "mysent")$.emoji_sentiment,
               emoji_score(d, text, lexicon = "mysent")$.emoji_score)
  # se needs the bundled annotation counts, and says so
  expect_error(emoji_sentiment(d, text, lexicon = "mysent", se = TRUE),
               "novak2015")
  # and it is not an emotion lexicon
  expect_error(emoji_emotion(d, text, lexicon = "mysent"),
               "at least one emotion column")

  # an emotion-shaped lexicon, full and partial
  full <- data.frame(emoji = c(A, H), stringsAsFactors = FALSE)
  for (k in dims) full[[k]] <- c(0.8, 0.2)
  register_emoji_lexicon("myemo", full)
  wide <- emoji_emotion(d, text, lexicon = "myemo")
  expect_true(all(paste0(".emoji_", dims) %in% names(wide)))
  expect_identical(nrow(emoji_emotion(d, text, lexicon = "myemo",
                                      long = TRUE)),
                   nrow(d) * length(dims))
  expect_s3_class(emoji_emotion_label(d, text, lexicon = "myemo"), "tbl_df")

  part <- data.frame(emoji = c(A, H), joy = c(0.9, 0.1), fear = c(0.1, 0.9),
                     stringsAsFactors = FALSE)
  register_emoji_lexicon("mypart", part)
  pw <- emoji_emotion(d, text, lexicon = "mypart")
  # only the dimensions supplied, in Plutchik order -- not the input's order
  expect_identical(grep("^\\.emoji_(anger|anticipation|disgust|fear|joy|sadness|surprise|trust)$",
                        names(pw), value = TRUE),
                   c(".emoji_fear", ".emoji_joy"))
  expect_identical(emoji_emotion_label(d, text,
                                       lexicon = "mypart")$.emoji_emotion,
                   c("joy", NA, "fear"))

  # emoji_lexicons() reports all three, with their dimensions
  lx <- emoji_lexicons()
  expect_true(all(c("mysent", "myemo", "mypart") %in% lx$name))
  expect_identical(lx$dimensions[[which(lx$name == "mypart")]],
                   c("joy", "fear"))
  expect_identical(lx$dimensions[[which(lx$name == "mysent")]], "score")
  expect_true(all(is.na(lx$licence[lx$type == "custom"])))

  # inline data frames take the same paths as registered names
  expect_equal(emoji_score(d, text, lexicon = sent)$.emoji_score, c(1, NA, -1))
  expect_identical(names(emoji_emotion(d, text, lexicon = full)), names(wide))
})

test_that("emoji_score() says where to go for an emotion-shaped lexicon", {
  A <- "\U0001F600"; H <- "\U0001F60D"
  d <- data.frame(text = c(paste("a", A), "plain", paste("b", H)),
                  stringsAsFactors = FALSE)
  dims <- c("anger", "anticipation", "disgust", "fear", "joy", "sadness",
            "surprise", "trust")
  full <- data.frame(emoji = c(A, H), stringsAsFactors = FALSE)
  for (k in dims) full[[k]] <- c(0.8, 0.2)

  # the message names both escape routes, rather than "supply `score`"
  msg <- tryCatch(emoji_score(d, text, lexicon = full),
                  error = function(e) conditionMessage(e))
  expect_true(grepl("emoji_emotion()", msg, fixed = TRUE))
  expect_true(grepl("score = \"anger\"", msg, fixed = TRUE))
  expect_true(grepl("emotag1200", msg, fixed = TRUE))
  expect_false(grepl("^No score column found", msg))

  # and both routes work
  expect_equal(emoji_score(d, text, lexicon = full,
                           score = "joy")$.emoji_score, c(0.8, NA, 0.2))
  expect_s3_class(emoji_emotion(d, text, lexicon = full), "tbl_df")

  # a table with neither a score nor an emotion column keeps the plain message
  plain <- tryCatch(
    emoji_score(d, text, lexicon = data.frame(emoji = A, weight = 1)),
    error = function(e) conditionMessage(e))
  expect_true(grepl("has no score column; supply `score`", plain,
                    fixed = TRUE))
  expect_false(grepl("emotion columns", plain, fixed = TRUE))

  # the bundled emotion lexicon still averages its dimensions, exactly
  wide <- emoji_emotion(d, text)
  expect_equal(emoji_score(d, text, lexicon = "emotag1200")$.emoji_score,
               rowMeans(as.matrix(wide[, paste0(".emoji_", dims)])))
})

# ---------------------------------------------------------------------------
# Round 60: the *type* of the text column, which nothing had constrained.
# as.character() is what makes a factor column work and is harmless on a
# numeric, Date or logical one. On a list column it deparses, so the emoji
# counted came from R source text the user's data never held.

test_that("a list or data-frame text column is refused, not deparsed", {
  A <- "\U0001F600"
  dl <- tibble::tibble(text = list(c("a", A), "b", list(A)))
  # the deparse the old code scored: the glyph really is in there
  expect_true(any(grepl(A, as.character(dl$text), fixed = TRUE)))
  expect_gt(sum(lengths(tidyEmoji:::emoji_glyph_list(as.character(dl$text)))),
            0L)
  # so the column has to be refused rather than coerced
  for (v in c("emoji_sentiment", "emoji_frequency", "emoji_tokens",
              "emoji_density", "emoji_summary", "emoji_type")) {
    expect_error(do.call(v, list(dl, rlang::sym("text"))),
                 "must be a column of text", info = v)
    expect_error(do.call(v, list(dl, rlang::sym("text"))),
                 "list column", info = v)
  }
  # a data-frame column deparses the same way and is refused the same way
  dn <- tibble::tibble(a = 1:2)
  dn$text <- tibble::tibble(x = c(paste("hi", A), "p"))
  expect_error(emoji_sentiment(dn, text), "must be a column of text")

  # the atomic types stay welcome: character, factor, and the ones that simply
  # contain no emoji
  expect_s3_class(emoji_sentiment(
    tibble::tibble(text = factor(c(paste("hi", A), "p"))), text), "tbl_df")
  for (col in list(c(1L, 2L), as.Date("2024-01-01") + 0:1, c(TRUE, FALSE),
                   c(1.5, 2.5))) {
    o <- emoji_sentiment(tibble::tibble(text = col), text)
    expect_identical(o$.emoji_n, c(0L, 0L))
  }
  # POSIXlt is a list, so it must not be a *text* column -- but it is still a
  # valid `time` column, which goes through a different reader
  dt <- tibble::tibble(text = c(paste("hi", A), "p"))
  dt$ts <- as.POSIXlt(as.POSIXct("2024-01-01 10:00", tz = "UTC") + c(0, 3600))
  expect_error(emoji_sentiment(dt, ts), "must be a column of text")
  expect_s3_class(suppressWarnings(
    emoji_seasonality(dt, text, ts, period = "hour")), "tbl_df")
})

test_that("a matrix text column is refused consistently by every verb", {
  A <- "\U0001F600"
  d <- tibble::tibble(a = 1:2)
  d$text <- matrix(c("x", A, "y", "z"), nrow = 2L)
  # four cells, two rows: the old code gave emoji_sentiment() and
  # emoji_tokens() an internal tibble error naming a variable from this
  # package's source, while emoji_frequency() silently counted every cell
  for (v in c("emoji_sentiment", "emoji_frequency", "emoji_tokens",
              "emoji_dfm", "emoji_context", "emoji_position")) {
    msg <- tryCatch(suppressWarnings(do.call(v, list(d, rlang::sym("text")))),
                    error = function(e) conditionMessage(e))
    expect_true(grepl("one value per row", msg, fixed = TRUE), info = v)
    expect_true(grepl("4 for 2 rows", msg, fixed = TRUE), info = v)
  }
  # a single-column matrix has one element per row, and still works
  d1 <- tibble::tibble(a = 1:2)
  d1$text <- matrix(c(paste("hi", A), "p"), ncol = 1L)
  expect_identical(emoji_sentiment(d1, text)$.emoji_n, c(1L, 0L))
})

test_that("a non-syntactic column name is read correctly", {
  # real corpora arrive with names like "my text" or "2024"; the unquoted-name
  # path has to survive them
  A <- "\U0001F600"
  for (nm in c("my text", "2024", "NA", "if", ".emoji", "TRUE", "a b c",
               "x-y")) {
    d <- data.frame(V = c(paste("hi", A), "plain"), stringsAsFactors = FALSE)
    names(d) <- nm
    sy <- rlang::sym(nm)
    o <- emoji_sentiment(d, !!sy)
    expect_identical(o$.emoji_n, c(1L, 0L), info = nm)
    # the column keeps its name, and the verb adds to it
    expect_identical(names(o)[1L], nm, info = nm)
  }
  # tidyselect forms resolve to one column, and more than one is an error
  d <- data.frame(text = c(paste("hi", A), "plain"), other = 1:2,
                  stringsAsFactors = FALSE)
  target <- emoji_sentiment(d, text)
  for (sel in list(quote(1), "text", quote(dplyr::all_of("text")),
                   quote(dplyr::starts_with("te")))) {
    expect_identical(eval(bquote(emoji_sentiment(d, .(sel)))), target)
  }
  expect_error(emoji_sentiment(d, dplyr::everything()),
               "must select exactly one column, not 2")
})

# ---------------------------------------------------------------------------
# Round 61: the same length check round 60 gave `text`, extended to the other
# three column arguments. A matrix column holds one element per *cell*, and
# each argument failed differently -- or not at all.

test_that("every column argument requires one value per row", {
  A <- "\U0001F600"; H <- "\U0001F60D"
  base <- tibble::tibble(text = c(paste("a", A), paste("b", H)))

  # `time`: emoji_trend() and emoji_adoption_lag() said "invalid 'times'
  # argument", emoji_seasonality() "missing value where TRUE/FALSE needed",
  # and emoji_turnover() returned a result computed over periods that were
  # not in the data
  d <- base
  d$time <- matrix(c("2024-01-01", "2024-01-02", "2024-02-01", "2024-02-02"),
                   nrow = 2L)
  for (v in c("emoji_trend", "emoji_turnover", "emoji_seasonality",
              "emoji_adoption_lag")) {
    msg <- tryCatch(
      suppressWarnings(do.call(v, list(d, rlang::sym("text"),
                                       rlang::sym("time")))),
      error = function(e) conditionMessage(e))
    expect_true(grepl("`time` must have one value per row", msg, fixed = TRUE),
                info = v)
    expect_true(grepl("4 for 2 rows", msg, fixed = TRUE), info = v)
  }

  # `doc_id`: emoji_dfm() reported four documents for two rows, because it was
  # the one column read that bypassed the shared helper
  d <- base
  d$doc <- matrix(c("x", "y", "p", "q"), nrow = 2L)
  for (v in c("emoji_pairs", "emoji_cooccurrence", "emoji_dfm")) {
    msg <- tryCatch(
      suppressWarnings(do.call(v, list(d, rlang::sym("text"),
                                       rlang::sym("doc")))),
      error = function(e) conditionMessage(e))
    expect_true(grepl("`doc_id` must have one value per row", msg,
                      fixed = TRUE), info = v)
  }

  # `text_score`: a matrix is.numeric(), so the type guard passed and tibble
  # reported "Assigned data `gap` must be compatible with existing data"
  d <- base
  d$sc <- matrix(c(0.5, -0.5, 0.1, 0.9), nrow = 2L)
  expect_true(is.numeric(d$sc))
  for (v in c("emoji_incongruity", "emoji_congruence",
              "emoji_incongruity_profile")) {
    msg <- tryCatch(
      suppressWarnings(do.call(v, list(d, rlang::sym("text"),
                                       rlang::sym("sc"), scale = "none"))),
      error = function(e) conditionMessage(e))
    expect_true(grepl("`text_score` must have one value per row", msg,
                      fixed = TRUE), info = v)
  }

  # POSIXlt is a list, but length() counts times rather than components, so
  # the check does not catch it and `period = "hour"` still works
  d <- base
  d$ts <- as.POSIXlt(as.POSIXct("2024-01-01 10:00", tz = "UTC") + c(0, 3600))
  expect_identical(length(d$ts), 2L)
  expect_s3_class(suppressWarnings(
    emoji_seasonality(d, text, ts, period = "hour")), "tbl_df")

  # a one-column matrix has one element per row and is accepted everywhere
  d <- base
  d$doc <- matrix(c("x", "y"), ncol = 1L)
  expect_s3_class(emoji_dfm(d, text, doc), "tbl_df")
  d$time <- matrix(c("2024-01-01", "2024-02-01"), ncol = 1L)
  expect_s3_class(suppressWarnings(emoji_trend(d, text, time)), "tbl_df")
})

test_that("the type and length checks report in the informative order", {
  A <- "\U0001F600"
  # a data-frame column's length() is its *column* count, so the length check
  # would fire first and say nothing about the real problem
  dn <- tibble::tibble(a = 1:2)
  dn$text <- tibble::tibble(x = c(paste("hi", A), "p"))
  expect_identical(length(dn$text), 1L)
  expect_identical(nrow(dn), 2L)
  expect_error(emoji_sentiment(dn, text), "must be a column of text")
  expect_error(emoji_sentiment(dn, text), "tbl_df column")

  # a list column is caught by type, a matrix by length
  dl <- tibble::tibble(text = list(c("a", A), "b"))
  expect_error(emoji_sentiment(dl, text), "must be a column of text")
  dm <- tibble::tibble(a = 1:2)
  dm$text <- matrix(c("x", A, "y", "z"), nrow = 2L)
  expect_error(emoji_sentiment(dm, text), "must have one value per row")

  # and only one column read remains outside the shared helper: the internal
  # one inside the helper itself
  code <- pkg_code_text()
  direct <- names(code)[vapply(code, function(x) {
    grepl("data[[", x, fixed = TRUE)
  }, logical(1))]
  expect_identical(setdiff(direct, c(".emoji_col", ".emoji_text_col")),
                   character(0))
})

# ---------------------------------------------------------------------------
# Round 62: the last absorbed argument. emoji_turnover() is the only verb that
# takes several values for one argument, and match.arg(several.ok = TRUE)
# returns the ones it recognises without a word about the rest.

test_that("emoji_turnover() rejects a measure it does not know", {
  A <- "\U0001F600"; H <- "\U0001F60D"
  d <- data.frame(text = c(paste("a", A), paste("b", H)),
                  when = as.Date("2024-01-01") + c(0, 40),
                  stringsAsFactors = FALSE)
  cols <- function(ms) {
    names(suppressWarnings(emoji_turnover(d, text, when, measure = ms)))
  }

  # a typo used to return the recognised half and swallow the rest
  expect_error(suppressWarnings(
    emoji_turnover(d, text, when, measure = c("jaccard", "nope"))),
    "no option \"nope\"")
  expect_error(suppressWarnings(
    emoji_turnover(d, text, when, measure = "nope")),
    "Choose from \"jaccard\", \"new\", \"lost\", \"core\"")
  # and the message names `measure`, not match.arg()'s own 'arg'
  msg <- tryCatch(suppressWarnings(
    emoji_turnover(d, text, when, measure = "nope")),
    error = function(e) conditionMessage(e))
  expect_true(grepl("`measure`", msg, fixed = TRUE))
  expect_false(grepl("'arg'", msg, fixed = TRUE))

  # empty, NULL, NA and non-character are all refused with one message
  for (ms in list(character(0), NULL, NA_character_, 1, TRUE, list("new"))) {
    expect_error(suppressWarnings(
      emoji_turnover(d, text, when, measure = ms)),
      "must be one or more of")
  }

  # the behaviour that had to survive: partial matching, deduplication, and
  # the four-measure default
  expect_true("jaccard" %in% cols("jac"))
  expect_true(all(c("jaccard", "n_core") %in% cols(c("jac", "co"))))
  expect_identical(cols(c("new", "new")), cols("new"))
  expect_identical(
    cols(c("jaccard", "new", "lost", "core")),
    names(suppressWarnings(emoji_turnover(d, text, when))))
  # the column order follows the fixed statistic order, not the order asked for
  expect_identical(cols(c("core", "jaccard")), cols(c("jaccard", "core")))
})

# ---------------------------------------------------------------------------
# Round 64: every stop() message named against the argument the *user* typed.
# 43 messages inspected; the lexicon helpers were the exception. They serve two
# callers with different argument names -- register_emoji_lexicon(tbl = ) and
# `lexicon = ` on the three scoring verbs -- and said "`tbl`" to both, so a
# user passing a data frame as `lexicon` was told to fix an argument that
# function does not have. The same failure mode the column resolver's `arg`
# was added for.

test_that("a lexicon error names the argument the caller typed", {
  A <- "\U0001F600"
  d <- data.frame(text = paste("a", A), stringsAsFactors = FALSE)
  dims <- c("anger", "anticipation", "disgust", "fear", "joy", "sadness",
            "surprise", "trust")
  emo <- data.frame(emoji = A, stringsAsFactors = FALSE)
  for (k in dims) emo[[k]] <- 0.5

  # reached by typing `lexicon =`
  by_lexicon <- list(
    quote(emoji_score(d, text, lexicon = data.frame(emoji = A, w = 1))),
    quote(emoji_score(d, text, lexicon = data.frame(emoji = A, score = 1),
                      score = "nope")),
    quote(emoji_score(d, text, lexicon = data.frame(g = A, score = 1))),
    quote(emoji_score(d, text, lexicon = data.frame(emoji = A, score = 1),
                      by = "nope")),
    quote(emoji_score(d, text, lexicon = emo)),
    quote(emoji_sentiment(d, text, lexicon = data.frame(emoji = A, w = 1)))
  )
  for (e in by_lexicon) {
    msg <- tryCatch(eval(e), error = function(err) conditionMessage(err))
    expect_true(grepl("`lexicon`", msg, fixed = TRUE),
                info = deparse(e)[1L])
    expect_false(grepl("`tbl`", msg, fixed = TRUE), info = deparse(e)[1L])
  }

  # reached by typing `tbl =`, where `tbl` is the right name
  by_tbl <- list(
    quote(register_emoji_lexicon("z1", 42)),
    quote(register_emoji_lexicon("z2", data.frame(g = A, score = 1))),
    quote(register_emoji_lexicon("z3", data.frame(emoji = A, w = 1)))
  )
  for (e in by_tbl) {
    msg <- tryCatch(eval(e), error = function(err) conditionMessage(err))
    expect_true(grepl("`tbl`", msg, fixed = TRUE), info = deparse(e)[1L])
    expect_false(grepl("`lexicon`", msg, fixed = TRUE), info = deparse(e)[1L])
  }
})

test_that("no stop() message names an argument no function has", {
  # The general form: a message that quotes `x` in backticks should be
  # quoting something a caller can type. Helpers parameterise this through
  # `arg`, so the check is on the literals that are *not* placeholders.
  exports <- getNamespaceExports("tidyEmoji")
  typeable <- unique(unlist(lapply(exports, function(f) {
    names(formals(get(f, envir = asNamespace("tidyEmoji"))))
  })))
  # plus the names of things a caller legitimately supplies inside a lexicon,
  # and the placeholders helpers fill with the real argument at run time
  typeable <- c(typeable, "emoji", "key", "sentiment_score", "%s", "{x}",
                "emotag1200", "novak2015")

  code <- pkg_code_text()
  offenders <- character(0)
  for (fn in names(code)) {
    calls <- unlist(regmatches(code[[fn]],
      gregexpr("stop\\((?:[^()]|\\([^()]*\\))*\\)", code[[fn]])))
    for (cl in calls) {
      lits <- unlist(regmatches(cl, gregexpr('"(?:[^"\\\\]|\\\\.)*"', cl)))
      quoted <- unlist(regmatches(paste(lits, collapse = " "),
        gregexpr("`[^`]+`", paste(lits, collapse = " "))))
      quoted <- gsub("`", "", quoted)
      # a message may quote an argument *with* its value -- `se = TRUE`,
      # `period = "hour"` -- which is still naming something a caller types
      quoted <- trimws(sub("\\s*=.*$", "", quoted))
      bad <- setdiff(quoted, typeable)
      if (length(bad)) {
        offenders <- c(offenders, paste0(fn, ": ", paste(bad, collapse = ", ")))
      }
    }
  }
  expect_identical(offenders, character(0))
})

# ---------------------------------------------------------------------------
# Round 65: as.Date()'s %Y accepts a one- or two-digit year, so a column
# written dd/mm/yyyy or mm/dd/yyyy parsed -- into the year 1 -- and every time
# verb bucketed on it without a word. Found while sweeping the warnings: the
# documented promise is that unreadable values "warn and are dropped", and
# these were neither warned about nor dropped.

test_that("a two-digit-year date is not silently read as year 1", {
  E <- asNamespace("tidyEmoji")
  # what base R does, and why the guard is needed
  expect_identical(as.Date("01/02/2024", format = "%Y/%m/%d"),
                   as.Date("0001-02-20"))

  # a whole column in that shape is refused, not accepted as year 1
  expect_error(E$.emoji_as_date(c("01/02/2024", "03/04/2024")),
               "No value in `time` could be read as a date")
  # mixed with a real date, the bad one warns and is dropped, as documented
  got <- withCallingHandlers(
    E$.emoji_as_date(c("2024-01-01", "01/02/2024")),
    warning = function(w) invokeRestart("muffleWarning"))
  expect_identical(got, as.Date(c("2024-01-01", NA)))
  expect_warning(E$.emoji_as_date(c("2024-01-01", "01/02/2024")),
                 "1 value in `time` could not be read")
  # and no value lands in a year the data never mentioned
  expect_false(any(format(got, "%Y") == "0001", na.rm = TRUE))

  # every shape that worked before still works
  expect_identical(E$.emoji_as_date("2024-01-01"), as.Date("2024-01-01"))
  expect_identical(E$.emoji_as_date("2024/01/01"), as.Date("2024-01-01"))
  expect_identical(E$.emoji_as_date("2024-1-1"), as.Date("2024-01-01"))
  expect_identical(E$.emoji_as_date("2024/1/1"), as.Date("2024-01-01"))
  expect_identical(E$.emoji_as_date("2024-01-01T10:00:00Z"),
                   as.Date("2024-01-01"))
  expect_identical(E$.emoji_as_date(c("2024-01-01", NA)),
                   as.Date(c("2024-01-01", NA)))
  # a real date that is out of range still warns rather than erroring
  expect_warning(E$.emoji_as_date(c("2024-13-45", "2024-01-01")),
                 "could not be read")

  # through the verbs, end to end
  A <- "\U0001F600"
  d <- data.frame(text = rep(paste("a", A), 2),
                  when = c("01/02/2024", "03/04/2024"),
                  stringsAsFactors = FALSE)
  for (v in c("emoji_trend", "emoji_turnover", "emoji_seasonality",
              "emoji_adoption_lag")) {
    expect_error(
      suppressWarnings(do.call(v, list(d, rlang::sym("text"),
                                       rlang::sym("when")))),
      "could be read as a date", info = v)
  }
})

test_that("every warning names the argument it is about", {
  A <- "\U0001F600"
  op <- options(lifecycle_verbosity = "warning")
  on.exit(options(op), add = TRUE)
  seen <- function(f) {
    ws <- character(0)
    withCallingHandlers(try(f(), silent = TRUE),
      warning = function(w) {
        ws <<- c(ws, conditionMessage(w))
        invokeRestart("muffleWarning")
      })
    ws
  }
  # the two hand-written warnings quote the argument, singular and plural
  w1 <- seen(function() emoji_trend(
    data.frame(text = rep(paste("a", A), 3),
               when = c("2024-01-01", "x", "y"), stringsAsFactors = FALSE),
    text, when))
  expect_length(w1, 1L)
  # `time` is the argument; `when` is only the column the caller passed to it,
  # and the package's convention is to name the argument
  expect_true(grepl("`time`", w1, fixed = TRUE))
  expect_false(grepl("`when`", w1, fixed = TRUE))
  expect_true(grepl("2 values", w1, fixed = TRUE))
  expect_true(grepl('first unreadable value: "x"', w1, fixed = TRUE))

  w2 <- seen(function() emoji_incongruity(
    data.frame(text = rep(paste("a", A), 2), sc = c(Inf, 0.1),
               stringsAsFactors = FALSE), text, sc, scale = "none"))
  expect_length(w2, 1L)
  expect_true(grepl("`text_score`", w2, fixed = TRUE))

  # the deprecations name what to use instead
  w3 <- seen(function() emoji_tweets(
    data.frame(text = paste("a", A), stringsAsFactors = FALSE), text))
  expect_true(any(grepl("emoji_filter()", w3, fixed = TRUE)))
  w4 <- seen(function() top_n_emojis(
    data.frame(text = paste("a", A), stringsAsFactors = FALSE), text,
    duplicated_unicode = TRUE))
  expect_true(any(grepl("`duplicated`", w4, fixed = TRUE)))
})

# ---------------------------------------------------------------------------
# Round 66: the time axis under a different session timezone -- the same
# reproducibility class as the collation and ctype dependence this release
# fixed, and the one axis nothing had varied.

test_that("a tagged POSIXct gives the same buckets in every timezone", {
  A <- "\U0001F600"
  # instants chosen to straddle midnight, a DST boundary, and the far side of
  # the date line
  tagged <- as.POSIXct(c("2024-01-01 23:30", "2024-03-31 23:30",
                         "2024-07-01 00:30"), tz = "UTC")
  d <- data.frame(text = rep(paste("a", A), 3), stringsAsFactors = FALSE)
  d$ts <- tagged

  old <- Sys.getenv("TZ")
  on.exit(if (nzchar(old)) Sys.setenv(TZ = old) else Sys.unsetenv("TZ"),
          add = TRUE)
  ref <- NULL
  for (tz in c("UTC", "America/New_York", "Asia/Tokyo",
               "Pacific/Kiritimati")) {
    Sys.setenv(TZ = tz)
    got <- list(
      days = sort(unique(suppressWarnings(
        emoji_trend(d, text, ts, by = "day"))$.period)),
      hours = suppressWarnings(
        emoji_seasonality(d, text, ts, period = "hour"))$n_texts,
      months = suppressWarnings(
        emoji_seasonality(d, text, ts, period = "month"))$n_texts
    )
    if (is.null(ref)) ref <- got else expect_identical(got, ref, info = tz)
  }
  # and the buckets really are the UTC ones the tzone asks for
  expect_identical(ref$days,
                   as.Date(c("2024-01-01", "2024-03-31", "2024-07-01")))
  expect_identical(which(ref$hours > 0L), c(1L, 24L))   # hours 0 and 23
})

test_that("a Date column is immune to the session timezone", {
  A <- "\U0001F600"
  d <- data.frame(text = rep(paste("a", A), 3),
                  when = as.Date(c("2024-01-01", "2024-03-31", "2024-07-01")),
                  stringsAsFactors = FALSE)
  old <- Sys.getenv("TZ")
  on.exit(if (nzchar(old)) Sys.setenv(TZ = old) else Sys.unsetenv("TZ"),
          add = TRUE)
  ref <- NULL
  for (tz in c("UTC", "Asia/Tokyo", "Pacific/Kiritimati")) {
    Sys.setenv(TZ = tz)
    got <- lapply(c("day", "week", "month", "quarter", "year"), function(b) {
      sort(unique(suppressWarnings(
        emoji_trend(d, text, when, by = b))$.period))
    })
    if (is.null(ref)) ref <- got else expect_identical(got, ref, info = tz)
  }
})

test_that("an untagged POSIXct follows the session timezone, as documented", {
  A <- "\U0001F600"
  # This is correct POSIXct semantics rather than a defect -- a column with no
  # `tzone` has no timezone of its own, so R displays it in the session's and
  # the buckets follow. It is a reproducibility trap all the same, which is why
  # ?emoji_trend's `time` now says to tag the column.
  naive <- as.POSIXct(c("2024-01-01 23:30", "2024-07-01 00:30"))
  expect_true(!length(attr(naive, "tzone")) ||
                !nzchar(attr(naive, "tzone")))
  d <- data.frame(text = rep(paste("a", A), 2), stringsAsFactors = FALSE)
  d$ts <- naive

  old <- Sys.getenv("TZ")
  on.exit(if (nzchar(old)) Sys.setenv(TZ = old) else Sys.unsetenv("TZ"),
          add = TRUE)
  hours <- lapply(c("UTC", "Asia/Tokyo"), function(tz) {
    Sys.setenv(TZ = tz)
    se <- suppressWarnings(emoji_seasonality(d, text, ts, period = "hour"))
    se$.period[se$n_texts > 0L]
  })
  expect_false(identical(hours[[1L]], hours[[2L]]))

  # and the help page warns about exactly this
  rd <- rd_flat("emoji_trend")
  expect_true(grepl("tzone", rd, fixed = TRUE))
  expect_true(grepl("Tag the column", rd, fixed = TRUE))
  expect_true(grepl("immune", rd, fixed = TRUE))
})

# ---------------------------------------------------------------------------
# Round 67: tidyselect falls back to an *external vector* when a bare column
# name is absent from the data. `text` is a common variable name, so a renamed
# or misspelled column in a session that also had a `text` vector reported the
# contents of that vector as column names, plus a tidyselect deprecation
# warning advising `all_of()` -- which is not what the caller meant. Same
# failure mode as the `var` message this resolver was written to replace.

test_that("a bare column name never resolves to a variable of that name", {
  A <- "\U0001F600"
  text <- c("from the global \U0001F600", "and another \U0001F600")
  no_col <- data.frame(a = 1:2, b = 3:4, stringsAsFactors = FALSE)

  for (v in c("emoji_sentiment", "emoji_frequency", "emoji_summary",
              "emoji_tokens", "emoji_density", "emoji_dfm")) {
    msg <- tryCatch(suppressWarnings(
      do.call(v, list(no_col, rlang::sym("text")))),
      error = function(e) conditionMessage(e))
    # the package's own message, naming the argument and the missing column
    expect_true(grepl("`text` does not exist", msg, fixed = TRUE), info = v)
    # and not the contents of the caller's variable
    expect_false(grepl("from the global", msg, fixed = TRUE), info = v)
    # it lists what is actually there
    expect_true(grepl("`a`", msg, fixed = TRUE), info = v)
  }
  # no tidyselect deprecation warning either
  expect_error(emoji_sentiment(no_col, text), "does not exist")
  w <- tryCatch(emoji_sentiment(no_col, text),
                warning = function(x) conditionMessage(x),
                error = function(e) NA_character_)
  expect_true(is.na(w))

  # and where the column exists, the column wins over the global
  both <- data.frame(text = c("in the data", "no emoji here"),
                     stringsAsFactors = FALSE)
  expect_identical(emoji_summary(both, text)$n_with_emoji, 0L)
  expect_identical(nrow(emoji_frequency(both, text)), 0L)
})

test_that("the tidyselect forms still resolve through select()", {
  A <- "\U0001F600"
  d <- data.frame(text = c(paste("hi", A), "plain"), other = 1:2,
                  stringsAsFactors = FALSE)
  target <- emoji_sentiment(d, text)
  col <- "text"
  expect_identical(emoji_sentiment(d, "text"), target)
  expect_identical(emoji_sentiment(d, 1), target)
  expect_identical(emoji_sentiment(d, dplyr::all_of(col)), target)
  expect_identical(emoji_sentiment(d, dplyr::starts_with("te")), target)
  expect_error(emoji_sentiment(d, dplyr::everything()),
               "must select exactly one column, not 2")
  # a non-syntactic name still arrives as a symbol and resolves
  nsd <- data.frame(V = c(paste("hi", A), "p"), stringsAsFactors = FALSE)
  names(nsd) <- "my text"
  expect_identical(emoji_sentiment(nsd, !!rlang::sym("my text"))$.emoji_n,
                   c(1L, 0L))
  # grouped input resolves without select()'s grouping-column re-add
  g <- dplyr::group_by(d, other)
  expect_true(dplyr::is_grouped_df(emoji_sentiment(g, text)))
  expect_identical(emoji_sentiment(g, text)$.emoji_n, target$.emoji_n)
})

test_that("resolving a bare column name does not call select()", {
  # the correctness fix above is also the hot path: nearly every call names a
  # bare column, and dplyr::select() costs about a millisecond. Compare the two
  # branches rather than asserting a wall-clock number.
  skip_on_cran()
  E <- asNamespace("tidyEmoji")
  d <- tibble::tibble(text = "hi", other = 1)
  bare <- system.time(for (i in 1:500) E$.emoji_col_name(d, text))[["elapsed"]]
  viaselect <- system.time(
    for (i in 1:500) E$.emoji_col_name(d, dplyr::all_of("text")))[["elapsed"]]
  expect_lt(bare, viaselect)
  # both give the same answer
  expect_identical(E$.emoji_col_name(d, text),
                   E$.emoji_col_name(d, dplyr::all_of("text")))
})

# ---------------------------------------------------------------------------
# Round 68: the last formula in the package that no test derived
# independently, plus two scale limits nothing had reached. No defect found in
# any of them; committed so they stay verified rather than remembered.

test_that("emoji_incongruity_profile's statistics are the row gaps aggregated", {
  A <- "\U0001F600"; H <- "\U0001F60D"; F1 <- "\U0001F525"; C <- "\U0001F602"
  set.seed(31)
  emo <- c(A, H, F1, C)
  txt <- vapply(1:120, function(i) {
    k <- sample(0:3, 1L)
    paste(c("row", i, if (k) sample(emo, k, replace = TRUE)), collapse = " ")
  }, character(1))
  d <- data.frame(text = txt, sc = ((seq_along(txt) %% 21) - 10) / 10,
                  stringsAsFactors = FALSE)

  for (sc in c("none", "rank", "zscore")) {
    prof <- suppressWarnings(
      emoji_incongruity_profile(d, text, sc, scale = sc, min_n = 1))
    row <- emoji_incongruity(d, text, sc, scale = sc)

    # reference: credit every glyph in a row with that row's gap
    lst <- lapply(tidyEmoji:::emoji_glyph_list(d$text),
                  tidyEmoji:::emoji_canonical)
    g <- unlist(lst, use.names = FALSE)
    gap <- rep(row$.emoji_incongruity, lengths(lst))
    flip <- rep(row$.emoji_polarity_flip, lengths(lst))
    keep <- !is.na(gap)
    g <- g[keep]; gap <- gap[keep]; flip <- flip[keep]
    by <- split(seq_along(g), g)
    m <- match(prof$emoji, names(by))
    expect_false(anyNA(m), info = sc)

    expect_identical(prof$n,
                     vapply(by, length, integer(1), USE.NAMES = FALSE)[m],
                     info = sc)
    expect_equal(prof$mean_incongruity,
                 vapply(by, function(i) mean(gap[i]), numeric(1),
                        USE.NAMES = FALSE)[m], info = sc)
    expect_equal(prof$sd_incongruity,
                 vapply(by, function(i) {
                   if (length(i) < 2L) NA_real_ else stats::sd(gap[i])
                 }, numeric(1), USE.NAMES = FALSE)[m], info = sc)
    expect_identical(prof$n_flips,
                     vapply(by, function(i) sum(flip[i], na.rm = TRUE),
                            integer(1), USE.NAMES = FALSE)[m], info = sc)

    # the derived column, the documented sort, and the documented NA rule
    expect_equal(prof$flip_rate, prof$n_flips / prof$n, info = sc)
    expect_true(all(prof$flip_rate >= 0 & prof$flip_rate <= 1), info = sc)
    expect_identical(prof, dplyr::arrange(prof, dplyr::desc(flip_rate),
                                          dplyr::desc(n), emoji), info = sc)
    expect_identical(is.na(prof$sd_incongruity), prof$n == 1L, info = sc)
    expect_false(anyNA(prof$name), info = sc)
  }

  # min_n selects rows; it does not change any statistic
  p1 <- suppressWarnings(
    emoji_incongruity_profile(d, text, sc, scale = "rank", min_n = 1))
  p5 <- suppressWarnings(
    emoji_incongruity_profile(d, text, sc, scale = "rank", min_n = 5))
  m <- match(p5$emoji, p1$emoji)
  expect_false(anyNA(m))
  expect_equal(p5$mean_incongruity, p1$mean_incongruity[m])
  expect_identical(p5$n, p1$n[m])
  expect_true(all(p5$n >= 5L))
})

test_that("emoji_dfm holds up at its widest", {
  skip_on_cran()
  ref <- tidyEmoji:::emoji_reference()
  canon <- ref$emoji[!duplicated(ref$key)]
  # one document containing every distinct emoji: the widest table possible
  one <- data.frame(text = paste(canon, collapse = " "),
                    stringsAsFactors = FALSE)
  o <- emoji_dfm(one, text)
  expect_identical(ncol(o), length(canon) + 1L)
  expect_identical(names(o)[1L], ".row_number")
  expect_true(all(nzchar(names(o))))
  expect_identical(length(unique(names(o))), ncol(o))
  expect_true(all(as.matrix(o[, -1L]) == 1L))
  # tf-idf over a single document is zero everywhere, log(N/df) being log(1)
  expect_true(all(as.matrix(
    emoji_dfm(one, text, weighting = "tfidf")[, -1L]) == 0))

  # and a wide, multi-document table keeps its documented ordering and sums
  set.seed(4)
  docs <- vapply(1:40, function(i) paste(sample(canon, 40), collapse = " "),
                 character(1))
  big <- data.frame(text = docs, stringsAsFactors = FALSE)
  m <- emoji_dfm(big, text)
  expect_identical(nrow(m), 40L)
  expect_identical(as.integer(rowSums(as.matrix(m[, -1L]))),
                   as.integer(lengths(tidyEmoji:::emoji_glyph_list(docs))))
  cs <- colSums(as.matrix(m[, -1L]))
  glyph <- names(m)[-1L]
  expect_identical(order(-cs, glyph, method = "radix"), seq_along(glyph))
})

test_that("a missing column is reported the same way for all four arguments", {
  A <- "\U0001F600"
  # globals of each name, to be sure none is picked up
  text <- "global text"; when <- "global when"
  doc <- "global doc"; sc <- c(1, 2)
  bare <- data.frame(a = 1:2, b = 3:4, stringsAsFactors = FALSE)
  withcol <- data.frame(text = rep(paste("x", A), 2), stringsAsFactors = FALSE)

  cases <- list(
    list(quote(emoji_sentiment(bare, text)), "text", "text"),
    list(quote(emoji_trend(withcol, text, when)), "time", "when"),
    list(quote(emoji_pairs(withcol, text, doc)), "doc_id", "doc"),
    list(quote(emoji_dfm(withcol, text, doc)), "doc_id", "doc"),
    list(quote(emoji_incongruity(withcol, text, sc, scale = "none")),
         "text_score", "sc")
  )
  for (cs in cases) {
    msg <- tryCatch(suppressWarnings(eval(cs[[1L]])),
                    error = function(e) conditionMessage(e))
    expect_true(grepl(paste0("`", cs[[2L]], "` must name a column"), msg,
                      fixed = TRUE), info = deparse(cs[[1L]])[1L])
    expect_true(grepl(paste0("`", cs[[3L]], "` does not exist"), msg,
                      fixed = TRUE), info = deparse(cs[[1L]])[1L])
    expect_false(grepl("global ", msg, fixed = TRUE),
                 info = deparse(cs[[1L]])[1L])
  }
})

# ---------------------------------------------------------------------------
# Round 69: the missing-column message added last round listed every column in
# `data`, which is the caller's data and can be wide. A 500-column frame gave
# a 5074-character error and a 40-column survey export 665, burying the one
# name that is wrong behind the ones that are not; a frame with no columns
# ended "Available: ." on its own.

test_that("the missing-column message stays short however wide the data is", {
  msg <- function(d) {
    tryCatch(emoji_sentiment(d, text), error = function(e) conditionMessage(e))
  }
  wide <- function(k) {
    as.data.frame(stats::setNames(as.list(rep(1, k)), paste0("c", seq_len(k))))
  }
  for (k in c(1, 2, 5, 6, 40, 500, 2000)) {
    m <- msg(wide(k))
    expect_lt(nchar(m), 160L, label = paste0(k, " columns: ", nchar(m)))
    # the part that matters comes first and always names the argument
    expect_true(grepl("`text` must name a column", m, fixed = TRUE))
    expect_true(startsWith(m, "`text` must name a column"))
  }
  # up to five names are listed in full; beyond that the rest are counted
  expect_true(grepl("Available: `c1`, `c2`, `c3`, `c4`, `c5`.", msg(wide(5)),
                    fixed = TRUE))
  expect_true(grepl("`c5`, and 1 more.", msg(wide(6)), fixed = TRUE))
  expect_true(grepl("`c5`, and 495 more.", msg(wide(500)), fixed = TRUE))
  # and a frame with no columns says so rather than trailing off
  for (d in list(data.frame(), data.frame(row.names = 1:3))) {
    expect_true(grepl("`data` has no columns.", msg(d), fixed = TRUE))
    expect_false(grepl("Available: .", msg(d), fixed = TRUE))
  }
})

test_that("only one example touches the lexicon registry", {
  # R CMD check runs every example in one session, so a registration in one
  # topic's example is visible to every topic that sorts after it.
  # ?register_emoji_lexicon legitimately registers one -- that is what it
  # demonstrates -- but nothing else may, or a help page's printed output
  # would depend on alphabetical luck. Today `register_emoji_lexicon` sorts
  # after every lexicon-using topic; this keeps that from mattering.
  skip_on_cran()
  cache <- tidyEmoji:::.tidyEmoji_cache
  saved <- cache$lexicons
  on.exit(assign("lexicons", saved, envir = cache), add = TRUE)

  db <- tools::Rd_db("tidyEmoji")
  code_of <- function(o) {
    f <- tempfile(fileext = ".R")
    tools::Rd2ex(o, out = f)
    if (!file.exists(f)) return(NULL)
    src <- readLines(f, warn = FALSE)
    src <- src[!grepl("^###|^cleanEx|^library\\(tidyEmoji\\)", src)]
    if (!any(nzchar(trimws(src)))) return(NULL)
    paste(src, collapse = "\n")
  }
  mutators <- character(0)
  for (nm in sort(names(db))) {
    code <- code_of(db[[nm]])
    if (is.null(code)) next
    assign("lexicons", saved, envir = cache)
    before <- names(cache$lexicons)
    invisible(utils::capture.output(suppressWarnings(
      eval(parse(text = code), new.env(parent = globalenv())))))
    if (!identical(names(cache$lexicons), before)) {
      mutators <- c(mutators, nm)
    }
  }
  expect_identical(mutators, "register_emoji_lexicon.Rd")

  # and in a clean registry the bundled table is exactly the two lexicons
  assign("lexicons", NULL, envir = cache)
  lx <- emoji_lexicons()
  expect_identical(lx$name, c("novak2015", "emotag1200"))
  expect_identical(nrow(lx), 2L)
})

# ---------------------------------------------------------------------------
# Round 70: auditing this release's own changes. The bare-symbol fast path
# added for `.emoji_col_name()` tested `nm %in% names(data)`, which is true
# even when the name appears twice -- and `[[` then silently returns the
# first. dplyr::select(), which that path replaced, rejected the ambiguity.

test_that("a duplicated column name is ambiguous, not silently the first", {
  A <- "\U0001F600"
  # read.csv(check.names = FALSE) on a sheet with repeated headers does this
  dd <- data.frame(text = c(paste("has", A), "none"),
                   text = c("no emoji", "none"),
                   check.names = FALSE, stringsAsFactors = FALSE)
  expect_identical(names(dd), c("text", "text"))
  # the first column holds an emoji and the second does not, so a silent pick
  # of either is a wrong answer that looks right
  for (v in c("emoji_summary", "emoji_frequency", "emoji_sentiment",
              "emoji_tokens", "emoji_density", "emoji_dfm", "emoji_type",
              "emoji_to_text", "emoji_ratio", "emoji_position")) {
    msg <- tryCatch(suppressWarnings(
      do.call(v, list(dd, rlang::sym("text")))),
      error = function(e) conditionMessage(e))
    expect_true(grepl("matches 2 columns named `text`", msg, fixed = TRUE),
                info = v)
    expect_true(grepl("`text` matches", msg, fixed = TRUE), info = v)
  }

  # every column argument, not just `text`
  d2 <- data.frame(text = paste("a", A), w = 1, w = 2, check.names = FALSE,
                   stringsAsFactors = FALSE)
  for (cs in list(list(quote(emoji_trend(d2, text, w)), "time"),
                  list(quote(emoji_dfm(d2, text, w)), "doc_id"),
                  list(quote(emoji_pairs(d2, text, w)), "doc_id"),
                  list(quote(emoji_incongruity(d2, text, w, scale = "none")),
                       "text_score"))) {
    msg <- tryCatch(suppressWarnings(eval(cs[[1L]])),
                    error = function(e) conditionMessage(e))
    expect_true(grepl(paste0("`", cs[[2L]], "` matches 2 columns"), msg,
                      fixed = TRUE), info = deparse(cs[[1L]])[1L])
  }

  # a unique name is unaffected
  expect_identical(
    emoji_sentiment(data.frame(text = paste("a", A),
                               stringsAsFactors = FALSE), text)$.emoji_n, 1L)
})

test_that("the column guards accept every legitimate atomic class", {
  # the type guard rejects non-atomic columns; make sure that has not caught
  # anything a caller might reasonably hold text or scores in
  A <- "\U0001F600"
  cols <- list(
    difftime = as.difftime(c(1, 2), units = "days"),
    complex = c(1 + 2i, 3 + 4i),
    classed_double = structure(c(1, 2), class = "myclass"),
    factor_with_na = factor(c(paste("a", A), NA), exclude = NULL),
    AsIs = I(c(paste("a", A), "b")),
    noquote = noquote(c(paste("a", A), "b"))
  )
  for (nm in names(cols)) {
    d <- data.frame(x = 1:2)
    d$text <- cols[[nm]]
    got <- emoji_sentiment(d, text)
    expect_true(inherits(got, "tbl_df"), info = nm)
    expect_identical(nrow(got), 2L, info = nm)
    expect_identical(got$.emoji_n[1L], if (nm %in% c("factor_with_na", "AsIs",
                                                     "noquote")) 1L else 0L,
                     info = nm)
  }
  # and the type messages still fire for the arguments that need a real type
  d <- data.frame(text = rep(paste("a", A), 2), stringsAsFactors = FALSE)
  d$t <- as.difftime(c(1, 2), units = "days")
  expect_error(emoji_trend(d, text, t), "must be a Date, a POSIXct")
  expect_error(emoji_incongruity(d, text, t, scale = "none"),
               "must be a numeric column")
  # an integer score is numeric and works
  d$i <- 1:2
  expect_s3_class(emoji_incongruity(d, text, i, scale = "none"), "tbl_df")
})


# Round 71: round 3 proved emoji_context()'s bounded-slice optimisation agrees
# with its own naive version, which establishes only that the two agree -- if
# both cut the window in the same wrong place, both would still agree. This
# round verifies the window *content* against a reference that shares no code
# with the package: it masks each glyph span to spaces, splits the two sides
# with a hand-written whitespace splitter, and takes the tail/head. Same for
# emoji_collocations()'s word list, whose documented rules (lower-cased,
# outer punctuation stripped, counted once per occurrence) had no test that
# read them off an independent tokenisation.

# an independent splitter: character-by-character, no strsplit(), no regex
# alternation, nothing the package's .emoji_words() could share a bug with
.ref_split_ws <- function(s) {
  ch <- strsplit(s, "")[[1L]]
  out <- character(0)
  cur <- character(0)
  for (c1 in ch) {
    if (grepl("^[[:space:]]$", c1)) {
      if (length(cur)) {
        out <- c(out, paste(cur, collapse = ""))
        cur <- character(0)
      }
    } else {
      cur <- c(cur, c1)
    }
  }
  if (length(cur)) out <- c(out, paste(cur, collapse = ""))
  out
}

# the reference window for occurrence k: blank out every emoji span so no
# glyph can be mistaken for a word, then take the window nearest the span
.ref_window <- function(s, spans, k, window) {
  masked <- s
  for (i in seq_len(nrow(spans))) {
    n <- spans[i, "end"] - spans[i, "start"] + 1L
    masked <- paste0(substr(masked, 1L, spans[i, "start"] - 1L),
                     strrep(" ", n),
                     substr(masked, spans[i, "end"] + 1L, nchar(masked)))
  }
  st <- spans[k, "start"]
  en <- spans[k, "end"]
  lw <- .ref_split_ws(substr(masked, 1L, st - 1L))
  rw <- .ref_split_ws(substr(masked, en + 1L, nchar(masked)))
  if (window <= 0L) {
    return(c(left = "", right = ""))
  }
  c(left = paste(utils::tail(lw, window), collapse = " "),
    right = paste(utils::head(rw, window), collapse = " "))
}

test_that("emoji_context() window content matches an independent reference", {
  # seeded, so this is reproducible rather than flaky, and it runs on CRAN:
  # a platform whose grapheme or regex build differs is precisely what would
  # move a window boundary, and only a machine that is not this one can show
  # that. Trial count is set so the pair costs about a second.
  E <- asNamespace("tidyEmoji")
  A <- "\U0001F600"
  B <- "\U0001F622"
  FAM <- "\U0001F468\u200d\U0001F469\u200d\U0001F467"   # multi-code-point ZWJ
  HEART <- "\u2764\ufe0f"                               # qualified
  pieces <- c("the", "cold", "coffee", "again", "a", "b", "!", "...",
              "  ", "\t", "x")
  set.seed(71)
  compared <- 0L
  for (trial in 1:30) {
    s <- paste(sample(c(pieces, A, B, FAM, HEART), sample(3:12, 1L),
                      replace = TRUE), collapse = " ")
    locs <- E$.emoji_locations(s)[[1L]]
    if (is.null(locs) || !nrow(locs)) next
    for (w in c(0L, 1L, 2L, 4L)) {
      got <- emoji_context(tibble::tibble(text = s), text, window = w,
                           unit = "word")
      for (k in seq_len(nrow(locs))) {
        ref <- .ref_window(s, locs, k, w)
        compared <- compared + 1L
        expect_identical(got$.emoji_context_left[k], unname(ref[["left"]]),
                         info = paste0("left w=", w, " k=", k, " s=", s))
        expect_identical(got$.emoji_context_right[k], unname(ref[["right"]]),
                         info = paste0("right w=", w, " k=", k, " s=", s))
      }
    }
  }
  expect_gt(compared, 100L)
})

test_that("no neighbouring emoji ever leaks into a context window", {
  # the documented promise. Three emoji in a row: the middle one's windows
  # must reach past its neighbours to real words, never quote the neighbours.
  A <- "\U0001F600"
  B <- "\U0001F622"
  HEART <- "\u2764\ufe0f"
  s <- paste("a", A, B, "b", HEART, "c")
  for (w in c(1L, 2L, 3L)) {
    got <- emoji_context(tibble::tibble(text = s), text, window = w,
                         unit = "word")
    ctx <- c(got$.emoji_context_left, got$.emoji_context_right,
             got$.emoji_context)
    n_in_ctx <- emoji_density(tibble::tibble(text = ctx), text)$.emoji_n
    expect_true(all(n_in_ctx == 0L), info = paste("window", w))
  }
  # and the reach is real: with window >= 2 the middle emoji sees both words
  got <- emoji_context(tibble::tibble(text = s), text, window = 2L,
                       unit = "word")
  expect_identical(got$.emoji_context_left[2L], "a")
  expect_identical(got$.emoji_context_right[2L], "b c")
})

test_that("emoji_collocations() applies its documented word rules", {
  A <- "\U0001F600"
  d <- tibble::tibble(text = c(
    paste("Cold COFFEE, again!", A),      # case + trailing punctuation
    paste("...best...", A, "(day)"),      # leading and trailing
    paste("the the the", A),              # repeats inside one window
    paste("don't co-op 3rd", A)           # internal punctuation, digits
  ))
  co <- emoji_collocations(d, text, window = 5L, min_n = 1L)
  # lower-cased
  expect_identical(co$word, tolower(co$word))
  # outer punctuation stripped, inner punctuation kept
  expect_true(all(c("again", "best", "day", "don't", "co-op", "3rd") %in%
                    co$word))
  expect_false(any(c("again!", "...best...", "(day)") %in% co$word))
  # no empty word survives the stripping of a pure-punctuation token
  expect_true(all(nzchar(co$word)))
  # counted once per occurrence however often it repeats in the window
  expect_identical(co$n[co$word == "the"], 1L)
})

test_that("collocation words match an independent tokenisation", {
  E <- asNamespace("tidyEmoji")
  A <- "\U0001F600"
  ref_words <- function(s) {
    low <- chartr("ABCDEFGHIJKLMNOPQRSTUVWXYZ", "abcdefghijklmnopqrstuvwxyz", s)
    w <- .ref_split_ws(low)
    w <- sub("^[^[:alnum:]]+", "", w)
    w <- sub("[^[:alnum:]]+$", "", w)
    sort(unique(w[nzchar(w)]))
  }
  vocab <- c("cold", "Coffee", "AGAIN", "the", "best!", "(day)", "don't",
             "3rd", "caf\u00e9", "...x...")
  set.seed(72)
  for (trial in 1:40) {
    s <- paste(c(sample(vocab, sample(1:6, 1L), replace = TRUE), A,
                 sample(vocab, sample(0:4, 1L), replace = TRUE)),
               collapse = " ")
    ctx <- emoji_context(tibble::tibble(text = s), text, window = 5L,
                         unit = "word")$.emoji_context[1L]
    got <- E$.emoji_words(E$.emoji_fold(ctx))
    got <- gsub("^[^[:alnum:]]+|[^[:alnum:]]+$", "", got)
    got <- sort(unique(got[nzchar(got)]))
    expect_identical(got, ref_words(ctx), info = s)
  }
})


# Round 72: the version cluster reads `version` out of the installed emoji
# package's table and joins it to a release-date table kept in this package's
# own source. That join is the one place where a *dependency update* can break
# tidyEmoji without any change here: the day emoji ships Unicode 18, the
# reference table carries a label the release table has never heard of. R CMD
# check cannot see that coming, because the check runs against today's emoji.
# So inject the future and require the verbs to degrade rather than fail.

test_that("release dates and version ordering are self-consistent", {
  rel <- emoji_unicode_releases()
  # `version` is documented as a unique key across the two numbering series
  expect_identical(anyDuplicated(rel$version), 0L)
  # version_num is the label parsed as a number, and it is what orders the
  # table -- string ordering would put "10.0" before "9.0"
  expect_identical(rel$version_num, as.numeric(rel$version))
  expect_false(is.unsorted(rel$version_num))
  expect_false(any(is.na(rel$version_num)))
  # the two series really are the documented ones and do not overlap
  expect_setequal(unique(rel$series), c("emoji", "unicode"))
  expect_length(intersect(rel$version[rel$series == "emoji"],
                          rel$version[rel$series == "unicode"]), 0L)
  # every date is a real, plausible release date: after the first emoji went
  # into Unicode and not in the future relative to the newest row
  expect_s3_class(rel$release_date, "Date")
  expect_false(any(is.na(rel$release_date)))
  expect_true(all(rel$release_date >= as.Date("2010-01-01")))
  # within a series, a later version is never released earlier
  for (s in c("emoji", "unicode")) {
    r <- rel[rel$series == s, ]
    r <- r[order(r$version_num), ]
    expect_false(is.unsorted(r$release_date), info = s)
  }
})

test_that("every version in the reference table resolves to a release date", {
  ref <- asNamespace("tidyEmoji")$emoji_reference()
  E <- asNamespace("tidyEmoji")
  have <- unique(E$.emoji_version_label(ref$version))
  have <- have[!is.na(have)]
  expect_length(setdiff(have, emoji_unicode_releases()$version), 0L)
  # and emoji_unicode_version() is the newest of them, by number not by string
  expect_identical(emoji_unicode_version(),
                   have[which.max(as.numeric(have))])
})

test_that("a version newer than the release table degrades, never errors", {
  E <- asNamespace("tidyEmoji")
  A <- "\U0001F600"
  B <- "\U0001F97A"
  real <- E$emoji_reference()
  on.exit(assign("reference", real, envir = E$.tidyEmoji_cache), add = TRUE)
  d <- tibble::tibble(
    text = c(paste("a", A), paste("b", B), paste(A, B)),
    when = as.Date("2024-01-01") + c(0L, 10L, 20L)
  )
  key_a <- E$emoji_key(A)
  # "E18.0" is the spelling the UTS #51 data files use; "18.0" the stripped
  # one; NA is what an upstream row with no version at all looks like
  for (inject in list("18.0", "E18.0", "99.9", NA_character_)) {
    ref <- real
    ref$version[ref$key == key_a] <- inject
    assign("reference", ref, envir = E$.tidyEmoji_cache)
    lbl <- if (is.na(inject)) "NA" else inject

    p <- emoji_version_profile(d, text)
    # the glyph is still counted, and its share still belongs to the whole
    expect_equal(sum(p$share_tokens), 1, info = lbl)
    expect_identical(sum(p$n_tokens), 4L, info = lbl)
    # its row exists, carries no release date, and is not silently dropped
    unmapped <- p[is.na(p$release_date), ]
    expect_identical(nrow(unmapped), 1L, info = lbl)
    expect_identical(unmapped$n_tokens, 2L, info = lbl)
    expect_s3_class(p$release_date, "Date")

    # adoption lag keeps the glyph with an NA lag rather than dropping it or
    # inventing a date
    l <- emoji_adoption_lag(d, text, when)
    expect_identical(nrow(l), 2L, info = lbl)
    row_a <- l[l$emoji == A, ]
    expect_identical(nrow(row_a), 1L, info = lbl)
    expect_true(is.na(row_a$release_date), info = lbl)
    expect_true(is.na(row_a$lag_days), info = lbl)
    # the other glyph is unaffected
    expect_false(is.na(l$lag_days[l$emoji == B]), info = lbl)

    # and the build's reported version follows the injected label numerically
    uv <- emoji_unicode_version()
    expect_identical(uv, switch(lbl, "18.0" = "18.0", "E18.0" = "18.0",
                                "99.9" = "99.9", "16.0"), info = lbl)
  }
})


# Round 73: grouping is a contract users pipe through
# (group_by |> verb |> summarise), and it is enforced by two different
# mechanisms -- .emoji_as_tibble() passing a grouped_df straight through, and
# .emoji_regroup() re-deriving the indices for the verbs that rewrite the text
# column. An earlier round pinned 13 row verbs; seven were left out, including
# all three that go through .emoji_regroup. A stray ungroup() added anywhere in
# those seven would change semantics with nothing failing.

test_that("the row verbs the earlier group test omitted also keep grouping", {
  A <- "\U0001F600"
  B <- "\U0001F622"
  d <- dplyr::group_by(
    tibble::tibble(
      g = c("a", "a", "b", "b"),
      text = c(paste("good", A), paste("bad", B), paste("ok", A), "plain"),
      sc = c(1, -1, 0.5, 0)
    ), g)
  calls <- list(
    emoji_emotion       = function(x) emoji_emotion(x, text),
    emoji_emotion_label = function(x) emoji_emotion_label(x, text),
    emoji_incongruity   = function(x) emoji_incongruity(x, text, sc,
                                                        scale = "none"),
    emoji_congruence    = function(x) emoji_congruence(x, text, sc,
                                                       scale = "none"),
    emoji_sanitize      = function(x) emoji_sanitize(x, text),
    emoji_to_text       = function(x) emoji_to_text(x, text),
    text_to_emoji       = function(x) text_to_emoji(x, text)
  )
  for (nm in names(calls)) {
    out <- suppressWarnings(calls[[nm]](d))
    expect_true(dplyr::is_grouped_df(out), info = nm)
    expect_identical(dplyr::group_vars(out), "g", info = nm)
    # the indices are the input's, unchanged: these verbs do not move rows
    expect_identical(dplyr::group_data(out), dplyr::group_data(d), info = nm)
  }
})

test_that("the verbs that do not return `data`'s rows drop grouping", {
  # the mirror image of the test above: emoji_summary() and
  # emoji_flag_ambiguous() return corpus-wide answers and
  # emoji_extract_unnest() returns .row_number rather than the caller's
  # columns, so there is no group column left to carry. Asserting the drop
  # keeps a future "fix" from reinstating a grouping that cannot be right.
  A <- "\U0001F600"
  d <- dplyr::group_by(
    tibble::tibble(g = c("a", "a", "b"),
                   text = c(paste("x", A), paste("y", A), "plain")), g)
  for (nm in c("emoji_summary", "emoji_extract_unnest",
               "emoji_flag_ambiguous")) {
    out <- suppressWarnings(do.call(nm, list(d, rlang::sym("text"))))
    expect_false(dplyr::is_grouped_df(out), info = nm)
    expect_false("g" %in% names(out), info = nm)
  }
})

test_that(".emoji_regroup() survives a rewrite that merges two groups", {
  # The case the helper exists for, in its sharpest form: grouped by the text
  # column, where policy = "strip" maps two distinct texts onto one. Three
  # groups become two, so every index shifts. Stale indices would leave a
  # group key pointing at a row that no longer holds that value.
  A <- "\U0001F600"
  B <- "\U0001F622"
  d <- tibble::tibble(text = c(paste("a", A), paste("a", B),
                               paste("a", A), "b"))
  g <- dplyr::group_by(d, text)
  expect_identical(dplyr::n_groups(g), 3L)

  rewrites <- list(
    strip         = function(x) emoji_sanitize(x, text, policy = "strip"),
    name          = function(x) emoji_sanitize(x, text, policy = "name"),
    emoji_to_text = function(x) emoji_to_text(x, text),
    text_to_emoji = function(x) text_to_emoji(x, text)
  )
  for (nm in names(rewrites)) {
    out <- suppressWarnings(rewrites[[nm]](g))
    expect_true(dplyr::is_grouped_df(out), info = nm)
    expect_identical(dplyr::group_vars(out), "text", info = nm)
    # every group's indices point at rows that really carry its key
    gd <- dplyr::group_data(out)
    for (i in seq_len(nrow(gd))) {
      idx <- gd[[".rows"]][[i]]
      expect_true(all(idx <= nrow(out)), info = paste(nm, i))
      expect_true(all(out$text[idx] == gd$text[i]), info = paste(nm, i))
    }
    # and the result is indistinguishable from regrouping from scratch
    expect_identical(gd,
                     dplyr::group_data(dplyr::group_by(dplyr::ungroup(out),
                                                       text)),
                     info = nm)
  }
  # strip really does merge, so the test is exercising the shift it claims to
  expect_identical(
    dplyr::n_groups(suppressWarnings(rewrites$strip(g))), 2L)
})


# Round 74: a character vector whose Encoding() is "bytes" is a bag of bytes
# R refuses to read as characters -- nchar(type = "chars"), gsub(), tolower()
# and substr() all stop on one. Emoji detection is built out of exactly those,
# so such a column already failed; it failed with R's own message, which names
# no argument, no column and no remedy. Strings arrive marked this way from
# readBin()/rawToChar() and from text that was decoded with the wrong
# encoding upstream, which is also why coercing is the wrong fix: the bytes
# usually are not valid UTF-8, so enc2utf8() cannot repair them and would
# substitute replacement characters instead.

# R only keeps the "bytes" mark on a string that is not plain ASCII, so a
# fixture has to carry a non-ASCII byte to be a real test of the guard.
.bytes_str <- function(s) {
  x <- s
  Encoding(x) <- "bytes"
  x
}

test_that("the bytes fixture really is marked bytes", {
  # guards the guard: if this stops holding, every test below passes vacuously
  expect_identical(Encoding(.bytes_str("x")), "unknown")
  expect_identical(Encoding(.bytes_str("x\U0001F600")), "bytes")
})

test_that("a bytes-encoded text column is refused, naming argument and column", {
  A <- "\U0001F600"
  d <- tibble::tibble(msg = c(.bytes_str(paste("hi", A)),
                              paste("ok", A), "plain"))
  verbs <- c("emoji_sentiment", "emoji_density", "emoji_ratio",
             "emoji_position", "emoji_token_cost", "emoji_to_text",
             "emoji_extract_nest", "emoji_extract_unnest", "emoji_type",
             "emoji_context", "emoji_summary", "emoji_frequency",
             "emoji_tokens", "emoji_dfm", "emoji_categorize", "emoji_filter",
             "emoji_risk", "emoji_emotion", "emoji_faceness", "emoji_score",
             "emoji_ngrams", "emoji_pairs", "emoji_version_profile")
  seen <- character(0)
  for (v in verbs) {
    m <- tryCatch({
      suppressWarnings(do.call(v, list(d, rlang::sym("msg"))))
      NA_character_
    }, error = function(e) conditionMessage(e))
    expect_false(is.na(m), info = v)
    # the package's own message, not R's: it names the argument, the column,
    # how many values are affected, and what to do
    expect_match(m, "`text` reads column `msg`", fixed = TRUE, info = v)
    expect_match(m, "1 of 3", fixed = TRUE, info = v)
    expect_match(m, "iconv", fixed = TRUE, info = v)
    expect_false(grepl("not supported by this function", m), info = v)
    seen <- c(seen, m)
  }
  # one message, not twenty-three variations of R's internals
  expect_length(unique(seen), 1L)
})

test_that("bytes-encoded string arguments are refused too", {
  A <- "\U0001F600"
  b <- .bytes_str(paste0("x", A))
  d <- tibble::tibble(msg = paste("a", A, A))
  # `sep`, via the shared .emoji_check_string()
  expect_error(emoji_ngrams(d, msg, sep = b), "`sep` carries")
  # `query`, which reaches tolower() rather than gsub()
  expect_error(emoji_search(b), "`query` carries")
  # `wrap`: this one used to return successfully and mark the *output* column
  # bytes, so the failure surfaced later and somewhere else
  expect_error(
    emoji_to_text(d, msg, format = "shortcode",
                  wrap = .bytes_str(paste0("<{x}", A, ">"))),
    "`wrap` carries")
  # `placeholder`
  expect_error(emoji_sanitize(d, msg, policy = "placeholder", placeholder = b),
               "`placeholder` carries")
})

test_that("emoji_to_text() never returns a bytes-encoded column", {
  # the property the `wrap` guard exists to protect
  A <- "\U0001F600"
  d <- tibble::tibble(msg = c(paste("a", A), "plain", NA_character_))
  for (fmt in c("name", "shortcode")) {
    out <- emoji_to_text(d, msg, format = fmt)
    expect_false(any(Encoding(out$msg) == "bytes"), info = fmt)
    expect_true(all(validUTF8(out$msg[!is.na(out$msg)])), info = fmt)
  }
  wrapped <- emoji_to_text(d, msg, format = "shortcode",
                           wrap = paste0("<{x}", A, ">"))
  expect_false(any(Encoding(wrapped$msg) == "bytes"))
  expect_true(all(validUTF8(wrapped$msg[!is.na(wrapped$msg)])))
})

test_that("the other encodings the guard must not touch still work", {
  A <- "\U0001F600"
  # latin1-marked and unknown-marked text are readable and must pass through
  lat <- "caf\xe9 text"
  Encoding(lat) <- "latin1"
  d <- tibble::tibble(msg = c(lat, "plain ascii", enc2utf8(paste("hi", A))))
  out <- emoji_sentiment(d, msg)
  expect_identical(out$.emoji_n, c(0L, 0L, 1L))
  expect_identical(nrow(out), 3L)
  # and a factor whose levels are fine is still fine
  d2 <- tibble::tibble(msg = factor(c(paste("hi", A), "plain")))
  expect_identical(emoji_sentiment(d2, msg)$.emoji_n, c(1L, 0L))
})


# Round 75: emoji_ambiguity() ranks the whole Novak lexicon, and the head of
# that ranking is not all emoji: 233 of the 969 rows are characters the
# reference table does not carry, and three of them tie for rank 1. The docs
# explained the tie by annotation count -- correctly -- but not what those
# rows are, so a user reading rank 1 = box-drawing character had nothing to
# go on. These pin the figures the new paragraph states, both from the data
# and from the rendered Rd, because a figure quoted in prose is the thing
# most likely to drift away from the data it describes.

test_that("the ambiguity ranking's non-emoji rows are exactly as documented", {
  E <- asNamespace("tidyEmoji")
  amb <- emoji_ambiguity()
  expect_identical(nrow(amb), 969L)
  inref <- E$emoji_key(amb$emoji) %in% E$emoji_reference()$key
  expect_identical(sum(!inref), 233L)
  # 6% of the annotations, so excluding them barely moves the evidence base
  share <- sum(amb$n_annotations[!inref]) / sum(amb$n_annotations)
  expect_gt(share, 0.05)
  expect_lt(share, 0.07)
  # three of the five rows tied at rank 1 are among them
  tied <- amb$rank == 1L
  expect_identical(sum(tied), 5L)
  expect_identical(sum(!inref[tied]), 3L)
  expect_identical(sort(amb$n_annotations[tied]), c(3L, 3L, 3L, 9L, 15L))
  # and the recommended n_annotations filter removes 200 of the 233
  expect_identical(sum(amb$n_annotations[!inref] < 50L), 200L)
  expect_gt(mean(amb$n_annotations[!inref] < 50L), 0.85)
  # the three at rank 1 really are non-emoji characters, not exotic emoji:
  # a dashed arrow, a box-drawing corner and a ballot X
  r1_absent <- amb$emoji[tied & !inref]
  expect_setequal(vapply(r1_absent, utf8ToInt, integer(1), USE.NAMES = FALSE),
                  c(0x21E2L, 0x250CL, 0x2717L))
  # none of them is detectable in text under any spelling
  for (x in r1_absent) {
    expect_identical(length(E$emoji_glyph_list(x)[[1L]]), 0L)
    expect_identical(length(E$emoji_glyph_list(paste0(x, "\ufe0f"))[[1L]]), 0L)
  }
})

test_that("emoji_ambiguity()'s Rd states those figures", {
  rd <- rd_flat("emoji_ambiguity")
  expect_true(grepl("233 of its 969 rows", rd, fixed = TRUE))
  expect_true(grepl("6%", rd, fixed = TRUE))
  expect_true(grepl("200 of the 233", rd, fixed = TRUE))
  # and it points at where the rest of the story is
  expect_true(grepl("emoji_sentiment_lexicon", rd, fixed = TRUE))
})

test_that("the lexicon coverage figures in emoji_sentiment_lexicon's Rd hold", {
  # 736 / 233 / 3790 are quoted in prose; derive each from the data
  E <- asNamespace("tidyEmoji")
  lex <- tidyEmoji::emoji_sentiment_lexicon
  ref <- E$emoji_reference()
  inref <- E$emoji_key(lex$emoji) %in% ref$key
  expect_identical(nrow(lex), 969L)
  expect_identical(sum(inref), 736L)
  expect_identical(sum(!inref), 233L)
  expect_identical(length(unique(ref$key)), 3790L)
  # "about 19%" of the reference table's distinct keys
  expect_equal(round(100 * 736 / 3790), 19)
  rd <- rd_flat("emoji_sentiment_lexicon")
  expect_true(grepl("969 rows", rd, fixed = TRUE))
  expect_true(grepl("736", rd, fixed = TRUE))
  expect_true(grepl("233", rd, fixed = TRUE))
  expect_true(grepl("3790", rd, fixed = TRUE))
})


# Round 76: the lexicon API takes a whole table from the caller, and three of
# its failures were silent. register_emoji_lexicon() resolves the score column
# at registration precisely so a bad table fails there rather than later --
# but it checked only that the column existed, not that it held numbers. A
# character score column therefore registered happily, and at scoring time
# reached mean(), which returns NA with R's own warning, while
# `.emoji_n_scored` still counted the emoji as scored. The row claimed a score
# it did not have.

test_that("a non-numeric score column is refused, not silently NA", {
  A <- "\U0001F600"
  B <- "\U0001F622"
  for (col in list(character = c("1", "-1"),
                   factor = factor(c("1", "-1")))) {
    tbl <- data.frame(emoji = c(A, B))
    tbl$score <- col
    # at registration, which is where the presence check already lives
    expect_error(register_emoji_lexicon("bad_score", tbl),
                 "score column `score`")
    # and on the bare-data-frame path, which does not go through registration
    expect_error(emoji_score(tibble::tibble(text = paste("a", A)), text,
                             lexicon = tbl),
                 "score column `score`")
  }
  # the contract the fix restores: a numeric NA is *not* counted as scored,
  # so `.emoji_n_scored` and `.emoji_score` never disagree
  ok <- data.frame(emoji = c(A, B), score = c(NA_real_, -1))
  r <- emoji_score(tibble::tibble(text = c(paste("a", A), paste("b", B))),
                   text, lexicon = ok)
  expect_identical(r$.emoji_n_scored, c(0L, 1L))
  expect_identical(r$.emoji_score, c(NA_real_, -1))
  # a logical column is a number for this purpose and still works
  lg <- data.frame(emoji = c(A, B), score = c(TRUE, FALSE))
  expect_identical(
    emoji_score(tibble::tibble(text = c(paste("a", A), paste("b", B))),
                text, lexicon = lg)$.emoji_score, c(1, 0))
})

test_that("two lexicon rows for one emoji must agree on the score", {
  H <- "\u2764"
  HQ <- "\u2764\ufe0f"
  B <- "\U0001F622"
  d <- tibble::tibble(text = c(paste("love", HQ), paste("sad", B)))
  # Agreeing duplicates are the normal case, not an error: a lexicon that
  # lists both the unqualified and the qualified spelling of one emoji
  # canonicalises to a single key.
  agree <- data.frame(emoji = c(H, HQ, B), score = c(0.5, 0.5, -1))
  expect_identical(emoji_score(d, text, lexicon = agree)$.emoji_score,
                   c(0.5, -1))
  # an NA alongside a value is not a disagreement
  with_na <- data.frame(emoji = c(H, HQ, B), score = c(0.5, NA, -1))
  expect_identical(emoji_score(d, text, lexicon = with_na)$.emoji_score,
                   c(0.5, -1))
  # Disagreeing duplicates are refused, because the lookup would otherwise
  # take whichever came first -- so the caller's row order, not the caller,
  # picks the score.
  dis <- data.frame(emoji = c(H, HQ, B), score = c(0.5, -0.5, -1))
  expect_error(emoji_score(d, text, lexicon = dis), "more than one score")
  expect_error(emoji_score(d, text, lexicon = dis), "2764")
  # and the row order really did decide it, which is why this is a defect
  swapped <- dis[c(2L, 1L, 3L), ]
  expect_error(emoji_score(d, text, lexicon = swapped), "more than one score")
  # neither bundled lexicon has a duplicated key at all, so the guard cannot
  # reach them
  E <- asNamespace("tidyEmoji")
  for (nm in c("emoji_sentiment_lexicon", "emoji_emotion_lexicon")) {
    tb <- get(nm, envir = asNamespace("tidyEmoji"))
    expect_identical(anyDuplicated(E$emoji_key(tb$emoji)), 0L, info = nm)
  }
})

test_that("`by` must name a single column", {
  A <- "\U0001F600"
  tbl <- data.frame(emoji = A, other = 1L, score = 1)
  d <- tibble::tibble(text = paste("a", A))
  # `by` reaches `%in%`, so a vector used to surface R's own
  # "the condition has length > 1" with no mention of the argument
  for (bad in list(c("emoji", "other"), NA_character_, 1, character())) {
    expect_error(register_emoji_lexicon("bad_by", tbl, by = bad),
                 "`by` must be a single string")
    expect_error(emoji_score(d, text, lexicon = tbl, by = bad),
                 "`by` must be a single string")
  }
  # and the valid case is unchanged
  expect_identical(emoji_score(d, text, lexicon = tbl, by = "emoji")$.emoji_score, 1)
})

test_that("the bundled lexicon paths are unaffected by the new guards", {
  H <- "\u2764\ufe0f"
  B <- "\U0001F622"
  d <- tibble::tibble(text = c(paste("love", H), paste("sad", B)),
                      sc = c(1, -1))
  expect_false(anyNA(emoji_sentiment(d, text)$.emoji_sentiment))
  expect_false(anyNA(emoji_score(d, text)$.emoji_score))
  expect_false(anyNA(emoji_score(d, text, lexicon = "emotag1200")$.emoji_score))
  expect_false(anyNA(emoji_emotion(d, text)$.emoji_joy))
  expect_false(anyNA(emoji_incongruity(d, text, sc,
                                       scale = "none")$.emoji_incongruity))
  # emoji_score(score = <one emotion dim>) still resolves
  expect_false(anyNA(emoji_score(d, text, lexicon = "emotag1200",
                                 score = "joy")$.emoji_score))
})


# Round 77: top_n_emojis() builds `emoji_name` two different ways -- from
# `emoji_frequency()`'s `shortcode` when duplicated = FALSE, and from a
# many-to-many join onto emoji_unicode_crosswalk when TRUE. Nothing tied the
# two together, so a change to either branch could leave them disagreeing
# about what an emoji is called, and only the expanded branch is exercised by
# the collation test. Over a corpus holding every catalogued glyph, the
# single name must be the *first* of the expanded ones.

test_that("top_n_emojis()'s two naming branches agree", {
  # deterministic and about two seconds, so it runs on CRAN: the branches
  # join against the installed emoji package's catalogue, and a build whose
  # aliases differ from this one is exactly what would break the agreement
  E <- asNamespace("tidyEmoji")
  ref <- E$emoji_reference()
  d <- tibble::tibble(text = ref$emoji)
  n <- nrow(ref)
  one <- top_n_emojis(d, text, n = n)
  many <- top_n_emojis(d, text, n = n, duplicated = TRUE)

  # the expanded form can only add rows, never glyphs
  expect_setequal(unique(many$unicode), one$unicode)
  expect_gt(nrow(many), nrow(one))
  # every (glyph, name) pair appears once
  expect_identical(anyDuplicated(many[, c("unicode", "emoji_name")]), 0L)

  by_glyph <- split(many$emoji_name, many$unicode)
  single <- stats::setNames(one$emoji_name, one$unicode)
  g <- names(single)
  expect_true(all(g %in% names(by_glyph)))
  # 189 of the reference table's rows carry no alias, but canonicalisation
  # matches on the codepoint key, so a glyph borrows the alias of its other
  # spelling: no glyph ends up nameless in either branch
  expect_false(anyNA(single))
  expect_false(anyNA(many$emoji_name))
  # the single name is the first expanded name, for every glyph
  offenders <- g[!vapply(g, function(k)
    identical(single[[k]], by_glyph[[k]][[1L]]), logical(1))]
  expect_identical(offenders, character())
  # and the shared columns carry the same values in both branches
  m1 <- match(one$unicode, many$unicode)
  expect_identical(one$n, many$n[m1])
  expect_identical(one$emoji_category, many$emoji_category[m1])
})

test_that("top_n_emojis() cuts on distinct emoji, not on rows", {
  A <- "\U0001F602"
  B <- "\U0001F60D"
  d <- tibble::tibble(text = c(paste0(A, A, B), A))
  # `n` counts distinct emoji and the head is taken before the names expand,
  # so a glyph with several aliases does not eat another glyph's slot
  expect_identical(nrow(top_n_emojis(d, text, n = 1L)), 1L)
  expect_setequal(unique(top_n_emojis(d, text, n = 1L,
                                      duplicated = TRUE)$unicode), A)
  expect_gt(nrow(top_n_emojis(d, text, n = 1L, duplicated = TRUE)), 1L)
  # fewer distinct emoji than `n` returns every one, without padding
  expect_identical(nrow(top_n_emojis(d, text, n = 99L)), 2L)
  # n = 0 is a typed zero-row tibble in both branches
  for (dup in c(FALSE, TRUE)) {
    z <- top_n_emojis(d, text, n = 0L, duplicated = dup)
    expect_identical(nrow(z), 0L, info = as.character(dup))
    expect_identical(names(z), c("emoji_name", "unicode", "emoji_category",
                                 "n"), info = as.character(dup))
    expect_type(z$emoji_name, "character")
    expect_type(z$unicode, "character")
    expect_type(z$emoji_category, "character")
    expect_type(z$n, "integer")
  }
})


# Round 78: round 71 verified emoji_context(unit = "word") against a reference
# sharing no code with the package, and left unit = "char" unverified -- the
# other half of the same verb, with its own bounded-slice optimisation and its
# own "enough characters after trimming" fallback. Same treatment: mask every
# glyph span to spaces, take the code points nearest the glyph, trimming only
# the whitespace adjacent to *this* emoji.

.ref_char_window <- function(s, spans, k, window) {
  m <- s
  for (i in seq_len(nrow(spans))) {
    len <- spans[i, "end"] - spans[i, "start"] + 1L
    m <- paste0(substr(m, 1L, spans[i, "start"] - 1L), strrep(" ", len),
                substr(m, spans[i, "end"] + 1L, nchar(m)))
  }
  left <- sub("[[:space:]]+$", "", substr(m, 1L, spans[k, "start"] - 1L))
  right <- sub("^[[:space:]]+", "", substr(m, spans[k, "end"] + 1L, nchar(m)))
  if (window <= 0L) {
    return(c(left = "", right = ""))
  }
  nl <- nchar(left)
  nr <- nchar(right)
  c(left = if (!nl) "" else substr(left, max(1L, nl - window + 1L), nl),
    right = if (!nr) "" else substr(right, 1L, min(window, nr)))
}

test_that("emoji_context(unit = 'char') matches an independent reference", {
  E <- asNamespace("tidyEmoji")
  A <- "\U0001F600"
  B <- "\U0001F622"
  FAM <- "\U0001F468\u200d\U0001F469\u200d\U0001F467"
  HEART <- "\u2764\ufe0f"
  pieces <- c("the", "cold", "coffee", "a", "b", "!", "...", "  ", "\t",
              "x", "zz")
  set.seed(78)
  compared <- 0L
  # window 25 exceeds the 4 * window + 16 first slice for short strings and
  # not for long ones, so both the bounded and the full path are exercised
  for (trial in 1:40) {
    s <- paste(sample(c(pieces, A, B, FAM, HEART), sample(3:12, 1L),
                      replace = TRUE), collapse = " ")
    locs <- E$.emoji_locations(s)[[1L]]
    if (is.null(locs) || !nrow(locs)) next
    for (w in c(0L, 1L, 3L, 7L, 25L)) {
      got <- emoji_context(tibble::tibble(text = s), text, window = w,
                           unit = "char")
      for (k in seq_len(nrow(locs))) {
        r <- .ref_char_window(s, locs, k, w)
        compared <- compared + 1L
        expect_identical(got$.emoji_context_left[k], unname(r[["left"]]),
                         info = paste0("left w=", w, " k=", k, " s=", s))
        expect_identical(got$.emoji_context_right[k], unname(r[["right"]]),
                         info = paste0("right w=", w, " k=", k, " s=", s))
      }
    }
  }
  expect_gt(compared, 150L)
})

test_that("a char window never quotes a neighbouring emoji's own bytes", {
  # masked glyphs become spaces, so a neighbour can pad a char window but can
  # never appear in it
  A <- "\U0001F600"
  B <- "\U0001F622"
  s <- paste("a", A, B, "b")
  for (w in c(1L, 3L, 6L, 12L)) {
    got <- emoji_context(tibble::tibble(text = s), text, window = w,
                         unit = "char")
    ctx <- c(got$.emoji_context_left, got$.emoji_context_right,
             got$.emoji_context)
    n_in_ctx <- emoji_density(tibble::tibble(text = ctx), text)$.emoji_n
    expect_true(all(n_in_ctx == 0L), info = paste("window", w))
  }
})


# Round 79: found by mutation testing -- swapping emoji_turnover()'s `n_new`
# to compute setdiff(a, b) instead of setdiff(b, a), so that "new emoji"
# reports the *lost* count, passed the entire suite. Two tests looked like
# they covered it and neither could: test-time.R asserts n_new == 1 and
# n_lost == 1, and the invariant test above checks each against hand set
# arithmetic but over a fixture whose first period pair gains one glyph and
# loses one. Both numbers are 1, so no permutation of them is detectable.
# The assertion was right; the fixture had no teeth.

test_that("emoji_turnover() tells `new` from `lost`", {
  laugh <- "\U0001F602"
  heart_eyes <- "\U0001F60D"
  party <- "\U0001F389"
  pleading <- "\U0001F97A"
  # deliberately asymmetric: period 1 has one glyph, period 2 has three, so
  # n_new is 2 and n_lost is 0 -- swap them and the numbers change
  df <- data.frame(
    text = c(laugh, laugh,
             paste0(laugh, heart_eyes), paste0(party, pleading)),
    when = as.Date(c("2021-01-05", "2021-01-20",
                     "2021-02-10", "2021-02-25"))
  )
  out <- emoji_turnover(df, text, when, by = "month",
                        measure = c("new", "lost", "core", "jaccard"))
  expect_identical(nrow(out), 1L)
  vocab <- lapply(split(df$text, format(df$when, "%Y-%m")),
                  function(v) unique(unlist(tidyEmoji:::emoji_glyph_list(v))))
  n_new <- length(base::setdiff(vocab[[2L]], vocab[[1L]]))
  n_lost <- length(base::setdiff(vocab[[1L]], vocab[[2L]]))
  # the fixture must be able to tell them apart, or this test proves nothing
  expect_false(n_new == n_lost)
  expect_identical(out$n_new, n_new)
  expect_identical(out$n_lost, n_lost)
  # named concretely too, so the direction is readable without the set algebra
  expect_identical(out$n_new, 3L)     # heart_eyes, party, pleading arrive
  expect_identical(out$n_lost, 0L)    # laugh is still there
  expect_identical(out$n_core, 1L)    # laugh

  # and the other direction, so neither is pinned by accident
  rev_df <- df
  rev_df$when <- as.Date(c("2021-02-10", "2021-02-25",
                           "2021-01-05", "2021-01-20"))
  rev_out <- emoji_turnover(rev_df, text, when, by = "month",
                            measure = c("new", "lost"))
  expect_identical(rev_out$n_new, 0L)
  expect_identical(rev_out$n_lost, 3L)

  # n_new + n_core is the later period's vocabulary; n_lost + n_core the
  # earlier one's -- the identity that fixes which is which
  expect_identical(out$n_new + out$n_core, length(vocab[[2L]]))
  expect_identical(out$n_lost + out$n_core, length(vocab[[1L]]))
})


# Round 80: emoji_provenance() exists to be pasted into a methods section, so
# its numbers get quoted verbatim in papers. `n_emoji` was documented as "the
# size of the detectable emoji set" but reports nrow(emoji_reference()) --
# spellings, of which 212 are not detectable as written and 1252 are the
# second spelling of an emoji already counted. Reporting it as a vocabulary
# size overstates by those 1252. The value is unchanged (it is the table's
# size, which is what a provenance row should record); the documentation now
# says which quantity it is, and these pin both.

test_that("emoji_provenance()$n_emoji is the reference table's row count", {
  E <- asNamespace("tidyEmoji")
  ref <- E$emoji_reference()
  p <- emoji_provenance()
  expect_identical(p$n_emoji, nrow(ref))
  # and it is *not* the count of distinct emoji, which is what the Details
  # section now tells the reader to use instead
  n_keys <- length(unique(ref$key))
  expect_gt(p$n_emoji, n_keys)
  expect_identical(p$n_emoji - n_keys, 1252L)
  # the lexicon strings count rows the same way
  expect_true(grepl(paste0("(", nrow(tidyEmoji::emoji_sentiment_lexicon),
                           " emoji)"), p$sentiment_lexicon, fixed = TRUE))
  expect_true(grepl(paste0("(", nrow(tidyEmoji::emoji_emotion_lexicon),
                           " emoji)"), p$emotion_lexicon, fixed = TRUE))
})

test_that("no emoji is lost to an undetectable spelling", {
  # The claim that makes n_emoji's overstatement harmless rather than a bug:
  # 212 spellings are undetectable, but every distinct emoji is reachable
  # through at least one spelling that is not.
  E <- asNamespace("tidyEmoji")
  ref <- E$emoji_reference()
  det <- vapply(ref$emoji,
                function(x) length(E$emoji_glyph_list(x)[[1L]]) > 0L,
                logical(1), USE.NAMES = FALSE)
  expect_identical(sum(!det), 212L)
  expect_identical(sum(det), 4830L)
  # no key is reachable only via an undetectable spelling
  orphaned <- setdiff(unique(ref$key[!det]), unique(ref$key[det]))
  expect_identical(orphaned, character())
  expect_identical(length(unique(ref$key[det])), length(unique(ref$key)))
})

test_that("emoji_provenance()'s Rd names the quantity n_emoji counts", {
  rd <- rd_flat("emoji_provenance")
  expect_true(grepl("spellings, not", rd, fixed = TRUE))
  expect_true(grepl("3790", rd, fixed = TRUE))
  expect_true(grepl("1252", rd, fixed = TRUE))
  expect_true(grepl("212", rd, fixed = TRUE))
  # the old wording claimed it was the detectable set
  expect_false(grepl("size of the detectable emoji set", rd, fixed = TRUE))
})


# Round 81: the fixture-symmetry search from round 79, applied to every pair
# of output columns that could be swapped. Two pairs had no fixture that could
# tell them apart.
#
# emoji_seasonality()'s n_texts and n_with_emoji: the existing fixture puts
# two texts in January and both carry emoji, so both columns read 2. July has
# one text and no emoji -- the one month where they differ -- and only
# n_emoji is asserted there, for neither of them.
#
# emoji_version_profile()'s share_types and share_tokens: only
# sum(share_tokens) == 1 was ever asserted, and *both* columns sum to 1, so
# exchanging the two expressions changes nothing any test looks at.

test_that("emoji_seasonality() tells texts from texts-with-emoji", {
  grin <- "\U0001F600"
  laugh <- "\U0001F602"
  d <- data.frame(
    when = as.Date(c("2024-01-05", "2024-01-20", "2024-01-25",
                     "2024-07-03", "2024-07-09")),
    text = c(grin, paste0(grin, laugh), "plain here",
             "no emoji", paste("some", laugh))
  )
  out <- emoji_seasonality(d, text, when, period = "month")
  # January: three texts, two of them with emoji, three emoji in total
  expect_identical(out$n_texts[1L], 3L)
  expect_identical(out$n_with_emoji[1L], 2L)
  expect_identical(out$n_emoji[1L], 3L)
  # July: two texts, one with emoji, one emoji
  expect_identical(out$n_texts[7L], 2L)
  expect_identical(out$n_with_emoji[7L], 1L)
  expect_identical(out$n_emoji[7L], 1L)
  # the fixture must separate them, or none of the above proves anything
  expect_false(identical(out$n_texts, out$n_with_emoji))
  # and the ordering that fixes which is which, over every level of the cycle
  expect_true(all(out$n_with_emoji <= out$n_texts))
  expect_true(all(out$n_emoji >= out$n_with_emoji))
  # emoji_per_text divides emoji by *texts*, not by texts-with-emoji
  expect_equal(out$emoji_per_text[1L], 3 / 3)
  expect_equal(out$emoji_per_text[7L], 1 / 2)
  # a month with no texts at all is NA, not 0
  expect_true(is.na(out$emoji_per_text[2L]))
  expect_identical(out$n_texts[2L], 0L)
})

test_that("emoji_version_profile() tells type shares from token shares", {
  grin <- "\U0001F600"
  pleading <- "\U0001F97A"
  # grin appears three times, pleading once: types and tokens differ, and so
  # do their shares
  d <- data.frame(text = c(paste0(grin, grin), paste(grin, pleading)))
  vp <- emoji_version_profile(d, text)
  expect_identical(sum(vp$n_types), 2L)
  expect_identical(sum(vp$n_tokens), 4L)
  # the fixture separates the two share columns
  expect_false(identical(vp$share_types, vp$share_tokens))
  # each is derived from its own count, and both still sum to 1
  expect_equal(vp$share_types, vp$n_types / sum(vp$n_types))
  expect_equal(vp$share_tokens, vp$n_tokens / sum(vp$n_tokens))
  expect_equal(sum(vp$share_types), 1)
  expect_equal(sum(vp$share_tokens), 1)
  # concretely: grin (Emoji 1.0) is one of two types but three of four tokens
  g <- vp[vp$n_tokens == 3L, ]
  expect_identical(nrow(g), 1L)
  expect_equal(g$share_types, 0.5)
  expect_equal(g$share_tokens, 0.75)
})


# Round 82: found by shadowing `stop` inside the package namespace and running
# the suite once, which logs every guard the tests actually trigger. 53 of the
# package's 54 guards fired; one never did -- emoji_sentiment()'s fallback for
# a lexicon it cannot use. Reaching it turned out to expose two message
# defects rather than one.

test_that("emoji_sentiment() explains why an emotion lexicon will not do", {
  A <- "\U0001F600"
  d <- tibble::tibble(text = paste("a", A))
  # The only input that reaches this guard is a bundled *emotion* lexicon.
  # The old message was "`lexicon` must be 'novak2015', a registered lexicon,
  # or a data frame" -- telling a user whose name is perfectly valid that it
  # is not, and pointing nowhere.
  for (nm in c("emotag1200", "emotion", "emoji_emotion_lexicon")) {
    expect_error(emoji_sentiment(d, text, lexicon = nm),
                 "is an emotion lexicon", info = nm)
    expect_error(emoji_sentiment(d, text, lexicon = nm),
                 "emoji_emotion()", fixed = TRUE, info = nm)
    # and it names the verb that *can* collapse it to one number
    expect_error(emoji_sentiment(d, text, lexicon = nm),
                 "emoji_score(lexicon", fixed = TRUE, info = nm)
    # the advice is actionable: both suggested calls work
    expect_s3_class(emoji_emotion(d, text, lexicon = nm), "tbl_df")
    expect_s3_class(emoji_score(d, text, lexicon = nm), "tbl_df")
  }
})

test_that("the lexicon guard describes what it accepts, and NULL is not it", {
  A <- "\U0001F600"
  d <- tibble::tibble(text = paste("a", A))
  # The message used to offer "or NULL for the default" -- an option this very
  # guard rejects, since is.character(NULL) is FALSE, and which no verb
  # accepts or documents.
  for (v in list(NULL, 42, list(), TRUE)) {
    expect_error(emoji_sentiment(d, text, lexicon = v),
                 "must be a single lexicon name or a data frame")
    expect_error(emoji_score(d, text, lexicon = v),
                 "must be a single lexicon name or a data frame")
  }
  expect_error(emoji_sentiment(d, text, lexicon = NULL), "not NULL", fixed = TRUE)
  # no message may still advertise NULL
  m <- tryCatch(emoji_sentiment(d, text, lexicon = NULL), error = conditionMessage)
  expect_false(grepl("NULL for the default", m, fixed = TRUE))

  # A length-2 name reached `%in%` inside an `if`, so R answered with "the
  # condition has length > 1"; character(0) with "argument is of length zero";
  # and NA_character_ fell through to a misleading "Unknown lexicon `NA`".
  for (v in list(c("novak2015", "emotag1200"), character(0), NA_character_)) {
    m <- tryCatch(emoji_sentiment(d, text, lexicon = v), error = conditionMessage)
    expect_match(m, "must be a single lexicon name or a data frame")
    expect_false(grepl("condition has length", m, fixed = TRUE))
    expect_false(grepl("argument is of length zero", m, fixed = TRUE))
    expect_false(grepl("Unknown lexicon", m, fixed = TRUE))
  }
  # and every name that is valid still resolves, through every alias
  for (nm in c("novak2015", "sentiment", "emoji_sentiment_lexicon")) {
    expect_s3_class(emoji_sentiment(d, text, lexicon = nm), "tbl_df")
  }
  expect_error(emoji_sentiment(d, text, lexicon = "nope"), "Unknown lexicon")
})


# Round 83: the deprecated `duplicated_unicode` converted with
# `isTRUE(x) || identical(x, "yes")`, which collapses everything it does not
# recognise to FALSE. So `duplicated_unicode = "TRUE"` and `= 1` -- both
# plausible for an argument that once took a string -- silently returned the
# *opposite* of what was asked, and NA and character(0) passed unnoticed.
# The replacement `duplicated` rejects all of them through .emoji_check_flag(),
# so the deprecated spelling was the more permissive of the two.

test_that("the deprecated flag still accepts every value it ever meant", {
  A <- "\U0001F600"
  d <- tibble::tibble(text = c(paste(A, A), "plain"))
  wide <- suppressWarnings(top_n_emojis(d, text, duplicated = TRUE))
  narrow <- top_n_emojis(d, text, duplicated = FALSE)
  expect_gt(nrow(wide), nrow(narrow))   # the fixture separates the two modes

  # TRUE / FALSE / "yes" / "no" are the values this argument ever took, and
  # each still gives exactly what the modern spelling gives
  for (v in list(TRUE, "yes")) {
    expect_identical(suppressWarnings(
      top_n_emojis(d, text, duplicated_unicode = v)), wide,
      info = paste(class(v), v))
  }
  for (v in list(FALSE, "no")) {
    expect_identical(suppressWarnings(
      top_n_emojis(d, text, duplicated_unicode = v)), narrow,
      info = paste(class(v), v))
  }
  # and it is deprecated, so it warns. lifecycle dedups per call site, and the
  # loop above already spent that budget, so force verbosity as the other
  # deprecation tests in this file do.
  op <- options(lifecycle_verbosity = "warning")
  on.exit(options(op), add = TRUE)
  expect_warning(top_n_emojis(d, text, duplicated_unicode = TRUE),
                 "duplicated_unicode")
  expect_warning(top_n_emojis(d, text, duplicated_unicode = "no"),
                 "duplicated_unicode")
})

test_that("the deprecated flag no longer swallows what it cannot read", {
  A <- "\U0001F600"
  d <- tibble::tibble(text = c(paste(A, A), "plain"))
  # every one of these used to return the narrow form without complaint --
  # the opposite answer, for the two that plainly mean TRUE
  for (v in list("TRUE", "true", "Yes", 1, 0, NA, NA_character_,
                 character(0), c(TRUE, TRUE), list())) {
    expect_error(
      suppressWarnings(top_n_emojis(d, text, duplicated_unicode = v)),
      "takes TRUE, FALSE",
      info = paste(class(v)[1L], length(v)))
  }
  # the message names the replacement, since the argument is deprecated anyway
  m <- tryCatch(suppressWarnings(
    top_n_emojis(d, text, duplicated_unicode = 1)), error = conditionMessage)
  expect_match(m, "duplicated = TRUE", fixed = TRUE)
  # and the modern argument is unchanged: still strictly TRUE or FALSE
  expect_error(top_n_emojis(d, text, duplicated = "yes"),
               "must be TRUE or FALSE")
  expect_error(top_n_emojis(d, text, duplicated = NA),
               "must be TRUE or FALSE")
})


# Round 84: match.arg() reports its own formal, so fifteen of the package's
# sixteen enum arguments answered a typo with "'arg' should be one of ..." --
# naming a variable the caller never wrote. emoji_turnover() had been given a
# hand-rolled check for exactly that reason, with a comment saying so, and the
# fix was never carried to the other fifteen. They now share
# .emoji_match_arg(), which keeps match.arg()'s behaviour (whole-choice-vector
# means the default, exact match wins, unambiguous prefixes resolve) and only
# changes the message.
#
# Converting them meant writing each choice set at the call site, since
# match.arg(x) reads it from the formal and the helper cannot. That is the
# risk this round introduces, so the first test derives every choice set from
# the formals and requires the message to list exactly it.

test_that("every enum argument's message lists exactly its formal's choices", {
  # verb, argument
  enums <- list(
    c("emoji_context", "unit"), c("emoji_collocations", "measure"),
    c("emoji_dfm", "weighting"), c("emoji_to_text", "format"),
    c("emoji_seasonality", "period"), c("emoji_trend", "measure"),
    c("emoji_incongruity", "method"), c("emoji_incongruity", "where")
    # `scale` is deliberately defaultless -- the package makes the caller
    # choose -- so its choices exist only at the .emoji_match_arg() call and
    # cannot be derived here. The leak test below covers it.
  )
  A <- "\U0001F600"
  d <- tibble::tibble(text = c(paste("a", A, A), paste("b", A)),
                      sc = c(1, -1),
                      when = as.Date(c("2024-01-01", "2024-03-01")))
  base_args <- function(verb) {
    switch(verb,
      emoji_context = list(d, rlang::sym("text")),
      emoji_collocations = list(d, rlang::sym("text"), min_n = 1L),
      emoji_dfm = list(d, rlang::sym("text")),
      emoji_to_text = list(d, rlang::sym("text")),
      emoji_seasonality = list(d, rlang::sym("text"), rlang::sym("when")),
      emoji_trend = list(d, rlang::sym("text"), rlang::sym("when")),
      emoji_incongruity = list(d, rlang::sym("text"), rlang::sym("sc"),
                               scale = "none"))
  }
  for (e in enums) {
    verb <- e[[1L]]
    arg <- e[[2L]]
    fo <- formals(get(verb, envir = asNamespace("tidyEmoji")))
    # the formal's default is the choice vector for these arguments. Test the
    # emptiness inline: a defaultless formal is the empty symbol, and binding
    # it first raises "argument is missing".
    expect_false(is.symbol(fo[[arg]]) && !nzchar(as.character(fo[[arg]])),
                 info = paste(verb, arg))
    choices <- eval(fo[[arg]])
    expect_true(is.character(choices) && length(choices) > 1L,
                info = paste(verb, arg))
    args <- base_args(verb)
    args[[arg]] <- "no-such-option"
    m <- tryCatch(suppressWarnings(do.call(verb, args)),
                  error = conditionMessage)
    expect_type(m, "character")
    # the argument is named, and every choice is offered
    expect_match(m, paste0("`", arg, "`"), fixed = TRUE,
                 info = paste(verb, arg))
    for (ch in choices) {
      expect_match(m, paste0('"', ch, '"'), fixed = TRUE,
                   info = paste(verb, arg, ch))
    }
    # and nothing that is not a choice is offered
    listed <- regmatches(m, gregexpr('"[^"]+"', m))[[1L]]
    listed <- gsub('"', "", listed)
    expect_setequal(setdiff(listed, "no-such-option"), choices)
  }
})

test_that("no enum message leaks match.arg()'s own formal name", {
  A <- "\U0001F600"
  d <- tibble::tibble(text = c(paste("a", A, A), paste("b", A)),
                      sc = c(1, -1),
                      when = as.Date(c("2024-01-01", "2024-03-01")))
  calls <- list(
    unit = function(v) emoji_context(d, text, unit = v),
    policy = function(v) emoji_sanitize(d, text, policy = v),
    format = function(v) emoji_to_text(d, text, format = v),
    weighting = function(v) emoji_dfm(d, text, weighting = v),
    period = function(v) emoji_seasonality(d, text, when, period = v),
    by_trend = function(v) emoji_trend(d, text, when, by = v),
    by_turnover = function(v) emoji_turnover(d, text, when, by = v),
    measure_trend = function(v) emoji_trend(d, text, when, measure = v),
    measure_amb = function(v) emoji_ambiguity(measure = v),
    measure_risk = function(v) emoji_risk(d, text, measure = v),
    measure_turnover = function(v) emoji_turnover(d, text, when, measure = v),
    measure_colloc = function(v) emoji_collocations(d, text, min_n = 1L,
                                                    measure = v),
    method = function(v) emoji_incongruity(d, text, sc, scale = "none",
                                           method = v),
    where = function(v) emoji_incongruity(d, text, sc, scale = "none",
                                          where = v),
    scale = function(v) emoji_incongruity(d, text, sc, scale = v)
  )
  # both the shapes match.arg() answers for: an unknown value, and more than
  # one where one is wanted
  for (nm in names(calls)) {
    for (v in list("zzz", c("zzz", "qqq"))) {
      m <- tryCatch(suppressWarnings(calls[[nm]](v)), error = conditionMessage)
      expect_type(m, "character")
      expect_false(grepl("'arg'", m, fixed = TRUE),
                   info = paste(nm, length(v)))
      expect_false(grepl("should be one of", m, fixed = TRUE),
                   info = paste(nm, length(v)))
      expect_false(grepl("must be of length 1", m, fixed = TRUE),
                   info = paste(nm, length(v)))
      expect_match(m, "`", fixed = TRUE, info = paste(nm, length(v)))
    }
  }
})

test_that(".emoji_match_arg() keeps match.arg()'s accepting behaviour", {
  f <- asNamespace("tidyEmoji")$.emoji_match_arg
  ch <- c("word", "char")
  # the whole choice vector means "no value supplied": take the first
  expect_identical(f(ch, ch, "unit"), "word")
  # exact and unambiguous-prefix matches resolve
  expect_identical(f("word", ch, "unit"), "word")
  expect_identical(f("char", ch, "unit"), "char")
  expect_identical(f("w", ch, "unit"), "word")
  expect_identical(f("cha", ch, "unit"), "char")
  # an ambiguous prefix is refused rather than guessed
  amb <- c("count", "core")
  expect_error(f("co", amb, "measure"), "has no option")
  expect_identical(f("cou", amb, "measure"), "count")
  # case matters, as it does for match.arg()
  expect_error(f("Word", ch, "unit"), "has no option")
  # and the shapes that are not a single string
  for (v in list(NA_character_, character(0), 1, TRUE, NULL, list("word"))) {
    expect_error(f(v, ch, "unit"), "must be a single string")
  }
  # the count is reported when several were given
  expect_error(f(c("word", "char", "word"), ch, "unit"), "You gave 3")
})


# Round 85: .emoji_warn_grouped()'s own comment says it exists because
# "silently ignoring a grouping turns a per-group question into a global one",
# and that seven aggregators went without it because it was written where the
# problem was noticed and never grepped across. Round 73 pinned which verbs
# keep a grouping and which drop it -- but not whether the droppers *say so*.
# Three do not: emoji_ngrams(), emoji_extract_unnest() and emoji_context().
# All three are defensible, because each returns `.row_number` and none of the
# caller's columns and none of them pools rows, so no per-group answer is
# being quietly globalised. That is a real distinction, and it was recorded
# nowhere: of 37 help pages only two mentioned grouping, both promising it is
# kept. It is now documented on all four reshapers, and the three-way
# classification is a contract here so a new verb cannot join the silent
# category by accident.

test_that("every data-first verb keeps a grouping, warns, or is a reshaper", {
  # the reshapers: they return `.row_number` instead of the caller's columns,
  # so there is no grouping column to carry. A closed list on purpose --
  # adding a fourth has to be a deliberate edit here.
  reshapers <- c("emoji_ngrams", "emoji_extract_unnest", "emoji_context")
  d <- dplyr::group_by(cbind(contract_fixture(), g = c("a", "b")), g)
  verbs <- data_first_verbs()
  expect_gt(length(verbs), 30L)

  kept <- character()
  warned <- character()
  silent <- character()
  for (n in verbs) {
    w <- NULL
    out <- withCallingHandlers(call_verb(n, d), warning = function(x) {
      w <<- c(w, conditionMessage(x))
      invokeRestart("muffleWarning")
    })
    if (dplyr::is_grouped_df(out)) {
      kept <- c(kept, n)
      # keeping the grouping means keeping the column it names
      expect_true("g" %in% names(out), info = n)
      expect_identical(dplyr::group_vars(out), "g", info = n)
    } else if (length(w)) {
      warned <- c(warned, n)
    } else {
      silent <- c(silent, n)
    }
  }
  # the silent set is exactly the documented reshapers
  expect_setequal(silent, reshapers)
  # and every one of them really does return `.row_number` and none of `data`
  for (n in reshapers) {
    out <- call_verb(n, d)
    expect_true(".row_number" %in% names(out), info = n)
    expect_false("g" %in% names(out), info = n)
    expect_false("text" %in% names(out), info = n)
  }
  # both other groups are populated, so the classification is not vacuous
  expect_gt(length(kept), 5L)
  expect_gt(length(warned), 5L)
  # a verb that warns must not also return the grouping column: that would be
  # the confusing middle case, warning about a grouping it went on to keep
  for (n in warned) {
    out <- suppressWarnings(call_verb(n, d))
    expect_false(dplyr::is_grouped_df(out), info = n)
  }
})

test_that("the reshapers document that they drop the caller's columns", {
  for (topic in c("emoji_ngrams", "emoji_extract_unnest", "emoji_context")) {
    rd <- rd_flat(topic)
    expect_match(rd, "columns of \\code{data} are not carried", fixed = TRUE,
                 info = topic)
    expect_match(rd, ".row_number", fixed = TRUE, info = topic)
  }
  # and the two that keep your columns say that instead
  for (topic in c("emoji_extract_nest", "emoji_tokens")) {
    expect_match(rd_flat(topic), "grouped input stays grouped", fixed = TRUE,
                 info = topic)
  }
})


# Round 86: the statistical core, verified against the raw annotation counts
# rather than against itself. These are numbers that go into papers, and the
# suite already pinned several of them -- the log(3) ceiling, ci_width as
# 2 * qnorm(0.975) * se, the median of 18, the 69% share, 11 of the top 20 --
# but four things it did not.

test_that("all four ambiguity measures recompute from the raw counts", {
  E <- asNamespace("tidyEmoji")
  lex <- tidyEmoji::emoji_sentiment_lexicon
  tab <- E$emoji_ambiguity_table()
  neg <- as.numeric(lex$negative)
  neu <- as.numeric(lex$neutral)
  pos <- as.numeric(lex$positive)
  n <- neg + neu + pos
  k <- E$emoji_key(lex$emoji)
  keep <- !is.na(k) & !duplicated(k)
  p <- cbind(neg / n, neu / n, pos / n)[keep, , drop = FALSE]
  ord <- match(tab$key, k[keep])
  expect_false(anyNA(ord))

  # Shannon entropy in nats, 0 log 0 taken as 0
  expect_equal(tab$entropy, -rowSums(ifelse(p <= 0, 0, p * log(p)))[ord])
  # Gini impurity, and its documented ceiling of 2/3 at a three-way even split
  expect_equal(tab$gini, (1 - rowSums(p^2))[ord])
  expect_true(all(tab$gini >= 0 & tab$gini <= 2 / 3 + 1e-12))
  expect_equal(tab$neutral_share, p[ord, 2L])
  # Var(X) for X in {-1, 0, 1}: E[X^2] - E[X]^2, then the SE of the mean
  score <- p[, 3L] - p[, 1L]
  se <- sqrt(pmax(p[, 3L] + p[, 1L] - score^2, 0) / n[keep])
  expect_equal(tab$se, se[ord])
  expect_equal(tab$ci_width, (2 * stats::qnorm(0.975) * se)[ord])
  # every one of the 969 rows, not a sample of them
  expect_identical(nrow(tab), 969L)
})

test_that("the score map and the se map cover exactly the same emoji", {
  # This is what makes .emoji_sentiment_se's denominator the same as
  # .emoji_n_scored: the mean drops glyphs the *score* map cannot score, and
  # the SE drops glyphs the *se* map cannot. If the two sets ever diverged,
  # the standard error would be the error of a mean nobody computed.
  E <- asNamespace("tidyEmoji")
  sm <- E$emoji_sentiment_map()
  em <- E$emoji_sentiment_se_map()
  expect_setequal(names(sm), names(em))
  expect_identical(length(sm), length(em))
  expect_false(anyNA(sm))
  expect_false(anyNA(em))
  # and the property it buys, over a corpus of many glyphs at once
  set.seed(86)
  lex <- tidyEmoji::emoji_sentiment_lexicon
  d <- tibble::tibble(text = c(
    vapply(1:40, function(i)
      paste(sample(lex$emoji, sample(1:4, 1L)), collapse = " "),
      character(1)),
    "no emoji", ""))
  out <- emoji_sentiment(d, text, se = TRUE)
  lst <- E$emoji_glyph_list(d$text)
  n_se <- vapply(lst, function(g) {
    if (!length(g)) return(NA_integer_)
    sum(!is.na(em[E$emoji_key(g)]))
  }, integer(1))
  expect_identical(as.integer(out$.emoji_n_scored), n_se)
  # the SE itself, propagated independently
  ref <- vapply(lst, function(g) {
    if (!length(g)) return(NA_real_)
    s <- em[E$emoji_key(g)]
    s <- s[!is.na(s)]
    if (!length(s)) return(NA_real_) else sqrt(sum(s^2)) / length(s)
  }, numeric(1))
  expect_equal(out$.emoji_sentiment_se, ref)
  expect_identical(is.na(out$.emoji_sentiment_se), is.na(ref))
})

test_that("the entropy/annotation-count correlation is as documented", {
  # ?emoji_ambiguity: "entropy is positively correlated with the annotation
  # count overall (Spearman 0.56)" -- the sentence that stops a reader
  # concluding the low-n bias runs through the whole ranking
  a <- emoji_ambiguity()
  rho <- suppressWarnings(stats::cor(a$ambiguity, a$n_annotations,
                                     method = "spearman",
                                     use = "complete.obs"))
  expect_gt(rho, 0)
  expect_equal(round(rho, 2), 0.56)
  rd <- rd_flat("emoji_ambiguity")
  expect_match(rd, "Spearman 0.56", fixed = TRUE)
})


# Round 87: emoji_type()'s recode maps the ten Unicode groups the catalogue
# currently uses and starts from NA, so a group added to Unicode after the
# installed emoji package was built has no type at all. Today nothing falls
# through -- all 5042 rows type -- but the NA path is reachable in principle,
# and `.emoji_type` then means two different things: "no emoji" and "emoji I
# cannot type". emoji_categorize() documents exactly that conflation for
# `.emoji_category`; emoji_type() documented only the first half.

test_that("the type recode covers every group in the catalogue", {
  E <- asNamespace("tidyEmoji")
  ref <- E$emoji_reference()
  ty <- E$.emoji_type_of(ref$group, ref$subgroup)
  # nothing in the current catalogue falls through
  expect_false(anyNA(ty))
  expect_identical(length(ty), nrow(ref))
  # and every type produced is one of the declared levels
  expect_true(all(ty %in% emoji_type_levels()))
  # the levels are all reachable, so none is dead
  expect_setequal(unique(ty), emoji_type_levels())
  # a group the recode has never seen yields NA rather than erroring or
  # silently landing in a catch-all bucket
  expect_true(is.na(E$.emoji_type_of("Weather & Sky", "cloud")))
  expect_true(is.na(E$.emoji_type_of(NA_character_, "x")))
  expect_identical(E$.emoji_type_of("Smileys & Emotion", "face-smiling"),
                   "face")
})

test_that("an untypable emoji is distinguishable from no emoji", {
  E <- asNamespace("tidyEmoji")
  A <- "\U0001F600"
  B <- "\U0001F602"
  d <- data.frame(text = c(paste("a", A, B), paste("b", A), "none"),
                  stringsAsFactors = FALSE)
  # force one glyph untyped, as a future Unicode group would be
  invisible(as_emoji_type(A))
  old <- E$.tidyEmoji_cache$type
  on.exit(assign("type", old, envir = E$.tidyEmoji_cache), add = TRUE)
  m <- old
  m[E$emoji_key(A)] <- NA_character_
  assign("type", m, envir = E$.tidyEmoji_cache)

  ty <- emoji_type(d, text)
  # row 2's only emoji cannot be typed, so .emoji_type is NA -- the same value
  # row 3 gets for having no emoji at all. That is the documented conflation.
  expect_true(is.na(ty$.emoji_type[2L]))
  expect_true(is.na(ty$.emoji_type[3L]))
  # the row keeps its other emoji's type rather than being dropped
  expect_identical(ty$.emoji_type[1L], "face")
  expect_identical(nrow(ty), 3L)

  # emoji_faceness() is what tells the two apart: 0 typed vs NA typed
  fc <- emoji_faceness(d, text)
  expect_identical(fc$.emoji_n_typed, c(1L, 0L, NA_integer_))
  expect_identical(fc$.emoji_n_face, c(1L, 0L, NA_integer_))
  # and the share is over typable emoji, so no division by zero
  expect_equal(fc$.emoji_faceness, c(1, NA, NA))
  # the untyped glyph leaves .emoji_n alone: it is still an emoji
  expect_identical(fc$.emoji_n, c(2L, 1L, 0L))
  expect_true(is.na(as_emoji_type(A)))
})

test_that("emoji_type()'s Rd documents both reasons for NA", {
  rd <- rd_flat("emoji_type")
  expect_match(rd, "two different reasons", fixed = TRUE)
  expect_match(rd, "cannot be typed", fixed = TRUE)
  expect_match(rd, "emoji_faceness", fixed = TRUE)
})


# Round 88: the NA-for-two-reasons class, swept across every verb rather than
# found one at a time. Over a fixture holding all three causes -- a row with
# no emoji, a row whose emoji the lexicon/recode cannot use, and an NA text --
# the design turns out uniform: every *answer* column is NA for all three,
# and every *count* column is 0 for "had emoji I could not use" and NA for
# "had no emoji". That is the contract emoji_sentiment() states and
# emoji_score(), emoji_emotion() and emoji_risk() restate. Two verbs carrying
# the same count column never said it: emoji_faceness() and
# emoji_incongruity().

test_that("a count column is 0 for unusable emoji and NA for none", {
  E <- asNamespace("tidyEmoji")
  A <- "\U0001F600"
  # a glyph that is detected but absent from the bundled lexicons
  fresh <- "\U0001FAE9"
  skip_if(length(E$emoji_glyph_list(fresh)[[1L]]) == 0L,
          "the unscorable fixture glyph is not detected by this build")
  skip_if(E$emoji_key(fresh) %in% names(E$emoji_sentiment_map()),
          "the unscorable fixture glyph is scorable in this build")
  d <- tibble::tibble(
    text = c(paste("hi", A), "plain text", paste("hi", fresh), NA_character_),
    sc = c(1, 0, -1, 0.5))

  # the four verbs that document the distinction, and the two that now do
  checks <- list(
    emoji_sentiment = function() emoji_sentiment(d, text),
    emoji_score     = function() emoji_score(d, text),
    emoji_emotion   = function() emoji_emotion(d, text),
    emoji_risk      = function() emoji_risk(d, text),
    emoji_incongruity = function() emoji_incongruity(d, text, sc,
                                                     scale = "none")
  )
  for (nm in names(checks)) {
    out <- suppressWarnings(checks[[nm]]())
    expect_identical(out$.emoji_n, c(1L, 0L, 1L, 0L), info = nm)
    # row 3 had an emoji the lexicon could not score: 0, not NA
    expect_identical(out$.emoji_n_scored, c(1L, NA_integer_, 0L, NA_integer_),
                     info = nm)
  }
  # and the answer columns are NA for all three, so the count is the only way
  # to tell them apart
  s <- emoji_sentiment(d, text)
  expect_identical(is.na(s$.emoji_sentiment), c(FALSE, TRUE, TRUE, TRUE))
})

test_that("emoji_faceness()'s count separates untypable from no emoji", {
  E <- asNamespace("tidyEmoji")
  A <- "\U0001F600"
  B <- "\U0001F602"
  d <- data.frame(text = c(paste("a", A, B), paste("b", A), "none"),
                  stringsAsFactors = FALSE)
  invisible(as_emoji_type(A))
  old <- E$.tidyEmoji_cache$type
  on.exit(assign("type", old, envir = E$.tidyEmoji_cache), add = TRUE)
  m <- old
  m[E$emoji_key(A)] <- NA_character_
  assign("type", m, envir = E$.tidyEmoji_cache)
  fc <- emoji_faceness(d, text)
  # 0 typed for the row whose only emoji cannot be typed, NA for the row with
  # no emoji -- the same shape .emoji_n_scored has
  expect_identical(fc$.emoji_n_typed, c(1L, 0L, NA_integer_))
  # and the share is NA in both cases: a share of no typable emoji is unknown,
  # not zero
  expect_true(is.na(fc$.emoji_faceness[2L]))
  expect_true(is.na(fc$.emoji_faceness[3L]))
})

test_that("every verb with a count column documents its two values", {
  # emoji_sentiment() states it in Details and the others point there; a page
  # that carries the column and never explains it is the gap this round found
  # rd_flat(), not rd_text(): these phrases straddle a line break in the
  # rendered Rd, and matching the wrapped form reports a gap that is not there
  for (topic in c("emoji_sentiment", "emoji_score", "emoji_emotion",
                  "emoji_risk", "emoji_incongruity")) {
    rd <- rd_flat(topic)
    expect_match(rd, "could not score|cannot score", info = topic)
    expect_match(rd, "no emoji", fixed = TRUE, info = topic)
    # the two values the count takes are both stated
    expect_match(rd, "\\b0\\b", info = topic)
    expect_match(rd, "NA", fixed = TRUE, info = topic)
  }
  fc <- rd_flat("emoji_faceness")
  expect_match(fc, "does not know", fixed = TRUE)
  expect_match(fc, "read the count before the share", fixed = TRUE)
})


test_that("rd_flat() collapses the line wrapping rd_text() preserves", {
  # The trap this helper exists for: Rd prose is wrapped, so a sentence that
  # reads as one line in the roxygen source arrives here with a newline in the
  # middle, and a fixed = TRUE match for it fails -- reporting a documentation
  # gap that does not exist. Three assertions in this file failed that way
  # before the helper was written.
  raw <- rd_text("emoji_score")
  flat <- rd_flat("emoji_score")
  expect_false(is.na(raw))
  expect_type(flat, "character")
  # flattening changes something on a real page, so this is not vacuous
  expect_true(grepl("\n", raw, fixed = TRUE))
  expect_false(grepl("\n", flat, fixed = TRUE))
  expect_false(grepl("  ", flat, fixed = TRUE))
  # and the phrase that motivated it matches only once flattened
  expect_match(flat, "the lexicon could not score", fixed = TRUE)
  # a missing topic still comes back as NA rather than erroring
  expect_true(is.na(rd_flat("no-such-topic")))
})


# Round 89: the suite hardcodes about seventy counts derived from the emoji
# package's catalogue -- 5042 rows, 3790 keys, 969 lexicon rows, 212
# undetectable spellings, 736/233, 1252, 216, 200 -- because the documentation
# quotes them and the point is to catch doc-vs-data drift. That coupling was
# nowhere written down and nothing checked it. When emoji ships a new Unicode
# version those figures all move at once, and today that would surface as
# dozens of unrelated-looking failures with no statement of the cause, plus
# four help pages silently naming a version the user does not have.

# The emoji release every documented figure in this package was derived from.
# Changing this is not enough on its own: the figures have to be re-derived.
doc_emoji_version <- function() "16.0.0"

test_that("the documented figures still match the installed emoji release", {
  have <- as.character(utils::packageVersion("emoji"))
  want <- doc_emoji_version()
  # A deliberately loud, self-explaining failure. If it is the only thing
  # failing, the catalogue moved and the figures need re-deriving; if it fails
  # alongside the count assertions, that is the same cause, not many.
  expect_identical(have, want,
    info = paste0(
      "The installed emoji package is ", have, ", but every catalogue figure ",
      "quoted in this package's documentation and pinned in these tests was ",
      "derived from ", want, ". Re-derive them (5042 catalogue rows, 3790 ",
      "distinct keys, 969 lexicon rows, 736/233 in-reference, 212 ",
      "undetectable spellings, 1252 carrying U+FE0F, 216, 200) and update ",
      "doc_emoji_version()."))
})

test_that("the help pages name the emoji release the figures came from", {
  # four pages quote the version in prose; they must agree with each other and
  # with the constant above, or a reader cannot tell which catalogue a figure
  # describes
  want <- doc_emoji_version()
  pages <- c("emoji_sentiment_lexicon", "emoji_provenance", "emoji_sanitize",
             "emoji_unicode_crosswalk")
  named <- character()
  for (p in pages) {
    rd <- rd_flat(p)
    if (is.na(rd)) next
    if (grepl(paste0("emoji} ", want), rd, fixed = TRUE) ||
        grepl(paste0("emoji ", want), rd, fixed = TRUE)) {
      named <- c(named, p)
    }
  }
  # at least one page states it, and no page states a different release
  expect_gt(length(named), 0L)
  for (p in pages) {
    rd <- rd_flat(p)
    if (is.na(rd)) next
    vers <- unique(regmatches(rd, gregexpr("[0-9]+\\.[0-9]+\\.[0-9]+", rd))[[1L]])
    stale <- setdiff(vers, c(want, "1.0.0"))
    expect_identical(stale, character(), info = p)
  }
})

test_that("the declared emoji floor is the release the figures came from", {
  # The other dependency floors are keyed to *arguments* the code calls, which
  # is why emoji is not in that table: tidyEmoji reads emoji's data, not its
  # functions. The reason it needs a floor is different and just as real --
  # every catalogue figure in the documentation describes one release, and an
  # older emoji has fewer rows, so those figures would simply be wrong. One
  # constant governs the docs, the pinned counts and this floor together.
  desc <- utils::packageDescription("tidyEmoji")
  declared <- paste(desc$Imports, desc$Suggests, sep = ", ")
  m <- regmatches(declared, regexpr("emoji \\(>= [0-9.]+\\)", declared))
  expect_identical(length(m), 1L, info = "emoji has no declared version floor")
  got <- gsub(".*>= |\\)", "", m)
  expect_identical(got, doc_emoji_version())
  # and the installed one satisfies it
  expect_true(package_version(as.character(utils::packageVersion("emoji"))) >=
                package_version(got))
})

test_that("emoji_provenance() reports the release the figures assume", {
  # the runtime counterpart: a reader who wonders which catalogue produced a
  # number has one call that answers it, and it agrees with the constant
  p <- emoji_provenance()
  expect_identical(p$emoji_pkg, as.character(utils::packageVersion("emoji")))
  expect_identical(p$emoji_pkg, doc_emoji_version())
  # and the figures the page quotes are the ones this build actually has
  E <- asNamespace("tidyEmoji")
  ref <- E$emoji_reference()
  expect_identical(p$n_emoji, nrow(ref))
  expect_identical(nrow(ref), 5042L)
  expect_identical(length(unique(ref$key)), 3790L)
})


# Round 90: a "possibly invalid URL" note is a CRAN submission item, so
# cran-comments.md explains the one this package gets. That explanation
# asserted "The site itself is up: curlGetHeaders(url, verify = FALSE)
# returns 200" -- a statement a reviewer can test, and one that had stopped
# being true: the redirect target now refuses TCP connections outright, with
# or without TLS verification. Every other URL in the package was re-checked
# over the network and returns 200. What can be checked without a network is
# that the URLs are well formed, which is the class of defect that turns a
# working link into a reported one.

test_that("every documented URL is well formed", {
  man <- rd_all()
  skip_if(length(man) == 0L, "installed help database not available")
  urls <- character()
  for (nm in names(man)) {
    m <- regmatches(man[[nm]],
                    gregexpr("\\\\(?:url|href)\\{[^}]*\\}", man[[nm]]))[[1L]]
    urls <- c(urls, sub("^\\\\(?:url|href)\\{(.*)\\}$", "\\1", m))
  }
  desc <- utils::packageDescription("tidyEmoji")
  urls <- c(urls, unlist(strsplit(paste(desc$URL, desc$BugReports), "[, ]+")))
  urls <- unique(urls[nzchar(urls)])
  expect_gt(length(urls), 4L)
  for (u in urls) {
    # no stray markdown or punctuation swept into the link -- the commonest way
    # a good URL is reported as broken
    expect_false(grepl("[`'\"<>]", u), info = u)
    expect_false(grepl("[[:space:]]", u), info = u)
    expect_false(grepl("[.,;:)]$", u), info = u)
    # https throughout: a http link is a redirect CRAN asks you to resolve
    expect_match(u, "^https://", info = u)
    # and it parses as a host plus a path
    expect_match(u, "^https://[A-Za-z0-9.-]+\\.[A-Za-z]{2,}(/|$|#)", info = u)
  }
})

test_that("cran-comments.md claims only what a reviewer can reproduce", {
  skip_on_cran()
  f <- testthat::test_path("..", "..", "cran-comments.md")
  skip_if(!file.exists(f), "cran-comments.md not available")
  txt <- paste(readLines(f, warn = FALSE), collapse = " ")
  # the stale assertion about a third-party host's availability is gone
  expect_false(grepl("The site itself is up", txt, fixed = TRUE))
  # what remains is the checkable part: the documented URL redirects, and the
  # note is about the target rather than about the package
  expect_true(grepl("302", txt, fixed = TRUE))
  expect_true(grepl("redirect target", txt, fixed = TRUE))
  expect_true(grepl("no claim about the target's current availability",
                    txt, fixed = TRUE))
})

test_that("cran-comments.md's own figures match the package", {
  # Round 91: this file is nothing but claims a reviewer can test, and two of
  # them had gone stale unnoticed -- a third-party host's availability, and
  # "two tests skip" written when the suite was much smaller. Its numbers are
  # now derived here so they cannot drift again.
  skip_on_cran()
  f <- testthat::test_path("..", "..", "cran-comments.md")
  skip_if(!file.exists(f), "cran-comments.md not available")
  txt <- paste(readLines(f, warn = FALSE), collapse = " ")

  # the skip inventory it describes: every skip CRAN sees is a skip_on_cran()
  tf <- Sys.glob(testthat::test_path("test-*.R"))
  skip_if(!length(tf), "test sources not available")
  lines <- unlist(lapply(tf, readLines, warn = FALSE))
  # Count lines that *are* the call, not occurrences of the string: the
  # literal appears in this test's own body and in prose comments, which is
  # how the first version of this assertion counted nine instead of six.
  n_soc <- sum(grepl("^\\s*skip_on_cran\\(\\)\\s*$", lines))
  expect_gt(n_soc, 0L)
  # Derive the word rather than hardcoding it here as well: adding a skipped
  # test should force cran-comments.md to be updated, which is the point of
  # this coupling, but it should not also force an edit in two places.
  words <- c("one", "two", "three", "four", "five", "six", "seven", "eight",
             "nine", "ten", "eleven", "twelve")
  expect_lte(n_soc, length(words))
  expect_true(grepl(paste(words[n_soc], "tests skip"), txt, fixed = TRUE),
              info = paste("cran-comments.md should say",
                           words[n_soc], "tests skip"))

  # the marked-UTF-8 breakdown, derived from the data it describes
  ns <- asNamespace("tidyEmoji")
  marked <- function(nm, col) {
    d <- get(nm, envir = ns)
    sum(Encoding(d[[col]]) == "UTF-8")
  }
  parts <- c(
    emoji_unicode_crosswalk = marked("emoji_unicode_crosswalk", "unicode"),
    emoji_sentiment_lexicon = marked("emoji_sentiment_lexicon", "emoji"),
    emoji_emotion_lexicon = marked("emoji_emotion_lexicon", "emoji"),
    category_unicode_crosswalk = marked("category_unicode_crosswalk",
                                        "unicodes"))
  for (nm in names(parts)) {
    expect_true(grepl(paste0("\\b", parts[[nm]], "\\b"), txt), info = nm)
  }
  expect_true(grepl(paste0("\\b", sum(parts), "\\b"), txt),
              info = "the total")
  # And the claim that no other column is marked, over the datasets the
  # package actually ships rather than a hand-written list. The first version
  # of this loop included "emoji_tweets", which is the deprecated synonym for
  # emoji_filter() -- a function, whose names() is empty, so that entry
  # iterated zero times and asserted nothing.
  ds <- utils::data(package = "tidyEmoji")$results[, "Item"]
  ds <- sub(" .*$", "", ds)
  expect_setequal(ds, c("category_unicode_crosswalk", "emoji_emotion_lexicon",
                        "emoji_sentiment_lexicon", "emoji_unicode_crosswalk"))
  checked <- 0L
  for (nm in ds) {
    d <- get(nm, envir = ns)
    # expect_s3_class() takes no info=, so name the dataset in the class check
    expect_true(inherits(d, "data.frame"), info = nm)
    for (cc in names(d)) {
      v <- d[[cc]]
      if (!is.character(v)) next
      checked <- checked + 1L
      if (cc %in% c("unicode", "emoji", "unicodes")) next
      expect_identical(sum(Encoding(v) == "UTF-8"), 0L,
                       info = paste(nm, cc))
    }
  }
  # The loop really did run, and over exactly the columns there are: 2 in
  # category_unicode_crosswalk, 3 in emoji_emotion_lexicon, 4 in
  # emoji_sentiment_lexicon, 4 in emoji_unicode_crosswalk. Pinning the count
  # rather than a floor means a new character column fires this test and has
  # to be classified as a glyph column or not.
  expect_identical(checked, 13L)
  # the version it says is published, and the licence it says DESCRIPTION has
  desc <- utils::packageDescription("tidyEmoji")
  expect_true(grepl(desc$License, txt, fixed = TRUE))
  # it must not claim the version under submission is the published one
  expect_false(grepl(paste0("published version is ", desc$Version),
                     txt, fixed = TRUE))
})


# Round 92: README.md is knitted from README.Rmd, so every `#>` line in it is
# output the package produced at some past moment. An existing test compares
# the two files' *prose*, which catches an edit to README.md that was not made
# in README.Rmd -- but not the opposite and more likely rot: prose and code
# unchanged, while the package's output moved underneath them. This release
# changed several messages and added columns, so that was worth checking. It
# had not rotted; nothing was checking.
#
# The comparison is over the `#>` lines only, not the whole file. Those come
# from knitr and are what can go stale. The surrounding prose is re-wrapped by
# pandoc, whose line breaking differs between versions, so diffing the whole
# render would fail on a different pandoc even when the README is perfectly
# current -- brittleness rather than a check.

test_that("README.md's shown output is what the package now produces", {
  skip_on_cran()
  rmd <- testthat::test_path("..", "..", "README.Rmd")
  md <- testthat::test_path("..", "..", "README.md")
  skip_if(!file.exists(rmd) || !file.exists(md), "README sources not available")
  skip_if_not_installed("rmarkdown")
  skip_if_not_installed("knitr")
  skip_if_not_installed("dplyr")
  skip_if(!rmarkdown::pandoc_available(), "pandoc not available")

  wd <- file.path(tempdir(), "tidyEmoji-readme")
  dir.create(file.path(wd, "man", "figures"), recursive = TRUE,
             showWarnings = FALSE)
  on.exit(unlink(wd, recursive = TRUE), add = TRUE)
  file.copy(rmd, file.path(wd, "README.Rmd"), overwrite = TRUE)
  logo <- testthat::test_path("..", "..", "man", "figures", "logo.png")
  if (file.exists(logo)) {
    file.copy(logo, file.path(wd, "man", "figures", "logo.png"),
              overwrite = TRUE)
  }
  ok <- tryCatch({
    rmarkdown::render(file.path(wd, "README.Rmd"),
                      output_format = "github_document",
                      output_file = "README.md", quiet = TRUE)
    TRUE
  }, error = function(e) conditionMessage(e))
  skip_if(!isTRUE(ok), paste("README could not be rendered:", ok))

  # testthat forces cli.unicode = FALSE for reproducible output, so pillar
  # decorates its tibbles in ASCII where a maintainer's render uses Unicode:
  # the header separator (\u00d7 vs x), the truncation marker (\u2026 vs ~)
  # and the "more rows" bullet (\u2139 vs i). All three depend on the option
  # rather than on the package, so normalise them. Everything that could
  # actually go stale -- row and column counts, column names, values -- is
  # compared byte for byte.
  ascii_markers <- c("\u00d7" = "x", "\u2026" = "~", "\u2139" = "i")
  out_lines <- function(f) {
    l <- readLines(f, warn = FALSE, encoding = "UTF-8")
    l <- trimws(grep("^\\s*#>", l, value = TRUE))
    for (m in names(ascii_markers)) {
      l <- gsub(m, ascii_markers[[m]], l, fixed = TRUE)
    }
    l
  }
  fresh <- out_lines(file.path(wd, "README.md"))
  shipped <- out_lines(md)
  expect_gt(length(shipped), 40L)          # the README really does show output
  expect_identical(length(fresh), length(shipped))
  expect_identical(fresh, shipped)
})


# Round 93: the suite is now large enough that its own quality needs checking,
# and the last two rounds each found a defect in a test rather than in the
# package -- a loop that iterated zero times, and a phrase match defeated by
# line wrapping. Two shapes of worthless assertion can be detected by reading
# the test sources, which ship in the tarball, so they are checked here rather
# than by hand.

test_that("no assertion in the suite compares something to itself", {
  files <- Sys.glob(testthat::test_path("*.R"))
  skip_if(!length(files), "test sources not available")
  empty_sym <- function(x) is.symbol(x) && !nzchar(as.character(x))
  offenders <- character()
  walk <- function(e, file) {
    if (is.call(e)) {
      fn <- if (is.symbol(e[[1L]])) as.character(e[[1L]]) else ""
      # expect_equal(x, x) passes whatever the package does
      if (fn %in% c("expect_equal", "expect_identical", "expect_setequal") &&
            length(e) >= 3L) {
        a <- paste(deparse(e[[2L]]), collapse = " ")
        b <- paste(deparse(e[[3L]]), collapse = " ")
        if (identical(a, b)) {
          offenders <<- c(offenders,
                          paste0(file, ": ", fn, "(", substr(a, 1, 40), ", <same>)"))
        }
      }
      # expect_true(TRUE) likewise
      if (fn == "expect_true" && length(e) >= 2L &&
            paste(deparse(e[[2L]]), collapse = " ") %in% c("TRUE", "T")) {
        offenders <<- c(offenders, paste0(file, ": expect_true(TRUE)"))
      }
    }
    if (is.call(e) || is.pairlist(e) || is.expression(e)) {
      for (i in seq_along(e)) {
        if (is.call(e) && i == 1L) next
        # inline: binding the empty symbol of x[, 1] and touching it raises
        # "argument is missing"
        if (empty_sym(e[[i]])) next
        walk(e[[i]], file)
      }
    }
  }
  for (f in files) {
    for (e in parse(f, keep.source = FALSE)) walk(e, basename(f))
  }
  expect_identical(offenders, character())
})

test_that("every test_that block contains at least one expectation", {
  # testthat warns about a test with no expectations but does not fail, and a
  # warning in a suite this size is easy to miss
  files <- Sys.glob(testthat::test_path("test-*.R"))
  skip_if(!length(files), "test sources not available")
  empty <- character()
  n_blocks <- 0L
  for (f in files) {
    for (e in parse(f, keep.source = FALSE)) {
      if (!is.call(e) || !identical(as.character(e[[1L]])[1L], "test_that")) next
      n_blocks <- n_blocks + 1L
      txt <- paste(deparse(e), collapse = "\n")
      if (!grepl("expect_", txt, fixed = TRUE) &&
            !grepl("succeed(", txt, fixed = TRUE)) {
        empty <- c(empty, paste0(basename(f), ": ",
                                 as.character(e[[2L]])[1L]))
      }
    }
  }
  expect_identical(empty, character())
  # the sweep really looked at the whole suite
  expect_gt(n_blocks, 400L)
})


# Round 94: metamorphic properties -- relations that must hold *between*
# related inputs. They catch a different class from unit tests, because they
# do not need a known answer: a verb can be wrong in a way no fixture reveals
# and still be caught by "these two corpora must agree".

test_that("corpus aggregates are additive over concatenation", {
  A <- "\U0001F600"
  B <- "\U0001F602"
  C <- "\U0001F389"
  a <- data.frame(text = c(paste("x", A, B), "none", paste("y", C)),
                  stringsAsFactors = FALSE)
  b <- data.frame(text = c(paste("z", A), paste("w", C, C)),
                  stringsAsFactors = FALSE)
  ab <- rbind(a, b)
  fa <- emoji_frequency(a, text)
  fb <- emoji_frequency(b, text)
  fab <- emoji_frequency(ab, text)
  # every glyph's count in the whole is its count in the parts
  all_g <- union(fa$emoji, fb$emoji)
  expect_setequal(fab$emoji, all_g)
  get_n <- function(f, g) {
    i <- match(g, f$emoji)
    ifelse(is.na(i), 0L, f$n[i])
  }
  expect_identical(get_n(fab, all_g), get_n(fa, all_g) + get_n(fb, all_g))
  # and the corpus counters add
  sa <- emoji_summary(a, text)
  sb <- emoji_summary(b, text)
  sab <- emoji_summary(ab, text)
  expect_identical(sab$n_total, sa$n_total + sb$n_total)
  expect_identical(sab$n_with_emoji, sa$n_with_emoji + sb$n_with_emoji)
  expect_identical(sum(emoji_version_profile(ab, text)$n_tokens),
                   sum(emoji_version_profile(a, text)$n_tokens) +
                     sum(emoji_version_profile(b, text)$n_tokens))
})

test_that("doubling the corpus doubles counts and leaves shares alone", {
  A <- "\U0001F600"
  B <- "\U0001F602"
  d <- data.frame(text = c(paste("warm", A, A), paste("cold", B),
                           paste("warm", A, B), "none"),
                  stringsAsFactors = FALSE)
  dd <- rbind(d, d)
  f1 <- emoji_frequency(d, text)
  f2 <- emoji_frequency(dd, text)
  expect_identical(f2$emoji, f1$emoji)
  expect_identical(f2$n, 2L * f1$n)
  # a share is a ratio, so it must not move
  v1 <- emoji_version_profile(d, text)
  v2 <- emoji_version_profile(dd, text)
  expect_equal(v2$share_tokens, v1$share_tokens)
  expect_equal(v2$share_types, v1$share_types)
  expect_identical(v2$n_types, v1$n_types)
  expect_identical(v2$n_tokens, 2L * v1$n_tokens)
  # pairs are counts, so they double
  p1 <- emoji_pairs(d, text)
  p2 <- emoji_pairs(dd, text)
  expect_gt(nrow(p1), 0L)
  mp <- merge(p1, p2, by = c("item1", "item2"), suffixes = c(".1", ".2"))
  expect_identical(nrow(mp), nrow(p1))
  expect_identical(mp$n.2, 2L * mp$n.1)
  # PMI is a ratio of probabilities: doubling every count cancels
  c1 <- emoji_collocations(d, text, min_n = 1L)
  c2 <- emoji_collocations(dd, text, min_n = 1L)
  mc <- merge(c1, c2, by = c("emoji", "word"), suffixes = c(".1", ".2"))
  expect_gt(nrow(mc), 0L)
  expect_identical(mc$n.2, 2L * mc$n.1)
  expect_equal(mc$pmi.2, mc$pmi.1)
})

test_that("rows without emoji do not move any emoji aggregate", {
  A <- "\U0001F600"
  C <- "\U0001F389"
  d <- data.frame(text = c(paste("x", A, C), paste("y", A), paste("z", C, C)),
                  stringsAsFactors = FALSE)
  pad <- rbind(d, data.frame(text = rep("nothing here at all", 12),
                             stringsAsFactors = FALSE))
  expect_identical(emoji_frequency(pad, text), emoji_frequency(d, text))
  expect_identical(emoji_pairs(pad, text), emoji_pairs(d, text))
  expect_identical(top_n_emojis(pad, text), top_n_emojis(d, text))
  expect_identical(emoji_version_profile(pad, text)$n_tokens,
                   emoji_version_profile(d, text)$n_tokens)
  # only the denominator the padding belongs to moves
  expect_identical(emoji_summary(pad, text)$n_with_emoji,
                   emoji_summary(d, text)$n_with_emoji)
  expect_identical(emoji_summary(pad, text)$n_total,
                   emoji_summary(d, text)$n_total + 12L)
})

test_that("a row verb's answer does not depend on the other rows", {
  # The property that separates a row verb from an aggregate. Only one row
  # verb is allowed to break it, and it is the one whose argument says so.
  A <- "\U0001F600"
  B <- "\U0001F602"
  D <- "\U0001F97A"
  d <- data.frame(
    text = c(paste("great", A, B), paste("awful", D), "no emoji",
             paste("mixed", A, D), NA_character_, ""),
    sc = c(1, -1, 0, 0.5, 0.3, -0.8),
    stringsAsFactors = FALSE)
  verbs <- list(
    emoji_sentiment = function(x) emoji_sentiment(x, text),
    emoji_score     = function(x) emoji_score(x, text),
    emoji_emotion   = function(x) emoji_emotion(x, text),
    emoji_risk      = function(x) emoji_risk(x, text),
    emoji_density   = function(x) emoji_density(x, text),
    emoji_position  = function(x) emoji_position(x, text),
    emoji_ratio     = function(x) emoji_ratio(x, text),
    emoji_type      = function(x) emoji_type(x, text),
    emoji_faceness  = function(x) emoji_faceness(x, text),
    emoji_token_cost = function(x) emoji_token_cost(x, text),
    emoji_sanitize  = function(x) emoji_sanitize(x, text, policy = "strip"),
    emoji_to_text   = function(x) emoji_to_text(x, text),
    incongruity_none = function(x) emoji_incongruity(x, text, sc,
                                                     scale = "none"))
  for (nm in names(verbs)) {
    whole <- suppressWarnings(verbs[[nm]](d))
    for (i in seq_len(nrow(d))) {
      one <- suppressWarnings(verbs[[nm]](d[i, , drop = FALSE]))
      cols <- grep("^\\.emoji", intersect(names(whole), names(one)),
                   value = TRUE)
      expect_equal(as.data.frame(whole[i, cols, drop = FALSE],
                                 row.names = NULL),
                   as.data.frame(one[1L, cols, drop = FALSE],
                                 row.names = NULL),
                   info = paste(nm, "row", i))
    }
  }
  # The documented exception: rank scaling maps each score to its percentile
  # *within the corpus*, so a row's answer must move when its neighbours do.
  # If this ever stopped differing, `scale = "rank"` would have quietly become
  # `scale = "none"`.
  rank_whole <- emoji_incongruity(d, text, sc, scale = "rank")
  differs <- FALSE
  for (i in seq_len(nrow(d))) {
    one <- emoji_incongruity(d[i, , drop = FALSE], text, sc, scale = "rank")
    if (!isTRUE(all.equal(rank_whole$.emoji_incongruity[i],
                          one$.emoji_incongruity[1L]))) {
      differs <- TRUE
    }
  }
  expect_true(differs)
})


# Round 95: the metamorphic families from the previous round, applied to the
# calendar arithmetic and to emoji_dfm(). Translation invariance is a strong
# property for a cycle: shifting every timestamp by a whole number of years
# cannot move a month cycle, nor a whole number of weeks a weekday cycle, and
# a bug in the bucketing would show up as a shift that leaks into the counts.

test_that("a whole-year shift moves the periods and nothing else", {
  A <- "\U0001F600"
  B <- "\U0001F602"
  C <- "\U0001F389"
  txt <- c(paste("a", A, B), paste("b", B), paste("c", A, C), paste("d", C),
           paste("e", A), "none")
  base <- as.Date(c("2021-01-05", "2021-01-20", "2021-02-10", "2021-03-03",
                    "2021-07-04", "2021-12-25"))
  off <- as.integer(365 * 4 + 1)          # 2021 -> 2025, same month and day
  d0 <- data.frame(text = txt, when = base, stringsAsFactors = FALSE)
  d1 <- data.frame(text = txt, when = base + off, stringsAsFactors = FALSE)
  expect_identical(format(d0$when, "%m-%d"), format(d1$when, "%m-%d"))

  # a month cycle cannot notice the year
  expect_identical(emoji_seasonality(d0, text, when, period = "month"),
                   emoji_seasonality(d1, text, when, period = "month"))
  # a trend keeps its counts and shifts its periods by one constant
  t0 <- emoji_trend(d0, text, when, by = "month")
  t1 <- emoji_trend(d1, text, when, by = "month")
  expect_identical(t1$emoji, t0$emoji)
  expect_identical(t1$n, t0$n)
  expect_equal(t1$share, t0$share)
  expect_length(unique(as.integer(t1$.period - t0$.period)), 1L)
  # turnover compares periods to each other, so its statistics are unmoved
  ms <- c("jaccard", "new", "lost", "core")
  u0 <- emoji_turnover(d0, text, when, by = "month", measure = ms)
  u1 <- emoji_turnover(d1, text, when, by = "month", measure = ms)
  expect_equal(u1$jaccard, u0$jaccard)
  expect_identical(u1$n_new, u0$n_new)
  expect_identical(u1$n_lost, u0$n_lost)
  expect_identical(u1$n_core, u0$n_core)

  # and a whole number of weeks cannot move a weekday cycle
  d7 <- data.frame(text = txt, when = base + 7L * 13L, stringsAsFactors = FALSE)
  expect_identical(emoji_seasonality(d0, text, when, period = "weekday"),
                   emoji_seasonality(d7, text, when, period = "weekday"))
})

test_that("the hour cycle follows the displayed hour, DST included", {
  A <- "\U0001F600"
  B <- "\U0001F602"
  txt <- c(paste("a", A, B), paste("b", B), paste("c", A), "none")
  # In a zone without DST, adding whole days of seconds cannot move an hour
  utc <- as.POSIXct(c("2021-03-01 03:15", "2021-03-01 09:40",
                      "2021-03-02 23:50", "2021-03-03 12:00"), tz = "UTC")
  u0 <- data.frame(text = txt, when = utc, stringsAsFactors = FALSE)
  u1 <- data.frame(text = txt, when = utc + 86400L * 5L,
                   stringsAsFactors = FALSE)
  expect_identical(emoji_seasonality(u0, text, when, period = "hour"),
                   emoji_seasonality(u1, text, when, period = "hour"))

  # Across a spring-forward boundary it must, and that is the documented
  # behaviour rather than a bug: the verb reads the timestamp's own zone, so
  # adding 86400 seconds twice is not the same as adding two calendar days.
  chi <- as.POSIXct(c("2021-03-12 03:15", "2021-03-12 09:40",
                      "2021-03-12 23:50", "2021-03-13 12:00"),
                    tz = "America/Chicago")
  skip_if(identical(format(chi, "%H"),
                    format(chi + 86400L * 2L, "%H")),
          "this build's zone data does not shift here")
  c0 <- data.frame(text = txt, when = chi, stringsAsFactors = FALSE)
  c1 <- data.frame(text = txt, when = chi + 86400L * 2L,
                   stringsAsFactors = FALSE)
  s0 <- emoji_seasonality(c0, text, when, period = "hour")
  s1 <- emoji_seasonality(c1, text, when, period = "hour")
  # the cycle moves with the displayed hours
  expect_false(identical(s0$n_emoji, s1$n_emoji))
  # the buckets are the displayed hours, in both
  for (dd in list(list(c0, s0), list(c1, s1))) {
    hrs <- as.integer(format(dd[[1L]]$when, "%H"))
    n <- lengths(tidyEmoji:::emoji_glyph_list(dd[[1L]]$text))
    want <- vapply(0:23, function(h) sum(n[hrs == h]), integer(1))
    expect_identical(dd[[2L]]$n_emoji, want)
  }
  # and nothing is created or lost by the shift
  expect_identical(sum(s0$n_emoji), sum(s1$n_emoji))
})

test_that("no time aggregate depends on the order of the rows", {
  A <- "\U0001F600"
  B <- "\U0001F602"
  C <- "\U0001F389"
  d <- data.frame(
    text = c(paste("a", A, B), paste("b", B), paste("c", A, C), paste("d", C),
             paste("e", A), "none"),
    when = as.Date(c("2021-01-05", "2021-01-20", "2021-02-10", "2021-03-03",
                     "2021-07-04", "2021-12-25")),
    stringsAsFactors = FALSE)
  set.seed(95)
  p <- d[sample(nrow(d)), , drop = FALSE]
  ms <- c("jaccard", "new", "lost", "core")
  expect_identical(emoji_trend(p, text, when, by = "month"),
                   emoji_trend(d, text, when, by = "month"))
  expect_identical(emoji_turnover(p, text, when, by = "month", measure = ms),
                   emoji_turnover(d, text, when, by = "month", measure = ms))
  expect_identical(emoji_seasonality(p, text, when, period = "month"),
                   emoji_seasonality(d, text, when, period = "month"))
  expect_identical(emoji_adoption_lag(p, text, when),
                   emoji_adoption_lag(d, text, when))
})

test_that("emoji_dfm conserves its cells under aggregation and reordering", {
  A <- "\U0001F600"
  B <- "\U0001F602"
  C <- "\U0001F389"
  d <- data.frame(
    who = c("p", "p", "q", "q", "r", "r"),
    text = c(paste("a", A, B), paste("b", B), paste("c", A, C), paste("d", C),
             paste("e", A), "none"),
    stringsAsFactors = FALSE)
  m_row <- emoji_dfm(d, text)
  m_doc <- emoji_dfm(d, text, doc_id = who)
  # aggregating rows into documents redistributes cells, never creates them
  expect_identical(sum(m_row[, -1L]), sum(m_doc[, -1L]))
  expect_setequal(names(m_row)[-1L], names(m_doc)[-1L])
  expect_identical(nrow(m_doc), length(unique(d$who)))
  # and the total is the corpus frequency total
  expect_identical(sum(m_row[, -1L]), sum(emoji_frequency(d, text)$n))

  set.seed(96)
  p <- sample(nrow(d))
  expect_identical(emoji_dfm(d[p, , drop = FALSE], text)[, -1L],
                   emoji_dfm(d, text)[p, -1L])
  # duplication leaves the first copy's rows untouched, and tf-idf with them:
  # N and df both double, so log(N/df) cancels
  d2 <- rbind(d, d)
  expect_identical(as.matrix(emoji_dfm(d2, text)[, -1L])[seq_len(nrow(d)), ],
                   as.matrix(emoji_dfm(d, text)[, -1L]))
  expect_equal(as.matrix(emoji_dfm(d2, text,
                                   weighting = "tfidf")[, -1L])[seq_len(nrow(d)), ],
               as.matrix(emoji_dfm(d, text, weighting = "tfidf")[, -1L]))
})


# Round 96: the package memoises six things for the session -- the reference
# table, its key set, the sentiment and emotion maps, the ambiguity table and
# the type map -- plus the user-writable lexicon registry. A memoised
# accessor has a failure mode nothing here covered: computing one value,
# storing another, and so answering differently the first time than
# afterwards. Six of the seven slots derive from sources that cannot change
# within a session, so they only need that check; the registry is the one a
# caller can rewrite, and it needs a coherence check too.

test_that("a cached accessor answers the same first time as later", {
  E <- asNamespace("tidyEmoji")
  cc <- E$.tidyEmoji_cache
  accessors <- list(
    reference = list(slot = "reference", f = function() E$emoji_reference()),
    sentiment = list(slot = "sentiment", f = function() E$emoji_sentiment_map()),
    ref_keys  = list(slot = "ref_keys", f = function() E$.emoji_ref_keys()),
    emotion   = list(slot = "emotion", f = function() E$emoji_emotion_map()),
    ambiguity = list(slot = "ambiguity",
                     f = function() E$emoji_ambiguity_table()),
    type      = list(slot = "type",
                     f = function() as_emoji_type("\U0001F600"))
  )
  for (nm in names(accessors)) {
    a <- accessors[[nm]]
    # clearing a derived slot is safe: it repopulates from the same immutable
    # source, so the suite is left exactly as it was found
    if (exists(a$slot, envir = cc)) {
      rm(list = a$slot, envir = cc)
    }
    first <- a$f()
    # the call populated the slot, so the memo is real rather than decorative
    expect_true(exists(a$slot, envir = cc), info = nm)
    second <- a$f()
    third <- a$f()
    expect_identical(first, second, info = nm)
    expect_identical(second, third, info = nm)
  }
})

test_that("re-registering a lexicon name replaces it, coherently", {
  A <- "\U0001F600"
  B <- "\U0001F602"
  d <- tibble::tibble(text = c(paste("a", A), paste("b", B)))
  register_emoji_lexicon("round96", data.frame(emoji = c(A, B),
                                               score = c(1, -1)))
  expect_identical(emoji_score(d, text, lexicon = "round96")$.emoji_score,
                   c(1, -1))
  # the registry is the one slot a caller can rewrite: the second table must
  # win, not be shadowed by the first
  register_emoji_lexicon("round96", data.frame(emoji = c(A, B),
                                               score = c(0.25, 0.5)))
  expect_identical(emoji_score(d, text, lexicon = "round96")$.emoji_score,
                   c(0.25, 0.5))
  lx <- emoji_lexicons()
  expect_identical(sum(lx$name == "round96"), 1L)
  expect_identical(lx$n[lx$name == "round96"], 2L)

  # and re-registering with a different glyph column still resolves, because
  # register_emoji_lexicon() stores a computed `key` column
  register_emoji_lexicon("round96", data.frame(glyph = c(A, B),
                                               score = c(9, 9)),
                         by = "glyph")
  expect_identical(emoji_score(d, text, lexicon = "round96")$.emoji_score,
                   c(9, 9))
  expect_identical(sum(emoji_lexicons()$name == "round96"), 1L)
})


# Round 97: NEWS.md's 0.4.0 section runs to 1830 lines and 194 bullets,
# because the release was audited exhaustively and both kinds of finding were
# recorded -- what changed, and what was checked and found already right. That
# is the right thing to keep, but it leaves a reader with no way in, so the
# section now opens with an orientation: the bold leads are the entries where
# something was actually wrong. That orientation states a count, which makes
# it the same kind of claim as the ones in cran-comments.md, and it goes stale
# the same way.

test_that("NEWS.md's orientation matches the section it describes", {
  f <- system.file("NEWS.md", package = "tidyEmoji")
  skip_if(!nzchar(f) || !file.exists(f), "NEWS.md not installed")
  l <- readLines(f, warn = FALSE, encoding = "UTF-8")
  v <- as.character(utils::packageVersion("tidyEmoji"))
  start <- grep(paste0("^# tidyEmoji ", v, "\\s*$"), l)
  expect_length(start, 1L)
  later <- grep("^# tidyEmoji ", l)
  stop_at <- later[later > start]
  sect <- l[start:(if (length(stop_at)) stop_at[1L] - 1L else length(l))]

  # the orientation is present and describes this section
  expect_true(any(grepl("Entries whose first sentence is", sect, fixed = TRUE)))
  # and the count it quotes is the number of bold leads there actually are
  n_bold <- sum(grepl("^\\* \\*\\*", sect))
  expect_gt(n_bold, 0L)
  words <- c("sixty-one", "sixty-two", "sixty-three", "sixty-four",
             "sixty-five", "sixty-six", "sixty-seven", "sixty-eight",
             "sixty-nine", "seventy")
  names(words) <- as.character(61:70)
  key <- as.character(n_bold)
  skip_if(!key %in% names(words),
          paste("no spelled form recorded for", n_bold, "-- update this test"))
  expect_true(any(grepl(paste("There are", words[[key]], "of them"),
                        sect, fixed = TRUE)),
              info = paste("NEWS.md should say there are", words[[key]],
                           "bold entries"))
})
