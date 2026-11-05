# Subdivision flags in a text column, as ISO 3166-2 codes

`emoji_subdivision()` returns one row per subdivision flag in the text
(the flags of England, Scotland and Wales, and any other tag sequence of
the same shape), with the code its tag characters spell (`"GB-SCT"`)
and, for the three Unicode recommends, the name.

## Usage

``` r
emoji_subdivision(data, text)
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

A tibble with the columns of `data` plus `.emoji` (the whole tag
sequence), `.emoji_subdivision` (the ISO 3166-2 code its tags spell) and
`.emoji_subdivision_name` (the Unicode name for the three in the
catalogue, `NA` otherwise). One row per sequence, in reading order; rows
without one are dropped.

## Details

A subdivision flag is not a regional-indicator pair. It is a black flag
(`U+1F3F4`) followed by invisible tag characters spelling a subdivision
code in lower case, and a cancel tag (`U+E007F`): Scotland is the black
flag, then `g b s c t`, then the cancel tag. The code is therefore read
straight off the tags, for any well-formed sequence.

Only three such sequences are in the catalogue, `GB-ENG`, `GB-SCT` and
`GB-WLS`, and only those three are emoji the other verbs count. Any
other (`US-TX` spelled the same way, say) is valid Unicode that no major
platform draws as a flag, so it is reported here with its code and `NA`
for the name, while
[`emoji_frequency()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_frequency.md)
and the rest see only the black flag at its start. That is the honest
answer to a question the text does not settle: the sender typed a Texas
flag and the reader most likely saw a black one.

## See also

[`emoji_country()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_country.md)
for country flags;
[`emoji_flag()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_flag.md)
to convert.

## Examples

``` r
scotland <- intToUtf8(c(0x1F3F4, 0xE0067, 0xE0062, 0xE0073, 0xE0063,
                        0xE0074, 0xE007F))
df <- data.frame(text = c(paste("go", scotland), "none"))
emoji_subdivision(df, text)
#> # A tibble: 1 × 4
#>   text  .emoji .emoji_subdivision .emoji_subdivision_name
#>   <chr> <chr>  <chr>              <chr>                  
#> 1 go 🏴󠁧󠁢󠁳󠁣󠁴󠁿 🏴󠁧󠁢󠁳󠁣󠁴󠁿     GB-SCT             Scotland               
```
