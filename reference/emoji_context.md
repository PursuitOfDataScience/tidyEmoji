# The text around each emoji occurrence

`emoji_context()` returns one row per emoji occurrence with a window of
the text on either side of it. It is the primitive the context-dependent
analyses need: emoji are polysemous, and what a glyph means in a message
is decided by its co-text, not by a lexicon.

## Usage

``` r
emoji_context(
  data,
  text,
  window = 5,
  unit = c("word", "char"),
  keep_text = FALSE
)
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

- window:

  Size of the context window on each side, in tokens (`unit = "word"`)
  or characters (`unit = "char"`). Default `5`.

- unit:

  `"word"` (default) or `"char"`.

- keep_text:

  If `TRUE`, also return the row's original text column. Default
  `FALSE`.

## Value

A tibble with one row per emoji occurrence, in reading order, and
columns `.row_number` (position of the entry in `data`), `.position`
(the character position at which the emoji starts), `.emoji`,
`.emoji_context_left`, `.emoji_context_right` and `.emoji_context` (the
two sides joined by a space – the co-text without the glyph). Rows with
no emoji contribute nothing.

## Details

Windows are taken from the text with *all* emoji blanked out, so a
neighbouring emoji never lands in a context window and character offsets
stay exact. With `unit = "word"` a token is a maximal run of
non-whitespace characters, the same definition
[`emoji_density()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_density.md)
uses; with `unit = "char"` the window is a literal character count after
trimming the whitespace next to the emoji.

Tokenisation stops there on purpose. If you need stemming, stopword
removal or sentence splitting, pass the result to tokenizers or tidytext
rather than expecting this verb to grow a tokeniser.

## See also

[`emoji_collocations()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_collocations.md)
for the corpus-level view;
[`emoji_position()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_position.md)
for where emoji sit in a text.

## Examples

``` r
df <- data.frame(text = c("the coffee was cold \U0001f622 again",
                          "no emoji here"))
emoji_context(df, text, window = 2)
#> # A tibble: 1 × 6
#>   .row_number .position .emoji .emoji_context_left .emoji_context_right
#>         <int>     <int> <chr>  <chr>               <chr>               
#> 1           1        21 😢     was cold            again               
#> # ℹ 1 more variable: .emoji_context <chr>
emoji_context(df, text, window = 6, unit = "char")
#> # A tibble: 1 × 6
#>   .row_number .position .emoji .emoji_context_left .emoji_context_right
#>         <int>     <int> <chr>  <chr>               <chr>               
#> 1           1        21 😢     s cold              again               
#> # ℹ 1 more variable: .emoji_context <chr>
```
