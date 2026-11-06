# Search emoji by keyword, name or shortcode

`emoji_search()` finds emoji whose Unicode keywords, name or shortcodes
match a query (case-insensitive, substring match). It returns a tidy
tibble of matches with the glyph, name, shortcode, category and the
matching keywords, ready for further inspection or piping into other
verbs.

## Usage

``` r
emoji_search(query)
```

## Arguments

- query:

  A search string, matched as a case-insensitive substring against
  keywords, name and shortcodes.

## Value

A tibble with columns `emoji`, `name`, `shortcode`, `group` and
`keyword` (the keywords of the emoji that contained the match, collapsed
with `, `). `keyword` is the empty string, not `NA`, when the query
matched the name or a shortcode rather than a keyword. `shortcode` *is*
`NA` when the matched spelling has no alias; see Details.

## Details

`shortcode` is the *matched row's* first alias, and it is `NA` when the
matched spelling has none: 189 of the catalogue's 5244 rows carry no
alias of their own, all of them spellings with a selector left out, so a
search that hits one (7 of the 235 rows `emoji_search("face")` returns,
for instance) has nothing to put in that column. The Emoji 17.0 and 18.0
additions, which the emoji package's aliases and keywords stop short of,
have emojibase's shortcodes and CLDR's keywords since 0.7.0, so they are
found like any other emoji. Use the `emoji` column for the 189, or
[`as_emoji_shortcode()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/as_emoji_name.md),
which is keyed on the emoji rather than on the row and so can borrow the
alias of the glyph's other spelling. For the same reason the two can
disagree even when both answer – see
[`as_emoji_shortcode()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/as_emoji_name.md).

Every non-`NA` `shortcode` is a token
[`text_to_emoji()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/text_to_emoji.md)
reads, and it recovers the matched row's emoji exactly.
[`as_emoji()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/as_emoji_name.md)
resolves a bare string by Unicode name first, so for the 17 strings that
name one emoji and alias another it returns the emoji of that *name*
rather than the row you searched. They are `calendar`, `camel`, `cat`,
`cow`, `dog`, `horse`, `kiss`, `mouse`, `pig`, `rabbit`, `satellite`,
`snowman`, `sunglasses`, `tiger`, `train`, `umbrella` and `whale`; that
is the complete set, not a sample of it. See
[`as_emoji()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/as_emoji_name.md)
for why.

## See also

[`text_to_emoji()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/text_to_emoji.md)
to turn `shortcode` back into a glyph;
[`as_emoji_name()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/as_emoji_name.md)
for the name of a glyph.

## Examples

``` r
emoji_search("happy")
#> # A tibble: 55 × 5
#>    emoji name                            shortcode             group     keyword
#>    <chr> <chr>                           <chr>                 <chr>     <chr>  
#>  1 😀    grinning face                   grinning              Smileys … happy  
#>  2 😃    grinning face with big eyes     smiley                Smileys … happy  
#>  3 😄    grinning face with smiling eyes smile                 Smileys … happy  
#>  4 😁    beaming face with smiling eyes  grin                  Smileys … happy  
#>  5 😆    grinning squinting face         laughing              Smileys … happy  
#>  6 🤣    rolling on the floor laughing   rofl                  Smileys … happy  
#>  7 😂    face with tears of joy          joy                   Smileys … happy  
#>  8 🙂    slightly smiling face           slightly_smiling_face Smileys … happy  
#>  9 😇    smiling face with halo          innocent              Smileys … happy  
#> 10 ☺️     smiling face                    relaxed               Smileys … happy  
#> # ℹ 45 more rows
emoji_search("heart")
#> # A tibble: 457 × 5
#>    emoji name                         shortcode                    group keyword
#>    <chr> <chr>                        <chr>                        <chr> <chr>  
#>  1 😉    winking face                 wink                         Smil… heartb…
#>  2 🥰    smiling face with hearts     smiling_face_with_three_hea… Smil… heart,…
#>  3 😍    smiling face with heart-eyes heart_eyes                   Smil… heart-…
#>  4 😘    face blowing a kiss          kissing_heart                Smil… heart  
#>  5 😻    smiling cat with heart-eyes  heart_eyes_cat               Smil… heart,…
#>  6 💌    love letter                  love_letter                  Smil… heart  
#>  7 💘    heart with arrow             cupid                        Smil… heart  
#>  8 💝    heart with ribbon            gift_heart                   Smil… heart  
#>  9 💖    sparkling heart              sparkling_heart              Smil… heart  
#> 10 💗    growing heart                heartpulse                   Smil… heart,…
#> # ℹ 447 more rows
```
