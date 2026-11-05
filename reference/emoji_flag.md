# Convert between flag emoji and region codes

`emoji_flag()` turns a region code into its flag and a flag into its
code, element by element: `"JP"` becomes the Japanese flag, the Japanese
flag becomes `"JP"`, and `"GB-SCT"` and Scotland's flag convert the same
way. Codes are matched without regard to case.

## Usage

``` r
emoji_flag(x)
```

## Arguments

- x:

  A character vector of two-letter region codes, ISO 3166-2 subdivision
  codes (`"GB-ENG"`, `"GB-SCT"`, `"GB-WLS"`), or flag emoji.

## Value

A character vector the same length as `x`: flags where `x` held codes,
codes where it held flags, and `NA` for anything that is neither.

## Details

Each element is converted in its own direction, so one call can carry
both. A code or a flag outside the catalogue's valid set, such as
`"XX"`, `"UK"` (the code is `GB`) or a stray indicator pair, gives `NA`
rather than a made-up flag. The valid set is the 259 country flags and
three subdivision flags of the catalogue
[`emoji_unicode_version()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_unicode_version.md)
reports; see
[`emoji_country()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_country.md)
for which of the 259 are not countries.

## See also

[`emoji_country()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_country.md),
[`emoji_subdivision()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_subdivision.md).

## Examples

``` r
emoji_flag(c("JP", "fr", "GB-SCT", "XX"))
#> [1] "🇯🇵" "🇫🇷" "🏴󠁧󠁢󠁳󠁣󠁴󠁿" NA  
emoji_flag(emoji_flag(c("JP", "fr")))
#> [1] "JP" "FR"
```
