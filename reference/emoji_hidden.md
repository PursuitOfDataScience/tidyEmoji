# Find, measure and decode what is hidden in a text

`emoji_hidden()` reports, per row, the code points riding invisibly in a
text column that Unicode gives no visible meaning to: runs of variation
selectors after an emoji, and tag characters outside a flag. These are
the two published ways of smuggling a message through an emoji,
invisibly and past copy and paste, into whatever reads the text next, a
language model included. The verb counts them, says how many bytes they
cost a tokenizer, and decodes the payload when it is in one of the two
published encodings.

## Usage

``` r
emoji_hidden(data, text)
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

## Value

`data`, as a tibble, with six columns added:

- `.emoji_n_hidden`:

  the number of hidden code points.

- `.emoji_hidden_bytes`:

  their size in UTF-8 bytes, which is what a byte-level tokenizer pays
  for.

- `.emoji_hidden_kind`:

  `"none"`, `"variation_selectors"`, `"tags"` or `"both"`.

- `.emoji_hidden_segments`:

  the number of contiguous runs of hidden code points.

- `.emoji_hidden_payload`:

  the decoded text, runs joined by `" | "`, with every control character
  shown as `<U+XXXX>`; `NA` when nothing is hidden or a run is in
  neither published encoding.

- `.emoji_hidden_decoded`:

  `TRUE` when every run decoded, `FALSE` otherwise, including when
  nothing is hidden.

A grouped input stays grouped. `NA` text has nothing hidden.

## Details

**What counts as hidden** is decided by two exact rules from Unicode's
own data, not by a guess:

- **A variation selector is hidden when it cannot be part of any
  sequence Unicode defines**: when it follows another selector (no
  defined sequence has two), when it is an ideographic selector
  (`U+E0100` to `U+E01EF`) that does not follow a CJK ideograph, or when
  it is one of `U+FE00` to `U+FE0D` and the pair is not a standardized
  variation sequence. A single `U+FE0E` or `U+FE0F` is never hidden,
  wherever it stands, because redundant presentation selectors are
  common in ordinary text and one carries at most one byte.

- **A tag character is hidden unless it is inside a well-formed flag tag
  sequence**: `U+1F3F4`, tag letters spelling a subdivision code, then
  `U+E007F`. The England, Scotland and Wales flags are untouched, and so
  is a well-formed subdivision flag the catalogue does not list.

So Japanese text spelled with ideographic variation selectors, the
mathematical and Mongolian variants Unicode standardizes, every keycap,
every catalogue spelling and every flag report nothing. Zero-width
spaces, joiners and non-joiners are deliberately not inspected: they are
not emoji mechanisms, and Persian, the Indic scripts, Thai and Khmer
need them. Use a general Unicode-security tool for those.

**Decoding** covers the two published encodings only: variation
selectors as bytes (`U+FE00` to `U+FE0F` as 0 to 15, `U+E0100` to
`U+E01EF` as 16 to 255, the scheme of Butler, 2025), accepted only when
the bytes are valid UTF-8; and tag characters `U+E0020` to `U+E007E` as
ASCII. Each contiguous run of hidden code points is decoded on its own
and the runs are joined by `" | "`. A row with any run in neither
encoding gets an `NA` payload and `.emoji_hidden_decoded = FALSE`; it is
still counted.

**The payload is attacker text, returned as data.** Do not paste it into
a model. Every C0 and C1 control character and every bidirectional
control in it is replaced by a visible `<U+XXXX>` marker, so printing
the result in a console or a knitted report cannot recolour or rewrite
the terminal or reorder what a reader sees.

There is no `presentation` argument, because neither rule depends on it:
a `U+FE0F` after a text-default glyph is valid whatever the caller
counts as an emoji.
[`emoji_sanitize()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sanitize.md)
and
[`emoji_to_text()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_to_text.md)
remove these code points by default, under every policy, and
[`emoji_summary()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_summary.md)
and
[`emoji_token_cost()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_token_cost.md)
count them.

## References

Butler P (2025). Smuggling arbitrary data through an emoji.
<https://paulbutler.org/2025/smuggling-arbitrary-data-through-an-emoji/>

Hackett W, Birch L, Trawicki S, Suri N, Garraghan P (2025). Bypassing
LLM Guardrails: An Empirical Analysis of Evasion Attacks against Prompt
Injection and Jailbreak Detection Systems. arXiv:2504.11168.

## See also

[`emoji_sanitize()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sanitize.md),
whose default `hidden = "remove"` deletes what this reports;
[`emoji_token_cost()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_token_cost.md)
for what the rest of the emoji cost.

## Examples

``` r
# "hi" hidden after a grinning face, one variation selector per byte
hide <- function(s) {
  b <- as.integer(charToRaw(s))
  intToUtf8(ifelse(b < 16L, 0xFE00L + b, 0xE0100L + b - 16L))
}
df <- data.frame(text = c(paste0("hello \U0001F600", hide("hi")),
                          "plain \U0001F600"))
emoji_hidden(df, text)
#> # A tibble: 2 × 7
#>   text     .emoji_n_hidden .emoji_hidden_bytes .emoji_hidden_kind 
#>   <chr>              <int>               <int> <chr>              
#> 1 hello 😀󠅘󠅙               2                   8 variation_selectors
#> 2 plain 😀               0                   0 none               
#> # ℹ 3 more variables: .emoji_hidden_segments <int>,
#> #   .emoji_hidden_payload <chr>, .emoji_hidden_decoded <lgl>

# the rewriting verbs remove it by default
nchar(emoji_sanitize(df, text)$text)
#> [1] 7 7
nchar(emoji_sanitize(df, text, hidden = "keep")$text)
#> [1] 9 7
```
