#' Frequency of every emoji in a text column
#'
#' `emoji_frequency()` counts how often each emoji appears across the whole text
#' column (an entry containing the same emoji twice contributes 2) and returns a
#' tibble sorted by descending count, with each emoji's name, shortcode and
#' category.
#'
#' @inheritParams emoji_summary
#' @return A tibble with columns `emoji`, `name`, `shortcode`, `group` and `n`,
#'   sorted by descending `n` with ties broken by the glyph so the order is
#'   deterministic.
#' @seealso [top_n_emojis()] for just the most frequent emoji.
#' @examples
#' df <- data.frame(text = c("\U0001f600\U0001f600", "\U0001f621"))
#' emoji_frequency(df, text)
#' @export
emoji_frequency <- function(data, text) {
  if (dplyr::is_grouped_df(data)) {
    lifecycle::deprecate_warn(
      "0.2.1", "emoji_frequency(data = \"must be ungrouped data\")",
      details = "emoji_frequency() currently ignores groups. Supply ungrouped data or expect a single global result."
    )
  }
  glyphs <- unlist(emoji_glyph_list(dplyr::pull(data, {{ text }})),
                   use.names = FALSE)
  if (!length(glyphs)) {
    return(tibble::tibble(emoji = character(), name = character(),
                          shortcode = character(), group = character(),
                          n = integer()))
  }
  counts <- tibble::tibble(emoji = glyphs) %>%
    dplyr::count(emoji, name = "n") %>%
    # stable secondary sort key so ties don't depend on input order
    dplyr::arrange(dplyr::desc(n), emoji)
  ref <- emoji_reference()
  idx <- match(emoji_key(counts$emoji), ref$key)
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

  if (dplyr::is_grouped_df(data)) {
    lifecycle::deprecate_warn(
      "0.2.1", "top_n_emojis(data = \"must be ungrouped data\")",
      details = "top_n_emojis() currently ignores groups. Supply ungrouped data or expect a single global result."
    )
    # Ungroup so the downstream emoji_frequency() call does not warn a second
    # time about the same ignored grouping.
    data <- dplyr::ungroup(data)
  }

  freq <- emoji_frequency(data, {{ text }})

  # n counts distinct emoji: take head before expanding names
  freq_head <- utils::head(freq, n)

  if (isTRUE(duplicated)) {
    # Expand to one row per alias the emoji is known by. Only the per-alias
    # `emoji_name` comes from the crosswalk; the `unicode` is always the exact
    # glyph the extractor returned (never NA, never a differently-qualified
    # twin) and `emoji_category` is the reference `group`. A left_join means an
    # emoji with no alias still survives as a single row (emoji_name = NA).
    freq_head$key <- emoji_key(freq_head$emoji)
    out <- freq_head %>%
      dplyr::select(key, emoji, group, n) %>%
      dplyr::left_join(
        emoji_unicode_crosswalk %>%
          dplyr::select(key, emoji_name) %>%
          dplyr::distinct(),
        by = "key", relationship = "many-to-many"
      ) %>%
      dplyr::transmute(
        emoji_name     = emoji_name,
        unicode        = emoji,
        emoji_category = group,
        n              = n
      ) %>%
      dplyr::arrange(dplyr::desc(n), unicode)
  } else {
    out <- freq_head %>%
      dplyr::transmute(emoji_name = shortcode, unicode = emoji,
                       emoji_category = group, n = n)
  }

  out
}
