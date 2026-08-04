# tidyEmoji 0.4.0

This release delivers the first wave of the feature roadmap filed as
[issue #5](https://github.com/PursuitOfDataScience/tidyEmoji/issues/5):
the items that are cheap, research-grounded, and need no new dataset and no
new dependency. Most of them are recombinations of machinery the package
already had — the Novak lexicon's annotation counts, the reference table's
Unicode version column, the grapheme-aware locator — read out in a way no R
package exposed before.

## New features

### Interpretation risk (roadmap theme B)

Miller et al. (2016) found that readers of the *same* rendering disagree about
whether an emoji is positive, neutral or negative roughly a quarter of the
time. The bundled Emoji Sentiment Ranking keeps the raw
`negative`/`neutral`/`positive` annotation counts behind its collapsed score,
so that disagreement was already inside the package as an empirical
distribution. It is now a number.

* `emoji_ambiguity()` reports per-glyph annotation shares and one of four
  disagreement statistics — Shannon `entropy` (the default), `gini`,
  `neutral_share` or `ci_width` — with a rank over the whole lexicon.
* `emoji_risk()` is the per-row version: `.emoji_ambiguity_mean`,
  `.emoji_ambiguity_max` and `.emoji_n_ambiguous`.
* `emoji_flag_ambiguous()` is the content-QA shortlist: the emoji in *your*
  corpus most likely to be misread.
* `emoji_sentiment(se = TRUE)` adds `.emoji_sentiment_se`, so a glyph annotated
  eight times no longer carries the same authority as one annotated eight
  thousand times.

### Context (roadmap theme C)

* `emoji_context()` returns one row per emoji occurrence with a window of the
  surrounding text, in words or characters. All other emoji are blanked out of
  the window, and character offsets stay exact.
* `emoji_collocations()` aggregates those windows into an emoji-word table
  scored by pointwise mutual information, shaped like `widyr::pairwise_count()`
  output. Corpus-derived senses have neither the licence problem nor the
  staleness problem of an imported sense inventory.

### Time (roadmap theme H)

* `emoji_trend()` counts emoji per period (`"day"`, `"week"`, `"month"`,
  `"quarter"`, `"year"`) and returns a *complete* period-by-emoji grid, so a
  trend line does not silently skip its zeros.
* `emoji_turnover()` reports vocabulary churn between consecutive periods:
  `jaccard`, `n_new`, `n_lost`, `n_core`.
* `emoji_version_profile()` breaks a corpus down by the Unicode emoji version
  that introduced each glyph, and `emoji_adoption_lag()` compares first use in
  the corpus with the release date. Both come almost free from the `version`
  column the reference table already carries.
* `emoji_seasonality()` aggregates by month, weekday or hour, returning every
  level of the cycle including the empty ones, with fixed English labels so a
  script's output does not change with the machine that runs it.
* `emoji_unicode_releases()` is the version-to-release-date lookup behind the
  two verbs above. It is a function rather than a bundled dataset: at a few
  dozen rows it belongs beside the code that uses it.

### Text-emoji mismatch (roadmap theme E)

* `emoji_incongruity()` measures the signed gap between a row's text sentiment
  and its emoji sentiment — the sarcasm feature in NLP, the (in)congruence
  variable in marketing research. `emoji_congruence()` is the same engine under
  the marketing framing; `emoji_incongruity_profile()` reports which glyphs go
  against the grain of their host text.
* tidyEmoji still does not score text: you supply `text_score` from
  tidytext, sentimentr, vader or a model. Because those live
  on incompatible scales, `scale` has **no default** — you have to say how the
  two sides were made comparable.
* Rows with no scorable emoji get `NA`, never `0`, in every new column.

### Functional type (roadmap theme K)

* `as_emoji_type()`, `emoji_type()` and `emoji_faceness()` recode the Unicode
  group and subgroup into `face`, `gesture`, `person`, `nature`, `food`,
  `place`, `activity`, `object`, `symbol`, `flag` and `component`. The
  emotional (face) versus semantic (object) contrast is the key variable in the
  consumer-behaviour literature and is now a one-liner.

### Language-model plumbing (roadmap theme J)

* `emoji_sanitize()` applies one named policy — `"keep"`, `"strip"`, `"name"`,
  `"shortcode"` or `"placeholder"` — to a text column. The capability mostly
  existed; the value is an argument that shows up in a script diff and in a
  methods section.
* `emoji_token_cost()` reports exact `.emoji_bytes`, `.emoji_codepoints` and
  `.emoji_graphemes` plus a clearly-labelled `.emoji_token_estimate`, or the
  real count if you pass your own `tokenizer`.

### Provenance (roadmap theme M)

* `emoji_provenance()` puts every version an emoji result depends on in one
  row: tidyEmoji, the emoji package, the Unicode emoji version, the size
  of the detectable emoji set, and the lexicons.
* `emoji_unicode_version()` reports that Unicode version on its own.
* `inst/CITATION` now credits the package and the two lexicon papers users have
  to cite anyway.

## Improvements and fixes

* **`emoji_dfm(doc_id = )` no longer orders its rows by the session's
  collation.** Documents were grouped with `factor()`, whose levels are sorted
  with the locale's collation, so the row order of the result could differ
  between machines — the same class of bug 0.3.0 fixed for glyph ordering in
  `emoji_pairs()` and the dfm's columns. Documents now appear in the order
  their id is first seen in the data. `emoji_pairs()`,
  `emoji_cooccurrence()` and `emoji_dfm()` share one grouping helper, so they
  cannot drift apart again.
* `emoji_sanitize(policy = "strip")` tidies only the whitespace left behind by
  a removed glyph, and only on rows that actually contained one.
* **Arguments given nonsense now error instead of quietly returning a
  different answer.** An audit of every argument that reaches a base R function
  without validation found one shape of bug repeated across the package: a
  value the function cannot honour was absorbed rather than rejected.
  `emoji_to_text(wrap = )` now requires the `{x}` placeholder, since a template
  without it replaces every emoji with the same literal string;
  `top_n_emojis(n = )` rejects a negative `n`, which `head()` had silently read
  as "drop the last row"; and every `TRUE`/`FALSE` argument
  (`emoji_pairs(directed = , sort = )`, `emoji_cooccurrence(diagonal = )`,
  `emoji_emotion(long = )`, `emoji_context(keep_text = )`,
  `top_n_emojis(duplicated = )`, `emoji_sentiment(se = )`) is now checked,
  because `isTRUE()` reads every non-`TRUE` value as `FALSE` — so
  `long = "yes"` used to return the wide form without complaint. The deprecated
  `top_n_emojis(duplicated_unicode = "yes")` still works: the check runs after
  the lifecycle conversion.
* `emoji_score()` gains the `lexicon = "novak2015"` default that
  `emoji_sentiment()` always had, so calling it without a lexicon works instead
  of raising a missing-argument error.
* The reference-manual sources are ASCII throughout, so the PDF manual builds
  everywhere.
* `next_release.md`, the repo's release ledger, gains a section 13 recording
  what wave 1 shipped, the third-audit defect, and the design decisions locked
  at implementation.

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
* The corpus-level verbs above (`emoji_pairs()`, `emoji_cooccurrence()`,
  `emoji_ngrams()`, `emoji_dfm()`) canonicalise glyphs through the package's
  codepoint key, so qualified and unqualified forms of the same emoji (for
  example the victory hand with and without `U+FE0F`) count as one
  node/feature. `emoji_frequency()` intentionally still reports the exact
  extracted glyph.
* `emoji_to_text()` replaces emoji in a text column with their Unicode names or
  shortcodes (demojize — useful for accessibility and NLP preprocessing), and
  `text_to_emoji()` is the inverse (emojize).
* Vector helpers `as_emoji_name()`, `as_emoji_shortcode()` and `as_emoji()` for
  ad-hoc conversion.
* `emoji_search()` finds emoji by keyword, name or shortcode and returns a tidy
  tibble of matches.
* New bundled dataset `emoji_emotion_lexicon`.
* tidyEmoji has a hex logo! It appears in the README and on the pkgdown site
  (`man/figures/logo.svg` is the vector master, `logo.png` the raster copy).

## Improvements and fixes

* **Grapheme-aware detection now covers newer zero-width-joiner sequences.**
  The upstream emoji regex only knows the ZWJ sequences that were current when
  it was built, so it reported later ones — face exhaling, face with spiral
  eyes, heart on fire, people holding hands, the skin-toned handshakes,
  "woman: blond hair", and around 630 others — as their *component* emoji.
  tidyEmoji now re-joins them (a ZWJ between two emoji always binds them into
  one grapheme cluster). Previously such an emoji inflated counts, resolved to
  the wrong name, split into several co-occurrence nodes and stopped
  `emoji_ratio()` recognising an emoji-only row; all of that is fixed. Emoji
  separated by anything other than a ZWJ are unaffected.
* Extraction and location are now sliced from the same spans, so no verb can
  disagree with another about where an emoji starts and ends.
* `text_to_emoji()` no longer misses a `:shortcode:` that follows an unrelated
  colon. `"meet at 10:30 :grinning:"` and `"https://example.org :grinning:"`
  previously came back unchanged, because the permissive `:...:` pattern
  consumed the shortcode's opening colon; shortcode tokens are now matched on
  the character set GitHub-style aliases actually use.
* `emoji_pairs()` and `emoji_dfm()` order glyphs in the C locale, so which
  glyph lands in `item1` and the order of a dfm's tied columns no longer depend
  on the session's collation. Results are now reproducible across machines.
* `emoji_lexicons()` no longer reports the glyph column as a score dimension
  for a lexicon registered with a `by` other than `"emoji"`.
* `emoji_emotion(long = TRUE)` no longer drops a user column named
  `.row_number`.
* `emoji_ngrams(n = Inf)` gives the documented error instead of a coercion
  warning followed by "missing value where TRUE/FALSE needed".
* `emoji_to_text()` is several times faster: it locates emoji once for the
  whole column rather than once per row.
* `emoji_density()` returns `.emoji_per_token = 0` (not `NA`) for
  whitespace-only text, matching `.emoji_per_char` and the documented
  "no emoji -> 0" contract (#1).
* `as_emoji()` accepts the spaced Unicode names produced by `as_emoji_name()`
  (routing through the reference table), so `as_emoji(as_emoji_name(x))`
  round-trips instead of returning `NA` (#2).
* `?emoji_sentiment_lexicon` now explains which lexicon entries are stored as
  unqualified, text-presentation code points (the bare heart `U+2764` without
  `U+FE0F`, the white smiling face, the heavy check mark, ...) and are
  therefore not detected in text, and notes that the qualified form resolves to
  the same entry (#3).
* The help pages no longer embed raw emoji glyphs, so the reference manual
  builds as PDF; `?register_emoji_lexicon` no longer points at an internal
  development file.
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
* rlang moved from Suggests to Imports (tidy-eval capture of the new optional
  `doc_id` argument); it was already a hard transitive dependency, so the
  installed footprint is unchanged.
* Grouped data frames passed to `emoji_pairs()`, `emoji_cooccurrence()` or
  `emoji_dfm()` warn that grouping is ignored — use `doc_id` to express
  per-group structure.
* The vignette header no longer carries a build date.
* DESCRIPTION Title and Description broadened to cover emotions, translation,
  search, co-occurrence, structural metrics and feature tables; version bumped
  to 0.3.0.

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
