#' Categorise each row by the emoji categories it contains
#'
#' `emoji_categorize()` keeps the rows of `data` that contain emoji and adds a
#' `.emoji_category` column listing the distinct Unicode categories present in
#' that row (for example "Smileys & Emotion"), separated by `|` when a row spans
#' more than one category.
#'
#' @inheritParams emoji_summary
#' @return `data`, as a tibble, filtered to the rows containing emoji and with an
#'   added `.emoji_category` column.
#' @examples
#' df <- data.frame(text = c("smile \U0001f600",
#'                           "flag \U0001f3c1\U0001f600",
#'                           "nothing"))
#' emoji_categorize(df, text)
#' @export
emoji_categorize <- function(data, text) {
  lst <- emoji_glyph_list(dplyr::pull(data, {{ text }}))
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

  out <- tibble::as_tibble(data)
  out$.emoji_category <- cats
  out[!is.na(cats), , drop = FALSE]
}
