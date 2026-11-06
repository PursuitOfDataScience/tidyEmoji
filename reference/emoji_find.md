# Which emoji carry these keywords?

`emoji_find()` returns the emoji whose CLDR keyword set contains any (or
all) of the given terms: "which emoji mean celebration?" in one call. It
is the inverse of
[`emoji_keywords()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_keywords.md),
and the way to assemble a stimulus set by semantic field.

## Usage

``` r
emoji_find(terms, match = c("any", "all"))
```

## Arguments

- terms:

  A character vector of keywords to look for. Terms that differ only in
  case are one term, reported in the spelling given first. An empty
  vector finds nothing; `NA` and `""` are errors.

- match:

  `"any"` (default) to return emoji carrying at least one of the terms,
  `"all"` for emoji carrying every one of them.

## Value

A tibble with one row per emoji found, under its canonical spelling:
`emoji`, `name`, `group`, `matched` (the terms it carries, joined with
`", "`, in the order given) and `n_matched`. Rows are sorted by
descending `n_matched`, then in catalogue order. No match gives a typed
zero-row tibble.

## Details

A term matches a keyword exactly, ignoring case, so `"celebration"`
finds the party popper and `"celebrat"` finds nothing;
[`emoji_search()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_search.md)
is the substring search, over names and shortcodes as well as keywords.
The fold to lower case does not depend on the session's locale.

**English only.** The keyword sets are English ones, the emoji package's
and CLDR 49's together (see
[`emoji_keywords()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_keywords.md)),
so a term in another language matches nothing and an English term says
nothing about how the emoji is read elsewhere. Every emoji in the
catalogue has keywords, the newest included.

## See also

[`emoji_keywords()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_keywords.md),
[`emoji_search()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_search.md).

## Examples

``` r
emoji_find("celebration")
#> # A tibble: 47 × 5
#>    emoji name                                  group           matched n_matched
#>    <chr> <chr>                                 <chr>           <chr>       <int>
#>  1 🥳    partying face                         Smileys & Emot… celebr…         1
#>  2 🙌    raising hands                         People & Body   celebr…         1
#>  3 🙌🏻    raising hands: light skin tone        People & Body   celebr…         1
#>  4 🙌🏼    raising hands: medium-light skin tone People & Body   celebr…         1
#>  5 🙌🏽    raising hands: medium skin tone       People & Body   celebr…         1
#>  6 🙌🏾    raising hands: medium-dark skin tone  People & Body   celebr…         1
#>  7 🙌🏿    raising hands: dark skin tone         People & Body   celebr…         1
#>  8 🎅    Santa Claus                           People & Body   celebr…         1
#>  9 🎅🏻    Santa Claus: light skin tone          People & Body   celebr…         1
#> 10 🎅🏼    Santa Claus: medium-light skin tone   People & Body   celebr…         1
#> # ℹ 37 more rows
emoji_find(c("cat", "face"), match = "all")
#> # A tibble: 11 × 5
#>    emoji name                           group             matched   n_matched
#>    <chr> <chr>                          <chr>             <chr>         <int>
#>  1 😺    grinning cat                   Smileys & Emotion cat, face         2
#>  2 😸    grinning cat with smiling eyes Smileys & Emotion cat, face         2
#>  3 😹    cat with tears of joy          Smileys & Emotion cat, face         2
#>  4 😻    smiling cat with heart-eyes    Smileys & Emotion cat, face         2
#>  5 😼    cat with wry smile             Smileys & Emotion cat, face         2
#>  6 😽    kissing cat                    Smileys & Emotion cat, face         2
#>  7 🙀    weary cat                      Smileys & Emotion cat, face         2
#>  8 😿    crying cat                     Smileys & Emotion cat, face         2
#>  9 😾    pouting cat                    Smileys & Emotion cat, face         2
#> 10 🐱    cat face                       Animals & Nature  cat, face         2
#> 11 🐯    tiger face                     Animals & Nature  cat, face         2
```
