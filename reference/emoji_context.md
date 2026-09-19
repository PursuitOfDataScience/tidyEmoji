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

- window:

  Size of the context window on each side, in tokens (`unit = "word"`)
  or characters (`unit = "char"`). Default `5`.

- unit:

  `"word"` (default) or `"char"`. "Character" means *code point*, the
  unit [`nchar()`](https://rdrr.io/r/base/nchar.html) and
  [`substr()`](https://rdrr.io/r/base/substr.html) count and the one
  [`emoji_density()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_density.md)
  and
  [`emoji_ratio()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_ratio.md)
  measure in. A character window can therefore begin or end part-way
  through a grapheme cluster: where an `e` carries a combining acute
  (`U+0065 U+0301`), `window = 1` returns the bare `U+0301`, a diacritic
  with nothing to sit on. Emoji themselves are safe from this, being
  masked out whole (see Details), and so is `unit = "word"`. If the
  window is going to be read by a person rather than tokenised, ask for
  words, or for a few more characters than you need.

- keep_text:

  If `TRUE`, also return the row's original text column. Default
  `FALSE`.

## Value

A tibble with one row per emoji occurrence, in reading order, and
columns `.row_number` (position of the entry in `data`), `.position`
(the code-point offset at which the emoji starts, the unit
[`substr()`](https://rdrr.io/r/base/substr.html) takes, so
`substr(text, .position, .position + nchar(.emoji) - 1)` is the glyph;
[`emoji_ngrams()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_ngrams.md)'s
column of the same name counts emoji instead), `.emoji`,
`.emoji_context_left`, `.emoji_context_right` and `.emoji_context` (the
two sides joined by a space – the co-text without the glyph). Rows with
no emoji contribute nothing. The columns of `data` are not carried, so a
grouping is not either – join back on `.row_number` to recover them.

## Details

Windows are taken from the text with *all* emoji blanked out, so a
neighbouring emoji never lands in a context window and character offsets
stay exact. With `unit = "word"` a token is a maximal run of
non-whitespace characters, the same definition
[`emoji_density()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_density.md)
uses; with `unit = "char"` the window is a literal code-point count
after trimming the whitespace next to the emoji.

Tokenisation stops there on purpose. If you need stemming, stopword
removal or sentence splitting, pass the result to tokenizers or tidytext
rather than expecting this verb to grow a tokeniser.

**Whitespace tokenisation has one consequence worth stating outright,
because it is invisible in the output.** A script that does not put
spaces between words (Chinese, Japanese, Thai, Khmer, Lao, Burmese) has
no whitespace for a token to end at, so a whole clause arrives as a
single token and `window = 5` reaches five clauses rather than five
words. This is not something the result can be passed to a tokeniser to
repair: segmentation has to happen *before* the text reaches this verb,
by inserting the spaces (with tokenizers, `jiebaR` or ICU) into the
column you pass in. For a quick look without that, `unit = "char"`
sidesteps the question entirely and is the better default on such text.

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
