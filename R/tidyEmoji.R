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
#'   [emoji_dfm()]), where in that entry something sits, or the time bucket
#'   ([emoji_trend()], [emoji_turnover()], [emoji_seasonality()]). Dotted for
#'   the same reason, and reserved on the same terms. That is the whole list.
#'
#'   `.position` is the one of the five whose unit depends on the verb, so it
#'   is worth reading before you index with it. In [emoji_context()] it is a
#'   **code-point offset into the text**, the unit [substr()] takes, so
#'   `substr(text, .position, .position + nchar(.emoji) - 1)` returns the
#'   glyph. In [emoji_ngrams()] it is the **index within the row's emoji
#'   sequence**, so the first n-gram of a row is 1 whatever the text looks
#'   like. Both pages say which, and the two are not interchangeable.
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
#' Two of the shared dotted names do **not** mean the same thing in every verb
#' that writes them, so chaining those verbs replaces a number with a
#' different one rather than with the same one:
#'
#' * `.emoji_n_scored` counts the emoji *that verb's* lexicon could score, and
#'   the lexicons cover different emoji. [emoji_sentiment()],
#'   [emoji_score()] and [emoji_incongruity()] read the sentiment lexicon,
#'   [emoji_risk()] the ambiguity table built from it, and [emoji_emotion()]
#'   the emotion lexicon: `U+203C U+FE0F` scores `0` under the first four and
#'   `1` under [emoji_emotion()]. `emoji_score(lexicon = )` can be anything
#'   you registered.
#' * `.emoji_sentiment` is the mean over every emoji in the row from
#'   [emoji_sentiment()], but over only the trailing run from
#'   [emoji_incongruity()] with `where = "final"`.
#'
#' So `emoji_sentiment()` followed by `emoji_emotion()` leaves a
#' `.emoji_n_scored` describing the emotion lexicon beside a
#' `.emoji_sentiment` that does not. Rename the first result's column before
#' adding the second, or keep the two tables apart.
#'
#' `group` always refers to the Unicode top-level category (the term used by
#' Unicode's own `emoji-test.txt`, which the catalogue is built from). Every
#' glyph-to-metadata join is normalised through a codepoint key that strips
#' the `U+FE0F` variation selector, so qualified and unqualified emoji forms
#' resolve identically in every verb.
#'
#' @section Rates and their denominators:
#' **Every rate tidyEmoji returns ships with the numerator and the denominator
#' it was computed from**, so a user can fit a count model (a Poisson or
#' negative binomial regression of the count with the denominator as its
#' exposure) instead of a linear model on a ratio. [emoji_ratio()] returns
#' `.emoji_codepoints` and `.emoji_n_char` beside `.emoji_ratio`,
#' [emoji_density()] returns `.emoji_n_char` and `.emoji_n_token` beside its
#' two densities, [emoji_trend()] returns `n_period` beside `share`, and
#' [emoji_coverage()] returns the counts beside both coverages. Where a table
#' already carries every count a share is built from, as
#' [emoji_seasonality()] and [emoji_version_profile()] do, the denominator is
#' the column's total.
#'
#' This matters more than it sounds. Emoji counts are compositional (shares
#' of a document's total) and heavily zero-inflated, and the log-ratio
#' transforms compositional analysis depends on are undefined at zero, so a
#' bare quotient pushes the analyst into the modelling error. tidyEmoji
#' offers no `clr` or `ilr` transform, because zero replacement is a
#' methodological choice that belongs to the analysis (\pkg{compositions} and
#' \pkg{zCompositions} make it properly), but it returns what such a choice
#' needs. A new verb is held to the same rule.
#'
#' @section Detection:
#' Detection is grapheme-aware: a skin-tone modifier or a zero-width-joiner
#' sequence (a family, a couple, a profession) stays intact as one emoji, and
#' every verb asks the same question, so counts agree across the package.
#'
#' **What counts as an emoji is decided by the catalogue**, Unicode's own
#' `emoji-test.txt` for the version [emoji_unicode_version()] reports, bundled
#' with the package. [emoji_properties()] shows what it records about any
#' glyph. Until 0.6.0 the catalogue was the table inside the \pkg{emoji}
#' package, which stayed at Emoji 16.0 through two Unicode releases, so the
#' 182 emoji added in 17.0 and 18.0 were invisible; they are detected now. A
#' corpus re-run under 0.6.0 can therefore report more emoji than it did, and
#' because of the two repairs below, it can also report fewer.
#'
#' There is one systematic exclusion, and it is worth knowing before you read
#' a count. Some code points are emoji only in their *emoji-presentation* form,
#' that is only when the variation selector `U+FE0F` is present. The
#' best-known is the heart: `U+2764 U+FE0F` is detected, the bare `U+2764` is
#' not, and several keyboards emit the bare form. Across the catalogue 1272
#' spellings carry `U+FE0F`, and 216 of those become undetectable if it is
#' dropped: in the bundled sentiment lexicon, 57 of the scorable glyphs.
#' Counted the other way round, 212 of the catalogue's 5244 spellings are
#' themselves undetectable; the two figures measure different things and both
#' are right.
#'
#' The selector does not always go at the end. For 200 of those 212 it does,
#' so appending `U+FE0F` is what makes them detectable. The exceptions are the
#' 12 keycap sequences -- `#`, `*` and `0` to `9` followed by the enclosing
#' keycap mark `U+20E3` -- where the selector belongs *between* the two:
#' `U+0031 U+FE0F U+20E3` is detected and `U+0031 U+20E3 U+FE0F` is not.
#' Inserting `U+FE0F` after the first code point is the rule that repairs all
#' 212.
#'
#' **`presentation = "any"` reads them as they are**, on every verb that
#' counts, scores or rewrites emoji, without your having to repair the text:
#' all 212 except three. The
#' default does not, and that is deliberate rather than an oversight: the
#' same set contains `U+00A9`, `U+00AE` and `U+2122`, so matching them would
#' count the copyright sign in a legal footer as emoji use, which is why
#' `"any"` leaves those three out. The default stays `"emoji"`, because
#' widening it would silently recount every corpus already analysed;
#' [emoji_coverage()] reports what the choice adds. Detection is the only
#' thing affected; the join is not. Every glyph-to-metadata lookup strips
#' `U+FE0F` first, so if you hand a bare `U+2764` to [as_emoji_name()],
#' [emoji_sentiment()]'s lexicon or [emoji_ambiguity()], it resolves exactly
#' like the qualified form.
#'
#' Joined sequences are unaffected either way. Unicode lists several
#' spellings of a zero-width-joiner sequence -- fully qualified, and shorter
#' forms with the selectors omitted -- and a shorter one can leave an
#' undetectable component in the middle. Detection repairs those: **every
#' fully-qualified and minimally-qualified spelling in the catalogue is read
#' as exactly one emoji**, so `U+2764 U+200D U+1F525` is "heart on fire"
#' rather than "fire" even with its selectors stripped.
#'
#' Two things are emoji *material* without being emoji, and since 0.6.0 no
#' verb counts them:
#'
#' * **A skin-tone swatch or hair component standing alone.** A modifier
#'   applied to a base that cannot take one, as in `U+1F600 U+1F3FB`, leaves
#'   the swatch with nothing to modify. That is one emoji, the grinning face,
#'   and a swatch; until 0.6.0 it was counted as two emoji, the second named
#'   "light skin tone" in group `"Component"`.
#' * **Regional indicators that spell no flag.** Any two regional indicators
#'   form one grapheme cluster, so `U+1F1FD U+1F1FD` ("XX") used to be read
#'   as an emoji with no name, as did a lone indicator. Only 259 of the 676
#'   possible pairs are flags in the catalogue; anything else is not an
#'   emoji. Subdivision flags are tag sequences, not pairs, and are
#'   unaffected.
#'
#' Neither is silently discarded. [emoji_summary()] counts both, in
#' `n_orphan_components` and `n_invalid_flags`, so a corpus whose count fell
#' can be explained, and [emoji_country()] reports a stray pair with its glyph
#' and no country code. The verbs that rewrite text treat them as before 0.6.0
#' (`emoji_sanitize(policy = "strip")` still removes a swatch, and
#' [emoji_to_text()] still names it), because what changed is what is
#' *counted*, and a swatch left in a stripped column would still be a swatch.
#'
#' ASCII emoticons such as `:)` are not emoji and are never detected, so a
#' study of the move from emoticons to emoji, which needs both in one
#' denominator, has to count the emoticons itself.
#'
#' @section Which spelling comes back:
#' Two spellings of one emoji, differing only by `U+FE0F`, are one emoji to
#' every lookup: the name, the score, the category and the type all resolve
#' through a key that strips the selector. They are not always one *row*. A
#' verb that reports a glyph either hands back the spelling it found or
#' collapses both onto the catalogue's, and which it does follows from what
#' the verb is for:
#'
#' * **The spelling as found**: [emoji_frequency()], [top_n_emojis()],
#'   [emoji_tokens()], [emoji_extract_nest()], [emoji_extract_unnest()] and
#'   [emoji_context()]. These report occurrences, and an occurrence is the
#'   text you actually had.
#' * **Collapsed onto one**: [emoji_pairs()], [emoji_cooccurrence()],
#'   [emoji_ngrams()], [emoji_dfm()], [emoji_collocations()],
#'   [emoji_trend()], [emoji_adoption_lag()] and
#'   [emoji_incongruity_profile()]. These build an item, a node, a feature
#'   or a series, and two spellings of one emoji are one of those.
#'   [emoji_turnover()] and [emoji_version_profile()] count the same way in
#'   their `n_types`, without reporting a glyph at all.
#'
#' A corpus holding both spellings shows the difference in one line:
#' [emoji_frequency()] returns two rows of `n = 1` where
#' [emoji_cooccurrence()] returns one node of `n = 2`. Nothing is lost
#' either way, and the two sides line up on the name, which is the same for
#' both spellings: `emoji_frequency()` already carries it, and
#' [as_emoji_name()] supplies it for a glyph column of your own.
#'
#' This is only ever about spellings of the *same* emoji. Skin tones, genders
#' and the members of a ZWJ sequence are different emoji and stay apart in
#' every verb.
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
  "item1", "item2", ".position", ".emoji_ngram", ".sort",
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
