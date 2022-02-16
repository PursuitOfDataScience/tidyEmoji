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
#'


emoji_categorize <- function(tweet_tbl, tweet_text) {

  purrr::map2_dfr(tidyEmoji::category_unicode_crosswalk$unicodes,
           tidyEmoji::category_unicode_crosswalk$category,
           emoji_category_add,
           tweet_tbl,
           {{ tweet_text }}) %>%
    tidyr::pivot_wider(names_from = .emoji_category,
                       values_from = .emoji_category) %>%
    tidyr::unite(".emoji_category", c("Smileys & Emotion": "Flags"), sep = "|", na.rm = T)


}



