# The dominant emoji emotion per row

`emoji_emotion_label()` adds `.emoji_emotion`, the emotion with the
highest mean score among the row's emoji (using
[`emoji_emotion()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_emotion.md)).
Ties are broken in Plutchik order; rows with no scored emoji receive
`NA`.

## Usage

``` r
emoji_emotion_label(data, text, lexicon = "emotag1200")
```

## Arguments

- data:

  A data frame or tibble containing a text column.

- text:

  The text column to scan, supplied unquoted.

- lexicon:

  Passed to
  [`emoji_emotion()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_emotion.md).

## Value

`data`, as a tibble, with a `.emoji_emotion` column added.

## Examples

``` r
df <- data.frame(text = c("love it \U0001f60d", "scary \U0001f628", "meh"))
emoji_emotion_label(df, text)
#> # A tibble: 3 × 4
#>   text       .emoji_n .emoji_n_scored .emoji_emotion
#>   <chr>         <int>           <int> <chr>         
#> 1 love it 😍        1               1 joy           
#> 2 scary 😨          1               1 fear          
#> 3 meh               0              NA NA            
```
