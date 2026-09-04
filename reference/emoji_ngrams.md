# Consecutive emoji sequences (n-grams)

`emoji_ngrams()` slides a window of `n` over each row's emoji, in
reading order (any text between the emoji is ignored), and returns one
row per n-gram occurrence. Repeated emoji are kept: a row containing the
same emoji twice in a row yields a bigram of that emoji with itself.
This is the emoji analogue of
`tidytext::unnest_tokens(..., token = "ngrams")` and feeds sequence /
Markov-style analyses of how emoji chain together.

## Usage

``` r
emoji_ngrams(data, text, n = 2, sep = " ")
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

- n:

  Length of the n-gram window. Default `2` (bigrams).

- sep:

  Separator between the glyphs of an n-gram. Default a space.

## Value

A tibble with columns `.row_number` (position of the entry in `data`),
`.position` (where the n-gram starts within the row's emoji sequence)
and `.emoji_ngram`. Rows with fewer than `n` emoji contribute nothing.

## See also

[`emoji_pairs()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_pairs.md)
for order-free co-occurrence;
[`emoji_extract_unnest()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_extract_unnest.md)
for the underlying one-emoji-per-row form.

## Examples

``` r
df <- data.frame(text = c("\U0001f602\U0001f60d\U0001f389", "\U0001f602"))
emoji_ngrams(df, text)
#> # A tibble: 2 × 3
#>   .row_number .position .emoji_ngram
#>         <int>     <int> <chr>       
#> 1           1         1 😂 😍       
#> 2           1         2 😍 🎉       
emoji_ngrams(df, text, n = 3)
#> # A tibble: 1 × 3
#>   .row_number .position .emoji_ngram
#>         <int>     <int> <chr>       
#> 1           1         1 😂 😍 🎉    
```
