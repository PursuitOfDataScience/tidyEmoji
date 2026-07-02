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

  A data frame or tibble containing a text column.

- text:

  The text column to scan, supplied unquoted.

## Value

`data`, as a tibble, with added columns `.emoji_n`, `.emoji_first` and
`.emoji_last` (character positions where the first/last emoji start) and
`.emoji_rel_position` (mean relative position in `[0, 1]`). Rows without
emoji get `NA` positions.

## Details

The relative position of an occurrence starting at character `s` in a
text of `L` characters is `(s - 1) / (L - 1)` (taken as 0 when
`L <= 1`). Positions are counted in characters (code points), the same
unit as [`substr()`](https://rdrr.io/r/base/substr.html).

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
