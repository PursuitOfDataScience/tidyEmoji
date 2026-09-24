# List bundled emoji lexicons

`emoji_lexicons()` returns a tibble describing the lexicons bundled with
tidyEmoji and any user-registered ones: their name, type (`"sentiment"`
or `"emotion"` for the bundled two, `"custom"` for a registered one),
dimensions, size, source and licence.

## Usage

``` r
emoji_lexicons()
```

## Value

A tibble with columns `name`, `type`, `dimensions`, `n`, `source`,
`licence`.

`dimensions` lists the columns a lexicon can be scored on. For a
registered lexicon those are its numeric or logical columns other than
the glyph column and `key`, so a text column carried along for reference
is not listed.

`n` is the lexicon's **row count**. For the two bundled ones that is
also the number of emoji they score, 969 and 150, because each has one
row per code-point key. A registered lexicon need not: two spellings of
one emoji are two rows and score one glyph, and a row whose glyph yields
no key at all (an empty string, an `NA`) is counted here and matched
never. `length(unique(emoji_key(tbl$emoji)))` is the count of distinct
emoji, the same distinction
[`emoji_provenance()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_provenance.md)
draws for `n_emoji`.

## See also

[`register_emoji_lexicon()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/register_emoji_lexicon.md)
to add your own;
[`emoji_score()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_score.md)
to score text against any lexicon.

## Examples

``` r
emoji_lexicons()
#> # A tibble: 2 × 6
#>   name       type      dimensions     n source                           licence
#>   <chr>      <chr>     <I<list>>  <int> <chr>                            <chr>  
#> 1 novak2015  sentiment <chr [1]>    969 Kralj Novak et al. (2015), PLoS… CC BY-…
#> 2 emotag1200 emotion   <chr [8]>    150 Shoeb & de Melo (2020), EMNLP 2… MIT    
```
