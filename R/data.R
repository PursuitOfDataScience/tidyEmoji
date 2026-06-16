#' Emoji name, unicode and category crosswalk
#'
#' A table with one row per emoji *name*: each emoji glyph appears once for every
#' GitHub-style name it is known by, so a single unicode can occur on several
#' rows (for example the grinning face is both "grinning" and "grinning_face").
#'
#' @format A data frame with three columns:
#' \describe{
#'   \item{emoji_name}{The emoji name / shortcode (e.g. "grinning").}
#'   \item{unicode}{The emoji glyph.}
#'   \item{emoji_category}{The Unicode category the emoji belongs to.}
#' }
#' @source Derived from the `emojis` table of the \pkg{emoji} package; rebuilt by
#'   `data-raw/crosswalks.R`.
"emoji_unicode_crosswalk"


#' Emoji category to unicode crosswalk
#'
#' A table with one row per Unicode category, listing every emoji glyph in that
#' category as a single `|`-separated string.
#'
#' @format A data frame with two columns:
#' \describe{
#'   \item{category}{The Unicode category (10 categories).}
#'   \item{unicodes}{The emoji glyphs in the category, separated by `|`.}
#' }
#' @source Derived from the `emojis` table of the \pkg{emoji} package; rebuilt by
#'   `data-raw/crosswalks.R`.
"category_unicode_crosswalk"


#' Emoji Sentiment Ranking lexicon
#'
#' Sentiment scores for emoji, from the *Emoji Sentiment Ranking 1.0*, computed
#' from ~70,000 tweets in 13 European languages annotated for sentiment. The
#' `sentiment_score` is `(positive - negative) / occurrences`, ranging from -1
#' (negative) to +1 (positive); `sentiment_label` is derived from its sign.
#'
#' @format A data frame with one row per emoji and the columns:
#' \describe{
#'   \item{emoji}{The emoji glyph.}
#'   \item{occurrences}{Number of times the emoji was observed.}
#'   \item{position}{Mean position of the emoji within its text (0-1).}
#'   \item{negative, neutral, positive}{Annotation counts for each class.}
#'   \item{sentiment_score}{Sentiment score from -1 to 1.}
#'   \item{sentiment_label}{"negative", "neutral" or "positive".}
#'   \item{unicode_name}{The official Unicode character name.}
#'   \item{unicode_block}{The Unicode block.}
#' }
#' @source Kralj Novak P, Smailovic J, Sluban B, Mozetic I (2015) Sentiment of
#'   Emojis. PLoS ONE 10(12): e0144296. \doi{10.1371/journal.pone.0144296}.
#'   Data from \url{https://hdl.handle.net/11356/1048}, released under the
#'   Creative Commons Attribution-ShareAlike 4.0 International (CC BY-SA 4.0)
#'   licence. Processed by `data-raw/emoji_sentiment_lexicon.R`.
"emoji_sentiment_lexicon"
