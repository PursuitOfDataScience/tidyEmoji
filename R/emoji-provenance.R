# Provenance: which emoji set did you actually use?
#
# A small thing with real research value. "Emoji" is not a fixed object: which
# glyphs exist, what they are called and which lexicon scored them all depend
# on versions. Pasted into a methods section, one row answers the question
# reviewers should be asking.

#' Versions behind an emoji analysis, in one row
#'
#' `emoji_provenance()` reports every version an emoji result depends on:
#' tidyEmoji itself, the Unicode emoji version of the catalogue it detects
#' against and the date of that catalogue's data file, the size of the
#' catalogue, the release of the \pkg{emoji} package whose shortcodes,
#' keywords and detection regex it bundles, and the bundled lexicons. It is
#' meant to be pasted into a methods section or stored beside a result.
#'
#' @details
#' None of these are cosmetic. A glyph newer than the catalogue is not
#' detected at all; a lexicon covers a few hundred of the thousands of emoji
#' that exist; and "we analysed emoji sentiment" without a lexicon name is not
#' a reproducible statement. See [emoji_lexicons()] for the lexicons in detail
#' and [emoji_unicode_version()] for the Unicode version on its own.
#'
#' **The catalogue moved in 0.6.0, so results from 0.5.0 and 0.6.0 differ, and
#' this row is how to tell which you have.** The catalogue is now Unicode's
#' `emoji-test.txt` rather than the table inside \pkg{emoji}, which takes it
#' from Emoji 16.0 to 18.0 and makes 182 more emoji detectable. In the other
#' direction, a skin-tone swatch standing alone and a regional-indicator pair
#' that is no country stopped being emoji occurrences; [emoji_summary()]
#' counts both. A corpus re-run under 0.6.0 can therefore report more emoji
#' or fewer, and `unicode_emoji` is the column that says why.
#'
#' `n_emoji` counts **rows of the reference table**, which are spellings, not
#' distinct emoji. With the Emoji 18.0 catalogue it is 5244, and those 5244
#' rows carry only 3972 distinct code-point keys, because an emoji whose
#' presentation can be selected appears both with and without `U+FE0F`. A
#' methods section reporting "5244 emoji" therefore overstates the vocabulary
#' by the 1272 duplicate spellings; `length(unique(emoji_properties()$key))`
#' is the count of distinct emoji, nine of which are the skin-tone and hair
#' components, which are not emoji on their own. 212 of the 5244 spellings
#' are not detectable in text as written under the default `presentation`
#' (see [emoji_sentiment_lexicon] for why, and [emoji_summary()] for
#' `presentation = "any"`). No *emoji* is lost to that: every one of the 3963
#' keys that is not a component is reachable through at least one detectable
#' spelling. The two lexicon strings count their tables' rows the same way.
#'
#' Since 0.7.0 `emoji_pkg` is the release of \pkg{emoji} the bundled snapshot
#' of its data was taken from, 16.0.0, not whatever version is installed:
#' tidyEmoji no longer reads the installed package, so it is the version every
#' result was computed with.
#'
#' @return A one-row tibble with columns `tidyEmoji`, `emoji_pkg`,
#'   `unicode_emoji`, `unicode_emoji_date` (the date in the header of the
#'   catalogue's data file, a `Date`), `n_emoji` (rows of the reference table;
#'   see Details), `sentiment_lexicon`, `emotion_lexicon` and `R`.
#' @seealso [emoji_unicode_version()], [emoji_unicode_releases()],
#'   [emoji_lexicons()].
#' @examples
#' emoji_provenance()
#' @concept provenance and reproducibility
#' @export
emoji_provenance <- function() {
  tibble::tibble(
    tidyEmoji = as.character(utils::packageVersion("tidyEmoji")),
    emoji_pkg = .emoji_upstream$version,
    unicode_emoji = emoji_unicode_version(),
    unicode_emoji_date = as.Date(.emoji_catalogue_meta$file_date),
    n_emoji = nrow(emoji_reference()),
    sentiment_lexicon = sprintf("novak2015 (%d emoji)",
                                nrow(emoji_sentiment_lexicon)),
    emotion_lexicon = sprintf("emotag1200 (%d emoji)",
                              nrow(emoji_emotion_lexicon)),
    R = paste(R.version$major, R.version$minor, sep = ".")
  )
}
