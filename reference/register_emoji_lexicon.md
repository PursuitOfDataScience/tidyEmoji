# Register a custom emoji lexicon

`register_emoji_lexicon()` adds a user-supplied lexicon to the
in-session registry so it can be referenced by name in
[`emoji_score()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_score.md),
[`emoji_sentiment()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sentiment.md)
or
[`emoji_emotion()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_emotion.md).
The lexicon is normalised through the package's codepoint key (`U+FE0F`
stripped), so a lexicon keyed on unqualified glyphs still matches
qualified text.

## Usage

``` r
register_emoji_lexicon(name, tbl, by = "emoji")
```

## Arguments

- name:

  Name to register the lexicon under.

- tbl:

  A data frame. Must contain a glyph column named `by` (default
  `"emoji"`) and at least one score column, and every score column
  present must be numeric or logical – a text column is rejected here
  rather than returning `NA` for every score at first use. See
  [`emoji_score()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_score.md)
  for the one-row-per-emoji requirement, which is checked when the
  lexicon is used.

- by:

  Name of the column holding the emoji glyph, as a single string.
  Default `"emoji"`. It cannot be `"key"`, the column registration
  writes the code-point keys to: rename such a glyph column first.

## Value

Invisibly, the registered lexicon, with a `key` column holding the
code-point key of each glyph. A `key` column already in `tbl` is
replaced rather than trusted: the registry looks a lexicon up by that
column, so one holding anything else would resolve every row to nothing.

## Details

Registration lasts for the session; it is not written to disk.
Registering a name that is already taken replaces the table under it,
without warning and without a way to get the old one back: there is no
public counterpart that removes a registration, so re-registering is how
a lexicon is changed.
[`emoji_lexicons()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_lexicons.md)
shows what is currently registered.

## Lexicons worth registering

The two bundled lexicons give polarity and eight discrete emotions, and
neither gives **arousal**, so nothing bundled can tell calm-positive
from excited-positive, which is the distinction persuasion and marketing
work turns on. Three peer-reviewed sets of emoji norms fill that gap,
and each is published on OSF under CC BY 4.0, so it can be downloaded,
registered and cited:

- **Emoji-SP** (Ferre et al., *Behavior Research Methods*, 2023): 1031
  emoji rated by Spanish speakers for valence, arousal, familiarity,
  frequency of use, clarity and visual complexity. Larger than the
  bundled sentiment lexicon, and the broadest arousal source there is.
  <https://osf.io/dtfjv/>

- **Emoji-Dis** (Ferre et al., *Scientific Data*, 2025): 112 emoji
  characterised on 13 discrete emotions by 763 Spanish speakers, from
  awe and serenity to disgust and anxiety. <https://osf.io/wv7ub/>

- **Face-emoji norms** (Scheffler and Nenchev, *Behavior Research
  Methods*, 2024): 107 face emoji rated by 138 German speakers for
  valence, arousal, familiarity, clarity and visual complexity; it pairs
  naturally with
  [`emoji_faceness()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_faceness.md).
  <https://osf.io/vbmpj/>

Each arrives as a table keyed by emoji, so registering one is two
renames and a call: put the glyphs in a column called `emoji` and the
rating to score on by default in one called `score`, which registration
requires. Every other numeric rating in the table stays usable through
`score =`.

    norms <- read.csv("emoji_sp_norms.csv")   # downloaded from OSF
    names(norms)[names(norms) == "Emoji"] <- "emoji"
    names(norms)[names(norms) == "valence"] <- "score"
    register_emoji_lexicon("emoji_sp", norms)
    emoji_score(df, text, lexicon = "emoji_sp")   # valence
    emoji_score(df, text, lexicon = "emoji_sp", score = "arousal")
    emoji_coverage(df, text, lexicon = "emoji_sp")

The column names above are illustrative: read the file's own codebook.
All three were rated by speakers of one language each, so the caution on
the bundled lexicons applies to them too: an emoji's reading is not
language-neutral. Cite the source you register, as you would a bundled
one.

## See also

[`emoji_lexicons()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_lexicons.md)
to list lexicons;
[`emoji_score()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_score.md)
to use one.

## Examples

``` r
my_lex <- data.frame(
  emoji = c("\U0001f600", "\U0001f621"),
  score = c(0.9, -0.8)
)
register_emoji_lexicon("mine", my_lex)
emoji_lexicons()
#> # A tibble: 3 × 6
#>   name       type      dimensions     n source                           licence
#>   <chr>      <chr>     <I<list>>  <int> <chr>                            <chr>  
#> 1 novak2015  sentiment <chr [1]>    969 Kralj Novak et al. (2015), PLoS… CC BY-…
#> 2 emotag1200 emotion   <chr [8]>    150 Shoeb & de Melo (2020), EMNLP 2… MIT    
#> 3 mine       custom    <chr [1]>      2 user-registered                  NA     
emoji_score(data.frame(text = "great \U0001f600"), text, lexicon = "mine")
#> # A tibble: 1 × 4
#>   text     .emoji_n .emoji_n_scored .emoji_score
#>   <chr>       <int>           <int>        <dbl>
#> 1 great 😀        1               1          0.9
```
