#' Search emoji by keyword, name or shortcode
#'
#' `emoji_search()` finds emoji whose Unicode keywords, name or shortcodes
#' match a query (case-insensitive, substring match). It returns a tidy tibble
#' of matches with the glyph, name, shortcode, category and the matching
#' keywords, ready for further inspection or piping into other verbs.
#'
#' @param query A search string, matched as a case-insensitive substring
#'   against keywords, name and shortcodes.
#' @details
#' `shortcode` is the *matched row's* first alias, and it is `NA` when the
#' matched spelling has none: 189 of the catalogue's 5244 rows carry no alias
#' of their own, all of them spellings with a selector left out, so a search
#' that hits one (7 of the 235 rows `emoji_search("face")` returns, for
#' instance) has nothing to put in that column. The Emoji 17.0 and 18.0
#' additions, which the \pkg{emoji} package's aliases and keywords stop short
#' of, have emojibase's shortcodes and CLDR's keywords since 0.7.0, so they
#' are found like any other emoji. Use the `emoji` column for the 189, or
#' [as_emoji_shortcode()], which
#' is keyed on the emoji rather than on the row and so can borrow the alias of
#' the glyph's other spelling. For the same reason the two can disagree even
#' when both answer -- see [as_emoji_shortcode()].
#'
#' Every non-`NA` `shortcode` is a token [text_to_emoji()] reads, and it
#' recovers the matched row's emoji exactly. [as_emoji()] resolves a bare
#' string by
#' Unicode name first, so for the 17 strings that name one emoji and alias
#' another it returns the emoji of that *name* rather than the row you
#' searched. They are `calendar`, `camel`, `cat`, `cow`, `dog`, `horse`,
#' `kiss`, `mouse`, `pig`, `rabbit`, `satellite`, `snowman`, `sunglasses`,
#' `tiger`, `train`, `umbrella` and `whale`; that is the complete set, not a
#' sample of it. See [as_emoji()] for why.
#'
#' @return A tibble with columns `emoji`, `name`, `shortcode`, `group` and
#'   `keyword` (the keywords of the emoji that contained the match, collapsed
#'   with `, `). `keyword` is the empty string, not `NA`, when the query matched
#'   the name or a shortcode rather than a keyword. `shortcode` *is* `NA` when
#'   the matched spelling has no alias; see Details.
#' @seealso [text_to_emoji()] to turn `shortcode` back into a glyph;
#'   [as_emoji_name()] for the name of a glyph.
#' @examples
#' emoji_search("happy")
#' emoji_search("heart")
#' @concept vocabulary
#' @concept stimulus design
#' @export
emoji_search <- function(query) {
  # is.na() has to come before nzchar(): nzchar() defaults to keepNA = FALSE,
  # which reads NA_character_ as the two-character string "NA", so the guard
  # passed and the NA propagated to `if (!any(hit))` -- reported as R's own
  # "missing value where TRUE/FALSE needed" from inside the verb, with no hint
  # that the argument was the problem.
  if (!is.character(query) || length(query) != 1L || is.na(query) ||
      !nzchar(query)) {
    stop("`query` must be a single non-empty string.", call. = FALSE)
  }
  # .emoji_fold() below calls tolower(), which stops on a "bytes" string with
  # "translating strings with \"bytes\" encoding is not allowed" -- R's
  # message, naming neither this function nor this argument
  if (Encoding(query) == "bytes") {
    stop("`query` carries \"bytes\" encoding, which R will not read as ",
         "characters. Convert it with iconv() from whatever encoding those ",
         "bytes really are.", call. = FALSE)
  }
  # The catalogue for the rows, names and groups, and {emoji} for the
  # keywords and shortcodes, aligned by spelling: the same split every other
  # verb uses, so a name found here is the name they report. An emoji newer
  # than {emoji} is found by its name alone.
  ix <- .emoji_search_index()
  pat <- .emoji_fold(query)

  # Fixed (non-regex) substring matching on folded text, so queries containing
  # regex metacharacters (e.g. the "+1" alias) are safe. .emoji_fold() rather
  # than tolower(): the latter honours LC_CTYPE, which under a Turkish locale
  # folds "I" to a dotless i and made any query containing it miss.
  kw_match <- grepl(pat, ix$kw_fold, fixed = TRUE)
  hit <- grepl(pat, ix$nm_fold, fixed = TRUE)
  hit[ix$kw_row[kw_match]] <- TRUE
  hit[ix$al_row[grepl(pat, ix$al_fold, fixed = TRUE)]] <- TRUE

  if (!any(hit)) {
    return(tibble::tibble(emoji = character(), name = character(),
                          shortcode = character(), group = character(),
                          keyword = character()))
  }

  # each hit row's matching keywords, in the row's own order, de-duplicated
  rows <- which(hit)
  per_row <- split(ix$kw[kw_match],
                   factor(ix$kw_row[kw_match], levels = rows))
  matched_kw <- vapply(per_row, function(k) {
    if (!length(k)) "" else paste(unique(k), collapse = ", ")
  }, character(1), USE.NAMES = FALSE)

  tibble::tibble(
    emoji     = ix$emoji[hit],
    name      = ix$name[hit],
    shortcode = ix$shortcode[hit],
    group     = ix$group[hit],
    keyword   = matched_kw
  )
}

# What emoji_search() matches against, folded once per session rather than
# once per call: every keyword and alias flattened into one vector beside the
# row it belongs to, and every name. Folding the 5244 rows' vocabularies one
# list element at a time cost a quarter of a second on every call; the
# matching itself is three vectorised grepl()s. Derived from the reference, so
# it is one of .emoji_derived_cache_slots().
.emoji_search_index <- function() {
  if (is.null(.tidyEmoji_cache$search)) {
    ref <- emoji_reference()
    kw <- .emoji_vocabulary(ref$emoji, "keywords", ref$key)
    al <- .emoji_vocabulary(ref$emoji, "aliases", ref$key)
    kw_flat <- unlist(kw, use.names = FALSE)
    al_flat <- unlist(al, use.names = FALSE)
    .tidyEmoji_cache$search <- list(
      emoji = ref$emoji,
      name = ref$name,
      group = ref$group,
      shortcode = vapply(al, function(a) {
        if (length(a)) a[[1L]] else NA_character_
      }, character(1), USE.NAMES = FALSE),
      kw = as.character(kw_flat),
      kw_fold = .emoji_fold(as.character(kw_flat)),
      kw_row = rep.int(seq_along(kw), lengths(kw)),
      al_fold = .emoji_fold(as.character(al_flat)),
      al_row = rep.int(seq_along(al), lengths(al)),
      nm_fold = .emoji_fold(ref$name)
    )
  }
  .tidyEmoji_cache$search
}
