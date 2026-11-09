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
#'
#'   Only the default is reversible by [text_to_emoji()], which looks for
#'   exactly `:shortcode:`; a `wrap` that does not produce that token leaves
#'   the shortcode in the text as an ordinary word, silently. See
#'   [emoji_sanitize()] for the cases.
#' @param hidden What to do with hidden payloads, as in [emoji_sanitize()]:
#'   `"remove"` (the default) deletes the variation selectors and tag
#'   characters [emoji_hidden()] reports, those the rewrite leaves hidden
#'   included, and `"keep"` leaves them, as every version before 0.7.0 did.
#' @return `data`, as a tibble, with the text column rewritten in place (same
#'   column name). `NA` entries stay `NA`, and emoji with no known name are left
#'   in place unchanged. A ZWJ sequence the catalogue does not list, such as
#'   grinning face, `U+200D`, fire, is written as the names of the parts it
#'   splits into, in order and separated by spaces ("grinning face fire"), or
#'   as their shortcodes (":grinning::fire:"): the parts every other verb
#'   counts since 0.7.0. If any part has no name the sequence stays as it is,
#'   and so it does when it holds anything that is no part, such as a hair
#'   component joined to a face, which naming the parts alone would delete.
#' @section A preview of what a screen reader says:
#' `format = "name"` writes the text a screen reader that reads CLDR names,
#' as NVDA does, will speak. That *Preview* is the design the sighted writers
#' in Griggio, Gorman and Tigwell (CSCW 2024) preferred to warnings, because
#' it leaves the judgement to them, so the package offers it here rather
#' than in a verb of its own; [emoji_a11y_check()] reports the facts their
#' taxonomy is built from.
#' @seealso [text_to_emoji()] for the inverse (emojize); [as_emoji_name()],
#'   [as_emoji_shortcode()], [as_emoji()] for vector helpers;
#'   [emoji_a11y_check()].
#' @examples
#' df <- data.frame(text = "great \U0001f600 love \u2764\ufe0f")
#' emoji_to_text(df, text, format = "name")
#' emoji_to_text(df, text, format = "shortcode")
#' @concept translation
#' @concept accessibility
#' @export
emoji_to_text <- function(data, text, format = c("name", "shortcode"),
                          wrap = ":{x}:", presentation = "emoji",
                          hidden = c("remove", "keep")) {
  format <- .emoji_match_arg(format, c("name", "shortcode"), "format")
  presentation <- .emoji_check_presentation(presentation)
  hidden <- .emoji_check_hidden(hidden)
  if (format == "shortcode" &&
      (!is.character(wrap) || length(wrap) != 1L || is.na(wrap) ||
         !grepl("{x}", wrap, fixed = TRUE))) {
    # a template with no placeholder silently collapses every emoji to the same
    # string -- the dead-argument failure mode the 0.3.0 audit already caught
    stop("`wrap` must be a single string containing `{x}`, the placeholder ",
         "for the shortcode.", call. = FALSE)
  }
  # A "bytes"-encoded template is worse than a rejected one: paste()ing it
  # into the rewritten text marks the *output* column "bytes" too, so the
  # verb returns happily and the failure surfaces later, somewhere else, as
  # R's "translating strings with \"bytes\" encoding is not allowed" from
  # inside whatever the user does with the column next.
  if (format == "shortcode") .emoji_check_string(wrap, "wrap")
  v <- .emoji_text_col(data, {{ text }})
  # hidden payloads go first, as in emoji_sanitize(): the rewrite is of the
  # text a reader sees
  if (hidden == "remove") v <- .emoji_hidden_remove(v)
  was_na <- is.na(v)
  v[was_na] <- ""

  # Every span, the stand-alone components D1 sets aside included: a swatch
  # left in the middle of a rewritten sentence is still a swatch, and the
  # catalogue names it ("light skin tone"), so it is named as before 0.6.0.
  # Stray regional indicators have no name and stay in place, as they did.
  locs <- .emoji_all_spans(v, presentation)
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
  glyph_rpl <- stats::setNames(unname(rpl_lookup[emoji_key(all_glyphs)]),
                               all_glyphs)
  # A ZWJ sequence the catalogue does not list has no name of its own; it is
  # written as the names of the parts it splits into, in order, which is what
  # the counting verbs count and what nearly every platform draws (D7). If
  # any part has no replacement the sequence stays as it is, as any glyph
  # with no known name does.
  zw <- all_glyphs[is.na(glyph_rpl) & grepl(.emoji_zwj, all_glyphs, fixed = TRUE)]
  for (g in zw) {
    cps <- utf8ToInt(g)
    pm <- .emoji_zwj_parts(cps)
    if (!nrow(pm)) next
    # Anything outside the parts but a joiner or a selector is visible
    # material no part accounts for: a hair component joined to a face, a
    # black star with a stray U+FE0F. Writing the parts' names alone deleted
    # it from the text, so such a sequence stays as it is, like any glyph
    # that cannot be named.
    inside <- rep(FALSE, length(cps))
    for (r in seq_len(nrow(pm))) inside[pm[r, "start"]:pm[r, "end"]] <- TRUE
    if (any(!inside & !cps %in% c(0x200DL, 0xFE0EL, 0xFE0FL))) next
    r <- unname(rpl_lookup[emoji_key(substring(g, pm[, "start"], pm[, "end"]))])
    if (!anyNA(r)) {
      glyph_rpl[[g]] <- paste(r, collapse = if (format == "name") " " else "")
    }
  }
  rewritten <- vapply(seq_along(v), function(i) {
    g <- lst[[i]]
    if (!length(g)) return(v[[i]])
    .emoji_replace_in_order(v[[i]], locs[[i]], g, unname(glyph_rpl[g]))
  }, character(1))
  # Naming an emoji can leave hidden what it made legitimate: the tags of a
  # subdivision flag the catalogue does not list are part of the flag until
  # its black flag becomes the words "black flag", and then they are tags
  # outside a flag, invisible, up to six letters a flag. So they go too.
  if (hidden == "remove") {
    had <- lengths(lst) > 0L
    rewritten[had] <- .emoji_hidden_remove(rewritten[had])
  }
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
#' (the inverse of [emoji_to_text()] with `format = "shortcode"` *and its
#' default* `wrap`, up to the presentation selector -- see Details).
#' Shortcodes that do not match a known emoji are left unchanged.
#'
#' @details
#' A shortcode token is a colon, one or more of `A-Z`, `a-z`, `0-9`, `_`, `+`
#' or `-`, and a closing colon. Restricting the token this way means colons
#' used for other purposes -- clock times, URLs, ratios, ordinary punctuation
#' -- cannot swallow a following shortcode: `"meet at 10:30 :wave:"` still
#' emojizes the wave. A colon pair that is shortcode-shaped but no alias gives
#' its closing colon up to the token after it, so `"10:30:grinning:"`, which
#' [emoji_sanitize()] writes for a clock time with a grinning face straight
#' after it, still emojizes the face.
#'
#' One reading stays ambiguous, because the text cannot settle it: an alias
#' written after a colon, straight before a shortcode. `"status:ok"` followed
#' by a thumbs-up sanitises to `"status:ok:+1:"`, and `:ok:` (`U+1F197`) is
#' read first, leaving `+1:` as text.
#'
#' **The converse is a limitation, not a feature.** This verb cannot tell a
#' token [emoji_sanitize()] or [emoji_to_text()] wrote from one the text always
#' held, so it emojizes both. Text that arrives with literal shortcode tokens in
#' it -- a Slack, Discord or GitHub export -- therefore gains emoji it never
#' contained, silently, and any count taken afterwards is inflated. See
#' [emoji_sanitize()] for the worked cases and the check.
#'
#' **The round trip recovers the emoji, not necessarily the same bytes.** Like
#' the vector helpers, both directions resolve through \code{emoji_key()},
#' which ignores `U+FE0F`, so an unqualified glyph and its fully-qualified form
#' share one shortcode and only one of the two spellings can come back.
#' Feeding the whole emoji catalogue through
#' `emoji_to_text(format = "shortcode")` and back returns an identical
#' code-point key for all 5244 entries and identical bytes for 80% of them.
#' The other 1060 differ **by `U+FE0F` alone, never by more**: they come back
#' as the spelling this verb's shortcode table carries. A second round trip
#' changes nothing, so the result is stable either way -- but compare with
#' \code{emoji_key()}, never with string equality.
#'
#' Which 80% is *not* the same question as which were already fully qualified,
#' and the two sets genuinely differ in both directions. The bare heart
#' (`U+2764`) survives unchanged, because that unqualified spelling is the one
#' `:heart:` maps to; the already-qualified man detective
#' (`U+1F575 U+FE0F U+200D U+2642`) does not, because it comes back with a
#' second selector on the gender sign. If your text holds the *canonical*
#' spelling of each emoji -- what a keyboard emits -- the round trip is
#' byte-exact for all 3972; see [emoji_sanitize()],
#' which tabulates both denominators.
#'
#' @inheritParams emoji_summary
#' @return `data`, as a tibble, with the text column rewritten in place. `NA`
#'   entries stay `NA`.
#' @seealso [emoji_to_text()]; [as_emoji()] for the vector helper, which
#'   resolves a bare string by Unicode name first and so differs from
#'   this verb on 17 strings that name one emoji and alias another.
#' @examples
#' df <- data.frame(text = "hi :grinning: bye :waving_hand:")
#' text_to_emoji(df, text)
#'
#' # colons elsewhere in the text do not interfere
#' text_to_emoji(data.frame(text = "https://example.org at 10:30 :grinning:"),
#'               text)
#' @concept translation
#' @export
text_to_emoji <- function(data, text) {
  v <- .emoji_text_col(data, {{ text }})
  was_na <- is.na(v)
  v[was_na] <- ""
  name_map <- .emoji_name_map()   # named vector: name -> glyph
  # Match only the characters GitHub-style aliases actually use. A permissive
  # ":[^:]+:" lets an unrelated colon pair (a URL, a clock time, "note: ...")
  # consume the opening colon of a real shortcode and silently skip it.
  # A row needs a whole token to hold one, so test for that first.
  cand <- which(grepl(":[A-Za-z0-9_+-]+:", v))
  if (length(cand)) {
    # The closing colon is a lookahead, not part of the match: until 0.7.0 a
    # colon pair that was no alias (the ":30:" of "10:30:grinning:", which
    # emoji_sanitize() writes for a clock time followed by an emoji) consumed
    # both colons, and the shortcode after it lost its opening one.
    m <- gregexpr(":[A-Za-z0-9_+-]+(?=:)", v[cand], perl = TRUE)
    v[cand] <- vapply(seq_along(cand), function(j) {
      .emoji_emojize(v[cand][[j]], m[[j]], name_map)
    }, character(1))
  }
  v[was_na] <- NA_character_
  out <- .emoji_as_tibble(data)
  col_name <- .emoji_col_name(data, {{ text }})
  out[[col_name]] <- v
  .emoji_regroup(out, col_name)
}

# Replace the alias tokens of one string. `mm` is its gregexpr() match of an
# opening colon and alias characters, the closing colon left to a lookahead,
# so consecutive matches can share a colon. Walked left to right: a match
# that is a known alias is replaced together with its closing colon, which
# the match after it then cannot reuse; one that is not leaves both colons in
# the text and its closing colon free to open the next token. Where every
# pair is an alias this is exactly the old non-overlapping scan.
.emoji_emojize <- function(s, mm, name_map) {
  st <- as.integer(mm)
  if (st[[1L]] < 0L) return(s)
  len <- attr(mm, "match.length")
  g <- unname(name_map[substring(s, st + 1L, st + len - 1L)])
  take <- logical(length(st))
  free <- 1L
  for (i in seq_along(st)) {
    if (st[[i]] < free || is.na(g[[i]])) next
    take[[i]] <- TRUE
    free <- st[[i]] + len[[i]] + 1L
  }
  if (!any(take)) return(s)
  locs <- cbind(start = st[take], end = st[take] + len[take])
  .emoji_replace_in_order(s, locs, substring(s, locs[, "start"],
                                             locs[, "end"]), g[take])
}


#' Vector helpers: convert emoji to/from names and shortcodes
#'
#' Small vector-level helpers for ad-hoc use. They do not take a data frame.
#'
#' * `as_emoji_name(x)` maps emoji glyphs to their Unicode names.
#' * `as_emoji_shortcode(x)` maps emoji glyphs to a shortcode.
#' * `as_emoji(x)` maps names/shortcodes to the emoji glyph (emojize).
#'
#' All three resolve through \code{emoji_key()}, so qualified emoji (carrying
#' `U+FE0F`) and unqualified forms resolve identically. Unmatched inputs return
#' `NA`.
#'
#' @section Which shortcode you get:
#' `as_emoji_shortcode()` returns one shortcode *per emoji*, not per spelling:
#' the first alias of the emoji's fully-qualified (RGI) form. That is what
#' makes it agree with [emoji_to_text()] and survive a round trip, but it is
#' not always the first alias of the glyph you passed in. 344 codepoint keys
#' have a different first alias on each of their two spellings, so for 175 of
#' the catalogue's 5244 rows the two answers differ:
#' `as_emoji_shortcode("\u2764")` is `"heart"`, the qualified heart's alias,
#' where the bare `U+2764` row's own first alias is `"red_heart"`.
#'
#' [emoji_search()] reports the other one -- the matched row's own alias, since
#' a search result is a row -- so the two verbs can disagree on the same glyph.
#' Both resolve back to the same emoji through [text_to_emoji()], which reads
#' every alias, so where both answer the disagreement is cosmetic. Where they
#' differ in substance is the 189 rows that have no alias of their own, all of
#' them spellings with a selector left out: [emoji_search()] reports `NA` for
#' those, while `as_emoji_shortcode()` still answers for all 189, having
#' borrowed the alias of the glyph's other spelling. The 202 spellings added
#' in Emoji 17.0 and 18.0, which the \pkg{emoji} package's aliases stop short
#' of, have emojibase's CLDR-style shortcodes since 0.7.0, so both answer for
#' them too.
#'
#' @details
#' `as_emoji()` accepts either namespace in the same argument, and 471 strings
#' belong to both -- they are the exact Unicode name of one emoji and a
#' shortcode alias of another. It resolves them in a fixed order: **exact
#' Unicode name first**, then shortcode, then \pkg{emoji}'s own name table. An
#' exact name match is the stronger signal, so `as_emoji("dog")` is the emoji
#' actually *named* "dog" (a dog, `U+1F415`), not the one whose alias is
#' `:dog:` (a dog face, `U+1F436`).
#'
#' For 17 of those 471 strings the two namespaces disagree, and there
#' `as_emoji()` and [text_to_emoji()] differ *by design*: a `:dog:` token is
#' explicitly delimited as a shortcode, so [text_to_emoji()] reads it in the
#' shortcode namespace and produces the dog face. The pattern is an emoji whose
#' name is a bare noun versus the "... face" variant that carries the alias
#' (`cat`, `cow`, `pig`, `tiger`, `mouse`, `rabbit`), or a plain object versus a
#' decorated one (`umbrella`, `snowman`, `calendar`, `sunglasses`). Pass a
#' shortcode through [text_to_emoji()], or the full Unicode name (`"dog face"`)
#' to `as_emoji()`, if you need one namespace specifically.
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
#' @concept translation
#' @concept accessibility
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
  miss <- is.na(out); out[miss] <- unname(.emoji_name_map()[x[miss]])
  out
}

