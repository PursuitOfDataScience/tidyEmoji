# Vector helpers: convert emoji to/from names and shortcodes

Small vector-level helpers for ad-hoc use. They do not take a data
frame.

## Usage

``` r
as_emoji_name(x)

as_emoji_shortcode(x)

as_emoji(x)
```

## Arguments

- x:

  A character vector of emoji glyphs (for `as_emoji_name`,
  `as_emoji_shortcode`) or of shortcodes/names (for `as_emoji`).

## Value

A character vector the same length as `x`.

## Details

- `as_emoji_name(x)` maps emoji glyphs to their Unicode names.

- `as_emoji_shortcode(x)` maps emoji glyphs to their first shortcode.

- `as_emoji(x)` maps shortcodes/names to the emoji glyph (emojize).

All three resolve through `emoji_key()`, so qualified emoji (carrying
`U+FE0F`) and unqualified forms resolve identically. Unmatched inputs
return `NA`.

## See also

[`emoji_to_text()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_to_text.md),
[`text_to_emoji()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/text_to_emoji.md)
for the data-frame verbs.

## Examples

``` r
as_emoji_name(c("\U0001f600", "\u2764\ufe0f"))
#> [1] "grinning face" "red heart"    
as_emoji_shortcode(c("\U0001f600", "\u2764\ufe0f"))
#> [1] "grinning" "heart"   
as_emoji(c("grinning", "heart"))
#> [1] "😀" "❤️" 
```
