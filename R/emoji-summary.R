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
#' @param text The text column to scan, supplied unquoted. What counts as an
#'   emoji is the same in every verb; see the *Detection* section of
#'   [tidyEmoji] for the one case that surprises people, code points that
#'   are emoji only when they carry `U+FE0F`.
#'
#' @return A one-row tibble with columns \code{n_with_emoji} (entries containing at
#'   least one emoji) and \code{n_total} (all entries).
#' @seealso [emoji_filter()] to keep the emoji-bearing rows themselves.
#' @examples
#' df <- data.frame(text = c("I love R \U0001f600",
#'                           "no emoji here",
#'                           "flags \U0001f3c1\U0001f600"))
#' emoji_summary(df, text)
#' @export
emoji_summary <- function(data, text) {
  .emoji_warn_grouped(data, "emoji_summary", "0.2.1")
  v <- .emoji_text_col(data, {{ text }})
  has <- emoji_has(v)
  tibble::tibble(
    n_with_emoji = sum(has, na.rm = TRUE),
    n_total = length(v)
  )
}


#' Keep only the rows whose text contains emoji
#'
#' `emoji_filter()` returns the rows of `data` whose text column contains at
#' least one emoji, preserving every original column. `emoji_tweets()` is a
#' synonym retained for backward compatibility.
#'
#' @inheritParams emoji_summary
#' @return A tibble containing only the rows with at least one emoji, with
#'   every original column kept. A grouped input stays grouped, as it would
#'   through [dplyr::filter()].
#' @examples
#' df <- data.frame(text = c("hi \U0001f600", "no emoji", "bye \U0001f44b"))
#' emoji_filter(df, text)
#' @export
emoji_filter <- function(data, text) {
  v <- .emoji_text_col(data, {{ text }})
  keep <- emoji_has(v)
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
  lifecycle::deprecate_soft("0.2.1", "emoji_tweets()", "emoji_filter()")
  emoji_filter(data, {{ text }})
}
