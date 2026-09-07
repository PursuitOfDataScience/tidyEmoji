# Versions behind an emoji analysis, in one row

`emoji_provenance()` reports every version an emoji result depends on:
tidyEmoji itself, the emoji package supplying the reference table, the
Unicode emoji version that table reflects, the size of that table, and
the bundled lexicons. It is meant to be pasted into a methods section or
stored beside a result.

## Usage

``` r
emoji_provenance()
```

## Value

A one-row tibble with columns `tidyEmoji`, `emoji_pkg`, `unicode_emoji`,
`n_emoji` (rows of the reference table – see Details),
`sentiment_lexicon`, `emotion_lexicon` and `R`.

## Details

None of these are cosmetic. A glyph released after your emoji package
was built is not detected at all; a lexicon covers a few hundred of the
thousands of emoji that exist; and "we analysed emoji sentiment" without
a lexicon name is not a reproducible statement. See
[`emoji_lexicons()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_lexicons.md)
for the lexicons in detail and
[`emoji_unicode_version()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_unicode_version.md)
for the Unicode version on its own.

`n_emoji` counts **rows of the reference table**, which are spellings,
not distinct emoji. With emoji 16.0.0 it is 5042, and those 5042 rows
carry only 3790 distinct code-point keys, because an emoji whose
presentation can be selected appears both with and without `U+FE0F`. A
methods section reporting "5042 emoji" therefore overstates the
vocabulary by the 1252 duplicate spellings;
`length(unique(emoji_reference()$key))` is the count of distinct emoji,
and 212 of the 5042 spellings are not detectable in text as written at
all (see
[emoji_sentiment_lexicon](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sentiment_lexicon.md)
for why). No *emoji* is lost to that: every one of the 3790 keys is
reachable through at least one detectable spelling. The two lexicon
strings count their tables' rows the same way.

## See also

[`emoji_unicode_version()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_unicode_version.md),
[`emoji_unicode_releases()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_unicode_releases.md),
[`emoji_lexicons()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_lexicons.md).

## Examples

``` r
emoji_provenance()
#> # A tibble: 1 × 7
#>   tidyEmoji emoji_pkg unicode_emoji n_emoji sentiment_lexicon    emotion_lexicon
#>   <chr>     <chr>     <chr>           <int> <chr>                <chr>          
#> 1 0.4.0     16.0.0    16.0             5042 novak2015 (969 emoj… emotag1200 (15…
#> # ℹ 1 more variable: R <chr>
```
