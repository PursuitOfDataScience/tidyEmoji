#' Summarise emoji presence in a text column
#'
#' `emoji_summary()` reports how many entries in a text column contain at least
#' one emoji, alongside the total number of entries. An entry is counted once
#' regardless of how many emoji it holds.
#'
#' @param data A data frame or tibble containing a text column.
#' @param text The text column to scan, supplied unquoted.
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
  if (dplyr::is_grouped_df(data)) {
    lifecycle::deprecate_warn(
      "0.2.1", "emoji_summary(data = \"must be ungrouped data\")",
      details = "emoji_summary() currently ignores groups. Supply ungrouped data or expect a single global result."
    )
  }
  v <- dplyr::pull(data, {{ text }})
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
#' @return A tibble containing only the rows with at least one emoji. The
#'   result is always a plain (ungrouped) tibble, whatever the class or
#'   grouping of the input.
#' @examples
#' df <- data.frame(text = c("hi \U0001f600", "no emoji", "bye \U0001f44b"))
#' emoji_filter(df, text)
#' @export
emoji_filter <- function(data, text) {
  v <- dplyr::pull(data, {{ text }})
  keep <- emoji_has(v)
  keep[is.na(keep)] <- FALSE
  tibble::as_tibble(data[keep, , drop = FALSE])
}

#' @rdname emoji_filter
#' @export
emoji_tweets <- function(data, text) {
  lifecycle::deprecate_soft("0.2.1", "emoji_tweets()", "emoji_filter()")
  emoji_filter(data, {{ text }})
}
