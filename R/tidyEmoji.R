#' \code{tidyEmoji} package
#'
#' A tidy way working with text containing Emoji
#'
#' @docType package
#' @name tidyEmoji
#' @import utils
NULL

## quiets concerns of R CMD check re: the .'s that appear in pipelines
if(getRversion() >= "2.15.1")  utils::globalVariables(c(".",
                                                        "name",
                                                        "emoji_name",
                                                        "unicode",
                                                        "emoji_category",
                                                        "emoji_unicode_crosswalk"))
