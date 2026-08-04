# How face-heavy is each row's emoji use?

`emoji_faceness()` reports the share of a row's emoji that are faces.
Face emoji act as emotional signals and object emoji as semantic ones,
and the two have measurably different effects on engagement, so the
split is worth a column of its own.

## Usage

``` r
emoji_faceness(data, text)
```

## Arguments

- data:

  A data frame or tibble containing a text column.

- text:

  The text column to scan, supplied unquoted.

## Value

`data`, as a tibble, with added columns `.emoji_n`, `.emoji_n_typed`
(emoji whose type is known), `.emoji_n_face` and `.emoji_faceness`
(`.emoji_n_face / .emoji_n_typed`). Rows with no emoji get `NA`.

## See also

[`emoji_type()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_type.md),
[`as_emoji_type()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/as_emoji_type.md).

## Examples

``` r
df <- data.frame(text = c("\U0001f600\U0001f355", "\U0001f600", "none"))
emoji_faceness(df, text)
#> # A tibble: 3 × 5
#>   text  .emoji_n .emoji_n_typed .emoji_n_face .emoji_faceness
#>   <chr>    <int>          <int>         <int>           <dbl>
#> 1 😀🍕         2              2             1             0.5
#> 2 😀           1              1             1             1  
#> 3 none         0             NA            NA            NA  
```
