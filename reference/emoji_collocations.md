# Which words keep company with which emoji

`emoji_collocations()` counts the words that appear near each emoji
across a corpus and scores the association with pointwise mutual
information. It is the corpus-derived alternative to importing a fixed
sense inventory: the senses come from *your* texts, so they cannot be
stale and carry no licence baggage.

## Usage

``` r
emoji_collocations(
  data,
  text,
  window = 5,
  min_n = 3,
  measure = c("pmi", "count", "ppmi", "dice", "logdice", "llr", "tscore"),
  presentation = "emoji"
)
```

## Arguments

- data:

  A data frame or tibble containing a text column. Grouped data frames
  are accepted. The verbs that work a row at a time (adding columns, or
  keeping and expanding rows) carry the grouping through to their
  result, as
  [`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html)
  and
  [`dplyr::filter()`](https://dplyr.tidyverse.org/reference/filter.html)
  do. The verbs that pool across rows – the counts, the co-occurrence
  edge lists, the time series – warn that they ignore the grouping and
  return one corpus-wide answer.

- text:

  The text column to scan, supplied unquoted. Any atomic column is
  accepted and read as character, so a `factor` works and a numeric,
  `Date` or logical one simply contains no emoji. A list column – or a
  data-frame column – is refused rather than coerced, because coercing
  one deparses it and the emoji found would be in the code rather than
  in your data. What counts as an emoji is the same in every verb; see
  the *Detection* section of
  [tidyEmoji](https://pursuitofdatascience.github.io/tidyEmoji/reference/tidyEmoji-package.md)
  for the one case that surprises people, code points that are emoji
  only when they carry `U+FE0F`.

- window:

  Context window on each side, in words. Default `5`.

- min_n:

  Minimum number of co-occurrences for a pair to be reported. Default
  `3`.

- measure:

  The association measure to sort by: `"pmi"` (default), `"count"`,
  `"ppmi"`, `"dice"`, `"logdice"`, `"llr"` or `"tscore"`. See *Choosing
  an association measure*.

- presentation:

  Which code points count as emoji: `"emoji"` (the default) or `"any"`.

  - `"emoji"` requires emoji presentation, so `U+2764 U+FE0F` is an
    emoji and the bare `U+2764` is not. This is the default and it will
    stay the default: widening it would silently recount every corpus
    already analysed.

  - `"any"` also reads the text-presentation spellings Unicode lists for
    an emoji (the bare heart, `U+263A`, `U+2714`, a keycap without its
    selector), because several keyboards emit them. It never reads the
    copyright, registered and trade-mark signs (`U+00A9`, `U+00AE`,
    `U+2122`), which are typography far more often than they are emoji.

  `"any"` only ever adds occurrences: everything `"emoji"` finds, it
  finds too, in the same place.
  [`emoji_coverage()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_coverage.md)
  reports how many it adds and how many of those a lexicon can score,
  which is the cost of the choice in one number. Every verb that counts,
  scores or rewrites the emoji in a text column takes this argument, so
  counts still agree across the package for whichever value you use. The
  flag verbs do not need it, since a flag has no text-presentation form.

## Value

A tibble with columns `emoji`, `word`, `n` (co-occurrences) and `pmi`,
shaped like `widyr::pairwise_count()` output so it drops into existing
tidytext workflows, plus a column named after `measure` when it is
neither `"pmi"` nor `"count"`. Rows are sorted by `measure` descending,
then by `n` descending (by `pmi` when `measure = "count"`), then by the
glyph and the word, so the order is fully determined. Ties in `pmi` are
common: every pair seen the same number of times with the same marginals
scores alike.

## Details

Each emoji occurrence contributes its context window (see
[`emoji_context()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_context.md)).
A word is counted once per occurrence however often it repeats inside
that window. Words are lower-cased and stripped of leading and trailing
characters that are not letters, digits or combining marks, and a token
left holding no letter and no digit at all is not a word. All three
rules read Unicode's own tables rather than the session's locale, so a
corpus in any script gives the same answer wherever it is run. No
stopword list is applied, because which stopwords are right is a
decision for your analysis, not for this package – filter the result
with tidytext's `stop_words` if you want one.

PMI is `log(n(e, w) * N / (n(e) * n(w)))`, with `N` the total number of
emoji-word co-occurrence events. Marginals are computed over *all*
co-occurrences before `min_n` filters the rows, so a rare pairing is
scored against the full corpus rather than against the surviving subset.

## Choosing an association measure

PMI alone is a fragile ranking. It favours rare pairs (a word seen once
beside an emoji seen once scores the maximum), and on a real corpus it
ties constantly: on the example corpus,
[oasst_messages](https://pursuitofdatascience.github.io/tidyEmoji/reference/oasst_messages.md),
42.7% of the rows share their PMI with another row. Corpus linguistics
answers this by choosing the measure for the question, and by knowing
which kind of question it is. `measure` offers the standard ones, all
computed from the same counts as PMI, with `O` the pair's `n` and
`E = n(e) * n(w) / N` the count expected by chance:

- **Effect size**, how strongly the two are associated: `"pmi"`,
  `log(O / E)`; `"ppmi"`, the same floored at 0; `"dice"`,
  `2 * O / (n(e) + n(w))`, from 0 to 1, which does not favour rare
  pairs; and `"logdice"`, `14 + log2(dice)`, the lexicographers'
  rescaling of it, at most 14.

- **Significance**, how sure the corpus makes you that there is an
  association at all: `"llr"`, Dunning's log-likelihood ratio
  (G-squared) over the two-by-two table, negative when the pair occurs
  less often than chance; and `"tscore"`, `(O - E) / sqrt(O)`. Both grow
  with the evidence, so they favour pairs that are common as well as
  associated.

The two kinds are not substitutes: a significance measure says a
frequent pairing is real, an effect size says a rare one is strong.
Report the one that matches the claim being made. Changing `measure`
never changes which pairs are returned or their `n`; it changes the
order, and adds the measure's column.

Glyphs are canonicalised through the package's codepoint key, so
qualified and unqualified forms of the same emoji share one row.

**On a script without spaces between words this verb cannot find a
collocation at all, and it will not say so.** Its tokens are the
whitespace-delimited ones of
[`emoji_context()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_context.md),
so a Chinese, Japanese, Thai, Khmer, Lao or Burmese clause is one token:
three rows of Chinese reading "the weather is good today", "my mood is
good today" and "going to Beijing tomorrow" yield three tokens, each a
whole clause, each with `n = 1`, and nothing clears `min_n`. The same
three sentences in English yield `good`, `is` and `today` at `n = 2`.
Segment the column before it reaches this verb (see
[`emoji_context()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_context.md));
`min_n` cannot rescue a vocabulary in which every type occurs once.

## See also

[`emoji_context()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_context.md)
for the occurrence-level windows this aggregates.

## Examples

``` r
df <- data.frame(text = c("cold coffee \U0001f622",
                          "coffee again \U0001f622",
                          "warm tea \U0001f60a"))
emoji_collocations(df, text, min_n = 1)
#> # A tibble: 5 × 4
#>   emoji word       n   pmi
#>   <chr> <chr>  <int> <dbl>
#> 1 😊    tea        1 1.10 
#> 2 😊    warm       1 1.10 
#> 3 😢    coffee     2 0.405
#> 4 😢    again      1 0.405
#> 5 😢    cold       1 0.405
```
