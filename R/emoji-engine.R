# Internal engine -------------------------------------------------------------
# Shared, cached helpers that power the user-facing verbs. Detection and
# extraction delegate to {emoji}, whose extractor is grapheme-aware (skin-tone
# modifiers and ZWJ sequences such as family emoji stay intact) and fast. None
# of the helpers below are exported.

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
# the qualified heart "❤️" matches the lexicon's unqualified "❤".
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

# A list, one element per element of `x`, of the emoji glyphs it contains.
emoji_glyph_list <- function(x) {
  x <- as.character(x)
  x[is.na(x)] <- ""
  emoji::emoji_extract_all(x)
}

# Unified detection: TRUE where text contains at least one emoji.
# All verbs should use this so they agree on "what counts as having an emoji."
emoji_has <- function(x) {
  lengths(emoji_glyph_list(x)) > 0L
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
# share one mechanism (next_release.md §6).
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
  if (!by %in% names(tbl)) {
    stop(sprintf("Lexicon has no column `%s` to map glyphs from.", by),
         call. = FALSE)
  }
  glyphs <- tbl[[by]]
  keys <- emoji_key(glyphs)
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
