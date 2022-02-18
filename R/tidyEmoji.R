#' \code{tidyEmoji} package
#'
#' A tidy way working with text containing Emoji.
#'
#' @docType package
#' @name tidyEmoji
#' @import utils
NULL


if(getRversion() >= "2.15.1")  utils::globalVariables(c(".",
                                                        "name",
                                                        "emoji_name",
                                                        "unicode",
                                                        "emoji_category",
                                                        "emoji_unicode_crosswalk",
                                                        "category_unicode_crosswalk",
                                                        ".emoji_category",
                                                        ".emoji_unicode",
                                                        ".emoji_unicode"))
