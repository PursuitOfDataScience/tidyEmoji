# Summarise emoji presence in a text column

`emoji_summary()` reports how many entries in a text column contain at
least one emoji, alongside the total number of entries. An entry is
counted once regardless of how many emoji it holds.

## Usage

``` r
emoji_summary(data, text, presentation = "emoji")
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

A one-row tibble with columns `n_with_emoji` (entries containing at
least one emoji), `n_total` (all entries), `n_orphan_components` and
`n_invalid_flags`. The last two count *glyphs*, not entries: the emoji
material the text holds that is not an emoji, and so is in no other
count. `n_orphan_components` is the skin-tone swatches and hair
components standing alone, as in `U+1F600 U+1F3FB`, where the tone
follows a base that cannot take one; `n_invalid_flags` is the runs of
regional indicators that spell no country, such as `U+1F1FD U+1F1FD`
("XX") or a lone indicator. Both were counted as emoji before 0.6.0, so
they are what to look at when a corpus reports fewer emoji than it used
to. See the *Detection* section of
[tidyEmoji](https://pursuitofdatascience.github.io/tidyEmoji/reference/tidyEmoji-package.md).

## See also

[`emoji_filter()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_filter.md)
to keep the emoji-bearing rows themselves;
[`emoji_coverage()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_coverage.md)
for what a lexicon can score of them.

## Examples

``` r
df <- data.frame(text = c("I love R \U0001f600",
                          "no emoji here",
                          "flags \U0001f3c1\U0001f600"))
emoji_summary(df, text)
#> # A tibble: 1 × 4
#>   n_with_emoji n_total n_orphan_components n_invalid_flags
#>          <int>   <int>               <int>           <int>
#> 1            2       3                   0               0

# a bare heart is an emoji only under presentation = "any"
hearts <- data.frame(text = c("I \u2764 R", "I \u2764\ufe0f R"))
emoji_summary(hearts, text)
#> # A tibble: 1 × 4
#>   n_with_emoji n_total n_orphan_components n_invalid_flags
#>          <int>   <int>               <int>           <int>
#> 1            1       2                   0               0
emoji_summary(hearts, text, presentation = "any")
#> # A tibble: 1 × 4
#>   n_with_emoji n_total n_orphan_components n_invalid_flags
#>          <int>   <int>               <int>           <int>
#> 1            2       2                   0               0
```
