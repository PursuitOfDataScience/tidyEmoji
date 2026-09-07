# Keep only the rows whose text contains emoji

`emoji_filter()` returns the rows of `data` whose text column contains
at least one emoji, preserving every original column. `emoji_tweets()`
is a synonym retained for backward compatibility.

## Usage

``` r
emoji_filter(data, text)

emoji_tweets(data, text)
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

## Value

A tibble containing only the rows with at least one emoji, with every
original column kept. A grouped input stays grouped, as it would through
[`dplyr::filter()`](https://dplyr.tidyverse.org/reference/filter.html).

## See also

[`emoji_summary()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_summary.md)
for the counts this filter is derived from;
[`emoji_ratio()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_ratio.md)
to find the rows that are *only* emoji;
[`emoji_extract_unnest()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_extract_unnest.md)
and
[`emoji_tokens()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_tokens.md)
for the emoji themselves.

## Examples

``` r
df <- data.frame(text = c("hi \U0001f600", "no emoji", "bye \U0001f44b"))
emoji_filter(df, text)
#> # A tibble: 2 × 1
#>   text  
#>   <chr> 
#> 1 hi 😀 
#> 2 bye 👋
```
