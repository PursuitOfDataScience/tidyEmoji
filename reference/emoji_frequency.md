# Frequency of every emoji in a text column

`emoji_frequency()` counts how often each emoji appears across the whole
text column (an entry containing the same emoji twice contributes 2) and
returns a tibble sorted by descending count, with each emoji's name,
shortcode and category.

## Usage

``` r
emoji_frequency(data, text)
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

A tibble with columns `emoji`, `name`, `shortcode`, `group` and `n`,
sorted by descending `n` with ties broken by the glyph so the order is
deterministic.

## See also

[`top_n_emojis()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/top_n_emojis.md)
for just the most frequent emoji.

## Examples

``` r
df <- data.frame(text = c("\U0001f600\U0001f600", "\U0001f621"))
emoji_frequency(df, text)
#> # A tibble: 2 × 5
#>   emoji name          shortcode group                 n
#>   <chr> <chr>         <chr>     <chr>             <int>
#> 1 😀    grinning face grinning  Smileys & Emotion     2
#> 2 😡    enraged face  rage      Smileys & Emotion     1
```
