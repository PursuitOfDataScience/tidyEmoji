# Register a custom emoji lexicon

`register_emoji_lexicon()` adds a user-supplied lexicon to the
in-session registry so it can be referenced by name in
[`emoji_score()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_score.md),
[`emoji_sentiment()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sentiment.md)
or
[`emoji_emotion()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_emotion.md).
The lexicon is normalised through `emoji_key()` (U+FE0F stripped), so a
lexicon keyed on unqualified glyphs still matches qualified text (see
next_release.md §4.1).

## Usage

``` r
register_emoji_lexicon(name, tbl, by = "emoji")
```

## Arguments

- name:

  Name to register the lexicon under.

- tbl:

  A data frame. Must contain a glyph column named `by` (default
  `"emoji"`) and at least one score column.

- by:

  Name of the column holding the emoji glyph. Default `"emoji"`.

## Value

Invisibly, the registered lexicon (with an added `key` column).

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
#>   text     .emoji_score .emoji_n_scored .emoji_n
#>   <chr>           <dbl>           <int>    <int>
#> 1 great 😀          0.9               1        1
```
