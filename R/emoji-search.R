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
#' matched spelling has none: 189 of the catalogue's 5042 rows carry no
#' GitHub-style alias at all, so a search that hits one (7 of the 198 rows
#' `emoji_search("face")` returns, for instance) has nothing to put in that
#' column. Use the `emoji` column for those, or [as_emoji_shortcode()], which
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
  e <- emoji::emojis
  pat <- .emoji_fold(query)

  # Fixed (non-regex) substring matching on folded text, so queries containing
  # regex metacharacters (e.g. the "+1" alias) are safe. .emoji_fold() rather
  # than tolower(): the latter honours LC_CTYPE, which under a Turkish locale
  # folds "I" to a dotless i and made any query containing it miss.
  kw_hit <- vapply(e$keywords,
                   function(k) any(grepl(pat, .emoji_fold(k), fixed = TRUE)),
                   logical(1))
  nm_hit <- grepl(pat, .emoji_fold(e$name), fixed = TRUE)
  al_hit <- vapply(e$aliases,
                   function(a) any(grepl(pat, .emoji_fold(a), fixed = TRUE)),
                   logical(1))
  hit <- kw_hit | nm_hit | al_hit

  if (!any(hit)) {
    return(tibble::tibble(emoji = character(), name = character(),
                          shortcode = character(), group = character(),
                          keyword = character()))
  }

  matched_kw <- vapply(which(hit), function(i) {
    k <- unlist(e$keywords[[i]])
    k <- k[grepl(pat, .emoji_fold(k), fixed = TRUE)]
    if (!length(k)) "" else paste(unique(k), collapse = ", ")
  }, character(1))

  shortcode <- vapply(e$aliases[hit], function(a) {
    if (length(a)) a[[1L]] else NA_character_
  }, character(1))

  tibble::tibble(
    emoji     = e$emoji[hit],
    name      = e$name[hit],
    shortcode = shortcode,
    group     = e$group[hit],
    keyword   = matched_kw
  )
}
