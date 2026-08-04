# Cyclical patterns in emoji use

`emoji_seasonality()` aggregates emoji use by month of year, day of week
or hour of day. Emoji use is strongly seasonal and strongly diurnal, and
both are confounders worth seeing before any trend is interpreted.

## Usage

``` r
emoji_seasonality(data, text, time, period = c("month", "weekday", "hour"))
```

## Arguments

- data:

  A data frame or tibble containing a text column.

- text:

  The text column to scan, supplied unquoted.

- time:

  Unquoted column of dates or date-times (`Date`, `POSIXct`, or
  character in `"YYYY-MM-DD"` form).

- period:

  `"month"` (default), `"weekday"` or `"hour"`. `"hour"` needs a
  `POSIXct`/`POSIXlt` time column.

## Value

A tibble with one row per level of the cycle: `.period` (integer: 1-12,
1-7 with Monday first, or 0-23), `.period_label`, `n_texts`,
`n_with_emoji`, `n_emoji`, `emoji_per_text` and `share` (this level's
share of all emoji tokens).

## Details

Every level of the cycle is returned, including the empty ones, so a bar
chart has no invisible gaps. Labels are fixed English abbreviations
rather than locale-dependent ones, so the output of a script does not
change with the machine that runs it. Weeks start on Monday.

## See also

[`emoji_trend()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_trend.md)
for the calendar-time view.

## Examples

``` r
df <- data.frame(
  when = as.Date(c("2024-01-05", "2024-01-20", "2024-07-03")),
  text = c("\U0001f600", "\U0001f600\U0001f602", "plain")
)
emoji_seasonality(df, text, when)
#> # A tibble: 12 × 7
#>    .period .period_label n_texts n_with_emoji n_emoji emoji_per_text share
#>      <int> <chr>           <int>        <int>   <int>          <dbl> <dbl>
#>  1       1 Jan                 2            2       3            1.5     1
#>  2       2 Feb                 0            0       0           NA       0
#>  3       3 Mar                 0            0       0           NA       0
#>  4       4 Apr                 0            0       0           NA       0
#>  5       5 May                 0            0       0           NA       0
#>  6       6 Jun                 0            0       0           NA       0
#>  7       7 Jul                 1            0       0            0       0
#>  8       8 Aug                 0            0       0           NA       0
#>  9       9 Sep                 0            0       0           NA       0
#> 10      10 Oct                 0            0       0           NA       0
#> 11      11 Nov                 0            0       0           NA       0
#> 12      12 Dec                 0            0       0           NA       0
```
