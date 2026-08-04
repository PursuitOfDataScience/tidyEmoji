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

  A data frame or tibble containing a text column.

- text:

  The text column to scan, supplied unquoted.

- time:

  Unquoted column of dates or date-times (`Date`, `POSIXct`, or
  character in `"YYYY-MM-DD"` form).

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
