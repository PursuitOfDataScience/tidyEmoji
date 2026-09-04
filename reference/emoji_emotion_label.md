# The dominant emoji emotion per row

`emoji_emotion_label()` adds `.emoji_emotion`, the emotion with the
highest mean score among the row's emoji (using
[`emoji_emotion()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_emotion.md)).
Ties are broken in Plutchik order; rows with no scored emoji receive
`NA`.

## Usage

``` r
emoji_emotion_label(data, text, lexicon = "emotag1200")
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

- lexicon:

  Passed to
  [`emoji_emotion()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_emotion.md).

## Value

`data`, as a tibble, with `.emoji_emotion` (the winning emotion, or `NA`
when nothing was scorable) added, alongside the `.emoji_n` and
`.emoji_n_scored` counts it inherits from
[`emoji_emotion()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_emotion.md).

## Details

Ties are broken in Plutchik order – the order the eight emotions are
listed in throughout the package (anger, anticipation, disgust, fear,
joy, sadness, surprise, trust) – so the winner is deterministic and does
not depend on the row's position in the data. Read `.emoji_n_scored`
alongside the label: a tie, or a near-tie, is invisible in a single
winning name, and
[`emoji_emotion()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_emotion.md)
gives the full profile the label collapses.

## Examples

``` r
df <- data.frame(text = c("love it \U0001f60d", "scary \U0001f628", "meh"))
emoji_emotion_label(df, text)
#> # A tibble: 3 × 4
#>   text       .emoji_n .emoji_n_scored .emoji_emotion
#>   <chr>         <int>           <int> <chr>         
#> 1 love it 😍        1               1 joy           
#> 2 scary 😨          1               1 fear          
#> 3 meh               0              NA NA            
```
