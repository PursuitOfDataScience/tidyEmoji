emoji_category_add <- function(emoji_unicodes, emoji_category, tweet_tbl, tweet_text){

  tweet_tbl %>%
    dplyr::filter(str_detect({{ tweet_text }}, emoji_unicodes)) %>%
    dplyr::mutate(.emoji_category = emoji_category)

}



#' Categorize Emoji Tweets/text based on Emoji category
#'
#' Users can use \code{emoji_categorize} to see the all the categories each
#' Emoji Tweet has. The function preserves the input data structure, and the
#' only change is it adds an extra column with information about Emoji
#' category separated by \code{|} if there is more than one category.
#'
#' @inheritParams emoji_summary
#' @import purrr
#' @import tidyr
#' @import dplyr
#' @return A filtered dataframe with the presence of Emoji only, and with an
#' extra column \code{.emoji_category}.
#' @export
#' @examples
#' library(dplyr)
#' data.frame(tweets = c("I love tidyverse \U0001f600\U0001f603\U0001f603",
#'                       "R is my language! \U0001f601\U0001f606\U0001f605",
#'                       "This Tweet does not have Emoji!",
#'                       "Wearing a mask\U0001f637\U0001f637\U0001f637.",
#'                       "Emoji does not appear in all Tweets",
#'                       "A flag \U0001f600\U0001f3c1")) %>%
#'          emoji_categorize(tweets)


emoji_categorize <- function(tweet_tbl, tweet_text) {

  emoji_long <- purrr::map2_dfr(tidyEmoji::category_unicode_crosswalk$unicodes,
                  tidyEmoji::category_unicode_crosswalk$category,
                  emoji_category_add,
                  tweet_tbl,
                  {{ tweet_text }})

  emoji_category_vector <- unique(emoji_long$.emoji_category)

  emoji_long %>%
    tidyr::pivot_wider(names_from = .emoji_category,
                       values_from = .emoji_category) %>%
    tidyr::unite(".emoji_category", emoji_category_vector, sep = "|", na.rm = T)


}



