# Add a list-column of the emoji found in each row

`emoji_extract_nest()` returns `data` unchanged except for an added
list-column, `.emoji_unicode`, holding the emoji found in each row.
Detection is grapheme-aware, so skin-tone modifiers and ZWJ sequences
(for example family emoji) are kept intact as a single emoji.

## Usage

``` r
emoji_extract_nest(data, text)
```

## Arguments

- data:

  A data frame or tibble containing a text column.

- text:

  The text column to scan, supplied unquoted.

## Value

`data` with an added list-column `.emoji_unicode`.

## See also

[`emoji_extract_unnest()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_extract_unnest.md)
for a long, counted form and
[`emoji_tokens()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_tokens.md)
for one row per emoji with metadata.

## Examples

``` r
df <- data.frame(text = c("hi \U0001f600\U0001f603", "none"))
emoji_extract_nest(df, text)
#>      text .emoji_unicode
#> 1 hi 😀😃         😀, 😃
#> 2    none               
```
