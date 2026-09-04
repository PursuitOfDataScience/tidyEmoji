# Emoji co-occurrence counts, with an optional diagonal

`emoji_cooccurrence()` is
[`emoji_pairs()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_pairs.md)
under another name, with one addition: `diagonal = TRUE` also returns
the `item1 == item2` rows, whose `n` is the number of documents
containing that emoji (the diagonal of the co-occurrence matrix, i.e.
its document frequency).

## Usage

``` r
emoji_cooccurrence(data, text, doc_id = NULL, diagonal = FALSE, sort = TRUE)
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

- doc_id:

  Optional unquoted column identifying documents. Rows sharing a value
  are treated as one document. Default: each row is a document.

- diagonal:

  If `TRUE`, include one `item1 == item2` row per emoji with its
  document frequency. Default `FALSE`.

- sort:

  If `TRUE` (default), sort by descending `n` (ties broken by `item1`,
  `item2` so the order is deterministic).

## Value

A tibble with columns `item1`, `item2` and `n`.

## See also

[`emoji_pairs()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_pairs.md),
[`emoji_ngrams()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_ngrams.md).

## Examples

``` r
df <- data.frame(text = c("\U0001f602\U0001f60d", "\U0001f602"))
emoji_cooccurrence(df, text, diagonal = TRUE)
#> # A tibble: 3 × 3
#>   item1 item2     n
#>   <chr> <chr> <int>
#> 1 😂    😂        2
#> 2 😂    😍        1
#> 3 😍    😍        1
```
