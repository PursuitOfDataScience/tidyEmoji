# How new is this corpus's emoji repertoire?

`emoji_version_profile()` breaks a corpus down by the Unicode emoji
version that introduced each glyph. A corpus written entirely in emoji
from 2015 and one full of 2023 additions look identical to a frequency
table and quite different here.

## Usage

``` r
emoji_version_profile(data, text)
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

A tibble with one row per version, oldest first: `version`,
`version_num`, `release_date`, `n_types` (distinct emoji), `n_tokens`
(occurrences), `share_types` and `share_tokens`.

## Details

The version comes from the reference table tidyEmoji detects against, so
it is capped by your installed emoji package (see
[`emoji_unicode_version()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_unicode_version.md)).
Glyphs whose version is unknown – including any the reference table does
not carry – are reported in a row with `version = NA` rather than
dropped. That row is rare in practice: the upstream table records the
introducing version on only one spelling of a variation pair, and
tidyEmoji fills it across every spelling sharing a codepoint key, so a
fully-qualified glyph such as `U+2764 U+FE0F` reports the same version
as its unqualified form.

The corpus's average vintage is a weighted mean over this table, for
example
`with(profile, weighted.mean(version_num, n_tokens, na.rm = TRUE))`.

## See also

[`emoji_adoption_lag()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_adoption_lag.md)
for how quickly new emoji were picked up;
[`emoji_unicode_releases()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_unicode_releases.md)
for the date lookup.

## Examples

``` r
df <- data.frame(text = c("\U0001f600 hello", "\U0001f97a nice"))
emoji_version_profile(df, text)
#> # A tibble: 2 × 7
#>   version version_num release_date n_types n_tokens share_types share_tokens
#>   <chr>         <dbl> <date>         <int>    <int>       <dbl>        <dbl>
#> 1 1.0               1 2015-06-09         1        1         0.5          0.5
#> 2 11.0             11 2018-06-05         1        1         0.5          0.5
```
