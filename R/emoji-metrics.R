# Structural & intensity metrics: where emoji sit in the text and how much of
# the text they make up. Pure computation over .emoji_locations() (the engine's
# grapheme-aware locator) and character counts; no metadata joins.

#' Where do emoji sit within each text?
#'
#' `emoji_position()` reports, for each row, the character position of the
#' first and last emoji and the mean *relative* position of all emoji
#' occurrences, from 0 (the very start of the text) to 1 (the very end). The
#' Emoji Sentiment Ranking (Kralj Novak et al., 2015) tracks the same relative
#' position, and it is a studied signal: emoji cluster near the end of
#' messages.
#'
#' @details
#' `.emoji_first` and `.emoji_last` are code-point offsets, the unit
#' [substr()] uses, so they can be fed straight back to it.
#'
#' `.emoji_rel_position` is *not* measured in code points. Each emoji counts as
#' one position however many code points it is built from, so an emoji that is
#' the last thing in the text scores 1 whether it is a single-code-point
#' smiley, a two-code-point flag or a seven-code-point family. Counting code
#' points instead put a sentence-final family emoji a third of the way through
#' its message. Everything that is not an emoji still counts one position per
#' code point, so a combining accent elsewhere in the text counts twice; that
#' affects the denominator only, and only for text carrying such marks.
#'
#' Positions are in *logical* (storage) order, not visual order. In a
#' right-to-left script an emoji that is logically last renders at the reader's
#' left, so "final" here means final in the string, not final on the screen.
#'
#' @inheritParams emoji_summary
#' @return `data`, as a tibble, with added columns `.emoji_n`, `.emoji_first`
#'   and `.emoji_last` (code-point offsets where the first/last emoji start)
#'   and `.emoji_rel_position` (mean relative position in `[0, 1]`, counting
#'   each emoji as one position). Rows without emoji get `NA` positions.
#' @seealso [emoji_density()] and [emoji_ratio()] for intensity metrics.
#' @examples
#' df <- data.frame(text = c("\U0001f600 leading", "trailing \U0001f600",
#'                           "none"))
#' emoji_position(df, text)
#' @export
emoji_position <- function(data, text) {
  v <- .emoji_text_col(data, {{ text }})
  locs <- .emoji_locations(v)
  n <- vapply(locs, nrow, integer(1))
  len <- nchar(v)
  len[is.na(len)] <- 0L

  first <- vapply(locs, function(m) {
    if (is.null(m) || nrow(m) == 0L) NA_integer_ else as.integer(min(m[, "start"]))
  }, integer(1))
  last <- vapply(locs, function(m) {
    if (is.null(m) || nrow(m) == 0L) NA_integer_ else as.integer(max(m[, "start"]))
  }, integer(1))
  # The denominator counts each emoji once, not once per code point. With
  # nchar() a seven-code-point family emoji inflated the length by six, so an
  # emoji that was genuinely the last thing in the message came back at 0.333
  # -- a proportion that reads as "a third of the way through" and is simply
  # wrong. Collapsing each located span to one unit is what makes 1.0 mean
  # "at the end".
  rel <- vapply(seq_along(locs), function(i) {
    m <- locs[[i]]
    if (is.null(m) || nrow(m) == 0L) return(NA_real_)
    extra <- m[, "end"] - m[, "start"]          # code points beyond the first
    L <- len[i] - sum(extra)                    # length in positions
    if (L <= 1L) return(0)
    # shift each start left by the extra code points of the emoji before it
    pos <- m[, "start"] - c(0L, cumsum(extra)[-length(extra)])
    mean((pos - 1) / (L - 1))
  }, numeric(1))

  out <- .emoji_as_tibble(data)
  out$.emoji_n <- as.integer(n)
  out$.emoji_first <- first
  out$.emoji_last <- last
  out$.emoji_rel_position <- rel
  out
}


#' Emoji density per character and per token
#'
#' `emoji_density()` measures how emoji-heavy each text is: the number of
#' emoji per character and per whitespace-delimited token. Rows with no emoji
#' get densities of 0; rows whose text is `NA` or empty get `NA`.
#'
#' @inheritParams emoji_summary
#' @return `data`, as a tibble, with added columns `.emoji_n`,
#'   `.emoji_per_char` (emoji per character of text) and `.emoji_per_token`
#'   (emoji per whitespace-delimited token).
#' @seealso [emoji_position()], [emoji_ratio()].
#' @examples
#' df <- data.frame(text = c("hi \U0001f600", "\U0001f600\U0001f600", "plain"))
#' emoji_density(df, text)
#' @export
emoji_density <- function(data, text) {
  v <- .emoji_text_col(data, {{ text }})
  n <- lengths(emoji_glyph_list(v))
  n_char <- nchar(v)
  # maximal runs of non-whitespace
  n_token <- vapply(strsplit(trimws(v), "\\s+"), function(t) {
    sum(nzchar(t))
  }, integer(1))
  n_token[is.na(v)] <- NA_integer_

  # Allocated NA_real_ first, then filled, rather than built with ifelse():
  # ifelse() takes the result's type from its arguments, so on a zero-row input
  # it returned logical(0) where a populated call returns double, breaking the
  # package's own promise that empty input yields a *typed* zero-row tibble.
  per_char <- rep(NA_real_, length(v))
  per_token <- rep(NA_real_, length(v))
  measurable <- !is.na(n_char) & n_char > 0L
  per_char[measurable] <- n[measurable] / n_char[measurable]
  tok <- measurable & !is.na(n_token)
  per_token[tok] <- n[tok] / n_token[tok]
  # text made only of whitespace has characters but no tokens: no emoji in it
  per_token[tok & n_token == 0L] <- 0

  out <- .emoji_as_tibble(data)
  out$.emoji_n <- as.integer(n)
  out$.emoji_per_char <- per_char
  out$.emoji_per_token <- per_token
  out
}


#' What share of the text is emoji, and is it emoji-only?
#'
#' `emoji_ratio()` reports, per row, the share of the text's characters that
#' belong to emoji, and whether the text is emoji-only (nothing left after
#' removing emoji and whitespace). "Emoji-only" messages are a studied signal
#' in social-media research and a useful filter in practice.
#'
#' The ratio is computed over characters (code points), so a multi-code-point
#' emoji (a ZWJ family, a skin-tone sequence) contributes all of its
#' characters.
#'
#' @inheritParams emoji_summary
#' @return `data`, as a tibble, with added columns `.emoji_ratio` (emoji
#'   characters / all characters, 0 when there are no emoji) and
#'   `.emoji_only` (`TRUE` when the text contains emoji and nothing else but
#'   whitespace). `NA` text gets `NA` in both.
#' @seealso [emoji_position()], [emoji_density()]; [emoji_filter()] to keep
#'   emoji-bearing rows.
#' @examples
#' df <- data.frame(text = c("\U0001f600\U0001f389", "half \U0001f600", "no"))
#' emoji_ratio(df, text)
#' @export
emoji_ratio <- function(data, text) {
  v <- .emoji_text_col(data, {{ text }})
  was_na <- is.na(v)
  locs <- .emoji_locations(v)
  n_char <- nchar(v)

  emoji_chars <- vapply(locs, function(m) {
    if (is.null(m) || nrow(m) == 0L) 0L else as.integer(sum(m[, "end"] - m[, "start"] + 1L))
  }, integer(1))

  # typed allocate-then-fill, as in emoji_density() above
  ratio <- rep(NA_real_, length(v))
  measurable <- !is.na(n_char) & n_char > 0L
  ratio[measurable] <- emoji_chars[measurable] / n_char[measurable]

  # emoji-only: strip the located emoji, then whitespace; nothing may remain
  residual <- vapply(seq_along(v), function(i) {
    m <- locs[[i]]
    s <- v[[i]]
    if (is.na(s)) return(NA_character_)
    if (is.null(m) || nrow(m) == 0L) return(s)
    keep <- character(nrow(m) + 1L)
    prev <- 1L
    for (k in seq_len(nrow(m))) {
      keep[k] <- substr(s, prev, m[k, "start"] - 1L)
      prev <- m[k, "end"] + 1L
    }
    keep[nrow(m) + 1L] <- substr(s, prev, nchar(s))
    paste0(keep, collapse = "")
  }, character(1))
  only <- !was_na & emoji_chars > 0L & !nzchar(gsub("\\s", "", residual))
  only[was_na] <- NA

  out <- .emoji_as_tibble(data)
  out$.emoji_ratio <- ratio
  out$.emoji_only <- only
  out
}
