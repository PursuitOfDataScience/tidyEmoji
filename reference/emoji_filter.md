# Keep only the rows whose text contains emoji

`emoji_filter()` returns the rows of `data` whose text column contains
at least one emoji, preserving every original column. `emoji_tweets()`
is a synonym retained for backward compatibility.

## Usage

``` r
emoji_filter(data, text)

emoji_tweets(data, text)
```

## Arguments

- data:

  A data frame or tibble containing a text column.

- text:

  The text column to scan, supplied unquoted.

## Value

A tibble containing only the rows with at least one emoji. The result is
always a plain (ungrouped) tibble, whatever the class or grouping of the
input.

## Examples

``` r
df <- data.frame(text = c("hi \U0001f600", "no emoji", "bye \U0001f44b"))
emoji_filter(df, text)
#> # A tibble: 2 × 1
#>   text  
#>   <chr> 
#> 1 hi 😀 
#> 2 bye 👋
```
