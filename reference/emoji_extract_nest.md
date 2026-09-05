# Add a list-column of the emoji found in each row

`emoji_extract_nest()` returns `data` unchanged except for an added
list-column, `.emoji_unicode`, holding the emoji found in each row.
Detection is grapheme-aware, so skin-tone modifiers and ZWJ sequences
(for example family emoji) are kept intact as a single emoji.

## Usage

``` r
emoji_extract_nest(data, text)
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

`data`, as a tibble, with an added list-column `.emoji_unicode`. A
grouped input stays grouped.

## See also

[`emoji_extract_unnest()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_extract_unnest.md)
for a long, counted form and
[`emoji_tokens()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_tokens.md)
for one row per emoji with metadata.

## Examples

``` r
df <- data.frame(text = c("hi \U0001f600\U0001f603", "none"))
emoji_extract_nest(df, text)
#> # A tibble: 2 × 2
#>   text    .emoji_unicode
#>   <chr>   <list>        
#> 1 hi 😀😃 <chr [2]>     
#> 2 none    <chr [0]>     
```
