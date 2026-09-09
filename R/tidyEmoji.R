#' @keywords internal
#' @aliases tidyEmoji-package
#' @importFrom dplyr %>%
#'
#' @section Output and naming contract:
#' Every verb follows `verb(data, text, ...)`, takes the text column unquoted,
#' and returns a tibble. Output column names come in three shapes, and which
#' one you get tells you what the column is:
#'
#' * **`.emoji_*`** -- a measurement of your text, added to your data
#'   (`.emoji`, `.emoji_name`, `.emoji_category`, `.emoji_sentiment`,
#'   `.emoji_n`, ...). Dotted so it will not collide with your own columns.
#' * **`.row_number`, `.position`, `.period`, `.period_prev`,
#'   `.period_label`** -- structural indices saying *where* a row came from
#'   rather than what was measured: the position of the entry in `data`
#'   ([emoji_extract_unnest()], [emoji_context()], [emoji_ngrams()],
#'   [emoji_dfm()]), the character offset of an occurrence, or the time bucket
#'   ([emoji_trend()], [emoji_turnover()], [emoji_seasonality()]). Dotted for
#'   the same reason, and reserved on the same terms. That is the whole list.
#' * **bare names** -- the columns of a *new* summary tibble, which is not your
#'   data with something added ([emoji_frequency()]'s `emoji`, `name`, `n`;
#'   [emoji_ambiguity()]'s `ambiguity`, `rank`). [emoji_dfm()] is the one verb
#'   whose column names are data: one per emoji, named with the glyph itself.
#'
#' Every dotted name is **reserved**: a verb overwrites any column of its own
#' output name that is already there, without warning. That is what makes
#' verbs chainable and re-runnable -- `emoji_sentiment()` then
#' `emoji_position()` both write `.emoji_n`, and both mean the same thing --
#' but it also means a column of your own called `.emoji_n` will be replaced,
#' and that includes the text column itself if you named it `.emoji_n`. Rename
#' it first if you need to keep it.
#'
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
#' that is only when the variation selector `U+FE0F` is present. The
#' best-known is the heart: `U+2764 U+FE0F` is detected, the bare `U+2764` is
#' not, and several keyboards emit the bare form. Across the reference
#' catalogue 1252 emoji carry `U+FE0F`, and 216 of those become undetectable
#' if it is dropped -- in the bundled sentiment lexicon, 57 of the scorable
#' glyphs. Counted the other way round, 212 of the catalogue's 5042 rows are
#' spellings that are themselves undetectable; the two figures measure
#' different things and both are right.
#'
#' The selector does not always go at the end. For 200 of those 212 it does,
#' so appending `U+FE0F` is what makes them detectable. The exceptions are the
#' 12 keycap sequences -- `#`, `*` and `0` to `9` followed by the enclosing
#' keycap mark `U+20E3` -- where the selector belongs *between* the two:
#' `U+0031 U+FE0F U+20E3` is detected and `U+0031 U+20E3 U+FE0F` is not.
#' Inserting `U+FE0F` after the first code point is the rule that repairs all
#' 212.
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
#' Everything above is about what detection *misses*. It also admits two
#' things that are well formed but not emoji, and both flow through every
#' verb, so a corpus statistic can be inflated by them:
#'
#' * **An invalid regional-indicator pair.** Any two regional indicators form
#'   one grapheme cluster, so `U+1F1FD U+1F1FD` is read as a single emoji even
#'   though no country has that code. It appears in [emoji_frequency()] with
#'   `name = NA`, gets a column in [emoji_dfm()] and a node in
#'   [emoji_pairs()]. Only 262 of the pairs are real: `subgroup` is
#'   `"country-flag"` for 259 rows of the reference table and
#'   `"subdivision-flag"` for 3, so you can filter against that set --
#'   [emoji_frequency()] carries `group`, and [emoji_provenance()] reports
#'   which catalogue you have.
#' * **An orphan skin-tone modifier or hair component.** A modifier applied to
#'   a base that cannot take one, as in `U+1F600 U+1F3FB`, leaves the swatch
#'   standing alone -- and because the Component group is in the reference
#'   table it comes back *named*, as "light skin tone" in group `"Component"`,
#'   not as `NA`. [as_emoji_type()] labels these `"component"`, which is the
#'   way to find and drop them:
#'   `subset(emoji_frequency(df, text), as_emoji_type(emoji) != "component")`.
#'
#' Both are defensible as raw detection and misleading as a corpus statistic,
#' which is why they are named here rather than silently filtered: dropping
#' them inside the verbs would make the emoji counts disagree with the text.
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
