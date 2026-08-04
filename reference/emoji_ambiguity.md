# How ambiguous is each emoji?

`emoji_ambiguity()` reports, for every emoji in the Emoji Sentiment
Ranking (see
[emoji_sentiment_lexicon](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sentiment_lexicon.md)),
how much its human annotators disagreed about whether it was negative,
neutral or positive. Miller et al. (2016) found that readers of the same
rendering disagree about a quarter of the time; the bundled lexicon
keeps the raw annotation counts behind its collapsed score, so that
disagreement can be reported as a number rather than described as a
caveat.

## Usage

``` r
emoji_ambiguity(x = NULL, measure = "entropy")
```

## Arguments

- x:

  Optional character vector of emoji glyphs to report on. The default,
  `NULL`, returns every emoji in the lexicon, most ambiguous first.
  Glyphs absent from the lexicon come back with `NA` statistics.

- measure:

  Which ambiguity statistic to put in the `ambiguity` column: one of
  `"entropy"` (default), `"gini"`, `"neutral_share"` or `"ci_width"`.

## Value

A tibble with columns `emoji`, `key` (the codepoint-normalised join
key), `n_annotations`, `p_neg`, `p_neu`, `p_pos`, `ambiguity` and
`rank`. With `x` supplied the result has one row per element of `x`, in
the same order.

## Details

The four measures are computed from the annotation shares
`(p_neg, p_neu, p_pos)`:

- `"entropy"` (the default) is Shannon entropy in nats: 0 when the
  annotators were unanimous, `log(3)` (about 1.0986) when they split
  evenly three ways.

- `"gini"` is the Gini impurity, `1 - sum(p^2)`: 0 when unanimous, 2/3
  at maximum disagreement.

- `"neutral_share"` is `p_neu` on its own, for the "is this emoji simply
  uninformative?" question.

- `"ci_width"` is the width of a 95% Wald interval around the glyph's
  sentiment score. Unlike the other three it shrinks as the number of
  annotations grows, so it answers "how well do we know this score?"
  rather than "how much do readers disagree?".

`rank` is always computed over the whole lexicon (1 = most ambiguous),
so a rank keeps its meaning when `x` selects a handful of glyphs.

## References

Miller H, Thebault-Spieker J, Chang S, Johnson I, Terveen L, Hecht B
(2016). "Blissfully Happy" or "Ready to Fight": Varying Interpretations
of Emoji. *ICWSM 2016*.

## See also

[`emoji_risk()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_risk.md)
for the per-row version,
[`emoji_flag_ambiguous()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_flag_ambiguous.md)
for the emoji in your own corpus, and
[`emoji_sentiment()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sentiment.md)
with `se = TRUE` for the uncertainty around a score.

## Examples

``` r
head(emoji_ambiguity())
#> # A tibble: 6 × 8
#>   emoji key   n_annotations p_neg p_neu p_pos ambiguity  rank
#>   <chr> <chr>         <int> <dbl> <dbl> <dbl>     <dbl> <int>
#> 1 ⇢     21E2              3 0.333 0.333 0.333      1.10     1
#> 2 ┌     250C              3 0.333 0.333 0.333      1.10     1
#> 3 ✗     2717              3 0.333 0.333 0.333      1.10     1
#> 4 ❔    2754              9 0.333 0.333 0.333      1.10     1
#> 5 🎭    1F3AD            15 0.333 0.333 0.333      1.10     1
#> 6 😳    1F633           846 0.327 0.327 0.345      1.10     6
emoji_ambiguity(c("\U0001f602", "\U0001f643"))
#> # A tibble: 2 × 8
#>   emoji key   n_annotations  p_neg  p_neu  p_pos ambiguity  rank
#>   <chr> <chr>         <int>  <dbl>  <dbl>  <dbl>     <dbl> <int>
#> 1 😂    1F602         14622  0.247  0.285  0.468      1.06    68
#> 2 🙃    1F643            NA NA     NA     NA         NA       NA
head(emoji_ambiguity(measure = "ci_width"))
#> # A tibble: 6 × 8
#>   emoji key   n_annotations p_neg p_neu p_pos ambiguity  rank
#>   <chr> <chr>         <int> <dbl> <dbl> <dbl>     <dbl> <int>
#> 1 ⬛    2B1B              3 0.667     0 0.333      2.13     1
#> 2 🎱    1F3B1             3 0.333     0 0.667      2.13     1
#> 3 📙    1F4D9             3 0.333     0 0.667      2.13     1
#> 4 🔕    1F515             3 0.667     0 0.333      2.13     1
#> 5 ⓒ     24D2              4 0.5       0 0.5        1.96     5
#> 6 👃    1F443             4 0.5       0 0.5        1.96     5
```
