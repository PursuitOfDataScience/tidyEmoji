# List bundled emoji lexicons

`emoji_lexicons()` returns a tibble describing the lexicons bundled with
tidyEmoji and any user-registered ones: their name, type (sentiment or
emotion), dimensions, number of emoji, source and licence.

## Usage

``` r
emoji_lexicons()
```

## Value

A tibble with columns `name`, `type`, `dimensions`, `n`, `source`,
`licence`.

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
