# Introduction to tidyEmoji

## Overview

Emoji are everywhere in modern text (social-media posts, product
reviews, chat and support logs, survey free-text), and they carry
information that plain words do not. Yet summarising emoji from a corpus
is surprisingly awkward. Unicode does not interact cleanly with regular
expressions, not every code point is an emoji, and a single visible
emoji is often built from several code points joined together. Counting
“how many posts contain an emoji” or “which emoji are most common” by
hand quickly becomes painful.

**tidyEmoji** removes that friction. It provides a small family of verbs
that take a data frame and the name of a text column, and return tidy
data frames that drop straight into a `dplyr`/`ggplot2` workflow:

| Task | Function(s) |
|----|----|
| Summarise / filter | [`emoji_summary()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_summary.md), [`emoji_filter()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_filter.md) |
| Extract | [`emoji_extract_nest()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_extract_nest.md), [`emoji_extract_unnest()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_extract_unnest.md), [`emoji_tokens()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_tokens.md) |
| Count | [`emoji_frequency()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_frequency.md), [`top_n_emojis()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/top_n_emojis.md) |
| Categorise | [`emoji_categorize()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_categorize.md) |
| Score sentiment | [`emoji_sentiment()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sentiment.md) |
| Score emotions | [`emoji_emotion()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_emotion.md), [`emoji_emotion_label()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_emotion_label.md) |
| Custom lexicons | [`emoji_lexicons()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_lexicons.md), [`register_emoji_lexicon()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/register_emoji_lexicon.md), [`emoji_score()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_score.md) |
| Translate | [`emoji_to_text()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_to_text.md), [`text_to_emoji()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/text_to_emoji.md), `as_emoji*()` |
| Search the vocabulary | [`emoji_search()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_search.md), [`emoji_find()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_find.md), [`emoji_keywords()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_keywords.md) |
| Describe a glyph | [`emoji_properties()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_properties.md), [`as_emoji_canonical()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/as_emoji_canonical.md), [`emoji_identical()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_identical.md) |
| Identity | [`emoji_decompose()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_decompose.md), [`emoji_skin_tone()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_skin_tone.md), [`emoji_gender()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_gender.md), [`emoji_retone()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_retone.md) |
| Sequences and accessibility | [`emoji_runs()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_runs.md), [`emoji_features()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_features.md), [`emoji_a11y_check()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_a11y_check.md) |
| Coverage | [`emoji_coverage()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_coverage.md) |
| Flags and places | [`emoji_country()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_country.md), [`emoji_subdivision()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_subdivision.md), [`emoji_flag()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_flag.md) |
| Tallies | [`emoji_from_counts()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_from_counts.md) |
| Relate | [`emoji_pairs()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_pairs.md), [`emoji_cooccurrence()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_cooccurrence.md), [`emoji_ngrams()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_ngrams.md) |
| Measure | [`emoji_position()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_position.md), [`emoji_density()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_density.md), [`emoji_ratio()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_ratio.md) |
| Interpretation risk | [`emoji_ambiguity()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_ambiguity.md), [`emoji_risk()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_risk.md), [`emoji_flag_ambiguous()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_flag_ambiguous.md) |
| Context | [`emoji_context()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_context.md), [`emoji_collocations()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_collocations.md) |
| Functional type | [`emoji_type()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_type.md), [`emoji_faceness()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_faceness.md), [`as_emoji_type()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/as_emoji_type.md) |
| Time | [`emoji_trend()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_trend.md), [`emoji_turnover()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_turnover.md), [`emoji_seasonality()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_seasonality.md), [`emoji_version_profile()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_version_profile.md), [`emoji_adoption_lag()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_adoption_lag.md) |
| Text-emoji mismatch | [`emoji_incongruity()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_incongruity.md), [`emoji_congruence()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_congruence.md), [`emoji_incongruity_profile()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_incongruity_profile.md) |
| Model features | [`emoji_dfm()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_dfm.md) |
| LLM pipelines | [`emoji_sanitize()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sanitize.md), [`emoji_token_cost()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_token_cost.md), [`emoji_hidden()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_hidden.md) |
| Provenance | [`emoji_provenance()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_provenance.md), [`emoji_unicode_version()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_unicode_version.md), [`emoji_unicode_releases()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_unicode_releases.md) |

### Find the verb for your question

The same capability serves many research communities, and the table
above is organised by what the verbs do rather than by what people ask.
This is the other index. Every help page also carries the matching
keyword, so `help.search("accessibility", package = "tidyEmoji")` finds
the verbs for it.

| If you are asking… | Start with |
|----|----|
| How much emoji is in this corpus, and which? | [`emoji_summary()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_summary.md), [`emoji_frequency()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_frequency.md) |
| How much of my corpus can a lexicon score? | [`emoji_coverage()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_coverage.md) |
| Is this emoji the same character as that one? (forensics, eDiscovery) | [`emoji_identical()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_identical.md), [`emoji_properties()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_properties.md) |
| What do readers disagree about? (content QA, miscommunication) | [`emoji_ambiguity()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_ambiguity.md), [`emoji_flag_ambiguous()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_flag_ambiguous.md) |
| Does the emoji contradict the words? (sarcasm, review helpfulness) | [`emoji_incongruity()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_incongruity.md), [`emoji_congruence()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_congruence.md) |
| Which countries do these flags name? | [`emoji_country()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_country.md), [`emoji_flag()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_flag.md) |
| What do the reactions on these pull requests say? | [`emoji_from_counts()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_from_counts.md) |
| Which emoji belong to a semantic field? (stimulus sets, L2 studies) | [`emoji_find()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_find.md), [`emoji_keywords()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_keywords.md) |
| Which words keep company with an emoji? | [`emoji_collocations()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_collocations.md) |
| Which emoji cluster together? (networks) | [`emoji_pairs()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_pairs.md), [`vignette("emoji-networks")`](https://pursuitofdatascience.github.io/tidyEmoji/articles/emoji-networks.md) |
| How did emoji use change over time, and how fast were new ones adopted? | [`emoji_trend()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_trend.md), [`emoji_adoption_lag()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_adoption_lag.md) |
| What will a screen reader announce? (accessibility) | [`emoji_to_text()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_to_text.md), [`as_emoji_name()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/as_emoji_name.md) |
| Is this message hard to follow with a screen reader? (accessibility) | [`emoji_a11y_check()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_a11y_check.md) |
| How do writers string emoji together? (reduplication, sequences) | [`emoji_runs()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_runs.md) |
| What is each emoji doing in its sentence? (emoji function) | [`emoji_features()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_features.md) |
| Faces or objects? (crisis communication, marketing) | [`emoji_type()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_type.md), [`emoji_faceness()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_faceness.md) |
| Which skin tones do writers choose, out of how many they could have? | [`emoji_skin_tone()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_skin_tone.md), [`emoji_decompose()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_decompose.md) |
| Which gender do the person emoji depict? | [`emoji_gender()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_gender.md) |
| Does a model treat the same text differently in another skin tone? (fairness) | [`emoji_retone()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_retone.md) |
| What should a language-model pipeline do with emoji? | [`emoji_sanitize()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sanitize.md), [`emoji_token_cost()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_token_cost.md) |
| Is something hidden in this text? (prompt injection, phishing) | [`emoji_hidden()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_hidden.md), [`emoji_sanitize()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sanitize.md) |
| How does a model’s own output use emoji? (LLM output auditing) | [`emoji_ratio()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_ratio.md), [`emoji_position()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_position.md) |
| What features does a classifier need? (stylometry, ML) | [`emoji_dfm()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_dfm.md) |
| Which catalogue and lexicons produced this result? | [`emoji_provenance()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_provenance.md) |

Two design choices are worth highlighting:

- **Grapheme-aware detection.** Detection is performed on whole grapheme
  clusters, so skin-tone modifiers (👍🏽) and zero-width-joiner sequences
  such as the family emoji (👨‍👩‍👧‍👦) are treated as a *single* emoji rather
  than being split into their component parts. This is illustrated in
  the [extraction section](#a-note-on-grapheme-aware-detection).
- **Tidy by default.** Every verb returns a tibble, follows the
  `verb(data, text_column)` convention, and supports unquoted column
  names, so the functions compose naturally with the pipe. Grouping
  composes too: the verbs that work a row at a time carry a
  [`group_by()`](https://dplyr.tidyverse.org/reference/group_by.html)
  through to their result, as
  [`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html)
  and
  [`dplyr::filter()`](https://dplyr.tidyverse.org/reference/filter.html)
  do, while the ones that pool across rows – the counts, the
  co-occurrence tables, the time series – warn that they ignore it and
  return one corpus-wide answer. See
  [`?tidyEmoji`](https://pursuitofdatascience.github.io/tidyEmoji/reference/tidyEmoji-package.md)
  for the full contract.

``` r

library(tidyEmoji)
library(dplyr)

# The charts below need three packages that tidyEmoji only Suggests. A vignette
# has to build without its optional dependencies, so the plotting chunks are
# gated on this flag rather than assuming the packages are there.
has_plot_pkgs <- all(vapply(
  c("ggplot2", "forcats", "stringr"),
  requireNamespace, logical(1), quietly = TRUE
))
if (has_plot_pkgs) library(ggplot2)
```

That gate covers building this vignette. It does *not* carry over to the
script `knitr` tangles out of it, the one
`edit(vignette("introduction", package = "tidyEmoji"))` opens: a chunk’s
`eval` option is a build-time instruction and is not part of the
extracted code, so `introduction.R` calls
[`ggplot()`](https://ggplot2.tidyverse.org/reference/ggplot.html)
unconditionally. Everything in it that uses tidyEmoji alone runs against
the package’s declared dependencies; install `ggplot2`, `forcats` and
`stringr` if you want to run the whole file.

That describes the script you get from an installed package, because the
tarball is built on a machine that has all three. The gate is evaluated
when the vignette is built, so if you rebuild it yourself without them,
`knitr` comments those chunks out of the tangled script rather than
emitting them.

## Example data

Throughout this vignette we use `oasst_messages`, a sample of 1,485
messages from OpenAssistant Conversations (OASST2, released under the
Apache License 2.0), bundled with the package: people asking an
assistant questions, and people writing the assistant’s replies, between
January and October 2023 and in 17 languages. Emoji are rare in real
text, so the sample is stratified on them: about half the messages carry
one, where about 1% of OASST2 does. The figures below describe this
sample, not chat in general.
[`?oasst_messages`](https://pursuitofdatascience.github.io/tidyEmoji/reference/oasst_messages.md)
says how it was drawn and screened. Nothing below is specific to it: any
data frame with a text column will do.

``` r

oasst_messages %>%
  select(created_at, role, lang)
#> # A tibble: 1,485 × 3
#>    created_at          role      lang 
#>    <dttm>              <chr>     <chr>
#>  1 2023-01-17 21:57:59 prompter  en   
#>  2 2023-01-18 02:53:56 assistant en   
#>  3 2023-01-18 16:46:42 prompter  en   
#>  4 2023-01-18 17:53:42 prompter  en   
#>  5 2023-01-18 18:55:26 assistant en   
#>  6 2023-01-18 20:34:44 assistant en   
#>  7 2023-01-19 09:04:12 prompter  en   
#>  8 2023-01-19 10:42:54 prompter  en   
#>  9 2023-01-20 06:19:07 prompter  en   
#> 10 2023-01-20 19:14:58 prompter  en   
#> # ℹ 1,475 more rows

emoji_summary(oasst_messages, text)
#> # A tibble: 1 × 6
#>   n_with_emoji n_total n_orphan_components n_invalid_flags n_unlisted n_hidden
#>          <int>   <int>               <int>           <int>      <int>    <int>
#> 1          750    1485                   0               0          3        0
```

The messages themselves live in the `text` column, which is the column
we pass to each tidyEmoji verb, beside a timestamp (`created_at`), the
writer’s `role` and the language (`lang`). The outputs below report what
tidyEmoji finds in that column rather than printing the messages.

## Detecting and summarising emoji

### `emoji_summary()`

[`emoji_summary()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_summary.md)
answers the first question one usually asks of a new corpus: *how much
emoji is in here?* It returns a one-row tibble with the number of
entries that contain at least one emoji and the total number of entries.
An entry is counted once regardless of how many emoji it holds.

``` r

summary_tbl <- oasst_messages %>%
  emoji_summary(text)

summary_tbl
#> # A tibble: 1 × 6
#>   n_with_emoji n_total n_orphan_components n_invalid_flags n_unlisted n_hidden
#>          <int>   <int>               <int>           <int>      <int>    <int>
#> 1          750    1485                   0               0          3        0
```

Here, 750 of the 1,485 entries (50.5%) contain at least one emoji.

### `emoji_filter()`

[`emoji_filter()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_filter.md)
keeps only the rows whose text contains at least one emoji, preserving
every original column. This is useful when you want to compare
emoji-bearing and emoji-free text, or restrict an analysis to the emoji
subset.
([`emoji_tweets()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_filter.md),
its old name, is defunct: since 0.7.0 it stops with an error naming
[`emoji_filter()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_filter.md).)

``` r

oasst_messages %>%
  emoji_filter(text) %>%
  nrow()
#> [1] 750
```

## Extracting emoji

tidyEmoji offers three complementary ways to pull the emoji out of text,
depending on the shape of output you want.

### `emoji_extract_nest()`

[`emoji_extract_nest()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_extract_nest.md)
leaves the data unchanged except for an added list-column,
`.emoji_unicode`, holding the emoji found in each row. The original data
structure is preserved, which makes this convenient as an intermediate
step.

``` r

oasst_messages %>%
  emoji_extract_nest(text) %>%
  select(.emoji_unicode)
#> # A tibble: 1,485 × 1
#>    .emoji_unicode
#>    <list>        
#>  1 <chr [0]>     
#>  2 <chr [0]>     
#>  3 <chr [0]>     
#>  4 <chr [0]>     
#>  5 <chr [0]>     
#>  6 <chr [0]>     
#>  7 <chr [0]>     
#>  8 <chr [0]>     
#>  9 <chr [0]>     
#> 10 <chr [0]>     
#> # ℹ 1,475 more rows
```

### `emoji_extract_unnest()`

[`emoji_extract_unnest()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_extract_unnest.md)
returns a long, tidy table with one row per (entry, emoji) pair:
`.row_number` records the position of the entry in the data,
`.emoji_unicode` is the emoji, and `.emoji_count` is how many times that
emoji occurs in that entry. Entries without emoji are dropped.

``` r

emoji_per_message <- oasst_messages %>%
  emoji_extract_unnest(text)

emoji_per_message
#> # A tibble: 1,284 × 3
#>    .row_number .emoji_unicode .emoji_count
#>          <int> <chr>                 <int>
#>  1          15 👍                        1
#>  2          32 🤓                        1
#>  3          39 😉                        1
#>  4          41 😊                        1
#>  5          46 ⛔                        1
#>  6          46 ❌                        1
#>  7          46 🌲                        1
#>  8          46 🏡                        1
#>  9          46 🐺                        1
#> 10          46 👧🏻                        1
#> # ℹ 1,274 more rows
```

We can use this to plot how many emoji each emoji-bearing entry
contains:

``` r

emoji_per_message %>%
  group_by(.row_number) %>%
  summarise(n_emoji = sum(.emoji_count)) %>%
  filter(n_emoji <= 10) %>%
  ggplot(aes(n_emoji)) +
  geom_bar() +
  scale_x_continuous(breaks = seq(1, 10)) +
  labs(x = "Number of emoji in the message",
       y = "Number of messages",
       title = "Most emoji-bearing messages contain a single emoji")
```

![Bar chart of the number of emoji per emoji-bearing message, up to ten.
About three messages in four contain a single emoji, with a long, thin
tail of more emoji-heavy
messages.](introduction_files/figure-html/unnamed-chunk-7-1.png)

About three emoji-bearing messages in four carry just one emoji, with a
long, thin tail of more emoji-heavy ones: a handful of replies tabulate
dozens, which is why the chart stops at ten.

### `emoji_tokens()`

[`emoji_tokens()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_tokens.md)
produces a “one row per emoji occurrence” table, the emoji analogue of a
tidy-text token table. It keeps the original columns and adds the glyph
(`.emoji`) together with its name (`.emoji_name`), category
(`.emoji_category`) and sentiment score (`.emoji_sentiment`). This
single call gives you everything needed for counting, joining and
plotting.

``` r

oasst_messages %>%
  emoji_tokens(text) %>%
  select(role, lang, starts_with(".emoji"))
#> # A tibble: 1,454 × 6
#>    role      lang  .emoji .emoji_name           .emoji_category .emoji_sentiment
#>    <chr>     <chr> <chr>  <chr>                 <chr>                      <dbl>
#>  1 assistant en    👍     thumbs up             People & Body              0.522
#>  2 prompter  en    🤓     nerd face             Smileys & Emot…           NA    
#>  3 assistant fr    😉     winking face          Smileys & Emot…            0.464
#>  4 assistant en    😊     smiling face with sm… Smileys & Emot…            0.645
#>  5 assistant ru    👧🏻     girl: light skin tone People & Body             NA    
#>  6 assistant ru    🔴     red circle            Symbols                    0.422
#>  7 assistant ru    🧒🏻     child: light skin to… People & Body             NA    
#>  8 assistant ru    🧑🏼‍🍳     cook: medium-light s… People & Body             NA    
#>  9 assistant ru    🌲     evergreen tree        Animals & Natu…            0.435
#> 10 assistant ru    🐺     wolf                  Animals & Natu…            0.263
#> # ℹ 1,444 more rows
```

### A note on grapheme-aware detection

Modern emoji are frequently composed of several code points: a base
emoji plus a skin-tone modifier, or several emoji joined by zero-width
joiners. tidyEmoji detects emoji at the level of grapheme clusters, so
these stay intact. The example below contains exactly two emoji (one
family and one thumbs-up), and tidyEmoji counts them as such rather than
splitting the family into four people or separating the thumb from its
skin tone:

``` r

demo <- data.frame(
  text = c("our family \U0001F468‍\U0001F469‍\U0001F467‍\U0001F466",
           "great work \U0001F44D\U0001F3FD")
)

demo %>%
  emoji_extract_unnest(text)
#> # A tibble: 2 × 3
#>   .row_number .emoji_unicode .emoji_count
#>         <int> <chr>                 <int>
#> 1           1 👨‍👩‍👧‍👦                        1
#> 2           2 👍🏽                        1
```

### What counts, and what does not

The catalogue tidyEmoji detects against is Unicode’s own list of emoji,
for the version
[`emoji_unicode_version()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_unicode_version.md)
reports, bundled with the package. Two kinds of emoji *material* are not
emoji in it, and no verb counts them: a skin-tone swatch with nothing to
modify (the tone after a grinning face, which cannot take one) and
regional indicators that spell no country.
[`emoji_summary()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_summary.md)
counts both, so they are accounted for rather than silently lost:

``` r

odd <- data.frame(text = c("\U0001F600\U0001F3FB",        # face + stray tone
                           "\U0001F1FD\U0001F1FD",        # "XX", no country
                           "\U0001F1EF\U0001F1F5"))       # Japan
emoji_summary(odd, text)
#> # A tibble: 1 × 6
#>   n_with_emoji n_total n_orphan_components n_invalid_flags n_unlisted n_hidden
#>          <int>   <int>               <int>           <int>      <int>    <int>
#> 1            2       3                   1               1          0        0
```

Some emoji are also emoji only when they carry the presentation selector
`U+FE0F`: the bare heart `U+2764` is text, `U+2764 U+FE0F` is an emoji.
Every verb that counts, scores or rewrites emoji takes
`presentation = "any"` to read the bare forms as well (all but the
copyright, registered and trade-mark signs, which are typography far
more often than emoji):

``` r

hearts <- data.frame(text = c("I \u2764 R", "I \u2764\ufe0f R"))
emoji_summary(hearts, text)
#> # A tibble: 1 × 6
#>   n_with_emoji n_total n_orphan_components n_invalid_flags n_unlisted n_hidden
#>          <int>   <int>               <int>           <int>      <int>    <int>
#> 1            1       2                   0               0          0        0
emoji_summary(hearts, text, presentation = "any")
#> # A tibble: 1 × 6
#>   n_with_emoji n_total n_orphan_components n_invalid_flags n_unlisted n_hidden
#>          <int>   <int>               <int>           <int>      <int>    <int>
#> 1            2       2                   0               0          0        0
```

## Counting emoji across the corpus

### `emoji_frequency()`

[`emoji_frequency()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_frequency.md)
counts how often each emoji appears across the whole text column (an
entry containing the same emoji twice contributes 2) and returns the
result sorted by descending count, annotated with each emoji’s name,
shortcode and category.

``` r

oasst_messages %>%
  emoji_frequency(text)
#> # A tibble: 398 × 5
#>    emoji name                            shortcode             group           n
#>    <chr> <chr>                           <chr>                 <chr>       <int>
#>  1 😊    smiling face with smiling eyes  blush                 Smileys & …   230
#>  2 😉    winking face                    wink                  Smileys & …    49
#>  3 😁    beaming face with smiling eyes  grin                  Smileys & …    34
#>  4 😄    grinning face with smiling eyes smile                 Smileys & …    30
#>  5 💰    money bag                       moneybag              Objects        28
#>  6 🤗    smiling face with open hands    hugs                  Smileys & …    28
#>  7 👍    thumbs up                       +1                    People & B…    25
#>  8 🤔    thinking face                   thinking              Smileys & …    23
#>  9 🙂    slightly smiling face           slightly_smiling_face Smileys & …    22
#> 10 😂    face with tears of joy          joy                   Smileys & …    19
#> # ℹ 388 more rows
```

### `top_n_emojis()`

When you only need the leaders,
[`top_n_emojis()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/top_n_emojis.md)
is a convenience wrapper around
[`emoji_frequency()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_frequency.md)
that returns the `n` most frequent emoji (default `n = 20`).

``` r

top_20_emojis <- oasst_messages %>%
  top_n_emojis(text)

top_20_emojis
#> # A tibble: 20 × 4
#>    emoji_name            unicode emoji_category        n
#>    <chr>                 <chr>   <chr>             <int>
#>  1 blush                 😊      Smileys & Emotion   230
#>  2 wink                  😉      Smileys & Emotion    49
#>  3 grin                  😁      Smileys & Emotion    34
#>  4 smile                 😄      Smileys & Emotion    30
#>  5 moneybag              💰      Objects              28
#>  6 hugs                  🤗      Smileys & Emotion    28
#>  7 +1                    👍      People & Body        25
#>  8 thinking              🤔      Smileys & Emotion    23
#>  9 slightly_smiling_face 🙂      Smileys & Emotion    22
#> 10 joy                   😂      Smileys & Emotion    19
#> 11 smiley                😃      Smileys & Emotion    18
#> 12 wave                  👋      People & Body        16
#> 13 black_square_button   🔲      Symbols              14
#> 14 white_square_button   🔳      Symbols              14
#> 15 grinning              😀      Smileys & Emotion    14
#> 16 sweat_smile           😅      Smileys & Emotion    13
#> 17 rocket                🚀      Travel & Places      13
#> 18 cat2                  🐈      Animals & Nature     12
#> 19 clap                  👏      People & Body        12
#> 20 rofl                  🤣      Smileys & Emotion    12
```

Plotting the top 20, coloured by category, gives an immediate sense of
how the community expresses itself:

``` r

top_20_emojis %>%
  mutate(emoji_name = stringr::str_replace_all(emoji_name, "_", " "),
         emoji_name = forcats::fct_reorder(emoji_name, n)) %>%
  ggplot(aes(n, emoji_name, fill = emoji_category)) +
  geom_col() +
  labs(x = "Count",
       y = NULL,
       fill = "Category",
       title = "The 20 most frequent emoji")
```

![Horizontal bar chart of the 20 most frequent emoji in the corpus,
coloured by Unicode
category.](introduction_files/figure-html/unnamed-chunk-14-1.png)

The `unicode` column holds the actual glyph, should you wish to render
the emoji themselves on a plot (this requires a graphics device with an
emoji-capable font). You can also request a different number of emoji:

``` r

oasst_messages %>%
  top_n_emojis(text, n = 10) %>%
  mutate(emoji_name = stringr::str_replace_all(emoji_name, "_", " "),
         emoji_name = forcats::fct_reorder(emoji_name, n)) %>%
  ggplot(aes(n, emoji_name, fill = emoji_category)) +
  geom_col() +
  labs(x = "Count", y = NULL, fill = "Category",
       title = "The 10 most frequent emoji")
```

![Horizontal bar chart of the 10 most frequent emoji in the corpus,
coloured by Unicode
category.](introduction_files/figure-html/unnamed-chunk-15-1.png)

## Categorising emoji

The Unicode standard organises emoji into 10 categories (see
[`?category_unicode_crosswalk`](https://pursuitofdatascience.github.io/tidyEmoji/reference/category_unicode_crosswalk.md)).
[`emoji_categorize()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_categorize.md)
keeps the emoji-bearing rows and adds a `.emoji_category` column listing
the distinct categories present in each row, separated by `|` when a row
spans more than one.

``` r

msg_emoji_category <- oasst_messages %>%
  emoji_categorize(text) %>%
  select(.emoji_category)

msg_emoji_category
#> # A tibble: 750 × 1
#>    .emoji_category                                                            
#>    <chr>                                                                      
#>  1 People & Body                                                              
#>  2 Smileys & Emotion                                                          
#>  3 Smileys & Emotion                                                          
#>  4 Smileys & Emotion                                                          
#>  5 Animals & Nature|People & Body|Smileys & Emotion|Symbols|Travel & Places   
#>  6 Activities|Animals & Nature|Objects|People & Body|Smileys & Emotion|Symbols
#>  7 Animals & Nature|Food & Drink|People & Body|Travel & Places                
#>  8 People & Body                                                              
#>  9 Smileys & Emotion                                                          
#> 10 Smileys & Emotion                                                          
#> # ℹ 740 more rows
```

We can tally the most common category combinations:

``` r

msg_emoji_category %>%
  count(.emoji_category, sort = TRUE) %>%
  filter(n > 20) %>%
  mutate(.emoji_category = forcats::fct_reorder(.emoji_category, n)) %>%
  ggplot(aes(n, .emoji_category)) +
  geom_col() +
  labs(x = "Number of entries", y = NULL,
       title = "Most common emoji category combinations")
```

![Horizontal bar chart of the most common emoji category combinations
that appear in more than 20
entries.](introduction_files/figure-html/unnamed-chunk-17-1.png)

To count the 10 individual categories rather than their combinations,
split the `.emoji_category` strings on `|` with
[`tidyr::separate_longer_delim()`](https://tidyr.tidyverse.org/reference/separate_longer_delim.html):

``` r

msg_emoji_category %>%
  tidyr::separate_longer_delim(.emoji_category, delim = "|") %>%
  count(.emoji_category, sort = TRUE) %>%
  mutate(.emoji_category = forcats::fct_reorder(.emoji_category, n)) %>%
  ggplot(aes(n, .emoji_category)) +
  geom_col() +
  labs(x = "Number of entries", y = NULL,
       title = "Emoji category usage")
```

![Horizontal bar chart of how often each individual Unicode emoji
category is used, dominated by Smileys & Emotion followed by People &
Body.](introduction_files/figure-html/unnamed-chunk-18-1.png)

“Smileys & Emotion” dominates, followed by “People & Body”. Note that an
entry spanning several categories is counted once in each, so these
counts can exceed the number of emoji-bearing entries.

### `emoji_type()`: faces versus everything else

The consumer-behaviour literature repeatedly contrasts *emotional*
(face) emoji with *semantic* (object) emoji and finds that the two have
different effects on engagement.
[`emoji_type()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_type.md)
recodes the Unicode group and subgroup into that smaller functional
vocabulary, and
[`emoji_faceness()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_faceness.md)
reduces it to a single per-entry share:

``` r

oasst_messages %>%
  emoji_type(text) %>%
  count(.emoji_type, sort = TRUE) %>%
  head(5)
#> # A tibble: 5 × 2
#>   .emoji_type     n
#>   <chr>       <int>
#> 1 NA            735
#> 2 face          511
#> 3 gesture        50
#> 4 place          15
#> 5 nature         14

oasst_messages %>%
  emoji_faceness(text) %>%
  summarise(mean_faceness = mean(.emoji_faceness, na.rm = TRUE),
            all_faces = sum(.emoji_faceness == 1, na.rm = TRUE))
#> # A tibble: 1 × 2
#>   mean_faceness all_faces
#>           <dbl>     <int>
#> 1         0.719       511
```

[`as_emoji_type()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/as_emoji_type.md)
is the vector-level version, for typing a glyph you already have in
hand.

## Scoring emoji sentiment

### `emoji_sentiment()`

Emoji are a strong sentiment signal, and
[`emoji_sentiment()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sentiment.md)
surfaces it directly. It adds `.emoji_n` (the number of emoji in the
entry), `.emoji_n_scored` (the number that appear in the lexicon), and
`.emoji_sentiment` (the mean sentiment of the scored emoji, from -1 to
+1). Scores come from the bundled `emoji_sentiment_lexicon` (described
below); entries with no emoji, or whose emoji are not in the lexicon,
receive `NA`.

``` r

msg_sentiment <- oasst_messages %>%
  emoji_sentiment(text)

msg_sentiment %>%
  select(.emoji_n, .emoji_sentiment)
#> # A tibble: 1,485 × 2
#>    .emoji_n .emoji_sentiment
#>       <int>            <dbl>
#>  1        0               NA
#>  2        0               NA
#>  3        0               NA
#>  4        0               NA
#>  5        0               NA
#>  6        0               NA
#>  7        0               NA
#>  8        0               NA
#>  9        0               NA
#> 10        0               NA
#> # ℹ 1,475 more rows
```

### Sentiment distribution

Looking across the entries that contain at least one scored emoji:

``` r

msg_sentiment %>%
  filter(!is.na(.emoji_sentiment)) %>%
  ggplot(aes(.emoji_sentiment)) +
  geom_histogram(binwidth = 0.1) +
  labs(x = "Mean emoji sentiment",
       y = "Number of entries",
       title = "Emoji sentiment skews positive")
```

![Histogram of the mean emoji sentiment per entry, which is concentrated
on the positive side of the
scale.](introduction_files/figure-html/unnamed-chunk-21-1.png)

Emoji sentiment leans strongly positive, as it does in most text and
more so here, where most emoji are an assistant being friendly.

### Sentiment by category

Because
[`emoji_tokens()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_tokens.md)
attaches a sentiment score to every emoji occurrence, we can summarise
average sentiment by category in a couple of lines:

``` r

oasst_messages %>%
  emoji_tokens(text) %>%
  group_by(.emoji_category) %>%
  summarise(mean_sentiment = mean(.emoji_sentiment, na.rm = TRUE),
            n_scored = sum(!is.na(.emoji_sentiment))) %>%
  filter(n_scored > 0) %>%
  mutate(.emoji_category = forcats::fct_reorder(.emoji_category, mean_sentiment)) %>%
  ggplot(aes(mean_sentiment, .emoji_category)) +
  geom_col() +
  labs(x = "Mean sentiment", y = NULL,
       title = "Average emoji sentiment by category")
```

![Horizontal bar chart of the average emoji sentiment within each
Unicode
category.](introduction_files/figure-html/unnamed-chunk-22-1.png)

### The sentiment lexicon

The scores come from `emoji_sentiment_lexicon`, the *Emoji Sentiment
Ranking* of Kralj Novak et al. (2015), computed from around 70,000
tweets annotated in 13 European languages. You can work with it
directly, for instance to find the most positive and most negative
reasonably common emoji:

``` r

emoji_sentiment_lexicon %>%
  filter(occurrences >= 500) %>%
  slice_max(sentiment_score, n = 8) %>%
  select(emoji, unicode_name, occurrences, sentiment_score)
#>   emoji         unicode_name occurrences sentiment_score
#> 1     ❤    HEAVY BLACK HEART        8050       0.7460870
#> 2    💞     REVOLVING HEARTS         687       0.7423581
#> 3    🎉         PARTY POPPER        1125       0.7395556
#> 4    💃               DANCER        1344       0.7358631
#> 5    💙           BLUE HEART         912       0.7324561
#> 6    💖      SPARKLING HEART        1263       0.7133808
#> 7    💛         YELLOW HEART         602       0.7126246
#> 8    😘 FACE THROWING A KISS        3648       0.7017544

emoji_sentiment_lexicon %>%
  filter(occurrences >= 500) %>%
  slice_min(sentiment_score, n = 8) %>%
  select(emoji, unicode_name, occurrences, sentiment_score)
#>   emoji       unicode_name occurrences sentiment_score
#> 1    😒      UNAMUSED FACE        1385     -0.37472924
#> 2    😩         WEARY FACE        1808     -0.36836283
#> 3    🔫             PISTOL         604     -0.19536424
#> 4    😡       POUTING FACE         756     -0.17328042
#> 5    😔       PENSIVE FACE        1205     -0.14605809
#> 6    😞  DISAPPOINTED FACE         532     -0.11842105
#> 7    😭 LOUDLY CRYING FACE        5526     -0.09337676
#> 8    😴      SLEEPING FACE         718     -0.08077994
```

### How much of the corpus can be scored?

A lexicon scores the emoji it was built from and nothing else, so before
reading a sentiment result it is worth knowing how much of the corpus it
covers.
[`emoji_coverage()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_coverage.md)
reports that for every lexicon at once, as a share of the emoji
*occurrences*, as a share of the distinct emoji *types*, and as the
number of emoji-bearing entries left with no score at all:

``` r

coverage <- oasst_messages %>%
  emoji_coverage(text)

coverage %>%
  select(lexicon, occurrence_coverage, type_coverage, n_rows_with_emoji,
         n_rows_unscored)
#> # A tibble: 2 × 5
#>   lexicon    occurrence_coverage type_coverage n_rows_with_emoji n_rows_unscored
#>   <chr>                    <dbl>         <dbl>             <int>           <int>
#> 1 novak2015                0.750         0.613               750             135
#> 2 emotag1200               0.529         0.266               750             194
```

The sentiment lexicon scores 75% of the emoji occurrences here but only
61.3% of the distinct emoji, because a few common glyphs make up most of
the occurrences. And 135 of the 750 entries holding an emoji have no
`.emoji_sentiment` at all. Filtering those out before a comparison drops
a sixth of the emoji-bearing data, and not at random: the unscored
entries are the ones using the rarer glyphs. Report both coverage
figures beside any lexicon-based result.

## Interpretation risk: how much do readers disagree?

The most practically important fact about emoji is that people do not
agree on what they mean. Miller et al. (2016) showed the *same*
rendering to many readers and found they disagreed about whether it was
positive, neutral or negative around a quarter of the time.

That disagreement was already inside the package. The Emoji Sentiment
Ranking keeps the raw `negative`/`neutral`/`positive` annotation counts
behind its collapsed score, which is an empirical interpretation
distribution per glyph.
[`emoji_ambiguity()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_ambiguity.md)
reads it out:

``` r

emoji_ambiguity() %>%
  filter(n_annotations > 500) %>%
  head(5)
#> # A tibble: 5 × 8
#>   emoji key   n_annotations p_neg p_neu p_pos ambiguity  rank
#>   <chr> <chr>         <int> <dbl> <dbl> <dbl>     <dbl> <int>
#> 1 😳    1F633           846 0.327 0.327 0.345      1.10     6
#> 2 💯    1F4AF           637 0.281 0.317 0.402      1.09    16
#> 3 😴    1F634           718 0.422 0.237 0.341      1.07    43
#> 4 😢    1F622           749 0.385 0.224 0.391      1.07    47
#> 5 😱    1F631          1130 0.264 0.282 0.454      1.07    50
```

Because the measure is a property of the glyph, the corpus-level
question – “which of *my* emoji are most likely to be misread?” – is one
call:

``` r

oasst_messages %>%
  emoji_flag_ambiguous(text, top_n = 5)
#> # A tibble: 5 × 6
#>   emoji name                    n n_annotations ambiguity  rank
#>   <chr> <chr>               <int>         <int>     <dbl> <int>
#> 1 ❔    white question mark     1             9      1.10     1
#> 2 🎭    performing arts         1            15      1.10     1
#> 3 😳    flushed face            7           846      1.10     6
#> 4 💣    bomb                    1           131      1.09    10
#> 5 😲    astonished face         4           129      1.09    13
```

The default measure, entropy, treats the three annotation classes as
unordered, so it scores an emoji whose readers split between negative
and positive exactly as it scores one whose readers split between
negative and neutral. The first is the one that causes real
miscommunication. `measure = "polarisation"` respects the order: it is
the expected distance between two readers’ judgements on a -1, 0, 1
scale, the statistic Miller et al. used, and it puts the face with open
mouth and cold sweat at rank 6 of 969 where entropy puts it at rank 156.

``` r

emoji_ambiguity(measure = "polarisation") %>%
  filter(n_annotations > 100) %>%
  head(5)
#> # A tibble: 5 × 8
#>   emoji key   n_annotations p_neg p_neu p_pos ambiguity  rank
#>   <chr> <chr>         <int> <dbl> <dbl> <dbl>     <dbl> <int>
#> 1 😰    1F630           302 0.437 0.146 0.417     0.978     6
#> 2 😞    1F61E           532 0.479 0.160 0.361     0.960    12
#> 3 😡    1F621           756 0.533 0.107 0.360     0.958    16
#> 4 😢    1F622           749 0.385 0.224 0.391     0.950    18
#> 5 😫    1F62B           467 0.486 0.173 0.340     0.949    19
```

[`emoji_risk()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_risk.md)
is the per-entry version, and the pair `.emoji_n` / `.emoji_n_scored`
keeps the coverage honest: an entry whose emoji are absent from the
lexicon is not a low-risk entry, it is an unmeasured one.

``` r

oasst_messages %>%
  emoji_risk(text) %>%
  filter(.emoji_n > 1) %>%
  select(.emoji_n, .emoji_n_scored, .emoji_ambiguity_mean,
         .emoji_n_ambiguous) %>%
  head(5)
#> # A tibble: 5 × 4
#>   .emoji_n .emoji_n_scored .emoji_ambiguity_mean .emoji_n_ambiguous
#>      <int>           <int>                 <dbl>              <int>
#> 1       10               7                 0.934                  2
#> 2        9               7                 0.811                  2
#> 3       14               4                 0.935                  1
#> 4        3               0                NA                      0
#> 5       11              10                 0.885                  5
```

The same counts also put an error bar on the sentiment score itself. A
glyph annotated eight times should not carry the authority of one
annotated eight thousand times, and `emoji_sentiment(se = TRUE)` says
so:

``` r

oasst_messages %>%
  emoji_sentiment(text, se = TRUE) %>%
  filter(!is.na(.emoji_sentiment)) %>%
  select(.emoji_n_scored, .emoji_sentiment, .emoji_sentiment_se) %>%
  head(5)
#> # A tibble: 5 × 3
#>   .emoji_n_scored .emoji_sentiment .emoji_sentiment_se
#>             <int>            <dbl>               <dbl>
#> 1               1            0.522              0.0161
#> 2               1            0.464              0.0171
#> 3               1            0.645              0.0104
#> 4               7            0.323              0.0408
#> 5               7            0.454              0.0601
```

## Scoring emoji emotions

Valence (negative↔︎positive) is only one affective dimension.
[`emoji_emotion()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_emotion.md)
goes further, scoring each entry’s emoji across the eight Plutchik
emotions (anger, anticipation, disgust, fear, joy, sadness, surprise,
trust) using the bundled EmoTag1200 lexicon (Shoeb & de Melo, 2020).
Scores are in `[0, 1]`.

``` r

msg_emotion <- oasst_messages %>%
  emoji_emotion(text)

msg_emotion %>%
  select(.emoji_joy, .emoji_trust, .emoji_anger, .emoji_n)
#> # A tibble: 1,485 × 4
#>    .emoji_joy .emoji_trust .emoji_anger .emoji_n
#>         <dbl>        <dbl>        <dbl>    <int>
#>  1         NA           NA           NA        0
#>  2         NA           NA           NA        0
#>  3         NA           NA           NA        0
#>  4         NA           NA           NA        0
#>  5         NA           NA           NA        0
#>  6         NA           NA           NA        0
#>  7         NA           NA           NA        0
#>  8         NA           NA           NA        0
#>  9         NA           NA           NA        0
#> 10         NA           NA           NA        0
#> # ℹ 1,475 more rows
```

A quick way to read the result is the dominant emotion per entry:

``` r

oasst_messages %>%
  emoji_emotion_label(text) %>%
  count(.emoji_emotion, sort = TRUE)
#> # A tibble: 9 × 2
#>   .emoji_emotion     n
#>   <chr>          <int>
#> 1 NA               929
#> 2 joy              410
#> 3 trust             66
#> 4 anticipation      48
#> 5 fear              12
#> 6 sadness           11
#> 7 surprise           4
#> 8 disgust            3
#> 9 anger              2
```

The emotion scores join through the same codepoint-normalised key as
sentiment, so emoji carrying the `U+FE0F` variation selector resolve
correctly.

## Bringing your own lexicon

Sentiment and emotion scoring share one pluggable engine.
[`emoji_lexicons()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_lexicons.md)
lists the bundled lexicons (plus any you have registered):

``` r

emoji_lexicons()
#> # A tibble: 2 × 6
#>   name       type      dimensions     n source                           licence
#>   <chr>      <chr>     <I<list>>  <int> <chr>                            <chr>  
#> 1 novak2015  sentiment <chr [1]>    969 Kralj Novak et al. (2015), PLoS… CC BY-…
#> 2 emotag1200 emotion   <chr [8]>    150 Shoeb & de Melo (2020), EMNLP 2… MIT
```

[`emoji_score()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_score.md)
is the generic scorer underneath
[`emoji_sentiment()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sentiment.md):
give it any data frame with an emoji column and a score column (say,
scores tailored to your own domain), and it returns the per-row mean,
joined through the same codepoint-normalised key as everything else:

``` r

my_lexicon <- data.frame(
  emoji = c("\U0001f600", "\U0001f621", "\U0001f637"),
  score = c(1, -1, -0.5)
)

data.frame(text = c("great \U0001f600", "bad \U0001f621\U0001f637", "none")) %>%
  emoji_score(text, lexicon = my_lexicon)
#> # A tibble: 3 × 4
#>   text     .emoji_n .emoji_n_scored .emoji_score
#>   <chr>       <int>           <int>        <dbl>
#> 1 great 😀        1               1         1   
#> 2 bad 😡😷        2               2        -0.75
#> 3 none            0              NA        NA
```

[`register_emoji_lexicon()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/register_emoji_lexicon.md)
stores a lexicon under a name for the session, so you can refer to it in
[`emoji_score()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_score.md),
or in
[`emoji_emotion()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_emotion.md)
if it carries emotion columns:

``` r

register_emoji_lexicon("mine", my_lexicon)
emoji_lexicons() %>% filter(name == "mine")
#> # A tibble: 1 × 6
#>   name  type   dimensions     n source          licence
#>   <chr> <chr>  <I<list>>  <int> <chr>           <chr>  
#> 1 mine  custom <chr [1]>      3 user-registered NA
```

## Relating emoji: co-occurrence and sequences

Which emoji appear *together*?
[`emoji_pairs()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_pairs.md)
returns a tidy edge list: one row per pair of distinct emoji that
co-occur in the same entry, with the number of entries in which they do.
The `item1`/`item2`/`n` shape matches `widyr::pairwise_count()` and
feeds directly into graph tools such as igraph, tidygraph and ggraph:

``` r

emoji_edges <- oasst_messages %>%
  emoji_pairs(text)

emoji_edges
#> # A tibble: 4,316 × 3
#>    item1 item2     n
#>    <chr> <chr> <int>
#>  1 🔬    🚀        4
#>  2 ☀️     ⛅        3
#>  3 ☀️     ⛈️         3
#>  4 ☀️     ❄️         3
#>  5 ☀️     🌊        3
#>  6 ☀️     🌤️         3
#>  7 ☀️     🌥️         3
#>  8 ☀️     🌦️         3
#>  9 ☀️     🌧️         3
#> 10 ☀️     🌨️         3
#> # ℹ 4,306 more rows
```

The strongest pairings make a readable chart on their own:

``` r

emoji_edges %>%
  slice_max(n, n = 10) %>%
  mutate(pair = paste(item1, item2),
         pair = forcats::fct_reorder(pair, n)) %>%
  ggplot(aes(n, pair)) +
  geom_col() +
  labs(x = "Number of entries containing both", y = NULL,
       title = "Emoji that appear together")
```

![Horizontal bar chart of the most frequent emoji pairs, labelled by the
two glyphs of each
pair.](introduction_files/figure-html/unnamed-chunk-36-1.png)

Set `directed = TRUE` to order each pair by first appearance, or supply
`doc_id` to pool several rows (a conversation, a user, a day) into one
document. `emoji_cooccurrence(diagonal = TRUE)` additionally returns
each emoji’s document frequency on the diagonal.

Raw counts favour the common emoji, which pair with everything, and most
pairs in a real corpus are seen exactly once. `measure` scores each pair
against what its two emoji’s frequencies predict instead, and
[`vignette("emoji-networks", package = "tidyEmoji")`](https://pursuitofdatascience.github.io/tidyEmoji/articles/emoji-networks.md)
builds a network on it:

``` r

oasst_messages %>%
  emoji_pairs(text, measure = "dice") %>%
  filter(n >= 3) %>%
  head(5)
#> # A tibble: 5 × 4
#>   item1 item2     n  dice
#>   <chr> <chr> <int> <dbl>
#> 1 ⛅    ⛈️         3     1
#> 2 ⛅    ❄️         3     1
#> 3 ⛅    🌤️         3     1
#> 4 ⛅    🌥️         3     1
#> 5 ⛅    🌦️         3     1
```

Order also matters *within* an entry.
[`emoji_ngrams()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_ngrams.md)
slides a window over each entry’s emoji in reading order (any text in
between is ignored), which is the raw material for sequence and
Markov-style analyses:

``` r

oasst_messages %>%
  emoji_ngrams(text) %>%
  count(.emoji_ngram, sort = TRUE)
#> # A tibble: 579 × 2
#>    .emoji_ngram     n
#>    <chr>        <int>
#>  1 💰 💰           15
#>  2 🔲 🔲           10
#>  3 🔳 🔳           10
#>  4 🐑 🐑            8
#>  5 🍎 🍎            7
#>  6 🐈 🐈            7
#>  7 🔹 🔹            7
#>  8 👏 👏            5
#>  9 🐱 👢            4
#> 10 👢 💰            4
#> # ℹ 569 more rows
```

All the relational verbs canonicalise glyphs through the same
codepoint-normalised key as the rest of the package, so qualified and
unqualified forms of one emoji count as a single node.

## The words around an emoji

Which emoji occurred is only half the story: emoji are polysemous, and
their reading is decided by the co-text.
[`emoji_context()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_context.md)
returns one row per occurrence with a window of the surrounding text.
Other emoji are blanked out of the window, so a neighbouring glyph never
leaks into it:

``` r

notes <- data.frame(text = c(
  "so proud of the whole team \U0001F389 see you all on Friday",
  "missed the last train again \U0001F62D\U0001F62D walking home now"
))
notes %>%
  emoji_context(text, window = 4) %>%
  select(.row_number, .emoji, .emoji_context)
#> # A tibble: 3 × 3
#>   .row_number .emoji .emoji_context                       
#>         <int> <chr>  <chr>                                
#> 1           1 🎉     of the whole team see you all on     
#> 2           2 😭     the last train again walking home now
#> 3           2 😭     the last train again walking home now
```

Aggregated over a corpus, those windows give the emoji-word associations
that a sense inventory would otherwise have to supply – derived from
your own data, so they are neither stale nor licence-encumbered:

``` r

oasst_messages %>%
  emoji_collocations(text, window = 4, min_n = 5) %>%
  head(10)
#> # A tibble: 10 × 4
#>    emoji word             n   pmi
#>    <chr> <chr>        <int> <dbl>
#>  1 🐈    котиках          8  5.55
#>  2 🐑    begin{matrix     9  4.90
#>  3 🐑    end{matrix       9  4.90
#>  4 🐑    left             9  4.90
#>  5 🔳    доски            7  4.71
#>  6 🐑    right            9  4.70
#>  7 🍎    manzanas         8  4.57
#>  8 🔹    замените         9  4.25
#>  9 🔲    больше          14  4.23
#> 10 🔹    игрового         8  4.23
```

Tokenisation stops at whitespace on purpose. If you need stemming or
stopword removal, hand the result to `tidytext` rather than expecting
this verb to grow a tokeniser.

## Measuring how emoji are used

*Where* emoji sit and *how much* of the text they occupy are studied
signals in their own right.
[`emoji_position()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_position.md)
reports each entry’s first and last emoji position and the mean relative
position from 0 (start) to 1 (end):

``` r

oasst_messages %>%
  emoji_position(text) %>%
  filter(!is.na(.emoji_rel_position)) %>%
  ggplot(aes(.emoji_rel_position)) +
  geom_histogram(binwidth = 0.05) +
  labs(x = "Mean relative position of the entry's emoji",
       y = "Number of entries",
       title = "Emoji cluster at the end of a message")
```

![Histogram of the mean relative position of emoji within each entry,
showing emoji concentrated towards the end of the
text.](introduction_files/figure-html/unnamed-chunk-41-1.png)

[`emoji_density()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_density.md)
normalises the emoji count by text length (per character and per
whitespace-delimited token), and
[`emoji_ratio()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_ratio.md)
reports what share of the text’s characters belong to emoji, including
an `.emoji_only` flag for entries that are nothing but emoji (and
whitespace):

``` r

oasst_messages %>%
  emoji_ratio(text) %>%
  summarise(
    n_emoji_only = sum(.emoji_only, na.rm = TRUE),
    mean_ratio   = mean(.emoji_ratio[.emoji_ratio > 0], na.rm = TRUE)
  )
#> # A tibble: 1 × 2
#>   n_emoji_only mean_ratio
#>          <int>      <dbl>
#> 1           19     0.0517
```

## Emoji over time

Almost every substantive emoji study is longitudinal, and every message
here carries the time it was written.
[`emoji_trend()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_trend.md)
follows the most used emoji month by month, with the period’s total
beside each count so the share can be recomputed for any grouping:

``` r

oasst_messages %>%
  emoji_trend(text, created_at, by = "month", top_n = 3) %>%
  filter(n_period > 50)
#> # A tibble: 12 × 6
#>    .period    emoji name                               n n_period  share
#>    <date>     <chr> <chr>                          <int>    <int>  <dbl>
#>  1 2023-02-01 😊    smiling face with smiling eyes    40      480 0.0833
#>  2 2023-02-01 😉    winking face                      15      480 0.0312
#>  3 2023-02-01 😁    beaming face with smiling eyes     9      480 0.0188
#>  4 2023-03-01 😊    smiling face with smiling eyes    51      262 0.195 
#>  5 2023-03-01 😉    winking face                      12      262 0.0458
#>  6 2023-03-01 😁    beaming face with smiling eyes     9      262 0.0344
#>  7 2023-04-01 😊    smiling face with smiling eyes    72      422 0.171 
#>  8 2023-04-01 😉    winking face                      17      422 0.0403
#>  9 2023-04-01 😁    beaming face with smiling eyes    10      422 0.0237
#> 10 2023-05-01 😊    smiling face with smiling eyes    25      158 0.158 
#> 11 2023-05-01 😁    beaming face with smiling eyes     2      158 0.0127
#> 12 2023-05-01 😉    winking face                       2      158 0.0127
```

[`emoji_turnover()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_turnover.md)
asks a different question – not how often an emoji is used but how much
of the *repertoire* changes from one period to the next:

``` r

oasst_messages %>%
  emoji_turnover(text, created_at, by = "month")
#> # A tibble: 9 × 8
#>   .period    .period_prev n_types_prev n_types jaccard n_new n_lost n_core
#>   <date>     <date>              <int>   <int>   <dbl> <int>  <int>  <int>
#> 1 2023-02-01 2023-01-01              1     204 0.00490   203      0      1
#> 2 2023-03-01 2023-02-01            204     111 0.230      52    145     59
#> 3 2023-04-01 2023-03-01            111     168 0.187     124     67     44
#> 4 2023-05-01 2023-04-01            168      82 0.208      39    125     43
#> 5 2023-06-01 2023-05-01             82      11 0.0333      8     79      3
#> 6 2023-07-01 2023-06-01             11      14 0.0417     13     10      1
#> 7 2023-08-01 2023-07-01             14       7 0.05        6     13      1
#> 8 2023-09-01 2023-08-01              7      16 0          16      7      0
#> 9 2023-10-01 2023-09-01             16      16 0.0323     15     15      1
```

The sample is stratified on emoji presence, so its monthly totals follow
how many messages OASST2 collected each month, not how often people used
emoji: use the counts to compare emoji with each other within a month,
and read the totals as the sample’s, not the world’s.

Two of the time verbs read their time axis off the reference table,
which already records the Unicode version that introduced each glyph.
[`emoji_version_profile()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_version_profile.md)
needs no timestamp at all as a result, so “how new is this corpus’s
emoji vocabulary?” is a single call:

``` r

oasst_messages %>%
  emoji_version_profile(text) %>%
  head(8)
#> # A tibble: 8 × 7
#>   version version_num release_date n_types n_tokens share_types share_tokens
#>   <chr>         <dbl> <date>         <int>    <int>       <dbl>        <dbl>
#> 1 0.6             0.6 2010-10-11       215      982      0.540       0.675  
#> 2 0.7             0.7 2014-06-16        24       64      0.0603      0.0440 
#> 3 1.0             1   2015-06-09        67      238      0.168       0.164  
#> 4 2.0             2   2015-11-12        12       14      0.0302      0.00963
#> 5 3.0             3   2016-06-21        20       41      0.0503      0.0282 
#> 6 4.0             4   2016-11-22        13       23      0.0327      0.0158 
#> 7 5.0             5   2017-06-20        22       53      0.0553      0.0365 
#> 8 11.0           11   2018-06-05         9       15      0.0226      0.0103
```

With real timestamps,
[`emoji_adoption_lag()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_adoption_lag.md)
goes one step further and compares each glyph’s first appearance in the
corpus with its Unicode release date – see
[`emoji_unicode_releases()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_unicode_releases.md)
for that lookup, and
[`emoji_seasonality()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_seasonality.md)
for month-of-year, day-of-week and hour-of-day cycles:

``` r

oasst_messages %>%
  emoji_adoption_lag(text, created_at) %>%
  arrange(lag_days) %>%
  head(5)
#> # A tibble: 5 × 7
#>   emoji name                          n version release_date first_seen lag_days
#>   <chr> <chr>                     <int> <chr>   <date>       <date>        <int>
#> 1 🫥    dotted line face              4 14.0    2021-09-14   2023-02-08      512
#> 2 🫄🏾    pregnant person: medium-…     2 14.0    2021-09-14   2023-02-12      516
#> 3 🫣    face with peeking eye         1 14.0    2021-09-14   2023-04-16      579
#> 4 🫡    saluting face                 3 14.0    2021-09-14   2023-04-17      580
#> 5 🥷    ninja                         3 13.0    2020-03-10   2023-02-04     1061
```

## Emoji as model features

For classification and regression work,
[`emoji_dfm()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_dfm.md)
turns the corpus into a document-by-emoji feature table: one row per
entry (or per `doc_id`), one column per emoji, weighted by counts,
binary presence or tf-idf. Every entry is kept (emoji-free rows are all
zeros), so the table binds row-for-row to your outcome columns:

``` r

oasst_messages %>%
  emoji_dfm(text, weighting = "tfidf") %>%
  select(1:6)
#> # A tibble: 1,485 × 6
#>    .row_number  `😊`  `😉`  `😁`  `😄`  `💰`
#>          <int> <dbl> <dbl> <dbl> <dbl> <dbl>
#>  1           1     0     0     0     0     0
#>  2           2     0     0     0     0     0
#>  3           3     0     0     0     0     0
#>  4           4     0     0     0     0     0
#>  5           5     0     0     0     0     0
#>  6           6     0     0     0     0     0
#>  7           7     0     0     0     0     0
#>  8           8     0     0     0     0     0
#>  9           9     0     0     0     0     0
#> 10          10     0     0     0     0     0
#> # ℹ 1,475 more rows
```

## Text-emoji mismatch

Two separate literatures converge on one statistic. NLP sarcasm
detection uses emoji-text sentiment incongruity as a feature; marketing
research finds that a mismatch between a review’s words and its emoji
lowers perceived helpfulness and authenticity. Both want the same
number.

tidyEmoji deliberately does not score text – that choice belongs in your
script, where the method is visible. Here is a deliberately crude
word-list scorer standing in for `tidytext` + AFINN, `sentimentr` or a
transformer:

``` r

positive <- c("love", "great", "best", "happy", "good", "thanks", "beautiful")
negative <- c("hate", "worst", "bad", "sad", "awful", "sick", "tired")

scored <- oasst_messages %>%
  mutate(text_score = vapply(
    strsplit(tolower(text), "[^a-z]+"),
    function(w) as.numeric(sum(w %in% positive) - sum(w %in% negative)),
    numeric(1)
  ))
```

`scale` has no default: AFINN runs -5 to 5, VADER -1 to 1, and a model’s
logits on nothing in particular, so you have to say how the two sides
were made comparable. `"rank"` puts both on percentiles and is the
safest choice.

The word list above keeps this vignette runnable on the package’s own
dependencies, but it is not what you would use. Here is the same step
with a real scorer, left unevaluated so that nothing here depends on it.
Both produce a `text_score` column, and
[`emoji_incongruity()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_incongruity.md)
does not care which:

``` r

# tidytext + AFINN: one score per matched word, summed per document
library(tidytext)
library(dplyr)

afinn <- tidytext::get_sentiments("afinn")     # prompts to download once

scored <- oasst_messages %>%
  mutate(.doc = row_number()) %>%
  tidytext::unnest_tokens(word, text, drop = FALSE) %>%
  inner_join(afinn, by = "word") %>%
  group_by(.doc) %>%
  summarise(text_score = sum(value), .groups = "drop") %>%
  right_join(mutate(oasst_messages, .doc = row_number()), by = ".doc") %>%
  mutate(text_score = tidyr::replace_na(text_score, 0))

# sentimentr, which scores sentences and handles negation and amplifiers
scored <- oasst_messages %>%
  mutate(text_score = sentimentr::sentiment_by(text)$ave_sentiment)
```

Two R packages take the opposite design, and both are complements rather
than alternatives. **EmojiSentR** (Hanson, Lahrim and Tong, 2026) scores
text and emoji together: it extracts the emoji, scores the words and the
emoji separately, applies VADER’s negation rules and returns one
weighted composite per document. That composite is a finished answer,
where tidyEmoji keeps the two channels apart precisely so their
*disagreement* can be measured: feed EmojiSentR’s word-channel score in
as `text_score` and the two packages compose. **text2emotion** runs the
other way round entirely: it classifies the emotion of the *words* with
a trained model and maps the prediction onto an emoji for display, so it
adds emoji to text rather than reading the emoji already there.

Either way, pass `scale = "rank"` unless you can say why the two scales
are already comparable.

The percentiles are taken over the rows the comparison is defined on –
those with both a scorable emoji and a text score – not over the whole
corpus. Only 615 of these 1485 messages qualify, and ranking the text
score against all 1485 would compare a percentile of one population with
a percentile of another. One consequence is a useful sanity check: on
the rank scale the mean gap over the scored rows is exactly zero, so a
non-zero mean means your filtering, not your data.

``` r

incong <- scored %>%
  emoji_incongruity(text, text_score, scale = "rank")

incong %>%
  filter(!is.na(.emoji_incongruity)) %>%
  count(.emoji_polarity_flip)
#> # A tibble: 2 × 2
#>   .emoji_polarity_flip     n
#>   <lgl>                <int>
#> 1 FALSE                  610
#> 2 TRUE                     5

incong %>%
  filter(.emoji_polarity_flip) %>%
  select(.emoji_sentiment, text_score) %>%
  head(3)
#> # A tibble: 3 × 2
#>   .emoji_sentiment text_score
#>              <dbl>      <dbl>
#> 1           0.645          -1
#> 2           0.268          -1
#> 3          -0.0934          1
```

Note what happens to entries with no scorable emoji: they get `NA`,
never `0`. A neutral emoji and no emoji at all are different states, and
collapsing them biases every model downstream.
[`emoji_incongruity_profile()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_incongruity_profile.md)
aggregates the same numbers by glyph, and
[`emoji_congruence()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_congruence.md)
is the identical engine under the marketing framing.

``` r

scored %>%
  emoji_incongruity_profile(text, text_score, scale = "rank", min_n = 10)
#> # A tibble: 18 × 7
#>    emoji name                n mean_incongruity sd_incongruity n_flips flip_rate
#>    <chr> <chr>           <int>            <dbl>          <dbl>   <int>     <dbl>
#>  1 😊    smiling face w…   230           0.521          0.343        2   0.00870
#>  2 😉    winking face       49          -0.278          0.304        0   0      
#>  3 😁    beaming face w…    34          -0.398          0.249        0   0      
#>  4 😄    grinning face …    30          -0.484          0.308        0   0      
#>  5 💰    money bag          28          -0.498          0.129        0   0      
#>  6 👍    thumbs up          25          -0.161          0.505        0   0      
#>  7 😂    face with tear…    19          -0.722          0.187        0   0      
#>  8 😃    grinning face …    18           0.0116         0.354        0   0      
#>  9 👋    waving hand        16          -0.451          0.271        0   0      
#> 10 🔲    black square b…    14          -0.205          0            0   0      
#> 11 🔳    white square b…    14          -0.205          0            0   0      
#> 12 😀    grinning face      14          -0.0355         0.440        0   0      
#> 13 😅    grinning face …    13          -0.840          0.280        0   0      
#> 14 🚀    rocket             13           0.156          0.658        0   0      
#> 15 🐈    cat                12          -0.510          0.212        0   0      
#> 16 👏    clapping hands     12          -0.0501         0.322        0   0      
#> 17 🔥    fire               11          -0.571          0.0878       0   0      
#> 18 🐑    ewe                10          -0.920          0            0   0
```

## Translating emoji to and from text

Replacing emoji with words is useful for accessibility (screen readers)
and as an NLP normalisation step before tokenising.
[`emoji_to_text()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_to_text.md)
does this for a whole column, in either Unicode-name or shortcode form;
[`text_to_emoji()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/text_to_emoji.md)
is the inverse.

``` r

demo <- data.frame(text = "great \U0001f600 love \u2764\ufe0f")
demo %>% emoji_to_text(text, format = "name")
#> # A tibble: 1 × 1
#>   text                              
#>   <chr>                             
#> 1 great grinning face love red heart
demo %>% emoji_to_text(text, format = "shortcode")
#> # A tibble: 1 × 1
#>   text                         
#>   <chr>                        
#> 1 great :grinning: love :heart:
demo %>%
  emoji_to_text(text, format = "shortcode") %>%
  text_to_emoji(text)
#> # A tibble: 1 × 1
#>   text           
#>   <chr>          
#> 1 great 😀 love ❤️
```

Note that the qualified heart (which carries the `U+FE0F` variation
selector) translates just as reliably as any other emoji, thanks to the
normalised join key. For ad-hoc, vector-level use there are also
[`as_emoji_name()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/as_emoji_name.md),
[`as_emoji_shortcode()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/as_emoji_name.md)
and
[`as_emoji()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/as_emoji_name.md):

``` r

as_emoji_name(c("\U0001f600", "\u2764\ufe0f"))
#> [1] "grinning face" "red heart"
as_emoji_shortcode(c("\U0001f600", "\u2764\ufe0f"))
#> [1] "grinning" "heart"
as_emoji(c("grinning", "heart"))
#> [1] "😀" "❤️"
```

## Searching the emoji catalogue

[`emoji_search()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_search.md)
looks emoji up by keyword, name or shortcode (case-insensitive, literal
matching), returning a tidy tibble you can filter further or feed into
the other verbs:

``` r

emoji_search("happy")
#> # A tibble: 55 × 5
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
#> 10 ☺️     smiling face                    relaxed               Smileys … happy  
#> # ℹ 45 more rows
emoji_search("celebration")
#> # A tibble: 49 × 5
#>    emoji name                                  shortcode           group keyword
#>    <chr> <chr>                                 <chr>               <chr> <chr>  
#>  1 🥳    partying face                         partying_face       Smil… celebr…
#>  2 🙌    raising hands                         raised_hands        Peop… celebr…
#>  3 🙌🏻    raising hands: light skin tone        raising_hands_ligh… Peop… celebr…
#>  4 🙌🏼    raising hands: medium-light skin tone raising_hands_medi… Peop… celebr…
#>  5 🙌🏽    raising hands: medium skin tone       raising_hands_medi… Peop… celebr…
#>  6 🙌🏾    raising hands: medium-dark skin tone  raising_hands_medi… Peop… celebr…
#>  7 🙌🏿    raising hands: dark skin tone         raising_hands_dark… Peop… celebr…
#>  8 🎅    Santa Claus                           santa               Peop… celebr…
#>  9 🎅🏻    Santa Claus: light skin tone          Santa_Claus_light_… Peop… celebr…
#> 10 🎅🏼    Santa Claus: medium-light skin tone   Santa_Claus_medium… Peop… celebr…
#> # ℹ 39 more rows
```

[`emoji_find()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_find.md)
goes the other way, from a semantic field to its emoji, which is how a
stimulus set is assembled; it matches whole CLDR keywords, and
[`emoji_keywords()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_keywords.md)
returns those keywords in long form:

``` r

emoji_find(c("party", "celebration"))
#> # A tibble: 131 × 5
#>    emoji name                           group             matched      n_matched
#>    <chr> <chr>                          <chr>             <chr>            <int>
#>  1 🥳    partying face                  Smileys & Emotion party, cele…         2
#>  2 🎂    birthday cake                  Food & Drink      party, cele…         2
#>  3 🎈    balloon                        Activities        party, cele…         2
#>  4 🎉    party popper                   Activities        party, cele…         2
#>  5 🎊    confetti ball                  Activities        party, cele…         2
#>  6 🪅    piñata                         Activities        party, cele…         2
#>  7 😛    face with tongue               Smileys & Emotion party                1
#>  8 😜    winking face with tongue       Smileys & Emotion party                1
#>  9 🙌    raising hands                  People & Body     celebration          1
#> 10 🙌🏻    raising hands: light skin tone People & Body     celebration          1
#> # ℹ 121 more rows
emoji_keywords("\U0001F389")
#> # A tibble: 10 × 4
#>    emoji name         keyword     source
#>    <chr> <chr>        <chr>       <chr> 
#>  1 🎉    party popper awesome     github
#>  2 🎉    party popper birthday    github
#>  3 🎉    party popper celebrate   github
#>  4 🎉    party popper celebration github
#>  5 🎉    party popper excited     github
#>  6 🎉    party popper hooray      github
#>  7 🎉    party popper party       github
#>  8 🎉    party popper popper      github
#>  9 🎉    party popper tada        github
#> 10 🎉    party popper woohoo      github
```

The keywords are the English CLDR sets, from the `emoji` package, so an
emoji newer than that package has a name but no keywords.

## What the catalogue knows about a glyph

[`emoji_properties()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_properties.md)
reports everything the catalogue records about a glyph: its code points,
its qualification status, its name, group and subgroup, the Unicode
version that introduced it, and whether it takes a skin tone. Called
with no argument it returns the whole catalogue:

``` r

emoji_properties(c("\u2764", "\u2764\ufe0f", "\U0001F44D\U0001F3FD"))
#> # A tibble: 3 × 11
#>   emoji codepoints      n_codepoints key     name  status group subgroup version
#>   <chr> <chr>                  <int> <chr>   <chr> <chr>  <chr> <chr>    <chr>  
#> 1 ❤     U+2764                     1 2764    red … unqua… Smil… heart    0.6    
#> 2 ❤️     U+2764 U+FE0F              2 2764    red … fully… Smil… heart    0.6    
#> 3 👍🏽    U+1F44D U+1F3FD            2 1F44D … thum… fully… Peop… hand-fi… 1.0    
#> # ℹ 2 more variables: modifiable <lgl>, has_fe0f <lgl>
```

Two spellings of one emoji differ only in `U+FE0F`, which makes a plain
join on the glyph miss rows.
[`as_emoji_canonical()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/as_emoji_canonical.md)
maps every spelling to the one the catalogue marks fully qualified, and
[`emoji_identical()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_identical.md)
says whether two glyphs are the same emoji, and how they differ when
they are not:

``` r

as_emoji_canonical(c("\u2764", "\u2764\ufe0f"))
#> [1] "❤️" "❤️"
emoji_identical(c("\u2764", "\U0001F44D"),
                c("\u2764\ufe0f", "\U0001F44D\U0001F3FD"),
                details = TRUE)
#> # A tibble: 2 × 7
#>   x     y     identical exact difference         x_codepoints y_codepoints   
#>   <chr> <chr> <lgl>     <lgl> <chr>              <chr>        <chr>          
#> 1 ❤     ❤️     TRUE      FALSE variation selector U+2764       U+2764 U+FE0F  
#> 2 👍    👍🏽    FALSE     FALSE skin tone          U+1F44D      U+1F44D U+1F3FD
```

[`emoji_identical()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_identical.md)
compares code points. It cannot say what anyone saw, because rendering
belongs to the font and the platform; its help page says so in full, and
anyone using it as evidence should read it.

## Flags and places

A flag emoji is two regional-indicator letters, so the country code is
arithmetic, and the catalogue’s 259 country flags say which pairs are
real.
[`emoji_country()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_country.md)
returns one row per flag with its ISO 3166-1 code, ready to join to a
map or to `countrycode::countrycode()`:

``` r

places <- data.frame(
  id = 1:2,
  text = c("Tokyo \U0001F1EF\U0001F1F5 then Paris \U0001F1EB\U0001F1F7",
           "stray \U0001F1FD\U0001F1FD letters"))
emoji_country(places, text)
#> # A tibble: 3 × 6
#>      id text               .emoji .emoji_iso2 .emoji_country_name .emoji_iso3166
#>   <int> <chr>              <chr>  <chr>       <chr>               <lgl>         
#> 1     1 Tokyo 🇯🇵 then Pari… 🇯🇵     JP          Japan               TRUE          
#> 2     1 Tokyo 🇯🇵 then Pari… 🇫🇷     FR          France              TRUE          
#> 3     2 stray 🇽🇽 letters   🇽🇽     NA          NA                  NA
emoji_flag(c("JP", "fr", "GB-SCT"))
#> [1] "🇯🇵" "🇫🇷" "🏴󠁧󠁢󠁳󠁣󠁴󠁿"
```

A pair that spells no country keeps its row and its glyph, with `NA` for
the code.
[`emoji_subdivision()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_subdivision.md)
does the same for the tag-sequence flags of England, Scotland and Wales.

## Reaction data and other tallies

Reactions arrive as counts, not text: one row per item, emoji and number
of presses.
[`emoji_from_counts()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_from_counts.md)
writes each item’s tally out as text, so every verb above reads it. It
understands GitHub’s reaction names as well as glyphs and shortcodes:

``` r

reactions <- data.frame(pr = c(101, 101, 102),
                        reaction = c("+1", "rocket", "-1"),
                        count = c(3, 1, 2))
reaction_text <- emoji_from_counts(reactions, reaction, count, id = pr)
reaction_text
#> # A tibble: 2 × 2
#>      pr text       
#>   <dbl> <chr>      
#> 1   101 👍 👍 👍 🚀
#> 2   102 👎 👎
emoji_sentiment(reaction_text, text)
#> # A tibble: 2 × 5
#>      pr text        .emoji_n .emoji_n_scored .emoji_sentiment
#>   <dbl> <chr>          <int>           <int>            <dbl>
#> 1   101 👍 👍 👍 🚀        4               4            0.523
#> 2   102 👎 👎              2               2           -0.190
```

Real tally data is messier. OASST2 records reactions on its messages,
and `oasst_reactions` holds them for the sample. Beside the two votes
(`"+1"` and `"-1"`) sit a report button (`"red_flag"`) and the
interface’s skip actions, none of which is an emoji. By default a value
that resolves to no emoji is an error, because dropping it silently
would change the answer; `unknown = "drop"` sets such rows aside and
says which, with the counts they carried:

``` r

oasst_reactions %>%
  emoji_from_counts(reaction, n, id = message_id, unknown = "drop") %>%
  emoji_frequency(text)
#> # A tibble: 2 × 5
#>   emoji name        shortcode group             n
#>   <chr> <chr>       <chr>     <chr>         <int>
#> 1 👍    thumbs up   +1        People & Body  2323
#> 2 👎    thumbs down -1        People & Body   802
```

The text is built so that every counting verb gives exactly the answer
the tally implies. What it cannot do is say more than the tally does: a
platform offering eight reactions records which of eight buttons was
pressed, not what the reader felt.

## Emoji in language-model pipelines

Emoji are now a preprocessing decision in every LLM pipeline, and the
decision matters: they inflate token counts several-fold, and models
disambiguate them poorly.
[`emoji_token_cost()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_token_cost.md)
gives the exact sizes plus a clearly-labelled estimate – pass your real
tokeniser through `tokenizer` when the number matters:

``` r

oasst_messages %>%
  emoji_token_cost(text) %>%
  filter(.emoji_n > 0) %>%
  summarise(emoji = sum(.emoji_n),
            bytes = sum(.emoji_bytes),
            codepoints = sum(.emoji_codepoints),
            est_tokens = sum(.emoji_token_estimate))
#> # A tibble: 1 × 4
#>   emoji bytes codepoints est_tokens
#>   <int> <int>      <int>      <int>
#> 1  1454  6551       1706       3300
```

[`emoji_sanitize()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sanitize.md)
then applies one *named* policy to the column. The capability is not new
– most of it exists across
[`emoji_to_text()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_to_text.md)
and the extraction verbs – but the named argument shows up in a script
diff and in a methods section, which is the point:

``` r

demo_llm <- data.frame(text = "ship it \U0001f680 today")
for (p in c("keep", "strip", "name", "shortcode", "placeholder")) {
  cat(format(p, width = 12), emoji_sanitize(demo_llm, text, policy = p)$text,
      "\n")
}
#> keep         ship it 🚀 today 
#> strip        ship it today 
#> name         ship it rocket today 
#> shortcode    ship it :rocket: today 
#> placeholder  ship it [emoji] today
```

Those five policies are not interchangeable: they lose different amounts
of information, and only one of them can be undone after the model call.
[`vignette("reversible-preprocessing", package = "tidyEmoji")`](https://pursuitofdatascience.github.io/tidyEmoji/articles/reversible-preprocessing.md)
works through that round trip on the cases that break a hand-rolled
substitution, and shows how to keep the emoji signal as feature columns
while the text you send holds no emoji at all.

### Auditing the emoji a model writes

The same verbs work on emoji a model *produces*. A transcript of model
output is a text column, so “how much emoji does this assistant use,
where, and of what kind?” needs nothing new:
[`emoji_ratio()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_ratio.md)
finds the replies that are nothing but emoji,
[`emoji_position()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_position.md)
whether the emoji close a reply,
[`emoji_type()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_type.md)
the faces against the objects, and
[`emoji_trend()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_trend.md)
over a model-version column whether an update changed the register. Work
on around a million chatbot conversations treats exactly this, the emoji
in the model’s turns, as part of how the model positions itself towards
the user.

``` r

replies <- data.frame(
  model = c("v1", "v1", "v2", "v2"),
  reply = c("Sure, here is the summary.",
            "Done \U0001F44D",
            "Great question! \U0001F60A Here you go \U0001F680",
            "\U0001F389\U0001F389")
)
replies %>%
  emoji_ratio(reply) %>%
  group_by(model) %>%
  summarise(replies = n(), with_emoji = sum(.emoji_n > 0),
            emoji_only = sum(.emoji_only, na.rm = TRUE),
            emoji = sum(.emoji_n), codepoints = sum(.emoji_codepoints))
#> # A tibble: 2 × 6
#>   model replies with_emoji emoji_only emoji codepoints
#>   <chr>   <int>      <int>      <int> <int>      <int>
#> 1 v1          2          1          0     1          1
#> 2 v2          2          2          1     4          4
```

### Real model output: deduplicate before you count

WildChat-1M (Zhao et al. 2024) logs a million real conversations with
GPT-3.5 and GPT-4 from April 2023 on. Its licence, ODC-BY 1.0, covers
the database and not the text of each conversation, so it is not
bundled; the chunk below fetches one of its fourteen shards, about 200
MB, and is not run here. The figures after it were measured on that
shard.

``` r

# install.packages("arrow")
url <- paste0("https://huggingface.co/datasets/allenai/WildChat-1M/",
              "resolve/main/data/train-00000-of-00014.parquet")
f <- tempfile(fileext = ".parquet")
download.file(url, f, mode = "wb")
shard <- arrow::read_parquet(f, col_select = c("conversation_hash", "model",
                                                "conversation"))
turns <- tidyr::unnest(shard, conversation)   # one row per turn
assistant <- turns %>% filter(role == "assistant")

# counted as they come, the top two are a lock and an unlock ...
emoji_frequency(assistant, content) %>% head(3)
# ... because a jailbreak template asks for them; deduplicate by
# conversation and set the template's echoes aside first
assistant %>%
  distinct(conversation_hash, content, .keep_all = TRUE) %>%
  filter(!grepl("Developer Mode", content, fixed = TRUE)) %>%
  emoji_frequency(content) %>%
  head(3)
```

On that shard emoji appear in 0.96% of assistant turns against 0.44% of
user turns, and in 1.05% of `gpt-4-0314`’s against 0.93% of
`gpt-3.5-turbo-0301`’s. Counted naively, the two most frequent emoji in
the assistant turns are the unlocked padlock (474) and the locked one
(371), and 200 of the 592 turns holding the unlocked padlock carry the
“Developer Mode” jailbreak template’s tags. A frequency table of model
output surfaces prompt templates before it surfaces style, which is the
first thing to know about auditing it: deduplicate by
`conversation_hash` and by template, then count.

## Recording provenance

“Emoji” is not a fixed object. Which glyphs exist, what they are called
and which lexicon scored them all depend on versions, and a result is
not reproducible without them.
[`emoji_provenance()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_provenance.md)
puts the lot in one row you can paste into a methods section:

``` r

emoji_provenance() %>% glimpse()
#> Rows: 1
#> Columns: 10
#> $ tidyEmoji          <chr> "0.7.0"
#> $ emoji_pkg          <chr> "16.0.0"
#> $ unicode_emoji      <chr> "18.0"
#> $ unicode_emoji_date <date> 2026-04-30
#> $ n_emoji            <int> 5244
#> $ sentiment_lexicon  <chr> "novak2015 (969 emoji)"
#> $ emotion_lexicon    <chr> "emotag1200 (150 emoji)"
#> $ R                  <chr> "4.6.2"
#> $ cldr               <chr> "49.0.0"
#> $ emojibase          <chr> "18.0.0"
```

## Bundled datasets

tidyEmoji ships six datasets, each documented with its own help page:

- **`oasst_messages`** and **`oasst_reactions`**: the example corpus
  used throughout this vignette, 1,485 messages from OpenAssistant
  Conversations with their dates, roles and languages, and the reaction
  tallies on them (see
  [`?oasst_messages`](https://pursuitofdatascience.github.io/tidyEmoji/reference/oasst_messages.md)).
- **`emoji_sentiment_lexicon`**: emoji sentiment scores from the Emoji
  Sentiment Ranking (see
  [`?emoji_sentiment_lexicon`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sentiment_lexicon.md)).
- **`emoji_emotion_lexicon`**: emoji emotion scores from EmoTag1200 (see
  [`?emoji_emotion_lexicon`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_emotion_lexicon.md)).
- **`emoji_unicode_crosswalk`**: one row per (name, glyph) pair, mapping
  names / shortcodes to glyphs and categories. The mapping is
  many-to-many both ways, so join on `key` rather than `emoji_name`
  unless you want the duplicates (see
  [`?emoji_unicode_crosswalk`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_unicode_crosswalk.md)).
- **`category_unicode_crosswalk`**: one row per Unicode category,
  listing its emoji.

The emoji catalogue itself is internal and is surfaced by
[`emoji_properties()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_properties.md).
It and the two crosswalks are rebuilt from Unicode’s `emoji-test.txt`
(with the shortcodes taken from the `emoji` package), and the two
lexicons from their published sources, by the scripts in the `data-raw/`
directory of the package’s source repository, as is the example corpus
from OASST2. That directory is not part of the installed package.

## References

Köpf A, Kilcher Y, von Rütte D, Anagnostidis S, Tam ZR, Stevens K, et
al. (2023). OpenAssistant Conversations: Democratizing Large Language
Model Alignment. *NeurIPS 2023 Datasets and Benchmarks*.
<https://arxiv.org/abs/2304.07327>. The source of `oasst_messages` and
`oasst_reactions`, distributed under the Apache License 2.0.

Kralj Novak P, Smailović J, Sluban B, Mozetič I (2015). Sentiment of
Emojis. *PLoS ONE* 10(12): e0144296.
<https://doi.org/10.1371/journal.pone.0144296>. The Emoji Sentiment
Ranking is distributed under the Creative Commons Attribution-ShareAlike
4.0 International (CC BY-SA 4.0) licence.

Hanson L, Lahrim E, Tong X (2026). EmojiSentR: An R Package for
Integrated Text and Emoji Sentiment Analysis. *Journal of Behavioral
Data Science* 6(1). <https://doi.org/10.35566/jbds/tonghl>.

Miller H, Thebault-Spieker J, Chang S, Johnson I, Terveen L, Hecht B
(2016). “Blissfully Happy” or “Ready to Fight”: Varying Interpretations
of Emoji. *ICWSM 2016*. The source of the disagreement result behind
[`emoji_ambiguity()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_ambiguity.md),
and of the polarisation measure.

Shoeb AAM, de Melo G (2020). EmoTag1200: Understanding the Association
between Emojis and Emotions. *EMNLP 2020*.
<https://aclanthology.org/2020.emnlp-main.720/>. The EmoTag1200 data is
distributed under the MIT licence.

Zhao W, Ren X, Hessel J, Cardie C, Choi Y, Deng Y (2024). WildChat: 1M
ChatGPT Interaction Logs in the Wild. *ICLR 2024*.
<https://huggingface.co/datasets/allenai/WildChat-1M>, distributed under
ODC-BY 1.0.
