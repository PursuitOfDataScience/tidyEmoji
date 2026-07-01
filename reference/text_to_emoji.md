# Replace shortcodes with emoji (emojize)

`text_to_emoji()` returns a copy of `data` with its text column
rewritten so that every `:shortcode:` token is replaced by the
corresponding emoji glyph (the inverse of
[`emoji_to_text()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_to_text.md)
with `format = "shortcode"`). Shortcodes that do not match a known emoji
are left unchanged.

## Usage

``` r
text_to_emoji(data, text)
```

## Arguments

- data:

  A data frame or tibble containing a text column.

- text:

  The text column to scan, supplied unquoted.

## Value

`data`, as a tibble, with the text column rewritten in place.

## See also

[`emoji_to_text()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_to_text.md);
[`as_emoji()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/as_emoji_name.md)
for the vector helper.

## Examples

``` r
df <- data.frame(text = "hi :grinning: bye :waving_hand:")
text_to_emoji(df, text)
#> # A tibble: 1 × 1
#>   text        
#>   <chr>       
#> 1 hi 😀 bye 👋
```
