# Are two glyphs the same emoji?

`emoji_identical()` compares glyphs element by element and says whether
each pair is the same emoji, which means the same code points once the
variation selector `U+FE0F` is set aside. With `details = TRUE` it also
says how two glyphs differ: not at all, only in that selector, only in
skin tone, or in the emoji itself.

## Usage

``` r
emoji_identical(x, y, details = FALSE)
```

## Arguments

- x, y:

  Character vectors of glyphs, the same length or one of them of length
  one.

- details:

  If `FALSE` (default), return a logical vector. If `TRUE`, return a
  tibble describing each comparison.

## Value

With `details = FALSE`, a logical vector: `TRUE` where the two glyphs
are the same emoji, `NA` where either is `NA`. With `details = TRUE`, a
tibble with columns `x`, `y`, `identical` (the same vector), `exact`
(the code points are identical, selector included), `difference`
(`"none"`, `"variation selector"`, `"skin tone"` or `"different"`), and
`x_codepoints` and `y_codepoints`, the two code-point sequences written
out (`"U+2764 U+FE0F"`) for the record.

## What this can and cannot tell you

This is the comparison a forensic or legal question needs, and it has a
hard limit that belongs here rather than in a footnote. **tidyEmoji can
say which code points a message contains and which Unicode version
defines them. It cannot say what the sender or the recipient saw.**
Rendering is decided by the font and the platform: the same code points
draw differently on two phones, an emoji newer than a device's font
draws as an empty box or as its separate parts, and a skin-tone sequence
can draw as a base emoji beside a colour swatch. No dataset of vendor
renderings is available to the package (all eight `vendor_*` columns of
the emoji package's table are empty), so nothing here reports one.

Two glyphs that are `identical` here can therefore look different to
people, and two that are not can look alike. Treat a `TRUE` as "the same
characters were sent", never as "the same picture was seen".

## See also

[`as_emoji_canonical()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/as_emoji_canonical.md),
[`emoji_properties()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_properties.md).

## Examples

``` r
emoji_identical("\u2764", "\u2764\ufe0f")
#> [1] TRUE
emoji_identical("\U0001f600", "\U0001f602")
#> [1] FALSE

emoji_identical(c("\u2764", "\U0001f44d", "\U0001f600"),
                c("\u2764\ufe0f", "\U0001f44d\U0001f3fd", "\U0001f602"),
                details = TRUE)
#> # A tibble: 3 × 7
#>   x     y     identical exact difference         x_codepoints y_codepoints   
#>   <chr> <chr> <lgl>     <lgl> <chr>              <chr>        <chr>          
#> 1 ❤     ❤️     TRUE      FALSE variation selector U+2764       U+2764 U+FE0F  
#> 2 👍    👍🏽    FALSE     FALSE skin tone          U+1F44D      U+1F44D U+1F3FD
#> 3 😀    😂    FALSE     FALSE different          U+1F600      U+1F602        
```
