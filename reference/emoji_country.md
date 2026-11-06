# Country flags in a text column, as ISO 3166-1 codes

`emoji_country()` returns one row per country flag in the text, with the
two-letter region code the flag spells and the region's name. A pair of
regional indicators that spells no valid flag (`U+1F1FD U+1F1FD` is
"XX") is returned too, with its glyph preserved and `NA` for the code,
so a stray pair is visible rather than silently dropped.

## Usage

``` r
emoji_country(data, text)
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

A tibble with the columns of `data` plus `.emoji` (the flag as it
appears in the text), `.emoji_iso2` (the two-letter code, `NA` for a
pair that spells no flag), `.emoji_country_name` and `.emoji_iso3166`
(`TRUE` where the code is an assigned ISO 3166-1 alpha-2 code, `FALSE`
for the ten above, `NA` for a pair that spells no flag). One row per
flag, in reading order; rows without one are dropped. A grouped input
stays grouped, as it does through
[`emoji_tokens()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_tokens.md).

## Details

A flag emoji is two *regional indicator* symbols, one per letter of a
region code, so the code is plain arithmetic on the code points. The
arithmetic accepts any pair, though, and only 259 pairs are flags in the
catalogue; anything else is reported with `.emoji_iso2 = NA`. That
includes a lone indicator, and it includes pairs that a bigger alphabet
soup happened to produce: indicators pair up from the start of a run, so
`XUS` reads as `XU` and a lone `S`, not as `X` and the United States,
which is also how a phone displays it.

The code is the join key, not the name, because the code is what other
packages take. Hand `.emoji_iso2` to
`countrycode::countrycode(x, "iso2c", "country.name")`, or join it to a
map's ISO column, and a corpus of flags is a choropleth. Two things to
know before you do:

- Not every valid flag is a country, and `.emoji_iso3166` says which are
  not, so you can filter before a country-level join rather than lose
  ten rows in it. Ten of the 259 flags have no assigned ISO 3166-1 code:
  `EU` (European Union) and `UN` (United Nations); `AC` (Ascension
  Island), `CP` (Clipperton Island), `CQ` (Sark), `DG` (Diego Garcia),
  `EA` (Ceuta and Melilla), `IC` (Canary Islands) and `TA` (Tristan da
  Cunha), codes ISO reserves for territories it does not list as
  countries; and `XK` (Kosovo), a user-assigned code that ISO does not
  define. A country-level tool will not map them.

- `.emoji_country_name` is the Unicode (CLDR) English name, kept for
  reading the output, and it changes between Unicode versions: three
  names did between Emoji 16.0 and 18.0. Join on the code.

Subdivision flags such as Scotland's are tag sequences rather than
indicator pairs; see
[`emoji_subdivision()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_subdivision.md).

## See also

[`emoji_flag()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_flag.md)
to convert between codes and flags,
[`emoji_subdivision()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_subdivision.md)
for England, Scotland and Wales.

## Examples

``` r
df <- data.frame(id = 1:3,
                 text = c("go \U0001f1fa\U0001f1f8 and \U0001f1ef\U0001f1f5",
                          "no flags here",
                          "stray \U0001f1fd\U0001f1fd pair"))
emoji_country(df, text)
#> # A tibble: 3 × 6
#>      id text          .emoji .emoji_iso2 .emoji_country_name .emoji_iso3166
#>   <int> <chr>         <chr>  <chr>       <chr>               <lgl>         
#> 1     1 go 🇺🇸 and 🇯🇵  🇺🇸     US          United States       TRUE          
#> 2     1 go 🇺🇸 and 🇯🇵  🇯🇵     JP          Japan               TRUE          
#> 3     3 stray 🇽🇽 pair 🇽🇽     NA          NA                  NA            
```
