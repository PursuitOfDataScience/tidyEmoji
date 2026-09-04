# Emoji emotion profiles (the 8 Plutchik emotions)

`emoji_emotion()` scores each row's emoji across the eight Plutchik
emotions (anger, anticipation, disgust, fear, joy, sadness, surprise,
trust) using the bundled EmoTag1200 lexicon (Shoeb & de Melo, 2020).
Scores each range from 0 to 1 and are averaged over the emoji in the row
that appear in the lexicon.

## Usage

``` r
emoji_emotion(data, text, lexicon = "emotag1200", long = FALSE)
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

  Lexicon to use. Either a string naming a bundled lexicon
  (`"emotag1200"`, the default), the name of a registered lexicon (see
  [`register_emoji_lexicon()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/register_emoji_lexicon.md)),
  or a data frame. A custom lexicon must have an `emoji` column and one
  column per emotion (any subset of the eight Plutchik emotions); it is
  joined through the same codepoint-normalised key as the bundled one.

- long:

  If `TRUE`, return one row per (row, emotion) in long form with columns
  `.emoji_emotion` (the emotion name) and `.emoji_score` (its mean).
  Default `FALSE` adds eight `.emoji_<emotion>` columns plus `.emoji_n`
  and `.emoji_n_scored`.

## Value

`data`, as a tibble. With `long = FALSE` (the default), eight emotion
columns – `.emoji_anger`, `.emoji_anticipation`, `.emoji_disgust`,
`.emoji_fear`, `.emoji_joy`, `.emoji_sadness`, `.emoji_surprise`,
`.emoji_trust` – plus `.emoji_n` and `.emoji_n_scored`, one row per
input row. With `long = TRUE`, one row per input row *per emotion*,
carrying `.emoji_emotion` and `.emoji_score` instead of the eight
columns. Rows without emoji, or whose emoji are absent from the lexicon,
receive `NA` scores.

## Details

**The lexicon is 150 glyphs, about 4% of the distinct emoji tidyEmoji
can detect**, so a row of post-2018 emoji will score `NA` and still be a
row full of emoji. Read `.emoji_n_scored` alongside `.emoji_n` before
concluding a corpus carries no emotion; see
[emoji_emotion_lexicon](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_emotion_lexicon.md)
for the figure and its denominator.

## References

Shoeb AAM, de Melo G (2020). EmoTag1200: Understanding the Association
between Emojis and Emotions. *EMNLP 2020*.
<https://aclanthology.org/2020.emnlp-main.720/>. Data released under the
MIT licence.

## See also

[emoji_emotion_lexicon](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_emotion_lexicon.md)
for the underlying scores;
[`emoji_emotion_label()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_emotion_label.md)
for the dominant emotion per row;
[`emoji_sentiment()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sentiment.md)
for valence.

## Examples

``` r
df <- data.frame(text = c("love it \U0001f60d", "scary \U0001f628", "meh"))
emoji_emotion(df, text)
#> # A tibble: 3 × 11
#>   text    .emoji_anger .emoji_anticipation .emoji_disgust .emoji_fear .emoji_joy
#>   <chr>          <dbl>               <dbl>          <dbl>       <dbl>      <dbl>
#> 1 love i…         0                   0.31           0           0          0.83
#> 2 scary …         0.17                0.39           0.33        0.97       0   
#> 3 meh            NA                  NA             NA          NA         NA   
#> # ℹ 5 more variables: .emoji_sadness <dbl>, .emoji_surprise <dbl>,
#> #   .emoji_trust <dbl>, .emoji_n <int>, .emoji_n_scored <int>
emoji_emotion(df, text, long = TRUE)
#> # A tibble: 24 × 3
#>    text       .emoji_emotion .emoji_score
#>    <chr>      <chr>                 <dbl>
#>  1 love it 😍 anger                  0   
#>  2 love it 😍 anticipation           0.31
#>  3 love it 😍 disgust                0   
#>  4 love it 😍 fear                   0   
#>  5 love it 😍 joy                    0.83
#>  6 love it 😍 sadness                0   
#>  7 love it 😍 surprise               0.5 
#>  8 love it 😍 trust                  0.5 
#>  9 scary 😨   anger                  0.17
#> 10 scary 😨   anticipation           0.39
#> # ℹ 14 more rows
```
