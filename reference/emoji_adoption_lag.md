# How long did this population take to adopt each emoji?

`emoji_adoption_lag()` compares the date an emoji was first used in your
corpus with the date Unicode released it, giving a per-glyph adoption
lag in days.

## Usage

``` r
emoji_adoption_lag(data, text, time)
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

  The text column to scan, supplied unquoted. What counts as an emoji is
  the same in every verb; see the *Detection* section of
  [tidyEmoji](https://pursuitofdatascience.github.io/tidyEmoji/reference/tidyEmoji-package.md)
  for the one case that surprises people, code points that are emoji
  only when they carry `U+FE0F`.

- time:

  Unquoted column of dates or date-times (`Date`, `POSIXct`, or
  character in `"YYYY-MM-DD"` form). A date-time is bucketed by the
  calendar day it *displays* as in its own timezone, not by its UTC day:
  an emoji posted at 23:30 New York time belongs to that day, not to the
  next one. Character values that cannot be read as a date warn and are
  dropped.

## Value

A tibble with one row per emoji, most frequent first: `emoji`, `name`,
`n`, `version`, `release_date`, `first_seen` and `lag_days`. `lag_days`
is `NA` when the release date of the version is unknown.

## Details

A lag is only as good as the corpus window: an emoji released before
your data begins will look adopted on day one, so read the lag together
with `n` and the span of your data. Negative lags mean the corpus
contains a glyph before its official release date – usually a vendor
shipping early, or a timestamp problem worth investigating.

Occurrences whose time is missing or unparseable are dropped.

## See also

[`emoji_version_profile()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_version_profile.md),
[`emoji_unicode_releases()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_unicode_releases.md).

## Examples

``` r
df <- data.frame(
  when = as.Date(c("2021-01-01", "2022-06-01")),
  text = c("\U0001f600", "\U0001f97a")
)
emoji_adoption_lag(df, text, when)
#> # A tibble: 2 × 7
#>   emoji name              n version release_date first_seen lag_days
#>   <chr> <chr>         <int> <chr>   <date>       <date>        <int>
#> 1 😀    grinning face     1 1.0     2015-06-09   2021-01-01     2033
#> 2 🥺    pleading face     1 11.0    2018-06-05   2022-06-01     1457
```
