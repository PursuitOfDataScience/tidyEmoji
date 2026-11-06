# Runs of emoji: the sequences writers build

`emoji_runs()` returns one row per run of emoji: a maximal stretch of
emoji with nothing but white space between them, or nothing at all with
`sep = "adjacent"`. Runs are the unit the literature on emoji sequences
annotates. Reduplication, one emoji repeated for emphasis, is the
dominant multi-emoji pattern (Cohn, Engelen and Schilperoord 2019), and
repetitive sequences are one of the few emoji features that tell
people's text from a language model's.

## Usage

``` r
emoji_runs(
  data,
  text,
  sep = c("whitespace", "adjacent"),
  presentation = "emoji"
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

- sep:

  What may stand between two emoji of one run: `"whitespace"` (the
  default) or `"adjacent"` (nothing).

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

A tibble with one row per run, carrying the columns of `data` (rows
without emoji contribute none), and `.row_number`, `.emoji_run` (the
number of the run within its row), `.emoji_run_start` and
`.emoji_run_end` (code-point offsets), `.emoji_run_length` (emoji in
it), `.emoji_run_n_distinct`, `.emoji_run_glyphs` (its emoji, written
together), `.emoji_run_is_reduplication` (more than one emoji, all the
same) and `.emoji_run_position` (`"begin"`, `"mid"`, `"end"` or
`"only"`). A grouped input stays grouped.

## Details

**What separates two runs.** With `sep = "whitespace"`, the default and
what the annotators of the sequence literature did, white space may sit
inside a run, so "x x x" spaced out is one run; with `"adjacent"` only
emoji written directly together are. White space is Unicode's
`White_Space`, as everywhere in the package. The choice matters: the
bundled sample holds 1,038 runs under the default and 1,148 under
`"adjacent"`, and how far apart the two are depends on how the text was
written. Under the default 37.5% of its 1,454 emoji sit in a run of two
or more, and 19 of its 129 such runs are reduplications. A
zero-width-joiner sequence that counts as its parts (see the *Detection*
section of
[tidyEmoji](https://pursuitofdatascience.github.io/tidyEmoji/reference/tidyEmoji-package.md))
is one run of those parts.

**Position.** A run is at the `"begin"` of its text when only white
space and punctuation come before it, at the `"end"` when only they come
after it, `"only"` when both are true, and `"mid"` otherwise.

Runs are not n-grams:
[`emoji_ngrams()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_ngrams.md)
slides a window of fixed length over the emoji of a text, where a run is
a maximal span of any length.

## References

Cohn, N., Engelen, J. and Schilperoord, J. (2019). The grammar of emoji?
Constraints on communicative pictorial sequencing. *Cognitive Research:
Principles and Implications* 4, 33.
[doi:10.1186/s41235-019-0177-0](https://doi.org/10.1186/s41235-019-0177-0)

## See also

[`emoji_features()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_features.md)
for one row per emoji, with its run;
[`emoji_a11y_check()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_a11y_check.md);
[`emoji_ngrams()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_ngrams.md).

## Examples

``` r
d <- data.frame(text = c("wow \U0001f600\U0001f600\U0001f600",
                         "\U0001f600 ok \U0001f389",
                         "\U0001f600\U0001f389"))
emoji_runs(d, text)
#> # A tibble: 4 × 10
#>   text  .row_number .emoji_run .emoji_run_start .emoji_run_end .emoji_run_length
#>   <chr>       <int>      <int>            <int>          <int>             <int>
#> 1 wow …           1          1                5              7                 3
#> 2 😀 ok…           2          1                1              1                 1
#> 3 😀 ok…           2          2                6              6                 1
#> 4 😀🎉            3          1                1              2                 2
#> # ℹ 4 more variables: .emoji_run_n_distinct <int>, .emoji_run_glyphs <chr>,
#> #   .emoji_run_is_reduplication <lgl>, .emoji_run_position <chr>
```
