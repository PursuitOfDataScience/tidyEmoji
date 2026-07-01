# tidyEmoji — Roadmap for the Next Release(s)

*Planning document, written after the 0.2.0 CRAN submission. It is intentionally
ambitious and broad: it captures both the **new capabilities** worth building and
a **maintenance audit** of the shipped 0.2.0 code — every bug, inconsistency and
improvement found by reading the source. Not everything here ships at once; see
the phased plan in §9. This file is build-ignored and is not part of the
package.*

---

## 0. TL;DR — what to do next

1. **Ship a 0.2.1 patch first** that fixes the correctness bugs found in the
   0.2.0 audit (§4). The headline issue is a *key-normalisation asymmetry*:
   sentiment joins are codepoint-normalised but name/category/shortcode joins are
   exact-glyph matches, so qualified vs. unqualified emoji (the `U+FE0F`
   variation selector) can silently lose their name/category — and in
   `emoji_categorize()` the whole row is dropped, while in
   `top_n_emojis(duplicated = TRUE)` the emoji vanishes entirely. This is a
   real, user-visible inconsistency, not a theoretical one.
2. **Then build features** in the phased order of §9, leading with the
   high-value / low-risk affect + translation + relational work.
3. **Keep docs in lockstep.** `NEWS.md` for 0.2.0 is verified accurate (§4.12);
   the README, lifecycle badge and DESCRIPTION Title now lag the repositioning
   and must be refreshed (§4.12, §8.2). Every new verb gets a vignette home
   *before* it ships — see the coverage matrix (§8.3) and per-release NEWS drafts
   (§8.1) so each release's changelog accurately reflects the work.

---

## 1. Vision

tidyEmoji 0.2.0 turned the package into a **tidy toolkit for emoji in any text**:
detect, filter, extract, count, categorise, and valence-score emoji, returning
data frames that compose with the tidyverse. The next phase should make
tidyEmoji the **de-facto analytical layer for emoji in R** — the place you reach
for once you have emoji in a column and want to *understand* them.

The organising idea is a pipeline of capabilities, each tidy and composable:

```
detect → extract → enrich → relate → measure → represent → integrate
         (glyphs)   (meaning) (pairs)  (metrics)  (visuals)   (ML / ecosystem)
```

0.2.0 covers *detect/extract* and the first slice of *enrich* (valence). The
roadmap fills in the rest: richer affect (emotions, multiple lexicons),
translation/accessibility, relational analysis (co-occurrence, sequences,
networks), modifier/diversity/representation analysis, geography (flags),
structural metrics (position, density, richness), metadata/QA, machine-learning
features, visualization, and deep ecosystem integration.

### How we stay distinct

| Package | Role | tidyEmoji's relationship |
|---|---|---|
| **emoji** (Hvitfeldt) | vector-level engine: detect/extract/replace, the emoji table | We *build on it*; never duplicate its vector verbs. |
| **EmojiSentR** | a black-box `sentiment_analysis()` pipeline (emoji + words + VADER) | We provide *composable building blocks*, not a monolithic pipeline; users combine our tidy outputs with tidytext/sentimentr/VADER as they wish. |
| **tidytext** | word tokenisation & lexicons | We are the emoji-shaped analogue and integrate with it (`emoji_tokens()` already mirrors `unnest_tokens()`). |
| **emojifont / ggimage / ragg** | rendering glyphs in plots | We provide the *data* (twemoji image handles, tidy frames) to drive them. |

Guiding principle: **be the building blocks, not the black box.**

---

## 2. Design principles to preserve

1. **Tidy & composable.** `verb(data, text, ...)` → tibble; unquoted column
   selection; respect grouped data frames; never force a monolithic workflow.
2. **Grapheme-aware & correct.** Continue delegating detection/extraction to
   `emoji::emoji_extract_all()` so ZWJ sequences and skin-tone modifiers stay
   intact.
3. **Don't reinvent the dependency.** No vector-level re-implementations of what
   `emoji` already exports.
4. **Lexicons are data with provenance.** Every bundled lexicon has a `data-raw/`
   builder, a documented source, and a clear licence. Lexicons should be
   *pluggable* (see §6).
5. **Light core, heavy optional.** Keep `Imports` lean; push `igraph`, `ggimage`,
   embeddings, etc. to `Suggests` or optional downloads.
6. **CRAN-clean & documented.** Keep `R CMD check` green; one focused vignette
   per major workflow.
7. **One canonical join key.** *(New.)* Every glyph → metadata/score join must go
   through the same codepoint-normalised key (`emoji_key()`), so that qualified
   and unqualified forms resolve identically everywhere. The 0.2.0 audit (§4)
   shows what happens when this principle is applied inconsistently.

---

## 3. Where 0.2.0 stands (baseline)

Exported verbs: `emoji_summary()`, `emoji_filter()`/`emoji_tweets()`,
`emoji_frequency()`, `top_n_emojis()`, `emoji_extract_nest()`,
`emoji_extract_unnest()`, `emoji_tokens()`, `emoji_categorize()`,
`emoji_sentiment()`.
Data: `emoji_unicode_crosswalk`, `category_unicode_crosswalk`,
`emoji_sentiment_lexicon` (Emoji Sentiment Ranking, valence).
Engine: cached one-row-per-glyph reference from `emoji::emojis`; codepoint
normalisation for robust joins.

The internals (`emoji_reference()`, `emoji_key()`, `emoji_glyph_list()`,
`emoji_sentiment_map()`) already provide most of what the new verbs need — but
several of the public verbs bypass `emoji_key()` and join on the raw glyph; see
§4.

---

## 4. Maintenance audit — bugs & improvements in the shipped 0.2.0 code

Found by reading `R/`, `tests/`, `data-raw/` and the vignette. Each item lists
the location, the problem, the impact, and the proposed fix. Severity:
🔴 correctness (can return wrong/missing data) · 🟠 inconsistency / footgun ·
🟡 polish / performance. Items marked **(verify)** should be confirmed against an
installed `emoji` package before fixing, but the underlying asymmetry is
structural in the code.

### 4.1 🔴 Key-normalisation asymmetry — the central bug *(verify)*

`emoji_sentiment_map()` and `emoji_sentiment()` join glyph → score through
`emoji_key()`, which strips the `U+FE0F` variation selector so qualified text
("❤️", `U+2764 U+FE0F`) matches the unqualified lexicon entry ("❤", `U+2764`).
This is correct and even has a dedicated regression test
(`tests/testthat/test-sentiment.R:11`). **But every other glyph → metadata join
uses an exact-glyph match against `emoji::emojis$emoji` (or the crosswalk),
*without* normalisation:**

- `R/emoji-extraction.R:67` — `emoji_tokens()`: `match(out$.emoji, ref$emoji)`
  for `.emoji_name` and `.emoji_category`.
- `R/emoji-summary.R:26` — `emoji_frequency()`: `match(counts$emoji, ref$emoji)`
  for `name`, `shortcode`, `group`.
- `R/emoji-categorize.R:20` — `emoji_categorize()`: `setNames(ref$group,
  ref$emoji)` then `cat_of[g]`.
- `R/top-n-emojis.R:68` — `top_n_emojis(duplicated = TRUE)`: `inner_join(...,
  by = "unicode")` against `emoji_unicode_crosswalk`.

**Why it bites.** The existing sentiment test *proves* that extraction yields a
different qualification form than the reference/lexicon path needs normalising —
otherwise that test would be unnecessary. So wherever an extracted glyph's
qualification differs from `emoji::emojis$emoji`, the exact-match joins return
`NA` even though the emoji is perfectly well known. Concretely:

- `emoji_tokens()` / `emoji_frequency()`: emoji with a mismatch get **`NA`
  name/category** while still being scored for sentiment — internally
  inconsistent output for the *same glyph*.
- `emoji_categorize()`: a row whose only emoji fail the exact match yields an
  empty category set → the row is **dropped entirely** (`out[!is.na(cats), ]`),
  even though `emoji_summary()`/`emoji_filter()` correctly say it contains emoji.
- `top_n_emojis(duplicated = TRUE)`: an `inner_join` **silently drops** any
  affected glyph from the leaderboard.

**Fix.** Build one cached, key-indexed reference (extend `emoji_reference()` with
an `emoji_key` column, or add `emoji_reference_by_key()`), and route *all* joins
through it — `match(emoji_key(x), ref$key)` rather than `match(x, ref$emoji)`.
Add regression tests mirroring the sentiment one (a qualified glyph must get a
non-`NA` name/category and survive `emoji_categorize()`).

### 4.2 🟠 Two different detection code paths can disagree

`emoji_summary()` and `emoji_filter()` use `emoji::emoji_detect()`
(`R/emoji-summary.R:21`, `:43`), while every other verb derives presence from
`emoji::emoji_extract_all()` via `emoji_glyph_list()`. If `emoji_detect()` ever
flags a string from which `emoji_extract_all()` extracts nothing (or vice
versa), `emoji_summary()$emoji_tweets` will not equal the number of rows that
survive `emoji_tokens()` / `emoji_categorize()`. **Fix:** define presence once as
`lengths(emoji_glyph_list(x)) > 0L` and have the summary/filter verbs use it, so
the whole package agrees on "what counts as having an emoji." (Add a test
asserting `emoji_summary()$emoji_tweets == nrow(distinct rows of
emoji_tokens())`.)

### 4.3 🔴 Grouped data frames are silently ignored

`emoji_summary()`, `emoji_frequency()` and `top_n_emojis()` `pull()` the whole
column and summarise globally, discarding any `group_by()`. A user who writes
`df |> group_by(author) |> emoji_frequency(text)` gets a **single global table
with no warning** — a silently wrong answer, not just a missing feature. **Fix
(0.2.x):** at minimum detect `dplyr::is_grouped_df(data)` and either honour the
grouping (return per-group results) or `rlang::warn()` that grouping is ignored.
Full grouped-aware semantics are the 1.0 goal (§5J), but the silent-wrong-answer
case should be closed sooner.

### 4.4 🟠 Twitter-era naming holdovers

The package is now "emoji in *any* text," but:

- `emoji_summary()` returns columns **`emoji_tweets` / `total_tweets`**
  (`R/emoji-summary.R:23-24`); the vignette's inline prose depends on them
  (`vignettes/introduction.Rmd:95`).
- `emoji_tweets()` is exported as a synonym for `emoji_filter()`.

These read oddly for product reviews, chat logs, surveys. **Fix:** rename the
columns to neutral names (e.g. `n_with_emoji` / `n_total`, or `n_emoji` /
`n_total`) and keep the old names available for one cycle. `emoji_tweets()` is
already documented as a back-compat synonym; mark it `lifecycle::deprecated()`
(soft) so the canonical name is `emoji_filter()`. Use the `lifecycle` machinery
already in `Imports`.

### 4.5 🟠 Inconsistent output column names across verbs

The same concept appears under different names/casings:

| Concept | `emoji_frequency()` | `top_n_emojis()` | `emoji_tokens()` | `emoji_categorize()` |
|---|---|---|---|---|
| glyph | `emoji` | `unicode` | `.emoji` | — |
| name/shortcode | `name`, `shortcode` | `emoji_name` | `.emoji_name` | — |
| category | `group` | `emoji_category` | `.emoji_category` | `.emoji_category` |

There *is* a defensible convention hiding here — dotted prefixes (`.emoji_*`) for
columns *added to user data*, bare names for *new summary tibbles* — but the bare
names themselves are inconsistent (`emoji` vs `unicode`, `group` vs
`emoji_category`). **Fix:** write the convention down (a short "naming & output
contract" in a dev doc / `?tidyEmoji`), pick one term per concept (recommend
`group` everywhere the Unicode top-level category is meant, since that's what
`emoji::emojis` calls it), and migrate with `lifecycle` warnings where a public
column is renamed.

### 4.6 🟠 `top_n_emojis()` — `n` semantics and dropped emoji in `duplicated` mode

`R/top-n-emojis.R:78` applies `utils::head(out, n)` *after* the many-to-many
join. With `duplicated = TRUE` a single glyph occupies several rows, so:

- `n` counts **rows, not distinct emoji** — `top_n_emojis(df, text, n = 20,
  duplicated = TRUE)` can return far fewer than 20 distinct emoji.
- Ties on `n` aren't broken deterministically, so a glyph's multiple-name rows
  can be split across the `head()` cutoff.
- Glyphs **without** a GitHub alias are dropped by the `inner_join` in
  `duplicated` mode, yet kept (`shortcode = NA`) in the default mode — an
  inconsistency on top of 4.1.

**Fix:** decide whether `n` means "n emoji" or "n rows" (recommend: n distinct
emoji, take the head of the de-duplicated frequency first, *then* expand names);
use `left_join` (not `inner_join`) so alias-less emoji survive; add a stable
secondary sort key (e.g. the glyph) for deterministic ties.

### 4.7 🟠 `emoji_sentiment()` — `.emoji_n` vs. the count actually scored

`emoji_sentiment()` reports `.emoji_n` = total emoji in the row
(`R/emoji-sentiment.R:30`) but averages with `na.rm = TRUE` over only the
lexicon-covered subset. A row with three emoji where one is in the lexicon shows
`.emoji_n = 3` and a mean computed from one glyph — silently misleading. The
vignette itself works around this by recomputing `n_scored`
(`vignettes/introduction.Rmd:340`). **Fix:** add `.emoji_n_scored` (number of
emoji that contributed to the mean) and document the distinction; optionally a
`coverage = .emoji_n_scored / .emoji_n` helper.

### 4.8 🟡 Vignette data is a CSV misnamed `.rda`, and it's large

`vignettes/ata_tweets.rda` is, despite its extension, a **752 KB CSV** (it's read
with `readr::read_csv("ata_tweets.rda")`, `vignettes/introduction.Rmd:72`; `file`
reports "UTF-8 Unicode text"). Two problems: (a) the misleading extension is a
trap for the next maintainer; (b) a 752 KB sample shipped in the vignette source
inflates the CRAN tarball for no analytical benefit. **Fix:** rename to
`ata_tweets.csv`, and downsample to ~1–2k rows (the bar/histogram plots look
identical and the vignette builds faster on CRAN). Consider moving the example to
`inst/extdata/` and loading via `system.file()`.

### 4.9 🟡 Vignette is still framed around tweets

Narrative, the object name `ata_tweets`, and axis labels ("Number of tweets")
remain Twitter-specific even though 0.2.0 repositioned the package. **Fix:** lead
with a non-Twitter example (product reviews / support chat), or at least reframe
the labels; this also sets up the planned per-workflow vignettes (§8).

### 4.10 🟡 Minor robustness & performance

- **Per-row `emoji_key()`.** `emoji_sentiment()` calls `emoji_key()` inside a
  per-row `vapply` (`R/emoji-sentiment.R:25`), recomputing keys for repeated
  glyphs. Compute keys once over the *unique* glyph universe and look up — a real
  win on the "millions of rows" target (§5J). Same opportunity: a single cached
  key → {name, group, shortcode, sentiment} table feeds every verb (and fixes
  4.1 in one stroke).
- **`row_number` collision.** `emoji_extract_unnest()` emits an undotted
  `row_number` column (`R/emoji-extraction.R:37`); it can collide with a user
  column and shadows `dplyr::row_number`. Consider `.row` or `.row_number`.
- **`emoji_extract_nest()` return type.** It returns the input's class (a plain
  `mutate`, `R/emoji-extraction.R:17`) while sibling verbs coerce to tibble —
  minor inconsistency; document or align.
- **`emoji_filter()` drops grouping/class.** Returns `as_tibble(data[keep, ])`,
  silently dropping `group_by()` grouping and any non-tibble subclass. Fine for
  the tidy contract, but document it.
- **Session cache staleness.** `emoji_reference()` / `emoji_sentiment_map()`
  cache for the session; if a user upgrades/attaches a different `emoji` mid
  session the cache is stale. Negligible in practice; note it.

### 4.11 Testing gaps surfaced by the audit

Add before/with the fixes above: a name/category normalisation test (mirror the
sentiment FE0F test for `emoji_tokens`/`emoji_categorize`); a grouped-df test
(asserting either per-group output or a warning); a `top_n_emojis(duplicated =
TRUE)` test that an alias-less emoji survives and that `n` counts what we say;
and a cross-verb consistency test (`emoji_summary` count vs. distinct
`emoji_tokens` rows). Consider `goodpractice` and snapshot tests for the tidy
outputs.

### 4.12 🟠 Documentation drift — NEWS is accurate, but README/DESCRIPTION lag the repositioning

- ✅ **`NEWS.md` (0.2.0) is accurate.** Every claim was checked against the 0.1.1
  source via git: old verbs took `tweet_tbl`/`tweet_text`; detection built a
  `paste(emoji::emojis$emoji, collapse = "|")` mega-alternation (which *is* why a
  family emoji split into four people, and is the "multi-thousand-way regular
  expression" perf claim); `top_n_emojis()` scanned the text once per known emoji
  via `purrr::map(..., str_count)` and used an `inner_join` (the many-to-many
  warning); `emoji_tweets()` returned a plain data frame; `duplicated_unicode =
  "yes"/"no"` was the old argument. **No corrections needed** — keep this
  discipline going forward (§8.1).
- 🟠 **Lifecycle badge says "stable"** (`README.Rmd:23`, `README.md:11`) while the
  roadmap reaches lifecycle *stable* only at 1.0.0 (§9) and plans column
  renames / soft-deprecations on the way there. Downgrade to **"maturing"** (or
  "experimental") until 1.0, or the badge contradicts the plan. The package
  version (0.2.0) also argues against "stable."
- 🟠 **README prints soon-to-be-renamed columns.** The `emoji_summary()` example
  shows `emoji_tweets`/`total_tweets` (`README.md:53–56`) — exactly the names
  §4.4 retires. `README.md` is generated from `README.Rmd`, so **re-knit** (never
  hand-edit `README.md`) when the rename lands.
- 🟠 **DESCRIPTION Title/Description are narrow.** Title *"Discover, Count and
  Score Emoji in Text"* (`DESCRIPTION:3`) won't cover emotion, translation,
  networks, flags or embeddings. Broaden Title and Description as those features
  land — CRAN re-reviews Title/Description wording at each submission.
- 🟡 **Single, tweet-framed vignette** (`introduction.Rmd`) is the only long-form
  doc; see §4.9 and the coverage plan in §8.3.

---

## 5. Feature roadmap — proposed functions

Each item: motivation, proposed API, output, data/deps, effort (S/M/L), and
notes. Function names are proposals, open to bikeshedding.

### A. Affect enrichment: emotions + a pluggable lexicon framework

**Why.** 0.2.0 scores *valence* only (negative↔positive). Research and practice
want discrete **emotions**. EmoTag1200 (EMNLP 2020) gives human association
ratings for 150 popular emoji across the 8 Plutchik emotions (anger,
anticipation, disgust, fear, joy, sadness, surprise, trust), scores in [0, 1],
**MIT-licensed** — easy to bundle.

```r
# 8-emotion profile per row (mean over the row's emoji), tidy & wide
emoji_emotion(data, text, lexicon = "emotag1200")
#> # adds .emoji_joy, .emoji_trust, ... .emoji_anticipation (+ .emoji_n)

# long form: one row per (row, emotion)
emoji_emotion(data, text, long = TRUE)

# the dominant emotion per row, as a convenience
emoji_emotion_label(data, text)        #> adds .emoji_emotion (e.g. "joy")
```

**Pluggable lexicons.** Generalise the sentiment machinery into a small registry
so valence, emotion, and user-supplied lexicons share one mechanism:

```r
emoji_lexicons()                       # list bundled lexicons + metadata
emoji_sentiment(data, text, lexicon = "novak2015")   # default
emoji_score(data, text, lexicon = my_tbl, by = "emoji")  # bring-your-own
```

- New dataset: `emoji_emotion_lexicon` (EmoTag1200, MIT), built by
  `data-raw/emoji_emotion_lexicon.R`.
- Effort: **M** (data + tidy joins reuse `emoji_key()` — and the 4.1 fix means
  the join engine is already correct).
- Differentiation from EmojiSentR: we expose the *profiles*, not a single
  composite verdict; combining with word-level sentiment stays the user's choice
  (and we can document the recipe in a vignette).

**Optional stretch:** a valence/arousal/dominance lexicon if a suitably licensed
one exists; an opt-in `emoji_affect()` that returns valence + emotions together.

### B. Translation, conversion & accessibility

**Why.** Converting emoji ↔ names/shortcodes inline is one of the most common
emoji operations (Python's `emoji.emojize`/`demojize`), and replacing emoji with
words is essential for accessibility and as an **NLP normalisation** step before
tokenising. `emoji::emoji_replace_name()` exists at the vector level, but tidy,
column-oriented verbs with consistent output are missing.

```r
emoji_to_text(data, text, format = c("name", "shortcode"), wrap = ":{x}:")
#>  "great \U0001f600" -> "great :grinning:"   (NLP- and screen-reader-friendly)

text_to_emoji(data, text)              # ":grinning:" -> the glyph (emojize)

# vector helpers for ad-hoc use, delegating to {emoji} where possible
as_emoji_name(x); as_emoji_shortcode(x); as_emoji(x)
```

- Data/deps: `emoji::emojis` (names, aliases). Multilingual names are a stretch
  (see §7, CLDR).
- Effort: **S–M**. High everyday utility; strong vignette material
  (accessibility, preprocessing for text models).

### C. Relational analysis: co-occurrence, sequences, networks

**Why.** A rich research literature studies **which emoji appear together** and
**in what order** (co-occurrence networks, directed "EmojiNet" sequence graphs,
power-law structure, topic-specific clusters). None of this is available tidily
in R. This is a flagship, differentiating capability.

```r
# tidy edge list of co-occurring emoji within the same text (à la widyr)
emoji_pairs(data, text, doc_id = NULL, sort = TRUE)
#> columns: item1, item2, n   (undirected by default; directed = TRUE for order)

# alias / fuller form
emoji_cooccurrence(data, text, diagonal = FALSE)

# ordered sequences within a text
emoji_ngrams(data, text, n = 2)        #> columns: row, position, ngram
```

- Output is deliberately **graph-ready**: pipe `emoji_pairs()` straight into
  `igraph::graph_from_data_frame()` / `ggraph` / `tidygraph`, or correlate with
  `widyr::pairwise_*`.
- Deps: none required in core (return tidy frames); `igraph`/`ggraph` only in
  Suggests/vignette.
- Effort: **M**. Builds directly on `emoji_glyph_list()`.

### D. Modifiers, diversity & representation (research-grade)

**Why.** Skin-tone and gender modifiers are a major area of social-science
research (identity, self-representation, demographic signalling). The data is
fully recoverable from codepoints (Fitzpatrick modifiers U+1F3FB–U+1F3FF;
gender signs/ZWJ), but no R tool surfaces it.

```r
emoji_skin_tone(data, text)            # per emoji: none / light / ... / dark
#> uses the 5 Fitzpatrick modifiers; "default" when unmodified

emoji_gender(data, text)               # woman / man / neutral where applicable

emoji_components(data, text)           # decompose a ZWJ sequence into parts
#>  "\U0001F468‍\U0001F469‍\U0001F467‍\U0001F466" -> man, woman, girl, boy

# corpus/document diversity indices
emoji_diversity(data, text, index = c("richness", "shannon", "skin_tone"))
#>  lexical richness, Shannon entropy of the emoji distribution, and a
#>  skin-tone diversity index for representation studies
```

- Deps: none (codepoint logic + the reference table). Effort: **M–L**.
- Sensitivity: document these as *descriptive* measures; avoid inferring
  identity. Cite the literature and frame carefully in the vignette.

### E. Geography: flags ↔ countries

**Why.** Flags are ~258 sequences and a whole emoji category; mapping them to
countries unlocks geographic analysis of emoji-bearing text. Regional-indicator
pairs map deterministically to ISO 3166-1 alpha-2 (offset 127397, **confirmed**:
`intToUtf8(utf8ToInt("🇺🇸") - 127397)` → `"US"`), and a small ISO table supplies
names/regions.

```r
emoji_flag_to_country(x)               # 🇺🇸 -> list(code="US", name="United States")
country_to_flag(x)                     # "US" / "United States" -> 🇺🇸
emoji_is_flag(x)                       # logical

# enrich flag emoji within a column
emoji_flags(data, text)                #> rows of flags with code, name, region
```

- Note: also handle subdivision flags (England/Scotland/Wales use tag sequences,
  not regional indicators) and the non-country regional flags (EU, UN) — these
  are the edge cases the simple offset arithmetic does *not* cover.
- Data: a compact bundled ISO 3166 table (or reuse {ISOcodes} via Suggests).
- Effort: **S–M**. Deterministic, well-specified.

### F. Structural & intensity metrics

**Why.** *How* emoji are used matters: position in the message (the Emoji
Sentiment Ranking already tracks mean position), emoji-to-text ratio, and
"emoji-only" messages are all studied signals.

```r
emoji_position(data, text)             # first/last index, mean relative position (0–1)
emoji_density(data, text)              # emoji per token and per character
emoji_ratio(data, text)               # share of graphemes that are emoji; is_emoji_only
```

- Effort: **S**. Pure computation over `emoji_glyph_list()` + token counts.

### G. Metadata & content QA

**Why.** `emoji::emojis` carries underused metadata: Unicode `version`,
per-vendor support (`vendor_apple`, `vendor_google`, …), `keywords`, and
qualification status. These power practical QA and search.

```r
emoji_version(data, text)              # Unicode version per emoji (recency / compatibility)
emoji_vendor_support(data, text, vendor = "google")  # will it render there?
emoji_search("happy")                  # keyword/concept search -> tibble of matches
emoji_lookup(x)                        # everything we know about a glyph, tidily
```

- "How modern are these emoji?" and "will these render on platform X?" are real
  content-moderation / publishing questions.
- The qualification status surfaced here is also a natural home for diagnostics
  related to the 4.1 normalisation work.
- Effort: **S–M** (mostly surfacing existing columns).

### H. Machine-learning feature engineering

**Why.** Emoji are strong, compact features for text classification, but turning
them into model-ready matrices is manual today.

```r
# document × emoji count matrix (wide tibble or sparse Matrix), tidymodels-ready
emoji_dfm(data, doc_id, text, weighting = c("count", "binary", "tfidf"))

# semantic similarity & neighbours via emoji2vec (MIT, 300-dim, all emoji)
emoji_similarity(x, y)                 # cosine similarity between glyphs
emoji_nearest(x, n = 5)                # nearest emoji in embedding space
```

- emoji2vec is MIT-licensed but a few MB → **do not bundle**; ship via a small
  `Suggests`-gated download helper (`emoji_download_embeddings()`), à la
  `textdata`. Effort: **M** (dfm) / **L** (embeddings infra).
- `emoji_dfm()` alone is a high-value, low-risk addition.

### I. Visualization

**Why.** Plotting *actual emoji* is perennially awkward in R. We can supply the
data layer that the good rendering tools (ggimage, ragg, emojifont) consume.

```r
emoji_image(x, set = "twemoji")        # vector of PNG URLs/paths for ggimage::geom_image
emoji_label(x)                         # safe labels (name fallback when glyph won't render)
# optional sugar:
geom_emoji(...)                        # thin wrapper over ggimage for emoji-as-points
scale_*_emoji()                        # emoji glyphs on an axis
```

- Twemoji (CC-BY) gives consistent, license-clean glyph images across platforms
  (the approach Emil Hvitfeldt documents). Deps: `ggimage`/`ggplot2` in Suggests.
- Effort: **M**. Big "wow" factor for the vignette and README.

### J. Ecosystem integration & performance

- **tidytext / widyr / quanteda / tidymodels**: ensure outputs slot in;
  document joins; an `unnest_emoji()` alias mirroring `unnest_tokens()`.
- **Grouped data frames**: every summary/metric verb should respect `group_by()`
  (e.g., per-author, per-day) and return per-group results. *(This is the proper
  fix for the 4.3 silent-wrong-answer bug — the patch warns, 1.0 honours.)*
- **Performance**: benchmark on millions of rows; offer an optional
  `data.table`/`arrow`-backed path for the hot loops; cache the reference once;
  vectorise `emoji_key()` over the unique glyph set (see 4.10).
- **Native pipe / R version**: consider `Depends: R (>= 4.1)` to use `|>` and
  drop the `%>%` import once the user base allows.

---

## 6. Cross-cutting: a lexicon API

Several features (sentiment, emotion, future affect dimensions) share the same
shape: *map glyph → score(s), aggregate per row.* Promote this into a tiny,
documented interface so the package is **extensible**:

```r
emoji_lexicons()                       # registry: name, dims, source, licence, n
register_emoji_lexicon(name, tbl, key = "emoji")   # user/extension lexicons
emoji_score(data, text, lexicon, ...)  # generic scorer all the verbs share
```

This keeps `emoji_sentiment()` / `emoji_emotion()` as friendly front-ends over
one tested engine, and lets researchers drop in their own lexicons without
forking the package. **It must join through `emoji_key()`** (§4.1) so
user-supplied lexicons keyed on unqualified glyphs still match qualified text.

---

## 7. New bundled datasets & licensing

| Dataset | Source | Licence | Bundle? | Notes |
|---|---|---|---|---|
| `emoji_sentiment_lexicon` | Novak et al. 2015 | CC BY-SA 4.0 | ✅ shipped | valence |
| `emoji_emotion_lexicon` | EmoTag1200 (Shoeb & de Melo 2020) | **MIT** | ✅ small | 150 emoji × 8 emotions |
| `emoji_country` (flags) | Unicode regional indicators + ISO 3166 | Unicode / public | ✅ small | or reuse {ISOcodes} |
| emoji embeddings | emoji2vec (Eisner et al. 2016) | **MIT** | ⛔ download | ~MB; exceeds CRAN data budget |
| multilingual names/keywords | Unicode CLDR | Unicode licence | ⚠️ partial | bundle a few locales or download |

Licensing notes:
- CC BY-SA (Novak) requires attribution + share-alike on the *data*; already
  documented. Keep that pattern.
- MIT (EmoTag, emoji2vec) is trivially compatible; attribute in `@source`.
- Respect CRAN's ~5 MB package guidance: anything large is `Suggests`-gated and
  downloaded on demand (pattern: `textdata`, `tokenizers.bpe`). Note the current
  vignette sample alone is ~752 KB (§4.8) — shrink it before adding more data.

---

## 8. Documentation, infrastructure & quality

**Rule for every release: nothing ships undocumented.** A new exported verb or
dataset isn't "done" until it has (a) a roxygen help page with runnable
`@examples`, (b) a home in a vignette, (c) a `NEWS.md` entry, and — for headline
features — (d) a README mention and a pkgdown reference-index entry. The
subsections below make that concrete.

### 8.1 NEWS discipline & per-release changelog drafts

0.2.0's `NEWS.md` is accurate (§4.12); keep the same rigour. Conventions: open a
`# tidyEmoji (development version)` heading the moment work starts; one bullet per
*user-visible* change, grouped **New features / Improvements and fixes / Breaking
changes / Deprecations**; describe the behaviour change, not the commit. Draft
entries (refine at release time — they double as the release checklist, so if a
bullet has no NEWS-worthy change, the work isn't user-visible yet):

**0.2.1 — Improvements and fixes**
- Emoji name, shortcode and category now resolve through the same
  codepoint-normalised key as sentiment, so emoji carrying the `U+FE0F` variation
  selector no longer get `NA` metadata, are no longer dropped by
  `emoji_categorize()`, and no longer disappear from `top_n_emojis(duplicated =
  TRUE)`. (§4.1)
- The whole package now agrees on what "contains an emoji" means:
  `emoji_summary()`/`emoji_filter()` use the same detection as the extraction
  verbs. (§4.2)
- `emoji_sentiment()` gains `.emoji_n_scored` (emoji actually found in the
  lexicon), distinct from `.emoji_n`. (§4.7)
- `top_n_emojis(n =)` again counts *distinct* emoji, breaks ties deterministically,
  and keeps emoji that have no GitHub-style alias. (§4.6)
- Faster on large corpora: codepoint keys are computed once over the unique glyph
  set rather than per row. (§4.10)
- *Deprecations:* grouped data frames passed to `emoji_summary()`,
  `emoji_frequency()` and `top_n_emojis()` now warn that grouping is ignored
  (per-group results land in 1.0). (§4.3)
- *Docs:* lifecycle badge → "maturing"; vignette sample renamed
  `ata_tweets.csv` and downsampled (was a CSV misnamed `.rda`). (§4.8, §4.12)
- *(Optional, soft-deprecation — may slip to 0.3.0):* `emoji_summary()` columns
  renamed to `n_with_emoji`/`n_total`; `emoji_tweets()` soft-deprecated in favour
  of `emoji_filter()`. (§4.4)

**0.3.0 — New features:** `emoji_emotion()`/`emoji_emotion_label()` + bundled
`emoji_emotion_lexicon` (EmoTag1200); pluggable lexicon API
(`emoji_lexicons()`, `register_emoji_lexicon()`, `emoji_score()`);
`emoji_to_text()`/`text_to_emoji()` + `as_emoji*()` helpers; `emoji_search()`.
**0.4.0 — New features:** `emoji_pairs()`/`emoji_cooccurrence()`/`emoji_ngrams()`;
`emoji_position()`/`emoji_density()`/`emoji_ratio()`; `emoji_dfm()`.
**0.5.0 — New features:** `emoji_skin_tone()`/`emoji_gender()`/`emoji_components()`/`emoji_diversity()`;
`emoji_flag_to_country()`/`country_to_flag()`/`emoji_is_flag()`/`emoji_flags()` +
`emoji_country` data.
**0.6.0 — New features:** `emoji_image()`/`emoji_label()`/`geom_emoji()`;
`emoji_version()`/`emoji_vendor_support()`/`emoji_lookup()`; optional
`emoji_similarity()`/`emoji_nearest()` via `emoji_download_embeddings()`.
**1.0.0 — Breaking changes / Improvements:** grouped-df support across all
verbs; finalise column-name migrations (drop the soft-deprecated aliases);
lifecycle → **stable**; performance backend.

### 8.2 README maintenance

- `README.md` is **generated** from `README.Rmd` — always edit the `.Rmd` and
  re-knit; never hand-edit `README.md`. The CRAN/GitHub front page must always
  show live, correct output (it will change the moment columns are renamed in
  §4.4).
- Broaden the opening tagline ("discover, count, categorise and sentiment-score")
  as new capabilities land — e.g. add "score emotions, translate, and map
  co-occurrence." Keep it in sync with the DESCRIPTION Title/Description (§4.12).
- Each release adds **one** short Usage snippet for its headline verb (emotion,
  translation, `emoji_pairs()`, flags, `geom_emoji()`), so the README always
  demonstrates the newest thing. Don't let it grow unbounded — rotate older demos
  into the vignettes.
- Flip the lifecycle badge to "stable" only at 1.0.0.

### 8.3 Documentation coverage matrix

Every planned feature must map to a vignette home *before* it ships. Vignettes
(one per workflow, each a real analysis):

| Feature group (release) | Help page | Vignette home | README |
|---|---|---|---|
| Emotions + lexicon API (0.3) | ✓ | **V1 Sentiment & emotion** (valence + Plutchik, plots) | snippet |
| Translation / accessibility (0.3) | ✓ | **V6 Accessibility & preprocessing** (`emoji_to_text()`) | mention |
| `emoji_search()` (0.3) | ✓ | V1 / reference | brief |
| Co-occurrence / sequences (0.4) | ✓ | **V3 Emoji networks** (→ ggraph/tidygraph) | mention |
| Structural & intensity metrics (0.4) | ✓ | **V2 Social listening / brand analytics** (reviews; also de-Twitters §4.9) | — |
| `emoji_dfm()` + embeddings (0.4/0.6) | ✓ | **V5 Emoji as model features** (→ tidymodels) | mention |
| Skin tone / gender / components / diversity (0.5) | ✓ | **V4 Representation & skin tone** (research-framed, sensitivity caveats) | brief |
| Flags ↔ countries (0.5) | ✓ | V2 or V3 | brief |
| Visualization (`geom_emoji()`, twemoji) (0.6) | ✓ | figures throughout + a dedicated section | hero image |
| Version / vendor support / lookup (0.6) | ✓ | V5 / a QA note | — |

The existing `introduction.Rmd` becomes the canonical "getting started" tour
(updated for the renamed columns and de-Twittered per §4.9); the table above adds
six workflow vignettes as their features land. Extend the pkgdown
reference-index "function families" grouping (`_pkgdown.yml`) for every new verb.

### 8.4 Testing & tooling

- **Testing**: keep ≥ the current coverage; add the audit regression tests
  (§4.11); snapshot tests for new tidy outputs; property tests for codepoint
  logic (skin tone, flags, components). Add a test that pins the `emoji`
  extractor's qualification behaviour (§10.7).
- **Tooling**: `goodpractice`, `urlchecker`, spell check; keep CI green on the
  5-platform matrix; rebuild README + vignettes in CI so doc drift is caught.
- **Deprecation discipline**: use `lifecycle`; avoid gratuitous breaking changes
  (the column renames in §4.4/§4.5 all go through soft deprecation, then drop at
  1.0 per §8.1).
- **Docs**: a short "output & naming contract" doc (§4.5) plus the `?tidyEmoji`
  package overview kept current with the verb list.

---

## 9. Proposed phased releases

Sized so each release is coherent and shippable on its own. **The maintenance
patch leads** — it fixes correctness before we build on the engine.

| Release | Theme | Headline contents | Risk |
|---|---|---|---|
| **0.2.1** | *Correctness patch* | Fix the key-normalisation asymmetry (§4.1); unify detection (§4.2); warn on grouped input (§4.3); `top_n_emojis` n-semantics + alias-less fix (§4.6); `.emoji_n_scored` (§4.7); vignette CSV rename/shrink (§4.8). Add regression tests (§4.11). No new public verbs. | **Low** — internal fixes + tests; renames soft-deprecated |
| **0.3.0** | *Affect & translation* | `emoji_emotion()` + EmoTag1200 + lexicon API; `emoji_to_text()`/`text_to_emoji()`; `emoji_search()` | Low — data + tidy wrappers on the (now-correct) engine |
| **0.4.0** | *Relational & structure* | `emoji_pairs()`/`emoji_cooccurrence()`/`emoji_ngrams()`; `emoji_position()`/`emoji_density()`; `emoji_dfm()` | Low/Med — all return tidy frames |
| **0.5.0** | *Modifiers, flags & representation* | `emoji_skin_tone()`/`emoji_gender()`/`emoji_components()`/`emoji_diversity()`; flags↔countries | Med — sensitive framing, more edge cases |
| **0.6.0** | *Visualization & semantics* | `emoji_image()`/`geom_emoji()`; `emoji_version()`/`emoji_vendor_support()`; optional emoji2vec similarity | Med — optional heavy deps/downloads |
| **1.0.0** | *Stable & integrated* | ecosystem integration polish, **grouped-df guarantees** (the full §4.3 fix), performance backend, neutral column-name migration complete, full vignette suite → lifecycle **stable** | Med — API freeze |

Rationale for ordering: land the 0.2.1 correctness patch first so every later
feature builds on a single, normalised join engine; 0.3/0.4 are high-value and
low-risk (reuse the engine, ship as tidy data); 0.5/0.6 take on the trickier
codepoint and rendering work; 1.0 consolidates.

---

## 10. Risks, open questions & decisions needed

1. **Scope vs EmojiSentR.** Decision: stay *composable building blocks*; offer a
   documented recipe for combined emoji+word sentiment rather than a monolithic
   verb. Revisit if users ask for a one-shot composite.
2. **Data-size budget (CRAN ≤ ~5 MB).** Embeddings and full multilingual CLDR
   must be download-on-demand, not bundled. Shrink the vignette sample (§4.8).
   Confirm before promising `emoji_similarity()` as core.
3. **Dependency weight.** Keep core `Imports` lean; igraph/ggimage/Matrix/arrow
   in `Suggests`. Each new core dep needs justification.
4. **Unicode churn.** New emoji land yearly; the `data-raw/` refresh discipline
   from 0.2.0 must extend to every new lexicon (re-key by codepoint, not glyph —
   the same principle as §4.1).
5. **Sensitive features.** Skin-tone/gender analysis is descriptive, not
   identity-inferring; lead the vignette with that framing and cite the
   literature.
6. **Naming/back-compat.** Lock a consistent naming scheme now (§4.4/§4.5);
   `emoji_*` verbs on `(data, text)`; one term per concept; use `lifecycle` for
   every rename.
7. **`emoji` package coupling.** We depend on `emoji::emojis` columns (version,
   vendor_*, keywords, aliases) and on the qualification form its extractor
   returns (the root of §4.1). Pin a minimum `emoji` version when we start
   relying on specific columns, and add a test that pins the extractor's
   qualification behaviour so an upstream change can't silently break joins.
8. **Verify §4.1 empirically.** Before the 0.2.1 fix, install `emoji` and confirm
   exactly which glyphs differ in qualification between `emoji_extract_all()`
   output and `emoji::emojis$emoji`; capture those as fixtures.

---

## 11. References (research & resources consulted)

- Kralj Novak et al. (2015) *Sentiment of Emojis*, PLoS ONE —
  <https://doi.org/10.1371/journal.pone.0144296> (Emoji Sentiment Ranking; CC BY-SA 4.0).
- Shoeb & de Melo (2020) *EmoTag1200*, EMNLP —
  <https://aclanthology.org/2020.emnlp-main.720/> ; data
  <https://github.com/abushoeb/EmoTag> (MIT).
- Eisner et al. (2016) *emoji2vec* — <https://arxiv.org/abs/1609.08359> ; code/models
  <https://github.com/uclnlp/emoji2vec> (MIT).
- Robertson et al. (2018/2020) *skin-tone modifiers on social media* —
  <https://dl.acm.org/doi/fullHtml/10.1145/3377479> ; *gender & skin tone semantics*
  <https://aclanthology.org/S18-2011/>.
- *Emoji co-occurrence / sequence networks* —
  <https://arxiv.org/abs/1806.07785> ; <https://link.springer.com/chapter/10.1007/978-3-031-04819-7_28>.
- EmojiSentR (R package; JBDS) — <https://jbds.isdsa.org/jbds/article/view/200>.
- Real emoji in ggplot2 (twemoji + ggimage), E. Hvitfeldt —
  <https://emilhvitfeldt.com/post/2020-01-02-real-emojis-in-ggplot2/>.
- Unicode CLDR emoji annotations (multilingual names/keywords) —
  <https://cldr.unicode.org/> ; regional-indicator → ISO 3166 flags —
  <https://en.wikipedia.org/wiki/Regional_indicator_symbol>.
- Python `emoji` (emojize/demojize/replace/analyze) —
  <https://carpedm20.github.io/emoji/docs/> ; emoji marketing/social-listening
  use cases — <https://onlinelibrary.wiley.com/doi/10.1002/cb.70017>.
