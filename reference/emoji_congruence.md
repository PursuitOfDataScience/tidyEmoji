# Text-emoji congruence

`emoji_congruence()` is
[`emoji_incongruity()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_incongruity.md)
under the framing used in the marketing and eWOM literature, where the
finding is that a *mismatch* between a review's words and its emoji
lowers perceived helpfulness and authenticity. Same engine, same
columns, plus `.emoji_congruent`.

## Usage

``` r
emoji_congruence(
  data,
  text,
  text_score,
  method = c("difference", "sign_flip"),
  scale,
  where = c("all", "final"),
  threshold = 1
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

## Value

`data`, as a tibble, with everything
[`emoji_incongruity()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_incongruity.md)
adds plus `.emoji_congruent`, the negation of `.emoji_incongruent`.

## See also

[`emoji_incongruity()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_incongruity.md).

## Examples

``` r
df <- data.frame(
  text = c("lovely stay \U0001f600", "terrible room \U0001f600"),
  score = c(0.8, -0.9)
)
emoji_congruence(df, text, score, scale = "none")
#> # A tibble: 2 × 9
#>   text        score .emoji_n .emoji_n_scored .emoji_sentiment .emoji_incongruity
#>   <chr>       <dbl>    <int>           <int>            <dbl>              <dbl>
#> 1 lovely sta…   0.8        1               1            0.572             -0.228
#> 2 terrible r…  -0.9        1               1            0.572              1.47 
#> # ℹ 3 more variables: .emoji_polarity_flip <lgl>, .emoji_incongruent <lgl>,
#> #   .emoji_congruent <lgl>
```
