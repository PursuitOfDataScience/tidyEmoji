# Turn a tally of emoji into text the other verbs can read

`emoji_from_counts()` takes data that records emoji as counts (one row
per item and emoji, with how many times it was used) and writes out, for
each item, a text holding each emoji that many times. Every verb in the
package then reads it like any other text column, so reaction data can
be scored, counted, profiled over time and turned into a
document-by-emoji matrix.

## Usage

``` r
emoji_from_counts(data, emoji, n, id = NULL)
```

## Arguments

- data:

  A data frame with one row per (item, emoji) count.

- emoji:

  The unquoted column holding the emoji (see Details).

- n:

  The unquoted column holding the counts.

- id:

  Optional unquoted column identifying the item each count belongs to.
  Without it the whole table is one document.

## Value

A tibble with one row per item, in order of first appearance: the `id`
column (under its own name) when given, and `text`, the emoji written
out.

## Details

**The contract is an identity.** The text written for a tally gives
exactly the counts, scores and matrix the original text would have
given:
[`emoji_frequency()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_frequency.md),
[`emoji_sentiment()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sentiment.md),
[`emoji_emotion()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_emotion.md)
and
[`emoji_dfm()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_dfm.md)
cannot tell the two apart. The emoji are separated by single spaces, so
two tallied glyphs cannot fuse into a third (a tone and a hand into a
toned hand, two regional indicators into a flag), and nothing else is
added. Verbs that measure the *text* around emoji, such as
[`emoji_position()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_position.md),
[`emoji_context()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_context.md)
and
[`emoji_ratio()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_ratio.md),
are measuring those spaces, and have nothing to say about a tally.

The `emoji` column can hold glyphs in any spelling, the names of
GitHub's eight reactions (`"+1"`, `"-1"`, `"laugh"`, `"hooray"`,
`"confused"`, `"heart"`, `"rocket"`, `"eyes"`, as its API returns them),
shortcodes with or without their colons, or Unicode names. Every glyph
is written in its canonical spelling, so a bare `U+2764` in the tally is
read by the default `presentation`. A value that resolves to no emoji is
an error naming it, rather than a silent zero.

`n` must be a whole number of at least 0. A fractional count, such as a
survey weight or an average, is refused rather than rounded: a text
cannot hold 2.5 emoji, and truncating it would change the answer without
saying so. An item whose counts are all zero keeps its row, with an
empty text, so it still counts as a document wherever the number of
documents matters (the inverse document frequency of
[`emoji_dfm()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_dfm.md),
for one).

**What a reaction count measures.** A tally records which buttons were
pressed, and the set of buttons is the platform's: GitHub offers eight,
so "nobody reacted with a skull" says nothing about whether anyone
thought it. A study of Telegram reactions found them unreliable
indicators of emotional resonance, for that reason among others. The
scores this makes possible are scores of what the platform let people
say.

## See also

[`emoji_dfm()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_dfm.md),
[`emoji_sentiment()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sentiment.md)
and
[`emoji_frequency()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_frequency.md)
for what to do with the result.

## Examples

``` r
reactions <- data.frame(
  pr = c(101, 101, 102),
  reaction = c("+1", "rocket", "-1"),
  count = c(3, 1, 2)
)
txt <- emoji_from_counts(reactions, reaction, count, id = pr)
txt
#> # A tibble: 2 × 2
#>      pr text       
#>   <dbl> <chr>      
#> 1   101 👍 👍 👍 🚀
#> 2   102 👎 👎      
emoji_sentiment(txt, text)
#> # A tibble: 2 × 5
#>      pr text        .emoji_n .emoji_n_scored .emoji_sentiment
#>   <dbl> <chr>          <int>           <int>            <dbl>
#> 1   101 👍 👍 👍 🚀        4               4            0.523
#> 2   102 👎 👎              2               2           -0.190
```
