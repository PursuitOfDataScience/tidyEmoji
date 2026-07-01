# Emoji counts per row, in long (tidy) form

`emoji_extract_unnest()` returns one row per (row, emoji) pair with a
count, dropping rows that contain no emoji. `.row_number` refers to the
position of the entry in `data`.

## Usage

``` r
emoji_extract_unnest(data, text)
```

## Arguments

- data:

  A data frame or tibble containing a text column.

- text:

  The text column to scan, supplied unquoted.

## Value

A tibble with columns `.row_number`, `.emoji_unicode` and
`.emoji_count`.

## Examples

``` r
df <- data.frame(text = c("hi \U0001f600\U0001f600", "none", "\U0001f44b"))
emoji_extract_unnest(df, text)
#> # A tibble: 2 × 3
#>   .row_number .emoji_unicode .emoji_count
#>         <int> <chr>                 <int>
#> 1           1 😀                        2
#> 2           3 👋                        1
```
