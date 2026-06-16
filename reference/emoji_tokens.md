# Tidy emoji tokens, one row per occurrence with metadata

`emoji_tokens()` expands `data` to one row per emoji occurrence (in
reading order), keeping the original columns and adding the glyph
together with its name, category and sentiment score. This mirrors the
one-token-per-row shape familiar from tidy text mining and is convenient
for counting, joining and plotting.

## Usage

``` r
emoji_tokens(data, text)
```

## Arguments

- data:

  A data frame or tibble containing a text column.

- text:

  The text column to scan, supplied unquoted.

## Value

A tibble with the original columns plus `.emoji`, `.emoji_name`,
`.emoji_category` and `.emoji_sentiment`. Rows without emoji are
dropped.

## See also

[`emoji_frequency()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_frequency.md)
for corpus-level counts and
[`emoji_sentiment()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sentiment.md)
for per-row sentiment.

## Examples

``` r
df <- data.frame(id = 1:2, text = c("great \U0001f600", "bad \U0001f621"))
emoji_tokens(df, text)
#> # A tibble: 2 × 6
#>      id text     .emoji .emoji_name   .emoji_category   .emoji_sentiment
#>   <int> <chr>    <chr>  <chr>         <chr>                        <dbl>
#> 1     1 great 😀 😀     grinning face Smileys & Emotion            0.572
#> 2     2 bad 😡   😡     enraged face  Smileys & Emotion           -0.173
```
