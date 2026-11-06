# Rewrite every skin tone in a text column to one tone

`emoji_retone()` rewrites the text so that every emoji that can carry a
skin tone carries `tone`, every person in a multi-person emoji alike,
and `"default"` takes the tones out. It rewrites glyphs for an
experiment and describes no person; see *Glyphs, not people* in
[tidyEmoji](https://pursuitofdatascience.github.io/tidyEmoji/reference/tidyEmoji-package.md).

## Usage

``` r
emoji_retone(data, text, tone = "default", presentation = "emoji")
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

- tone:

  The tone to write: `"default"` (no tone, the default), `"light"`,
  `"medium_light"`, `"medium"`, `"medium_dark"` or `"dark"`.

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

`data`, as a tibble, with the text column rewritten and two columns
added: `.emoji_n_retoned` (the tone-able occurrences now in `tone`, the
ones already in it included) and `.emoji_n_unretonable` (those left as
they were for want of a catalogue spelling). The two add up to
[`emoji_skin_tone()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_skin_tone.md)'s
`.emoji_n_modifiable`. A grouped input stays grouped.

## Details

**Why it exists.** The way to measure how a model treats skin tones is
to give it the same text in each tone and compare, as "Digital Skin,
Digital Bias" (Li et al. 2026) does for language models and emoji
embeddings. A regular expression over `U+1F3FB` to `U+1F3FF` gets
multi-person emoji and the selector cases wrong; this reads the
catalogue instead. A paired design:

    arms <- c("default", "light", "medium", "dark")
    copies <- lapply(arms, function(t) emoji_retone(d, text, tone = t))
    # score each copy with your own model, then compare the arms row by row

**Rules.** The rewritten spelling is always one the catalogue lists.
Where there is none, the occurrence is left as it was and counted in
`.emoji_n_unretonable`; on the Emoji 18.0 catalogue that never happens.
A swatch standing alone is left alone, and so is every emoji that cannot
take a tone. The column is rewritten in place, as
[`emoji_sanitize()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sanitize.md)
does.

## References

Li, M. et al. (2026). Digital skin, digital bias: uncovering tone-based
biases in LLMs and emoji embeddings. *Proceedings of the ACM Web
Conference 2026*.
[doi:10.1145/3774904.3792508](https://doi.org/10.1145/3774904.3792508)

## See also

[`emoji_skin_tone()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_skin_tone.md)
to count the tones first;
[`emoji_decompose()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_decompose.md).

## Examples

``` r
d <- data.frame(text = c("thanks \U0001f44d\U0001f3fd",
                         "\U0001f9d1\U0001f3fb\u200d\U0001f91d\u200d\U0001f9d1\U0001f3ff"))
emoji_retone(d, text, tone = "dark")
#> # A tibble: 2 × 3
#>   text      .emoji_n_retoned .emoji_n_unretonable
#>   <chr>                <int>                <int>
#> 1 thanks 👍🏿                1                    0
#> 2 🧑🏿‍🤝‍🧑🏿                       1                    0
emoji_retone(d, text)
#> # A tibble: 2 × 3
#>   text      .emoji_n_retoned .emoji_n_unretonable
#>   <chr>                <int>                <int>
#> 1 thanks 👍                1                    0
#> 2 🧑‍🤝‍🧑                       1                    0
```
