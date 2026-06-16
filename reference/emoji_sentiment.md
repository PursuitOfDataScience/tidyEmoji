# Score the sentiment of the emoji in each row

`emoji_sentiment()` adds the mean emoji sentiment of each row, based on
the Emoji Sentiment Ranking lexicon (see
[emoji_sentiment_lexicon](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sentiment_lexicon.md)).
Scores range from -1 (negative) through 0 (neutral) to +1 (positive).
Rows that contain no emoji, or whose emoji are absent from the lexicon,
receive `NA`.

## Usage

``` r
emoji_sentiment(data, text)
```

## Arguments

- data:

  A data frame or tibble containing a text column.

- text:

  The text column to scan, supplied unquoted.

## Value

`data`, as a tibble, with added columns `.emoji_n` (the number of emoji
in the row) and `.emoji_sentiment` (the mean sentiment of the emoji that
appear in the lexicon).

## References

Kralj Novak P, Smailovic J, Sluban B, Mozetic I (2015) Sentiment of
Emojis. PLoS ONE 10(12): e0144296.
[doi:10.1371/journal.pone.0144296](https://doi.org/10.1371/journal.pone.0144296)

## See also

[emoji_sentiment_lexicon](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sentiment_lexicon.md)
for the underlying scores.

## Examples

``` r
df <- data.frame(text = c("love it \U0001f60d", "awful \U0001f621", "meh"))
emoji_sentiment(df, text)
#> # A tibble: 3 × 3
#>   text       .emoji_n .emoji_sentiment
#>   <chr>         <int>            <dbl>
#> 1 love it 😍        1            0.678
#> 2 awful 😡          1           -0.173
#> 3 meh               0           NA    
```
