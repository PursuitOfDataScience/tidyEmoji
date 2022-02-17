#' Emoji extraction unnested summary
#'
#' If users would like to know how many Emojis and what kinds of Emojis each
#' Tweet has, \code{emoji_extract} is a useful function to output a global
#' summary with the row number of each Tweet containing Emoji and the Unicodes
#' associated with each Tweet.
#'
#' @inheritParams emoji_summary
#'
#' @import dplyr
#' @import stringr
#' @import tidyr
#' @return A summary tibble with the original row number and Emoji count.
#' @export
#' @examples
#' library(dplyr)
#' data.frame(tweets = c("I love tidyverse \U0001f600\U0001f603\U0001f603",
#'                       "R is my language! \U0001f601\U0001f606\U0001f605",
#'                       "This Tweet does not have Emoji!",
#'                       "Wearing a mask\U0001f637\U0001f637\U0001f637.",
#'                       "Emoji does not appear in all Tweets",
#'                       "A flag \U0001f600\U0001f3c1")) %>%
#'          emoji_extract_unnest(tweets)
#'


emoji_extract_unnest <- function(tweet_tbl, tweet_text){
  tweet_tbl %>%
    tidyEmoji::emoji_extract_nest({{ tweet_text }}) %>%
    dplyr::select({{ tweet_text }}, .emoji_unicode) %>%
    dplyr::mutate(row_number = dplyr::row_number()) %>%
    tidyr::unnest(.emoji_unicode) %>%
    dplyr::group_by(row_number, .emoji_unicode) %>%
    dplyr::summarize(.emoji_count = dplyr::n()) %>%
    dplyr::ungroup()

}







#' Emoji extraction nested summary
#'
#' This function adds an extra list column called \code{.emoji_unicode} to the
#' original data, with all Emojis included.
#'
#' @inheritParams emoji_summary
#'
#' @import dplyr
#' @import stringr
#' @import emoji
#' @return The original dataframe/tibble with an extra column collumn called
#' \code{.emoji_unicode}.
#' @export
#' @examples
#' library(dplyr)
#' data.frame(tweets = c("I love tidyverse \U0001f600\U0001f603\U0001f603",
#'                       "R is my language! \U0001f601\U0001f606\U0001f605",
#'                       "This Tweet does not have Emoji!",
#'                       "Wearing a mask\U0001f637\U0001f637\U0001f637.",
#'                       "Emoji does not appear in all Tweets",
#'                       "A flag \U0001f600\U0001f3c1")) %>%
#'          emoji_extract_nest(tweets)



emoji_extract_nest <- function(tweet_tbl, tweet_text){
  tweet_tbl %>%
    dplyr::mutate(.emoji_unicode = stringr::str_extract_all({{ tweet_text }}, emoji::emojis %>%
                                                             dplyr::filter(!str_detect(name, "keycap: \\*")) %>%
                                                             dplyr::pull(emoji) %>%
                                                             paste(., collapse = "|")))

}
