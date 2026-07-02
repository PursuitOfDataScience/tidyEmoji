#' Search emoji by keyword, name or shortcode
#'
#' `emoji_search()` finds emoji whose Unicode keywords, name or shortcodes
#' match a query (case-insensitive, substring match). It returns a tidy tibble
#' of matches with the glyph, name, shortcode, category and the matching
#' keywords, ready for further inspection or piping into other verbs.
#'
#' @param query A search string, matched as a case-insensitive substring
#'   against keywords, name and shortcodes.
#' @return A tibble with columns `emoji`, `name`, `shortcode`, `group` and
#'   `keyword` (the keywords of the emoji that contained the match, collapsed
#'   with `, `).
#' @examples
#' emoji_search("happy")
#' emoji_search("heart")
#' @export
emoji_search <- function(query) {
  if (!is.character(query) || length(query) != 1L || !nzchar(query)) {
    stop("`query` must be a single non-empty string.", call. = FALSE)
  }
  e <- emoji::emojis
  pat <- tolower(query)

  # Fixed (non-regex) substring matching on lower-cased text, so queries
  # containing regex metacharacters (e.g. the "+1" alias) are safe.
  kw_hit <- vapply(e$keywords,
                   function(k) any(grepl(pat, tolower(k), fixed = TRUE)),
                   logical(1))
  nm_hit <- grepl(pat, tolower(e$name), fixed = TRUE)
  al_hit <- vapply(e$aliases,
                   function(a) any(grepl(pat, tolower(a), fixed = TRUE)),
                   logical(1))
  hit <- kw_hit | nm_hit | al_hit

  if (!any(hit)) {
    return(tibble::tibble(emoji = character(), name = character(),
                          shortcode = character(), group = character(),
                          keyword = character()))
  }

  matched_kw <- vapply(which(hit), function(i) {
    k <- unlist(e$keywords[[i]])
    k <- k[grepl(pat, tolower(k), fixed = TRUE)]
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
