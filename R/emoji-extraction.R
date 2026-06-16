#' Add a list-column of the emoji found in each row
#'
#' `emoji_extract_nest()` returns `data` unchanged except for an added
#' list-column, `.emoji_unicode`, holding the emoji found in each row. Detection
#' is grapheme-aware, so skin-tone modifiers and ZWJ sequences (for example
#' family emoji) are kept intact as a single emoji.
#'
#' @inheritParams emoji_summary
#' @return `data` with an added list-column `.emoji_unicode`.
#' @seealso [emoji_extract_unnest()] for a long, counted form and
#'   [emoji_tokens()] for one row per emoji with metadata.
#' @examples
#' df <- data.frame(text = c("hi \U0001f600\U0001f603", "none"))
#' emoji_extract_nest(df, text)
#' @export
emoji_extract_nest <- function(data, text) {
  dplyr::mutate(data, .emoji_unicode = emoji_glyph_list({{ text }}))
}


#' Emoji counts per row, in long (tidy) form
#'
#' `emoji_extract_unnest()` returns one row per (row, emoji) pair with a count,
#' dropping rows that contain no emoji. `row_number` refers to the position of
#' the entry in `data`.
#'
#' @inheritParams emoji_summary
#' @return A tibble with columns `row_number`, `.emoji_unicode` and
#'   `.emoji_count`.
#' @examples
#' df <- data.frame(text = c("hi \U0001f600\U0001f600", "none", "\U0001f44b"))
#' emoji_extract_unnest(df, text)
#' @export
emoji_extract_unnest <- function(data, text) {
  lst <- emoji_glyph_list(dplyr::pull(data, {{ text }}))
  tibble::tibble(
    row_number     = rep(seq_along(lst), lengths(lst)),
    .emoji_unicode = as.character(unlist(lst, use.names = FALSE))
  ) %>%
    dplyr::count(row_number, .emoji_unicode, name = ".emoji_count") %>%
    dplyr::arrange(row_number, .emoji_unicode)
}


#' Tidy emoji tokens, one row per occurrence with metadata
#'
#' `emoji_tokens()` expands `data` to one row per emoji occurrence (in reading
#' order), keeping the original columns and adding the glyph together with its
#' name, category and sentiment score. This mirrors the one-token-per-row shape
#' familiar from tidy text mining and is convenient for counting, joining and
#' plotting.
#'
#' @inheritParams emoji_summary
#' @return A tibble with the original columns plus `.emoji`, `.emoji_name`,
#'   `.emoji_category` and `.emoji_sentiment`. Rows without emoji are dropped.
#' @seealso [emoji_frequency()] for corpus-level counts and [emoji_sentiment()]
#'   for per-row sentiment.
#' @examples
#' df <- data.frame(id = 1:2, text = c("great \U0001f600", "bad \U0001f621"))
#' emoji_tokens(df, text)
#' @export
emoji_tokens <- function(data, text) {
  data <- tibble::as_tibble(data)
  data$.emoji <- emoji_glyph_list(dplyr::pull(data, {{ text }}))
  out <- tidyr::unnest(data, ".emoji")
  ref <- emoji_reference()
  idx <- match(out$.emoji, ref$emoji)
  out$.emoji_name      <- ref$name[idx]
  out$.emoji_category  <- ref$group[idx]
  out$.emoji_sentiment <- unname(emoji_sentiment_map()[emoji_key(out$.emoji)])
  out
}
