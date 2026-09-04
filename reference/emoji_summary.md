# Summarise emoji presence in a text column

`emoji_summary()` reports how many entries in a text column contain at
least one emoji, alongside the total number of entries. An entry is
counted once regardless of how many emoji it holds.

## Usage

``` r
emoji_summary(data, text)
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

## Value

A one-row tibble with columns `n_with_emoji` (entries containing at
least one emoji) and `n_total` (all entries).

## See also

[`emoji_filter()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_filter.md)
to keep the emoji-bearing rows themselves.

## Examples

``` r
df <- data.frame(text = c("I love R \U0001f600",
                          "no emoji here",
                          "flags \U0001f3c1\U0001f600"))
emoji_summary(df, text)
#> # A tibble: 1 × 2
#>   n_with_emoji n_total
#>          <int>   <int>
#> 1            2       3
```
