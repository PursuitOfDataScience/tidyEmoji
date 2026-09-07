# Replace shortcodes with emoji (emojize)

`text_to_emoji()` returns a copy of `data` with its text column
rewritten so that every `:shortcode:` token is replaced by the
corresponding emoji glyph (the inverse of
[`emoji_to_text()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_to_text.md)
with `format = "shortcode"` *and its default* `wrap`, up to the
presentation selector – see Details). Shortcodes that do not match a
known emoji are left unchanged.

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
form share one shortcode and only one of the two spellings can come
back. Feeding the whole emoji catalogue through
`emoji_to_text(format = "shortcode")` and back returns an identical
code-point key for all 5042 entries and identical bytes for 79% of them.
The other 1040 differ **by `U+FE0F` alone, never by more**: they come
back as the spelling this verb's shortcode table carries. A second round
trip changes nothing, so the result is stable either way – but compare
with `emoji_key()`, never with string equality.

Which 79% is *not* the same question as which were already fully
qualified, and the two sets genuinely differ in both directions. The
bare heart (`U+2764`) survives unchanged, because that unqualified
spelling is the one `:heart:` maps to; the already-qualified man
detective (`U+1F575 U+FE0F U+200D U+2642`) does not, because it comes
back with a second selector on the gender sign. If your text holds the
*canonical* spelling of each emoji – what a keyboard emits – the round
trip is byte-exact for all 3790 of them; see
[`emoji_sanitize()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sanitize.md),
which tabulates both denominators.

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
