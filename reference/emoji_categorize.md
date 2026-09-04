# Categorise each row by the emoji categories it contains

`emoji_categorize()` keeps the rows of `data` that contain emoji and
adds a `.emoji_category` column listing the distinct Unicode categories
present in that row (for example "Smileys & Emotion"), separated by `|`
when a row spans more than one category.

## Usage

``` r
emoji_categorize(data, text)
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

## Value

`data`, as a tibble, filtered to the rows containing at least one emoji,
with an added `.emoji_category` column. That column is `NA` for a row
whose emoji are all absent from the reference table.

## Details

A row is kept because it contains an emoji, not because that emoji could
be categorised. If none of a row's emoji is in the reference table –
which happens for a zero-width-joiner sequence newer than your installed
emoji package, since detection is grapheme-aware and does not require
the sequence to be catalogued – the row is kept with `.emoji_category`
set to `NA`. Dropping it would silently shrink the corpus, and by
exactly the rows a user whose Unicode coverage is behind most needs to
see. Use
[`emoji_provenance()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_provenance.md)
to check which catalogue you are matching against.

## Examples

``` r
df <- data.frame(text = c("smile \U0001f600",
                          "flag \U0001f3c1\U0001f600",
                          "nothing"))
emoji_categorize(df, text)
#> # A tibble: 2 × 2
#>   text      .emoji_category        
#>   <chr>     <chr>                  
#> 1 smile 😀  Smileys & Emotion      
#> 2 flag 🏁😀 Flags|Smileys & Emotion
```
