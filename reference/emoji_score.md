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
emoji_score(data, text, lexicon, by = "emoji", score = NULL)
```

## Arguments

- data:

  A data frame or tibble containing a text column.

- text:

  The text column to scan, supplied unquoted.

- lexicon:

  Either a string naming a bundled or registered lexicon, or a data
  frame. For data frames, `by` names the glyph column and `score` the
  score column.

- by:

  Glyph column name when `lexicon` is a data frame. Default `"emoji"`.

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
