# What share of the text is emoji, and is it emoji-only?

`emoji_ratio()` reports, per row, the share of the text's characters
that belong to emoji, and whether the text is emoji-only (nothing left
after removing emoji and whitespace). "Emoji-only" messages are a
studied signal in social-media research and a useful filter in practice.

## Usage

``` r
emoji_ratio(data, text, presentation = "emoji")
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

`data`, as a tibble, with added columns `.emoji_n`, `.emoji_codepoints`
(code points belonging to emoji), `.emoji_n_char` (all code points),
`.emoji_ratio` (`.emoji_codepoints / .emoji_n_char`, 0 when there are no
emoji) and `.emoji_only` (`TRUE` when the text contains emoji and
nothing else but whitespace). "Whitespace" is Unicode's `White_Space`
property, written out explicitly rather than left to the C library: it
includes the no-break spaces `U+00A0` and `U+202F` and the ideographic
space `U+3000`, and excludes the zero-width space `U+200B`, which
despite its name Unicode does not classify as whitespace. The same set
is used everywhere the package splits or trims text, and it does not
vary with the locale. `NA` text gets `NA` in both, and in
`.emoji_n_char`, with `0` in the two emoji counts. Empty text (`""`) has
no characters to take a share of, so `.emoji_ratio` is `NA` there too,
but `.emoji_only` is `FALSE`: an empty string is not a row of emoji.

## Details

The ratio is computed over characters (code points), so a
multi-code-point emoji (a ZWJ family, a skin-tone sequence) contributes
all of its characters. It ships with both of the counts it is the
quotient of, `.emoji_codepoints` and `.emoji_n_char`, and with
`.emoji_n`, the number of emoji those code points make up; see *Rates
and their denominators* in
[tidyEmoji](https://pursuitofdatascience.github.io/tidyEmoji/reference/tidyEmoji-package.md).

A skin-tone swatch or hair component standing alone, or a regional
indicator that spells no flag, is not an emoji (see the *Detection*
section of
[tidyEmoji](https://pursuitofdatascience.github.io/tidyEmoji/reference/tidyEmoji-package.md)),
so it adds nothing to `.emoji_n` or `.emoji_codepoints`. It is not text
either, so it does not stop a row being `.emoji_only`: `U+1F600 U+1F3FB`
is one emoji, a ratio of `0.5`, and emoji-only.

## See also

[`emoji_position()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_position.md),
[`emoji_density()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_density.md);
[`emoji_filter()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_filter.md)
to keep emoji-bearing rows.

## Examples

``` r
df <- data.frame(text = c("\U0001f600\U0001f389", "half \U0001f600", "no"))
emoji_ratio(df, text)
#> # A tibble: 3 × 6
#>   text    .emoji_n .emoji_codepoints .emoji_n_char .emoji_ratio .emoji_only
#>   <chr>      <int>             <int>         <int>        <dbl> <lgl>      
#> 1 😀🎉           2                 2             2        1     TRUE       
#> 2 half 😀        1                 1             6        0.167 FALSE      
#> 3 no             0                 0             2        0     FALSE      
```
