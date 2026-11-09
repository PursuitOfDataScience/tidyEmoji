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
#' @concept counting
#' @concept LLM output auditing
#' @export
emoji_frequency <- function(data, text, presentation = "emoji") {
  presentation <- .emoji_check_presentation(presentation)
  .emoji_warn_grouped(data, "emoji_frequency", "0.2.1")
  glyphs <- unlist(emoji_glyph_list(.emoji_text_col(data, {{ text }}),
                                    presentation),
                   use.names = FALSE)
  if (!length(glyphs)) {
    return(tibble::tibble(emoji = character(), name = character(),
                          shortcode = character(), group = character(),
                          n = integer()))
  }
  counts <- tibble::tibble(emoji = glyphs) %>%
    dplyr::count(emoji, name = "n") %>%
    # stable secondary sort key so ties don't depend on input order
    .emoji_arrange(dplyr::desc(n), emoji)
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
#' @param duplicated_unicode `r lifecycle::badge("defunct")` Use `duplicated`
#'   instead. Deprecated in 0.2.0 and defunct since 0.7.0: supplying it is an
#'   error that names `duplicated`, whatever the value. It leaves the
#'   signature in 0.8.0.
#' @return A tibble with columns `emoji_name`, `unicode`, `emoji_category` and
#'   `n`, sorted by descending `n` with ties broken by the glyph so the order is
#'   deterministic -- the same rule [emoji_frequency()] uses. When a tie
#'   straddles position `n` the glyph order decides which side of the cut each
#'   emoji falls on, and a corpus with fewer than `n` distinct emoji returns
#'   every one of them rather than padding to `n`.
#'
#'   `duplicated = TRUE` leaves several rows sharing both `n` and `unicode`,
#'   which that rule does not settle. Within one glyph the rows come out in
#'   [emoji_unicode_crosswalk]'s order for the glyph's codepoint key, and the
#'   first of them carries the same `emoji_name` that `duplicated = FALSE`
#'   reports. Because the join is on the key rather than on the spelling, a
#'   glyph collects the aliases of *every* spelling of itself: the unqualified
#'   `U+26F9 U+200D U+2640` is listed under `woman_bouncing_ball` and under
#'   the two aliases the fully-qualified spelling carries. That is what "every
#'   name an emoji is known by" means here.
#' @seealso [emoji_frequency()] for the full distribution.
#' @examples
#' df <- data.frame(text = c("\U0001f600\U0001f600\U0001f3c1", "\U0001f621"))
#' top_n_emojis(df, text, n = 2)
#' @concept counting
#' @export
top_n_emojis <- function(data, text, n = 20, duplicated = FALSE,
                         duplicated_unicode = lifecycle::deprecated(),
                         presentation = "emoji") {
  presentation <- .emoji_check_presentation(presentation)
  if (!.emoji_is_count(n, finite = FALSE)) {
    # head(x, -1) silently drops the last row rather than erroring, and
    # head(x, 2.5) silently returns two, so either mistake would have returned
    # a quietly wrong answer
    stop("`n` must be a single non-negative whole number.", call. = FALSE)
  }
  if (lifecycle::is_present(duplicated_unicode)) {
    # Deprecated in 0.2.0 and warned for five releases, so defunct in 0.7.0:
    # a script still passing it stops, told what to write instead, rather
    # than being answered. The argument stays in the signature until 0.8.0 so
    # that the error is this one and not R's "unused argument".
    lifecycle::deprecate_stop(
      "0.2.0", "top_n_emojis(duplicated_unicode)", "top_n_emojis(duplicated)"
    )
  }
  .emoji_check_flag(duplicated, "duplicated")

  if (.emoji_warn_grouped(data, "top_n_emojis", "0.2.1")) {
    # Ungroup so the downstream emoji_frequency() call does not warn a second
    # time about the same ignored grouping.
    data <- dplyr::ungroup(data)
  }

  freq <- emoji_frequency(data, {{ text }}, presentation = presentation)

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
        tidyEmoji::emoji_unicode_crosswalk %>%
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
      .emoji_arrange(dplyr::desc(n), unicode)
  } else {
    out <- freq_head %>%
      dplyr::transmute(emoji_name = shortcode, unicode = emoji,
                       emoji_category = group, n = n)
  }

  out
}
