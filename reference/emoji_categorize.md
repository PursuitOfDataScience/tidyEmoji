# Categorise each row by the emoji categories it contains

`emoji_categorize()` keeps the rows of `data` that contain emoji and
adds a `.emoji_category` column listing the distinct Unicode categories
present in that row (for example "Smileys & Emotion"), separated by `|`
when a row spans more than one category.

## Usage

``` r
emoji_categorize(data, text, presentation = "emoji")
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

- presentation:

  Which code points count as emoji: `"emoji"` (the default) or `"any"`.

  - `"emoji"` requires emoji presentation, so `U+2764 U+FE0F` is an
    emoji and the bare `U+2764` is not. This is the default and it will
    stay the default: widening it would silently recount every corpus
    already analysed.

  - `"any"` also reads the text-presentation spellings Unicode lists for
    an emoji (the bare heart, `U+263A`, `U+2714`, a keycap without its
    selector), because several keyboards emit them. It never reads the
    copyright, registered and trade-mark signs (`U+00A9`, `U+00AE`,
    `U+2122`), which are typography far more often than they are emoji.

  `"any"` only ever adds occurrences: everything `"emoji"` finds, it
  finds too, in the same place.
  [`emoji_coverage()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_coverage.md)
  reports how many it adds and how many of those a lexicon can score,
  which is the cost of the choice in one number. Every verb that counts,
  scores or rewrites the emoji in a text column takes this argument, so
  counts still agree across the package for whichever value you use. The
  flag verbs do not need it, since a flag has no text-presentation form.

## Value

`data`, as a tibble, filtered to the rows containing at least one emoji,
with an added `.emoji_category` column. That column is `NA` for a row
whose emoji are all absent from the reference table.

## Details

A row is kept because it contains an emoji, not because that emoji could
be categorised. If none of a row's emoji is in the reference table the
row is kept with `.emoji_category` set to `NA`. Dropping it would
silently shrink the corpus, and by exactly the rows a user whose Unicode
coverage is behind most needs to see.

Two different things reach that `NA`, and only the first is a catalogue
question:

1.  A zero-width-joiner sequence **newer than the bundled catalogue**,
    since detection is grapheme-aware and does not require the sequence
    to be catalogued. Use
    [`emoji_provenance()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_provenance.md)
    to check which catalogue you are matching against; a tidyEmoji
    release built on a newer Unicode file fixes it.

2.  A **non-RGI ZWJ join**: components joined in a combination Unicode
    does not recommend, which no catalogue lists.

An invalid regional-indicator pair such as `U+1F1FD U+1F1FD` used to be
a third. Since 0.6.0 it is not an emoji at all, so it no longer keeps a
row here; see the Detection section of
[tidyEmoji](https://pursuitofdatascience.github.io/tidyEmoji/reference/tidyEmoji-package.md).

## See also

[`emoji_type()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_type.md)
for the smaller functional vocabulary recoded from the same group and
subgroup, and
[`emoji_faceness()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_faceness.md)
for the face share it reduces to;
[`emoji_frequency()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_frequency.md)
for per-glyph counts carrying `group`;
[category_unicode_crosswalk](https://pursuitofdatascience.github.io/tidyEmoji/reference/category_unicode_crosswalk.md)
for the ten categories themselves.

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
