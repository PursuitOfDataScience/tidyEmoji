# Document-by-emoji feature matrix

`emoji_dfm()` turns a text column into a wide, model-ready table with
one row per document and one column per emoji, weighted by raw counts,
binary presence or tf-idf. All documents are kept, including those with
no emoji (all-zero rows), so the result aligns row-for-row with the
corpus and can be bound to outcome columns for tidymodels-style
workflows.

## Usage

``` r
emoji_dfm(data, text, doc_id = NULL, weighting = c("count", "binary", "tfidf"))
```

## Arguments

- data:

  A data frame or tibble containing a text column.

- text:

  The text column to scan, supplied unquoted.

- doc_id:

  Optional unquoted column identifying documents; rows sharing a value
  are aggregated into one document. Default: each row is a document.

- weighting:

  One of `"count"` (default), `"binary"` or `"tfidf"`.

## Value

A tibble with one row per document: `.row_number` (or the `doc_id`
column) followed by one numeric column per emoji. Zero emoji in the
corpus yields just the document column.

## Details

By default every row of `data` is a document and the first output
column, `.row_number`, is its position in `data` (matching
[`emoji_extract_unnest()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_extract_unnest.md)).
Give `doc_id` to aggregate rows sharing an id into one document; the id
column keeps its name. Emoji columns are named by the glyph itself,
canonicalised through the package's codepoint key (so qualified and
unqualified forms count as one feature), and ordered by descending total
count (ties broken by glyph).

For `weighting = "tfidf"`, the cell for emoji *e* in document *d* is
`count(d, e) * log(N / df(e))`, where `N` is the number of documents and
`df(e)` the number of documents containing *e*. An emoji that appears in
every document therefore scores 0.

## See also

[`emoji_frequency()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_frequency.md)
for corpus totals;
[`emoji_tokens()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_tokens.md)
for the long form this widens.

## Examples

``` r
df <- data.frame(text = c("\U0001f600\U0001f600 fun", "\U0001f621",
                          "no emoji"))
emoji_dfm(df, text)
#> # A tibble: 3 × 3
#>   .row_number  `😀`  `😡`
#>         <int> <int> <int>
#> 1           1     2     0
#> 2           2     0     1
#> 3           3     0     0
emoji_dfm(df, text, weighting = "binary")
#> # A tibble: 3 × 3
#>   .row_number  `😀`  `😡`
#>         <int> <dbl> <dbl>
#> 1           1     1     0
#> 2           2     0     1
#> 3           3     0     0
emoji_dfm(df, text, weighting = "tfidf")
#> # A tibble: 3 × 3
#>   .row_number  `😀`  `😡`
#>         <int> <dbl> <dbl>
#> 1           1  2.20  0   
#> 2           2  0     1.10
#> 3           3  0     0   
```
