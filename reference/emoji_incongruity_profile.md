# Which emoji go against the grain of their text?

`emoji_incongruity_profile()` aggregates
[`emoji_incongruity()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_incongruity.md)
by glyph: for each emoji, how far from its host text's sentiment it
typically sits, and how often it appears with the opposite polarity.
Those are the candidate irony markers in your corpus.

## Usage

``` r
emoji_incongruity_profile(
  data,
  text,
  text_score,
  method = c("difference", "sign_flip"),
  scale,
  where = c("all", "final"),
  threshold = 1,
  min_n = 5
)
```

## Arguments

- data:

  A data frame or tibble containing a text column.

- text:

  The text column to scan, supplied unquoted.

- text_score:

  Unquoted numeric column holding the text's own sentiment.

- method:

  `"difference"` (default) for the continuous gap, or `"sign_flip"` for
  the categorical polarity-flip feature.

- scale:

  How to make the two scores comparable: `"rank"`, `"zscore"` or
  `"none"`. Required – there is no sensible default.

- where:

  `"all"` (default) scores every emoji in the row; `"final"` scores only
  the trailing run of emoji that ends the text.

- threshold:

  For `method = "difference"`, the absolute gap at or above which
  `.emoji_incongruent` is `TRUE`. Default `1`, a full polarity swing on
  the rank scale.

- min_n:

  Minimum number of scored occurrences for an emoji to be reported.
  Default `5`.

## Value

A tibble with one row per emoji: `emoji`, `name`, `n` (scored
occurrences), `mean_incongruity`, `sd_incongruity`, `n_flips` and
`flip_rate`, sorted by descending `flip_rate`.

## Details

Incongruity is a property of a row, so every emoji in a row is credited
with that row's gap. A glyph that habitually shares a message with a
genuinely incongruent one will therefore inherit some of its score; read
`n` alongside `flip_rate` before drawing conclusions from a handful of
occurrences.

## See also

[`emoji_incongruity()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_incongruity.md).

## Examples

``` r
df <- data.frame(
  text = c("great \U0001f621", "lovely \U0001f621", "awful \U0001f621"),
  score = c(0.8, 0.7, -0.9)
)
emoji_incongruity_profile(df, text, score, scale = "none", min_n = 1)
#> # A tibble: 1 × 7
#>   emoji name             n mean_incongruity sd_incongruity n_flips flip_rate
#>   <chr> <chr>        <int>            <dbl>          <dbl>   <int>     <dbl>
#> 1 😡    enraged face     3           -0.373          0.954       2     0.667
```
