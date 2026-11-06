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

A tibble with columns `emoji`, `name`, `keyword` and `source`
(`"github"` or `"cldr"`, `NA` with a `NA` keyword), one row per keyword,
in the order of `x` and then of the keyword set.

## Details

**These are the English keyword sets**, and nothing in them says
anything about how an emoji is read in another language or culture.
Multilingual keywords are not bundled.

Since 0.7.0 each emoji's set is the union of two sources, and `source`
says which a keyword came from: `"github"`, the GitHub-style set the
emoji package carried, which every earlier release used and which comes
first, unchanged; and `"cldr"`, the keywords of Unicode's CLDR 49
annotations that set lacks. The union only adds: every emoji in the
catalogue has keywords now, the 182 of Emoji 17.0 and 18.0 included,
which had none, and no keyword an earlier release returned is gone. A
string that is not an emoji gets **one row with `keyword = NA`**, never
a row with an empty string, so `is.na(keyword)` is the test for "no
vocabulary".

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
#> # A tibble: 14 × 4
#>    emoji name         keyword     source
#>    <chr> <chr>        <chr>       <chr> 
#>  1 🎉    party popper awesome     github
#>  2 🎉    party popper birthday    github
#>  3 🎉    party popper celebrate   github
#>  4 🎉    party popper celebration github
#>  5 🎉    party popper excited     github
#>  6 🎉    party popper hooray      github
#>  7 🎉    party popper party       github
#>  8 🎉    party popper popper      github
#>  9 🎉    party popper tada        github
#> 10 🎉    party popper woohoo      github
#> 11 ❤     red heart    love        github
#> 12 ❤     red heart    emotion     github
#> 13 ❤     red heart    heart       github
#> 14 ❤     red heart    red         github
```
