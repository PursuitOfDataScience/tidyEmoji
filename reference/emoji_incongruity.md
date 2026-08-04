# Text-emoji sentiment mismatch

`emoji_incongruity()` measures the signed gap between the sentiment a
row's emoji carry and the sentiment of its text. It is the
sarcasm-detection feature the NLP literature keeps rediscovering, and
the mismatch variable the marketing literature calls (in)congruence.

## Usage

``` r
emoji_incongruity(
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

## Value

`data`, as a tibble, with added columns `.emoji_n`, `.emoji_n_scored`,
`.emoji_sentiment`, `.emoji_incongruity`, `.emoji_polarity_flip` and
`.emoji_incongruent`.

## Details

`.emoji_incongruity` is `emoji - text` after scaling, so it is positive
when the emoji is the more positive of the two. `"sign_flip"` is the
categorical version most sarcasm papers use and is computed on the
*unscaled* scores, where the sign means something.

A row with no scorable emoji gets `NA`, never `0`: a neutral emoji and
no emoji at all are different states, and collapsing them silently
biases every downstream model. The same applies to a missing
`text_score`.

With `where = "final"` only the run of emoji that ends the text is
scored: both the illocutionary-force account of emoji and the P600
evidence on ironic emoji are specifically about sentence-final glyphs. A
text whose emoji sit mid-sentence then has nothing eligible to score, so
it gets `NA` and `.emoji_n_scored = NA`, while `.emoji_n` still counts
every emoji in the row.

## You supply the text score

tidyEmoji deliberately does not score text. `text_score` is a column you
produce with tidytext and AFINN or Bing, sentimentr, vader, or a
transformer – which keeps the method choice visible in your script
instead of buried in this package, and keeps our dependency footprint
where it is.

Because those methods live on wildly different scales (AFINN runs -5 to
5, VADER -1 to 1, a model's logits on nothing in particular), `scale`
has no default: you have to say how the two sides were made comparable.
`"rank"` maps both to percentiles on `[-1, 1]` and is the safest choice
for cross-method comparison; `"zscore"` standardises both; `"none"`
compares the raw numbers, which is only meaningful if your text score
already lives on the emoji lexicon's -1 to 1 scale.

## References

An emoji centric approach to sarcasm detection in online discourse.
*Scientific Reports* (2025). The influence of emoji meaning multipleness
on perceived online review helpfulness. \*Journal of Business Research\*
(2022).

## See also

[`emoji_congruence()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_congruence.md)
for the same engine under the marketing framing;
[`emoji_incongruity_profile()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_incongruity_profile.md)
for which glyphs go against the grain;
[`emoji_sentiment()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sentiment.md)
for the emoji side on its own.

## Examples

``` r
df <- data.frame(
  text = c("this is wonderful \U0001f621", "awful \U0001f621", "great \U0001f600"),
  score = c(0.9, -0.8, 0.7)
)
emoji_incongruity(df, text, score, scale = "none")
#> # A tibble: 3 × 8
#>   text        score .emoji_n .emoji_n_scored .emoji_sentiment .emoji_incongruity
#>   <chr>       <dbl>    <int>           <int>            <dbl>              <dbl>
#> 1 this is wo…   0.9        1               1           -0.173             -1.07 
#> 2 awful 😡     -0.8        1               1           -0.173              0.627
#> 3 great 😀      0.7        1               1            0.572             -0.128
#> # ℹ 2 more variables: .emoji_polarity_flip <lgl>, .emoji_incongruent <lgl>
emoji_incongruity(df, text, score, scale = "none", method = "sign_flip")
#> # A tibble: 3 × 8
#>   text        score .emoji_n .emoji_n_scored .emoji_sentiment .emoji_incongruity
#>   <chr>       <dbl>    <int>           <int>            <dbl>              <dbl>
#> 1 this is wo…   0.9        1               1           -0.173             -1.07 
#> 2 awful 😡     -0.8        1               1           -0.173              0.627
#> 3 great 😀      0.7        1               1            0.572             -0.128
#> # ℹ 2 more variables: .emoji_polarity_flip <lgl>, .emoji_incongruent <lgl>
```
