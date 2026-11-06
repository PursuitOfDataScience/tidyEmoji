# Take an emoji apart: base, skin tone, gender and hair

`emoji_decompose()` reports, for each glyph, what it depicts of a person
and how it is built: the emoji with its skin tones taken out, its
gender-neutral form, its tones, the gender and hair it shows, and the
components it is joined from. It describes glyphs, never the people who
write them; see *Glyphs, not people* in
[tidyEmoji](https://pursuitofdatascience.github.io/tidyEmoji/reference/tidyEmoji-package.md).
It is what
[`emoji_skin_tone()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_skin_tone.md),
[`emoji_gender()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_gender.md)
and
[`emoji_retone()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_retone.md)
read.

## Usage

``` r
emoji_decompose(x, long = FALSE)
```

## Arguments

- x:

  A character vector of glyphs.

- long:

  If `TRUE`, return one row per component instead, the way
  [`emoji_emotion()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_emotion.md)
  does: `emoji`, `position`, `component`, `role` (`"person"`,
  `"object"`, `"gender_sign"`, `"hair"`, `"tone"` or `"other"`) and
  `component_name`.

## Value

With `long = FALSE`, a tibble with one row per element of `x`: `emoji`
(as given), `name`, `base`, `neutral`, `tone`, `tones`, `n_tones`
(distinct tones), `gender`, `hair` (`"red"`, `"curly"`, `"white"` or
`"bald"`, `NA` otherwise), `n_parts` (the components a zero-width joiner
joins, 1 for a glyph with no joiner), `parts` (those components without
their tones, separated by `"|"`) and `modifiable` (whether the base
takes a tone). `NA` input gives a row of `NA`.

## Details

Each glyph is canonicalised first, so the bare heart `U+2764` and the
qualified `U+2764 U+FE0F` decompose alike, and read from a table the
package builds once per session over the catalogue; a glyph the
catalogue does not list, such as a face followed by a swatch it cannot
take, is worked out on the fly.

- **Tone** is `"default"` for a glyph that takes a tone and has none,
  `"light"`, `"medium_light"`, `"medium"`, `"medium_dark"` or `"dark"`
  for one tone however many people carry it, and `"mixed"` for two or
  more, as on a couple with two tones. It is `NA` only where the glyph
  cannot take a tone. `tones` lists every tone in reading order.

- **Gender** is the one the glyph is drawn with: `"female"` or `"male"`
  from the female and male signs `U+2640` and `U+2642` or a gendered
  person (woman, man, girl, boy, old woman, old man), and from a list of
  twelve emoji whose gender lives in one code point (prince and
  princess, Santa and Mrs. Claus, the two dancers, the two pregnant
  people, men and women holding hands, the woman with headscarf, and
  breast-feeding, which the list follows emojibase in calling female);
  `"mixed"` for a multi-person emoji with both, a derivation of this
  package's own; `"neutral"` for the gender-neutral form, which
  platforms draw differently; `NA` where no gender is depicted.

- **Neutral** is the gender-neutral form the catalogue has, so woman
  running gives person running and woman technologist gives
  technologist; `NA` where there is none.

- **Base** is the glyph with every tone taken out, in the catalogue's
  spelling. For a two-person emoji written as one code point untoned, a
  kiss or a handshake, the toned spellings are joined sequences and the
  base is the single code point.

## See also

[`emoji_skin_tone()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_skin_tone.md),
[`emoji_gender()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_gender.md)
and
[`emoji_retone()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_retone.md),
which apply it to a text column;
[`emoji_properties()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_properties.md)
for what the catalogue records.

## Examples

``` r
couple <- "\U0001f469\U0001f3fb\u200d\u2764\ufe0f\u200d\U0001f468\U0001f3ff"
emoji_decompose(c("\U0001f44d\U0001f3fd", couple, "\U0001f3c3\u200d\u2640\ufe0f"))
#> # A tibble: 3 × 12
#>   emoji name        base  neutral tone  tones n_tones gender hair  n_parts parts
#>   <chr> <chr>       <chr> <chr>   <chr> <chr>   <int> <chr>  <chr>   <int> <chr>
#> 1 👍🏽    thumbs up:… 👍    NA      medi… medi…       1 NA     NA          1 👍   
#> 2 👩🏻‍❤️‍👨🏿    couple wit… 👩‍❤️‍👨    💑      mixed ligh…       2 mixed  NA          3 👩|❤️|…
#> 3 🏃‍♀️    woman runn… 🏃‍♀️    🏃      defa… defa…       0 female NA          2 🏃|♀️ 
#> # ℹ 1 more variable: modifiable <lgl>
emoji_decompose(couple, long = TRUE)
#> # A tibble: 5 × 5
#>   emoji position component role   component_name 
#>   <chr>    <int> <chr>     <chr>  <chr>          
#> 1 👩🏻‍❤️‍👨🏿           1 👩        person woman          
#> 2 👩🏻‍❤️‍👨🏿           2 🏻        tone   light skin tone
#> 3 👩🏻‍❤️‍👨🏿           3 ❤️         object red heart      
#> 4 👩🏻‍❤️‍👨🏿           4 👨        person man            
#> 5 👩🏻‍❤️‍👨🏿           5 🏿        tone   dark skin tone 
```
