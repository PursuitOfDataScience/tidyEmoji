# tidyEmoji

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
2.  Load it:
    [`library(tidyEmoji)`](https://pursuitofdatascience.github.io/tidyEmoji/)
3.  Hand any verb a data frame and its text column:
    `emoji_summary(df, text)`
4.  Take the tour:
    [`vignette("introduction", package = "tidyEmoji")`](https://pursuitofdatascience.github.io/tidyEmoji/articles/introduction.md)

## 🧰 Pick a verb by question

| Question | Verbs |
|----|----|
| How much emoji is here, and which? | [`emoji_summary()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_summary.md), [`emoji_frequency()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_frequency.md), [`emoji_tokens()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_tokens.md) |
| What does it say? | [`emoji_sentiment()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sentiment.md), [`emoji_emotion()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_emotion.md), [`emoji_coverage()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_coverage.md) |
| Will readers agree on it? | [`emoji_ambiguity()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_ambiguity.md), [`emoji_risk()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_risk.md) |
| What is this glyph, exactly? | [`emoji_properties()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_properties.md), [`emoji_identical()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_identical.md), [`emoji_find()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_find.md) |
| What goes with what? | [`emoji_pairs()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_pairs.md), [`emoji_collocations()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_collocations.md), [`emoji_ngrams()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_ngrams.md) |
| When, and how new? | [`emoji_trend()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_trend.md), [`emoji_adoption_lag()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_adoption_lag.md) |
| Which countries do the flags name? | [`emoji_country()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_country.md), [`emoji_flag()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_flag.md) |
| Reaction counts rather than text? | [`emoji_from_counts()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_from_counts.md) |
| Sending text to a language model? | [`emoji_sanitize()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sanitize.md), [`emoji_token_cost()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_token_cost.md) |

## 💡 Tips

- Count bare text-style emoji such as the plain heart with
  `presentation = "any"`, which every counting and scoring verb takes.
- Report
  [`emoji_coverage()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_coverage.md)
  next to any lexicon score: it says how much of the corpus the score
  covers.
- Paste
  [`emoji_provenance()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_provenance.md)
  into a methods section: it records the Unicode catalogue (Emoji 18.0,
  bundled) and the lexicons behind a result.

## 📚 Learn more

Three articles ship with the package:
[`vignette("introduction")`](https://pursuitofdatascience.github.io/tidyEmoji/articles/introduction.md)
for a full analysis of a real corpus,
[`vignette("reversible-preprocessing")`](https://pursuitofdatascience.github.io/tidyEmoji/articles/reversible-preprocessing.md)
for emoji in language-model pipelines, and
[`vignette("emoji-networks")`](https://pursuitofdatascience.github.io/tidyEmoji/articles/emoji-networks.md)
for co-occurrence networks. All three are on the [package
website](https://pursuitofdatascience.github.io/tidyEmoji/).
