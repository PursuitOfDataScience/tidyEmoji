# Where do emoji sit within each text?

`emoji_position()` reports, for each row, the character position of the
first and last emoji and the mean *relative* position of all emoji
occurrences, from 0 (the very start of the text) to 1 (the very end).
The Emoji Sentiment Ranking (Kralj Novak et al., 2015) tracks the same
relative position, and it is a studied signal: emoji cluster near the
end of messages.

## Usage

``` r
emoji_position(data, text)
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

`data`, as a tibble, with added columns `.emoji_n`, `.emoji_first` and
`.emoji_last` (code-point offsets where the first/last emoji start) and
`.emoji_rel_position` (mean relative position in `[0, 1]`, counting each
emoji as one position). Rows without emoji get `NA` positions.

## Details

`.emoji_first` and `.emoji_last` are code-point offsets, the unit
[`substr()`](https://rdrr.io/r/base/substr.html) uses, so they can be
fed straight back to it.

`.emoji_rel_position` is *not* measured in code points. Each emoji
counts as one position however many code points it is built from, so an
emoji that is the last thing in the text scores 1 whether it is a
single-code-point smiley, a two-code-point flag or a seven-code-point
family. Counting code points instead put a sentence-final family emoji a
third of the way through its message. Everything that is not an emoji
still counts one position per code point, so a combining accent
elsewhere in the text counts twice; that affects the denominator only,
and only for text carrying such marks.

Positions are in *logical* (storage) order, not visual order. In a
right-to-left script an emoji that is logically last renders at the
reader's left, so "final" here means final in the string, not final on
the screen.

## See also

[`emoji_density()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_density.md)
and
[`emoji_ratio()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_ratio.md)
for intensity metrics.

## Examples

``` r
df <- data.frame(text = c("\U0001f600 leading", "trailing \U0001f600",
                          "none"))
emoji_position(df, text)
#> # A tibble: 3 × 5
#>   text        .emoji_n .emoji_first .emoji_last .emoji_rel_position
#>   <chr>          <int>        <int>       <int>               <dbl>
#> 1 😀 leading         1            1           1                   0
#> 2 trailing 😀        1           10          10                   1
#> 3 none               0           NA          NA                  NA
```
