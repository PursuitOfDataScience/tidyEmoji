# Internal engine -------------------------------------------------------------
# Shared, cached helpers that power the user-facing verbs. Detection is
# delegated to {emoji}'s regex, which is fast and grapheme-aware (skin-tone
# modifiers and ZWJ sequences such as family emoji stay intact), with a
# post-pass here that re-joins ZWJ sequences the upstream regex does not yet
# know about (see .emoji_merge_zwj()). Every verb goes through
# .emoji_locations() / emoji_glyph_list(), so they all agree on what an emoji
# is. None of the helpers below are exported.

.tidyEmoji_cache <- new.env(parent = emptyenv())

# One row per emoji glyph, derived from the installed emoji::emojis table.
# `shortcode` is the first GitHub-style alias (e.g. "grinning" for the glyph
# that emoji::emojis names "grinning face"). `key` is the codepoint-normalised
# join key (U+FE0F removed). Cached for the session.
emoji_reference <- function() {
  if (is.null(.tidyEmoji_cache$reference)) {
    e <- emoji::emojis
    shortcode <- vapply(
      e$aliases,
      function(a) if (length(a)) a[[1L]] else NA_character_,
      character(1)
    )
    ref <- tibble::tibble(
      emoji     = e$emoji,
      name      = e$name,
      shortcode = shortcode,
      group     = e$group,
      subgroup  = e$subgroup,
      version   = e$version
    )
    ref$key <- emoji_key(ref$emoji)
    .tidyEmoji_cache$reference <- ref
  }
  .tidyEmoji_cache$reference
}

# Codepoint key used to join emoji robustly across qualified / unqualified
# forms: the emoji variation selector U+FE0F is dropped so that, for example,
# the qualified heart (U+2764 U+FE0F) matches the lexicon's unqualified
# U+2764.
emoji_key <- function(glyphs) {
  vapply(glyphs, function(g) {
    if (is.na(g) || !nzchar(g)) return(NA_character_)
    cp <- utf8ToInt(g)
    cp <- cp[cp != 0xFE0F]
    paste(sprintf("%X", cp), collapse = " ")
  }, character(1), USE.NAMES = FALSE)
}

# Named vector mapping emoji_key() -> sentiment score, cached for the session.
emoji_sentiment_map <- function() {
  if (is.null(.tidyEmoji_cache$sentiment)) {
    lex <- emoji_sentiment_lexicon
    keys <- emoji_key(lex$emoji)
    score <- lex$sentiment_score
    names(score) <- keys
    .tidyEmoji_cache$sentiment <- score[!duplicated(keys)]
  }
  .tidyEmoji_cache$sentiment
}

# Grapheme-cluster repair ------------------------------------------------
# The upstream emoji regex only knows the ZWJ sequences that were current when
# it was built, so newer ones (face exhaling, heart on fire, people holding
# hands, the skin-toned handshakes, ...) come back as their component emoji.
# UAX #29 rule GB11 is unconditional: a zero-width joiner between two
# emoji always binds them into one grapheme cluster. So whenever two matches
# are separated by exactly one ZWJ, merge them.
.emoji_zwj <- "\u200d"

# Merge ZWJ-adjacent rows of one start/end matrix. `s` is the string the
# positions refer to.
.emoji_merge_zwj <- function(m, s) {
  n <- nrow(m)
  if (n < 2L) return(m)
  gap_start <- m[-n, "end"] + 1L
  gap_end   <- m[-1L, "start"] - 1L
  joined <- gap_end == gap_start & substring(s, gap_start, gap_end) == .emoji_zwj
  if (!any(joined)) return(m)
  grp <- cumsum(c(TRUE, !joined))
  cbind(start = as.integer(tapply(m[, "start"], grp, min)),
        end   = as.integer(tapply(m[, "end"], grp, max)))
}

# Emoji locations per element, as a list of start/end matrices (possibly
# 0-row). Positions are in characters, matching substr(). This is the single
# source of truth: emoji_glyph_list() slices the same spans, so extraction and
# location can never disagree.
.emoji_locations <- function(x) {
  x <- as.character(x)
  x[is.na(x)] <- ""
  locs <- emoji::emoji_locate_all(x)
  z <- grepl(.emoji_zwj, x, fixed = TRUE)
  if (any(z)) {
    locs[z] <- mapply(.emoji_merge_zwj, locs[z], x[z], SIMPLIFY = FALSE)
  }
  locs
}

# Slice the glyphs of one string out of its start/end matrix.
.emoji_slice <- function(m, s) {
  if (!nrow(m)) character(0) else substring(s, m[, "start"], m[, "end"])
}

# A list, one element per element of `x`, of the emoji glyphs it contains.
emoji_glyph_list <- function(x) {
  x <- as.character(x)
  x[is.na(x)] <- ""
  mapply(.emoji_slice, .emoji_locations(x), x,
         SIMPLIFY = FALSE, USE.NAMES = FALSE)
}

# Unified detection: TRUE where text contains at least one emoji.
# All verbs should use this so they agree on "what counts as having an emoji."
emoji_has <- function(x) {
  lengths(emoji_glyph_list(x)) > 0L
}

# One row per emoji occurrence, in reading order, with the character span it
# occupies. The long-form counterpart of emoji_glyph_list(): every verb that
# needs occurrence-level detail (context windows, per-glyph profiles) builds on
# this so occurrence identity is defined in exactly one place.
.emoji_occurrences <- function(v) {
  v <- as.character(v)
  v[is.na(v)] <- ""
  locs <- .emoji_locations(v)
  n <- vapply(locs, nrow, integer(1))
  if (!sum(n)) {
    return(tibble::tibble(.row_number = integer(), .position = integer(),
                          .end = integer(), .emoji = character()))
  }
  tibble::tibble(
    .row_number = rep(seq_along(v), n),
    .position = as.integer(unlist(lapply(locs, function(m) m[, "start"]),
                                  use.names = FALSE)),
    .end = as.integer(unlist(lapply(locs, function(m) m[, "end"]),
                             use.names = FALSE)),
    .emoji = as.character(unlist(
      mapply(.emoji_slice, locs, v, SIMPLIFY = FALSE, USE.NAMES = FALSE),
      use.names = FALSE
    ))
  )
}

# Split row indices into documents, in *first-appearance* order of the id.
# factor() would order the levels by sort(), which for character ids depends on
# the session's collation -- the same trap emoji_pairs()/emoji_dfm() avoid when
# ordering glyphs. Rows whose id is NA form one document.
.emoji_id_split <- function(ids) {
  lvls <- unique(ids)
  f <- factor(match(ids, lvls), levels = seq_along(lvls))
  split(seq_along(ids), f)
}

# Canonical glyph identity for the relational verbs (pairs / co-occurrence /
# n-grams / dfm): map each extracted glyph to the reference glyph that shares
# its codepoint key, so the qualified (U+2764 U+FE0F) and unqualified (U+2764)
# forms of the same emoji count as one item / node / feature. Glyphs unknown to
# the reference pass through unchanged.
emoji_canonical <- function(glyphs) {
  if (!length(glyphs)) return(character(0))
  ref <- emoji_reference()
  idx <- match(emoji_key(glyphs), ref$key)
  out <- ref$emoji[idx]
  out[is.na(idx)] <- glyphs[is.na(idx)]
  out
}

# Emotion map -------------------------------------------------------------
# Named matrix of emotion scores, rows indexed by emoji_key() so emoji carrying
# U+FE0F resolve exactly like sentiment. Cached for the session.
emoji_emotion_map <- function() {
  if (is.null(.tidyEmoji_cache$emotion)) {
    lex <- emoji_emotion_lexicon
    m <- as.matrix(lex[, c("anger", "anticipation", "disgust", "fear",
                            "joy", "sadness", "surprise", "trust")])
    rownames(m) <- lex$key
    .tidyEmoji_cache$emotion <- m
  }
  .tidyEmoji_cache$emotion
}

# Lexicon registry ------------------------------------------------------
# A tiny, documented registry so sentiment, emotion and user-supplied lexicons
# share one mechanism.
#   key -> score table is returned keyed by emoji_key() so user lexicons keyed
#   on unqualified glyphs still match qualified text.
emoji_emotion_dims <- function() {
  c("anger", "anticipation", "disgust", "fear",
    "joy", "sadness", "surprise", "trust")
}

# Build the (key -> score) record from a lexicon data frame or named score
# column, normalised through emoji_key().
.emoji_lexicon_record <- function(tbl, by = "emoji", score = NULL) {
  if (!is.data.frame(tbl)) {
    stop("`tbl` must be a data frame.", call. = FALSE)
  }
  keys <- .emoji_lexicon_keys(tbl, by)
  if (is.null(score)) {
    # heuristic: prefer 'sentiment_score', then 'score'
    score <- intersect(c("sentiment_score", "score"), names(tbl))[1L]
    if (is.na(score)) {
      stop("No score column found in `tbl`; supply `score`.",
           call. = FALSE)
    }
  }
  if (!score %in% names(tbl)) {
    stop(sprintf("Lexicon has no score column `%s`.", score), call. = FALSE)
  }
  s <- tbl[[score]]
  out <- stats::setNames(s, keys)
  out[!is.na(keys) & keys != ""]
}

# Normalised join keys for a lexicon table: prefer the glyph column `by`, and
# fall back to a pre-computed `key` column (as stored by
# register_emoji_lexicon()) so registered lexicons resolve regardless of what
# their glyph column was called.
.emoji_lexicon_keys <- function(tbl, by = "emoji") {
  if (by %in% names(tbl)) {
    emoji_key(tbl[[by]])
  } else if ("key" %in% names(tbl)) {
    as.character(tbl[["key"]])
  } else {
    stop(sprintf("Lexicon has no column `%s` to map glyphs from.", by),
         call. = FALSE)
  }
}

# Name --> tidy key index. Resolve a requested lexicon to a record or table.
# `lexicon` may be a string naming a bundled lexicon ("novak2015",
# "emotag1200"), a data frame, or a registry name registered via
# register_emoji_lexicon().
.emoji_lexicon_lookup <- function(lexicon) {
  if (is.data.frame(lexicon)) return(lexicon)
  reg <- .tidyEmoji_cache$lexicons %||% list()
  if (!is.character(lexicon)) {
    stop("`lexicon` must be a name (string), a data frame, or NULL for the default.",
         call. = FALSE)
  }
  if (lexicon %in% c("novak2015", "emoji_sentiment_lexicon", "sentiment")) {
    ans <- list(type = "sentiment")
  } else if (lexicon %in% c("emotag1200", "emoji_emotion_lexicon", "emotion")) {
    ans <- list(type = "emotion")
  } else {
    # registered lexicon?
    if (!lexicon %in% names(reg)) {
      stop(sprintf("Unknown lexicon `%s`. See emoji_lexicons() for the bundled ones.",
                   lexicon), call. = FALSE)
    }
    ans <- list(type = "custom", tbl = reg[[lexicon]])
  }
  ans
}

# Convenience for `%||%` operator without importing rlang.
`%||%` <- function(a, b) if (is.null(a)) b else a

# Validate a TRUE/FALSE argument. isTRUE() quietly treats every non-TRUE value
# as FALSE, so an unchecked flag turns a typo into a different, silently wrong
# answer instead of an error -- the same failure mode as an unvalidated `n` or
# a `wrap` template with no placeholder.
.emoji_check_flag <- function(x, arg) {
  if (!is.logical(x) || length(x) != 1L || is.na(x)) {
    stop(sprintf("`%s` must be TRUE or FALSE.", arg), call. = FALSE)
  }
  invisible(x)
}
