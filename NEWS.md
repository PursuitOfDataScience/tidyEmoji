# tidyEmoji 0.4.0

## New features

* Relational analysis. `emoji_pairs()` returns a tidy, graph-ready edge list
  (`item1`, `item2`, `n`) of the emoji that co-occur in the same document —
  each row is a document, or supply `doc_id` to pool rows — with
  `directed = TRUE` to order pairs by first appearance. `emoji_cooccurrence()`
  is the same with an optional `diagonal` (each emoji's document frequency).
  `emoji_ngrams()` slides a window over each row's emoji in reading order and
  returns one row per consecutive n-gram.
* Structural metrics. `emoji_position()` reports where emoji sit in each text
  (first/last character position and mean relative position in `[0, 1]`),
  `emoji_density()` reports emoji per character and per token, and
  `emoji_ratio()` reports the share of the text's characters that are emoji
  plus an `.emoji_only` flag.
* `emoji_dfm()` builds a document-by-emoji feature table (weightings: counts,
  binary, tf-idf), keeping every document — including emoji-free ones — so the
  result binds row-for-row to outcome columns in modelling workflows.
* The four corpus-level verbs above canonicalise glyphs through the package's
  codepoint key, so qualified and unqualified forms of the same emoji (for
  example the victory hand with and without `U+FE0F`) count as one
  node/feature. `emoji_frequency()` intentionally still reports the exact
  extracted glyph.

## Improvements and fixes

* rlang moved from Suggests to Imports (tidy-eval capture of the new optional
  `doc_id` argument); it was already a hard transitive dependency, so the
  installed footprint is unchanged.
* Grouped data frames passed to `emoji_pairs()`, `emoji_cooccurrence()` or
  `emoji_dfm()` warn that grouping is ignored — use `doc_id` to express
  per-group structure.
* The vignette header no longer carries a build date.

# tidyEmoji 0.3.0

## New features

* `emoji_emotion()` scores each row's emoji across the eight Plutchik emotions
  (anger, anticipation, disgust, fear, joy, sadness, surprise, trust), using the
  new bundled `emoji_emotion_lexicon` (EmoTag1200, Shoeb & de Melo 2020, MIT).
  Supports a long form (`long = TRUE`) with one row per (row, emotion).
* `emoji_emotion_label()` adds the dominant emotion per row.
* A pluggable lexicon API: `emoji_lexicons()` lists bundled and registered
  lexicons, `register_emoji_lexicon()` adds your own, and `emoji_score()` is the
  generic scorer all the verbs share. `emoji_sentiment()` gains a `lexicon`
  argument (default `"novak2015"`, unchanged behaviour).
* `emoji_to_text()` replaces emoji in a text column with their Unicode names or
  shortcodes (demojize — useful for accessibility and NLP preprocessing), and
  `text_to_emoji()` is the inverse (emojize).
* Vector helpers `as_emoji_name()`, `as_emoji_shortcode()` and `as_emoji()` for
  ad-hoc conversion.
* `emoji_search()` finds emoji by keyword, name or shortcode and returns a tidy
  tibble of matches.
* New bundled dataset `emoji_emotion_lexicon`.

## Improvements and fixes

* `emoji_search()` matches literally, so queries containing regex
  metacharacters (for example the `+1` alias) are safe and cannot error.
* `emoji_to_text(format = "shortcode")` now always emits the emoji's canonical
  (first) GitHub-style alias — the same one reported by `emoji_frequency()` and
  `as_emoji_shortcode()` — and the `wrap` template is honoured. Emoji with no
  known name/shortcode are left in place rather than dropped from the text.
* `emoji_to_text()` and `text_to_emoji()` keep `NA` text entries as `NA`.
* `emoji_emotion()` and `emoji_emotion_label()` accept registered or
  data-frame emotion lexicons (any subset of the eight Plutchik dimensions),
  not just the bundled `"emotag1200"`.
* Registered lexicons resolve through their stored normalised key, so
  `register_emoji_lexicon(by = )` works with any glyph column name in
  `emoji_sentiment()` and `emoji_emotion()`.
* `emoji_frequency()` (and therefore `top_n_emojis()`) breaks count ties by
  the glyph, making the output order deterministic.
* `emoji_lexicons()` no longer lists a custom lexicon's glyph/key columns among
  its score dimensions.
* The package help page (`?tidyEmoji`) documents the output and naming
  contract shared by all verbs.
* DESCRIPTION Title and Description broadened to cover emotions, translation and
  search; version bumped to 0.3.0.

# tidyEmoji 0.2.1

## Improvements and fixes

* Emoji name, shortcode and category now resolve through the same
  codepoint-normalised key as sentiment, so emoji carrying the `U+FE0F` variation
  selector no longer get `NA` metadata, are no longer dropped by
  `emoji_categorize()`, and no longer disappear from `top_n_emojis(duplicated =
  TRUE)`.
* The whole package now agrees on what "contains an emoji" means:
  `emoji_summary()` and `emoji_filter()` use the same detection as the extraction
  verbs.
* `emoji_sentiment()` gains `.emoji_n_scored` (emoji actually found in the
  lexicon), distinct from `.emoji_n`.
* `top_n_emojis(n =)` counts distinct emoji rather than rows, breaks ties
  deterministically, keeps emoji that have no GitHub-style alias, and preserves
  the exact extracted glyph in `duplicated` mode (one row per distinct alias;
  `left_join` instead of `inner_join`).
* `emoji_extract_unnest()` now uses `.row_number` (dotted) to avoid collision
  with user columns and `dplyr::row_number`.
* `emoji_summary()` column names renamed from `emoji_tweets`/`total_tweets` to
  `n_with_emoji`/`n_total`. The old names are no longer available in this
  release.
* `emoji_tweets()` is soft-deprecated in favour of `emoji_filter()`.
* Faster on large corpora: codepoint keys are computed once over the unique glyph
  set rather than per row in `emoji_sentiment()` and `emoji_categorize()`.
* Grouped data frames passed to `emoji_summary()`, `emoji_frequency()` and
  `top_n_emojis()` now warn that grouping is ignored (per-group results land in
  1.0).
* Lifecycle badge downgraded from stable to maturing.
* Vignette sample renamed from `ata_tweets.rda` (a CSV misnamed `.rda`) to
  `ata_tweets.csv` and downsampled from 10k to 2k rows. Vignette language
  updated to be less Twitter-specific.
* Crosswalk datasets rebuilt with a `key` column for normalised joins.

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
