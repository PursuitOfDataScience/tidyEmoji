#' Replace emoji in a text column with words (demojize)
#'
#' `emoji_to_text()` returns a copy of `data` with its text column rewritten so
#' that every emoji is replaced by its name or shortcode. This is useful for
#' accessibility (screen readers) and as an NLP normalisation step before
#' tokenising. Detection is grapheme-aware and joins go through \code{emoji_key()},
#' so emoji carrying the `U+FE0F` variation selector still resolve.
#'
#' @inheritParams emoji_summary
#' @param format Output form: `"name"` (the Unicode name, e.g.
#'   "grinning face") or `"shortcode"` (the canonical GitHub-style alias, e.g.
#'   "grinning", wrapped as ":grinning:"). Default `"name"`.
#' @param wrap When `format = "shortcode"`, the wrapper applied to each
#'   shortcode, written as a template with `{x}` standing for the shortcode.
#'   Default `":{x}:"`. Ignored for `format = "name"`.
#' @return `data`, as a tibble, with the text column rewritten in place (same
#'   column name). `NA` entries stay `NA`, and emoji with no known name are left
#'   in place unchanged.
#' @seealso [text_to_emoji()] for the inverse (emojize); [as_emoji_name()],
#'   [as_emoji_shortcode()], [as_emoji()] for vector helpers.
#' @examples
#' df <- data.frame(text = "great \U0001f600 love \u2764\ufe0f")
#' emoji_to_text(df, text, format = "name")
#' emoji_to_text(df, text, format = "shortcode")
#' @export
emoji_to_text <- function(data, text, format = c("name", "shortcode"),
                          wrap = ":{x}:") {
  format <- match.arg(format)
  v <- as.character(dplyr::pull(data, {{ text }}))
  was_na <- is.na(v)
  v[was_na] <- ""

  lst <- emoji_glyph_list(v)
  ref <- emoji_reference()

  # Map every unique glyph to its replacement once, then splice per row.
  # Shortcodes use the canonical (first) GitHub-style alias, the same one
  # reported by emoji_frequency() and as_emoji_shortcode(), so the output is
  # deterministic and locale-independent.
  if (format == "name") {
    rpl_lookup <- stats::setNames(ref$name, ref$key)
  } else {
    wrapped <- vapply(ref$shortcode, function(s) {
      if (is.na(s)) NA_character_ else gsub("{x}", s, wrap, fixed = TRUE)
    }, character(1), USE.NAMES = FALSE)
    rpl_lookup <- stats::setNames(wrapped, ref$key)
  }
  all_glyphs <- unique(unlist(lst, use.names = FALSE))
  key_lookup <- stats::setNames(emoji_key(all_glyphs), all_glyphs)
  rewritten <- vapply(seq_along(v), function(i) {
    g <- lst[[i]]
    if (!length(g)) return(v[[i]])
    .emoji_replace_in_order(v[[i]], g, rpl_lookup[key_lookup[g]])
  }, character(1))
  rewritten[was_na] <- NA_character_

  out <- tibble::as_tibble(data)
  col_name <- .emoji_col_name(data, {{ text }})
  out[[col_name]] <- rewritten
  out
}

# Internal: resolve the (single) column name selected by a tidy selection like
# `{{ text }}`, without depending on rlang/tidyselect directly.
.emoji_col_name <- function(data, col) {
  nm <- names(dplyr::select(data, {{ col }}))
  if (length(nm) != 1L) {
    stop("`text` must select exactly one column.", call. = FALSE)
  }
  nm
}

# Internal: replace each emoji glyph with its replacement, in reading order,
# rebuilding the string from the (character-based) locate positions so repeated
# glyphs and multi-byte sequences are handled correctly.
.emoji_replace_in_order <- function(str, glyphs, replacements) {
  if (!length(glyphs)) return(str)
  locs <- emoji::emoji_locate_all(str)[[1L]]
  if (is.null(locs) || nrow(locs) == 0L) return(str)
  # emoji_extract_all and emoji_locate_all emit emoji in the same order, so the
  # replacements align row-by-row. If they ever disagree, fall back to a safe
  # sequential fixed substitution.
  if (nrow(locs) != length(glyphs)) {
    for (k in seq_along(glyphs)) {
      r <- replacements[k]
      if (is.na(r)) next   # unknown emoji: leave the glyph in place
      str <- sub(glyphs[k], r, str, fixed = TRUE)
    }
    return(str)
  }
  bp <- locs[, "start"]
  ep <- locs[, "end"]
  # unknown emoji keep their glyph rather than vanishing
  rpls <- ifelse(is.na(replacements), glyphs, replacements)
  # Splice: prefix + replacement + middle + ... + suffix.
  pieces <- character(2L * length(bp) + 1L)
  prev <- 1L
  j <- 1L
  for (i in seq_along(bp)) {
    pieces[j] <- substr(str, prev, bp[i] - 1L)
    pieces[j + 1L] <- rpls[i]
    prev <- ep[i] + 1L
    j <- j + 2L
  }
  pieces[j] <- substr(str, prev, nchar(str))
  paste0(pieces, collapse = "")
}


#' Replace shortcodes with emoji (emojize)
#'
#' `text_to_emoji()` returns a copy of `data` with its text column rewritten so
#' that every `:shortcode:` token is replaced by the corresponding emoji glyph
#' (the inverse of [emoji_to_text()] with `format = "shortcode"`). Shortcodes
#' that do not match a known emoji are left unchanged.
#'
#' @inheritParams emoji_summary
#' @return `data`, as a tibble, with the text column rewritten in place. `NA`
#'   entries stay `NA`.
#' @seealso [emoji_to_text()]; [as_emoji()] for the vector helper.
#' @examples
#' df <- data.frame(text = "hi :grinning: bye :waving_hand:")
#' text_to_emoji(df, text)
#' @export
text_to_emoji <- function(data, text) {
  v <- as.character(dplyr::pull(data, {{ text }}))
  was_na <- is.na(v)
  v[was_na] <- ""
  name_map <- emoji::emoji_name   # named vector: name -> glyph
  m <- gregexpr(":[^:]+:", v)
  regmatches(v, m) <- lapply(regmatches(v, m), function(toks) {
    vapply(toks, function(t) {
      sc <- substr(t, 2L, nchar(t) - 1L)
      g <- unname(name_map[sc])
      if (is.na(g)) t else g
    }, character(1))
  })
  v[was_na] <- NA_character_
  out <- tibble::as_tibble(data)
  col_name <- .emoji_col_name(data, {{ text }})
  out[[col_name]] <- v
  out
}


#' Vector helpers: convert emoji to/from names and shortcodes
#'
#' Small vector-level helpers for ad-hoc use. They do not take a data frame.
#'
#' * `as_emoji_name(x)` maps emoji glyphs to their Unicode names.
#' * `as_emoji_shortcode(x)` maps emoji glyphs to their first shortcode.
#' * `as_emoji(x)` maps shortcodes/names to the emoji glyph (emojize).
#'
#' All three resolve through \code{emoji_key()}, so qualified emoji (carrying
#' `U+FE0F`) and unqualified forms resolve identically. Unmatched inputs return
#' `NA`.
#'
#' @param x A character vector of emoji glyphs (for `as_emoji_name`,
#'   `as_emoji_shortcode`) or of shortcodes/names (for `as_emoji`).
#' @return A character vector the same length as `x`.
#' @seealso [emoji_to_text()], [text_to_emoji()] for the data-frame verbs.
#' @examples
#' as_emoji_name(c("\U0001f600", "\u2764\ufe0f"))
#' as_emoji_shortcode(c("\U0001f600", "\u2764\ufe0f"))
#' as_emoji(c("grinning", "heart"))
#' @rdname as_emoji_name
#' @export
as_emoji_name <- function(x) {
  ref <- emoji_reference()
  name_lookup <- stats::setNames(ref$name, ref$key)
  unname(name_lookup[emoji_key(as.character(x))])
}

#' @rdname as_emoji_name
#' @export
as_emoji_shortcode <- function(x) {
  ref <- emoji_reference()
  sc_lookup <- stats::setNames(ref$shortcode, ref$key)
  unname(sc_lookup[emoji_key(as.character(x))])
}

#' @rdname as_emoji_name
#' @export
as_emoji <- function(x) {
  x <- as.character(x)
  unname(emoji::emoji_name[x])
}

