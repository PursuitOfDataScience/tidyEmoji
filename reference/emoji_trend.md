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

  A data frame or tibble containing a text column. Grouped data frames
  are accepted. The verbs that work a row at a time (adding columns, or
  keeping and expanding rows) carry the grouping through to their
  result, as
  [`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html)
  and
  [`dplyr::filter()`](https://dplyr.tidyverse.org/reference/filter.html)
  do. The verbs that pool across rows – the counts, the co-occurrence
  edge lists, the time series – warn that they ignore the grouping and
  return one corpus-wide answer.

- text:

  The text column to scan, supplied unquoted. Any atomic column is
  accepted and read as character, so a `factor` works and a numeric,
  `Date` or logical one simply contains no emoji. A list column – or a
  data-frame column – is refused rather than coerced, because coercing
  one deparses it and the emoji found would be in the code rather than
  in your data. What counts as an emoji is the same in every verb; see
  the *Detection* section of
  [tidyEmoji](https://pursuitofdatascience.github.io/tidyEmoji/reference/tidyEmoji-package.md)
  for the one case that surprises people, code points that are emoji
  only when they carry `U+FE0F`.

- time:

  Unquoted column of dates or date-times (`Date`, `POSIXct`, or
  character in `"YYYY-MM-DD"` form). A date-time is bucketed by the
  calendar day it *displays* as in its own timezone, not by its UTC day:
  an emoji posted at 23:30 New York time belongs to that day, not to the
  next one.

  "Its own timezone" means the column's `tzone` attribute. A `POSIXct`
  created without one – which is what `as.POSIXct("2024-01-01 23:30")`
  and most CSV readers give you – has no timezone of its own, so R
  displays it in the session's, and the buckets follow. The same column
  then gives hour 23 on one machine and hour 4 on another. Tag the
  column (`as.POSIXct(x, tz = "UTC")`, or `lubridate::force_tz()`) if
  the result has to be reproducible; a `Date` column is immune either
  way.

  A character column must lead with a four-digit year: `"2024-01-01"` or
  `"2024/01/01"`, with one- or two-digit month and day, and any trailing
  time ignored. Values that do not warn and are dropped – but a column
  in which *nothing* reads as a date is an error rather than a column of
  `NA`, since there would be no time axis left. Note that `"01/02/2024"`
  is in the second group: convert a column written that way with
  [`as.Date()`](https://rdrr.io/r/base/as.Date.html) and its own
  `format` first.

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
