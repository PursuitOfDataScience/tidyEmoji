# Changelog

## tidyEmoji 0.4.0

This release delivers the first wave of the feature roadmap filed as
[issue](https://github.com/PursuitOfDataScience/tidyEmoji/issues/5)
[\#5](https://github.com/PursuitOfDataScience/tidyEmoji/issues/5): the
items that are cheap, research-grounded, and need no new dataset and no
new dependency. Most of them are recombinations of machinery the package
already had — the Novak lexicon’s annotation counts, the reference
table’s Unicode version column, the grapheme-aware locator — read out in
a way no R package exposed before.

### New features

#### Interpretation risk (roadmap theme B)

Miller et al. (2016) found that readers of the *same* rendering disagree
about whether an emoji is positive, neutral or negative roughly a
quarter of the time. The bundled Emoji Sentiment Ranking keeps the raw
`negative`/`neutral`/`positive` annotation counts behind its collapsed
score, so that disagreement was already inside the package as an
empirical distribution. It is now a number.

- [`emoji_ambiguity()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_ambiguity.md)
  reports per-glyph annotation shares and one of four disagreement
  statistics — Shannon `entropy` (the default), `gini`, `neutral_share`
  or `ci_width` — with a rank over the whole lexicon.
- [`emoji_risk()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_risk.md)
  is the per-row version: `.emoji_ambiguity_mean`,
  `.emoji_ambiguity_max` and `.emoji_n_ambiguous`.
- [`emoji_flag_ambiguous()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_flag_ambiguous.md)
  is the content-QA shortlist: the emoji in *your* corpus most likely to
  be misread.
- `emoji_sentiment(se = TRUE)` adds `.emoji_sentiment_se`, so a glyph
  annotated eight times no longer carries the same authority as one
  annotated eight thousand times.

#### Context (roadmap theme C)

- [`emoji_context()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_context.md)
  returns one row per emoji occurrence with a window of the surrounding
  text, in words or characters. All other emoji are blanked out of the
  window, and character offsets stay exact.
- [`emoji_collocations()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_collocations.md)
  aggregates those windows into an emoji-word table scored by pointwise
  mutual information, shaped like `widyr::pairwise_count()` output.
  Corpus-derived senses have neither the licence problem nor the
  staleness problem of an imported sense inventory.

#### Time (roadmap theme H)

- [`emoji_trend()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_trend.md)
  counts emoji per period (`"day"`, `"week"`, `"month"`, `"quarter"`,
  `"year"`) and returns a *complete* period-by-emoji grid, so a trend
  line does not silently skip its zeros.
- [`emoji_turnover()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_turnover.md)
  reports vocabulary churn between consecutive periods: `jaccard`,
  `n_new`, `n_lost`, `n_core`.
- [`emoji_version_profile()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_version_profile.md)
  breaks a corpus down by the Unicode emoji version that introduced each
  glyph, and
  [`emoji_adoption_lag()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_adoption_lag.md)
  compares first use in the corpus with the release date. Both come
  almost free from the `version` column the reference table already
  carries.
- [`emoji_seasonality()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_seasonality.md)
  aggregates by month, weekday or hour, returning every level of the
  cycle including the empty ones, with fixed English labels so a
  script’s output does not change with the machine that runs it.
- [`emoji_unicode_releases()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_unicode_releases.md)
  is the version-to-release-date lookup behind the two verbs above. It
  is a function rather than a bundled dataset: at a few dozen rows it
  belongs beside the code that uses it.

#### Text-emoji mismatch (roadmap theme E)

- [`emoji_incongruity()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_incongruity.md)
  measures the signed gap between a row’s text sentiment and its emoji
  sentiment — the sarcasm feature in NLP, the (in)congruence variable in
  marketing research.
  [`emoji_congruence()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_congruence.md)
  is the same engine under the marketing framing;
  [`emoji_incongruity_profile()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_incongruity_profile.md)
  reports which glyphs go against the grain of their host text.
- tidyEmoji still does not score text: you supply `text_score` from
  tidytext, sentimentr, vader or a model. Because those live on
  incompatible scales, `scale` has **no default** — you have to say how
  the two sides were made comparable.
- Rows with no scorable emoji get `NA`, never `0`, in every new column.

#### Functional type (roadmap theme K)

- [`as_emoji_type()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/as_emoji_type.md),
  [`emoji_type()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_type.md)
  and
  [`emoji_faceness()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_faceness.md)
  recode the Unicode group and subgroup into `face`, `gesture`,
  `person`, `nature`, `food`, `place`, `activity`, `object`, `symbol`,
  `flag` and `component`. The emotional (face) versus semantic (object)
  contrast is the key variable in the consumer-behaviour literature and
  is now a one-liner.

#### Language-model plumbing (roadmap theme J)

- [`emoji_sanitize()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sanitize.md)
  applies one named policy — `"keep"`, `"strip"`, `"name"`,
  `"shortcode"` or `"placeholder"` — to a text column. The capability
  mostly existed; the value is an argument that shows up in a script
  diff and in a methods section.
- [`emoji_token_cost()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_token_cost.md)
  reports exact `.emoji_bytes`, `.emoji_codepoints` and
  `.emoji_graphemes` plus a clearly-labelled `.emoji_token_estimate`, or
  the real count if you pass your own `tokenizer`.

#### Provenance (roadmap theme M)

- [`emoji_provenance()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_provenance.md)
  puts every version an emoji result depends on in one row: tidyEmoji,
  the emoji package, the Unicode emoji version, the size of the
  detectable emoji set, and the lexicons.
- [`emoji_unicode_version()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_unicode_version.md)
  reports that Unicode version on its own.
- `inst/CITATION` now credits the package and the two lexicon papers
  users have to cite anyway.

### Improvements and fixes

- **Grouped data frames no longer break six verbs, and no longer lose
  their grouping in the rest.** Two independent bugs, found by calling
  every verb on a grouped input:
  [`emoji_to_text()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_to_text.md),
  [`text_to_emoji()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/text_to_emoji.md),
  [`emoji_sanitize()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sanitize.md),
  [`emoji_context()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_context.md)
  and
  [`emoji_collocations()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_collocations.md)
  resolved their text column with
  [`dplyr::select()`](https://dplyr.tidyverse.org/reference/select.html),
  which silently re-adds the grouping columns, so a grouped data frame
  made the selection return two names and the call failed with
  `` `text` must select exactly one column `` — an error blaming an
  argument the user had got right. And the verbs that work a row at a
  time returned `tibble::as_tibble(data)`, which strips the `grouped_df`
  class, so
  `group_by(author) |> emoji_sentiment(text) |> summarise(...)` quietly
  collapsed to one corpus-wide row instead of one row per author. Those
  verbs now carry the grouping through, as
  [`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html)
  and
  [`dplyr::filter()`](https://dplyr.tidyverse.org/reference/filter.html)
  do; the three that rewrite the text column in place re-derive the
  group indices if the user grouped by that column. See
  [`?tidyEmoji`](https://pursuitofdatascience.github.io/tidyEmoji/reference/tidyEmoji-package.md)
  for the contract.

- **Seven cross-row aggregators were silently pooling grouped input.**
  [`emoji_version_profile()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_version_profile.md),
  [`emoji_trend()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_trend.md),
  [`emoji_turnover()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_turnover.md),
  [`emoji_seasonality()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_seasonality.md),
  [`emoji_adoption_lag()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_adoption_lag.md),
  [`emoji_collocations()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_collocations.md)
  and
  [`emoji_incongruity_profile()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_incongruity_profile.md)
  had no grouped-input guard, so a user grouping by author, platform or
  date got a corpus-wide answer that looked like a per-group one. All
  seven now warn.
  [`emoji_cooccurrence()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_cooccurrence.md)
  and
  [`emoji_flag_ambiguous()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_flag_ambiguous.md)
  warned under the name of the verb they delegate to
  ([`emoji_pairs()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_pairs.md),
  [`emoji_frequency()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_frequency.md))
  and now warn under their own. The guard lives in one helper rather
  than being copy-pasted into each verb — that copy-paste is why the
  seven were missed — and the helper reports the warning against the
  caller’s frame, so it no longer appends “Please report the issue” to a
  warning about the user’s own data.

- **A missing, ambiguous or misspelled column argument now names the
  argument the user actually wrote.** Every verb resolved its column
  with
  [`dplyr::pull()`](https://dplyr.tidyverse.org/reference/pull.html),
  whose errors are phrased in terms of `var` — a formal of
  [`pull()`](https://dplyr.tidyverse.org/reference/pull.html) that
  appears in no tidyEmoji signature. `emoji_sentiment(df)` said
  `` `var` is absent but must be supplied ``, `emoji_trend(df, text)`
  said the same about the missing `time`, a two-column selection said
  `` `!!enquo(var)` must select exactly one column ``, and a typo was
  reported as `object 'txet' not found`, as if the user’s own code had a
  free variable in it. All 38 call sites now go through one resolver:
  the messages name `text`, `time`, `text_score` or `doc_id`, and a
  misspelling is reported as `Column \`txet\` doesn’t exist\`.

- **[`emoji_extract_nest()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_extract_nest.md)
  accepted a missing text column.** It resolved `{{ text }}` in the data
  mask rather than as a column selection, so `emoji_extract_nest(df)`
  returned a bogus empty list-column instead of erroring, and a
  misspelled column was not caught either. It now uses the same resolver
  as every other verb, and still returns `data` with its class and
  grouping intact.

- The package’s own help page was stale relative to `DESCRIPTION`: the
  paragraph describing interpretation risk, context, time, incongruity
  and the sanitiser was missing from
  [`?tidyEmoji`](https://pursuitofdatascience.github.io/tidyEmoji/reference/tidyEmoji-package.md).
  The build no longer ships the `.claude` directory, which
  `R CMD check --as-cran` flagged as a hidden file included in error.

- **Zero-row input now really does return a *typed* zero-row tibble.**
  Five verbs built their output columns with
  [`ifelse()`](https://rdrr.io/r/base/ifelse.html), which takes the
  result’s type from its arguments, so
  [`emoji_density()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_density.md),
  [`emoji_ratio()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_ratio.md),
  [`emoji_faceness()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_faceness.md)
  and
  [`emoji_risk()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_risk.md)
  returned `logical` columns where a populated call returns `double` or
  `integer`, and
  [`emoji_tokens()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_tokens.md)
  returned an unspecified `.emoji` instead of `character`. Splitting a
  corpus, mapping a verb and binding the pieces back therefore produced
  a different schema depending on whether any chunk was empty. The
  values are unchanged.

- **A fractional count errors instead of being silently truncated.**
  `top_n_emojis(n = 2.5)` returned two rows,
  `emoji_context(window = 2.7)` used a window of two,
  `emoji_ngrams(n = 2.9)` built bigrams: in each case the number the
  user wrote was not the number that was used — the same failure mode as
  the `head(n = -1)` this release already caught, in the other
  direction. `n`, `top_n`, `window` and `min_n` now require a whole
  number; `NULL` and `Inf` keep their “all of them” meanings where they
  had one. `emoji_ngrams(sep = )` is checked too: it reached
  `paste(collapse = )`, which failed with `invalid 'collapse' argument`
  and an internal call stack for `NA` or a number, and silently used
  only the first element of a longer vector.

- [`emoji_extract_nest()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_extract_nest.md)
  now returns a tibble, like every other verb.
  [`?tidyEmoji`](https://pursuitofdatascience.github.io/tidyEmoji/reference/tidyEmoji-package.md)
  promises “every verb … returns a tibble”, but this was the one row
  verb that did not route its output through the shared helper, so a
  plain `data.frame` in gave a plain `data.frame` back while the other
  seventeen returned a tibble — which also meant a list-column printing
  badly instead of as `<list>`. A grouped input still stays grouped. The
  whole output contract is now asserted across every verb at once rather
  than verb by verb.

- Test line coverage went from 96.6% to 99.4%, and closing the gap found
  four **documented features that no test exercised**:
  [`emoji_score()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_score.md)
  with the `"emotag1200"` lexicon (the mean over its eight emotion
  dimensions), `emoji_sentiment(lexicon = )` given a data frame or a
  registered lexicon, `emoji_trend(by = "quarter")`, and `sort = FALSE`
  on the relational verbs. Also now covered: the lexicon aliases
  `"sentiment"` and `"emoji_sentiment_lexicon"`, a `factor` time column,
  the degenerate branches of the rank and z-score rescalings,
  [`emoji_incongruity_profile()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_incongruity_profile.md)’s
  zero-row return, and every argument-validation error on the lexicon
  surface — each of which had been checked by hand in an earlier round
  and never written down. The nine lines still uncovered are guards
  whose callers validate first.

- `commonmark` and `xml2` join `Suggests`. The test that checks
  `NEWS.md` parses calls
  [`utils::news()`](https://rdrr.io/r/utils/news.html), and R’s Markdown
  news reader calls both of them unguarded — packages that were present
  in the development library only because roxygen2 and testthat pull
  them in. Declaring them means CI installs them and the test runs,
  rather than skipping everywhere but the maintainer’s machine.
  `NEWS.md`’s version headings are now *also* checked directly, without
  parsing Markdown at all, so that invariant holds even where the reader
  is unavailable.

- `DESCRIPTION` declares `Language: en-GB`. The field was missing, so
  `spelling::spell_check_package()` defaulted to `en-US` and flagged 55
  correct British spellings — `licence`, `normalised`, `analysed`,
  `summarise`, `behaviour`, `neighbouring` — as errors, which made the
  check unusable as a gate. The prose was already consistently British:
  across ten British/American word pairs, the R sources, help pages,
  vignette, README, NEWS and `cran-comments.md` contain **zero**
  American spellings. The only American tokens are the exported names
  [`emoji_categorize()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_categorize.md)
  and
  [`emoji_sanitize()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sanitize.md),
  which follow R convention and stay.

- A new `inst/WORDLIST` records the 84 remaining terms the dictionary
  cannot know — author surnames, package names, and vocabulary like
  `codepoint`, `grapheme`, `shortcode`, `keycaps`, `ZWJ`, `Plutchik`,
  `idf`. With the language declared and the wordlist in place,
  `spell_check_package()` now reports zero, so a future typo is visible
  instead of buried in 139 lines of false positives.

- The test suite now passes in a non-UTF-8 locale. Ten test files
  carried 114 literal non-ASCII characters inside string literals —
  zero-width joiners, gender signs, hearts, the no-break and ideographic
  spaces — and R parses a source literal byte-wise under `LC_ALL=C`, so
  each became a run of replacement characters and every fixture built
  from one silently tested the wrong string. All 114 are now `\u` / `\U`
  escapes, and the suite gives identical results under `LC_ALL=C` and a
  UTF-8 locale. Two new tests keep it that way: one asserts `R/` is pure
  ASCII (the invariant 0.4.0 introduced so the PDF manual builds,
  checked by hand until now), the other that test string literals stay
  escaped. The package’s own detection was never affected — verified by
  re-running the whole-catalogue sweep under `LC_ALL=C`, which gives
  exactly the same 4830 of 5042 as a UTF-8 locale.

- The test suite no longer attaches `dplyr`. One test file called
  [`library(dplyr)`](https://dplyr.tidyverse.org), which in a single
  `testthat` session leaks into every alphabetically-later file and
  masks [`filter()`](https://dplyr.tidyverse.org/reference/filter.html),
  [`lag()`](https://dplyr.tidyverse.org/reference/lead-lag.html),
  [`intersect()`](https://generics.r-lib.org/reference/setops.html),
  [`setdiff()`](https://generics.r-lib.org/reference/setops.html),
  [`setequal()`](https://generics.r-lib.org/reference/setops.html),
  [`union()`](https://generics.r-lib.org/reference/setops.html) and
  `testthat::matches()` for all of them — so nine set-operation call
  sites were resolving to dplyr’s generics purely because of filename
  order. They worked, but by accident. The attach is gone, those calls
  are `base::`-qualified, and the suite’s behaviour no longer depends on
  the order its files happen to sort in.

- [`as_emoji()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/as_emoji_name.md)
  and
  [`text_to_emoji()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/text_to_emoji.md)
  accept **every** GitHub alias, not just the primary one each emoji is
  listed under, and that is now tested. The reference table keeps only
  an emoji’s first alias as its `shortcode`, so 751 of the 4698 aliases
  — `"grinning_face"`, `"satisfied"`, `"face_with_tears_of_joy"` —
  resolve solely through
  [`as_emoji()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/as_emoji_name.md)’s
  fallback to
  [`emoji::emoji_name`](https://emilhvitfeldt.github.io/emoji/reference/emoji_name.html).
  Nothing exercised that path.

- `emoji_incongruity(threshold =)` is documented as the gap “at or above
  which” `.emoji_incongruent` is `TRUE`, and the boundary is now tested.
  A row sitting exactly on the threshold is classified as incongruent;
  nothing had pinned that, so the comparison could have drifted to a
  strict one and silently reclassified every borderline row.

- [`emoji_search()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_search.md)’s
  three search fields are now tested separately. It is documented to
  match against keywords, name *and* shortcodes, and some queries match
  on one field only — `"grinning_face"` and `"thumbsup"` appear in no
  name (names use spaces, not underscores) and in no keyword — so a
  regression that dropped the shortcode field would have gone unnoticed.
  Also pinned: the search is case-insensitive, a query matching nothing
  returns a typed zero-row tibble, and the `+1` shortcode’s regex
  metacharacter is safe.

- [`emoji_dfm()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_dfm.md)’s
  column order is now guaranteed independent of the order the rows
  arrive in. Columns are sorted by descending total count with the glyph
  as tiebreak; without that tiebreak, tied columns fell back to the
  order the glyphs happened to appear in the data, so the same corpus
  sorted differently produced a differently-ordered feature matrix. The
  behaviour was already correct — this release pins it, along with
  row-order independence for
  [`emoji_frequency()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_frequency.md),
  [`top_n_emojis()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/top_n_emojis.md),
  [`emoji_version_profile()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_version_profile.md),
  [`emoji_pairs()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_pairs.md),
  [`emoji_cooccurrence()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_cooccurrence.md)
  and
  [`emoji_collocations()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_collocations.md).

- [`?emoji_emotion_label`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_emotion_label.md)
  now documents that ties are broken in Plutchik order, so the winning
  emotion is deterministic and does not depend on a row’s position in
  the data — it was a code comment only. The help page also points at
  [`emoji_emotion()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_emotion.md)
  for the profile the label collapses, since a near-tie is invisible in
  a single winning name.

- The introduction vignette’s “design choices” list now mentions how
  grouping composes, which became a design choice in this release and
  was documented only on
  [`?tidyEmoji`](https://pursuitofdatascience.github.io/tidyEmoji/reference/tidyEmoji-package.md).

- [`?emoji_incongruity`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_incongruity.md)
  now says what “ends the text” means for `where = "final"`. Only
  whitespace may follow the last glyph, so `"great \U0001f602"` has a
  final run and `"great \U0001f602."` does not — a trailing full stop,
  bracket or quote mark disqualifies it, which is easy to meet unaware
  in a punctuated corpus. The behaviour is unchanged; it was simply not
  stated.

- **A `POSIXct` time column was bucketed by its UTC day, not its own.**
  [`as.Date()`](https://rdrr.io/r/base/as.Date.html) on a date-time
  converts in UTC whatever the object’s `tzone` says, so an emoji posted
  at 23:30 New York time was counted on the *next* calendar day — and
  for an evening-heavy corpus, systematically so. It also made the
  package disagree with itself: `emoji_seasonality(period = "hour")`
  reads `format(x, "%H")` and had always used the timestamp’s own zone,
  so the same row could be hour 23 and the following day at once.
  [`emoji_trend()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_trend.md),
  [`emoji_turnover()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_turnover.md),
  [`emoji_adoption_lag()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_adoption_lag.md)
  and `emoji_seasonality(period = "month" / "weekday")` now all take the
  calendar day the timestamp displays as. The session’s `TZ` does not
  affect any of them, before or after.

- **A time column of strings silently shrank the corpus.** A value that
  would not parse as a date became `NA`, and the time verbs then dropped
  the row — indistinguishable, in the result, from a row whose date was
  genuinely missing.
  [`emoji_trend()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_trend.md),
  [`emoji_turnover()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_turnover.md),
  [`emoji_seasonality()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_seasonality.md)
  and
  [`emoji_adoption_lag()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_adoption_lag.md)
  now say how many values were unreadable and show the first one; a real
  `NA` still passes without comment, and a column where nothing parses
  still errors.

- **[`?emoji_sanitize`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sanitize.md)
  now documents which policies can be undone.** The five policies were
  presented as five parallel options; they are a ladder of information
  loss, and how far down it you stepped only became visible when you
  tried to restore the emoji after a model call. The help page gains the
  table: `"shortcode"` is the only rewriting policy that round-trips
  (losslessly, including skin tones, flags, ZWJ sequences, keycaps and
  `U+FE0F` forms), `"placeholder"` keeps *where* but not *which*, and
  `"strip"` keeps neither.

- **232 of the catalogue’s 2501 zero-width-joiner sequences were
  detected as their component emoji rather than as one emoji.** The
  repair that rejoins sequences the upstream regex does not know
  required the gap between two matches to be exactly one joiner. In a
  sequence whose middle component is a text-presentation code point,
  that component is not matched either, so the gap is
  `ZWJ + component + ZWJ` and the rule declined. The damage was a
  *wrong* count, not a missing one — `🚶` `U+200D` `U+2640` `U+200D`
  `U+27A1` `U+FE0F`, “woman walking facing right”, arrived as two emoji,
  “person walking” and “right arrow”, neither of which the text
  contains, and most of the 232 are 2023-2024 additions. The repair now
  also merges when the gap holds a joiner and the union of the two spans
  is itself a catalogued emoji: exact, so it can only join code points
  that really do spell one emoji, and the original rule still covers
  everything the catalogue has not heard of. 2499 of the 2501 now detect
  as one glyph; the two that do not are unqualified spellings whose
  every component needs `U+FE0F`, and their qualified forms are found.
  This changes `.emoji_n`, frequency tables and every count derived from
  them for corpora containing these sequences.

  A second, subtler form of the same defect needed a second rule. Both
  merge rules need *two* matches to work with, and a sequence whose only
  detectable component is one of its parts yields a single match — so
  there was no pair to merge and the sequence arrived as that part.
  `U+2764 U+200D U+1F525` (“heart on fire”) with its selectors omitted
  read as `U+1F525` (“fire”), and `U+1F9D4 U+200D U+2642` (“man: beard”)
  as “person with beard”. Counting glyphs cannot see this — one match is
  still one glyph — so the test for it looks for a joiner left *outside*
  every detected span. A lone match beside such a joiner is now grown
  outwards while the span stays a catalogued emoji, bounded by the
  longest catalogued emoji (10 code points), never crossing a
  neighbouring match, and skipped entirely unless the string actually
  has an orphaned joiner.

  Together the three rules take exact detection of the reference table
  from **80.1% to 95.8%** and orphaned joiners from **793 to 2** — the
  two being spellings with no detectable component at all, both of which
  have a canonical form that is found. Well-formed text costs about 6%
  more; text that was broken now costs more and is right.

- [`emoji_dfm()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_dfm.md)
  names one column per emoji glyph, so a `doc_id` column named with one
  of those glyphs was overwritten by the count column and the document
  identifiers vanished without a word. It is now an error that says
  which column to rename.

- **[`emoji_categorize()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_categorize.md)
  silently dropped rows that do contain emoji.** It filtered on
  `.emoji_category` being non-`NA`, and that column is `NA` for two
  different reasons: the row has no emoji, or the row’s emoji are not in
  the reference table. The second case is real and grows with every
  Unicode release — detection is grapheme-aware, so a zero-width-joiner
  sequence newer than your installed is found as one emoji but cannot be
  categorised — and those rows vanished from the result. 0.2.1 fixed one
  instance of this (a `U+FE0F`-qualified heart went missing) by
  repairing that particular join; the conflation behind it survived. The
  filter is now on “contains at least one emoji”, so such a row is kept
  with `.emoji_category = NA`, and `nrow(emoji_categorize())` now always
  equals `nrow(emoji_filter())`.

- **[`emoji_risk()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_risk.md)
  treated the same row two ways.** A row holding emoji the ambiguity
  lexicon cannot score — anything added to Unicode after 2015 —
  correctly got `.emoji_n_scored = 0`, but `.emoji_n_ambiguous = NA`,
  where the count of ambiguous glyphs found is genuinely zero. The
  `@return` had promised `NA` only for rows with no emoji at all, so the
  documentation was right and the code was wrong.
  `.emoji_ambiguity_mean` and `.emoji_ambiguity_max` stay `NA` there,
  because there is nothing to average.

- `emoji_key()`, the codepoint key every glyph-to-metadata join goes
  through, had two “no key here” values: `NA` for empty or missing
  input, but `""` for a string made of nothing but variation selectors.
  Every consumer had to remember to filter both. It is now `NA` in all
  three cases; a lexicon row whose glyph is a stray `U+FE0F` is ignored
  rather than keyed on `""`.

- [`?emoji_sanitize`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sanitize.md)’s
  reversibility claim is now measured rather than asserted, and the
  measurement is stronger than the old wording: for all 3790 emoji in
  their canonical spelling — the spelling a keyboard emits — the
  `"shortcode"` round trip **returns the original text byte for byte,
  100% of the time**. Feed it one of Unicode’s shorter spellings, with
  the `U+FE0F` selectors omitted, and it returns the canonical one
  instead; across all 4853 catalogued spellings that is 79.5%
  byte-identical, with every difference being `U+FE0F` alone and never
  more. Tests assert the exact claim rather than a byte-identity
  threshold, because that rate falls each time detection improves — a
  spelling that used to fragment now merges and normalises.

- **The lexicon coverage ceilings are now on the help pages, with the
  right denominator.**
  [`emoji_emotion()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_emotion.md)
  can score 150 glyphs — about **4%** of the 3790 distinct emoji
  tidyEmoji can detect — and
  [`emoji_sentiment()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sentiment.md)
  about **19%**, with nothing added to Unicode after 2015. A user who
  does not know that reads a column of `NA` as “no emotional content”
  rather than “not in the lexicon”. Both verbs and both dataset pages
  now state the figure, name the
  [emoji](https://emilhvitfeldt.github.io/emoji/) version it is computed
  against, and point at `.emoji_n_scored` as the per-row answer. (The
  internal roadmap had quoted 3.0% and 19.2% against the reference
  table’s 5042 *rows*; the table stores the qualified and unqualified
  forms of an emoji separately, so the denominator is 3790 distinct
  codepoint keys.)

- [`?emoji_emotion`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_emotion.md)
  and
  [`?emoji_emotion_label`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_emotion_label.md)
  named fewer columns than they return: the eight emotion columns and
  the `.emoji_n` / `.emoji_n_scored` counts were missing, and the
  completely different shape of `long = TRUE` (one row per row *per
  emotion*) was not in the `@return` at all.

- `README.md` is now byte-for-byte what `README.Rmd` renders to, so it
  cannot drift from its source unnoticed.

- **The lexicon registry accepted two registrations it could never
  honour.** `register_emoji_lexicon("novak2015", ...)` succeeded, showed
  up in
  [`emoji_lexicons()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_lexicons.md)
  as a second row with the same `name`, and was then unreachable,
  because a bundled name resolves before the registry is consulted — so
  `lexicon = "novak2015"` still got the bundled table. All six bundled
  names are now refused with the list of them. And a lexicon with no
  usable score column registered happily and only failed at first use,
  from inside
  [`emoji_score()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_score.md),
  in a message naming `tbl` — an argument of a call that had long since
  returned; the score column is resolved at registration. An `NA` name
  is rejected too.

- **The detection contract is now on the help pages.** Code points that
  are emoji only when they carry `U+FE0F` — the bare heart `U+2764`
  being the one people meet — are not detected, which was documented on
  [`?emoji_sentiment_lexicon`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sentiment_lexicon.md)
  but nowhere a user counting emoji would look.
  [`?tidyEmoji`](https://pursuitofdatascience.github.io/tidyEmoji/reference/tidyEmoji-package.md)
  gains a *Detection* section with the measured size of the exclusion
  (1252 of 5042 catalogue emoji carry `U+FE0F`; 216 of those are
  undetectable without it), the reason the default does not change
  (`U+00A9`, `U+00AE` and `U+2122` are in the same set), and the fact
  that it affects detection only and never the `U+FE0F`-stripped join.
  The `.emoji_*` prefix is documented as reserved: a verb overwrites a
  column of its own output name without warning, which is what makes the
  verbs chainable.

- **`emoji_dfm(doc_id = )` no longer orders its rows by the session’s
  collation.** Documents were grouped with
  [`factor()`](https://rdrr.io/r/base/factor.html), whose levels are
  sorted with the locale’s collation, so the row order of the result
  could differ between machines — the same class of bug 0.3.0 fixed for
  glyph ordering in
  [`emoji_pairs()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_pairs.md)
  and the dfm’s columns. Documents now appear in the order their id is
  first seen in the data.
  [`emoji_pairs()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_pairs.md),
  [`emoji_cooccurrence()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_cooccurrence.md)
  and
  [`emoji_dfm()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_dfm.md)
  share one grouping helper, so they cannot drift apart again.

- `emoji_sanitize(policy = "strip")` tidies only the whitespace left
  behind by a removed glyph, and only on rows that actually contained
  one.

- **Arguments given nonsense now error instead of quietly returning a
  different answer.** An audit of every argument that reaches a base R
  function without validation found one shape of bug repeated across the
  package: a value the function cannot honour was absorbed rather than
  rejected. `emoji_to_text(wrap = )` now requires the `{x}` placeholder,
  since a template without it replaces every emoji with the same literal
  string; `top_n_emojis(n = )` rejects a negative `n`, which
  [`head()`](https://rdrr.io/r/utils/head.html) had silently read as
  “drop the last row”; and every `TRUE`/`FALSE` argument
  (`emoji_pairs(directed = , sort = )`,
  `emoji_cooccurrence(diagonal = )`, `emoji_emotion(long = )`,
  `emoji_context(keep_text = )`, `top_n_emojis(duplicated = )`,
  `emoji_sentiment(se = )`) is now checked, because
  [`isTRUE()`](https://rdrr.io/r/base/Logic.html) reads every non-`TRUE`
  value as `FALSE` — so `long = "yes"` used to return the wide form
  without complaint. The deprecated
  `top_n_emojis(duplicated_unicode = "yes")` still works: the check runs
  after the lifecycle conversion.

- [`emoji_score()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_score.md)
  gains the `lexicon = "novak2015"` default that
  [`emoji_sentiment()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sentiment.md)
  always had, so calling it without a lexicon works instead of raising a
  missing-argument error.

- The reference-manual sources are ASCII throughout, so the PDF manual
  builds everywhere.

- `next_release.md`, the repo’s release ledger, gains a section 13
  recording what wave 1 shipped, the third-audit defect, and the design
  decisions locked at implementation.

- Emoji-dense rows no longer cost quadratic time. Five hot paths reached
  a character offset with
  [`substr()`](https://rdrr.io/r/base/substr.html)/[`substring()`](https://rdrr.io/r/base/substr.html),
  which rescans a multi-byte string from its first byte on every call,
  so the work grew with the square of the emoji in a row: glyph slicing
  (used by nearly every verb), the splice in the translation verbs, the
  residual test in
  [`emoji_ratio()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_ratio.md),
  the trailing-run walk-back behind
  [`emoji_incongruity()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_incongruity.md),
  and the per-occurrence window loop in
  [`emoji_context()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_context.md),
  which handed the whole prefix and suffix to a windowing function that
  only ever needed the few tokens next to the glyph. The four that cut
  text around glyph spans now share one helper that converts the string
  once and slices code points past a threshold, keeping ordinary rows on
  the existing path;
  [`emoji_context()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_context.md)
  reads a bounded slice anchored at the glyph. Measured on a row holding
  6400 emoji:
  [`emoji_ratio()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_ratio.md)
  about thirteen times faster,
  [`emoji_summary()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_summary.md)
  and
  [`emoji_sentiment()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sentiment.md)
  about ten, the trailing-run walk-back about seven,
  [`emoji_context()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_context.md)
  about four, and every stage of the engine now scales linearly. Results
  are unchanged – the fast paths are pinned to the slow ones by tests
  that compare them directly, and fall back whenever
  [`utf8ToInt()`](https://rdrr.io/r/base/utf8Conversion.html) cannot
  represent the string.

## tidyEmoji 0.3.0

CRAN release: 2026-08-04

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
- Relational analysis.
  [`emoji_pairs()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_pairs.md)
  returns a tidy, graph-ready edge list (`item1`, `item2`, `n`) of the
  emoji that co-occur in the same document — each row is a document, or
  supply `doc_id` to pool rows — with `directed = TRUE` to order pairs
  by first appearance.
  [`emoji_cooccurrence()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_cooccurrence.md)
  is the same with an optional `diagonal` (each emoji’s document
  frequency).
  [`emoji_ngrams()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_ngrams.md)
  slides a window over each row’s emoji in reading order and returns one
  row per consecutive n-gram.
- Structural metrics.
  [`emoji_position()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_position.md)
  reports where emoji sit in each text (first/last character position
  and mean relative position in `[0, 1]`),
  [`emoji_density()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_density.md)
  reports emoji per character and per token, and
  [`emoji_ratio()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_ratio.md)
  reports the share of the text’s characters that are emoji plus an
  `.emoji_only` flag.
- [`emoji_dfm()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_dfm.md)
  builds a document-by-emoji feature table (weightings: counts, binary,
  tf-idf), keeping every document — including emoji-free ones — so the
  result binds row-for-row to outcome columns in modelling workflows.
- The corpus-level verbs above
  ([`emoji_pairs()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_pairs.md),
  [`emoji_cooccurrence()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_cooccurrence.md),
  [`emoji_ngrams()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_ngrams.md),
  [`emoji_dfm()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_dfm.md))
  canonicalise glyphs through the package’s codepoint key, so qualified
  and unqualified forms of the same emoji (for example the victory hand
  with and without `U+FE0F`) count as one node/feature.
  [`emoji_frequency()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_frequency.md)
  intentionally still reports the exact extracted glyph.
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
- tidyEmoji has a hex logo! It appears in the README and on the pkgdown
  site (`man/figures/logo.svg` is the vector master, `logo.png` the
  raster copy).

### Improvements and fixes

- **Grapheme-aware detection now covers newer zero-width-joiner
  sequences.** The upstream emoji regex only knows the ZWJ sequences
  that were current when it was built, so it reported later ones — face
  exhaling, face with spiral eyes, heart on fire, people holding hands,
  the skin-toned handshakes, “woman: blond hair”, and around 630 others
  — as their *component* emoji. tidyEmoji now re-joins them (a ZWJ
  between two emoji always binds them into one grapheme cluster).
  Previously such an emoji inflated counts, resolved to the wrong name,
  split into several co-occurrence nodes and stopped
  [`emoji_ratio()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_ratio.md)
  recognising an emoji-only row; all of that is fixed. Emoji separated
  by anything other than a ZWJ are unaffected.
- Extraction and location are now sliced from the same spans, so no verb
  can disagree with another about where an emoji starts and ends.
- [`text_to_emoji()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/text_to_emoji.md)
  no longer misses a `:shortcode:` that follows an unrelated colon.
  `"meet at 10:30 :grinning:"` and `"https://example.org :grinning:"`
  previously came back unchanged, because the permissive `:...:` pattern
  consumed the shortcode’s opening colon; shortcode tokens are now
  matched on the character set GitHub-style aliases actually use.
- [`emoji_pairs()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_pairs.md)
  and
  [`emoji_dfm()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_dfm.md)
  order glyphs in the C locale, so which glyph lands in `item1` and the
  order of a dfm’s tied columns no longer depend on the session’s
  collation. Results are now reproducible across machines.
- [`emoji_lexicons()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_lexicons.md)
  no longer reports the glyph column as a score dimension for a lexicon
  registered with a `by` other than `"emoji"`.
- `emoji_emotion(long = TRUE)` no longer drops a user column named
  `.row_number`.
- `emoji_ngrams(n = Inf)` gives the documented error instead of a
  coercion warning followed by “missing value where TRUE/FALSE needed”.
- [`emoji_to_text()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_to_text.md)
  is several times faster: it locates emoji once for the whole column
  rather than once per row.
- [`emoji_density()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_density.md)
  returns `.emoji_per_token = 0` (not `NA`) for whitespace-only text,
  matching `.emoji_per_char` and the documented “no emoji -\> 0”
  contract
  ([\#1](https://github.com/PursuitOfDataScience/tidyEmoji/issues/1)).
- [`as_emoji()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/as_emoji_name.md)
  accepts the spaced Unicode names produced by
  [`as_emoji_name()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/as_emoji_name.md)
  (routing through the reference table), so `as_emoji(as_emoji_name(x))`
  round-trips instead of returning `NA`
  ([\#2](https://github.com/PursuitOfDataScience/tidyEmoji/issues/2)).
- [`?emoji_sentiment_lexicon`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sentiment_lexicon.md)
  now explains which lexicon entries are stored as unqualified,
  text-presentation code points (the bare heart `U+2764` without
  `U+FE0F`, the white smiling face, the heavy check mark, …) and are
  therefore not detected in text, and notes that the qualified form
  resolves to the same entry
  ([\#3](https://github.com/PursuitOfDataScience/tidyEmoji/issues/3)).
- The help pages no longer embed raw emoji glyphs, so the reference
  manual builds as PDF;
  [`?register_emoji_lexicon`](https://pursuitofdatascience.github.io/tidyEmoji/reference/register_emoji_lexicon.md)
  no longer points at an internal development file.
- [`emoji_search()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_search.md)
  matches literally, so queries containing regex metacharacters (for
  example the `+1` alias) are safe and cannot error.
- `emoji_to_text(format = "shortcode")` now always emits the emoji’s
  canonical (first) GitHub-style alias — the same one reported by
  [`emoji_frequency()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_frequency.md)
  and
  [`as_emoji_shortcode()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/as_emoji_name.md)
  — and the `wrap` template is honoured. Emoji with no known
  name/shortcode are left in place rather than dropped from the text.
- [`emoji_to_text()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_to_text.md)
  and
  [`text_to_emoji()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/text_to_emoji.md)
  keep `NA` text entries as `NA`.
- [`emoji_emotion()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_emotion.md)
  and
  [`emoji_emotion_label()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_emotion_label.md)
  accept registered or data-frame emotion lexicons (any subset of the
  eight Plutchik dimensions), not just the bundled `"emotag1200"`.
- Registered lexicons resolve through their stored normalised key, so
  `register_emoji_lexicon(by = )` works with any glyph column name in
  [`emoji_sentiment()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sentiment.md)
  and
  [`emoji_emotion()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_emotion.md).
- [`emoji_frequency()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_frequency.md)
  (and therefore
  [`top_n_emojis()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/top_n_emojis.md))
  breaks count ties by the glyph, making the output order deterministic.
- [`emoji_lexicons()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_lexicons.md)
  no longer lists a custom lexicon’s glyph/key columns among its score
  dimensions.
- The package help page
  ([`?tidyEmoji`](https://pursuitofdatascience.github.io/tidyEmoji/reference/tidyEmoji-package.md))
  documents the output and naming contract shared by all verbs.
- rlang moved from Suggests to Imports (tidy-eval capture of the new
  optional `doc_id` argument); it was already a hard transitive
  dependency, so the installed footprint is unchanged.
- Grouped data frames passed to
  [`emoji_pairs()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_pairs.md),
  [`emoji_cooccurrence()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_cooccurrence.md)
  or
  [`emoji_dfm()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_dfm.md)
  warn that grouping is ignored — use `doc_id` to express per-group
  structure.
- The vignette header no longer carries a build date.
- DESCRIPTION Title and Description broadened to cover emotions,
  translation, search, co-occurrence, structural metrics and feature
  tables; version bumped to 0.3.0.

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
