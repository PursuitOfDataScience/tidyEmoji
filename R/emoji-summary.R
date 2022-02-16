#' Emoji summary tibble
#'
#' When having a Twitter dataframe/tibble at hand, it should be nice to know
#' how many Tweets contain Emojis. This is the right time to use this function.
#' What is worth noting is that it does not matter whether a Tweet has one Emoji
#' or ten Emojis, the function only counts it once and returns a tibble that
#' summarizes the number of Tweets containing at least one Emoji and the total
#' number of Tweets presented in the dataframe/tibble.
#'
#' @param tweet_tbl A dataframe/tibble containing tweets/text.
#' @param tweet_text The tweet/text column.
#'
#' @return A summary tibble including # of Tweets in total and # of Tweets that
#' have at least one Emoji.
#'
#' @import dplyr
#' @import emoji
#' @import stringr
#' @import tibble
#' @export
#' @examples
#' library(dplyr)
#' data.frame(tweets = c("I love tidyverse \U0001f600\U0001f603\U0001f603",
#'                       "R is my language! \U0001f601\U0001f606\U0001f605",
#'                       "This Tweet does not have Emoji!",
#'                       "Wearing a mask\U0001f637\U0001f637\U0001f637.",
#'                       "Emoji does not appear in all Tweets",
#'                       "A flag \U0001f600\U0001f3c1")) %>%
#'          emoji_summary(tweets)
#'



emoji_summary <- function(tweet_tbl, tweet_text){

  num_tweets <- dim(tweet_tbl)[1]

  num_emoji_tweets <- tweet_tbl %>%
    dplyr::filter(stringr::str_detect({{ tweet_text }},
                                      emoji::emojis %>%
                                        dplyr::filter(!stringr::str_detect(name, "keycap: \\*")) %>%
                                        dplyr::pull(emoji) %>%
                                        paste(., collapse = "|"))) %>%
    dim() %>%
    .[1]

  return(tibble::tibble(emoji_tweets = num_emoji_tweets,
                        total_tweets = num_tweets))

}





#' Emoji Text/Tweets Output
#'
#' When users just want to focus on Tweets containing Emoji(s),
#' \code{emoji_tweets} filters out non-Emoji rows and only returns rows that
#' have at least one Emoji.
#'
#' @inheritParams emoji_summary
#'
#' @return A dataframe/tibble containing only text with at least one Emoji
#' @export
#' @examples
#' library(dplyr)
#' data.frame(tweets = c("I love tidyverse \U0001f600\U0001f603\U0001f603",
#'                       "R is my language! \U0001f601\U0001f606\U0001f605",
#'                       "This Tweet does not have Emoji!",
#'                       "Wearing a mask\U0001f637\U0001f637\U0001f637.",
#'                       "Emoji does not appear in all Tweets",
#'                       "A flag \U0001f600\U0001f3c1")) %>%
#'          emoji_tweets(tweets)
#'


emoji_tweets <- function(tweet_tbl, tweet_text){

  tweet_tbl %>%
    dplyr::filter(stringr::str_detect({{ tweet_text }},
                                      emoji::emojis %>%
                                        dplyr::filter(!stringr::str_detect(name, "keycap: \\*")) %>%
                                        dplyr::pull(emoji) %>%
                                        paste(., collapse = "|")))

}
