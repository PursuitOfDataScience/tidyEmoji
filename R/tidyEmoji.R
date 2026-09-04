#' @keywords internal
#' @aliases tidyEmoji-package
#' @importFrom dplyr %>%
#'
#' @section Output and naming contract:
#' Every verb follows `verb(data, text, ...)`, takes the text column unquoted,
#' and returns a tibble. Columns *added to your data* carry a dotted
#' `.emoji_*` prefix (`.emoji`, `.emoji_name`, `.emoji_category`,
#' `.emoji_sentiment`, `.emoji_n`, ...) so they will not collide with your own
#' columns; *new summary tibbles* (e.g. [emoji_frequency()]) use bare names.
#' The dotted prefix is **reserved**: a verb overwrites any column of its own
#' output name that is already there, without warning. That is what makes
#' verbs chainable and re-runnable -- `emoji_sentiment()` then
#' `emoji_position()` both write `.emoji_n`, and both mean the same thing --
#' but
#' it also means a column of your own called `.emoji_n` will be replaced.
#' Rename it first if you need to keep it.
#' `group` always refers to the Unicode top-level category (the term used by
#' the underlying `emoji::emojis` table). Every glyph-to-metadata join is
#' normalised through a codepoint key that strips the `U+FE0F` variation
#' selector, so qualified and unqualified emoji forms resolve identically in
#' every verb.
#'
#' @section Detection:
#' Detection is grapheme-aware: a skin-tone modifier or a zero-width-joiner
#' sequence (a family, a couple, a profession) stays intact as one emoji, and
#' every verb asks the same question, so counts agree across the package.
#'
#' There is one systematic exclusion, and it is worth knowing before you read
#' a count. Some code points are emoji only in their *emoji-presentation* form,
#' that is only when followed by the variation selector `U+FE0F`. The
#' best-known is the heart: `U+2764 U+FE0F` is detected, the bare `U+2764` is
#' not, and several keyboards emit the bare form. Across the reference
#' catalogue 1252 emoji carry `U+FE0F`, and 216 of those become undetectable
#' if it is dropped -- in the bundled sentiment lexicon, 57 of the scorable
#' glyphs.
#'
#' The default does not match the bare forms, and that is deliberate rather
#' than an oversight: the same set contains `U+00A9`, `U+00AE` and `U+2122`, so
#' matching them unqualified would count the copyright sign in a legal footer
#' as emoji use. Detection is the only thing affected -- the join is not. Every
#' glyph-to-metadata lookup strips `U+FE0F` first, so if you hand a bare
#' `U+2764` to [as_emoji_name()], [emoji_sentiment()]'s lexicon or
#' [emoji_ambiguity()], it resolves exactly like the qualified form.
#'
#' Joined sequences are unaffected either way. Unicode lists several
#' spellings of a zero-width-joiner sequence -- fully qualified, and shorter
#' forms with the selectors omitted -- and a shorter one can leave an
#' undetectable component in the middle. Detection repairs those: **every
#' canonical spelling in the reference table, and all but two of the shorter
#' ones, is read as exactly one emoji**, so `U+2764 U+200D U+1F525` is "heart
#' on fire" rather than "fire" even with its selectors stripped. The two
#' exceptions are spellings in which no component at all is detectable, and
#' both have a canonical form that is found.
#'
#' @section Grouped data frames:
#' Grouping is respected where it can be, and reported where it cannot. The
#' verbs that work a row at a time -- the ones that add `.emoji_*` columns, and
#' the ones that keep or expand rows -- carry the input's grouping through to
#' their result, exactly as [dplyr::mutate()] and [dplyr::filter()] do, so a
#' `group_by()` upstream still means something to a `summarise()` downstream.
#' The verbs that pool across rows -- [emoji_frequency()], [emoji_dfm()],
#' [emoji_pairs()], the time series, and the other corpus-level summaries --
#' cannot honour groups yet: they warn and return a single corpus-wide answer.
#' Splitting the data yourself, or passing a `doc_id` where the verb offers
#' one, is the way to get per-group results today.
"_PACKAGE"

# Quiet R CMD check notes about variables referenced via tidy evaluation and
# bundled datasets used inside package functions.
utils::globalVariables(c(
  ".",
  "emoji", "name", "shortcode", "group", "subgroup", "version", "n", "unicode",
  "emoji_name", "emoji_category", "key",
  "word", "pmi", "share", "ambiguity", "rank", "flip_rate", ".period",
  ".row_number", ".emoji", ".emoji_unicode", ".emoji_count", ".emoji_category",
  ".emoji_name", ".emoji_sentiment", ".emoji_n", ".emoji_n_scored",
  ".emoji_score", ".emoji_emotion",
  "item1", "item2", ".position", ".emoji_ngram",
  ".emoji_first", ".emoji_last", ".emoji_rel_position",
  ".emoji_per_char", ".emoji_per_token", ".emoji_ratio", ".emoji_only",
  ".emoji_anger", ".emoji_anticipation", ".emoji_disgust", ".emoji_fear",
  ".emoji_joy", ".emoji_sadness", ".emoji_surprise", ".emoji_trust",
  "anger", "anticipation", "disgust", "fear", "joy", "sadness", "surprise",
  "trust",
  "sentiment_score", "sentiment_label",
  "emoji_unicode_crosswalk", "category_unicode_crosswalk",
  "emoji_sentiment_lexicon", "emoji_emotion_lexicon"
))
