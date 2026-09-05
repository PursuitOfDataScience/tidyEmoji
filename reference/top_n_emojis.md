# The most frequent emoji in a text column

`top_n_emojis()` returns the `n` most frequent emoji. By default each
emoji (unicode) appears on a single row; set `duplicated = TRUE` to list
every name an emoji is known by, so glyphs that share several names
occupy several rows.

## Usage

``` r
top_n_emojis(
  data,
  text,
  n = 20,
  duplicated = FALSE,
  duplicated_unicode = lifecycle::deprecated()
)
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

  Number of emoji to return. Default `20`.

- duplicated:

  If `TRUE`, emoji with several names occupy several rows. Default
  `FALSE`.

- duplicated_unicode:

  **\[deprecated\]** Use `duplicated` instead.

## Value

A tibble with columns `emoji_name`, `unicode`, `emoji_category` and `n`,
sorted by descending `n` with ties broken by the glyph so the order is
deterministic – the same rule
[`emoji_frequency()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_frequency.md)
uses. When a tie straddles position `n` the glyph order decides which
side of the cut each emoji falls on, and a corpus with fewer than `n`
distinct emoji returns every one of them rather than padding to `n`.

## See also

[`emoji_frequency()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_frequency.md)
for the full distribution.

## Examples

``` r
df <- data.frame(text = c("\U0001f600\U0001f600\U0001f3c1", "\U0001f621"))
top_n_emojis(df, text, n = 2)
#> # A tibble: 2 × 4
#>   emoji_name     unicode emoji_category        n
#>   <chr>          <chr>   <chr>             <int>
#> 1 grinning       😀      Smileys & Emotion     2
#> 2 checkered_flag 🏁      Flags                 1
```
