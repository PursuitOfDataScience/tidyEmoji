#' Score the sentiment of the emoji in each row
#'
#' `emoji_sentiment()` adds the mean emoji sentiment of each row, based on the
#' Emoji Sentiment Ranking lexicon (see [emoji_sentiment_lexicon]). Scores range
#' from -1 (negative) through 0 (neutral) to +1 (positive). Rows that contain no
#' emoji, or whose emoji are absent from the lexicon, receive `NA`.
#'
#' @inheritParams emoji_summary
#' @return `data`, as a tibble, with added columns `.emoji_n` (the number of
#'   emoji in the row) and `.emoji_sentiment` (the mean sentiment of the emoji
#'   that appear in the lexicon).
#' @references Kralj Novak P, Smailovic J, Sluban B, Mozetic I (2015) Sentiment
#'   of Emojis. PLoS ONE 10(12): e0144296. \doi{10.1371/journal.pone.0144296}
#' @seealso [emoji_sentiment_lexicon] for the underlying scores.
#' @examples
#' df <- data.frame(text = c("love it \U0001f60d", "awful \U0001f621", "meh"))
#' emoji_sentiment(df, text)
#' @export
emoji_sentiment <- function(data, text) {
  lst <- emoji_glyph_list(dplyr::pull(data, {{ text }}))
  score <- emoji_sentiment_map()

  means <- vapply(lst, function(g) {
    if (!length(g)) return(NA_real_)
    s <- score[emoji_key(g)]
    if (all(is.na(s))) NA_real_ else mean(s, na.rm = TRUE)
  }, numeric(1))

  out <- tibble::as_tibble(data)
  out$.emoji_n <- as.integer(lengths(lst))
  out$.emoji_sentiment <- means
  out
}
