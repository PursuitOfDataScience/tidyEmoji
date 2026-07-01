# Changelog

## tidyEmoji 0.3.0

### New features

- [`emoji_emotion()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_emotion.md)
  scores each row’s emoji across the eight Plutchik emotions (anger,
  anticipation, disgust, fear, joy, sadness, surprise, trust), using the
  new bundled `emoji_emotion_lexicon` (EmoTag1200, Shoeb & de Melo 2020,
  MIT). Supports a long form (`long = TRUE`) with one row per (row,
  emotion).
- [`emoji_emotion_label()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_emotion_label.md)
  adds the dominant emotion per row.
- A pluggable lexicon API:
  [`emoji_lexicons()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_lexicons.md)
  lists bundled and registered lexicons,
  [`register_emoji_lexicon()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/register_emoji_lexicon.md)
  adds your own, and
  [`emoji_score()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_score.md)
  is the generic scorer all the verbs share.
  [`emoji_sentiment()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sentiment.md)
  gains a `lexicon` argument (default `"novak2015"`, unchanged
  behaviour).
- [`emoji_to_text()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_to_text.md)
  replaces emoji in a text column with their Unicode names or shortcodes
  (demojize — useful for accessibility and NLP preprocessing), and
  [`text_to_emoji()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/text_to_emoji.md)
  is the inverse (emojize).
- Vector helpers
  [`as_emoji_name()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/as_emoji_name.md),
  [`as_emoji_shortcode()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/as_emoji_name.md)
  and
  [`as_emoji()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/as_emoji_name.md)
  for ad-hoc conversion.
- [`emoji_search()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_search.md)
  finds emoji by keyword, name or shortcode and returns a tidy tibble of
  matches.
- New bundled dataset `emoji_emotion_lexicon`.

### Improvements and fixes

- DESCRIPTION Title and Description broadened to cover emotions,
  translation and search; version bumped to 0.3.0.

## tidyEmoji 0.2.1

### Improvements and fixes

- Emoji name, shortcode and category now resolve through the same
  codepoint-normalised key as sentiment, so emoji carrying the `U+FE0F`
  variation selector no longer get `NA` metadata, are no longer dropped
  by
  [`emoji_categorize()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_categorize.md),
  and no longer disappear from `top_n_emojis(duplicated = TRUE)`.
- The whole package now agrees on what “contains an emoji” means:
  [`emoji_summary()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_summary.md)
  and
  [`emoji_filter()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_filter.md)
  use the same detection as the extraction verbs.
- [`emoji_sentiment()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sentiment.md)
  gains `.emoji_n_scored` (emoji actually found in the lexicon),
  distinct from `.emoji_n`.
- `top_n_emojis(n =)` counts distinct emoji rather than rows, breaks
  ties deterministically, keeps emoji that have no GitHub-style alias,
  and preserves the exact extracted glyph in `duplicated` mode (one row
  per distinct alias; `left_join` instead of `inner_join`).
- [`emoji_extract_unnest()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_extract_unnest.md)
  now uses `.row_number` (dotted) to avoid collision with user columns
  and
  [`dplyr::row_number`](https://dplyr.tidyverse.org/reference/row_number.html).
- [`emoji_summary()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_summary.md)
  column names renamed from `emoji_tweets`/`total_tweets` to
  `n_with_emoji`/`n_total`. The old names are no longer available in
  this release.
- [`emoji_tweets()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_filter.md)
  is soft-deprecated in favour of
  [`emoji_filter()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_filter.md).
- Faster on large corpora: codepoint keys are computed once over the
  unique glyph set rather than per row in
  [`emoji_sentiment()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sentiment.md)
  and
  [`emoji_categorize()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_categorize.md).
- Grouped data frames passed to
  [`emoji_summary()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_summary.md),
  [`emoji_frequency()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_frequency.md)
  and
  [`top_n_emojis()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/top_n_emojis.md)
  now warn that grouping is ignored (per-group results land in 1.0).
- Lifecycle badge downgraded from stable to maturing.
- Vignette sample renamed from `ata_tweets.rda` (a CSV misnamed `.rda`)
  to `ata_tweets.csv` and downsampled from 10k to 2k rows. Vignette
  language updated to be less Twitter-specific.
- Crosswalk datasets rebuilt with a `key` column for normalised joins.

## tidyEmoji 0.2.0

CRAN release: 2026-06-17

tidyEmoji is now positioned as a general toolkit for emoji in **any**
text column (social-media posts, reviews, chat logs, survey responses,
…), not just tweets.

### New features

- [`emoji_sentiment()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sentiment.md)
  scores the emoji in each row using the bundled
  `emoji_sentiment_lexicon` (the Emoji Sentiment Ranking of Kralj Novak
  et al., 2015), returning a mean sentiment in `[-1, 1]`.
- [`emoji_frequency()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_frequency.md)
  returns the count of *every* emoji in a text column, with name,
  shortcode and category.
  [`top_n_emojis()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/top_n_emojis.md)
  is now a thin wrapper over it.
- [`emoji_tokens()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_tokens.md)
  expands data to one row per emoji occurrence with its name, category
  and sentiment score — a tidy, “one-token-per-row” shape.
- [`emoji_filter()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_filter.md)
  is a clearer, text-agnostic name for
  [`emoji_tweets()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_filter.md)
  (which is kept as a synonym).
- New bundled dataset `emoji_sentiment_lexicon`.

### Improvements and fixes

- **Grapheme-aware detection.** Extraction now keeps skin-tone modifiers
  and zero-width-joiner sequences intact. Previously a family emoji (👨‍👩‍👧‍👦)
  was miscounted as four separate people and a skin-tone thumbs-up split
  into two “emoji”; both are now counted as one.
- **Much faster.** Detection and counting no longer build a
  multi-thousand-way regular expression on every call or scan the text
  once per known emoji;
  [`top_n_emojis()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/top_n_emojis.md)
  in particular is dramatically faster on large inputs.
- [`top_n_emojis()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/top_n_emojis.md)
  no longer emits a many-to-many join warning, and reports the emoji’s
  canonical shortcode (e.g. `mask`) by default.
- All verbs now return tibbles consistently
  ([`emoji_tweets()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_filter.md)
  previously returned a plain data frame), and
  [`emoji_extract_unnest()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_extract_unnest.md)
  no longer prints a grouping message.
- Bundled emoji data refreshed against the current Unicode emoji list
  (via `data-raw/`).

### Breaking changes

- Arguments are renamed `tweet_tbl` -\> `data` and `tweet_text` -\>
  `text`. Code that passed these positionally
  (e.g. `df %>% emoji_summary(text_col)`) is unaffected; update any
  calls that named the old arguments.
- `top_n_emojis(duplicated_unicode = "yes"/"no")` is deprecated in
  favour of the logical `duplicated = TRUE/FALSE`. The old argument
  still works with a warning.

## tidyEmoji 0.1.1

CRAN release: 2023-08-19

- Changed the package metadata

## tidyEmoji 0.1.0

CRAN release: 2022-02-18

- Initial release to CRAN.
