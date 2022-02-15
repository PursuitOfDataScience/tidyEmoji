#' \code{tidyEmoji} package
#'
#' A tidy way working with text containing Emoji
#'
#' @docType package
#' @name tidyEmoji
#' @importFrom dplyr %>%
#' @importFrom purrr %||%
NULL

## quiets concerns of R CMD check re: the .'s that appear in pipelines
if(getRversion() >= "2.15.1")  utils::globalVariables(c(".", "name"))
