#' Summarise emoji presence in a text column
#'
#' `emoji_summary()` reports how many entries in a text column contain at least
#' one emoji, alongside the total number of entries. An entry is counted once
#' regardless of how many emoji it holds.
#'
#' @param data A data frame or tibble containing a text column. Grouped data
#'   frames are accepted. The verbs that work a row at a time (adding columns,
#'   or keeping and expanding rows) carry the grouping through to their result,
#'   as [dplyr::mutate()] and [dplyr::filter()] do. The verbs that pool across
#'   rows -- the counts, the co-occurrence edge lists, the time series -- warn
#'   that they ignore the grouping and return one corpus-wide answer.
#' @param text The text column to scan, supplied unquoted. Any atomic column
#'   is accepted and read as character, so a `factor` works and a numeric,
#'   `Date` or logical one simply contains no emoji. A list column -- or a
#'   data-frame column -- is refused rather than coerced, because coercing one
#'   deparses it and the emoji found would be in the code rather than in your
#'   data. What counts as an emoji is the same in every verb; see the
#'   *Detection* section of [tidyEmoji] for the one case that surprises
#'   people, code points that are emoji only when they carry `U+FE0F`.
#' @param presentation Which code points count as emoji: `"emoji"` (the
#'   default) or `"any"`.
#'
#'   * `"emoji"` requires emoji presentation, so `U+2764 U+FE0F` is an emoji
#'     and the bare `U+2764` is not. This is the default and it will stay the
#'     default: widening it would silently recount every corpus already
#'     analysed.
#'   * `"any"` also reads the text-presentation spellings Unicode lists for an
#'     emoji (the bare heart, `U+263A`, `U+2714`, a keycap without its
#'     selector), because several keyboards emit them. It never reads the
#'     copyright, registered and trade-mark signs (`U+00A9`, `U+00AE`,
#'     `U+2122`), which are typography far more often than they are emoji.
#'
#'   `"any"` only ever adds occurrences: everything `"emoji"` finds, it finds
#'   too, in the same place. [emoji_coverage()] reports how many it adds and
#'   how many of those a lexicon can score, which is the cost of the choice in
#'   one number. Every verb that counts, scores or rewrites the emoji in a
#'   text column takes this argument, so counts still agree across the
#'   package for whichever value you use. The flag verbs do not need it,
#'   since a flag has no text-presentation form.
#'
#' @return A one-row tibble with columns \code{n_with_emoji} (entries containing at
#'   least one emoji), \code{n_total} (all entries), \code{n_orphan_components}
#'   and \code{n_invalid_flags}. The last two count *glyphs*, not entries: the
#'   emoji material the text holds that is not an emoji, and so is in no other
#'   count. `n_orphan_components` is the skin-tone swatches and hair
#'   components standing alone, as in `U+1F600 U+1F3FB`, where the tone
#'   follows a base that cannot take one; `n_invalid_flags` is the runs of
#'   regional indicators that spell no country, such as `U+1F1FD U+1F1FD`
#'   ("XX") or a lone indicator. Both were counted as emoji before 0.6.0, so
#'   they are what to look at when a corpus reports fewer emoji than it used
#'   to. See the *Detection* section of [tidyEmoji].
#' @seealso [emoji_filter()] to keep the emoji-bearing rows themselves;
#'   [emoji_coverage()] for what a lexicon can score of them.
#' @examples
#' df <- data.frame(text = c("I love R \U0001f600",
#'                           "no emoji here",
#'                           "flags \U0001f3c1\U0001f600"))
#' emoji_summary(df, text)
#'
#' # a bare heart is an emoji only under presentation = "any"
#' hearts <- data.frame(text = c("I \u2764 R", "I \u2764\ufe0f R"))
#' emoji_summary(hearts, text)
#' emoji_summary(hearts, text, presentation = "any")
#' @concept detection
#' @concept reporting
#' @export
emoji_summary <- function(data, text, presentation = "emoji") {
  presentation <- .emoji_check_presentation(presentation)
  .emoji_warn_grouped(data, "emoji_summary", "0.2.1")
  v <- .emoji_text_col(data, {{ text }})
  sp <- .emoji_spans(v, presentation)
  kinds <- sp$kinds
  n_kind <- function(k) {
    sum(vapply(kinds, function(z) sum(z == k), integer(1)))
  }
  has <- vapply(seq_along(sp$locs), function(i) {
    k <- kinds[[i]]
    if (is.null(k)) nrow(sp$locs[[i]]) > 0L else any(k <= 2L)
  }, logical(1))
  tibble::tibble(
    n_with_emoji = sum(has, na.rm = TRUE),
    n_total = length(v),
    n_orphan_components = n_kind(.emoji_kind_component),
    n_invalid_flags = n_kind(.emoji_kind_flag)
  )
}


#' Keep only the rows whose text contains emoji
#'
#' `emoji_filter()` returns the rows of `data` whose text column contains at
#' least one emoji, preserving every original column. `emoji_tweets()`, its
#' old name, is defunct: deprecated in 0.2.1 and warning through 0.6.0, it
#' stops since 0.7.0 with an error naming `emoji_filter()`, and it is deleted
#' in 0.8.0.
#'
#' @inheritParams emoji_summary
#' @return A tibble containing only the rows with at least one emoji, with
#'   every original column kept. A grouped input stays grouped, as it would
#'   through [dplyr::filter()].
#' @seealso [emoji_summary()] for the counts this filter is derived from;
#'   [emoji_ratio()] to find the rows that are *only* emoji;
#'   [emoji_extract_unnest()] and [emoji_tokens()] for the emoji themselves.
#' @examples
#' df <- data.frame(text = c("hi \U0001f600", "no emoji", "bye \U0001f44b"))
#' emoji_filter(df, text)
#' @concept detection
#' @export
emoji_filter <- function(data, text, presentation = "emoji") {
  presentation <- .emoji_check_presentation(presentation)
  v <- .emoji_text_col(data, {{ text }})
  keep <- emoji_has(v, presentation)
  # Belt-and-braces: emoji_has() cannot return NA, because emoji_glyph_list()
  # maps NA text to "" before counting, so "NA text is never an emoji" is
  # enforced upstream. Kept so the subscript is provably safe here rather than
  # only safe because of what a different function does.
  keep[is.na(keep)] <- FALSE
  .emoji_as_tibble(data)[keep, , drop = FALSE]
}

#' @rdname emoji_filter
#' @export
emoji_tweets <- function(data, text) {
  # Soft-deprecated from 0.2.1 to 0.5.0, warned in 0.6.0, which announced its
  # removal in 0.7.0. It is defunct rather than deleted: still exported for
  # one release, so an old script fails here, with the replacement named,
  # instead of with "could not find function". Deleted in 0.8.0.
  lifecycle::deprecate_stop(
    "0.2.1", "emoji_tweets()", "emoji_filter()",
    details = "emoji_tweets() is deleted in tidyEmoji 0.8.0."
  )
}
