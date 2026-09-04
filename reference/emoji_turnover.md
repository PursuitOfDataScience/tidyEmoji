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
