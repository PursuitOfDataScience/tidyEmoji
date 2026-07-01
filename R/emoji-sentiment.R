#' Score the sentiment of the emoji in each row
#'
#' `emoji_sentiment()` adds the mean emoji sentiment of each row, based on the
#' Emoji Sentiment Ranking lexicon (see [emoji_sentiment_lexicon]). Scores range
#' from -1 (negative) through 0 (neutral) to +1 (positive). Rows that contain no
#' emoji, or whose emoji are absent from the lexicon, receive `NA`.
#'
#' @inheritParams emoji_summary
#' @param lexicon Lexicon to use. The default, `"novak2015"`, uses the bundled
#'   [emoji_sentiment_lexicon]. A registered lexicon (see
#'   [register_emoji_lexicon()]) or a data frame can also be supplied; see
#'   [emoji_score()] for the generic scorer.
#' @return \code{data}, as a tibble, with added columns \code{.emoji_n} (the number of
#'   emoji in the row), \code{.emoji_n_scored} (the number of emoji that actually
#'   appear in the lexicon), and \code{.emoji_sentiment} (the mean sentiment of the
#'   scored emoji).
#' @references Kralj Novak P, Smailovic J, Sluban B, Mozetic I (2015) Sentiment
#'   of Emojis. PLoS ONE 10(12): e0144296. \doi{10.1371/journal.pone.0144296}
#' @seealso [emoji_sentiment_lexicon] for the underlying scores;
#'   [emoji_score()] for scoring against any lexicon; [emoji_emotion()] for
#'   discrete emotions.
#' @examples
#' df <- data.frame(text = c("love it \U0001f60d", "awful \U0001f621", "meh"))
#' emoji_sentiment(df, text)
#' @export
emoji_sentiment <- function(data, text, lexicon = "novak2015") {
  if (missing(lexicon) || identical(lexicon, "novak2015")) {
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
  out
}
