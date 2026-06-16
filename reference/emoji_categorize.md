# Categorise each row by the emoji categories it contains

`emoji_categorize()` keeps the rows of `data` that contain emoji and
adds a `.emoji_category` column listing the distinct Unicode categories
present in that row (for example "Smileys & Emotion"), separated by `|`
when a row spans more than one category.

## Usage

``` r
emoji_categorize(data, text)
```

## Arguments

- data:

  A data frame or tibble containing a text column.

- text:

  The text column to scan, supplied unquoted.

## Value

`data`, as a tibble, filtered to the rows containing emoji and with an
added `.emoji_category` column.

## Examples

``` r
df <- data.frame(text = c("smile \U0001f600",
                          "flag \U0001f3c1\U0001f600",
                          "nothing"))
emoji_categorize(df, text)
#> # A tibble: 2 × 2
#>   text      .emoji_category        
#>   <chr>     <chr>                  
#> 1 smile 😀  Smileys & Emotion      
#> 2 flag 🏁😀 Flags|Smileys & Emotion
```
