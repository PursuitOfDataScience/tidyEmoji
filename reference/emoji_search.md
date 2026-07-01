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
with `, `).

## Examples

``` r
emoji_search("happy")
#> # A tibble: 27 × 5
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
#> 10 ☺     smiling face                    smiling_face          Smileys … happy  
#> # ℹ 17 more rows
emoji_search("heart")
#> # A tibble: 254 × 5
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
#> # ℹ 244 more rows
```
