# Skin tones in a text column, with their denominator

`emoji_skin_tone()` counts, per row, the emoji that can carry a skin
tone, how many of them do, and which tones they carry. It describes the
glyphs a text uses and never infers anyone's skin colour or identity;
see *Glyphs, not people* in
[tidyEmoji](https://pursuitofdatascience.github.io/tidyEmoji/reference/tidyEmoji-package.md).

## Usage

``` r
emoji_skin_tone(data, text, presentation = "emoji")
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

`data`, as a tibble, with added columns `.emoji_n_modifiable`
(occurrences of an emoji that can take a tone, toned or not),
`.emoji_n_modified` (those that carry one), `.emoji_n_light`,
`.emoji_n_medium_light`, `.emoji_n_medium`, `.emoji_n_medium_dark` and
`.emoji_n_dark` (tone instances, so a couple in two tones adds to two
columns and one in a single tone adds two to one), `.emoji_n_mixed`
(occurrences carrying two or more distinct tones),
`.emoji_n_orphan_modifiers` (swatches standing alone) and `.emoji_tone`
(the row's one tone, `"default"`, `"mixed"` when its tone-able emoji
differ, or `NA` when it has none). A grouped input stays grouped.

## Details

Both halves of that sentence have evidence behind them. Writers mostly
choose a tone close to their own (Robertson, Magdy and Goldwater 2018,
2020), so tones *are* informative about writers in aggregate; and
readers infer the writer's identity from a tone, the default yellow
included (CSCW 2021), which is exactly why a tool must not. `"default"`
means a tone-able emoji written without a tone, which is a keyboard
setting on some platforms and an active choice on others.

**Report the denominator.** The share of tone-able emoji that carry a
tone differs tenfold between corpora: 88.9% of 117 on the tweet sample
this package bundled until 0.7.0, 9.2% of 782 in all of OASST2, 8.0% of
1,445 in a WildChat shard, and 23.2% of 181 in
[oasst_messages](https://pursuitofdatascience.github.io/tidyEmoji/reference/oasst_messages.md),
whose half carrying emoji was sampled for them. A bare percentage cannot
tell a difference in the writers from a difference in which emoji they
chose, so the verb returns the two counts and leaves the ratio to you,
which is also what makes it right for any grouping:

    emoji_skin_tone(d, text) |>
      dplyr::group_by(author) |>
      dplyr::summarise(modified = sum(.emoji_n_modified),
                       modifiable = sum(.emoji_n_modifiable),
                       share = modified / modifiable)

A swatch standing alone, as in `U+1F600 U+1F3FB`, where the face cannot
take the tone, is no emoji (see the *Detection* section of
[tidyEmoji](https://pursuitofdatascience.github.io/tidyEmoji/reference/tidyEmoji-package.md))
and so in none of the tone counts; `.emoji_n_orphan_modifiers` accounts
for it.

## References

Robertson, A., Magdy, W. and Goldwater, S. (2018). Self-representation
on Twitter using emoji skin color modifiers. *ICWSM 2018*, 680-683.

Robertson, A., Magdy, W. and Goldwater, S. (2020). Emoji skin tone
modifiers: analyzing variation in usage on social media. *ACM
Transactions on Social Computing* 3(2).
[doi:10.1145/3377479](https://doi.org/10.1145/3377479)

Black or white but never neutral: how readers perceive identity from
yellow or skin-toned emoji (2021). *Proceedings of the ACM on
Human-Computer Interaction* 5 (CSCW2).
[doi:10.1145/3476091](https://doi.org/10.1145/3476091)

## See also

[`emoji_decompose()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_decompose.md)
for one glyph at a time;
[`emoji_retone()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_retone.md)
to rewrite the tones for an experiment.

## Examples

``` r
d <- data.frame(text = c("thanks \U0001f44d\U0001f3fd",
                         "\U0001f44d and \U0001f44b\U0001f3ff",
                         "a \U0001f600\U0001f3fb b"))
emoji_skin_tone(d, text)
#> # A tibble: 3 × 11
#>   text      .emoji_n_modifiable .emoji_n_modified .emoji_n_light
#>   <chr>                   <int>             <int>          <int>
#> 1 thanks 👍🏽                   1                 1              0
#> 2 👍 and 👋🏿                   2                 1              0
#> 3 a 😀🏻 b                      0                 0              0
#> # ℹ 7 more variables: .emoji_n_medium_light <int>, .emoji_n_medium <int>,
#> #   .emoji_n_medium_dark <int>, .emoji_n_dark <int>, .emoji_n_mixed <int>,
#> #   .emoji_n_orphan_modifiers <int>, .emoji_tone <chr>
```
