# tidyEmoji 0.2.0

tidyEmoji is now positioned as a general toolkit for emoji in **any** text
column (social-media posts, reviews, chat logs, survey responses, ...), not just
tweets.

## New features

* `emoji_sentiment()` scores the emoji in each row using the bundled
  `emoji_sentiment_lexicon` (the Emoji Sentiment Ranking of Kralj Novak et al.,
  2015), returning a mean sentiment in `[-1, 1]`.
* `emoji_frequency()` returns the count of *every* emoji in a text column, with
  name, shortcode and category. `top_n_emojis()` is now a thin wrapper over it.
* `emoji_tokens()` expands data to one row per emoji occurrence with its name,
  category and sentiment score — a tidy, "one-token-per-row" shape.
* `emoji_filter()` is a clearer, text-agnostic name for `emoji_tweets()` (which
  is kept as a synonym).
* New bundled dataset `emoji_sentiment_lexicon`.

## Improvements and fixes

* **Grapheme-aware detection.** Extraction now keeps skin-tone modifiers and
  zero-width-joiner sequences intact. Previously a family emoji
  (👨‍👩‍👧‍👦) was miscounted as four separate people and a skin-tone
  thumbs-up split into two "emoji"; both are now counted as one.
* **Much faster.** Detection and counting no longer build a multi-thousand-way
  regular expression on every call or scan the text once per known emoji;
  `top_n_emojis()` in particular is dramatically faster on large inputs.
* `top_n_emojis()` no longer emits a many-to-many join warning, and reports the
  emoji's canonical shortcode (e.g. `mask`) by default.
* All verbs now return tibbles consistently (`emoji_tweets()` previously
  returned a plain data frame), and `emoji_extract_unnest()` no longer prints a
  grouping message.
* Bundled emoji data refreshed against the current Unicode emoji list (via
  `data-raw/`).

## Breaking changes

* Arguments are renamed `tweet_tbl` -> `data` and `tweet_text` -> `text`. Code
  that passed these positionally (e.g. `df %>% emoji_summary(text_col)`) is
  unaffected; update any calls that named the old arguments.
* `top_n_emojis(duplicated_unicode = "yes"/"no")` is deprecated in favour of the
  logical `duplicated = TRUE/FALSE`. The old argument still works with a warning.

# tidyEmoji 0.1.1

- Changed the package metadata

# tidyEmoji 0.1.0

- Initial release to CRAN.
