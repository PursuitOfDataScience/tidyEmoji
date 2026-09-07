# Functional type: face vs everything else.
#
# The consumer-behaviour literature repeatedly contrasts "emotional" (face)
# emoji with "semantic" (object) emoji and finds different engagement effects.
# That contrast is derivable for free from the Unicode group and subgroup the
# reference table already carries, so this is a documented recode, not new data.

# Unicode group/subgroup -> tidyEmoji type. Vectorised over the reference rows.
.emoji_type_of <- function(group, subgroup) {
  group <- as.character(group)
  group[is.na(group)] <- ""
  # .emoji_fold() is a no-op on the current catalogue -- every subgroup is
  # already lower-case ASCII and none of the literals matched below contains an
  # "i" -- but it keeps the recode locale-independent if either ever changes.
  subgroup <- .emoji_fold(as.character(subgroup))
  subgroup[is.na(subgroup)] <- ""
  out <- rep(NA_character_, length(group))
  out[group == "Smileys & Emotion"] <- "symbol"
  is_face <- group == "Smileys & Emotion" &
    (grepl("face", subgroup, fixed = TRUE) | subgroup == "costume")
  out[is_face] <- "face"
  out[group == "People & Body"] <- "person"
  is_gesture <- group == "People & Body" &
    (startsWith(subgroup, "hand") | subgroup == "person-gesture")
  out[is_gesture] <- "gesture"
  out[group == "Animals & Nature"] <- "nature"
  out[group == "Food & Drink"] <- "food"
  out[group == "Travel & Places"] <- "place"
  out[group == "Activities"] <- "activity"
  out[group == "Objects"] <- "object"
  out[group == "Symbols"] <- "symbol"
  out[group == "Flags"] <- "flag"
  out[group == "Component"] <- "component"
  out
}

# The type levels, in a fixed reporting order.
emoji_type_levels <- function() {
  c("face", "gesture", "person", "nature", "food", "place", "activity",
    "object", "symbol", "flag", "component")
}


#' Functional type of an emoji glyph
#'
#' `as_emoji_type(x)` maps emoji glyphs to a small functional vocabulary --
#' `"face"`, `"gesture"`, `"person"`, `"nature"`, `"food"`, `"place"`,
#' `"activity"`, `"object"`, `"symbol"`, `"flag"`, `"component"` -- recoded from
#' the Unicode group and subgroup. The distinction that matters most in the
#' literature is `face` (emotional) against `object` (semantic).
#'
#' @details
#' The recode is: faces and costumed characters in *Smileys & Emotion* become
#' `face` and the rest of that group (hearts, the anger symbol, ...) becomes
#' `symbol`; hands and gesturing people in *People & Body* become `gesture` and
#' the rest `person`; the remaining Unicode groups map one-to-one. Glyphs the
#' reference table does not know return `NA`.
#'
#' @param x A character vector of emoji glyphs.
#' @return A character vector the same length as `x`.
#' @seealso [emoji_type()] for the data-frame verb, [emoji_faceness()] for the
#'   per-row share, [emoji_categorize()] for the raw Unicode categories.
#' @examples
#' as_emoji_type(c("\U0001f600", "\U0001f44d", "\U0001f355", "\u2764\ufe0f"))
#' @export
as_emoji_type <- function(x) {
  ref <- emoji_reference()
  if (is.null(.tidyEmoji_cache$type)) {
    .tidyEmoji_cache$type <- stats::setNames(
      .emoji_type_of(ref$group, ref$subgroup), ref$key
    )
  }
  unname(.tidyEmoji_cache$type[emoji_key(as.character(x))])
}


#' Which functional types of emoji does each row use?
#'
#' `emoji_type()` adds `.emoji_type`, the distinct functional types present in
#' each row (see [as_emoji_type()]), separated by `|` when a row spans more than
#' one. The face-versus-object contrast it exposes is the key variable in the
#' consumer-behaviour literature on emoji in reviews and marketing copy.
#'
#' @details
#' `.emoji_type` is `NA` for two different reasons, and this column cannot
#' tell you which: a row with no emoji at all, and a row whose every emoji is
#' one the recode cannot type. The second is rare but not impossible -- the
#' recode maps the ten Unicode groups the catalogue currently uses, so a glyph
#' in a group added to Unicode after your \pkg{emoji} package was built has no
#' type -- and it is the same conflation [emoji_categorize()] describes for
#' `.emoji_category`. [emoji_faceness()] separates them: `.emoji_n_typed` is
#' `NA` when the row had no emoji and `0` when it had emoji that could not be
#' typed. [emoji_provenance()] reports which catalogue you are matching
#' against.
#'
#' @inheritParams emoji_summary
#' @return `data`, as a tibble, with an added `.emoji_type` column. Unlike
#'   [emoji_categorize()], no rows are dropped: a row with no emoji gets `NA`,
#'   as does a row whose emoji cannot be typed -- see Details.
#' @seealso [as_emoji_type()], [emoji_faceness()], [emoji_categorize()].
#' @examples
#' df <- data.frame(text = c("yum \U0001f355 \U0001f600", "\U0001f44d", "none"))
#' emoji_type(df, text)
#' @export
emoji_type <- function(data, text) {
  lst <- emoji_glyph_list(.emoji_text_col(data, {{ text }}))
  all_glyphs <- unique(unlist(lst, use.names = FALSE))
  type_lookup <- stats::setNames(as_emoji_type(all_glyphs), all_glyphs)
  types <- vapply(lst, function(g) {
    if (!length(g)) return(NA_character_)
    tt <- unique(unname(type_lookup[g]))
    tt <- tt[!is.na(tt)]
    if (!length(tt)) return(NA_character_)
    tt <- emoji_type_levels()[sort(match(tt, emoji_type_levels()))]
    paste(tt, collapse = "|")
  }, character(1))

  out <- .emoji_as_tibble(data)
  out$.emoji_type <- types
  out
}


#' How face-heavy is each row's emoji use?
#'
#' `emoji_faceness()` reports the share of a row's emoji that are faces. Face
#' emoji act as emotional signals and object emoji as semantic ones, and the
#' two have measurably different effects on engagement, so the split is worth a
#' column of its own.
#'
#' @inheritParams emoji_summary
#' @return `data`, as a tibble, with added columns `.emoji_n`,
#'   `.emoji_n_typed` (emoji whose type is known), `.emoji_n_face` and
#'   `.emoji_faceness` (`.emoji_n_face / .emoji_n_typed`). Rows with no emoji
#'   get `NA`.
#'
#'   `.emoji_n_typed` distinguishes the two ways a share can be missing, as
#'   `.emoji_n_scored` does in [emoji_sentiment()]: `0` means the row had
#'   emoji whose type the recode does not know, `NA` that it had no emoji at
#'   all. `.emoji_faceness` is `NA` in both cases -- a share of no typable
#'   emoji is not 0, it is unknown -- so read the count before the share. See
#'   [emoji_type()] for when a glyph can be untypable.
#' @seealso [emoji_type()], [as_emoji_type()].
#' @examples
#' df <- data.frame(text = c("\U0001f600\U0001f355", "\U0001f600", "none"))
#' emoji_faceness(df, text)
#' @export
emoji_faceness <- function(data, text) {
  lst <- emoji_glyph_list(.emoji_text_col(data, {{ text }}))
  all_glyphs <- unique(unlist(lst, use.names = FALSE))
  type_lookup <- stats::setNames(as_emoji_type(all_glyphs), all_glyphs)
  typed <- lapply(lst, function(g) {
    if (!length(g)) return(character(0))
    tt <- unname(type_lookup[g])
    tt[!is.na(tt)]
  })
  has_emoji <- lengths(lst) > 0L
  n_typed <- as.integer(lengths(typed))
  n_face <- vapply(typed, function(tt) sum(tt == "face"), integer(1))

  # typed allocate-then-fill: ifelse() returned logical(0) for a zero-row input
  typed_out <- rep(NA_integer_, length(has_emoji))
  face_out <- rep(NA_integer_, length(has_emoji))
  faceness <- rep(NA_real_, length(has_emoji))
  typed_out[has_emoji] <- n_typed[has_emoji]
  face_out[has_emoji] <- n_face[has_emoji]
  scoreable <- n_typed > 0L
  faceness[scoreable] <- n_face[scoreable] / n_typed[scoreable]

  out <- .emoji_as_tibble(data)
  out$.emoji_n <- as.integer(lengths(lst))
  out$.emoji_n_typed <- typed_out
  out$.emoji_n_face <- face_out
  out$.emoji_faceness <- faceness
  out
}
