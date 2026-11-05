# How new is this corpus's emoji repertoire?

`emoji_version_profile()` breaks a corpus down by the Unicode emoji
version that introduced each glyph. A corpus written entirely in emoji
from 2015 and one full of 2023 additions look identical to a frequency
table and quite different here.

## Usage

``` r
emoji_version_profile(data, text, presentation = "emoji")
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

- presentation:

  Which code points count as emoji: `"emoji"` (the default) or `"any"`.

  - `"emoji"` requires emoji presentation, so `U+2764 U+FE0F` is an
    emoji and the bare `U+2764` is not. This is the default and it will
    stay the default: widening it would silently recount every corpus
    already analysed.

  - `"any"` also reads the text-presentation spellings Unicode lists for
    an emoji (the bare heart, `U+263A`, `U+2714`, a keycap without its
    selector), because several keyboards emit them. It never reads the
    copyright, registered and trade-mark signs (`U+00A9`, `U+00AE`,
    `U+2122`), which are typography far more often than they are emoji.

  `"any"` only ever adds occurrences: everything `"emoji"` finds, it
  finds too, in the same place.
  [`emoji_coverage()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_coverage.md)
  reports how many it adds and how many of those a lexicon can score,
  which is the cost of the choice in one number. Every verb that counts,
  scores or rewrites the emoji in a text column takes this argument, so
  counts still agree across the package for whichever value you use. The
  flag verbs do not need it, since a flag has no text-presentation form.

## Value

A tibble with one row per version, oldest first: `version`,
`version_num`, `release_date`, `n_types` (distinct emoji), `n_tokens`
(occurrences), `share_types` and `share_tokens`. Emoji whose version the
reference table does not give are pooled into one last row with
`version = NA`, after every known version rather than before them.

## Details

The version comes from the catalogue tidyEmoji detects against, so it is
capped by that catalogue's Unicode version (see
[`emoji_unicode_version()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_unicode_version.md)).
Glyphs whose version is unknown, which means any the catalogue does not
carry, such as a ZWJ sequence newer than it, are reported in a row with
`version = NA` rather than dropped. Every spelling in the catalogue
carries its emoji's version, so a fully-qualified glyph such as
`U+2764 U+FE0F` reports the same version as its unqualified form.

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
