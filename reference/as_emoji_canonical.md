# The canonical spelling of an emoji

`as_emoji_canonical()` maps each glyph to the one spelling the catalogue
marks fully-qualified, so that the bare heart `U+2764` and the qualified
heart `U+2764 U+FE0F` become the same string. It is the normalisation
every verb in the package applies before a join, exported so a join of
your own can apply it too.

## Usage

``` r
as_emoji_canonical(x)
```

## Arguments

- x:

  A character vector of glyphs.

## Value

A character vector the same length as `x`.

## Details

Two spellings of one emoji differ only in the variation selector
`U+FE0F` (or `U+FE0E`, which asks for the text form), and a plain
[`dplyr::left_join()`](https://dplyr.tidyverse.org/reference/mutate-joins.html)
on the glyph treats them as different keys, which silently drops every
row whose text holds the other spelling. Canonicalising both sides first
is the fix. A glyph the catalogue does not know comes back unchanged, so
the function is safe to apply to a whole column, and `NA` stays `NA`.

The canonical spelling is a choice of bytes, not of meaning: a skin
tone, a gender sign and a ZWJ component are part of the emoji and are
kept. Use
[`emoji_identical()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_identical.md)
to ask whether two glyphs are the same emoji, and how they differ when
they are not.

## See also

[`emoji_identical()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_identical.md),
[`emoji_properties()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_properties.md).

## Examples

``` r
as_emoji_canonical(c("\u2764", "\u2764\ufe0f", "\u263a", "not an emoji"))
#> [1] "❤️"            "❤️"            "☺️"            "not an emoji"
```
