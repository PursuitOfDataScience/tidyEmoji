# Versions behind an emoji analysis, in one row

`emoji_provenance()` reports every version an emoji result depends on:
tidyEmoji itself, the Unicode emoji version of the catalogue it detects
against and the date of that catalogue's data file, the size of the
catalogue, the emoji package supplying the shortcodes, keywords and
detection regex, and the bundled lexicons. It is meant to be pasted into
a methods section or stored beside a result.

## Usage

``` r
emoji_provenance()
```

## Value

A one-row tibble with columns `tidyEmoji`, `emoji_pkg`, `unicode_emoji`,
`unicode_emoji_date` (the date in the header of the catalogue's data
file, a `Date`), `n_emoji` (rows of the reference table; see Details),
`sentiment_lexicon`, `emotion_lexicon` and `R`.

## Details

None of these are cosmetic. A glyph newer than the catalogue is not
detected at all; a lexicon covers a few hundred of the thousands of
emoji that exist; and "we analysed emoji sentiment" without a lexicon
name is not a reproducible statement. See
[`emoji_lexicons()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_lexicons.md)
for the lexicons in detail and
[`emoji_unicode_version()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_unicode_version.md)
for the Unicode version on its own.

**The catalogue moved in 0.6.0, so results from 0.5.0 and 0.6.0 differ,
and this row is how to tell which you have.** The catalogue is now
Unicode's `emoji-test.txt` rather than the table inside emoji, which
takes it from Emoji 16.0 to 18.0 and makes 182 more emoji detectable. In
the other direction, a skin-tone swatch standing alone and a
regional-indicator pair that is no country stopped being emoji
occurrences;
[`emoji_summary()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_summary.md)
counts both. A corpus re-run under 0.6.0 can therefore report more emoji
or fewer, and `unicode_emoji` is the column that says why.

`n_emoji` counts **rows of the reference table**, which are spellings,
not distinct emoji. With the Emoji 18.0 catalogue it is 5244, and those
5244 rows carry only 3972 distinct code-point keys, because an emoji
whose presentation can be selected appears both with and without
`U+FE0F`. A methods section reporting "5244 emoji" therefore overstates
the vocabulary by the 1272 duplicate spellings;
`length(unique(emoji_properties()$key))` is the count of distinct emoji,
nine of which are the skin-tone and hair components, which are not emoji
on their own. 212 of the 5244 spellings are not detectable in text as
written under the default `presentation` (see
[emoji_sentiment_lexicon](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sentiment_lexicon.md)
for why, and
[`emoji_summary()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_summary.md)
for `presentation = "any"`). No *emoji* is lost to that: every one of
the 3963 keys that is not a component is reachable through at least one
detectable spelling. The two lexicon strings count their tables' rows
the same way.

## See also

[`emoji_unicode_version()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_unicode_version.md),
[`emoji_unicode_releases()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_unicode_releases.md),
[`emoji_lexicons()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_lexicons.md).

## Examples

``` r
emoji_provenance()
#> # A tibble: 1 × 8
#>   tidyEmoji emoji_pkg unicode_emoji unicode_emoji_date n_emoji sentiment_lexicon
#>   <chr>     <chr>     <chr>         <date>               <int> <chr>            
#> 1 0.7.0     16.0.0    18.0          2026-04-30            5244 novak2015 (969 e…
#> # ℹ 2 more variables: emotion_lexicon <chr>, R <chr>
```
