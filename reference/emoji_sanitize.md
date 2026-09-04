# Apply an explicit emoji policy to a text column

`emoji_sanitize()` rewrites a text column under one named policy: keep
the emoji, delete them, spell them out as names or shortcodes, or
replace them with a placeholder token. The value is not new capability –
most of it exists across
[`emoji_to_text()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_to_text.md)
and the extraction verbs – but a single argument that says which choice
was made, so that "we replaced emoji with their Unicode names" becomes a
reproducibility statement rather than a forgotten line of
[`gsub()`](https://rdrr.io/r/base/grep.html).

## Usage

``` r
emoji_sanitize(
  data,
  text,
  policy = "keep",
  placeholder = "[emoji]",
  wrap = ":{x}:"
)
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

  The text column to scan, supplied unquoted. What counts as an emoji is
  the same in every verb; see the *Detection* section of
  [tidyEmoji](https://pursuitofdatascience.github.io/tidyEmoji/reference/tidyEmoji-package.md)
  for the one case that surprises people, code points that are emoji
  only when they carry `U+FE0F`.

- policy:

  One of `"keep"` (default), `"strip"`, `"name"`, `"shortcode"` or
  `"placeholder"`.

- placeholder:

  Replacement token for `policy = "placeholder"`. Default `"[emoji]"`.

- wrap:

  Template for `policy = "shortcode"`, with `{x}` standing for the
  shortcode. Default `":{x}:"`.

## Value

`data`, as a tibble, with the text column rewritten in place (same
column name). `NA` entries stay `NA`.

## Details

The policies:

- `"keep"` returns the text untouched. It is the honest baseline for an
  A/B comparison, and it means the policy argument can stay in the
  script even when the answer is "do nothing".

- `"strip"` deletes the emoji. Because deleting a glyph can leave two
  spaces where there was one, `strip` also collapses runs of spaces and
  tabs and trims the ends – the only policy that touches anything but
  the emoji.

- `"name"` and `"shortcode"` substitute the Unicode name ("grinning
  face") or the GitHub-style alias (":grinning:"), exactly as
  [`emoji_to_text()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_to_text.md)
  does. `name` is also the accessibility answer: it is what a screen
  reader announces.

- `"placeholder"` substitutes a fixed token, which keeps the *position*
  of an emoji as a feature while removing its identity.

Replacements go exactly where the glyph was, with no padding, so a
grinning face glued to the end of a word yields `"wordgrinning face"`.
If your tokeniser needs whitespace around them, use `"placeholder"` with
a padded placeholder such as `" [emoji] "`.

## Which policies can be undone

The five policies are not five parallel options: they are a ladder of
information loss, and how far down it you step is invisible until you
try to put the emoji back after the model call.

|  |  |  |  |
|----|----|----|----|
| `policy` | `"great <U+1F600> work"` becomes | Restorable with [`text_to_emoji()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/text_to_emoji.md)? | What is lost |
| `"keep"` | `great <U+1F600> work` | yes | nothing |
| `"shortcode"` | `great :grinning: work` | **yes** | nothing |
| `"name"` | `great grinning face work` | no | the delimiters; the name is now ordinary words |
| `"placeholder"` | `great [emoji] work` | no | *which* emoji – the position survives |
| `"strip"` | `great work` | no | that there was an emoji at all |

So if the pipeline has to restore emoji downstream, `"shortcode"` is the
only policy that permits it, and it holds up on the awkward cases:
skin-tone modifiers, flags, ZWJ sequences and keycaps all come back.
Measured against the whole reference table of emoji 16.0.0: for all 3790
emoji in their canonical (fully qualified) spelling – the spelling a
keyboard emits and text normally holds – **the round trip returns the
original text byte for byte, 100% of the time**.

Unicode also lists shorter spellings of the same emoji, with the
`U+FE0F` presentation selectors omitted. Feed one of those in and the
round trip returns the *canonical* spelling instead: `U+270C` comes back
as `U+270C U+FE0F`. Across all 4853 catalogued spellings that is 79.5%
byte-identical, and the remaining 20.5% differ by `U+FE0F` alone – never
by more. The emoji is always the same emoji, and every tidyEmoji lookup
treats the two spellings as one, so this matters only if you are diffing
raw bytes on text that had its selectors stripped upstream.

`"placeholder"` keeps *where* but not *which*, which is enough to use
"an emoji was here" as a model feature and not enough to reconstruct the
text. `"name"` is the accessibility answer rather than the reversible
one – it is what a screen reader announces.

## See also

[`emoji_token_cost()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_token_cost.md)
for what the emoji are costing you;
[`emoji_to_text()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_to_text.md)
for the name/shortcode rewrite on its own.

## Examples

``` r
df <- data.frame(text = c("ship it \U0001f680", "no emoji"))
emoji_sanitize(df, text, policy = "strip")
#> # A tibble: 2 × 1
#>   text    
#>   <chr>   
#> 1 ship it 
#> 2 no emoji
emoji_sanitize(df, text, policy = "name")
#> # A tibble: 2 × 1
#>   text          
#>   <chr>         
#> 1 ship it rocket
#> 2 no emoji      
emoji_sanitize(df, text, policy = "placeholder")
#> # A tibble: 2 × 1
#>   text           
#>   <chr>          
#> 1 ship it [emoji]
#> 2 no emoji       
```
