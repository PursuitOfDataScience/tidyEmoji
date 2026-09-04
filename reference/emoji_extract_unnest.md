# Emoji counts per row, in long (tidy) form

`emoji_extract_unnest()` returns one row per (row, emoji) pair with a
count, dropping rows that contain no emoji. `.row_number` refers to the
position of the entry in `data`.

## Usage

``` r
emoji_extract_unnest(data, text)
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

A tibble with columns `.row_number`, `.emoji_unicode` and
`.emoji_count`.

## Examples

``` r
df <- data.frame(text = c("hi \U0001f600\U0001f600", "none", "\U0001f44b"))
emoji_extract_unnest(df, text)
#> # A tibble: 2 × 3
#>   .row_number .emoji_unicode .emoji_count
#>         <int> <chr>                 <int>
#> 1           1 😀                        2
#> 2           3 👋                        1
```
