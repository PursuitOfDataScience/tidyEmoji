
<!-- README.md is generated from README.Rmd. Please edit that file -->

# tidyEmoji <img src="man/figures/logo.png" align="right" height="139" alt="tidyEmoji hex logo" />

<!-- badges: start -->

[![R-CMD-check](https://github.com/PursuitOfDataScience/tidyEmoji/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/PursuitOfDataScience/tidyEmoji/actions)
[![CRAN
status](https://www.r-pkg.org/badges/version/tidyEmoji)](https://CRAN.R-project.org/package=tidyEmoji)
[![CRAN
downloads](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fcranlogs.r-pkg.org%2Fdownloads%2Ftotal%2F1990-01-01%3A2030-01-01%2FtidyEmoji&query=%24%5B0%5D.downloads&label=downloads&color=blue)](https://CRAN.R-project.org/package=tidyEmoji)
[![Lifecycle:
maturing](https://img.shields.io/badge/lifecycle-maturing-blue.svg)](https://lifecycle.r-lib.org/articles/stages.html#maturing)
<!-- badges: end -->

**Count, score, translate and relate the emoji in any text column, and
get tidy data frames back.**

``` r
library(tidyEmoji)

reviews <- data.frame(text = c("Best purchase ever \U0001f600\U0001f60d",
                               "It broke after a day \U0001f621",
                               "Does the job.",
                               "Shipped to \U0001f1ef\U0001f1f5 in two days \U0001f680"))

emoji_frequency(reviews, text)
#> # A tibble: 5 × 5
#>   emoji name                         shortcode  group                 n
#>   <chr> <chr>                        <chr>      <chr>             <int>
#> 1 🇯🇵    flag: Japan                  jp         Flags                 1
#> 2 😀    grinning face                grinning   Smileys & Emotion     1
#> 3 😍    smiling face with heart-eyes heart_eyes Smileys & Emotion     1
#> 4 😡    enraged face                 rage       Smileys & Emotion     1
#> 5 🚀    rocket                       rocket     Travel & Places       1
emoji_sentiment(reviews, text)
#> # A tibble: 4 × 4
#>   text                         .emoji_n .emoji_n_scored .emoji_sentiment
#>   <chr>                           <int>           <int>            <dbl>
#> 1 Best purchase ever 😀😍             2               2            0.625
#> 2 It broke after a day 😡             1               1           -0.173
#> 3 Does the job.                       0              NA           NA    
#> 4 Shipped to 🇯🇵 in two days 🚀        2               1            0.525
```

How much of that could the lexicon score? One more call says so:

``` r
emoji_coverage(reviews, text)[, c("lexicon", "occurrence_coverage",
                                  "n_rows_unscored")]
#> # A tibble: 2 × 3
#>   lexicon    occurrence_coverage n_rows_unscored
#>   <chr>                    <dbl>           <int>
#> 1 novak2015                  0.8               0
#> 2 emotag1200                 0.6               1
```

## 🚀 Get started

1.  Install from CRAN: `install.packages("tidyEmoji")`
2.  Load it: `library(tidyEmoji)`
3.  Hand any verb a data frame and its text column:
    `emoji_summary(df, text)`
4.  Take the tour: `vignette("introduction", package = "tidyEmoji")`

## 🧰 Pick a verb by question

| Question | Verbs |
|----|----|
| How much emoji is here, and which? | `emoji_summary()`, `emoji_frequency()`, `emoji_tokens()` |
| What does it say? | `emoji_sentiment()`, `emoji_emotion()`, `emoji_coverage()` |
| Will readers agree on it? | `emoji_ambiguity()`, `emoji_risk()` |
| What is this glyph, exactly? | `emoji_properties()`, `emoji_identical()`, `emoji_find()` |
| What goes with what? | `emoji_pairs()`, `emoji_collocations()`, `emoji_ngrams()` |
| When, and how new? | `emoji_trend()`, `emoji_adoption_lag()` |
| Which countries do the flags name? | `emoji_country()`, `emoji_flag()` |
| Reaction counts rather than text? | `emoji_from_counts()` |
| Sending text to a language model? | `emoji_sanitize()`, `emoji_token_cost()` |

## 💡 Tips

- Count bare text-style emoji such as the plain heart with
  `presentation = "any"`, which every counting and scoring verb takes.
- Report `emoji_coverage()` next to any lexicon score: it says how much
  of the corpus the score covers.
- Paste `emoji_provenance()` into a methods section: it records the
  Unicode catalogue (Emoji 18.0, bundled) and the lexicons behind a
  result.

## 📚 Learn more

Three articles ship with the package: `vignette("introduction")` for a
full analysis of a real corpus, `vignette("reversible-preprocessing")`
for emoji in language-model pipelines, and `vignette("emoji-networks")`
for co-occurrence networks. All three are on the [package
website](https://pursuitofdatascience.github.io/tidyEmoji/).
