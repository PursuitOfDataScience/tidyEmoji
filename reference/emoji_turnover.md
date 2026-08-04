# Emoji vocabulary churn between consecutive periods

`emoji_turnover()` compares the set of distinct emoji used in each
period with the set used in the one before: how much of the vocabulary
is shared, how much is new, how much was dropped.

## Usage

``` r
emoji_turnover(
  data,
  text,
  time,
  by = "month",
  measure = c("jaccard", "new", "lost", "core")
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

- measure:

  Which statistics to return: any of `"jaccard"`, `"new"`, `"lost"` and
  `"core"`. All four by default.

## Value

A tibble with one row per consecutive pair of periods: `.period`,
`.period_prev`, `n_types_prev`, `n_types`, and then the requested
`jaccard`, `n_new`, `n_lost` and `n_core` columns. Fewer than two
periods yields no rows.

## Details

A period's vocabulary is its set of distinct canonicalised glyphs, so an
emoji used a thousand times and one used once count the same – turnover
is about repertoire, not volume. `jaccard` is the size of the
intersection over the size of the union, and is `NA` when both periods
are empty.

## See also

[`emoji_trend()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_trend.md),
[`emoji_version_profile()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_version_profile.md).

## Examples

``` r
df <- data.frame(
  when = as.Date(c("2024-01-05", "2024-02-03", "2024-02-20")),
  text = c("\U0001f600\U0001f602", "\U0001f600", "\U0001f389")
)
emoji_turnover(df, text, when)
#> # A tibble: 1 × 8
#>   .period    .period_prev n_types_prev n_types jaccard n_new n_lost n_core
#>   <date>     <date>              <int>   <int>   <dbl> <int>  <int>  <int>
#> 1 2024-02-01 2024-01-01              2       2   0.333     1      1      1
```
