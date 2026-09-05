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
#'   Default `":{x}:"`. Must contain `{x}`, or every emoji would be replaced by
#'   the same literal string. Ignored for `format = "name"`.
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
  if (format == "shortcode" &&
      (!is.character(wrap) || length(wrap) != 1L || is.na(wrap) ||
         !grepl("{x}", wrap, fixed = TRUE))) {
    # a template with no placeholder silently collapses every emoji to the same
    # string -- the dead-argument failure mode the 0.3.0 audit already caught
    stop("`wrap` must be a single string containing `{x}`, the placeholder ",
         "for the shortcode.", call. = FALSE)
  }
  v <- .emoji_text_col(data, {{ text }})
  was_na <- is.na(v)
  v[was_na] <- ""

  locs <- .emoji_locations(v)
  lst <- mapply(.emoji_slice, locs, v, SIMPLIFY = FALSE, USE.NAMES = FALSE)
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
    .emoji_replace_in_order(v[[i]], locs[[i]], g, rpl_lookup[key_lookup[g]])
  }, character(1))
  rewritten[was_na] <- NA_character_

  out <- .emoji_as_tibble(data)
  col_name <- .emoji_col_name(data, {{ text }})
  out[[col_name]] <- rewritten
  .emoji_regroup(out, col_name)
}

# Internal: replace each emoji glyph with its replacement, in reading order,
# rebuilding the string from the (character-based) locate positions so repeated
# glyphs and multi-byte sequences are handled correctly. `locs` is the row's
# start/end matrix from .emoji_locations() and `glyphs` the glyphs sliced from
# it, so the two are aligned by construction.
.emoji_replace_in_order <- function(str, locs, glyphs, replacements) {
  if (!length(glyphs)) return(str)
  if (is.null(locs) || nrow(locs) == 0L) return(str)
  bp <- locs[, "start"]
  ep <- locs[, "end"]
  # unknown emoji keep their glyph rather than vanishing
  rpls <- ifelse(is.na(replacements), glyphs, replacements)
  # Splice: gap + replacement + gap + ... + gap. .emoji_gaps() cuts every
  # stretch outside the glyphs in one pass.
  pieces <- character(2L * length(bp) + 1L)
  pieces[seq(1L, by = 2L, length.out = length(bp) + 1L)] <-
    .emoji_gaps(str, locs)
  pieces[seq(2L, by = 2L, length.out = length(bp))] <- rpls
  paste0(pieces, collapse = "")
}


#' Replace shortcodes with emoji (emojize)
#'
#' `text_to_emoji()` returns a copy of `data` with its text column rewritten so
#' that every `:shortcode:` token is replaced by the corresponding emoji glyph
#' (the inverse of [emoji_to_text()] with `format = "shortcode"`). Shortcodes
#' that do not match a known emoji are left unchanged.
#'
#' @details
#' A shortcode token is a colon, one or more of `A-Z`, `a-z`, `0-9`, `_`, `+`
#' or `-`, and a closing colon. Restricting the token this way means colons
#' used for other purposes -- clock times, URLs, ratios, ordinary punctuation
#' -- cannot swallow a following shortcode: `"meet at 10:30 :wave:"` still
#' emojizes the wave.
#'
#' @inheritParams emoji_summary
#' @return `data`, as a tibble, with the text column rewritten in place. `NA`
#'   entries stay `NA`.
#' @seealso [emoji_to_text()]; [as_emoji()] for the vector helper.
#' @examples
#' df <- data.frame(text = "hi :grinning: bye :waving_hand:")
#' text_to_emoji(df, text)
#'
#' # colons elsewhere in the text do not interfere
#' text_to_emoji(data.frame(text = "https://example.org at 10:30 :grinning:"),
#'               text)
#' @export
text_to_emoji <- function(data, text) {
  v <- .emoji_text_col(data, {{ text }})
  was_na <- is.na(v)
  v[was_na] <- ""
  name_map <- emoji::emoji_name   # named vector: name -> glyph
  # Match only the characters GitHub-style aliases actually use. A permissive
  # ":[^:]+:" lets an unrelated colon pair (a URL, a clock time, "note: ...")
  # consume the opening colon of a real shortcode and silently skip it.
  m <- gregexpr(":[A-Za-z0-9_+-]+:", v)
  regmatches(v, m) <- lapply(regmatches(v, m), function(toks) {
    vapply(toks, function(t) {
      sc <- substr(t, 2L, nchar(t) - 1L)
      g <- unname(name_map[sc])
      if (is.na(g)) t else g
    }, character(1))
  })
  v[was_na] <- NA_character_
  out <- .emoji_as_tibble(data)
  col_name <- .emoji_col_name(data, {{ text }})
  out[[col_name]] <- v
  .emoji_regroup(out, col_name)
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
  ref <- emoji_reference()
  by_name <- stats::setNames(ref$emoji, ref$name)
  by_short <- stats::setNames(ref$emoji, ref$shortcode)
  out <- unname(by_name[x])
  miss <- is.na(out); out[miss] <- unname(by_short[x[miss]])
  miss <- is.na(out); out[miss] <- unname(emoji::emoji_name[x[miss]])
  out
}

