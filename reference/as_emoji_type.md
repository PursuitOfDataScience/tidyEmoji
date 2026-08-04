# Functional type of an emoji glyph

`as_emoji_type(x)` maps emoji glyphs to a small functional vocabulary –
`"face"`, `"gesture"`, `"person"`, `"nature"`, `"food"`, `"place"`,
`"activity"`, `"object"`, `"symbol"`, `"flag"`, `"component"` – recoded
from the Unicode group and subgroup. The distinction that matters most
in the literature is `face` (emotional) against `object` (semantic).

## Usage

``` r
as_emoji_type(x)
```

## Arguments

- x:

  A character vector of emoji glyphs.

## Value

A character vector the same length as `x`.

## Details

The recode is: faces and costumed characters in *Smileys & Emotion*
become `face` and the rest of that group (hearts, the anger symbol, ...)
becomes `symbol`; hands and gesturing people in *People & Body* become
`gesture` and the rest `person`; the remaining Unicode groups map
one-to-one. Glyphs the reference table does not know return `NA`.

## See also

[`emoji_type()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_type.md)
for the data-frame verb,
[`emoji_faceness()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_faceness.md)
for the per-row share,
[`emoji_categorize()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_categorize.md)
for the raw Unicode categories.

## Examples

``` r
as_emoji_type(c("\U0001f600", "\U0001f44d", "\U0001f355", "\u2764\ufe0f"))
#> [1] "face"    "gesture" "food"    "symbol" 
```
