# Emoji density per character and per token

`emoji_density()` measures how emoji-heavy each text is: the number of
emoji per character and per whitespace-delimited token. Rows with no
emoji get densities of 0; rows whose text is `NA` or empty get `NA`.

## Usage

``` r
emoji_density(data, text)
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

`data`, as a tibble, with added columns `.emoji_n`, `.emoji_per_char`
(emoji per character of text) and `.emoji_per_token` (emoji per
whitespace-delimited token).

## See also

[`emoji_position()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_position.md),
[`emoji_ratio()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_ratio.md).

## Examples

``` r
df <- data.frame(text = c("hi \U0001f600", "\U0001f600\U0001f600", "plain"))
emoji_density(df, text)
#> # A tibble: 3 × 4
#>   text  .emoji_n .emoji_per_char .emoji_per_token
#>   <chr>    <int>           <dbl>            <dbl>
#> 1 hi 😀        1            0.25              0.5
#> 2 😀😀         2            1                 2  
#> 3 plain        0            0                 0  
```
