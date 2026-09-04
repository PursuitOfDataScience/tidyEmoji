#' Categorise each row by the emoji categories it contains
#'
#' `emoji_categorize()` keeps the rows of `data` that contain emoji and adds a
#' `.emoji_category` column listing the distinct Unicode categories present in
#' that row (for example "Smileys & Emotion"), separated by `|` when a row spans
#' more than one category.
#'
#' @details
#' A row is kept because it contains an emoji, not because that emoji could be
#' categorised. If none of a row's emoji is in the reference table -- which
#' happens for a zero-width-joiner sequence newer than your installed
#' \pkg{emoji} package, since detection is grapheme-aware and does not require
#' the sequence to be catalogued -- the row is kept with `.emoji_category` set
#' to `NA`. Dropping it would silently shrink the corpus, and by exactly the
#' rows a user whose Unicode coverage is behind most needs to see. Use
#' [emoji_provenance()] to check which catalogue you are matching against.
#'
#' @inheritParams emoji_summary
#' @return `data`, as a tibble, filtered to the rows containing at least one
#'   emoji, with an added `.emoji_category` column. That column is `NA` for a
#'   row whose emoji are all absent from the reference table.
#' @examples
#' df <- data.frame(text = c("smile \U0001f600",
#'                           "flag \U0001f3c1\U0001f600",
#'                           "nothing"))
#' emoji_categorize(df, text)
#' @export
emoji_categorize <- function(data, text) {
  lst <- emoji_glyph_list(.emoji_text_col(data, {{ text }}))
  ref <- emoji_reference()
  cat_of <- stats::setNames(ref$group, ref$key)

  all_glyphs <- unique(unlist(lst, use.names = FALSE))
  key_lookup <- stats::setNames(emoji_key(all_glyphs), all_glyphs)

  cats <- vapply(lst, function(g) {
    if (!length(g)) return(NA_character_)
    keys <- unique(key_lookup[g])
    keys <- keys[!is.na(keys)]
    cc <- unique(cat_of[keys])
    cc <- cc[!is.na(cc)]
    if (!length(cc)) NA_character_ else paste(cc, collapse = "|")
  }, character(1))

  out <- .emoji_as_tibble(data)
  out$.emoji_category <- cats
  # Keep on "has an emoji", not on "has a categorisable emoji". `cats` is NA
  # for both, so filtering on it dropped rows whose only emoji was a ZWJ
  # sequence newer than the installed reference table -- the same conflation
  # that made 0.2.1 drop rows holding a U+FE0F-qualified glyph, fixed there
  # only for that one join.
  out[lengths(lst) > 0L, , drop = FALSE]
}
