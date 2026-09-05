# Replace shortcodes with emoji (emojize)

`text_to_emoji()` returns a copy of `data` with its text column
rewritten so that every `:shortcode:` token is replaced by the
corresponding emoji glyph (the inverse of
[`emoji_to_text()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_to_text.md)
with `format = "shortcode"`, up to the presentation selector – see
Details). Shortcodes that do not match a known emoji are left unchanged.

## Usage

``` r
text_to_emoji(data, text)
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

`data`, as a tibble, with the text column rewritten in place. `NA`
entries stay `NA`.

## Details

A shortcode token is a colon, one or more of `A-Z`, `a-z`, `0-9`, `_`,
`+` or `-`, and a closing colon. Restricting the token this way means
colons used for other purposes – clock times, URLs, ratios, ordinary
punctuation – cannot swallow a following shortcode:
`"meet at 10:30 :wave:"` still emojizes the wave.

**The round trip recovers the emoji, not necessarily the same bytes.**
Like the vector helpers, both directions resolve through `emoji_key()`,
which ignores `U+FE0F`, so an unqualified glyph and its fully-qualified
form share one shortcode and this verb emits the fully-qualified (RGI)
form of the pair. Feeding the whole emoji catalogue through
`emoji_to_text(format = "shortcode")` and back therefore returns an
identical code-point key for every entry, and identical bytes for the
79% that were already fully qualified; the rest gain `U+FE0F`. A second
round trip changes nothing, so the result is stable. Use `emoji_key()`
rather than string equality when comparing before and after.

## See also

[`emoji_to_text()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_to_text.md);
[`as_emoji()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/as_emoji_name.md)
for the vector helper, which resolves a bare string by Unicode name
first and so differs from this verb on 17 strings that name one emoji
and alias another.

## Examples

``` r
df <- data.frame(text = "hi :grinning: bye :waving_hand:")
text_to_emoji(df, text)
#> # A tibble: 1 × 1
#>   text        
#>   <chr>       
#> 1 hi 😀 bye 👋

# colons elsewhere in the text do not interfere
text_to_emoji(data.frame(text = "https://example.org at 10:30 :grinning:"),
              text)
#> # A tibble: 1 × 1
#>   text                           
#>   <chr>                          
#> 1 https://example.org at 10:30 😀
```
