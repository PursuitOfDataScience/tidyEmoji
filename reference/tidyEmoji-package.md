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
language-model pipelines. The bundled emoji sentiment lexicon is from
the Emoji Sentiment Ranking of Kralj Novak et al. (2015)
[doi:10.1371/journal.pone.0144296](https://doi.org/10.1371/journal.pone.0144296)
, released under CC BY-SA 4.0; the emotion lexicon is from EmoTag1200 of
Shoeb & de Melo (2020) <https://aclanthology.org/2020.emnlp-main.720/>,
released under the MIT licence.

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
by the underlying
[`emoji::emojis`](https://emilhvitfeldt.github.io/emoji/reference/emojis.html)
table). Every glyph-to-metadata join is normalised through a codepoint
key that strips the `U+FE0F` variation selector, so qualified and
unqualified emoji forms resolve identically in every verb.

## Detection

Detection is grapheme-aware: a skin-tone modifier or a zero-width-joiner
sequence (a family, a couple, a profession) stays intact as one emoji,
and every verb asks the same question, so counts agree across the
package.

There is one systematic exclusion, and it is worth knowing before you
read a count. Some code points are emoji only in their
*emoji-presentation* form, that is only when the variation selector
`U+FE0F` is present. The best-known is the heart: `U+2764 U+FE0F` is
detected, the bare `U+2764` is not, and several keyboards emit the bare
form. Across the reference catalogue 1252 emoji carry `U+FE0F`, and 216
of those become undetectable if it is dropped – in the bundled sentiment
lexicon, 57 of the scorable glyphs. Counted the other way round, 212 of
the catalogue's 5042 rows are spellings that are themselves
undetectable; the two figures measure different things and both are
right.

The selector does not always go at the end. For 200 of those 212 it
does, so appending `U+FE0F` is what makes them detectable. The
exceptions are the 12 keycap sequences – `#`, `*` and `0` to `9`
followed by the enclosing keycap mark `U+20E3` – where the selector
belongs *between* the two: `U+0031 U+FE0F U+20E3` is detected and
`U+0031 U+20E3 U+FE0F` is not. Inserting `U+FE0F` after the first code
point is the rule that repairs all 212.

The default does not match the bare forms, and that is deliberate rather
than an oversight: the same set contains `U+00A9`, `U+00AE` and
`U+2122`, so matching them unqualified would count the copyright sign in
a legal footer as emoji use. Detection is the only thing affected – the
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
canonical spelling in the reference table, and all but two of the
shorter ones, is read as exactly one emoji**, so `U+2764 U+200D U+1F525`
is "heart on fire" rather than "fire" even with its selectors stripped.
The two exceptions are spellings in which no component at all is
detectable, and both have a canonical form that is found.

Everything above is about what detection *misses*. It also admits two
things that are well formed but not emoji, and both flow through every
verb, so a corpus statistic can be inflated by them:

- **An invalid regional-indicator pair.** Any two regional indicators
  form one grapheme cluster, so `U+1F1FD U+1F1FD` is read as a single
  emoji even though no country has that code. It appears in
  [`emoji_frequency()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_frequency.md)
  with `name = NA`, gets a column in
  [`emoji_dfm()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_dfm.md)
  and a node in
  [`emoji_pairs()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_pairs.md).
  Only 259 of the 676 possible pairs are real, the rows of the reference
  table whose `subgroup` is `"country-flag"`; its three
  `"subdivision-flag"` rows are tag sequences, not pairs. A pair outside
  that set is in no catalogue, so
  [`emoji_frequency()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_frequency.md)
  reports it with `group = NA` as well as `name = NA`, which is the way
  to filter it out, and
  [`emoji_provenance()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_provenance.md)
  reports which catalogue you have.

- **An orphan skin-tone modifier or hair component.** A modifier applied
  to a base that cannot take one, as in `U+1F600 U+1F3FB`, leaves the
  swatch standing alone – and because the Component group is in the
  reference table it comes back *named*, as "light skin tone" in group
  `"Component"`, not as `NA`.
  [`as_emoji_type()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/as_emoji_type.md)
  labels these `"component"`, which is the way to find and drop them:
  `subset(emoji_frequency(df, text), as_emoji_type(emoji) != "component")`.

Both are defensible as raw detection and misleading as a corpus
statistic, which is why they are named here rather than silently
filtered: dropping them inside the verbs would make the emoji counts
disagree with the text.

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
do, so a
[`group_by()`](https://dplyr.tidyverse.org/reference/group_by.html)
upstream still means something to a
[`summarise()`](https://dplyr.tidyverse.org/reference/summarise.html)
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
