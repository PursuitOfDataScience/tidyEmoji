# Internal engine -------------------------------------------------------------
# Shared, cached helpers that power the user-facing verbs. Detection and
# extraction delegate to {emoji}, whose extractor is grapheme-aware (skin-tone
# modifiers and ZWJ sequences such as family emoji stay intact) and fast. None
# of the helpers below are exported.

.tidyEmoji_cache <- new.env(parent = emptyenv())

# One row per emoji glyph, derived from the installed emoji::emojis table.
# `shortcode` is the first GitHub-style alias (e.g. "grinning" for the glyph
# that emoji::emojis names "grinning face"). Cached for the session.
emoji_reference <- function() {
  if (is.null(.tidyEmoji_cache$reference)) {
    e <- emoji::emojis
    shortcode <- vapply(
      e$aliases,
      function(a) if (length(a)) a[[1L]] else NA_character_,
      character(1)
    )
    .tidyEmoji_cache$reference <- tibble::tibble(
      emoji     = e$emoji,
      name      = e$name,
      shortcode = shortcode,
      group     = e$group,
      subgroup  = e$subgroup,
      version   = e$version
    )
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
