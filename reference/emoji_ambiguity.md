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
`rank`. `rank` is `1` for the most ambiguous emoji; glyphs with
identical `ambiguity` **share** the lowest rank of their group and the
next distinct value skips ahead accordingly
([`rank()`](https://rdrr.io/r/base/rank.html)'s `ties.method = "min"`),
so ranks are not necessarily consecutive. With `x = NULL` rows are
ordered by `rank` with ties broken by the glyph, so the order is
deterministic; with `x` supplied the result has one row per element of
`x`, in the same order.

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

**Read `n_annotations` before you read the ranking.** The lexicon's
annotation counts are wildly uneven – the median glyph has 18, and 69%
have fewer than 50 – and the first three measures are shape statistics
that do not care how many annotations produced the shape. A glyph seen
by three annotators who split one-one-one scores the maximum entropy of
`log(3)` on that evidence alone, which is why five of the rows tied at
`rank = 1` have 3, 3, 3, 9 and 15 annotations, and why 11 of the top 20
have fewer than 50.

Three of those five are not emoji at all. The lexicon was built from
2015 tweets and 233 of its 969 rows are characters absent from the
reference table – box-drawing characters, dingbats, enclosed letters –
so the head of the ranking can show a glyph such as `U+250C` that no
corpus this package analyses will ever yield. They carry 6% of the
lexicon's annotations and 86% of them have fewer than 50, so the
`n_annotations` filter recommended here removes 200 of the 233 as a side
effect. See the *Detection limitations* section of
[emoji_sentiment_lexicon](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sentiment_lexicon.md)
for what the rest of them are.

The bias is at the *top* of the ranking specifically, not across it: a
thinly annotated glyph is usually unanimous, so entropy is positively
correlated with the annotation count overall (Spearman 0.56). What three
annotators can do that thousands cannot is hit the exact maximum. So
filter on `n_annotations` before interpreting the head of the table, as
the introduction vignette does. That advice applies to `"ci_width"` too,
and the reason is worth stating plainly, because the obvious reading of
a confidence width is that it has already accounted for thin evidence:

`"ci_width"` is a **Wald** interval, so it scales as `1 / sqrt(n)` only
*at a given spread*, and it is exactly zero wherever the spread is zero.
For a glyph whose annotators were unanimous the estimated variance is 0
whatever `n` is, so the interval has zero width on one annotation just
as on eight thousand. That is the textbook degeneracy of the Wald
interval at a boundary proportion, not a property of the data: **166 of
the lexicon's 969 rows report `ci_width = 0`, and their annotation
counts run from 1 to 68.** So `ci_width` does not rescue a thin glyph –
ranked ascending it puts the thinnest unanimous ones first, as the most
certain rows in the table. `n_annotations` remains the column to filter
on; `ci_width` separates well-known from poorly-known scores only among
glyphs that are not unanimous.

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

# the head of that table is glyphs a handful of annotators disagreed about;
# filter on n_annotations before reading it as a finding
amb <- emoji_ambiguity()
head(amb[amb$n_annotations >= 500, ])
#> # A tibble: 6 × 8
#>   emoji key   n_annotations p_neg p_neu p_pos ambiguity  rank
#>   <chr> <chr>         <int> <dbl> <dbl> <dbl>     <dbl> <int>
#> 1 😳    1F633           846 0.327 0.327 0.345      1.10     6
#> 2 💯    1F4AF           637 0.281 0.317 0.402      1.09    16
#> 3 😴    1F634           718 0.422 0.237 0.341      1.07    43
#> 4 😢    1F622           749 0.385 0.224 0.391      1.07    47
#> 5 😱    1F631          1130 0.264 0.282 0.454      1.07    50
#> 6 😭    1F62D          5526 0.436 0.220 0.343      1.06    54

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
