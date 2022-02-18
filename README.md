
<!-- README.md is generated from README.Rmd. Please edit that file -->

# tidyEmoji

<!-- badges: start -->

[![R-CMD-check](https://github.com/PursuitOfDataScience/tidyEmoji/workflows/R-CMD-check/badge.svg)](https://github.com/PursuitOfDataScience/tidyEmoji/actions)
[![CRAN
status](https://www.r-pkg.org/badges/version/tidyEmoji)](https://CRAN.R-project.org/package=tidyEmoji)
<!-- badges: end -->

The goal of tidyEmoji is to help R users work with text data with the
presence of Emoji as easy as possible. The most common text data that
falls into this category would be Tweets. When people tweet their
emotions, ideas, celebrations, etc., Emoji sometimes appears on their
Tweets, making the text rendered more colorful. To researchers/users who
want to work with this type of text, it is intriguing to know the
information about Emoji appearing in the text. With the help of
tidyEmoji, dealing with Emoji is at ease.

## Installation

Please install the released version of `tidyEmoji` from CRAN with:

``` r
install.packages("tidyEmoji")
```

Alternatively, you can install the latest development version from
Github with:

``` r
# install.packages("devtools")
devtools::install_github("PursuitOfDataScience/tidyEmoji")
```

## Usage

Here a tweet-like dataframe is created for brief demostration.

``` r
library(tidyEmoji)
library(dplyr)
```

``` r
tweet_df <- data.frame(tweets = c("I love tidyverse \U0001f600\U0001f603\U0001f603",
                                  "R is my language! \U0001f601\U0001f606\U0001f605",
                                  "This Tweet does not have Emoji!",
                                  "Wearing a mask\U0001f637\U0001f637\U0001f637\U0001f637.",
                                  "Emoji does not appear in all Tweets",
                                  "A flag \U0001f600\U0001f3c1"))
```

### Emoji Tweets summary

Emoji Tweets are defined as Tweets containing at least one Emoji.

-   `emoji_summary()`:

``` r
tweet_df %>%
  emoji_summary(tweets)
#> # A tibble: 1 x 2
#>   emoji_tweets total_tweets
#>          <int>        <int>
#> 1            4            6
```

`emoji_summary()` gives an overview of how many Emoji Tweets and Tweet
in total the data has.

-   `emoji_tweets()`:

``` r
tweet_df %>%
  emoji_tweets(tweets)
#>                                                            tweets
#> 1           I love tidyverse <U+0001F600><U+0001F603><U+0001F603>
#> 2          R is my language! <U+0001F601><U+0001F606><U+0001F605>
#> 3 Wearing a mask<U+0001F637><U+0001F637><U+0001F637><U+0001F637>.
#> 4                                 A flag <U+0001F600><U+0001F3C1>
```

`emoji_tweets()` filters out non-Emoji Tweets while preserving the raw
data structure.

### Popular Emoji Tweets

-   `top_n_emojis()`:

``` r
tweet_df %>%
  top_n_emojis(tweets, n = 2)
#> # A tibble: 2 x 4
#>   emoji_name             unicode      emoji_category        n
#>   <chr>                  <chr>        <chr>             <int>
#> 1 face_with_medical_mask "\U0001f637" Smileys & Emotion     4
#> 2 grinning               "\U0001f600" Smileys & Emotion     2
```

`top_n_emojis()` returns a tibble about the most popular Emojis in the
entire data. `n` is how many the most popular Emojis users want to
output. By default, it is 20.

### Emoji extraction

-   `emoji_extract_unnest()`:

``` r
tweet_df %>%
  emoji_extract_unnest(tweets)
#> # A tibble: 8 x 3
#>   row_number .emoji_unicode .emoji_count
#>        <int> <chr>                 <int>
#> 1          1 "\U0001f600"              1
#> 2          1 "\U0001f603"              2
#> 3          2 "\U0001f601"              1
#> 4          2 "\U0001f605"              1
#> 5          2 "\U0001f606"              1
#> 6          4 "\U0001f637"              4
#> 7          6 "\U0001f3c1"              1
#> 8          6 "\U0001f600"              1
```

When looking at the tibble above, it has three columns: `row_number`,
`.emoji_unicode`, and `.emoji_count`. `row_number` is which row each
Tweet is located in the raw data. This can give users a global overview
of Emoji and count.

-   `emoji_extract_nest()`:

`emoji_extract_nest()` is analogous to `emoji_extract_unnest()`, but it
preserves the raw data with one extra column `.emoji_unicode` added.

``` r
tweet_df %>%
  emoji_extract_nest(tweets)
#>                                                            tweets
#> 1           I love tidyverse <U+0001F600><U+0001F603><U+0001F603>
#> 2          R is my language! <U+0001F601><U+0001F606><U+0001F605>
#> 3                                 This Tweet does not have Emoji!
#> 4 Wearing a mask<U+0001F637><U+0001F637><U+0001F637><U+0001F637>.
#> 5                             Emoji does not appear in all Tweets
#> 6                                 A flag <U+0001F600><U+0001F3C1>
#>                                           .emoji_unicode
#> 1               <U+0001F600>, <U+0001F603>, <U+0001F603>
#> 2               <U+0001F601>, <U+0001F606>, <U+0001F605>
#> 3                                                       
#> 4 <U+0001F637>, <U+0001F637>, <U+0001F637>, <U+0001F637>
#> 5                                                       
#> 6                             <U+0001F600>, <U+0001F3C1>
```

### Emoji category

-   `emoji_categorize()`:

``` r
tweet_df %>%
  emoji_categorize(tweets)
#> # A tibble: 4 x 2
#>   tweets                                                    .emoji_category     
#>   <chr>                                                     <chr>               
#> 1 "I love tidyverse \U0001f600\U0001f603\U0001f603"         Smileys & Emotion   
#> 2 "R is my language! \U0001f601\U0001f606\U0001f605"        Smileys & Emotion   
#> 3 "Wearing a mask\U0001f637\U0001f637\U0001f637\U0001f637." Smileys & Emotion   
#> 4 "A flag \U0001f600\U0001f3c1"                             Smileys & Emotion|F~
```

Each Emoji Tweet is categorized based on the Emoji(s). If Emojis fall
into various categories, the `.emoji_category` column has `|` to
separate each category.

For more information about tidyEmoji, please refer to the package
vignette for a comprehensive introduction.
