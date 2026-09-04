#' Emoji emotion lexicon (EmoTag1200)
#'
#' Human-annotated emotion-association scores (each from 0 to 1) for the eight
#' Plutchik emotions (anger, anticipation, disgust, fear, joy, sadness, surprise,
#' trust), for the 150 most popular Twitter emoji, from EmoTag1200.
#'
#' @section How much of the catalogue this covers:
#' **150 glyphs, about 4% of the distinct emoji tidyEmoji can detect** (3790
#' distinct codepoint keys in the reference table of \pkg{emoji} 16.0.0; see
#' [emoji_provenance()] for the version you have). That is not a defect --
#' EmoTag1200 is a carefully annotated 150-glyph resource -- but it is worth
#' knowing *before* concluding that a corpus carries no emotion: a modern
#' corpus is mostly post-2018 glyphs that no bundled lexicon has seen.
#' [emoji_emotion()] reports this per row rather than hiding it:
#' `.emoji_n_scored` is `0` when a row has emoji the lexicon cannot score, and
#' `NA` only when the row has no emoji at all.
#'
#' @format A data frame with one row per emoji and the columns:
#' \describe{
#'   \item{key}{Codepoint-normalised key (U+FE0F stripped) for robust joining.}
#'   \item{emoji}{The emoji glyph (unqualified form, as stored by the source).}
#'   \item{name}{The emoji's Unicode name.}
#'   \item{anger, anticipation, disgust, fear, joy, sadness, surprise, trust}{
#'     Emotion-association scores, each from 0 to 1.}
#' }
#' @source Shoeb AAM, de Melo G (2020). EmoTag1200: Understanding the
#'   Association between Emojis and Emotions. *EMNLP 2020*.
#'   <https://aclanthology.org/2020.emnlp-main.720/>. Data from
#'   <https://github.com/abushoeb/EmoTag>, released under the MIT licence.
#'   Processed by `data-raw/emoji_emotion_lexicon.R`.
"emoji_emotion_lexicon"


#' Emoji name, unicode and category crosswalk
#'
#' A table with one row per emoji *name*: each emoji glyph appears once for every
#' GitHub-style name it is known by, so a single unicode can occur on several
#' rows (for example the grinning face is both "grinning" and "grinning_face").
#'
#' @format A data frame with four columns:
#' \describe{
#'   \item{emoji_name}{The emoji name / shortcode (e.g. "grinning").}
#'   \item{unicode}{The emoji glyph.}
#'   \item{emoji_category}{The Unicode category the emoji belongs to.}
#'   \item{key}{Codepoint-normalised key (U+FE0F stripped) for robust joining.}
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
#' @section How much of the catalogue this covers:
#' **969 rows, covering about 19% of the distinct emoji tidyEmoji can detect**
#' (3790 distinct codepoint keys in the reference table of \pkg{emoji} 16.0.0;
#' see [emoji_provenance()] for the version you have). Two caveats on that
#' figure, both consequences of the lexicon being built from 2015 tweets: 233
#' of the 969 rows are not in the reference table at all -- see *Detection
#' limitations* below -- and nothing added to Unicode after 2015 is in here.
#' [emoji_sentiment()]'s `.emoji_n_scored` reports the shortfall per row.
#'
#' @section Detection limitations:
#' Many of the glyphs in this lexicon are stored in their *unqualified*,
#' text-presentation form: a single code point with no \code{U+FE0F}
#' emoji-presentation variation selector. The best-known is the bare heart,
#' \code{U+2764}; others include the white smiling face (\code{U+263A}), the
#' heavy check mark (\code{U+2714}) and the black rightwards arrow
#' (\code{U+27A1}). The lexicon also contains characters that are not emoji at
#' all (box-drawing characters, the copyright and registered signs, the
#' replacement character), inherited from the tweets it was built from.
#'
#' The grapheme-aware detection used throughout the package does not treat
#' these text-presentation code points as emoji, so a row whose only "emoji" is
#' one of them is not counted or scored -- it behaves as if it contained no
#' emoji. This affects detection only, never the join: supply the qualified
#' form (the red heart \code{U+2764 U+FE0F}, say) and it resolves to the same
#' lexicon entry, because every lookup goes through a codepoint key that
#' ignores \code{U+FE0F}.
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
