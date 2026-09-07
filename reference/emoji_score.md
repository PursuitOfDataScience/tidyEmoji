# Score emoji in a text column against any lexicon

`emoji_score()` is the generic scorer that the friendly verbs
([`emoji_sentiment()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sentiment.md),
[`emoji_emotion()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_emotion.md))
sit on top of. It joins each row's emoji to `lexicon` through
`emoji_key()` and returns the per-row mean of the `score` column, plus
the number of emoji scored. Bring your own lexicon, or name a bundled /
registered one.

## Usage

``` r
emoji_score(data, text, lexicon = "novak2015", by = "emoji", score = NULL)
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

- lexicon:

  Either a string naming a bundled or registered lexicon, or a data
  frame. For data frames, `by` names the glyph column and `score` the
  score column. Defaults to `"novak2015"`, matching
  [`emoji_sentiment()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sentiment.md).

  Two requirements on a data frame, both refused rather than worked
  around. The score column must be numeric or logical: as text every
  score comes back `NA` while the emoji still counts as scored, which
  contradicts `.emoji_n_scored` below. And no two rows may give one
  emoji *different* scores – spellings differing only by a variation
  selector share a single code-point key, so a table listing both
  `U+2764` and `U+2764 U+FE0F` has one emoji twice. Identical scores are
  fine and collapse silently; when they differ, the row order would be
  choosing the answer.

- by:

  Glyph column name when `lexicon` is a data frame, as a single string.
  Default `"emoji"`.

- score:

  Score column name when `lexicon` is a data frame. If `NULL`,
  `"sentiment_score"` then `"score"` are tried.

## Value

`data`, as a tibble, with `.emoji_score` (per-row mean),
`.emoji_n_scored` (emoji found in the lexicon) and `.emoji_n` (total
emoji) added. For the multi-dimensional `"emotag1200"` lexicon the score
is the mean over its eight emotion dimensions; use
[`emoji_emotion()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_emotion.md)
for the per-emotion profile.

That averaging is specific to the bundled lexicon. A *registered* or
inline lexicon carrying emotion columns has no score column, so
`emoji_score()` cannot collapse it and says so: pass it to
[`emoji_emotion()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_emotion.md)
instead, or name one dimension with `score = "joy"` to score on that
alone.

`.emoji_n_scored` distinguishes the two ways a score can be missing, as
in
[`emoji_sentiment()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sentiment.md):
`0` means the row had emoji that the lexicon could not score, `NA` that
it had no emoji to score. `.emoji_n` counts every emoji either way.

## See also

[`emoji_lexicons()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_lexicons.md),
[`register_emoji_lexicon()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/register_emoji_lexicon.md).

## Examples

``` r
df <- data.frame(text = c("love \U0001f60d", "angry \U0001f621", "meh"))
emoji_score(df, text, lexicon = "novak2015")
#> # A tibble: 3 × 4
#>   text     .emoji_score .emoji_n_scored .emoji_n
#>   <chr>           <dbl>           <int>    <int>
#> 1 love 😍         0.678               1        1
#> 2 angry 😡       -0.173               1        1
#> 3 meh            NA                  NA        0

# a bring-your-own lexicon
own <- data.frame(emoji = c("\U0001f600", "\U0001f621"),
                  score = c(0.9, -0.8))
emoji_score(df, text, lexicon = own)
#> # A tibble: 3 × 4
#>   text     .emoji_score .emoji_n_scored .emoji_n
#>   <chr>           <dbl>           <int>    <int>
#> 1 love 😍          NA                 0        1
#> 2 angry 😡         -0.8               1        1
#> 3 meh              NA                NA        0
```
