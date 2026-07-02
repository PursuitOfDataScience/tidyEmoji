# What share of the text is emoji — and is it emoji-only?

`emoji_ratio()` reports, per row, the share of the text's characters
that belong to emoji, and whether the text is emoji-only (nothing left
after removing emoji and whitespace). "Emoji-only" messages are a
studied signal in social-media research and a useful filter in practice.

## Usage

``` r
emoji_ratio(data, text)
```

## Arguments

- data:

  A data frame or tibble containing a text column.

- text:

  The text column to scan, supplied unquoted.

## Value

`data`, as a tibble, with added columns `.emoji_ratio` (emoji characters
/ all characters, 0 when there are no emoji) and `.emoji_only` (`TRUE`
when the text contains emoji and nothing else but whitespace). `NA` text
gets `NA` in both.

## Details

The ratio is computed over characters (code points), so a
multi-code-point emoji (a ZWJ family, a skin-tone sequence) contributes
all of its characters.

## See also

[`emoji_position()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_position.md),
[`emoji_density()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_density.md);
[`emoji_filter()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_filter.md)
to keep emoji-bearing rows.

## Examples

``` r
df <- data.frame(text = c("\U0001f600\U0001f389", "half \U0001f600", "no"))
emoji_ratio(df, text)
#> # A tibble: 3 × 3
#>   text    .emoji_ratio .emoji_only
#>   <chr>          <dbl> <lgl>      
#> 1 😀🎉           1     TRUE       
#> 2 half 😀        0.167 FALSE      
#> 3 no             0     FALSE      
```
