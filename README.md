
<!-- README.md is generated from README.Rmd. Please edit that file -->

# tidyEmoji

<!-- badges: start -->

[![R-CMD-check](https://github.com/PursuitOfDataScience/tidyEmoji/workflows/R-CMD-check/badge.svg)](https://github.com/PursuitOfDataScience/tidyEmoji/actions)
[![CRAN
status](https://www.r-pkg.org/badges/version/tidyEmoji)](https://CRAN.R-project.org/package=tidyEmoji)
[![Lifecycle:
stable](https://img.shields.io/badge/lifecycle-stable-brightgreen.svg)](https://lifecycle.r-lib.org/articles/stages.html#stable)
<!-- badges: end -->

tidyEmoji helps you **discover, count, categorise and sentiment-score
the emoji in any text column** — social-media posts, product reviews,
chat logs, survey responses, support tickets — and hands the result back
as tidy data frames that drop straight into a tidyverse workflow.

Unicode is awkward to work with and not every code point is an emoji,
which makes emoji statistics fiddly. tidyEmoji takes care of that,
including grapheme-aware detection so skin-tone modifiers (👍🏽) and
multi-person sequences (👨‍👩‍👧‍👦) are treated as a single emoji rather than
being split apart.

## Installation

``` r
install.packages("tidyEmoji")

# development version
# install.packages("devtools")
devtools::install_github("PursuitOfDataScience/tidyEmoji")
```

## Usage

``` r
library(tidyEmoji)
library(dplyr)

reviews <- data.frame(text = c("Best purchase ever \U0001f600\U0001f60d",
                               "It broke after a day \U0001f621",
                               "Does the job.",
                               "Wearing my mask \U0001f637\U0001f637",
                               "Shipped fast \U0001f3c1\U0001f600"))
```

### How much emoji is in the data?

``` r
reviews %>% emoji_summary(text)        # entries with emoji vs. total
#> # A tibble: 1 × 2
#>   emoji_tweets total_tweets
#>          <int>        <int>
#> 1            4            5
reviews %>% emoji_filter(text)         # keep only the rows that have emoji
#> # A tibble: 4 × 1
#>   text                   
#>   <chr>                  
#> 1 Best purchase ever 😀😍
#> 2 It broke after a day 😡
#> 3 Wearing my mask 😷😷   
#> 4 Shipped fast 🏁😀
```

### Which emoji are most common?

``` r
reviews %>% emoji_frequency(text)      # every emoji, with name + category
#> # A tibble: 5 × 5
#>   emoji name                         shortcode      group                 n
#>   <chr> <chr>                        <chr>          <chr>             <int>
#> 1 😀    grinning face                grinning       Smileys & Emotion     2
#> 2 😷    face with medical mask       mask           Smileys & Emotion     2
#> 3 🏁    chequered flag               checkered_flag Flags                 1
#> 4 😍    smiling face with heart-eyes heart_eyes     Smileys & Emotion     1
#> 5 😡    enraged face                 rage           Smileys & Emotion     1
reviews %>% top_n_emojis(text, n = 3)  # just the most frequent
#> # A tibble: 3 × 4
#>   emoji_name     unicode emoji_category        n
#>   <chr>          <chr>   <chr>             <int>
#> 1 grinning       😀      Smileys & Emotion     2
#> 2 mask           😷      Smileys & Emotion     2
#> 3 checkered_flag 🏁      Flags                 1
```

### Pull the emoji out

`emoji_tokens()` gives one tidy row per emoji occurrence, with its name,
category and sentiment — ready to count, join or plot.

``` r
reviews %>% emoji_tokens(text)
#> # A tibble: 7 × 5
#>   text                    .emoji .emoji_name    .emoji_category .emoji_sentiment
#>   <chr>                   <chr>  <chr>          <chr>                      <dbl>
#> 1 Best purchase ever 😀😍 😀     grinning face  Smileys & Emot…            0.572
#> 2 Best purchase ever 😀😍 😍     smiling face … Smileys & Emot…            0.678
#> 3 It broke after a day 😡 😡     enraged face   Smileys & Emot…           -0.173
#> 4 Wearing my mask 😷😷    😷     face with med… Smileys & Emot…           -0.171
#> 5 Wearing my mask 😷😷    😷     face with med… Smileys & Emot…           -0.171
#> 6 Shipped fast 🏁😀       🏁     chequered flag Flags                      0.571
#> 7 Shipped fast 🏁😀       😀     grinning face  Smileys & Emot…            0.572
```

### Categorise and score sentiment

``` r
reviews %>% emoji_categorize(text)     # which Unicode categories each row spans
#> # A tibble: 4 × 2
#>   text                    .emoji_category        
#>   <chr>                   <chr>                  
#> 1 Best purchase ever 😀😍 Smileys & Emotion      
#> 2 It broke after a day 😡 Smileys & Emotion      
#> 3 Wearing my mask 😷😷    Smileys & Emotion      
#> 4 Shipped fast 🏁😀       Flags|Smileys & Emotion
reviews %>% emoji_sentiment(text)      # mean emoji sentiment per row (-1 to +1)
#> # A tibble: 5 × 3
#>   text                    .emoji_n .emoji_sentiment
#>   <chr>                      <int>            <dbl>
#> 1 Best purchase ever 😀😍        2            0.625
#> 2 It broke after a day 😡        1           -0.173
#> 3 Does the job.                  0           NA    
#> 4 Wearing my mask 😷😷           2           -0.171
#> 5 Shipped fast 🏁😀              2            0.572
```

`emoji_sentiment()` uses the bundled **Emoji Sentiment Ranking** lexicon
(Kralj Novak et al., 2015). See the package vignette for a fuller tour.
