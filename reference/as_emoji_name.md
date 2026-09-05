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

- `as_emoji(x)` maps names/shortcodes to the emoji glyph (emojize).

All three resolve through `emoji_key()`, so qualified emoji (carrying
`U+FE0F`) and unqualified forms resolve identically. Unmatched inputs
return `NA`.

`as_emoji()` accepts either namespace in the same argument, and 464
strings belong to both – they are the exact Unicode name of one emoji
and a shortcode alias of another. It resolves them in a fixed order:
**exact Unicode name first**, then shortcode, then emoji's own name
table. An exact name match is the stronger signal, so `as_emoji("dog")`
is the emoji actually *named* "dog" (a dog, `U+1F415`), not the one
whose alias is `:dog:` (a dog face, `U+1F436`).

For 17 of those 464 strings the two namespaces disagree, and there
`as_emoji()` and
[`text_to_emoji()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/text_to_emoji.md)
differ *by design*: a `:dog:` token is explicitly delimited as a
shortcode, so
[`text_to_emoji()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/text_to_emoji.md)
reads it in the shortcode namespace and produces the dog face. The
pattern is an emoji whose name is a bare noun versus the "... face"
variant that carries the alias (`cat`, `cow`, `pig`, `tiger`, `mouse`,
`rabbit`), or a plain object versus a decorated one (`umbrella`,
`snowman`, `calendar`, `sunglasses`). Pass a shortcode through
[`text_to_emoji()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/text_to_emoji.md),
or the full Unicode name (`"dog face"`) to `as_emoji()`, if you need one
namespace specifically.

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
