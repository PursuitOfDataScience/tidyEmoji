# The ten Unicode categories, in one fixed order, read from the bundled
# crosswalk so the two cannot drift apart. This is emoji_type_levels()' role
# for the category vocabulary: it is what stops `.emoji_category` depending on
# the order the emoji happened to appear in.
.emoji_category_levels <- function() {
  tidyEmoji::category_unicode_crosswalk$category
}

#' Categorise each row by the emoji categories it contains
#'
#' `emoji_categorize()` keeps the rows of `data` that contain emoji and adds a
#' `.emoji_category` column listing the distinct Unicode categories present in
#' that row (for example "Smileys & Emotion"), separated by `|` when a row spans
#' more than one category.
#'
#' @details
#' A row is kept because it contains an emoji, not because that emoji could be
#' categorised. If none of a row's emoji is in the reference table the row is
#' kept with `.emoji_category` set to `NA`. Dropping it would silently shrink
#' the corpus, and by exactly the rows a user whose Unicode coverage is behind
#' most needs to see.
#'
#' What reaches that `NA` is an emoji the catalogue does not list that is no
#' joined sequence, such as a family with a skin tone (`U+1F46A U+1F3FD`, a
#' sequence Unicode allows but does not recommend). A zero-width-joiner
#' sequence the catalogue does not list, newer than the bundled catalogue or
#' joined in a combination Unicode does not recommend, used to reach it too.
#' Since 0.7.0 it counts as its parts, as in every verb, and they are
#' categorised: a cat joined to a laptop is `"Animals & Nature|Objects"`. Use
#' [emoji_provenance()] to check which catalogue you are matching against.
#'
#' An invalid regional-indicator pair such as `U+1F1FD U+1F1FD` used to reach
#' it as well. Since 0.6.0 it is not an emoji at all, so it no longer keeps a
#' row here; see the Detection section of [tidyEmoji].
#'
#' @inheritParams emoji_summary
#' @return `data`, as a tibble, filtered to the rows containing at least one
#'   emoji, with an added `.emoji_category` column. That column is `NA` for a
#'   row whose emoji are all absent from the reference table.
#' @seealso [emoji_type()] for the smaller functional vocabulary recoded from
#'   the same group and subgroup, and [emoji_faceness()] for the face share it
#'   reduces to; [emoji_frequency()] for per-glyph counts carrying `group`;
#'   [category_unicode_crosswalk] for the ten categories themselves.
#' @examples
#' df <- data.frame(text = c("smile \U0001f600",
#'                           "flag \U0001f3c1\U0001f600",
#'                           "nothing"))
#' emoji_categorize(df, text)
#' @concept categories and types
#' @export
emoji_categorize <- function(data, text, presentation = "emoji") {
  presentation <- .emoji_check_presentation(presentation)
  lst <- emoji_glyph_list(.emoji_text_col(data, {{ text }}), presentation)
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
    # Sorted into the crosswalk's fixed category order, not the order the
    # emoji happen to appear in. First-appearance order made
    # "Flags|Smileys & Emotion" and "Smileys & Emotion|Flags" two different
    # values for one combination, so count(.emoji_category) split every
    # multi-category row across as many groups as the corpus had orderings --
    # which is exactly what the introduction vignette does. emoji_type()
    # already sorts into emoji_type_levels() for the same reason.
    if (!length(cc)) NA_character_ else
      paste(cc[order(match(cc, .emoji_category_levels()))], collapse = "|")
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
