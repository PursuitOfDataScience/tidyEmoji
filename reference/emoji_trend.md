# Emoji frequency over time

`emoji_trend()` counts emoji per time period and returns the long,
complete table that plots directly: one row per (period, emoji),
including the periods in which an emoji is absent, so a trend line does
not silently skip its zeros.

## Usage

``` r
emoji_trend(
  data,
  text,
  time,
  by = "month",
  top_n = 20,
  measure = c("n", "share")
)
```

## Arguments

- data:

  A data frame or tibble containing a text column.

- text:

  The text column to scan, supplied unquoted.

- time:

  Unquoted column of dates or date-times (`Date`, `POSIXct`, or
  character in `"YYYY-MM-DD"` form).

- by:

  Period length: `"day"`, `"week"` (starting Monday), `"month"`
  (default), `"quarter"` or `"year"`.

- top_n:

  Number of emoji to follow, ranked by `measure` over the whole corpus.
  `NULL` keeps every emoji. Default `20`.

- measure:

  Statistic used to rank emoji for `top_n` and to order the rows within
  a period: `"n"` (default) or `"share"`.

## Value

A tibble with columns `.period` (a `Date`, the start of the period),
`emoji`, `name`, `n` and `share`.

## Details

`share` is the emoji's count divided by all emoji tokens in the same
period, which is what makes periods with different volumes comparable.
`top_n` selects the emoji to follow, ranked over the whole corpus by
`measure`, and the selected set is the same in every period.

Rows whose time is missing or unparseable contribute nothing. Glyphs are
canonicalised through the package's codepoint key, so qualified and
unqualified forms share one series.

## See also

[`emoji_turnover()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_turnover.md)
for vocabulary churn,
[`emoji_seasonality()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_seasonality.md)
for cyclical patterns.

## Examples

``` r
df <- data.frame(
  when = as.Date(c("2024-01-05", "2024-01-20", "2024-02-03")),
  text = c("\U0001f600 hi", "\U0001f600\U0001f602", "\U0001f602 yes")
)
emoji_trend(df, text, when)
#> # A tibble: 4 × 5
#>   .period    emoji name                       n share
#>   <date>     <chr> <chr>                  <int> <dbl>
#> 1 2024-01-01 😀    grinning face              2 0.667
#> 2 2024-01-01 😂    face with tears of joy     1 0.333
#> 3 2024-02-01 😂    face with tears of joy     1 1    
#> 4 2024-02-01 😀    grinning face              0 0    
```
