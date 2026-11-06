# Emoji density per character and per token

`emoji_density()` measures how emoji-heavy each text is: the number of
emoji per character and per whitespace-delimited token. Rows with no
emoji get densities of 0; rows whose text is `NA` or empty get `NA`.

## Usage

``` r
emoji_density(data, text, presentation = "emoji")
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

`data`, as a tibble, with added columns `.emoji_n`, `.emoji_n_char`
(characters, i.e. code points, of text), `.emoji_n_token`
(whitespace-delimited tokens), `.emoji_per_char` (emoji per character,
i.e. per code point: `.emoji_n / .emoji_n_char`) and `.emoji_per_token`
(`.emoji_n / .emoji_n_token`). A token is a maximal run of characters
outside Unicode's `White_Space` property; see
[`emoji_ratio()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_ratio.md)
for the exact set, which does not vary with the locale. An `NA` text has
`.emoji_n = 0` and `NA` for both denominators and both rates, since its
length is not known; an empty text has denominators of `0` and rates of
`NA`.

## Details

"Character" here means *code point*, the unit
[`nchar()`](https://rdrr.io/r/base/nchar.html) counts, so a
multi-code-point emoji inflates the denominator by all of its code
points. The same visible text therefore gives different answers
depending on how the emoji is built: `"hi <emoji>"` is four graphemes
either way, but `.emoji_per_char` is 0.25 for a single-code-point
smiley, 0.200 for a two-code-point flag and 0.100 for a seven-code-point
ZWJ family. It is not exotic – 79 of the 750 emoji-bearing rows in the
example corpus,
[oasst_messages](https://pursuitofdatascience.github.io/tidyEmoji/reference/oasst_messages.md),
contain a multi-code-point emoji.

This is the same basis
[`emoji_ratio()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_ratio.md)
uses and states, and the opposite of the one
[`emoji_position()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_position.md)
uses: `.emoji_rel_position` counts each emoji as one position, because a
proportion of the message has to. If you want a density that does not
move with an emoji's internal length, `.emoji_per_token` is immune – all
three examples above give 0.5.

Both rates ship with the counts they were computed from, `.emoji_n` over
`.emoji_n_char` and over `.emoji_n_token`, so a count model can be
fitted to the counts with the denominator as its exposure, rather than a
linear model to the quotient. See *Rates and their denominators* in
[tidyEmoji](https://pursuitofdatascience.github.io/tidyEmoji/reference/tidyEmoji-package.md).

## See also

[`emoji_position()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_position.md),
[`emoji_ratio()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_ratio.md).

## Examples

``` r
df <- data.frame(text = c("hi \U0001f600", "\U0001f600\U0001f600", "plain"))
emoji_density(df, text)
#> # A tibble: 3 × 6
#>   text  .emoji_n .emoji_n_char .emoji_n_token .emoji_per_char .emoji_per_token
#>   <chr>    <int>         <int>          <int>           <dbl>            <dbl>
#> 1 hi 😀        1             4              2            0.25              0.5
#> 2 😀😀         2             2              1            1                 2  
#> 3 plain        0             5              1            0                 0  
```
