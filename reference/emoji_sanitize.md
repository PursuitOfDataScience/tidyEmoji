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

  A data frame or tibble containing a text column.

- text:

  The text column to scan, supplied unquoted.

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
