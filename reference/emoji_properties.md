# What the catalogue knows about a glyph

`emoji_properties()` reports, for each glyph, everything the bundled
emoji catalogue records about it: its code points, its qualification
status, its Unicode name, group and subgroup, the emoji version that
introduced it, and whether it can carry a skin-tone modifier. With no
argument it returns the whole catalogue, one row per spelling.

## Usage

``` r
emoji_properties(x = NULL)
```

## Arguments

- x:

  A character vector of glyphs. The default, `NULL`, returns every
  spelling in the catalogue, in the catalogue's own order.

## Value

A tibble with one row per element of `x` (or per catalogue spelling), in
the same order, and columns `emoji`, `codepoints` (as
`"U+1F600 U+FE0F"`), `n_codepoints`, `key` (the code-point key, with
`U+FE0F` removed), `name`, `status`, `group`, `subgroup`, `version` (the
emoji version that introduced it, such as `"15.0"`), `modifiable` and
`has_fe0f`.

## Details

The catalogue is Unicode's `emoji-test.txt` for the version
[`emoji_unicode_version()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_unicode_version.md)
reports. It lists every spelling of every emoji, and `status` is what
the file calls the spelling:

- `"fully-qualified"`: the spelling a keyboard emits, carrying every
  `U+FE0F` the emoji needs. Exactly one per emoji.

- `"minimally-qualified"`: a shorter spelling of a joined sequence, with
  some selectors left out but the first one kept.

- `"unqualified"`: a spelling with the first selector left out too, such
  as the bare heart `U+2764`. These are detected only under
  `presentation = "any"`; see
  [`emoji_summary()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_summary.md).

- `"component"`: the five skin-tone swatches and four hair components,
  which are parts of emoji rather than emoji. Standing alone they are
  not counted by any verb.

`status` describes the exact spelling you passed, so it is `NA` for one
the catalogue does not list: a correct emoji with a stray extra
`U+FE0F`, a sequence too new for this catalogue, or a string that is not
an emoji at all. The other catalogue columns describe the *emoji*, and
are looked up through the code-point key every verb uses, which ignores
`U+FE0F`: the bare and the qualified heart share a name, a group and a
version. The `codepoints`, `n_codepoints` and `has_fe0f` columns
describe the string itself and are filled in for anything, emoji or not.

`modifiable` is `TRUE` when the catalogue spells the emoji with a skin
tone, so it is a statement about the emoji with any tone it carries
removed: `U+1F44D` and `U+1F44D U+1F3FD` are both modifiable. It is `NA`
where the emoji is not in the catalogue.

## See also

[`as_emoji_canonical()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/as_emoji_canonical.md)
for the fully-qualified spelling,
[`emoji_identical()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_identical.md)
to compare two glyphs,
[`emoji_unicode_releases()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_unicode_releases.md)
to turn `version` into a date, and
[`emoji_keywords()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_keywords.md)
for the vocabulary.

## Examples

``` r
emoji_properties(c("\u2764", "\u2764\ufe0f", "\U0001f44d\U0001f3fd"))
#> # A tibble: 3 × 11
#>   emoji codepoints      n_codepoints key     name  status group subgroup version
#>   <chr> <chr>                  <int> <chr>   <chr> <chr>  <chr> <chr>    <chr>  
#> 1 ❤     U+2764                     1 2764    red … unqua… Smil… heart    0.6    
#> 2 ❤️     U+2764 U+FE0F              2 2764    red … fully… Smil… heart    0.6    
#> 3 👍🏽    U+1F44D U+1F3FD            2 1F44D … thum… fully… Peop… hand-fi… 1.0    
#> # ℹ 2 more variables: modifiable <lgl>, has_fe0f <lgl>

# the whole catalogue, one row per spelling
cat <- emoji_properties()
table(cat$status)
#> 
#>           component     fully-qualified minimally-qualified         unqualified 
#>                   9                3963                1029                 243 
```
