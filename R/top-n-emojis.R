#' Getting n most popular Emojis
#'
#' When working with Tweets, counting how many times each Emoji appears in the
#' entire Tweet corpus is useful. This is when \code{top_n_emojis} comes into
#' play, and it is handy to see how Emojis are distributed across the corpus.
#' If a Tweet has 10 Emojis, \code{top_n_emojis} will count it 10 times and
#' assign each of the 10 Emojis on its respective Emoji category. What is
#' interesting to note is Unicodes returned by \code{top_n_emojis} could have
#' duplicates, meaning some Unicodes share various Emoji names. By default, this
#' does not happen, but users can choose \code{duplicated_unicode = 'yes'} to
#' obtain duplicated Unicodes.
#'
#' @inheritParams emoji_summary
#' @param n Top \code{n} Emojis, default is 20.
#' @param duplicated_unicode If no repetitious Unicode, \code{no}. Otherwise,
#' \code{yes}. Default is \code{no}.
#' @return A tibble with top \code{n} Emojis
#' @import tibble
#' @import purrr
#' @import dplyr
#' @export
#' @examples
#' library(dplyr)
#' data.frame(tweets = c("I love tidyverse \U0001f600\U0001f603\U0001f603",
#'                       "R is my language! \U0001f601\U0001f606\U0001f605",
#'                       "This Tweet does not have Emoji!",
#'                       "Wearing a mask\U0001f637\U0001f637\U0001f637.",
#'                       "Emoji does not appear in all Tweets",
#'                       "A flag \U0001f600\U0001f3c1")) %>%
#'          top_n_emojis(tweets, n = 2)


top_n_emojis <- function(tweet_tbl, tweet_text, n = 20, duplicated_unicode = "no"){

  emoji_tbl <- tidyEmoji::emoji_tweets(tweet_tbl, {{ tweet_text }})

  emoji_count_list <- purrr::map(tidyEmoji::emoji_unicode_crosswalk$unicode,
                                 .f = count_each_emoji,
                                 emoji_tbl,
                                 {{ tweet_text }})

  tbl <- tibble::tibble(unicode = tidyEmoji::emoji_unicode_crosswalk$unicode,
                        emoji_count = unlist(emoji_count_list)) %>%
    dplyr::inner_join(tidyEmoji::emoji_unicode_crosswalk, by = "unicode") %>%
    dplyr::distinct() %>%
    dplyr::count(emoji_name, unicode, emoji_category, wt = emoji_count, sort = T)

  if(duplicated_unicode == "no"){
    tbl %>%
      distinct(unicode, .keep_all = T) %>%
      head(n)
  }
  else if(duplicated_unicode == "yes"){
    tbl %>%
      head(n)
  }


}


count_each_emoji <- function(unicode, df, tweet_text){
  return(df %>%
           dplyr::pull({{ tweet_text }}) %>%
           stringr::str_count(., unicode) %>%
           sum())
}
