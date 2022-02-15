#' Emoji Summary Tibble
#'
#' @param tweet_tbl A dataframe/tibble containing tweets.
#' @param tweet_text The column that is the tweet column.
#'
#' @return A summary tibble including # of tweets in total and # of tweets that
#' have at least one Emoji.
#'
#' @import dplyr
#' @import emoji
#' @import stringr
#' @import tibble
#' @import rlang
#' @export
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
