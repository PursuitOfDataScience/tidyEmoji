# Accessibility facts about the emoji in a text column

`emoji_a11y_check()` reports, per row, the facts the accessibility
taxonomy of Griggio, Gorman and Tigwell (CSCW 2024) is built from: how
often an emoji or a sequence repeats, where emoji sit, which are
ambiguous or carry long modified names, and how many characters a screen
reader would say for them. It reports facts and gives no verdicts:
whether a message is too much is the writer's call, which is the paper's
own finding.

## Usage

``` r
emoji_a11y_check(data, text, max_name = 40L, presentation = "emoji")
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

- max_name:

  A name longer than this many characters counts in
  `.emoji_n_long_names`. Default `40`.

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

`data`, as a tibble, with added columns `.emoji_max_repeat`,
`.emoji_n_repeated_seqs`, `.emoji_longest_run`, `.emoji_n_mid`,
`.emoji_n_begin`, `.emoji_n_ambiguous`, `.emoji_n_modifier_names` (see
Details), `.emoji_spoken_chars` (the characters of the row's emoji
names), `.emoji_n_char` (the text's own length, the denominator; `NA`
for `NA` text), `.emoji_n_long_names` (names longer than `max_name`),
`.emoji_n_ri_letters` (regional indicators that spell no flag, which a
screen reader reads out one letter at a time) and `.emoji_n_hidden`
(hidden code points, as
[`emoji_hidden()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_hidden.md)
counts them). A grouped input stays grouped.

## Details

The columns follow the taxonomy. **Number of emoji:**
`.emoji_max_repeat` (1a, one emoji repeated), `.emoji_n_repeated_seqs`
(1b, the same pair of different emoji written together more than once; a
run of one emoji is 1a, not 1b) and `.emoji_longest_run` (1c, a run of
emoji of any kind, as
[`emoji_runs()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_runs.md)
segments it). **Placement:** `.emoji_n_mid` (2a, inside the text) and
`.emoji_n_begin` (2b, opening it). The package does no sentence
segmentation, so these are relative to the row; split your text into
sentences first and they are exactly the paper's. **Purpose:**
`.emoji_n_ambiguous` (3a, emoji in the top tenth of
[`emoji_ambiguity()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_ambiguity.md)'s
polarisation, which reads the bundled lexicon and so is 0 for the emoji
it cannot score;
[`emoji_coverage()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_coverage.md)
says how many those are) and `.emoji_n_modifier_names` (3b, emoji whose
name a skin tone or a gender extends, as in "woman facepalming: light
skin tone").

The paper's Alert fired on one emoji three times, two emoji twice each,
and three different emoji in a row. Those are thresholds to apply to
these columns if you want them; the verb applies none. The design its
participants preferred, a Preview of what a screen reader will say, is
[`emoji_to_text()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_to_text.md)
with `format = "name"`.

**Spoken length is a proxy.** `.emoji_spoken_chars` adds up the CLDR
names, which is what NVDA's symbol dictionaries are built from;
VoiceOver, the Windows readers and TalkBack each announce their own
strings, and Remy Sharp's emoji accessibility reference tabulates them.
Some readers shorten a repeat ("three face with tears of joy"), which
the column does not model. On the bundled sample, naming every emoji
takes the emoji-bearing rows from 147,742 characters to 171,606, 16.2%
more, and 50 of its 750 emoji-bearing rows hold a run of three or more.

`max_name` is the one threshold, because a long name is a property of
the catalogue rather than of the text: four catalogue names in five are
40 characters or shorter (the median is 26), so the default flags 18.7%
of the catalogue, but only 1 of the sample's 1,454 occurrences, because
the emoji people use most have short names.

## References

Griggio, C. F., Gorman, B. M. and Tigwell, G. W. (2024). "Party Face
Congratulations!" Exploring design ideas to help sighted users with
emoji accessibility when messaging with screen reader users.
*Proceedings of the ACM on Human-Computer Interaction* 8 (CSCW1),
article 175. [doi:10.1145/3641014](https://doi.org/10.1145/3641014)

## See also

[`emoji_to_text()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_to_text.md)
for the Preview;
[`emoji_runs()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_runs.md);
[`emoji_ambiguity()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_ambiguity.md).

## Examples

``` r
d <- data.frame(text = c(
  "lol \U0001f602\U0001f602\U0001f602\U0001f602",
  "\U0001f389\u2764\ufe0f yes \U0001f389\u2764\ufe0f",
  "so \U0001f389 much fun"))
emoji_a11y_check(d, text)
#> # A tibble: 3 × 13
#>   text  .emoji_max_repeat .emoji_n_repeated_seqs .emoji_longest_run .emoji_n_mid
#>   <chr>             <int>                  <int>              <int>        <int>
#> 1 lol …                 4                      0                  4            0
#> 2 🎉❤️ y…                 2                      1                  2            0
#> 3 so 🎉…                 1                      0                  1            1
#> # ℹ 8 more variables: .emoji_n_begin <int>, .emoji_n_ambiguous <int>,
#> #   .emoji_n_modifier_names <int>, .emoji_spoken_chars <int>,
#> #   .emoji_n_char <int>, .emoji_n_long_names <int>, .emoji_n_ri_letters <int>,
#> #   .emoji_n_hidden <int>
```
