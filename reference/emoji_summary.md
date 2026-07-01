# Summarise emoji presence in a text column

`emoji_summary()` reports how many entries in a text column contain at
least one emoji, alongside the total number of entries. An entry is
counted once regardless of how many emoji it holds.

## Usage

``` r
emoji_summary(data, text)
```

## Arguments

- data:

  A data frame or tibble containing a text column.

- text:

  The text column to scan, supplied unquoted.

## Value

A one-row tibble with columns `n_with_emoji` (entries containing at
least one emoji) and `n_total` (all entries).

## See also

[`emoji_filter()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_filter.md)
to keep the emoji-bearing rows themselves.

## Examples

``` r
df <- data.frame(text = c("I love R \U0001f600",
                          "no emoji here",
                          "flags \U0001f3c1\U0001f600"))
emoji_summary(df, text)
#> # A tibble: 1 × 2
#>   n_with_emoji n_total
#>          <int>   <int>
#> 1            2       3
```
