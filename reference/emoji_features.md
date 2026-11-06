# One row per emoji, with the cues that tell what it is doing

`emoji_features()` returns one row per emoji occurrence with the cues a
classifier of emoji function reads: where the emoji sits, what is on
either side of it, the run it belongs to, and what kind of emoji it is.
It reports cues and withholds labels. The best published classifier of
what an emoji does in a sentence reached an F1 of 0.62 on content and
its annotators a Fleiss kappa of 0.50 on subtype (Na'aman, Provenza and
Montoya 2017), and a shipped label at that accuracy is worse than none.
The Unicode group, the cue that helped that classifier most, is a
column.

## Usage

``` r
emoji_features(data, text, presentation = "emoji")
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

A tibble with one row per emoji occurrence, carrying the columns of
`data`, and `.row_number`, `.emoji_index` (its number within the row),
`.emoji`, `.emoji_start` and `.emoji_end` (code-point offsets),
`.emoji_rel_position` (as
[`emoji_position()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_position.md)
defines it, for this occurrence), `.emoji_zone` (the position of its
run, as
[`emoji_runs()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_runs.md)
reports it), `.emoji_prev` and `.emoji_next` (`"word"`, `"emoji"`,
`"punct"` or `"none"`, the nearest thing on that side past any white
space), `.emoji_prev_space` and `.emoji_next_space` (white space
directly on that side), `.emoji_intraword`, `.emoji_run` and
`.emoji_run_length`, and `.emoji_group`, `.emoji_subgroup` and
`.emoji_n_codepoints` from the catalogue. A grouped input stays grouped.

## Details

A "word" is Unicode letters and numbers, and punctuation is anything
else that is not white space or an emoji, so nothing here depends on the
session's locale. `.emoji_intraword` marks an emoji with a letter or
number directly on both sides, `h` emoji `ow`: in ordinary text a strong
cue that the emoji stands for a word or a syllable, and the signature of
the "Emoji Attack" on language-model judges (Wei et al. 2025), which
splits words with emoji to throw off their tokenisation.

## References

Na'aman, N., Provenza, H. and Montoya, O. (2017). Varying linguistic
purposes of emoji in (Twitter) context. *Proceedings of ACL 2017,
Student Research Workshop*, 136-141.
[doi:10.18653/v1/P17-3022](https://doi.org/10.18653/v1/P17-3022)

Wei, Z. et al. (2025). Emoji attack: enhancing jailbreak attacks against
judge LLM detection. *Proceedings of ICML 2025*, PMLR 267, 66103-66117.

## See also

[`emoji_runs()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_runs.md);
[`emoji_position()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_position.md)
for the row-level position.

## Examples

``` r
d <- data.frame(text = "h\U0001f600ow are you \U0001f600")
emoji_features(d, text)
#> # A tibble: 2 × 18
#>   text             .row_number .emoji_index .emoji .emoji_start .emoji_end
#>   <chr>                  <int>        <int> <chr>         <int>      <int>
#> 1 h😀ow are you 😀           1            1 😀                2          2
#> 2 h😀ow are you 😀           1            2 😀               14         14
#> # ℹ 12 more variables: .emoji_rel_position <dbl>, .emoji_zone <chr>,
#> #   .emoji_prev <chr>, .emoji_next <chr>, .emoji_prev_space <lgl>,
#> #   .emoji_next_space <lgl>, .emoji_intraword <lgl>, .emoji_run <int>,
#> #   .emoji_run_length <int>, .emoji_group <chr>, .emoji_subgroup <chr>,
#> #   .emoji_n_codepoints <int>
```
