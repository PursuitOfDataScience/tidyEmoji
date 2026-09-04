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
  measure = c("pmi", "count")
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

  The text column to scan, supplied unquoted. What counts as an emoji is
  the same in every verb; see the *Detection* section of
  [tidyEmoji](https://pursuitofdatascience.github.io/tidyEmoji/reference/tidyEmoji-package.md)
  for the one case that surprises people, code points that are emoji
  only when they carry `U+FE0F`.

- window:

  Context window on each side, in words. Default `5`.

- min_n:

  Minimum number of co-occurrences for a pair to be reported. Default
  `3`.

- measure:

  Sort order: `"pmi"` (default) or `"count"`. Both columns are always
  returned.

## Value

A tibble with columns `emoji`, `word`, `n` (co-occurrences) and `pmi`,
shaped like `widyr::pairwise_count()` output so it drops into existing
tidytext workflows.

## Details

Each emoji occurrence contributes its context window (see
[`emoji_context()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_context.md)).
A word is counted once per occurrence however often it repeats inside
that window. Words are lower-cased and stripped of leading and trailing
punctuation; no stopword list is applied, because which stopwords are
right is a decision for your analysis, not for this package – filter the
result with tidytext's `stop_words` if you want one.

PMI is `log(n(e, w) * N / (n(e) * n(w)))`, with `N` the total number of
emoji-word co-occurrence events. Marginals are computed over *all*
co-occurrences before `min_n` filters the rows, so a rare pairing is
scored against the full corpus rather than against the surviving subset.

Glyphs are canonicalised through the package's codepoint key, so
qualified and unqualified forms of the same emoji share one row.

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
