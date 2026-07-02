# Replace emoji in a text column with words (demojize)

`emoji_to_text()` returns a copy of `data` with its text column
rewritten so that every emoji is replaced by its name or shortcode. This
is useful for accessibility (screen readers) and as an NLP normalisation
step before tokenising. Detection is grapheme-aware and joins go through
`emoji_key()`, so emoji carrying the `U+FE0F` variation selector still
resolve.

## Usage

``` r
emoji_to_text(data, text, format = c("name", "shortcode"), wrap = ":{x}:")
```

## Arguments

- data:

  A data frame or tibble containing a text column.

- text:

  The text column to scan, supplied unquoted.

- format:

  Output form: `"name"` (the Unicode name, e.g. "grinning face") or
  `"shortcode"` (the canonical GitHub-style alias, e.g. "grinning",
  wrapped as ":grinning:"). Default `"name"`.

- wrap:

  When `format = "shortcode"`, the wrapper applied to each shortcode,
  written as a template with `{x}` standing for the shortcode. Default
  `":{x}:"`. Ignored for `format = "name"`.

## Value

`data`, as a tibble, with the text column rewritten in place (same
column name). `NA` entries stay `NA`, and emoji with no known name are
left in place unchanged.

## See also

[`text_to_emoji()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/text_to_emoji.md)
for the inverse (emojize);
[`as_emoji_name()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/as_emoji_name.md),
[`as_emoji_shortcode()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/as_emoji_name.md),
[`as_emoji()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/as_emoji_name.md)
for vector helpers.

## Examples

``` r
df <- data.frame(text = "great \U0001f600 love \u2764\ufe0f")
emoji_to_text(df, text, format = "name")
#> # A tibble: 1 × 1
#>   text                              
#>   <chr>                             
#> 1 great grinning face love red heart
emoji_to_text(df, text, format = "shortcode")
#> # A tibble: 1 × 1
#>   text                         
#>   <chr>                        
#> 1 great :grinning: love :heart:
```
