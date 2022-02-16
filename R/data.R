#' Emoji name, Unicode, and Emoji category crosswalk
#'
#' A data set containing each Emoji name (such as grinning, smile), its
#' respective Unicode and category. One thing to note here is there are
#' duplicated Unicodes in the data set, because one Unicode could have multiple
#' Emoji names.
#'
#' @format A data frame with 4536 rows and 3 columns:
#' \describe{
#'   \item{emoji_name}{The name of Emoji per se.}
#'   \item{unicode}{The Unicode of Emoji.}
#'   \item{emoji_category}{The category Emoji falls into.}
#' }
#' @source The raw data sets (\code{emoji_name} and \code{emojis}) come from the
#' \code{emoji} package, and they are processed by the author for the specific
#' needs of \code{tidyEmoji}.
"emoji_unicode_crosswalk"



#' Emoji category, Unicode crosswalk
#'
#' A data set containing each Emoji category (such as Activities), its
#' respective Unicodes string separated by \code{|}.
#'
#' @format A data frame with 10 rows and 2 columns:
#' \describe{
#'   \item{category}{Emoji category (10 categories only)}
#'   \item{unicodes}{The Unicodes string of Emojis belonging to category per
#'   se.}
#' }
#' @source The raw data set \code{emojis} comes from the
#' \code{emoji} package, and it is processed by the author for the specific
#' needs of \code{tidyEmoji}.
"category_unicode_crosswalk"


