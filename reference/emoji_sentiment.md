# Score the sentiment of the emoji in each row

`emoji_sentiment()` adds the mean emoji sentiment of each row, based on
the Emoji Sentiment Ranking lexicon (see
[emoji_sentiment_lexicon](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sentiment_lexicon.md)).
Scores range from -1 (negative) through 0 (neutral) to +1 (positive).
Rows that contain no emoji, or whose emoji are absent from the lexicon,
receive `NA`.

## Usage

``` r
emoji_sentiment(data, text, lexicon = "novak2015")
```

## Arguments

- data:

  A data frame or tibble containing a text column.

- text:

  The text column to scan, supplied unquoted.

- lexicon:

  Lexicon to use. The default, `"novak2015"`, uses the bundled
  [emoji_sentiment_lexicon](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sentiment_lexicon.md).
  A registered lexicon (see
  [`register_emoji_lexicon()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/register_emoji_lexicon.md))
  or a data frame can also be supplied; see
  [`emoji_score()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_score.md)
  for the generic scorer.

## Value

`data`, as a tibble, with added columns `.emoji_n` (the number of emoji
in the row), `.emoji_n_scored` (the number of emoji that actually appear
in the lexicon), and `.emoji_sentiment` (the mean sentiment of the
scored emoji).

## References

Kralj Novak P, Smailovic J, Sluban B, Mozetic I (2015) Sentiment of
Emojis. PLoS ONE 10(12): e0144296.
[doi:10.1371/journal.pone.0144296](https://doi.org/10.1371/journal.pone.0144296)

## See also

[emoji_sentiment_lexicon](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sentiment_lexicon.md)
for the underlying scores;
[`emoji_score()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_score.md)
for scoring against any lexicon;
[`emoji_emotion()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_emotion.md)
for discrete emotions.

## Examples

``` r
df <- data.frame(text = c("love it \U0001f60d", "awful \U0001f621", "meh"))
emoji_sentiment(df, text)
#> # A tibble: 3 × 4
#>   text       .emoji_n .emoji_n_scored .emoji_sentiment
#>   <chr>         <int>           <int>            <dbl>
#> 1 love it 😍        1               1            0.678
#> 2 awful 😡          1               1           -0.173
#> 3 meh               0              NA           NA    
```
