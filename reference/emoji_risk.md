# Interpretation risk per row

`emoji_risk()` scores how likely each row's emoji are to be *misread*,
using the annotation-disagreement statistics of
[`emoji_ambiguity()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_ambiguity.md).
It is the content-QA counterpart of
[`emoji_sentiment()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sentiment.md):
a row can carry a confident positive score built entirely out of glyphs
its annotators fought over.

## Usage

``` r
emoji_risk(data, text, measure = "entropy", threshold = NULL)
```

## Arguments

- data:

  A data frame or tibble containing a text column.

- text:

  The text column to scan, supplied unquoted.

- measure:

  Ambiguity statistic to use; see
  [`emoji_ambiguity()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_ambiguity.md).

- threshold:

  Value at or above which a glyph counts as ambiguous. `NULL` (default)
  uses the lexicon's upper quartile of `measure`.

## Value

`data`, as a tibble, with added columns `.emoji_n`, `.emoji_n_scored`,
`.emoji_ambiguity_mean`, `.emoji_ambiguity_max` and
`.emoji_n_ambiguous`. Rows with no emoji get `NA` throughout.

## Details

`threshold` decides what counts as an ambiguous glyph for
`.emoji_n_ambiguous`. The default, `NULL`, uses the upper quartile of
the chosen measure across the whole lexicon, i.e. "in the most-disputed
quarter of all emoji". Supply your own number to make the cut-off
explicit in your script.

Emoji absent from the lexicon cannot be scored and are excluded from the
means; `.emoji_n` and `.emoji_n_scored` together show how much of the
row was actually measured.

## See also

[`emoji_ambiguity()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_ambiguity.md),
[`emoji_flag_ambiguous()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_flag_ambiguous.md).

## Examples

``` r
df <- data.frame(text = c("thanks \U0001f643", "great \U0001f600", "plain"))
emoji_risk(df, text)
#> # A tibble: 3 × 6
#>   text      .emoji_n .emoji_n_scored .emoji_ambiguity_mean .emoji_ambiguity_max
#>   <chr>        <int>           <int>                 <dbl>                <dbl>
#> 1 thanks 🙃        1               0                NA                   NA    
#> 2 great 😀         1               1                 0.835                0.835
#> 3 plain            0              NA                NA                   NA    
#> # ℹ 1 more variable: .emoji_n_ambiguous <int>
```
