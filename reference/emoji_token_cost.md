# What are the emoji in this text costing a tokeniser?

`emoji_token_cost()` measures the size of the emoji in each row: bytes,
code points, grapheme clusters, and an estimate of the tokens they will
cost a byte-level tokeniser. Emoji are several times more expensive than
their visual weight suggests – a single ZWJ family emoji can run to well
over a dozen tokens – which makes them a real line item in a prompt
budget.

## Usage

``` r
emoji_token_cost(data, text, tokenizer = NULL)
```

## Arguments

- data:

  A data frame or tibble containing a text column.

- text:

  The text column to scan, supplied unquoted.

- tokenizer:

  Optional function taking a character vector and returning either token
  counts (a numeric vector of the same length) or a list of token
  vectors. It is called on the row's emoji, concatenated. `NULL`
  (default) uses the byte heuristic.

## Value

`data`, as a tibble, with added columns `.emoji_n`, `.emoji_bytes`,
`.emoji_codepoints`, `.emoji_graphemes` and `.emoji_token_estimate`.

## Details

Bytes, code points and graphemes are exact and tidyEmoji can be
authoritative about them. The token count cannot be: it depends on the
tokeniser. Without `tokenizer`, `.emoji_token_estimate` is a
deliberately crude heuristic of roughly two UTF-8 bytes per token, which
is in the right range for byte-level BPE vocabularies but is an estimate
and should never be quoted as a bill. Pass your real tokeniser through
`tokenizer` when the number matters.

`.emoji_graphemes` is the number of emoji occurrences, since the
package's detection is grapheme-aware: a skin-toned family emoji is one
grapheme and many code points, which is precisely the gap that makes
emoji expensive.

## See also

[`emoji_sanitize()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sanitize.md)
for acting on the answer;
[`emoji_ratio()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_ratio.md)
for the share of the text that is emoji.

## Examples

``` r
family <- paste0("\U0001F468\u200d\U0001F469\u200d",
                  "\U0001F467\u200d\U0001F466")
df <- data.frame(text = c("hi \U0001f600", family, "plain"))
emoji_token_cost(df, text)
#> # A tibble: 3 × 6
#>   text  .emoji_n .emoji_bytes .emoji_codepoints .emoji_graphemes
#>   <chr>    <int>        <int>             <int>            <int>
#> 1 hi 😀        1            4                 1                1
#> 2 👨‍👩‍👧‍👦           1           25                 7                1
#> 3 plain        0            0                 0                0
#> # ℹ 1 more variable: .emoji_token_estimate <int>
```
