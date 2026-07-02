# Co-occurring emoji pairs

`emoji_pairs()` returns a tidy edge list of the emoji that appear
together in the same document: one row per pair with the number of
documents in which the pair co-occurs. By default every row of `data` is
a document; give `doc_id` to treat all rows sharing an id (a
conversation, a user, a day) as one document. The output mirrors
`widyr::pairwise_count()` (`item1`, `item2`, `n`) and pipes straight
into `igraph::graph_from_data_frame()`, tidygraph or ggraph.

## Usage

``` r
emoji_pairs(data, text, doc_id = NULL, directed = FALSE, sort = TRUE)
```

## Arguments

- data:

  A data frame or tibble containing a text column.

- text:

  The text column to scan, supplied unquoted.

- doc_id:

  Optional unquoted column identifying documents. Rows sharing a value
  are treated as one document. Default: each row is a document.

- directed:

  If `TRUE`, pairs are ordered by first appearance: a document where the
  tears-of-joy emoji appears before the heart-eyes emoji counts towards
  (tears-of-joy, heart-eyes), not the reverse. Default `FALSE`
  (unordered pairs, with `item1` sorted before `item2`).

- sort:

  If `TRUE` (default), sort by descending `n` (ties broken by `item1`,
  `item2` so the order is deterministic).

## Value

A tibble with columns `item1`, `item2` and `n`. Empty (but typed) when
no document contains two distinct emoji.

## Details

Glyphs are canonicalised through the package's codepoint key, so
qualified and unqualified forms of the same emoji (with/without
`U+FE0F`) count as one node. Pairs are between *distinct* emoji: repeats
of the same emoji in a document do not pair with themselves (see
[`emoji_cooccurrence()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_cooccurrence.md)
for the diagonal).

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
