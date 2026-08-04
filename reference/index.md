# Package index

## Detect & summarise

- [`emoji_summary()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_summary.md)
  : Summarise emoji presence in a text column
- [`emoji_filter()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_filter.md)
  [`emoji_tweets()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_filter.md)
  : Keep only the rows whose text contains emoji

## Count

- [`emoji_frequency()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_frequency.md)
  : Frequency of every emoji in a text column
- [`top_n_emojis()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/top_n_emojis.md)
  : The most frequent emoji in a text column

## Extract

- [`emoji_extract_nest()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_extract_nest.md)
  : Add a list-column of the emoji found in each row
- [`emoji_extract_unnest()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_extract_unnest.md)
  : Emoji counts per row, in long (tidy) form
- [`emoji_tokens()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_tokens.md)
  : Tidy emoji tokens, one row per occurrence with metadata

## Categorise & score

- [`emoji_categorize()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_categorize.md)
  : Categorise each row by the emoji categories it contains
- [`emoji_type()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_type.md)
  : Which functional types of emoji does each row use?
- [`as_emoji_type()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/as_emoji_type.md)
  : Functional type of an emoji glyph
- [`emoji_faceness()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_faceness.md)
  : How face-heavy is each row's emoji use?
- [`emoji_sentiment()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sentiment.md)
  : Score the sentiment of the emoji in each row
- [`emoji_emotion()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_emotion.md)
  : Emoji emotion profiles (the 8 Plutchik emotions)
- [`emoji_emotion_label()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_emotion_label.md)
  : The dominant emoji emotion per row

## Interpretation risk

- [`emoji_ambiguity()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_ambiguity.md)
  : How ambiguous is each emoji?
- [`emoji_risk()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_risk.md)
  : Interpretation risk per row
- [`emoji_flag_ambiguous()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_flag_ambiguous.md)
  : Which emoji in this corpus are most likely to be misread?

## Lexicon API

- [`emoji_lexicons()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_lexicons.md)
  : List bundled emoji lexicons
- [`register_emoji_lexicon()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/register_emoji_lexicon.md)
  : Register a custom emoji lexicon
- [`emoji_score()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_score.md)
  : Score emoji in a text column against any lexicon

## Context

- [`emoji_context()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_context.md)
  : The text around each emoji occurrence
- [`emoji_collocations()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_collocations.md)
  : Which words keep company with which emoji

## Relate

- [`emoji_pairs()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_pairs.md)
  : Co-occurring emoji pairs
- [`emoji_cooccurrence()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_cooccurrence.md)
  : Emoji co-occurrence counts, with an optional diagonal
- [`emoji_ngrams()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_ngrams.md)
  : Consecutive emoji sequences (n-grams)

## Measure

- [`emoji_position()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_position.md)
  : Where do emoji sit within each text?
- [`emoji_density()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_density.md)
  : Emoji density per character and per token
- [`emoji_ratio()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_ratio.md)
  : What share of the text is emoji, and is it emoji-only?

## Text-emoji mismatch

- [`emoji_incongruity()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_incongruity.md)
  : Text-emoji sentiment mismatch
- [`emoji_congruence()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_congruence.md)
  : Text-emoji congruence
- [`emoji_incongruity_profile()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_incongruity_profile.md)
  : Which emoji go against the grain of their text?

## Time

- [`emoji_trend()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_trend.md)
  : Emoji frequency over time
- [`emoji_turnover()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_turnover.md)
  : Emoji vocabulary churn between consecutive periods
- [`emoji_seasonality()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_seasonality.md)
  : Cyclical patterns in emoji use
- [`emoji_version_profile()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_version_profile.md)
  : How new is this corpus's emoji repertoire?
- [`emoji_adoption_lag()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_adoption_lag.md)
  : How long did this population take to adopt each emoji?

## Model features

- [`emoji_dfm()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_dfm.md)
  : Document-by-emoji feature matrix

## Language-model pipelines

- [`emoji_sanitize()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sanitize.md)
  : Apply an explicit emoji policy to a text column
- [`emoji_token_cost()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_token_cost.md)
  : What are the emoji in this text costing a tokeniser?

## Translate & search

- [`emoji_to_text()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_to_text.md)
  : Replace emoji in a text column with words (demojize)
- [`text_to_emoji()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/text_to_emoji.md)
  : Replace shortcodes with emoji (emojize)
- [`as_emoji_name()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/as_emoji_name.md)
  [`as_emoji_shortcode()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/as_emoji_name.md)
  [`as_emoji()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/as_emoji_name.md)
  : Vector helpers: convert emoji to/from names and shortcodes
- [`emoji_search()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_search.md)
  : Search emoji by keyword, name or shortcode

## Provenance & reference data

- [`emoji_provenance()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_provenance.md)
  : Versions behind an emoji analysis, in one row
- [`emoji_unicode_version()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_unicode_version.md)
  : Which Unicode emoji version does this build reflect?
- [`emoji_unicode_releases()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_unicode_releases.md)
  : Unicode and Unicode Emoji release dates

## Data

- [`emoji_sentiment_lexicon`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sentiment_lexicon.md)
  : Emoji Sentiment Ranking lexicon
- [`emoji_emotion_lexicon`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_emotion_lexicon.md)
  : Emoji emotion lexicon (EmoTag1200)
- [`emoji_unicode_crosswalk`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_unicode_crosswalk.md)
  : Emoji name, unicode and category crosswalk
- [`category_unicode_crosswalk`](https://pursuitofdatascience.github.io/tidyEmoji/reference/category_unicode_crosswalk.md)
  : Emoji category to unicode crosswalk
