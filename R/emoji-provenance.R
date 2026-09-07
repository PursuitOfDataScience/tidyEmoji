# Provenance: which emoji set did you actually use?
#
# A small thing with real research value. "Emoji" is not a fixed object: which
# glyphs exist, what they are called and which lexicon scored them all depend
# on versions. Pasted into a methods section, one row answers the question
# reviewers should be asking.

#' Versions behind an emoji analysis, in one row
#'
#' `emoji_provenance()` reports every version an emoji result depends on:
#' tidyEmoji itself, the \pkg{emoji} package supplying the reference table, the
#' Unicode emoji version that table reflects, the size of that table, and the
#' bundled lexicons. It is meant to be pasted into a methods section or stored
#' beside a result.
#'
#' @details
#' None of these are cosmetic. A glyph released after your \pkg{emoji} package
#' was built is not detected at all; a lexicon covers a few hundred of the
#' thousands of emoji that exist; and "we analysed emoji sentiment" without a
#' lexicon name is not a reproducible statement. See [emoji_lexicons()] for the
#' lexicons in detail and [emoji_unicode_version()] for the Unicode version on
#' its own.
#'
#' `n_emoji` counts **rows of the reference table**, which are spellings, not
#' distinct emoji. With \pkg{emoji} 16.0.0 it is 5042, and those 5042 rows
#' carry only 3790 distinct code-point keys, because an emoji whose
#' presentation can be selected appears both with and without `U+FE0F`. A
#' methods section reporting "5042 emoji" therefore overstates the vocabulary
#' by the 1252 duplicate spellings; `length(unique(emoji_reference()$key))` is
#' the count of distinct emoji, and 212 of the 5042 spellings are not
#' detectable in text as written at all (see [emoji_sentiment_lexicon] for
#' why). No *emoji* is lost to that: every one of the 3790 keys is reachable
#' through at least one detectable spelling. The two lexicon strings count
#' their tables' rows the same way.
#'
#' @return A one-row tibble with columns `tidyEmoji`, `emoji_pkg`,
#'   `unicode_emoji`, `n_emoji` (rows of the reference table -- see Details),
#'   `sentiment_lexicon`, `emotion_lexicon` and `R`.
#' @seealso [emoji_unicode_version()], [emoji_unicode_releases()],
#'   [emoji_lexicons()].
#' @examples
#' emoji_provenance()
#' @export
emoji_provenance <- function() {
  tibble::tibble(
    tidyEmoji = as.character(utils::packageVersion("tidyEmoji")),
    emoji_pkg = as.character(utils::packageVersion("emoji")),
    unicode_emoji = emoji_unicode_version(),
    n_emoji = nrow(emoji_reference()),
    sentiment_lexicon = sprintf("novak2015 (%d emoji)",
                                nrow(emoji_sentiment_lexicon)),
    emotion_lexicon = sprintf("emotag1200 (%d emoji)",
                              nrow(emoji_emotion_lexicon)),
    R = paste(R.version$major, R.version$minor, sep = ".")
  )
}
