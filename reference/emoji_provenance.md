# Versions behind an emoji analysis, in one row

`emoji_provenance()` reports every version an emoji result depends on:
tidyEmoji itself, the emoji package supplying the reference table, the
Unicode emoji version that table reflects, the size of the detectable
emoji set, and the bundled lexicons. It is meant to be pasted into a
methods section or stored beside a result.

## Usage

``` r
emoji_provenance()
```

## Value

A one-row tibble with columns `tidyEmoji`, `emoji_pkg`, `unicode_emoji`,
`n_emoji`, `sentiment_lexicon`, `emotion_lexicon` and `R`.

## Details

None of these are cosmetic. A glyph released after your emoji package
was built is not detected at all; a lexicon covers a few hundred of the
thousands of emoji that exist; and "we analysed emoji sentiment" without
a lexicon name is not a reproducible statement. See
[`emoji_lexicons()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_lexicons.md)
for the lexicons in detail and
[`emoji_unicode_version()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_unicode_version.md)
for the Unicode version on its own.

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
