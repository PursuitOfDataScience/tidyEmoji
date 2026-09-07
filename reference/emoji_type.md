# Which functional types of emoji does each row use?

`emoji_type()` adds `.emoji_type`, the distinct functional types present
in each row (see
[`as_emoji_type()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/as_emoji_type.md)),
separated by `|` when a row spans more than one. The face-versus-object
contrast it exposes is the key variable in the consumer-behaviour
literature on emoji in reviews and marketing copy.

## Usage

``` r
emoji_type(data, text)
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

  The text column to scan, supplied unquoted. Any atomic column is
  accepted and read as character, so a `factor` works and a numeric,
  `Date` or logical one simply contains no emoji. A list column – or a
  data-frame column – is refused rather than coerced, because coercing
  one deparses it and the emoji found would be in the code rather than
  in your data. What counts as an emoji is the same in every verb; see
  the *Detection* section of
  [tidyEmoji](https://pursuitofdatascience.github.io/tidyEmoji/reference/tidyEmoji-package.md)
  for the one case that surprises people, code points that are emoji
  only when they carry `U+FE0F`.

## Value

`data`, as a tibble, with an added `.emoji_type` column. Unlike
[`emoji_categorize()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_categorize.md),
no rows are dropped: a row with no emoji gets `NA`, as does a row whose
emoji cannot be typed – see Details.

## Details

`.emoji_type` is `NA` for two different reasons, and this column cannot
tell you which: a row with no emoji at all, and a row whose every emoji
is one the recode cannot type. The second is rare but not impossible –
the recode maps the ten Unicode groups the catalogue currently uses, so
a glyph in a group added to Unicode after your emoji package was built
has no type – and it is the same conflation
[`emoji_categorize()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_categorize.md)
describes for `.emoji_category`.
[`emoji_faceness()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_faceness.md)
separates them: `.emoji_n_typed` is `NA` when the row had no emoji and
`0` when it had emoji that could not be typed.
[`emoji_provenance()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_provenance.md)
reports which catalogue you are matching against.

## See also

[`as_emoji_type()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/as_emoji_type.md),
[`emoji_faceness()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_faceness.md),
[`emoji_categorize()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_categorize.md).

## Examples

``` r
df <- data.frame(text = c("yum \U0001f355 \U0001f600", "\U0001f44d", "none"))
emoji_type(df, text)
#> # A tibble: 3 × 2
#>   text      .emoji_type
#>   <chr>     <chr>      
#> 1 yum 🍕 😀 face|food  
#> 2 👍        gesture    
#> 3 none      NA         
```
