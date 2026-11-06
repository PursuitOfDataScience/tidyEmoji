# tidyEmoji: Discover, Count, Categorise, Score, Translate and Relate Emoji in Text

A tidy toolkit for working with the emoji in any text column, such as
social-media posts, product reviews, chat logs or survey responses.
Unicode is awkward to handle and not every code point is an emoji, which
makes emoji statistics fiddly to obtain. 'tidyEmoji' extracts, counts,
categorises, sentiment-scores and emotion-scores emoji, converts them to
and from text (for accessibility and NLP preprocessing), searches the
emoji catalogue, maps emoji co-occurrence and sequences (graph-ready
edge lists and n-grams), measures where and how densely emoji are used,
and builds document-by-emoji feature tables for machine learning, with
grapheme-aware detection (so skin-tone and multi-person sequences stay
intact), returning tidy data frames that slot straight into a
'tidyverse' workflow. It also quantifies how much annotators disagreed
about an emoji (interpretation risk), extracts the words around each
emoji, tracks emoji use over time, measures text-emoji sentiment
mismatch, and applies explicit emoji-preprocessing policies for
language-model pipelines. Its emoji catalogue is the Unicode emoji test
data, bundled and current to Emoji 18.0, so it can also say what a glyph
is, map flag emoji to ISO 3166 codes, report how much of a corpus each
lexicon can score, and read reaction tallies as well as text. The
bundled emoji sentiment lexicon is from the Emoji Sentiment Ranking of
Kralj Novak et al. (2015)
[doi:10.1371/journal.pone.0144296](https://doi.org/10.1371/journal.pone.0144296)
, released under CC BY-SA 4.0; the emotion lexicon is from EmoTag1200 of
Shoeb & de Melo (2020) <https://aclanthology.org/2020.emnlp-main.720/>,
released under the MIT licence. The example data, dated and
multilingual, is a sample of OpenAssistant Conversations (Kopf et al.,
2023) [arXiv:2304.07327](https://arxiv.org/abs/2304.07327), released
under the Apache License 2.0.

## Output and naming contract

Every verb follows `verb(data, text, ...)`, takes the text column
unquoted, and returns a tibble. Output column names come in three
shapes, and which one you get tells you what the column is:

- **`.emoji_*`** – a measurement of your text, added to your data
  (`.emoji`, `.emoji_name`, `.emoji_category`, `.emoji_sentiment`,
  `.emoji_n`, ...). Dotted so it will not collide with your own columns.

- **`.row_number`, `.position`, `.period`, `.period_prev`,
  `.period_label`** – structural indices saying *where* a row came from
  rather than what was measured: the position of the entry in `data`
  ([`emoji_extract_unnest()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_extract_unnest.md),
  [`emoji_context()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_context.md),
  [`emoji_ngrams()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_ngrams.md),
  [`emoji_dfm()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_dfm.md)),
  where in that entry something sits, or the time bucket
  ([`emoji_trend()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_trend.md),
  [`emoji_turnover()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_turnover.md),
  [`emoji_seasonality()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_seasonality.md)).
  Dotted for the same reason, and reserved on the same terms. That is
  the whole list.

  `.position` is the one of the five whose unit depends on the verb, so
  it is worth reading before you index with it. In
  [`emoji_context()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_context.md)
  it is a **code-point offset into the text**, the unit
  [`substr()`](https://rdrr.io/r/base/substr.html) takes, so
  `substr(text, .position, .position + nchar(.emoji) - 1)` returns the
  glyph. In
  [`emoji_ngrams()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_ngrams.md)
  it is the **index within the row's emoji sequence**, so the first
  n-gram of a row is 1 whatever the text looks like. Both pages say
  which, and the two are not interchangeable.

- **bare names** – the columns of a *new* summary tibble, which is not
  your data with something added
  ([`emoji_frequency()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_frequency.md)'s
  `emoji`, `name`, `n`;
  [`emoji_ambiguity()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_ambiguity.md)'s
  `ambiguity`, `rank`).
  [`emoji_dfm()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_dfm.md)
  is the one verb whose column names are data: one per emoji, named with
  the glyph itself.

Every dotted name is **reserved**: a verb overwrites any column of its
own output name that is already there, without warning. That is what
makes verbs chainable and re-runnable –
[`emoji_sentiment()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sentiment.md)
then
[`emoji_position()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_position.md)
both write `.emoji_n`, and both mean the same thing – but it also means
a column of your own called `.emoji_n` will be replaced, and that
includes the text column itself if you named it `.emoji_n`. Rename it
first if you need to keep it.

Two of the shared dotted names do **not** mean the same thing in every
verb that writes them, so chaining those verbs replaces a number with a
different one rather than with the same one:

- `.emoji_n_scored` counts the emoji *that verb's* lexicon could score,
  and the lexicons cover different emoji.
  [`emoji_sentiment()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sentiment.md),
  [`emoji_score()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_score.md)
  and
  [`emoji_incongruity()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_incongruity.md)
  read the sentiment lexicon,
  [`emoji_risk()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_risk.md)
  the ambiguity table built from it, and
  [`emoji_emotion()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_emotion.md)
  the emotion lexicon: `U+203C U+FE0F` scores `0` under the first four
  and `1` under
  [`emoji_emotion()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_emotion.md).
  `emoji_score(lexicon = )` can be anything you registered.

- `.emoji_sentiment` is the mean over every emoji in the row from
  [`emoji_sentiment()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sentiment.md),
  but over only the trailing run from
  [`emoji_incongruity()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_incongruity.md)
  with `where = "final"`.

So
[`emoji_sentiment()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sentiment.md)
followed by
[`emoji_emotion()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_emotion.md)
leaves a `.emoji_n_scored` describing the emotion lexicon beside a
`.emoji_sentiment` that does not. Rename the first result's column
before adding the second, or keep the two tables apart.

`group` always refers to the Unicode top-level category (the term used
by Unicode's own `emoji-test.txt`, which the catalogue is built from).
Every glyph-to-metadata join is normalised through a codepoint key that
strips the `U+FE0F` variation selector, so qualified and unqualified
emoji forms resolve identically in every verb.

## Rates and their denominators

**Every rate tidyEmoji returns ships with the numerator and the
denominator it was computed from**, so a user can fit a count model (a
Poisson or negative binomial regression of the count with the
denominator as its exposure) instead of a linear model on a ratio.
[`emoji_ratio()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_ratio.md)
returns `.emoji_codepoints` and `.emoji_n_char` beside `.emoji_ratio`,
[`emoji_density()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_density.md)
returns `.emoji_n_char` and `.emoji_n_token` beside its two densities,
[`emoji_trend()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_trend.md)
returns `n_period` beside `share`, and
[`emoji_coverage()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_coverage.md)
returns the counts beside both coverages. Where a table already carries
every count a share is built from, as
[`emoji_seasonality()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_seasonality.md)
and
[`emoji_version_profile()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_version_profile.md)
do, the denominator is the column's total.

This matters more than it sounds. Emoji counts are compositional (shares
of a document's total) and heavily zero-inflated, and the log-ratio
transforms compositional analysis depends on are undefined at zero, so a
bare quotient pushes the analyst into the modelling error. tidyEmoji
offers no `clr` or `ilr` transform, because zero replacement is a
methodological choice that belongs to the analysis (compositions and
zCompositions make it properly), but it returns what such a choice
needs. A new verb is held to the same rule.

## Detection

Detection is grapheme-aware: a skin-tone modifier or a zero-width-joiner
sequence (a family, a couple, a profession) stays intact as one emoji,
and every verb asks the same question, so counts agree across the
package.

**What counts as an emoji is decided by the catalogue**, Unicode's own
`emoji-test.txt` for the version
[`emoji_unicode_version()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_unicode_version.md)
reports, bundled with the package.
[`emoji_properties()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_properties.md)
shows what it records about any glyph. Until 0.6.0 the catalogue was the
table inside the emoji package, which stayed at Emoji 16.0 through two
Unicode releases, so the 182 emoji added in 17.0 and 18.0 were
invisible; they are detected now. A corpus re-run under 0.6.0 can
therefore report more emoji than it did, and because of the two repairs
below, it can also report fewer.

There is one systematic exclusion, and it is worth knowing before you
read a count. Some code points are emoji only in their
*emoji-presentation* form, that is only when the variation selector
`U+FE0F` is present. The best-known is the heart: `U+2764 U+FE0F` is
detected, the bare `U+2764` is not, and several keyboards emit the bare
form. Across the catalogue 1272 spellings carry `U+FE0F`, and 216 of
those become undetectable if it is dropped: in the bundled sentiment
lexicon, 57 of the scorable glyphs. Counted the other way round, 212 of
the catalogue's 5244 spellings are themselves undetectable; the two
figures measure different things and both are right.

The selector does not always go at the end. For 200 of those 212 it
does, so appending `U+FE0F` is what makes them detectable. The
exceptions are the 12 keycap sequences – `#`, `*` and `0` to `9`
followed by the enclosing keycap mark `U+20E3` – where the selector
belongs *between* the two: `U+0031 U+FE0F U+20E3` is detected and
`U+0031 U+20E3 U+FE0F` is not. Inserting `U+FE0F` after the first code
point is the rule that repairs all 212.

**`presentation = "any"` reads them as they are**, on every verb that
counts, scores or rewrites emoji, without your having to repair the
text: all 212 except three. The default does not, and that is deliberate
rather than an oversight: the same set contains `U+00A9`, `U+00AE` and
`U+2122`, so matching them would count the copyright sign in a legal
footer as emoji use, which is why `"any"` leaves those three out. The
default stays `"emoji"`, because widening it would silently recount
every corpus already analysed;
[`emoji_coverage()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_coverage.md)
reports what the choice adds. Detection is the only thing affected; the
join is not. Every glyph-to-metadata lookup strips `U+FE0F` first, so if
you hand a bare `U+2764` to
[`as_emoji_name()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/as_emoji_name.md),
[`emoji_sentiment()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sentiment.md)'s
lexicon or
[`emoji_ambiguity()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_ambiguity.md),
it resolves exactly like the qualified form.

Joined sequences are unaffected either way. Unicode lists several
spellings of a zero-width-joiner sequence – fully qualified, and shorter
forms with the selectors omitted – and a shorter one can leave an
undetectable component in the middle. Detection repairs those: **every
fully-qualified and minimally-qualified spelling in the catalogue is
read as exactly one emoji**, so `U+2764 U+200D U+1F525` is "heart on
fire" rather than "fire" even with its selectors stripped.

Two things are emoji *material* without being emoji, and since 0.6.0 no
verb counts them:

- **A skin-tone swatch or hair component standing alone.** A modifier
  applied to a base that cannot take one, as in `U+1F600 U+1F3FB`,
  leaves the swatch with nothing to modify. That is one emoji, the
  grinning face, and a swatch; until 0.6.0 it was counted as two emoji,
  the second named "light skin tone" in group `"Component"`.

- **Regional indicators that spell no flag.** Any two regional
  indicators form one grapheme cluster, so `U+1F1FD U+1F1FD` ("XX") used
  to be read as an emoji with no name, as did a lone indicator. Only 259
  of the 676 possible pairs are flags in the catalogue; anything else is
  not an emoji. Subdivision flags are tag sequences, not pairs, and are
  unaffected.

Neither is silently discarded.
[`emoji_summary()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_summary.md)
counts both, in `n_orphan_components` and `n_invalid_flags`, so a corpus
whose count fell can be explained, and
[`emoji_country()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_country.md)
reports a stray pair with its glyph and no country code. The verbs that
rewrite text treat them as before 0.6.0
(`emoji_sanitize(policy = "strip")` still removes a swatch, and
[`emoji_to_text()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_to_text.md)
still names it), because what changed is what is *counted*, and a swatch
left in a stripped column would still be a swatch.

Since 0.7.0 the catalogue decides two more cases, and what a reader sees
decides how a sequence splits:

- **A symbol with a stray `U+FE0F` is an emoji only if the catalogue
  lists it.** The detection regex, inherited from the emoji package,
  accepts any pictographic code point followed by `U+FE0F`, a
  presentation sequence Unicode defines for only some of them, so a
  black star (`U+2605`), a chess piece or a playing card with a selector
  after it came back as an emoji with no name: 1,111 code points in all.
  No verb counts such a span now, and the verbs that rewrite text treat
  it as before.

- **A zero-width-joiner sequence Unicode does not recommend counts as
  its parts.** Segmentation joins any two pictographs a `U+200D` stands
  between, and nothing asked whether the result is a recommended
  sequence. Adult, girl and boy joined is not one: until 0.7.0 it was
  one emoji with no name, and now it is the three emoji nearly every
  platform draws, the longest catalogued parts read left to right. The
  verbs that rewrite text keep it whole, so `"strip"` removes the
  joiners with it and `"name"` names the parts in order. Microsoft's
  ninja-cat sequences (a cat joined to a laptop, a dragon, a rocket and
  three more) draw as one glyph on Windows and as a cat beside an object
  everywhere else, and here they count as the cat and the object, so a
  corpus written on Windows holds more emoji than its writers saw.

- **A request for the text form is honoured.** `U+FE0E` after a glyph
  asks for its text presentation, a sequence Unicode's
  `emoji-variation-sequences.txt` defines for 371 bases. Under the
  default `presentation = "emoji"` such a glyph is not an emoji, exactly
  as a bare `U+2764` is not, and the verbs that rewrite text leave it as
  text; under `"any"` it counts, with the selector inside the span, so
  `"strip"` removes all of it. Until 0.7.0 the 152 bases whose default
  is emoji (a watch, a star, the zodiac signs) and nine that take a skin
  tone (the index pointing up, the victory hand and seven more) were
  counted despite the request.

[`emoji_summary()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_summary.md)
counts the first two kinds in `n_unlisted`, so a count that moved
between versions can be explained.

ASCII emoticons such as `:)` are not emoji and are never detected, so a
study of the move from emoticons to emoji, which needs both in one
denominator, has to count the emoticons itself.

## Which spelling comes back

Two spellings of one emoji, differing only by `U+FE0F`, are one emoji to
every lookup: the name, the score, the category and the type all resolve
through a key that strips the selector. They are not always one *row*. A
verb that reports a glyph either hands back the spelling it found or
collapses both onto the catalogue's, and which it does follows from what
the verb is for:

- **The spelling as found**:
  [`emoji_frequency()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_frequency.md),
  [`top_n_emojis()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/top_n_emojis.md),
  [`emoji_tokens()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_tokens.md),
  [`emoji_extract_nest()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_extract_nest.md),
  [`emoji_extract_unnest()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_extract_unnest.md)
  and
  [`emoji_context()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_context.md).
  These report occurrences, and an occurrence is the text you actually
  had.

- **Collapsed onto one**:
  [`emoji_pairs()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_pairs.md),
  [`emoji_cooccurrence()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_cooccurrence.md),
  [`emoji_ngrams()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_ngrams.md),
  [`emoji_dfm()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_dfm.md),
  [`emoji_collocations()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_collocations.md),
  [`emoji_trend()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_trend.md),
  [`emoji_adoption_lag()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_adoption_lag.md)
  and
  [`emoji_incongruity_profile()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_incongruity_profile.md).
  These build an item, a node, a feature or a series, and two spellings
  of one emoji are one of those.
  [`emoji_turnover()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_turnover.md)
  and
  [`emoji_version_profile()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_version_profile.md)
  count the same way in their `n_types`, without reporting a glyph at
  all.

A corpus holding both spellings shows the difference in one line:
[`emoji_frequency()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_frequency.md)
returns two rows of `n = 1` where
[`emoji_cooccurrence()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_cooccurrence.md)
returns one node of `n = 2`. Nothing is lost either way, and the two
sides line up on the name, which is the same for both spellings:
[`emoji_frequency()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_frequency.md)
already carries it, and
[`as_emoji_name()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/as_emoji_name.md)
supplies it for a glyph column of your own.

This is only ever about spellings of the *same* emoji. Skin tones,
genders and the members of a ZWJ sequence are different emoji and stay
apart in every verb.

## Grouped data frames

Grouping is respected where it can be, and reported where it cannot. The
verbs that work a row at a time – the ones that add `.emoji_*` columns,
and the ones that keep or expand rows – carry the input's grouping
through to their result, exactly as
[`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html)
and
[`dplyr::filter()`](https://dplyr.tidyverse.org/reference/filter.html)
do, so a `group_by()` upstream still means something to a `summarise()`
downstream. The verbs that pool across rows –
[`emoji_frequency()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_frequency.md),
[`emoji_dfm()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_dfm.md),
[`emoji_pairs()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_pairs.md),
the time series, and the other corpus-level summaries – cannot honour
groups yet: they warn and return a single corpus-wide answer. Splitting
the data yourself, or passing a `doc_id` where the verb offers one, is
the way to get per-group results today.

## See also

Useful links:

- <https://pursuitofdatascience.github.io/tidyEmoji/>

- <https://github.com/PursuitOfDataScience/tidyEmoji>

- Report bugs at
  <https://github.com/PursuitOfDataScience/tidyEmoji/issues>

## Author

**Maintainer**: Youzhi Yu <yuyouzhi666@icloud.com>

Authors:

- Youzhi Yu <yuyouzhi666@icloud.com>

Other contributors:

- Unicode, Inc. (Unicode emoji and character data in R/sysdata.rda)
  \[copyright holder\]

- OpenAssistant contributors (OASST2 example data in data/oasst\_\*.rda)
  \[copyright holder\]
