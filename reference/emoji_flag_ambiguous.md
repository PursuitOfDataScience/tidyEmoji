# Which emoji in this corpus are most likely to be misread?

`emoji_flag_ambiguous()` crosses the emoji actually present in a text
column with their annotation-disagreement statistics and returns the
most ambiguous ones first. It is the content-QA shortlist: the glyphs
worth a second look before a campaign ships or a coding scheme is fixed.

## Usage

``` r
emoji_flag_ambiguous(data, text, top_n = 10, measure = "entropy")
```

## Arguments

- data:

  A data frame or tibble containing a text column.

- text:

  The text column to scan, supplied unquoted.

- top_n:

  Number of emoji to return, most ambiguous first. `NULL` returns all of
  them.

- measure:

  Ambiguity statistic to rank by; see
  [`emoji_ambiguity()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_ambiguity.md).

## Value

A tibble with columns `emoji`, `name`, `n` (occurrences in the corpus),
`n_annotations`, `ambiguity` and `rank` (the glyph's rank in the whole
lexicon). Emoji absent from the lexicon cannot be ranked and are
dropped.

## See also

[`emoji_ambiguity()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_ambiguity.md),
[`emoji_risk()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_risk.md).

## Examples

``` r
df <- data.frame(text = c("ok \U0001f643", "yay \U0001f600 \U0001f643",
                          "hmm \U0001f612"))
emoji_flag_ambiguous(df, text, top_n = 3)
#> # A tibble: 2 × 6
#>   emoji name              n n_annotations ambiguity  rank
#>   <chr> <chr>         <int>         <int>     <dbl> <int>
#> 1 😒    unamused face     1          1385     0.959   233
#> 2 😀    grinning face     1           439     0.835   410
```
