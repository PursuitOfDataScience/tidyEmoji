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
unquoted, and returns a tibble. Columns *added to your data* carry a
dotted `.emoji_*` prefix (`.emoji`, `.emoji_name`, `.emoji_category`,
`.emoji_sentiment`, `.emoji_n`, ...) so they will not collide with your
own columns; *new summary tibbles* (e.g.
[`emoji_frequency()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_frequency.md))
use bare names. The dotted prefix is **reserved**: a verb overwrites any
column of its own output name that is already there, without warning.
That is what makes verbs chainable and re-runnable –
[`emoji_sentiment()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sentiment.md)
then
[`emoji_position()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_position.md)
both write `.emoji_n`, and both mean the same thing – but it also means
a column of your own called `.emoji_n` will be replaced. Rename it first
if you need to keep it. `group` always refers to the Unicode top-level
category (the term used by the underlying
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
*emoji-presentation* form, that is only when followed by the variation
selector `U+FE0F`. The best-known is the heart: `U+2764 U+FE0F` is
detected, the bare `U+2764` is not, and several keyboards emit the bare
form. Across the reference catalogue 1252 emoji carry `U+FE0F`, and 216
of those become undetectable if it is dropped – in the bundled sentiment
lexicon, 57 of the scorable glyphs.

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

- Report bugs at
  <https://github.com/PursuitOfDataScience/tidyEmoji/issues>

## Author

**Maintainer**: Youzhi Yu <yuyouzhi666@icloud.com>
