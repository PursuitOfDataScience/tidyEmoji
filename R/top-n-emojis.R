#' Frequency of every emoji in a text column
#'
#' `emoji_frequency()` counts how often each emoji appears across the whole text
#' column (an entry containing the same emoji twice contributes 2) and returns a
#' tibble sorted by descending count, with each emoji's name, shortcode and
#' category.
#'
#' @inheritParams emoji_summary
#' @return A tibble with columns `emoji`, `name`, `shortcode`, `group` and `n`.
#' @seealso [top_n_emojis()] for just the most frequent emoji.
#' @examples
#' df <- data.frame(text = c("\U0001f600\U0001f600", "\U0001f621"))
#' emoji_frequency(df, text)
#' @export
emoji_frequency <- function(data, text) {
  glyphs <- unlist(emoji_glyph_list(dplyr::pull(data, {{ text }})),
                   use.names = FALSE)
  if (!length(glyphs)) {
    return(tibble::tibble(emoji = character(), name = character(),
                          shortcode = character(), group = character(),
                          n = integer()))
  }
  counts <- tibble::tibble(emoji = glyphs) %>%
    dplyr::count(emoji, name = "n", sort = TRUE)
  ref <- emoji_reference()
  idx <- match(counts$emoji, ref$emoji)
  counts$name      <- ref$name[idx]
  counts$shortcode <- ref$shortcode[idx]
  counts$group     <- ref$group[idx]
  counts[c("emoji", "name", "shortcode", "group", "n")]
}


#' The most frequent emoji in a text column
#'
#' `top_n_emojis()` returns the `n` most frequent emoji. By default each emoji
#' (unicode) appears on a single row; set `duplicated = TRUE` to list every name
#' an emoji is known by, so glyphs that share several names occupy several rows.
#'
#' @inheritParams emoji_summary
#' @param n Number of emoji to return. Default `20`.
#' @param duplicated If `TRUE`, emoji with several names occupy several rows.
#'   Default `FALSE`.
#' @param duplicated_unicode `r lifecycle::badge("deprecated")` Use `duplicated`
#'   instead.
#' @return A tibble with columns `emoji_name`, `unicode`, `emoji_category` and
#'   `n`.
#' @seealso [emoji_frequency()] for the full distribution.
#' @examples
#' df <- data.frame(text = c("\U0001f600\U0001f600\U0001f3c1", "\U0001f621"))
#' top_n_emojis(df, text, n = 2)
#' @export
top_n_emojis <- function(data, text, n = 20, duplicated = FALSE,
                         duplicated_unicode = lifecycle::deprecated()) {
  if (lifecycle::is_present(duplicated_unicode)) {
    lifecycle::deprecate_warn(
      "0.2.0", "top_n_emojis(duplicated_unicode)", "top_n_emojis(duplicated)"
    )
    duplicated <- isTRUE(duplicated_unicode) ||
      identical(duplicated_unicode, "yes")
  }

  freq <- emoji_frequency(data, {{ text }})

  if (isTRUE(duplicated)) {
    out <- freq %>%
      dplyr::select(unicode = emoji, n) %>%
      dplyr::inner_join(emoji_unicode_crosswalk, by = "unicode",
                        relationship = "many-to-many") %>%
      dplyr::arrange(dplyr::desc(n)) %>%
      dplyr::select(emoji_name, unicode, emoji_category, n)
  } else {
    out <- freq %>%
      dplyr::transmute(emoji_name = shortcode, unicode = emoji,
                       emoji_category = group, n = n)
  }

  utils::head(out, n)
}
