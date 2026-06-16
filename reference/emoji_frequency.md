# Frequency of every emoji in a text column

`emoji_frequency()` counts how often each emoji appears across the whole
text column (an entry containing the same emoji twice contributes 2) and
returns a tibble sorted by descending count, with each emoji's name,
shortcode and category.

## Usage

``` r
emoji_frequency(data, text)
```

## Arguments

- data:

  A data frame or tibble containing a text column.

- text:

  The text column to scan, supplied unquoted.

## Value

A tibble with columns `emoji`, `name`, `shortcode`, `group` and `n`.

## See also

[`top_n_emojis()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/top_n_emojis.md)
for just the most frequent emoji.

## Examples

``` r
df <- data.frame(text = c("\U0001f600\U0001f600", "\U0001f621"))
emoji_frequency(df, text)
#> # A tibble: 2 × 5
#>   emoji name          shortcode group                 n
#>   <chr> <chr>         <chr>     <chr>             <int>
#> 1 😀    grinning face grinning  Smileys & Emotion     2
#> 2 😡    enraged face  rage      Smileys & Emotion     1
```
