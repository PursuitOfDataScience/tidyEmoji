# Structural & intensity metrics: where emoji sit in the text and how much of
# the text they make up. Pure computation over emoji::emoji_locate_all() and
# character counts; no metadata joins.

# Internal: emoji locations per element, as a list of start/end matrices
# (possibly 0-row). Positions are in characters, matching substr().
.emoji_locations <- function(x) {
  x <- as.character(x)
  x[is.na(x)] <- ""
  emoji::emoji_locate_all(x)
}

#' Where do emoji sit within each text?
#'
#' `emoji_position()` reports, for each row, the character position of the
#' first and last emoji and the mean *relative* position of all emoji
#' occurrences, from 0 (the very start of the text) to 1 (the very end). The
#' Emoji Sentiment Ranking (Kralj Novak et al., 2015) tracks the same relative
#' position, and it is a studied signal: emoji cluster near the end of
#' messages.
#'
#' The relative position of an occurrence starting at character `s` in a text
#' of `L` characters is `(s - 1) / (L - 1)` (taken as 0 when `L <= 1`).
#' Positions are counted in characters (code points), the same unit as
#' [substr()].
#'
#' @inheritParams emoji_summary
#' @return `data`, as a tibble, with added columns `.emoji_n`, `.emoji_first`
#'   and `.emoji_last` (character positions where the first/last emoji start)
#'   and `.emoji_rel_position` (mean relative position in `[0, 1]`). Rows
#'   without emoji get `NA` positions.
#' @seealso [emoji_density()] and [emoji_ratio()] for intensity metrics.
#' @examples
#' df <- data.frame(text = c("\U0001f600 leading", "trailing \U0001f600",
#'                           "none"))
#' emoji_position(df, text)
#' @export
emoji_position <- function(data, text) {
  v <- as.character(dplyr::pull(data, {{ text }}))
  locs <- .emoji_locations(v)
  n <- lengths(emoji_glyph_list(v))
  len <- nchar(v)
  len[is.na(len)] <- 0L

  first <- vapply(locs, function(m) {
    if (is.null(m) || nrow(m) == 0L) NA_integer_ else as.integer(min(m[, "start"]))
  }, integer(1))
  last <- vapply(locs, function(m) {
    if (is.null(m) || nrow(m) == 0L) NA_integer_ else as.integer(max(m[, "start"]))
  }, integer(1))
  rel <- vapply(seq_along(locs), function(i) {
    m <- locs[[i]]
    if (is.null(m) || nrow(m) == 0L) return(NA_real_)
    L <- len[i]
    if (L <= 1L) return(0)
    mean((m[, "start"] - 1) / (L - 1))
  }, numeric(1))

  out <- tibble::as_tibble(data)
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
  v <- as.character(dplyr::pull(data, {{ text }}))
  n <- lengths(emoji_glyph_list(v))
  n_char <- nchar(v)
  # maximal runs of non-whitespace
  n_token <- vapply(strsplit(trimws(v), "\\s+"), function(t) {
    sum(nzchar(t))
  }, integer(1))
  n_token[is.na(v)] <- NA_integer_

  out <- tibble::as_tibble(data)
  out$.emoji_n <- as.integer(n)
  out$.emoji_per_char <- ifelse(is.na(n_char) | n_char == 0L, NA_real_,
                                n / n_char)
  out$.emoji_per_token <- ifelse(is.na(n_token) | n_token == 0L, NA_real_,
                                 n / n_token)
  out
}


#' What share of the text is emoji — and is it emoji-only?
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
  v <- as.character(dplyr::pull(data, {{ text }}))
  was_na <- is.na(v)
  locs <- .emoji_locations(v)
  n_char <- nchar(v)

  emoji_chars <- vapply(locs, function(m) {
    if (is.null(m) || nrow(m) == 0L) 0L else as.integer(sum(m[, "end"] - m[, "start"] + 1L))
  }, integer(1))

  ratio <- ifelse(is.na(n_char) | n_char == 0L, NA_real_,
                  emoji_chars / n_char)

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

  out <- tibble::as_tibble(data)
  out$.emoji_ratio <- ratio
  out$.emoji_only <- only
  out
}
