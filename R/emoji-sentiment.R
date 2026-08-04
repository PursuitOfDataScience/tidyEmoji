#' Score the sentiment of the emoji in each row
#'
#' `emoji_sentiment()` adds the mean emoji sentiment of each row, based on the
#' Emoji Sentiment Ranking lexicon (see [emoji_sentiment_lexicon]). Scores range
#' from -1 (negative) through 0 (neutral) to +1 (positive). Rows that contain no
#' emoji, or whose emoji are absent from the lexicon, receive `NA`.
#'
#' @details
#' Detection is grapheme-aware. Some lexicon entries are stored as unqualified,
#' text-presentation code points (notably the bare heart, \code{U+2764},
#' without the \code{U+FE0F} variation selector); those are not treated as
#' emoji in your text, so they are neither counted nor scored. Supply the
#' emoji-presentation (qualified) form and it resolves normally. See
#' [emoji_sentiment_lexicon] for the full picture.
#'
#' @inheritParams emoji_summary
#' @section Uncertainty:
#' A glyph annotated eight times should not carry the same authority as one
#' annotated eight thousand times, and the bundled lexicon keeps the annotation
#' counts that say which is which. With `se = TRUE` the result gains
#' `.emoji_sentiment_se`, the standard error of the row's mean: each glyph's
#' score has a binomial-style standard error computed from its own counts, and
#' those are propagated to the mean assuming independent annotations
#' (`sqrt(sum(se^2)) / n_scored`). It needs the annotation counts, so it is
#' available for the bundled `"novak2015"` lexicon only. See
#' [emoji_ambiguity()] for the same counts read as disagreement.
#'
#' @param lexicon Lexicon to use. The default, `"novak2015"`, uses the bundled
#'   [emoji_sentiment_lexicon]. A registered lexicon (see
#'   [register_emoji_lexicon()]) or a data frame can also be supplied; see
#'   [emoji_score()] for the generic scorer.
#' @param se If `TRUE`, also return `.emoji_sentiment_se`, the standard error of
#'   the row's mean sentiment. Requires the bundled `"novak2015"` lexicon.
#'   Default `FALSE`.
#' @return \code{data}, as a tibble, with added columns \code{.emoji_n} (the number of
#'   emoji in the row), \code{.emoji_n_scored} (the number of emoji that actually
#'   appear in the lexicon), and \code{.emoji_sentiment} (the mean sentiment of the
#'   scored emoji). With \code{se = TRUE}, also \code{.emoji_sentiment_se}.
#' @references Kralj Novak P, Smailovic J, Sluban B, Mozetic I (2015) Sentiment
#'   of Emojis. PLoS ONE 10(12): e0144296. \doi{10.1371/journal.pone.0144296}
#' @seealso [emoji_sentiment_lexicon] for the underlying scores;
#'   [emoji_score()] for scoring against any lexicon; [emoji_emotion()] for
#'   discrete emotions; [emoji_ambiguity()] for annotator disagreement.
#' @examples
#' df <- data.frame(text = c("love it \U0001f60d", "awful \U0001f621", "meh"))
#' emoji_sentiment(df, text)
#' emoji_sentiment(df, text, se = TRUE)
#' @export
emoji_sentiment <- function(data, text, lexicon = "novak2015", se = FALSE) {
  if (!is.logical(se) || length(se) != 1L || is.na(se)) {
    stop("`se` must be TRUE or FALSE.", call. = FALSE)
  }
  is_novak <- missing(lexicon) ||
    (is.character(lexicon) && length(lexicon) == 1L && !is.na(lexicon) &&
       lexicon %in% c("novak2015", "emoji_sentiment_lexicon", "sentiment"))
  if (se && !is_novak) {
    stop("`se = TRUE` needs the annotation counts behind a score, which only ",
         "the bundled \"novak2015\" lexicon carries.", call. = FALSE)
  }
  if (is_novak) {
    score <- emoji_sentiment_map()
  } else {
    lex <- .emoji_lexicon_lookup(lexicon)
    if (identical(lex$type, "sentiment")) {
      score <- emoji_sentiment_map()
    } else if (is.data.frame(lex)) {
      score <- .emoji_lexicon_record(lex)
    } else if (identical(lex$type, "custom")) {
      score <- .emoji_lexicon_record(lex$tbl)
    } else {
      stop("`lexicon` must be 'novak2015', a registered lexicon, or a data frame.",
           call. = FALSE)
    }
  }

  lst <- emoji_glyph_list(dplyr::pull(data, {{ text }}))

  all_glyphs <- unique(unlist(lst, use.names = FALSE))
  key_lookup <- stats::setNames(emoji_key(all_glyphs), all_glyphs)

  means <- vapply(lst, function(g) {
    if (!length(g)) return(NA_real_)
    s <- score[key_lookup[g]]
    if (all(is.na(s))) NA_real_ else mean(s, na.rm = TRUE)
  }, numeric(1))

  n_scored <- vapply(lst, function(g) {
    if (!length(g)) return(NA_integer_)
    s <- score[key_lookup[g]]
    sum(!is.na(s))
  }, integer(1))

  out <- tibble::as_tibble(data)
  out$.emoji_n <- as.integer(lengths(lst))
  out$.emoji_n_scored <- n_scored
  out$.emoji_sentiment <- means
  if (se) {
    se_map <- emoji_sentiment_se_map()
    out$.emoji_sentiment_se <- vapply(lst, function(g) {
      if (!length(g)) return(NA_real_)
      s <- se_map[key_lookup[g]]
      s <- s[!is.na(s)]
      if (!length(s)) return(NA_real_)
      sqrt(sum(s^2)) / length(s)
    }, numeric(1))
  }
  out
}
