
<!-- README.md is generated from README.Rmd. Please edit that file -->

# tidyEmoji

<!-- badges: start -->

[![R-CMD-check](https://github.com/PursuitOfDataScience/tidyEmoji/workflows/R-CMD-check/badge.svg)](https://github.com/PursuitOfDataScience/tidyEmoji/actions)
[![CRAN
status](https://www.r-pkg.org/badges/version/tidyEmoji)](https://CRAN.R-project.org/package=tidyEmoji)
[![Lifecycle:
maturing](https://img.shields.io/badge/lifecycle-maturing-blue.svg)](https://lifecycle.r-lib.org/articles/stages.html#maturing)
<!-- badges: end -->

tidyEmoji helps you **discover, count, categorise, sentiment-score,
score emotions, translate and relate the emoji in any text column** —
social-media posts, product reviews, chat logs, survey responses,
support tickets — from summary counts through emotion profiles,
co-occurrence networks, structural metrics and model-ready feature
tables, always as tidy data frames that drop straight into a tidyverse
workflow.

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
#>   n_with_emoji n_total
#>          <int>   <int>
#> 1            4       5
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
#> # A tibble: 5 × 4
#>   text                    .emoji_n .emoji_n_scored .emoji_sentiment
#>   <chr>                      <int>           <int>            <dbl>
#> 1 Best purchase ever 😀😍        2               2            0.625
#> 2 It broke after a day 😡        1               1           -0.173
#> 3 Does the job.                  0              NA           NA    
#> 4 Wearing my mask 😷😷           2               2           -0.171
#> 5 Shipped fast 🏁😀              2               2            0.572
```

`emoji_sentiment()` uses the bundled **Emoji Sentiment Ranking** lexicon
(Kralj Novak et al., 2015). See the package vignette for a fuller tour.

### Score emoji emotions

`emoji_emotion()` scores each row’s emoji across the eight Plutchik
emotions using the bundled EmoTag1200 lexicon (Shoeb & de Melo, 2020).

``` r
reviews %>% emoji_emotion(text) %>% select(text, .emoji_joy, .emoji_trust,
                                           .emoji_anger, .emoji_n)
#> # A tibble: 5 × 5
#>   text                    .emoji_joy .emoji_trust .emoji_anger .emoji_n
#>   <chr>                        <dbl>        <dbl>        <dbl>    <int>
#> 1 Best purchase ever 😀😍       0.76        0.375         0.03        2
#> 2 It broke after a day 😡       0           0.06          1           1
#> 3 Does the job.                NA          NA            NA           0
#> 4 Wearing my mask 😷😷          0           0.11          0.03        2
#> 5 Shipped fast 🏁😀             0.69        0.25          0.06        2
reviews %>% emoji_emotion_label(text)   # the dominant emotion per row
#> # A tibble: 5 × 4
#>   text                    .emoji_n .emoji_n_scored .emoji_emotion
#>   <chr>                      <int>           <int> <chr>         
#> 1 Best purchase ever 😀😍        2               2 joy           
#> 2 It broke after a day 😡        1               1 anger         
#> 3 Does the job.                  0              NA <NA>          
#> 4 Wearing my mask 😷😷           2               2 disgust       
#> 5 Shipped fast 🏁😀              2               1 joy
```

### Relate emoji to each other

`emoji_pairs()` returns a graph-ready edge list of the emoji that appear
in the same entry (`widyr`-style `item1`/`item2`/`n` — pipe it into
igraph, tidygraph or ggraph), and `emoji_ngrams()` captures consecutive
sequences.

``` r
reviews %>% emoji_pairs(text)
#> # A tibble: 2 × 3
#>   item1 item2     n
#>   <chr> <chr> <int>
#> 1 🏁    😀        1
#> 2 😀    😍        1
```

There are structural metrics too — `emoji_position()` (emoji sit at the
end of messages), `emoji_density()` and `emoji_ratio()` (emoji-only
detection) — and `emoji_dfm()` builds a document-by-emoji
count/binary/tf-idf table for modelling.

``` r
reviews %>% emoji_dfm(text) %>% select(1:4)
#> # A tibble: 5 × 4
#>   .row_number  `😀`  `😷`  `🏁`
#>         <int> <int> <int> <int>
#> 1           1     1     0     0
#> 2           2     0     0     0
#> 3           3     0     0     0
#> 4           4     0     2     0
#> 5           5     1     0     1
```

### Bring your own lexicon

The scoring machinery is pluggable: `emoji_lexicons()` lists what’s
available, `register_emoji_lexicon()` adds your own, and `emoji_score()`
scores a text column against any of them — always joining through a
codepoint-normalised key, so qualified and unqualified emoji forms both
match.

``` r
my_lexicon <- data.frame(emoji = c("\U0001f600", "\U0001f621"),
                         score = c(1, -1))
reviews %>% emoji_score(text, lexicon = my_lexicon)
#> # A tibble: 5 × 4
#>   text                    .emoji_score .emoji_n_scored .emoji_n
#>   <chr>                          <dbl>           <int>    <int>
#> 1 Best purchase ever 😀😍            1               1        2
#> 2 It broke after a day 😡           -1               1        1
#> 3 Does the job.                     NA              NA        0
#> 4 Wearing my mask 😷😷              NA               0        2
#> 5 Shipped fast 🏁😀                  1               1        2
```

### Translate emoji to and from text

`emoji_to_text()` replaces emoji with words (handy for accessibility and
NLP preprocessing); `text_to_emoji()` is the inverse. `as_emoji_name()`,
`as_emoji_shortcode()` and `as_emoji()` are the vector-level
equivalents.

``` r
reviews %>% emoji_to_text(text, format = "name")
#> # A tibble: 5 × 1
#>   text                                                        
#>   <chr>                                                       
#> 1 Best purchase ever grinning facesmiling face with heart-eyes
#> 2 It broke after a day enraged face                           
#> 3 Does the job.                                               
#> 4 Wearing my mask face with medical maskface with medical mask
#> 5 Shipped fast chequered flaggrinning face
reviews %>% emoji_to_text(text, format = "shortcode")
#> # A tibble: 5 × 1
#>   text                                     
#>   <chr>                                    
#> 1 Best purchase ever :grinning::heart_eyes:
#> 2 It broke after a day :rage:              
#> 3 Does the job.                            
#> 4 Wearing my mask :mask::mask:             
#> 5 Shipped fast :checkered_flag::grinning:
```

You can also search the emoji catalogue by keyword:

``` r
emoji_search("happy")
#> # A tibble: 27 × 5
#>    emoji name                            shortcode             group     keyword
#>    <chr> <chr>                           <chr>                 <chr>     <chr>  
#>  1 😀    grinning face                   grinning              Smileys … happy  
#>  2 😃    grinning face with big eyes     smiley                Smileys … happy  
#>  3 😄    grinning face with smiling eyes smile                 Smileys … happy  
#>  4 😁    beaming face with smiling eyes  grin                  Smileys … happy  
#>  5 😆    grinning squinting face         laughing              Smileys … happy  
#>  6 🤣    rolling on the floor laughing   rofl                  Smileys … happy  
#>  7 😂    face with tears of joy          joy                   Smileys … happy  
#>  8 🙂    slightly smiling face           slightly_smiling_face Smileys … happy  
#>  9 😇    smiling face with halo          innocent              Smileys … happy  
#> 10 ☺     smiling face                    smiling_face          Smileys … happy  
#> # ℹ 17 more rows
```

## Learn more

The [introductory
vignette](https://pursuitofdatascience.github.io/tidyEmoji/articles/introduction.html)
(`vignette("introduction", package = "tidyEmoji")`) walks through a full
analysis of a real corpus — counting, categorising, sentiment- and
emotion-scoring emoji, and plotting the results.
