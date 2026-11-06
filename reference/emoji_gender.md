# The gender the emoji in a text column depict

`emoji_gender()` counts, per row, the person emoji by the gender they
are drawn with. This is the gender a glyph depicts, not the writer's and
not the reader's; see *Glyphs, not people* in
[tidyEmoji](https://pursuitofdatascience.github.io/tidyEmoji/reference/tidyEmoji-package.md).
Studies of the gender of the *people* sending emoji, such as Lin (2025),
ask a different question, which this verb does not answer.

## Usage

``` r
emoji_gender(data, text, presentation = "emoji")
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

`data`, as a tibble, with added columns `.emoji_n_gender_variable`
(occurrences of a person emoji whose family has more than one gender
form), `.emoji_n_female`, `.emoji_n_male`, `.emoji_n_neutral` and
`.emoji_n_mixed` (occurrences by the gender they depict) and
`.emoji_gender` (the row's one gender, `"mixed"` when its emoji differ,
or `NA` when none depicts a gender). A grouped input stays grouped.

## Details

The classification is
[`emoji_decompose()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_decompose.md)'s:
the female and male signs, the gendered people (woman, man, girl, boy,
old woman, old man), and a list of twelve emoji whose gender lives in a
single code point, such as prince and princess. `"mixed"` is a
multi-person emoji showing both, a couple or a family, and is this
package's own derivation. `"neutral"` is Unicode's gender-neutral form,
which platforms draw differently.

**Gender-variable** emoji are the ones whose catalogue family has more
than one gender form: person, woman and man running, or the prince, the
princess and the person with crown. The families are derived from the
catalogue, by grouping every emoji under its gender-neutral form, not
listed by hand. `.emoji_n_gender_variable` is the denominator for "how
often did writers pick a gendered form": the woman dancing has no other
form and so is female without being a choice.

## References

Lin, Z.-X. (2025). Exploring gender differences in emoji usage:
implications for human-computer interaction. *Proceedings of the Fourth
Workshop on Bridging Human-Computer Interaction and Natural Language
Processing (HCI+NLP)*, 274-282.

## See also

[`emoji_decompose()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_decompose.md);
[`emoji_skin_tone()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_skin_tone.md)
for tones.

## Examples

``` r
d <- data.frame(text = c("\U0001f3c3\u200d\u2640\ufe0f and \U0001f3c3",
                         "\U0001f483 \U0001f57a",
                         "no people \U0001f600"))
emoji_gender(d, text)
#> # A tibble: 3 × 7
#>   text     .emoji_n_gender_vari…¹ .emoji_n_female .emoji_n_male .emoji_n_neutral
#>   <chr>                     <int>           <int>         <int>            <int>
#> 1 🏃‍♀️ and 🏃…                      2               1             0                1
#> 2 💃 🕺                         0               1             1                0
#> 3 no peop…                      0               0             0                0
#> # ℹ abbreviated name: ¹​.emoji_n_gender_variable
#> # ℹ 2 more variables: .emoji_n_mixed <int>, .emoji_gender <chr>
```
