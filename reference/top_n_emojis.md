# The most frequent emoji in a text column

`top_n_emojis()` returns the `n` most frequent emoji. By default each
emoji (unicode) appears on a single row; set `duplicated = TRUE` to list
every name an emoji is known by, so glyphs that share several names
occupy several rows.

## Usage

``` r
top_n_emojis(
  data,
  text,
  n = 20,
  duplicated = FALSE,
  duplicated_unicode = lifecycle::deprecated()
)
```

## Arguments

- data:

  A data frame or tibble containing a text column.

- text:

  The text column to scan, supplied unquoted.

- n:

  Number of emoji to return. Default `20`.

- duplicated:

  If `TRUE`, emoji with several names occupy several rows. Default
  `FALSE`.

- duplicated_unicode:

  **\[deprecated\]** Use `duplicated` instead.

## Value

A tibble with columns `emoji_name`, `unicode`, `emoji_category` and `n`.

## See also

[`emoji_frequency()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_frequency.md)
for the full distribution.

## Examples

``` r
df <- data.frame(text = c("\U0001f600\U0001f600\U0001f3c1", "\U0001f621"))
top_n_emojis(df, text, n = 2)
#> # A tibble: 2 × 4
#>   emoji_name     unicode emoji_category        n
#>   <chr>          <chr>   <chr>             <int>
#> 1 grinning       😀      Smileys & Emotion     2
#> 2 checkered_flag 🏁      Flags                 1
```
