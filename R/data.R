#' Emoji emotion lexicon (EmoTag1200)
#'
#' Human-annotated emotion-association scores (each from 0 to 1) for the eight
#' Plutchik emotions (anger, anticipation, disgust, fear, joy, sadness, surprise,
#' trust), for the 150 most popular Twitter emoji, from EmoTag1200.
#'
#' @section How much of the catalogue this covers:
#' **150 glyphs, about 4% of the distinct emoji tidyEmoji can detect** (3972
#' distinct codepoint keys in the Emoji 18.0 catalogue, nine of them the
#' skin-tone and hair components; see [emoji_provenance()] for the version
#' you have, and [emoji_coverage()] for the share of *your* corpus it scores,
#' which is a different and larger number). That is not a defect, since
#' EmoTag1200 is a carefully annotated 150-glyph resource, but it is worth
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
#' A table with one row per (name, glyph) *pair*, not one row per name and not
#' one row per glyph. 5761 rows cover 4698 distinct names and 4853 distinct
#' glyphs, because the mapping is many-to-many in both directions:
#'
#' * a glyph appears once for every GitHub-style name it is known by (the
#'   grinning face is both "grinning" and "grinning_face"), and
#' * a name appears once for every *spelling* of the emoji it names -- 973 do,
#'   because the qualified and unqualified forms of an emoji are separate rows
#'   that share one alias (`A_button_blood_type_` names both
#'   `U+1F170 U+FE0F` and the bare `U+1F170`).
#'
#' So a join by `emoji_name` duplicates rows for those 973 names. Join on `key`
#' -- which collapses the spellings -- or `dplyr::distinct()` the columns you
#' need first.
#'
#' @format A data frame with four columns:
#' \describe{
#'   \item{emoji_name}{The emoji name / shortcode (e.g. "grinning").}
#'   \item{unicode}{The emoji glyph.}
#'   \item{emoji_category}{The Unicode category the emoji belongs to.}
#'   \item{key}{Codepoint-normalised key (U+FE0F stripped) for robust joining.}
#' }
#' @source The glyphs and categories come from Unicode's `emoji-test.txt`,
#'   the catalogue [emoji_properties()] reports, and the names from the
#'   GitHub-style aliases of the \pkg{emoji} package; rebuilt by
#'   `data-raw/crosswalks.R`. An emoji newer than \pkg{emoji}'s own table has
#'   no alias, so it is in the catalogue but not in this table.
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
#' @source Unicode's `emoji-test.txt`, the catalogue [emoji_properties()]
#'   reports; rebuilt by `data-raw/crosswalks.R`.
"category_unicode_crosswalk"


#' Emoji Sentiment Ranking lexicon
#'
#' Sentiment scores for emoji, from the *Emoji Sentiment Ranking 1.0*, computed
#' from ~70,000 tweets in 13 European languages annotated for sentiment. The
#' `sentiment_score` is `(positive - negative) / occurrences`, ranging from -1
#' (negative) to +1 (positive); `sentiment_label` is derived from its sign.
#'
#' @section How much of the catalogue this covers:
#' **969 rows, of which 736 resolve to an emoji tidyEmoji can detect -- about
#' 19% of the 3972 distinct codepoint keys in the Emoji 18.0 catalogue** (see
#' [emoji_provenance()] for the version you have, and [emoji_coverage()] for
#' the share of your own corpus it can score).
#' Two caveats on that figure, both consequences of the lexicon being built
#' from 2015 tweets: the other 233 rows are not in the reference table at all
#' -- see *Detection limitations* below -- and nothing added to Unicode after
#' 2015 is in here.
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


#' OpenAssistant messages: a dated, multilingual example corpus
#'
#' 1,485 messages from OpenAssistant Conversations (OASST2): every eligible
#' message that carries an emoji (750) and as many emoji-free ones (735),
#' written between 2023-01-17 and 2023-10-30 in 17 languages, by people
#' asking (`"prompter"`, 508) and by people writing the assistant's replies
#' (`"assistant"`, 977). It is the example data of the vignettes and help
#' pages since 0.7.0, and the reaction tallies on the same messages are in
#' [oasst_reactions].
#'
#' Emoji are rare in real text, so the sample is stratified on them: about
#' half the rows carry one, where 1.03% of all OASST2 messages do. Figures
#' computed on it describe this sample, not OASST2, and not chat in general.
#'
#' @section How the sample was drawn:
#' From the 135,174 messages of the "ready" release, in this order: messages
#' marked deleted (4,376) and synthetic (0) were dropped; then those whose
#' largest detoxify score is 0.1 or more (2,092); those matching a word-list
#' screen for slurs (23); those holding an e-mail address, a phone-number
#' shape or a URL with a query string (1,021); and those longer than 600 code
#' points (36,614), so printed examples stay readable. That left 91,048
#' messages, 751 of them carrying an emoji.
#'
#' The toxicity scores and the word list are English-centred, and 107 of the
#' 751 emoji-bearing messages had no detoxify score at all (Portuguese,
#' Chinese, German, Japanese and Ukrainian among them). Each of those was read
#' in full before the data was committed, as was every row an example or a
#' vignette prints, and a message was to be removed if it was sexual, hateful
#' or harassing or held personal data the automatic screens missed: one was,
#' for describing the sexual abuse of minors. `data-raw/oasst-read-out.csv`
#' lists it with its rule.
#'
#' The sample is every remaining emoji-bearing message and an equal number of
#' emoji-free ones, allocated across month by role by language in proportion
#' to the emoji-free messages and drawn with `set.seed(20261106)`. "Carries
#' an emoji" is the package's own detection when the extract was built.
#'
#' @format A tibble with 1,485 rows and 6 columns:
#' \describe{
#'   \item{message_id}{OASST2's identifier for the message.}
#'   \item{parent_id}{The message this one replies to, so replies can be told
#'     from opening prompts (117 have `NA`). The parent need not be in the
#'     sample: 1,315 rows reply to a message that is not.}
#'   \item{created_at}{When the message was written, a `POSIXct` in UTC.}
#'   \item{role}{`"prompter"` or `"assistant"`. Both are written by people;
#'     OASST2's model-written messages are excluded with the synthetic ones.}
#'   \item{lang}{The language OASST2 records, as a BCP 47 tag (`"en"`,
#'     `"pt-BR"`).}
#'   \item{text}{The message as written, line breaks included.}
#' }
#' @source Kopf A, Kilcher Y, von Rutte D, Anagnostidis S, Tam ZR, Stevens K,
#'   et al. (2023). OpenAssistant Conversations: Democratizing Large Language
#'   Model Alignment. *NeurIPS 2023 Datasets and Benchmarks*.
#'   <https://arxiv.org/abs/2304.07327>. Data from
#'   <https://huggingface.co/datasets/OpenAssistant/oasst2>, file
#'   `2023-11-05_oasst2_ready.messages.jsonl.gz` at revision
#'   `179dd21fc55192153d94adb0e0ce8f69e222bf75`, released under the Apache
#'   License 2.0, whose text `inst/LICENSE.note` reproduces. Processed by
#'   `data-raw/oasst.R`, which rebuilds the sample offline from a committed
#'   extract of the eligible messages.
#' @seealso [oasst_reactions] for the tallies; [emoji_trend()] and
#'   [emoji_from_counts()] for the verbs that need what the old example
#'   corpus lacked, a date and a tally.
#' @examples
#' emoji_summary(oasst_messages, text)
#' table(oasst_messages$role)
#' @concept example data
"oasst_messages"


#' Reaction tallies on the OpenAssistant messages
#'
#' The reactions OASST2 records on the messages in [oasst_messages], in long
#' form: 2,469 rows over 1,294 of the messages, one per message and name,
#' with the number of people who used it.
#'
#' The names are OASST2's own, and they are realistically messy. `"+1"`
#' (2,323 uses), `"-1"` (802) and `"red_flag"` (48) are reactions, the first
#' two under GitHub's names. `"_skip_reply"` (1,365), `"_skip_labeling"` (857)
#' and `"_skip_ranking"` (396) are not: they are the interface's skip actions,
#' stored beside the reactions, and kept here because a real tally holds such
#' things and an analysis has to decide what to do with them.
#' [emoji_from_counts()] refuses a name it cannot resolve, by name, rather
#' than counting it as nothing.
#'
#' @format A tibble with 2,469 rows and 3 columns:
#' \describe{
#'   \item{message_id}{The message, as in [oasst_messages].}
#'   \item{reaction}{The name OASST2 records.}
#'   \item{n}{How many times it was used on the message, an integer.}
#' }
#' @source As [oasst_messages]: the `emojis` field of the same OASST2 file,
#'   Apache License 2.0, processed by `data-raw/oasst.R`.
#' @seealso [emoji_from_counts()], which turns a tally into text the other
#'   verbs read.
#' @examples
#' head(oasst_reactions)
#' # the reactions alone, as text every verb can read
#' votes <- oasst_reactions[oasst_reactions$reaction %in% c("+1", "-1"), ]
#' emoji_frequency(emoji_from_counts(votes, reaction, n, id = message_id), text)
#' @concept example data
#' @concept tallies
"oasst_reactions"
