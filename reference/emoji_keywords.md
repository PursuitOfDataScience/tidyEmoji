# The keywords of each emoji, one row per keyword

`emoji_keywords()` returns the CLDR keywords attached to each glyph in
long form, one row per (glyph, keyword) pair, which is the shape a join,
a count or a word cloud wants.
[`emoji_search()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_search.md)
reads the same keywords and returns them collapsed into one string per
match.

## Usage

``` r
emoji_keywords(x = NULL)
```

## Arguments

- x:

  A character vector of glyphs. The default, `NULL`, returns every emoji
  in the catalogue, each under its canonical spelling.

## Value

A tibble with columns `emoji`, `name` and `keyword`, one row per
keyword, in the order of `x` and then of the keyword set.

## Details

**These are the English keyword sets**, from the emoji package, and
nothing in them says anything about how an emoji is read in another
language or culture. Multilingual keywords are not bundled.

The keywords come from emoji while the catalogue comes from Unicode, and
the two are not equally current: an emoji newer than emoji's own table
(every Emoji 17.0 and 18.0 addition, at the time of writing) is detected
and named but has no keywords. Such a glyph, and any string that is not
an emoji at all, gets **one row with `keyword = NA`**, never a row with
an empty string, so `is.na(keyword)` is the test for "no vocabulary".

Keywords belong to the emoji, not to one spelling of it, so the bare and
the qualified heart return the same set.

## See also

[`emoji_find()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_find.md)
to go the other way, from keywords to emoji;
[`emoji_search()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_search.md)
for a substring search over keywords, names and shortcodes.

## Examples

``` r
emoji_keywords(c("\U0001f389", "\u2764"))
#> # A tibble: 14 × 3
#>    emoji name         keyword    
#>    <chr> <chr>        <chr>      
#>  1 🎉    party popper awesome    
#>  2 🎉    party popper birthday   
#>  3 🎉    party popper celebrate  
#>  4 🎉    party popper celebration
#>  5 🎉    party popper excited    
#>  6 🎉    party popper hooray     
#>  7 🎉    party popper party      
#>  8 🎉    party popper popper     
#>  9 🎉    party popper tada       
#> 10 🎉    party popper woohoo     
#> 11 ❤     red heart    love       
#> 12 ❤     red heart    emotion    
#> 13 ❤     red heart    heart      
#> 14 ❤     red heart    red        
```
