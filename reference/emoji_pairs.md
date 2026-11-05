# Co-occurring emoji pairs

`emoji_pairs()` returns a tidy edge list of the emoji that appear
together in the same document: one row per pair with the number of
documents in which the pair co-occurs. By default every row of `data` is
a document; give `doc_id` to treat all rows sharing an id (a
conversation, a user, a day) as one document. The output mirrors
`widyr::pairwise_count()` (`item1`, `item2`, `n`) and pipes straight
into
[`igraph::graph_from_data_frame()`](https://r.igraph.org/reference/graph_from_data_frame.html),
tidygraph or ggraph.

## Usage

``` r
emoji_pairs(
  data,
  text,
  doc_id = NULL,
  directed = FALSE,
  sort = TRUE,
  measure = c("count", "ppmi", "log_odds", "dice"),
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

- doc_id:

  Optional unquoted column identifying documents. Rows sharing a value
  are treated as one document. Default: each row is a document.

  The result has a row per pair, so it grows with the *square* of the
  distinct emoji in a document: a day or a conversation is cheap, and
  pooling a whole corpus under one id is not. 800 distinct emoji in one
  document is 319,600 pairs and a few seconds; all 3963 would be 7.9
  million.

- directed:

  If `TRUE`, pairs are ordered by first appearance: a document where the
  tears-of-joy emoji appears before the heart-eyes emoji counts towards
  (tears-of-joy, heart-eyes), not the reverse. Default `FALSE`
  (unordered pairs, with `item1` sorted before `item2`).

- sort:

  If `TRUE` (default), sort by descending `measure` (by descending `n`
  for `"count"`; ties broken by `n`, then `item1`, `item2`, so the order
  is deterministic). `FALSE` sorts by `item1` then `item2` instead,
  which is still a fixed order, computed in the C locale, not the order
  the pairs happened to be counted in.

- measure:

  `"count"` (default) for the raw co-occurrence counts, or an
  association measure to add as a column and sort by: `"ppmi"`,
  `"log_odds"` or `"dice"`. See *Counts are not associations*.

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

A tibble with columns `item1`, `item2` and `n`, plus a column named
after `measure` unless it is `"count"`. Empty (but typed) when no
document contains two distinct emoji.

## Details

Glyphs are canonicalised through the package's codepoint key, so
qualified and unqualified forms of the same emoji (with/without
`U+FE0F`) count as one node. Pairs are between *distinct* emoji: repeats
of the same emoji in a document do not pair with themselves (see
[`emoji_cooccurrence()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_cooccurrence.md)
for the diagonal).

## Counts are not associations

Most emoji pairs in a real corpus are seen once: on the corpus behind
the introduction vignette, 200 of the 213 edges (93.9%) have `n = 1`. A
graph drawn from raw counts is mostly noise with a layout, and the
common emoji pair with everything simply because they are common.
`measure` scores each pair against what its two emoji's frequencies
predict, over documents: `N` is the number of documents holding at least
one emoji, `n1` and `n2` the number holding each item, and `n` the
number holding both.

- `"ppmi"` is positive pointwise mutual information,
  `max(0, log(n * N / (n1 * n2)))`: how much more often the two appear
  together than chance, floored at "no more often".

- `"log_odds"` is the log odds ratio of the two-by-two table of
  documents, with half a document added to every cell so a pair that
  never appears apart stays finite.

- `"dice"` is `2 * n / (n1 + n2)`, from 0 (never together) to 1 (never
  apart); unlike the other two it does not favour rare pairs.

`N` counts only documents with an emoji, so adding emoji-free rows to a
corpus changes no measure. Under `directed = TRUE`, `n` counts documents
where `item1` comes first, and the measures score that ordered event
against the same marginals. For a network, filter on a frequency
threshold as well as on the measure, so the edges kept are both strong
and seen more than once.

## See also

[`emoji_cooccurrence()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_cooccurrence.md)
for the same counts with an optional diagonal;
[`emoji_ngrams()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_ngrams.md)
for consecutive sequences.

## Examples

``` r
df <- data.frame(text = c("fun \U0001f602\U0001f60d",
                          "\U0001f602\U0001f60d\U0001f389",
                          "just \U0001f602"))
emoji_pairs(df, text)
#> # A tibble: 3 × 3
#>   item1 item2     n
#>   <chr> <chr> <int>
#> 1 😂    😍        2
#> 2 🎉    😂        1
#> 3 🎉    😍        1
emoji_pairs(df, text, directed = TRUE)
#> # A tibble: 3 × 3
#>   item1 item2     n
#>   <chr> <chr> <int>
#> 1 😂    😍        2
#> 2 😂    🎉        1
#> 3 😍    🎉        1
```
