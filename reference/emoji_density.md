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

`data`, as a tibble, with added columns `.emoji_n`, `.emoji_per_char`
(emoji per character, i.e. per code point, of text) and
`.emoji_per_token` (emoji per whitespace-delimited token). A token is a
maximal run of characters outside Unicode's `White_Space` property; see
[`emoji_ratio()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_ratio.md)
for the exact set, which does not vary with the locale.

## Details

"Character" here means *code point*, the unit
[`nchar()`](https://rdrr.io/r/base/nchar.html) counts, so a
multi-code-point emoji inflates the denominator by all of its code
points. The same visible text therefore gives different answers
depending on how the emoji is built: `"hi <emoji>"` is four graphemes
either way, but `.emoji_per_char` is 0.25 for a single-code-point
smiley, 0.200 for a two-code-point flag and 0.100 for a seven-code-point
ZWJ family. It is not exotic – 115 of the 560 emoji-bearing rows in the
corpus behind the introduction vignette contain a multi-code-point
emoji.

This is the same basis
[`emoji_ratio()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_ratio.md)
uses and states, and the opposite of the one
[`emoji_position()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_position.md)
uses: `.emoji_rel_position` counts each emoji as one position, because a
proportion of the message has to. If you want a density that does not
move with an emoji's internal length, `.emoji_per_token` is immune – all
three examples above give 0.5.

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
