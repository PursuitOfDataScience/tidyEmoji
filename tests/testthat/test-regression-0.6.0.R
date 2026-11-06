# Regression tests for 0.6.0: the catalogue moved to Unicode's emoji-test.txt,
# two detection defects were repaired at the root, and ten verbs were added.
#
# Every test here runs. Glyphs are built with intToUtf8() rather than written
# as escapes, for the reason test-invariants.R gives: a source escape is
# resolved at parse time, and in a non-UTF-8 session that warns outside any
# test.

g <- function(...) intToUtf8(c(...))
smile <- g(0x1F600)
laugh <- g(0x1F602)
tone1 <- g(0x1F3FB)
heart_bare <- g(0x2764)
heart <- g(0x2764, 0xFE0F)
us <- g(0x1F1FA, 0x1F1F8)
jp <- g(0x1F1EF, 0x1F1F5)
xx <- g(0x1F1FD, 0x1F1FD)
scotland <- g(0x1F3F4, 0xE0067, 0xE0062, 0xE0073, 0xE0063, 0xE0074, 0xE007F)
ns <- asNamespace("tidyEmoji")

# Every exported verb that reads a text column, and so takes `presentation`.
text_verbs <- function() {
  ex <- getNamespaceExports("tidyEmoji")
  ex[vapply(ex, function(f) {
    fn <- get(f, envir = ns)
    is.function(fn) && "text" %in% names(formals(fn))
  }, logical(1))]
}


# ---------------------------------------------------------------------------
# The catalogue: Unicode's emoji-test.txt, Emoji 18.0, bundled.
# ---------------------------------------------------------------------------

test_that("the catalogue is Emoji 18.0, as its file says", {
  meta <- ns$.emoji_catalogue_meta
  expect_identical(meta$emoji_version, "18.0")
  expect_identical(meta$file_date, "2026-04-30")
  expect_identical(emoji_unicode_version(), meta$emoji_version)
  cat_tbl <- emoji_properties()
  expect_identical(nrow(cat_tbl), 5244L)
  expect_identical(as.integer(table(cat_tbl$status)[c(
    "fully-qualified", "minimally-qualified", "unqualified", "component")]),
    c(3963L, 1029L, 243L, 9L))
  # the newest row is the version the header names, by number not by string
  expect_identical(max(as.numeric(cat_tbl$version)), 18)
  expect_identical(length(unique(cat_tbl$group)), 10L)
  # three subdivision flags, not the four the 0.6.0 roadmap expected
  expect_identical(sum(cat_tbl$subgroup == "subdivision-flag"), 3L)
  expect_identical(sum(cat_tbl$subgroup == "country-flag"), 259L)
})

test_that("every catalogue version has a release date (roadmap fixture 2)", {
  vers <- unique(emoji_properties()$version)
  expect_true(all(stats::na.omit(vers) %in% emoji_unicode_releases()$version))
  rel <- emoji_unicode_releases()
  expect_identical(rel$release_date[rel$version == "18.0"],
                   as.Date("2026-09-16"))
  expect_identical(rel$series[rel$version == "18.0"], "emoji")
})

test_that("the 182 emoji added in 17.0 and 18.0 are detected, in context too", {
  p <- emoji_properties()
  new <- p$emoji[p$status == "fully-qualified" &
                   as.numeric(p$version) >= 17]
  expect_identical(length(new), 182L)
  for (shape in list(function(x) x, function(x) paste0("a", x, "b"),
                     function(x) paste0(x, x), function(x) paste(x, x))) {
    gl <- ns$emoji_glyph_list(shape(new))
    expected <- lengths(gl)
    expect_true(all(expected == length(ns$emoji_glyph_list(shape(smile))[[1L]])))
    expect_true(all(vapply(seq_along(gl), function(i) {
      all(gl[[i]] == new[[i]])
    }, logical(1))))
  }
  # and named by the catalogue; {emoji} gives them no shortcode, and since
  # 0.7.0 emojibase's CLDR-style ones fill the gap
  freq <- emoji_frequency(data.frame(text = paste(new, collapse = " ")), text)
  expect_identical(nrow(freq), 182L)
  expect_false(anyNA(freq$name))
  expect_false(anyNA(freq$shortcode))
  expect_false(any(new %in% upstream()$emoji))
  # the 20 minimally-qualified 17.0 spellings too
  mq <- p$emoji[p$status == "minimally-qualified" &
                  as.numeric(p$version) >= 17]
  expect_identical(length(mq), 20L)
  expect_true(all(lengths(ns$emoji_glyph_list(mq)) == 1L))
})

# Shared by the sweep and its CRAN twin: every such spelling, or those in a sample
check_qualified_exactly_one <- function(n = NULL) {
  p <- emoji_properties()
  sel <- p$status %in% c("fully-qualified", "minimally-qualified")
  n_sel <- sum(sel)
  if (!is.null(n)) sel <- sel & seq_along(sel) %in% sweep_rows(p$emoji, n)
  gl <- ns$emoji_glyph_list(p$emoji[sel])
  exact <- vapply(seq_along(gl), function(i) {
    length(gl[[i]]) == 1L && identical(gl[[i]][[1L]], p$emoji[sel][[i]])
  }, logical(1))
  expect_true(all(exact))
  expect_identical(n_sel, 4992L)
}

test_that("every fully- and minimally-qualified spelling is exactly one emoji", {
  skip_sweep(twin = "every qualified spelling in a sample is exactly one emoji")
  check_qualified_exactly_one()
})

test_that("every qualified spelling in a sample is exactly one emoji", {
  check_qualified_exactly_one(300L)
})

# Shared by the sweep and its CRAN twin: every Emoji 16.0 spelling, or a sample
check_e16_detection_unchanged <- function(n = NULL) {
  skip_if_catalogue_moved()
  # The prefix .emoji_detect_rx() adds can only match at a code point the
  # upstream regex cannot, so on every 16.0 spelling, alone and in context,
  # the raw spans are the bundled {emoji} regex's, repaired as before.
  old <- function(x) {
    l <- upstream_locate_all(x)
    z <- grepl(g(0x200D), x, fixed = TRUE)
    l[z] <- mapply(ns$.emoji_repair_zwj, l[z], x[z], SIMPLIFY = FALSE)
    l
  }
  e16 <- upstream()$emoji
  if (!is.null(n)) e16 <- sweep_sample(e16, n)
  for (x in list(e16, paste0("a", e16, "b"), paste0(e16, e16))) {
    a <- old(x)
    b <- ns$.emoji_matches(x)
    expect_true(all(mapply(function(p, q) identical(unname(p), unname(q)),
                           a, b)))
  }
  # the prefix holds only post-16.0 code points
  rx <- ns$.emoji_detect_rx()
  expect_true(startsWith(rx, "(?:"))
  expect_true(endsWith(rx, upstream()$rx))
}

test_that("default detection of Emoji 16.0 text is what 0.5.0 found", {
  skip_sweep(twin = "default detection of a sample of Emoji 16.0 text is what 0.5.0 found")
  check_e16_detection_unchanged()
})

test_that("default detection of a sample of Emoji 16.0 text is what 0.5.0 found", {
  check_e16_detection_unchanged(250L)
})

test_that("an {emoji} that catches up empties the detection prefix", {
  ref <- ns$emoji_reference()
  # a regex that already knows every fully-qualified spelling needs no prefix
  all_fq <- ref$emoji[ref$status == "fully-qualified"]
  # longest first, or the bare base would win the alternation over its toned
  # form and the regex would not know the toned one
  all_fq <- all_fq[order(-nchar(all_fq), method = "radix")]
  rx <- paste0("(?:", paste(vapply(all_fq, function(s) {
    paste(sprintf("\\x{%X}", utf8ToInt(s)), collapse = "")
  }, character(1)), collapse = "|"), ")")
  expect_identical(ns$.emoji_build_detect_rx(ref, rx), rx)
  # and the real one needs the 16 code points newer than it
  real <- ns$.emoji_detect_rx()
  expect_false(identical(real, upstream()$rx))
})

test_that("the vocabulary columns {emoji} supplies are there, loudly", {
  # Since 0.7.0 the package reads a bundled snapshot of {emoji}'s data
  # rather than the installed package: two columns of emoji::emojis, the
  # name map and the regex. Each must be present and of its type, or the
  # vocabulary verbs would answer NA without a word
  e <- upstream()
  expect_named(e, c("version", "emoji", "aliases", "keywords", "name", "rx"))
  expect_type(e$keywords, "list")
  expect_type(e$aliases, "list")
  is_strings <- function(v) is.null(v) || is.character(v)
  expect_true(all(vapply(e$keywords, is_strings, logical(1))))
  expect_true(all(vapply(e$aliases, is_strings, logical(1))))
  expect_gt(sum(lengths(e$keywords)), 10000L)
  expect_type(e$rx, "character")
  expect_length(e$rx, 1L)
  # and a missing column fails with a message naming it, not with NA
  expect_error(ns$.emoji_vocabulary_column(smile, "no_such_column"),
               "no_such_column")
})

# Shared by the sweep and its CRAN twin: the catalogue, or a sample of it
check_keys_resolve_both <- function(n = NULL) {
  # The bug class 0.6.0 was predicted to introduce: join asymmetry between
  # the two sources. A glyph from emoji-test.txt has keywords, or an explicit
  # NA, never an empty string.
  all_g <- ns$emoji_reference()$emoji
  kw <- emoji_keywords(if (is.null(n)) all_g else sweep_sample(all_g, n))
  expect_false(any(!is.na(kw$keyword) & !nzchar(kw$keyword)))
  # Since 0.7.0 the symmetry is complete (the plan's join-symmetry test):
  # every catalogue key has a name, at least one keyword and at least one
  # shortcode, the 182 newer than {emoji} included, which had neither
  p <- emoji_properties()
  canon <- p[!duplicated(p$key) & p$status != "component", ]
  n_new <- sum(as.numeric(canon$version) >= 17)
  if (!is.null(n)) canon <- canon[sweep_rows(canon$emoji, n), , drop = FALSE]
  none <- emoji_keywords(canon$emoji)
  expect_false(anyNA(none$keyword))
  expect_setequal(unique(none$emoji), canon$emoji)
  expect_false(anyNA(as_emoji_name(canon$emoji)))
  expect_false(anyNA(as_emoji_shortcode(canon$emoji)))
  expect_identical(n_new, 182L)
  # every glyph {emoji} knows is in the catalogue, spelled the same
  expect_true(all(upstream()$emoji %in% p$emoji))
}

test_that("every catalogue key resolves in both sources, or to NA (fixture 3)", {
  skip_sweep(twin = "a sample of catalogue keys resolves in both sources, or to NA")
  check_keys_resolve_both()
})

test_that("a sample of catalogue keys resolves in both sources, or to NA", {
  check_keys_resolve_both(200L)
})

test_that("the catalogue-currency canary (roadmap fixture 1)", {
  # Run weekly by the `catalogue` job in checks.yaml, never on a push: the
  # day Unicode ships 19.0 this fails on purpose, and that is a reason to
  # rerun data-raw/crosswalks.R, not to turn every commit red.
  skip_on_cran()
  skip_if_not(identical(Sys.getenv("TIDYEMOJI_CANARY"), "true"),
              "the catalogue canary runs in the weekly checks job")
  url <- "https://www.unicode.org/Public/emoji/latest/emoji-test.txt"
  hdr <- tryCatch(readLines(url(url), n = 40L, warn = FALSE),
                  error = function(e) NULL)
  skip_if(is.null(hdr), "unicode.org is not reachable")
  upstream <- sub("^# Version: *", "",
                  grep("^# Version:", hdr, value = TRUE)[1L])
  expect_identical(emoji_unicode_version(), trimws(upstream))
})


# ---------------------------------------------------------------------------
# D1: a component standing alone is not an emoji occurrence.
# ---------------------------------------------------------------------------

test_that("an orphan skin tone is no longer counted (D1, pinned both sides)", {
  orphan <- paste0(smile, tone1)
  f <- emoji_frequency(tibble::tibble(text = orphan), text)
  # 0.5.0: two rows, one of them "light skin tone" in group "Component"
  expect_false("Component" %in% f$group)
  expect_identical(nrow(f), 1L)
  expect_identical(f$emoji, smile)
  s <- emoji_summary(tibble::tibble(text = orphan), text)
  expect_identical(s$n_with_emoji, 1L)
  expect_identical(s$n_orphan_components, 1L)
  expect_identical(s$n_invalid_flags, 0L)
  # every component, standing alone, is accounted for and not counted
  props <- emoji_properties()
  comps <- props$emoji[props$status == "component"]
  expect_identical(length(comps), 9L)
  d <- tibble::tibble(text = paste("a", comps, "b"))
  expect_identical(sum(emoji_sentiment(d, text)$.emoji_n), 0L)
  expect_identical(emoji_summary(d, text)$n_orphan_components, 9L)
  # inside a sequence a component is part of the emoji, and kept
  red_haired <- g(0x1F9D1, 0x200D, 0x1F9B0)
  toned <- g(0x1F44D, 0x1F3FD)
  for (x in c(red_haired, toned)) {
    gl <- ns$emoji_glyph_list(x)[[1L]]
    expect_identical(gl, x)
  }
})

test_that("the verbs that rewrite text treat a swatch as before", {
  orphan <- tibble::tibble(text = paste0("hi ", smile, tone1))
  strip <- emoji_sanitize(orphan, text, policy = "strip")$text
  expect_identical(strip, "hi")
  named <- emoji_to_text(orphan, text)$text
  expect_identical(named, "hi grinning facelight skin tone")
  ph <- emoji_sanitize(orphan, text, policy = "placeholder")$text
  expect_identical(ph, "hi [emoji][emoji]")
  # a swatch is not text: the row is still emoji-only, and still ends in the
  # emoji
  r <- emoji_ratio(tibble::tibble(text = paste0(smile, tone1)), text)
  expect_true(r$.emoji_only)
  expect_identical(r$.emoji_n, 1L)
  expect_equal(r$.emoji_ratio, 0.5)
  inc <- emoji_incongruity(
    tibble::tibble(text = paste0("great ", smile, tone1), sc = 0.9),
    text, sc, scale = "none", where = "final")
  expect_identical(inc$.emoji_n_scored, 1L)
  # and it is masked out of a context window rather than read as a word
  ctx <- emoji_context(tibble::tibble(text = paste0("a ", smile, tone1, " b")),
                       text)
  expect_identical(nrow(ctx), 1L)
  expect_identical(ctx$.emoji_context, "a b")
})


# ---------------------------------------------------------------------------
# D2: regional indicators that spell no flag are not an emoji.
# ---------------------------------------------------------------------------

test_that("an invalid regional-indicator pair is no longer an emoji (D2)", {
  f <- emoji_frequency(tibble::tibble(text = xx), text)
  # 0.5.0: one row, every metadata column NA
  expect_identical(nrow(f), 0L)
  lone <- g(0x1F1FA)
  expect_identical(nrow(emoji_frequency(tibble::tibble(text = lone), text)),
                   0L)
  s <- emoji_summary(tibble::tibble(text = c(xx, lone, us)), text)
  expect_identical(s$n_with_emoji, 1L)
  expect_identical(s$n_invalid_flags, 2L)
  # indicators pair from the start of a run, as UAX #29 says: XUS is XU and a
  # lone S, so it holds no flag even though "US" is inside it
  xus <- g(0x1F1FD, 0x1F1FA, 0x1F1F8)
  expect_identical(nrow(emoji_frequency(tibble::tibble(text = xus), text)),
                   0L)
  # every one of the 259 valid flags is still an emoji, in its own name
  p <- emoji_properties()
  flags <- p$emoji[p$subgroup == "country-flag"]
  ff <- emoji_frequency(tibble::tibble(text = paste(flags, collapse = " ")),
                        text)
  expect_identical(nrow(ff), 259L)
  expect_false(anyNA(ff$name))
})

test_that("an invalid pair gets no country code (moved from pending)", {
  out <- emoji_country(tibble::tibble(text = paste("a", xx, "b")), text)
  expect_identical(nrow(out), 1L)
  expect_identical(out$.emoji, xx)
  expect_true(is.na(out$.emoji_iso2))
  expect_true(is.na(out$.emoji_country_name))
})


# ---------------------------------------------------------------------------
# D3: presentation = "any".
# ---------------------------------------------------------------------------

test_that("presentation = 'any' reaches text-presentation glyphs (moved)", {
  d <- tibble::tibble(text = paste("bare", heart_bare, "heart"))
  expect_identical(emoji_summary(d, text, presentation = "emoji")$n_with_emoji,
                   0L)
  expect_identical(emoji_summary(d, text, presentation = "any")$n_with_emoji,
                   1L)
  # and the glyph is scored through the shared key
  s <- emoji_sentiment(d, text, presentation = "any")
  expect_identical(s$.emoji_n_scored, 1L)
})

test_that("'any' reads all 243 unqualified spellings except three", {
  p <- emoji_properties()
  uq <- p$emoji[p$status == "unqualified"]
  gl <- ns$emoji_glyph_list(uq, "any")
  exact <- vapply(seq_along(gl), function(i) {
    length(gl[[i]]) == 1L && identical(gl[[i]][[1L]], uq[[i]])
  }, logical(1))
  expect_identical(sum(exact), 240L)
  expect_setequal(p$key[p$status == "unqualified"][!exact],
                  c("A9", "AE", "2122"))
  # a copyright line is not emoji use
  legal <- tibble::tibble(text = paste(g(0xA9), "2026 Example Inc.",
                                       g(0xAE), g(0x2122)))
  expect_identical(emoji_summary(legal, text, presentation = "any")$n_with_emoji,
                   0L)
  # an unqualified keycap is read whole, not as its digit
  kc <- g(0x31, 0x20E3)
  expect_identical(ns$emoji_glyph_list(paste("no.", kc), "any")[[1L]], kc)
})

# Shared by the sweep and its CRAN twin: the corpus and a seventh of the catalogue, or a share of both
check_any_only_adds <- function(stride) {
  corpus <- oasst_messages$text
  p <- emoji_properties()
  mixed <- c(corpus[seq(1L, length(corpus), by = stride)],
             paste(p$emoji[seq(1, nrow(p), by = 7L * stride)], collapse = " "),
             paste0(heart_bare, smile, heart_bare, g(0x263A), tone1))
  a <- ns$.emoji_locations(mixed, "emoji")
  b <- ns$.emoji_locations(mixed, "any")
  key <- function(m) paste(m[, "start"], m[, "end"])
  expect_true(all(mapply(function(x, y) all(key(x) %in% key(y)), a, b)))
  added <- sum(vapply(b, nrow, integer(1))) - sum(vapply(a, nrow, integer(1)))
  expect_gt(added, 0L)
  # on the example corpus the difference is nine bare glyphs
  if (stride == 1L) {
    ca <- emoji_coverage(data.frame(text = corpus), text)
    expect_identical(unique(ca$n_text_presentation), 9L)
  }
}

test_that("'any' only ever adds occurrences to what 'emoji' finds", {
  skip_sweep(twin = "'any' only ever adds occurrences, on a share of the corpus")
  check_any_only_adds(1L)
})

test_that("'any' only ever adds occurrences, on a share of the corpus", {
  check_any_only_adds(6L)
})

test_that("every verb that reads text takes presentation, defaulting to emoji", {
  verbs <- text_verbs()
  # emoji_tweets() is defunct and keeps its signature; text_to_emoji() reads
  # shortcodes, not glyphs; the flag verbs read regional indicators and tag
  # sequences, which have no text-presentation form; and emoji_hidden()'s two
  # rules do not depend on what the caller counts as an emoji (0.7.0)
  exempt <- c("emoji_tweets", "text_to_emoji", "emoji_country",
              "emoji_subdivision", "emoji_hidden")
  expect_gt(length(verbs), 35L)
  # Where `presentation` stood in each verb in 0.6.0, when it was always the
  # last argument. 0.7.0 appends its new arguments after it, by rule, so no
  # positional call written for 0.6.0 changes meaning: the position may not
  # move, and anything after it must be one of the arguments 0.7.0 named.
  pos_060 <- c(
    emoji_adoption_lag = 4L, emoji_categorize = 3L, emoji_collocations = 6L,
    emoji_congruence = 8L, emoji_context = 6L, emoji_cooccurrence = 6L,
    emoji_coverage = 4L, emoji_density = 3L, emoji_dfm = 5L,
    emoji_emotion = 5L, emoji_emotion_label = 4L, emoji_extract_nest = 3L,
    emoji_extract_unnest = 3L, emoji_faceness = 3L, emoji_filter = 3L,
    emoji_flag_ambiguous = 5L, emoji_frequency = 3L, emoji_incongruity = 8L,
    emoji_incongruity_profile = 9L, emoji_ngrams = 5L, emoji_pairs = 7L,
    emoji_position = 3L, emoji_ratio = 3L, emoji_risk = 5L,
    emoji_sanitize = 6L, emoji_score = 6L, emoji_seasonality = 5L,
    emoji_sentiment = 5L, emoji_summary = 3L, emoji_to_text = 5L,
    emoji_token_cost = 4L, emoji_tokens = 3L, emoji_trend = 7L,
    emoji_turnover = 6L, emoji_type = 3L, emoji_version_profile = 3L,
    top_n_emojis = 6L)
  added_070 <- c("hidden")
  for (v in setdiff(verbs, exempt)) {
    f <- formals(get(v, envir = ns))
    expect_true("presentation" %in% names(f), info = v)
    expect_identical(f$presentation, "emoji", info = v)
    at <- match("presentation", names(f))
    if (v %in% names(pos_060)) {
      expect_identical(at, pos_060[[v]], info = v)
      expect_true(all(utils::tail(names(f), -at) %in% added_070), info = v)
    } else {
      # a verb new in 0.7.0 puts it last, as every verb did in 0.6.0
      expect_identical(utils::tail(names(f), 1L), "presentation", info = v)
    }
  }
  # the verbs that gained an argument after it are exactly the two that
  # rewrite text and now remove hidden payloads
  gained <- setdiff(verbs, exempt)[vapply(setdiff(verbs, exempt), function(v) {
    nm <- names(formals(get(v, envir = ns)))
    match("presentation", nm) < length(nm)
  }, logical(1))]
  expect_setequal(gained, c("emoji_sanitize", "emoji_to_text"))
  expect_error(emoji_summary(data.frame(text = "a"), text,
                             presentation = "emojis"),
               "`presentation`")
})


# ---------------------------------------------------------------------------
# Rates ship with their denominators.
# ---------------------------------------------------------------------------

test_that("every rate the row verbs return ships its numerator and base", {
  d <- tibble::tibble(text = c("hi there", paste("hi", smile, laugh), "",
                               NA, paste0(smile, smile)))
  den <- emoji_density(d, text)
  ok <- !is.na(den$.emoji_n_char) & den$.emoji_n_char > 0L
  expect_equal(den$.emoji_per_char[ok], den$.emoji_n[ok] / den$.emoji_n_char[ok])
  okt <- ok & den$.emoji_n_token > 0L
  expect_equal(den$.emoji_per_token[okt],
               den$.emoji_n[okt] / den$.emoji_n_token[okt])
  expect_identical(den$.emoji_n_char, c(8L, 6L, 0L, NA, 2L))
  expect_identical(den$.emoji_n_token, c(2L, 3L, 0L, NA, 1L))
  r <- emoji_ratio(d, text)
  okr <- !is.na(r$.emoji_n_char) & r$.emoji_n_char > 0L
  expect_equal(r$.emoji_ratio[okr],
               r$.emoji_codepoints[okr] / r$.emoji_n_char[okr])
  expect_identical(r$.emoji_n, c(0L, 2L, 0L, 0L, 2L))
  # .emoji_codepoints means what it means in emoji_token_cost()
  expect_identical(r$.emoji_codepoints,
                   emoji_token_cost(d, text)$.emoji_codepoints)
  # the new count columns come before the rates they explain
  expect_identical(utils::tail(names(den), 5L),
                   c(".emoji_n", ".emoji_n_char", ".emoji_n_token",
                     ".emoji_per_char", ".emoji_per_token"))
  expect_identical(utils::tail(names(r), 5L),
                   c(".emoji_n", ".emoji_codepoints", ".emoji_n_char",
                     ".emoji_ratio", ".emoji_only"))
})

test_that("emoji_trend()'s share has its base even when top_n hides it", {
  d <- tibble::tibble(
    when = as.Date(c("2024-01-05", "2024-01-20", "2024-02-03")),
    text = c(paste(smile, smile, laugh), paste(heart, smile), laugh))
  all_n <- emoji_trend(d, text, when, top_n = NULL)
  one <- emoji_trend(d, text, when, top_n = 1)
  # the period total is every emoji in the period, not the kept ones
  jan <- one[one$.period == as.Date("2024-01-01"), ]
  expect_identical(jan$n_period, 5L)
  expect_equal(one$share, one$n / one$n_period)
  # and it agrees with the untruncated table's own totals
  tot <- tapply(all_n$n, as.character(all_n$.period), sum)
  expect_identical(as.integer(tot[as.character(one$.period)]), one$n_period)
})

test_that("?tidyEmoji states the rate contract", {
  rd <- rd_flat("tidyEmoji-package")
  expect_match(rd, "Every rate tidyEmoji returns ships with the numerator",
               fixed = TRUE)
  expect_match(rd, "count model", fixed = TRUE)
})


# ---------------------------------------------------------------------------
# The catalogue surface.
# ---------------------------------------------------------------------------

test_that("emoji_properties() says what the catalogue knows", {
  p <- emoji_properties(c(heart_bare, heart, g(0x1F44D, 0x1F3FD), tone1,
                          "abc", NA, g(0x1FAEA)))
  expect_named(p, c("emoji", "codepoints", "n_codepoints", "key", "name",
                    "status", "group", "subgroup", "version", "modifiable",
                    "has_fe0f"))
  expect_identical(p$status, c("unqualified", "fully-qualified",
                               "fully-qualified", "component", NA, NA,
                               "fully-qualified"))
  expect_identical(p$codepoints[1:2], c("U+2764", "U+2764 U+FE0F"))
  expect_identical(p$n_codepoints, c(1L, 2L, 2L, 1L, 3L, NA, 1L))
  # the emoji's fields resolve through the key, the spelling's status not
  expect_identical(p$name[1L], p$name[2L])
  expect_identical(p$version[7L], "17.0")
  expect_identical(p$modifiable, c(FALSE, FALSE, TRUE, FALSE, NA, NA, FALSE))
  expect_identical(p$has_fe0f, c(FALSE, TRUE, FALSE, FALSE, FALSE, NA, FALSE))
  # an 18.0 thumb takes a tone, which {emoji}'s own table cannot know
  expect_true(emoji_properties(g(0x1FAF9))$modifiable)
  # one row per element, in order, including repeats
  expect_identical(emoji_properties(c(smile, smile))$emoji, c(smile, smile))
  expect_identical(nrow(emoji_properties(character(0))), 0L)
  expect_error(emoji_properties(1:3), "`x`")
})

test_that("as_emoji_canonical() resolves both spellings to one (moved)", {
  expect_identical(as_emoji_canonical(heart_bare), as_emoji_canonical(heart))
  expect_identical(as_emoji_canonical(heart_bare), heart)
  expect_identical(as_emoji_canonical(c("abc", NA, smile)),
                   c("abc", NA, smile))
  # it is the normalisation the verbs use internally
  p <- emoji_properties()
  expect_identical(as_emoji_canonical(p$emoji), ns$emoji_canonical(p$emoji))
  # and every canonical spelling is the catalogue's fully-qualified one
  canon <- unique(as_emoji_canonical(p$emoji))
  expect_true(all(p$status[match(canon, p$emoji)] %in%
                    c("fully-qualified", "component")))
})

test_that("emoji_identical() compares by code points (moved)", {
  expect_true(emoji_identical(heart_bare, heart))
  expect_false(emoji_identical(smile, laugh))
  expect_identical(emoji_identical(c(smile, NA), smile), c(TRUE, NA))
  det <- emoji_identical(c(heart_bare, g(0x1F44D), smile, smile),
                         c(heart, g(0x1F44D, 0x1F3FD), laugh, smile),
                         details = TRUE)
  expect_identical(det$difference,
                   c("variation selector", "skin tone", "different", "none"))
  expect_identical(det$identical, c(TRUE, FALSE, FALSE, TRUE))
  expect_identical(det$exact, c(FALSE, FALSE, FALSE, TRUE))
  expect_identical(det$y_codepoints[1L], "U+2764 U+FE0F")
  expect_error(emoji_identical(c(smile, laugh, smile), c(smile, laugh)),
               "same length")
  # the help page owns the rendering limit
  rd <- rd_flat("emoji_identical")
  expect_match(rd, "cannot say what the sender or the recipient saw",
               fixed = TRUE)
})

test_that("emoji_keywords() and emoji_find() search the keywords (moved)", {
  kw <- emoji_keywords(smile)
  expect_s3_class(kw, "tbl_df")
  expect_gt(nrow(kw), 0L)
  expect_named(kw, c("emoji", "name", "keyword", "source"))
  # the bare and the qualified heart carry one set
  expect_identical(emoji_keywords(heart_bare)$keyword,
                   emoji_keywords(heart)$keyword)
  # a string with no vocabulary is one NA row, never ""; since 0.7.0 the
  # newest emoji have CLDR's keywords, so only the non-emoji is NA
  none <- emoji_keywords(c(g(0x1FAEA), "abc"))
  expect_identical(nrow(none), 7L)
  expect_identical(sum(is.na(none$keyword)), 1L)
  expect_identical(none$source[none$emoji == g(0x1FAEA)], rep("cldr", 6L))
  party <- g(0x1F389)
  expect_true(party %in% emoji_find("celebration")$emoji)
  expect_true(party %in% emoji_find("CELEBRATION")$emoji)
  both <- emoji_find(c("cat", "face"), match = "all")
  expect_true(all(both$n_matched == 2L))
  anyof <- emoji_find(c("cat", "face"))
  expect_gt(nrow(anyof), nrow(both))
  expect_false(is.unsorted(-anyof$n_matched))
  expect_identical(nrow(emoji_find("zzzz-no-such-keyword")), 0L)
  # an empty term list finds nothing since 0.7.0 (N5); NA is still an error
  expect_identical(nrow(emoji_find(character(0))), 0L)
  expect_error(emoji_find(c("cat", NA)), "`terms`")
  # every emoji emoji_find() returns does carry the keyword
  found <- emoji_find("pizza")
  expect_true(all(vapply(found$emoji, function(e) {
    "pizza" %in% emoji_keywords(e)$keyword
  }, logical(1))))
})


# ---------------------------------------------------------------------------
# Flags.
# ---------------------------------------------------------------------------

test_that("emoji_country() maps pairs to codes, and keeps stray pairs", {
  d <- tibble::tibble(id = 1:3,
                      text = c(paste("go", us, "and", jp), "none",
                               paste("stray", xx)))
  out <- emoji_country(d, text)
  expect_identical(out$id, c(1L, 1L, 3L))
  expect_identical(out$.emoji, c(us, jp, xx))
  expect_identical(out$.emoji_iso2, c("US", "JP", NA))
  expect_identical(out$.emoji_country_name, c("United States", "Japan", NA))
  # the arithmetic and the catalogue agree on all 259
  p <- emoji_properties()
  flags <- p$emoji[p$subgroup == "country-flag"]
  codes <- emoji_flag(flags)
  expect_false(anyNA(codes))
  expect_true(all(grepl("^[A-Z]{2}$", codes)))
  expect_identical(emoji_flag(codes), flags)
  expect_true(all(c("EU", "UN") %in% codes))
  expect_identical(nrow(emoji_country(tibble::tibble(text = "plain"), text)),
                   0L)
})

test_that("emoji_flag() converts both ways, case-insensitively, and refuses", {
  expect_identical(emoji_flag(c("JP", "jp", " us ")), c(jp, jp, us))
  expect_identical(emoji_flag(c(jp, us)), c("JP", "US"))
  expect_identical(emoji_flag(c("XX", "UK", xx, "", NA)),
                   rep(NA_character_, 5L))
  expect_identical(emoji_flag("GB-SCT"), scotland)
  expect_identical(emoji_flag(scotland), "GB-SCT")
})

test_that("emoji_subdivision() reads tag sequences, RGI or not", {
  texas <- g(0x1F3F4, 0xE0075, 0xE0073, 0xE0074, 0xE0078, 0xE007F)
  d <- tibble::tibble(text = c(paste("go", scotland), paste("tx", texas),
                               "none"))
  out <- emoji_subdivision(d, text)
  expect_identical(out$.emoji_subdivision, c("GB-SCT", "US-TX"))
  expect_identical(out$.emoji_subdivision_name, c("Scotland", NA))
  # the three in the catalogue are emoji; a non-RGI one is a black flag to
  # every other verb, which the help page says
  expect_identical(nrow(emoji_frequency(d[1L, ], text)), 1L)
  black <- emoji_frequency(d[2L, ], text)
  expect_identical(black$emoji, g(0x1F3F4))
  p <- emoji_properties()
  subs <- p$emoji[p$subgroup == "subdivision-flag"]
  expect_setequal(emoji_flag(subs), c("GB-ENG", "GB-SCT", "GB-WLS"))
})


# ---------------------------------------------------------------------------
# Tallies: emoji_from_counts() (roadmap fixture 4).
# ---------------------------------------------------------------------------

test_that("a tally and its expanded text score identically", {
  tally <- tibble::tibble(id = 1L, emoji = smile, n = 3L)
  txt <- tibble::tibble(id = 1L, text = strrep(smile, 3L))
  expect_equal(
    emoji_sentiment(emoji_from_counts(tally, emoji, n, id = id),
                    text)$.emoji_sentiment,
    emoji_sentiment(txt, text)$.emoji_sentiment
  )
})

test_that("tally output is the expanded text to every counting verb", {
  tally <- tibble::tibble(
    doc = c("a", "a", "b", "c", "c"),
    emoji = c(smile, laugh, heart, us, tone1),
    n = c(2, 1, 4, 1, 0))
  out <- emoji_from_counts(tally, emoji, n, id = doc)
  expect_identical(out$doc, c("a", "b", "c"))
  hand <- tibble::tibble(doc = c("a", "b", "c"),
                         text = c(paste(smile, smile, laugh),
                                  paste(rep(heart, 4L), collapse = " "),
                                  us))
  expect_identical(out$text, hand$text)
  expect_identical(emoji_frequency(out, text), emoji_frequency(hand, text))
  expect_identical(emoji_dfm(out, text, doc_id = doc),
                   emoji_dfm(hand, text, doc_id = doc))
  expect_identical(emoji_emotion(out, text)$.emoji_joy,
                   emoji_emotion(hand, text)$.emoji_joy)
  # glyphs are separated, so a tone tallied apart does not fuse with a hand
  sep <- emoji_from_counts(
    tibble::tibble(emoji = c(g(0x1F44D), tone1), n = c(1, 1)), emoji, n)
  expect_identical(nrow(emoji_frequency(sep, text)), 1L)
})

test_that("emoji_from_counts() reads reaction names and refuses bad counts", {
  gh <- tibble::tibble(pr = c(1, 1, 2), r = c("+1", "rocket", ":tada:"),
                       n = c(3, 1, 2))
  out <- emoji_from_counts(gh, r, n, id = pr)
  thumbs <- paste(rep(g(0x1F44D), 3L), collapse = " ")
  expect_identical(out$text, c(paste(thumbs, g(0x1F680)),
                               paste(g(0x1F389), g(0x1F389))))
  # GitHub's eight, as its API names them
  eight <- c("+1", "-1", "laugh", "hooray", "confused", "heart", "rocket",
             "eyes")
  res <- emoji_from_counts(tibble::tibble(r = eight, n = 1), r, n)
  expect_identical(length(ns$emoji_glyph_list(res$text)[[1L]]), 8L)
  # a bare text-presentation glyph is written canonically, so the default
  # presentation reads it
  bare <- emoji_from_counts(tibble::tibble(r = heart_bare, n = 2), r, n)
  expect_identical(emoji_summary(bare, text)$n_with_emoji, 1L)
  # an item with no reactions keeps its row
  z <- emoji_from_counts(tibble::tibble(i = 1:2, r = c("eyes", "eyes"),
                                        n = c(0, 1)), r, n, id = i)
  expect_identical(z$text, c("", g(0x1F440)))
  bad <- tibble::tibble(r = smile, n = 2.5)
  expect_error(emoji_from_counts(bad, r, n), "fraction")
  expect_error(emoji_from_counts(tibble::tibble(r = smile, n = -1), r, n),
               "whole numbers of at least 0")
  expect_error(emoji_from_counts(tibble::tibble(r = smile, n = NA_real_),
                                 r, n),
               "whole numbers")
  expect_error(emoji_from_counts(tibble::tibble(r = "notanemoji", n = 1),
                                 r, n),
               "notanemoji")
  expect_error(emoji_from_counts(tibble::tibble(r = paste0(smile, smile),
                                                n = 1), r, n),
               "not one emoji")
  expect_error(emoji_from_counts(tibble::tibble(r = smile, n = "3"), r, n),
               "numeric")
})


# ---------------------------------------------------------------------------
# Coverage.
# ---------------------------------------------------------------------------

test_that("emoji_coverage() reports what a lexicon could not score (moved)", {
  d <- tibble::tibble(text = c(paste("hi", smile),
                               paste("new", g(0x1F97A)),
                               "none"))
  out <- emoji_coverage(d, text, lexicon = "sentiment")
  expect_identical(out$n_occurrences, 2L)
  expect_identical(out$n_scorable, 1L)
  expect_identical(out$occurrence_coverage, 0.5)
  expect_identical(out$n_rows_unscored, 1L)
})

test_that("emoji_coverage() gives the example corpus's figures", {
  # 0.6.0 pinned these on the retired tweet corpus (900 occurrences, 62.8%
  # and 50.8% for the sentiment lexicon); 0.7.0 on the OASST2 sample, after
  # D7 split its three unrecommended ZWJ sequences into their parts (1,450
  # occurrences of 401 types before, 1,454 of 398 after)
  corpus <- oasst_messages
  cv <- emoji_coverage(corpus, text)
  expect_identical(cv$lexicon, c("novak2015", "emotag1200"))
  s <- cv[cv$lexicon == "novak2015", ]
  expect_identical(c(s$n_occurrences, s$n_scorable, s$n_types,
                     s$n_types_scorable, s$n_rows_with_emoji,
                     s$n_rows_unscored, s$lexicon_size),
                   c(1454L, 1091L, 398L, 244L, 750L, 135L, 969L))
  expect_equal(round(100 * s$occurrence_coverage, 1), 75.0)
  expect_equal(round(100 * s$type_coverage, 1), 61.3)
  e <- cv[cv$lexicon == "emotag1200", ]
  expect_equal(round(100 * e$occurrence_coverage, 1), 52.9)
  expect_identical(e$n_types_scorable, 106L)
  # the per-row figure it summarises: rows with emoji and no score
  sent <- emoji_sentiment(corpus, text)
  expect_identical(sum(sent$.emoji_n > 0L & is.na(sent$.emoji_sentiment)),
                   s$n_rows_unscored)
  # catalogue_share: lexicon emoji over the catalogue's 3963 emoji
  expect_equal(s$catalogue_share, 736 / 3963)
  # 'any' moves the text-presentation glyphs inside the counts, and the two
  # columns that describe them do not move
  ca <- emoji_coverage(corpus, text, presentation = "any")
  expect_identical(ca$n_occurrences - cv$n_occurrences,
                   cv$n_text_presentation)
  expect_identical(ca$n_text_presentation, cv$n_text_presentation)
  expect_identical(ca$n_text_presentation_scorable,
                   cv$n_text_presentation_scorable)
})

test_that("emoji_coverage() reports registered lexicons and refuses junk", {
  local_clean_registry()
  register_emoji_lexicon("mine", data.frame(emoji = c(smile, laugh),
                                            score = c(1, NA)))
  d <- tibble::tibble(text = c(smile, laugh, "none"))
  cv <- emoji_coverage(d, text)
  expect_true("mine" %in% cv$lexicon)
  m <- cv[cv$lexicon == "mine", ]
  # an NA score is no score
  expect_identical(m$n_scorable, 1L)
  expect_identical(m$lexicon_size, 1L)
  expect_error(emoji_coverage(d, text, lexicon = 1), "`lexicon`")
  expect_error(emoji_coverage(d, text, lexicon = "nope"), "Unknown lexicon")
  empty <- emoji_coverage(tibble::tibble(text = "plain"), text)
  expect_true(all(is.na(empty$occurrence_coverage)))
  expect_true(all(empty$n_occurrences == 0L))
})


# ---------------------------------------------------------------------------
# D5: the ambiguity measures, and polarisation (roadmap fixture 5).
# ---------------------------------------------------------------------------

test_that("entropy and gini are blind to ordering; polarisation is not", {
  ent <- function(q) -sum(ifelse(q <= 0, 0, q * log(q)))
  gini <- function(q) 1 - sum(q^2)
  polar <- function(q) {
    x <- c(-1, 0, 1)
    sum(outer(q, q) * abs(outer(x, x, "-")))
  }
  polarised <- c(0.5, 0.0, 0.5)
  mild <- c(0.5, 0.5, 0.0)
  expect_equal(ent(polarised), ent(mild))
  expect_equal(gini(polarised), gini(mild))
  expect_gt(polar(polarised), polar(mild))
  expect_equal(c(polar(polarised), polar(mild)), c(1, 0.5))
  # the package's closed form is that expectation, over the whole lexicon
  tbl <- ns$emoji_ambiguity_table()
  brute <- vapply(seq_len(nrow(tbl)), function(i) {
    polar(c(tbl$p_neg[i], tbl$p_neu[i], tbl$p_pos[i]))
  }, numeric(1))
  expect_equal(tbl$polarisation, brute)
  # and it is Berry and Mielke's IOV, 1 - l^2 in Blair and Lacy's terms
  iov <- with(tbl, 2 * (p_neg * (1 - p_neg) + (p_neg + p_neu) * p_pos))
  expect_equal(tbl$polarisation, iov)
})

test_that("polarisation finds the polarised glyph entropy ranks 156th", {
  e <- emoji_ambiguity(measure = "entropy")
  p <- emoji_ambiguity(measure = "polarisation")
  sweat <- g(0x1F630)
  expect_identical(e$rank[e$emoji == sweat], 156L)
  expect_identical(p$rank[p$emoji == sweat], 6L)
  expect_identical(e$n_annotations[e$emoji == sweat], 302L)
  expect_equal(round(stats::cor(e$ambiguity[order(e$emoji)],
                                p$ambiguity[order(p$emoji)],
                                method = "spearman"), 2), 0.96)
  # the default is unchanged, and the other two verbs take the measure
  expect_identical(formals(emoji_ambiguity)$measure, "entropy")
  d <- tibble::tibble(text = paste("hm", sweat))
  expect_equal(emoji_risk(d, text, measure = "polarisation")$
                 .emoji_ambiguity_mean, p$ambiguity[p$emoji == sweat])
  expect_identical(emoji_flag_ambiguous(d, text, measure = "polarisation")$
                     rank, 6L)
  rd <- rd_flat("emoji_ambiguity")
  expect_match(rd, "Polarised or merely uncertain?", fixed = TRUE)
  expect_match(rd, "2,482", fixed = TRUE)
})


# ---------------------------------------------------------------------------
# Association measures (roadmap fixture 7).
# ---------------------------------------------------------------------------

test_that("collocation measures agree on n and differ on ranking", {
  cry <- g(0x1F622)
  blush <- g(0x1F60A)
  d <- tibble::tibble(text = c(paste("cold coffee", cry),
                               paste("coffee again", cry),
                               paste("warm tea", blush)))
  a <- emoji_collocations(d, text, min_n = 1, measure = "pmi")
  b <- emoji_collocations(d, text, min_n = 1, measure = "logdice")
  expect_setequal(paste(a$emoji, a$word), paste(b$emoji, b$word))
  expect_equal(sum(a$n), sum(b$n))
  expect_false(identical(a$word, b$word))
  # the default output is 0.5.0's, column for column
  expect_named(a, c("emoji", "word", "n", "pmi"))
  expect_named(b, c("emoji", "word", "n", "pmi", "logdice"))
})

# Shared by the sweep and its CRAN twin: the whole corpus, or its first rows
check_association_formulas <- function(n = NULL) {
  corpus <- oasst_messages
  if (!is.null(n)) corpus <- corpus[seq_len(n), , drop = FALSE]
  base <- emoji_collocations(corpus, text, min_n = 1)
  ctx <- emoji_context(corpus, text)
  words <- lapply(ctx$.emoji_context, function(s) {
    unique(ns$.emoji_trim_words(ns$.emoji_words(ns$.emoji_fold(s))))
  })
  pairs <- data.frame(e = rep(ns$emoji_canonical(ctx$.emoji), lengths(words)),
                      w = unlist(words), stringsAsFactors = FALSE)
  N <- nrow(pairs)
  r <- table(pairs$e)[base$emoji]
  cc <- table(pairs$w)[base$word]
  o <- base$n
  e <- as.numeric(r) * as.numeric(cc) / N
  ref <- list(
    ppmi = pmax(0, log(o / e)),
    dice = 2 * o / (as.numeric(r) + as.numeric(cc)),
    logdice = 14 + log2(2 * o / (as.numeric(r) + as.numeric(cc))),
    tscore = (o - e) / sqrt(o)
  )
  for (m in names(ref)) {
    got <- emoji_collocations(corpus, text, min_n = 1, measure = m)
    idx <- match(paste(base$emoji, base$word), paste(got$emoji, got$word))
    expect_equal(got[[m]][idx], ref[[m]], info = m)
    expect_identical(got$n[idx], base$n, info = m)
    expect_false(is.unsorted(-got[[m]]), info = m)
  }
  # log-likelihood, cell by cell, against a direct two-by-two computation
  llr <- emoji_collocations(corpus, text, min_n = 1, measure = "llr")
  i <- match(paste(base$emoji, base$word), paste(llr$emoji, llr$word))[seq_len(min(25L, nrow(base)))]
  for (k in seq_along(i)) {
    j <- i[[k]]
    O <- matrix(c(llr$n[j], r[[llr$emoji[j]]] - llr$n[j],
                  cc[[llr$word[j]]] - llr$n[j], 0), 2)
    O[2, 2] <- N - sum(O)
    E <- outer(rowSums(O), colSums(O)) / N
    g2 <- 2 * sum(ifelse(O > 0, O * log(O / E), 0))
    expect_equal(abs(llr$llr[j]), g2)
    expect_identical(sign(llr$llr[j]), sign(O[1, 1] - E[1, 1]))
  }
}

test_that("each association measure is the textbook formula", {
  skip_sweep(twin = "each association measure is the textbook formula, on part of the corpus")
  check_association_formulas()
})

test_that("each association measure is the textbook formula, on part of the corpus", {
  check_association_formulas(120L)
})

test_that("emoji_pairs() measures score against document frequencies", {
  d <- tibble::tibble(text = c(paste(smile, laugh), paste(smile, laugh),
                               paste(smile, heart), laugh, "plain",
                               "plain too"))
  cnt <- emoji_pairs(d, text)
  for (m in c("ppmi", "log_odds", "dice")) {
    out <- emoji_pairs(d, text, measure = m)
    expect_setequal(paste(out$item1, out$item2), paste(cnt$item1, cnt$item2))
    expect_named(out, c("item1", "item2", "n", m))
    # emoji-free rows change nothing
    more <- emoji_pairs(rbind(d, tibble::tibble(text = rep("x", 50))), text,
                        measure = m)
    expect_identical(out, more, info = m)
  }
  sl <- emoji_pairs(d, text, measure = "dice")
  # smile is in 3 documents, laugh in 3, both in 2: dice = 4 / 6
  row <- sl[sl$item1 == min(smile, laugh) & sl$item2 == max(smile, laugh), ]
  expect_equal(row$dice, 2 * 2 / (3 + 3))
  pp <- emoji_pairs(d, text, measure = "ppmi")
  row <- pp[paste(pp$item1, pp$item2) == paste(row$item1, row$item2), ]
  # N = 4 documents hold an emoji
  expect_equal(row$ppmi, max(0, log(2 * 4 / (3 * 3))))
  # zero-row input stays typed, measure column included
  z <- emoji_pairs(tibble::tibble(text = "plain"), text, measure = "dice")
  expect_named(z, c("item1", "item2", "n", "dice"))
  expect_type(z$dice, "double")
})


# ---------------------------------------------------------------------------
# Lifecycle and documentation.
# ---------------------------------------------------------------------------


test_that("every help page carries a research-question concept tag", {
  db <- rd_db()
  exported <- getNamespaceExports("tidyEmoji")
  pages <- names(db)
  tagged <- vapply(db, function(rd) {
    any(vapply(rd, function(x) identical(attr(x, "Rd_tag"), "\\concept"),
               logical(1)))
  }, logical(1))
  # every page documenting an exported function, bar the package page
  fun_pages <- pages[vapply(db, function(rd) {
    al <- unlist(lapply(rd[vapply(rd, function(x) {
      identical(attr(x, "Rd_tag"), "\\alias")
    }, logical(1))], as.character))
    any(al %in% exported)
  }, logical(1))]
  expect_gt(length(fun_pages), 40L)
  expect_identical(names(tagged)[!tagged & names(tagged) %in% fun_pages],
                   character(0))
})


# ---------------------------------------------------------------------------
# The guards on the new verbs, which a coverage read found untested.
# ---------------------------------------------------------------------------

test_that("emoji_keywords() with no argument covers the whole catalogue", {
  kw <- emoji_keywords()
  p <- emoji_properties()
  expect_identical(length(unique(kw$emoji)), length(unique(p$key)))
  expect_false(any(!is.na(kw$keyword) & !nzchar(kw$keyword)))
  # every emoji has keywords since 0.7.0, the ones newer than {emoji} among
  # them, which until then had none
  expect_false(anyNA(kw$keyword))
  newer <- unique(as_emoji_canonical(p$emoji[as.numeric(p$version) >= 17]))
  expect_true(all(newer %in% kw$emoji[kw$source == "cldr"]))
})

test_that("the new verbs refuse unreadable input by name", {
  # ASCII is never marked, so the bytes have to include a non-ASCII one
  raw <- paste0("x", g(0x1F600))
  Encoding(raw) <- "bytes"
  expect_identical(Encoding(raw), "bytes")
  expect_error(emoji_properties(raw), "`x`.*bytes")
  expect_error(emoji_identical(raw, "a"), "`x`.*bytes")
  expect_error(emoji_find(raw), "`terms`.*bytes")
  expect_error(emoji_from_counts(data.frame(r = raw, n = 1), r, n),
               "`emoji`.*bytes")
  # a factor is read as the strings it holds
  expect_identical(emoji_properties(factor(g(0x1F600)))$name, "grinning face")
})

test_that("emoji_from_counts() refuses what it cannot write out", {
  expect_error(emoji_from_counts(data.frame(r = c(g(0x1F600), NA), n = 1),
                                 r, n),
               "1 missing value; a count needs an emoji")
  expect_error(emoji_from_counts(data.frame(r = g(0x1F600), n = 3e9), r, n),
               "past integer range")
  expect_error(emoji_from_counts(data.frame(text = 1, r = g(0x1F600), n = 1),
                                 r, n, id = text),
               "cannot be a column called `text`")
  # a tally with no rows is one empty document, not an error
  empty <- emoji_from_counts(data.frame(r = character(), n = numeric()), r, n)
  expect_identical(empty$text, "")
})

test_that("emoji_flag() answers NA for anything that is not one flag", {
  expect_identical(emoji_flag(c(g(0x1F1FA), g(0x1F600), g(0x1F1FA, 0x1F1F8,
                                                          0x1F1EF))),
                   rep(NA_character_, 3L))
  # a registered lexicon with no numeric column scores nothing
  local_clean_registry()
  # register_emoji_lexicon() refuses a table with no score column, so put one
  # in the registry directly to reach the guard behind it
  cache <- ns$.tidyEmoji_cache
  cache$lexicons <- c(cache$lexicons,
                      list(words = tibble::tibble(
                        emoji = g(0x1F600), key = ns$emoji_key(g(0x1F600)),
                        note = "a note")))
  expect_identical(ns$.emoji_lexicon_scorable_keys("words"), character(0))
})
