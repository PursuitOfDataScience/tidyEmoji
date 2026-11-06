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

**English only.** The keyword sets are the CLDR English ones, so a term
in another language matches nothing and an English term says nothing
about how the emoji is read elsewhere. And an emoji newer than the emoji
package's table has no keywords at all, so it is never found here; see
[`emoji_keywords()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_keywords.md).

## See also

[`emoji_keywords()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_keywords.md),
[`emoji_search()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_search.md).

## Examples

``` r
emoji_find("celebration")
#> # A tibble: 27 × 5
#>    emoji name                     group             matched     n_matched
#>    <chr> <chr>                    <chr>             <chr>           <int>
#>  1 🥳    partying face            Smileys & Emotion celebration         1
#>  2 🙌    raising hands            People & Body     celebration         1
#>  3 🎅    Santa Claus              People & Body     celebration         1
#>  4 🤶    Mrs. Claus               People & Body     celebration         1
#>  5 🧑‍🎄    Mx Claus                 People & Body     celebration         1
#>  6 🎂    birthday cake            Food & Drink      celebration         1
#>  7 🍾    bottle with popping cork Food & Drink      celebration         1
#>  8 🎃    jack-o-lantern           Activities        celebration         1
#>  9 🎄    Christmas tree           Activities        celebration         1
#> 10 🎆    fireworks                Activities        celebration         1
#> # ℹ 17 more rows
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
