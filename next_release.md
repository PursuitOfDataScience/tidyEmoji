# tidyEmoji — Roadmap for 0.5.0

*Planning document, written after 0.4.0 landed. It replaces the 0.2.0-era
roadmap of the same name, which had become an archaeological record: its
maintenance audit (§4) is fully discharged, its phased plan (§9) is three
releases out of date, and its ship reports (§12, §13) describe work that is now
in `git log`. That document is preserved in the history — `git show
f8989ef:next_release.md` — and its durable parts (the ledger, the design
principles, the lesson from each audit) are carried forward here in §1 and §9.*

*This file is build-ignored and is not part of the package.*

---

## 0. TL;DR — what to do next

1. **Re-survey `{emoji}` before writing a line of code.** The most important
   finding of this round: the upstream package moved, and it now ships much of
   what the roadmap assumed tidyEmoji would have to build. See §2.1. Several
   planned features shrink from "L, blocked" to "S, thin wrapper".
2. **0.5.0's theme is modifiers, representation and geography** — the
   long-planned phase — **plus accessibility**, a theme no version of this
   roadmap has had, and which turns out to be the cheapest research-grounded
   feature left (§4.3).
3. **Do not reimplement upstream.** `{emoji}` has modifier extraction and a
   modified→base lookup. tidyEmoji's contribution is the *tidy verb*, the
   *denominator discipline* and the *corpus-level summary* — not the codepoint
   arithmetic.
4. **Ship the Unicode 17.0 refresh with it.** Emoji 17.0 landed 2025-09-09;
   the bundled crosswalks need a refresh pass and a documented cadence (§2.2).

---

## 1. Where the package stands after 0.4.0

49 exported functions. Bundled data unchanged since 0.3.0:
`emoji_sentiment_lexicon`, `emoji_emotion_lexicon`, `emoji_unicode_crosswalk`,
`category_unicode_crosswalk`.

| Job | Exports |
|---|---|
| Detect / extract | `emoji_summary()`, `emoji_filter()`, `emoji_extract_nest()`, `emoji_extract_unnest()`, `emoji_tokens()` |
| Count | `emoji_frequency()`, `top_n_emojis()` |
| Categorise | `emoji_categorize()`, `emoji_type()`, `as_emoji_type()`, `emoji_faceness()` |
| Affect | `emoji_sentiment()`, `emoji_emotion()`, `emoji_emotion_label()`, `emoji_score()` |
| Interpretation risk | `emoji_ambiguity()`, `emoji_risk()`, `emoji_flag_ambiguous()` |
| Lexicon API | `emoji_lexicons()`, `register_emoji_lexicon()` |
| Context | `emoji_context()`, `emoji_collocations()` |
| Relate | `emoji_pairs()`, `emoji_cooccurrence()`, `emoji_ngrams()` |
| Measure | `emoji_position()`, `emoji_density()`, `emoji_ratio()` |
| Mismatch | `emoji_incongruity()`, `emoji_congruence()`, `emoji_incongruity_profile()` |
| Time | `emoji_trend()`, `emoji_turnover()`, `emoji_seasonality()`, `emoji_version_profile()`, `emoji_adoption_lag()`, `emoji_unicode_releases()` |
| Model features | `emoji_dfm()` |
| LLM pipelines | `emoji_sanitize()`, `emoji_token_cost()` |
| Translate & search | `emoji_to_text()`, `text_to_emoji()`, `as_emoji_name()`, `as_emoji_shortcode()`, `as_emoji()`, `emoji_search()` |
| Provenance | `emoji_provenance()`, `emoji_unicode_version()` |

**Invariants earned across three releases. Do not break these.**

- `verb(data, text, ...)`, unquoted column, tibble in / tibble out.
- Columns added to user data are dotted `.emoji_*`; new summary tibbles use
  bare names.
- Every glyph-to-metadata join goes through the `U+FE0F`-stripped codepoint key.
- `NA` text is never an emoji. Empty input returns a typed zero-row tibble.
- `.emoji_n_scored` is `NA` only when the row has no emoji at all, `0` when it
  has emoji the lexicon cannot score.
- **No user-visible ordering may depend on the session's collation.** This has
  bitten twice — `emoji_to_text()`'s shortcode choice in 0.3.0 and
  `emoji_dfm(doc_id =)`'s row order in 0.4.0. `factor()` and `sort()` on
  character are `sort(method = "radix")` waiting to happen.
- **Invalid argument values error; they are not absorbed.** 0.4.0 swept the
  package for arguments that reached a base R call with different semantics
  (`head(n = -1)`, `isTRUE()` on a non-logical, a `wrap` with no placeholder).
  New verbs validate on the way in.

**Known gaps carried forward:** grouped data frames still warn rather than
being honoured (the 1.0 promise); `emoji_ratio()` counts characters, not
graphemes; no benchmark script; no {covr}/spelling CI.

---

## 2. What changed in the world since `features.md` was written

This section is the reason to re-plan rather than simply execute wave 2. Four
things moved, and three of them change the design.

*Research caveat: this round used web search only — direct document fetch was
unavailable in the authoring environment, so the package facts below come from
search results and reference-manual summaries, not from reading an installed
package. Everything marked **(verify)** must be confirmed against a real
install before it is built on.*

### 2.1 `{emoji}` moved, and now ships much of the foundation

The upstream package was updated **2026-05-08**, tracks Unicode Emoji 16.0
(development version 16.0.0.9000), and its `emojis` table has columns
**(verify)**:

```
emoji, name, group, subgroup, version, points, nrunes, runes, qualified
```

Two of those change the plan outright:

- **`qualified`** is the qualification status from `emoji-test.txt`
  (fully-qualified / minimally-qualified / unqualified / component).
  `features.md` §15.1 called building this "the blocking dependency" for the
  whole modifier theme, to be derived by parsing `emoji-test.txt` ourselves.
  **It is already there.** The qualified/unqualified asymmetry that 0.2.1
  patched anecdotally — the victory-hand fixture was the only in-the-wild case
  pinned by a test — can now be handled *exhaustively*, at the cost of a join.
- **`points` / `runes` / `nrunes`** give codepoint decomposition we would
  otherwise have written.

There is also a second dataset, `emoji_modifiers` **(verify)**, a tibble of:

```
emoji_modifiers   the modified glyph
emoji             the same glyph with modifiers removed
modifiers         list column of the modifiers applied
```

plus the functions `emoji_modifier_extract()` and `emoji_modifier_remove()`.

**That is `emoji_base()`, and half of `emoji_skin_tone()`, handed to us.**

**Consequence for the design.** `features.md` §8 sketched tidyEmoji doing the
ZWJ and modifier parsing itself, guarded by "a wide fixture table of
hand-verified sequences" — an L-sized, medium-risk job. It should now be a thin
tidy layer over upstream primitives. tidyEmoji's real contribution to this
theme is not the codepoint arithmetic; it is:

1. the `verb(data, text)` shape over a whole column,
2. **denominator discipline** — Robertson et al.'s 42% is modified ÷
   *modifiable*, and getting that wrong understates tone use by an order of
   magnitude in emoji-heavy corpora,
3. corpus-level summaries (`emoji_tone_summary()`, `emoji_diversity()`),
4. the framing discipline: describe glyph usage, never infer identity.

**Action before coding:** install the current `{emoji}`; print `names(emojis)`,
`unique(emojis$qualified)`, `unique(emojis$version)` and `head(emoji_modifiers)`;
record the answers in this file. Pin a minimum `{emoji}` version in DESCRIPTION
the moment we read `qualified` or `emoji_modifiers` — the old roadmap's §10.7
promised this and it is now due.

### 2.2 Unicode Emoji 17.0 shipped

Released **2025-09-09** alongside Unicode 17.0: **163 new emoji**, raising the
RGI total to **3,953** including skin-tone and gender variations. New glyphs
include distorted face, fight cloud, hairy creature, ballet dancer, orca,
landslide, trombone, treasure chest and expanded people sequences.

Two consequences:

- `emoji_unicode_releases()` already carries `17.0 -> 2025-09-09`; that entry
  is confirmed correct. The table needs one new row per Unicode release,
  forever.
- The bundled crosswalks are only as current as the installed `{emoji}`.
  `emoji_provenance()` exists so a user can *see* this, but the `data-raw/`
  refresh needs to become a release-checklist item rather than a remembered
  habit (§8).

### 2.3 Colour emoji now render natively in R

`{ragg}` renders colour emoji in ggplot2 output. That substantially deflates
`features.md` §14 (Theme L, visualization), which was built on the premise that
plotting real emoji is "perennially awkward" and that tidyEmoji should supply
image URLs for `{ggimage}`.

**Revised position:** do not build `emoji_image()`. The remaining real needs
are two diagnostics, and they are cheap:

- `emoji_render_check()` — "will this glyph draw on this device?", the answer
  to "why are my axis labels tofu boxes?"
- `emoji_label()` — a render-safe label that degrades to name or shortcode.

Both belong with the accessibility work in §4.3, not in a visualization theme
of their own. `{emojifont}` remains showtext-based and RStudio-incompatible,
which is a reason to point users at `ragg`, not to wrap `{emojifont}`.

### 2.4 New literature, 2024-2026

Grouped by whether it changes what we build.

**Changes the plan — accessibility is a first-class theme, not a footnote.**

- *Emoji Accessibility for Visually Impaired People* (CHI 2020,
  doi:10.1145/3313831.3376267) established the problem: screen readers speak
  each emoji's Unicode name, so runs of emoji and mid-sentence emoji make
  messages hard to follow.
- *"Party Face Congratulations!"* (PACM HCI / CSCW 2024, doi:10.1145/3641014)
  tested two interventions with sighted senders: **PREVIEW** (show the sender
  the transcript a screen reader would narrate) and **ALERT** (summarise the
  accessibility problems in the message). Participants preferred PREVIEW,
  because it leaves the judgement to the human.
- Practitioner guidance converges on the same two rules: avoid runs of emoji,
  and prefer sentence-final placement over emoji sandwiched between words.

This is the finding of the round, because **tidyEmoji already has every
primitive it needs**: `emoji_to_text(format = "name")` *is* PREVIEW, and
`emoji_position()` + `emoji_ngrams()` + `emoji_ratio()` are ALERT. See §4.3.

**Reinforces the modifier theme.**

- *Digital Skin, Digital Bias: Uncovering Tone-Based Biases in LLMs and Emoji
  Embeddings* (ACM Web Conference 2026, doi:10.1145/3774904.3792508) — the
  first large-scale comparative study of skin-tone bias across emoji embedding
  models (emoji2vec, emoji-sw2v) and four modern LLMs. Skin tone is not a
  cosmetic attribute of a glyph; it propagates into downstream representations.
- *Digital Colourism? Understanding Emoji Skin Tone Preferences Among
  Indian-Origin Users* (BCS HCI 2025) — tone preference is culturally patterned
  well beyond the US/UK samples the earlier work used.
- 2025 work reports that women are more likely than men to use tones matching
  their own and to value the range of options — a *group difference*, which is
  exactly what `emoji_tone_summary(group_by =)` should make a one-liner.

**Reinforces the LLM theme (0.4.0 shipped the plumbing; the case got stronger).**

- **EMODIS** is now published at **AAAI 2026** (arXiv 2511.07193) with a number
  worth quoting: human annotators 88.5% versus GPT-4 58.8% on context-dependent
  emoji disambiguation — a roughly 30-point gap.
- *Small Symbols, Big Risks: Emoticon Semantic Confusion in LLMs* (arXiv
  2601.07885, 2026) — six LLMs, average confusion ratio above 38%, and **over
  90% of confused responses are "silent failures"**: syntactically valid output
  that deviates from intent. This is the strongest argument yet that
  `emoji_sanitize()` should be an explicit, recorded decision.
- *Emoji-Based Jailbreaking of Large Language Models* — supports the defensive
  framing of a future `emoji_obfuscation_scan()`, and the discipline of
  reporting structural anomalies rather than shipping attack patterns.

**Applied domains — new syntheses, no new API pressure.**

- *Emojis in Marketing and Advertising: A Systematic Literature Review*
  (Behavioral Sciences 2025, doi:10.3390/bs15111490), T-C-C-M framework; the
  field is "growing in volume yet immature".
- *Emoji-based marketing in consumer behavior: a systematic literature review*
  (Cogent Business & Management 2026, doi:10.1080/23311975.2026.2669001), 45
  articles, ADO framework.
- Health-communication reviews cover food safety, behaviour guidance and
  doctor-patient communication. None of this asks for a new verb:
  `emoji_type()` / `emoji_faceness()` and `emoji_congruence()` already carry
  the variables these literatures use. **Continue to ship no clinical
  instrument.**

**Semantics and embeddings — still not urgent.**

EmoSim508 remains the intrinsic benchmark; a 2025 evaluation puts GPT-4o at
79.23% semantics preservation. Nothing here beats the plan of building
`emoji_embed_corpus()` (dependency-free PPMI + SVD) before touching pretrained
downloads.

### 2.5 R ecosystem — the confirmed gaps

| Capability | State of the R ecosystem | tidyEmoji's position |
|---|---|---|
| Emoji data + string helpers | `{emoji}`, current and actively maintained | **Depend on it.** Do not duplicate |
| Modifier extraction / base glyph | `{emoji}` has it | Wrap as tidy verbs |
| ISO 3166 <-> flag emoji | **Nothing on CRAN.** A gist, and non-R libraries | **Real gap — fill it** (§4.2) |
| Colour emoji in plots | `{ragg}` natively; `{emojifont}` (showtext, RStudio-incompatible) | Point at `ragg`; ship diagnostics only |
| Emoji + text sentiment | `{EmojiSentR}` (integrated), `{text2emotion}` (emotion + emoji mapping) | Stay composable; document the recipe |
| Grapheme segmentation | `{stringi}` only | Suggests-gated opt-in engine (§4.5) |
| Tidy emoji verbs over a text column | **tidyEmoji** | The differentiator. Defend it |

`{text2emotion}` is new to this survey and should be read before 0.5.0 ships:
it maps text to emotion *and* emoji, so there may be overlap with
`emoji_emotion()` worth acknowledging in the docs. **(verify)**

---

## 3. What 0.5.0 should be

**Theme: identity, place and access — the human attributes of a glyph.**

Three feature groups plus two pieces of infrastructure. It is coherent
(everything answers "what does this glyph say about a person or a place, and
who can read it?"), it is the long-planned phase, and §2.1 has made the
expensive part cheap.

| Group | Why now |
|---|---|
| §4.1 Modifiers & representation | Long planned; upstream now supplies the primitives; 2025-26 literature strengthens the case |
| §4.2 Flags <-> countries | Confirmed gap in the R ecosystem; pure arithmetic, no new data |
| §4.3 Accessibility | **New.** Highest value-to-effort left; every primitive already shipped |
| §4.4 Unicode property surface | Now a join, not a parser (§2.1) |
| §4.5 `{stringi}` grapheme engine | Retires a documented limitation; gives exact ratios |

**Size discipline.** 0.4.0 added 21 verbs in one release, which was a lot to
review at once. 0.5.0 should aim for **10-14 verbs** and spend the difference
on the 1.0 debts in §8.

---

## 4. Feature specifications

### 4.1 Modifiers, identity and representation

```r
emoji_skin_tone(data, text)
#> .emoji_skin_tone: default | light | medium_light | medium | medium_dark | dark
#> .emoji_modifiable (logical), .emoji_n_modifiable, .emoji_n_modified

emoji_gender(data, text)          # woman | man | person | none
emoji_hair(data, text)            # red | curly | white | bald | none
emoji_base(x)                     # vector helper: strip modifiers -> base glyph
emoji_zwj_components(data, text)  # one row per component of each ZWJ sequence

emoji_tone_summary(data, text, group_by = NULL)
#> n_occurrences, n_modifiable, n_modified, modified_rate,
#> tone distribution, default_rate, tone_entropy

emoji_diversity(data, text,
                measures = c("richness", "shannon", "simpson", "tone_diversity"))
```

**Design notes — the methodology is the feature.**

- **`n_modifiable` is a returned column, not an internal.** Robertson et al.'s
  42% is modified ÷ modifiable. Reporting modified ÷ all emoji is the single
  most likely misuse, and the API should make it hard to do by accident.
- **`default` is not "unknown".** Choosing the yellow default is itself a
  choice readers interpret (*Black or White but Never Neutral*, CSCW 2021).
  Name the level `default`, never `NA` or `none`, and say why in the help page.
- **Never infer identity.** The API describes *glyph usage*. Robertson et al.
  found many tone-modified uses depict other people. This belongs in each help
  page and in the vignette, not only in a footnote.
- **`modifiers = c("keep", "strip")` threaded through `emoji_frequency()`,
  `emoji_dfm()` and `emoji_pairs()`** rather than forcing pre-processing.
  Default `keep`, because Barbieri & Camacho-Collados show modifiers change
  semantics — and because `keep` is today's behaviour, so the default is not a
  silent break. Document loudly in NEWS.
- Reuse `{emoji}`'s `emoji_modifiers` / `emoji_modifier_remove()`; write no
  codepoint arithmetic we do not have to. Still needs a fixture table for cases
  upstream may not cover: family combinations, kiss/couple with *mixed* tones,
  the ♀/♂ versus ZWJ gender forms, professions.

**Effort** M (was L). **Risk** medium — reputational, not technical.

### 4.2 Geography: flags and countries

```r
emoji_country(data, text)      # adds .emoji_iso2, .emoji_country_name
emoji_flag(x)                  # ISO-2 <-> flag emoji, vectorised, both ways
emoji_subdivision(data, text)  # tag sequences: the Scotland flag -> GB-SCT
```

Regional-indicator pairs map mechanically to ISO 3166-1 alpha-2: the offset
between an ASCII capital and its regional indicator is constant (`A` = 65,
`U+1F1E6` = 127462, difference 127397). **No external data is needed** for the
codes; only a name lookup, and ISO-2 to name is small enough to inline.

Two things not to miss:

- **Subdivision tag sequences** are a different encoding — a base flag plus tag
  characters — and are easy to overlook. Handle them in the same verb family or
  document their absence explicitly.
- **Cross-package recipe, not a dependency.** Hand `.emoji_iso2` to
  `countrycode::countrycode()` or `countryatlas` and a corpus of flag emoji
  becomes a choropleth in two lines. Document the recipe; import nothing.

This is the clearest unfilled gap in the R ecosystem (§2.5). **Effort** S-M.
**Risk** low.

### 4.3 Accessibility — new in this roadmap

Screen readers announce each emoji's Unicode name, so a run of six emoji
becomes six spoken names, and an emoji between two words interrupts the
sentence. The CHI 2020 and CSCW 2024 work above turned that into two concrete
interventions, and tidyEmoji already has the machinery for both.

```r
# PREVIEW: what a screen reader will actually say
emoji_speak(data, text, sep = " ")
#> the text with every emoji replaced by its spoken name

# ALERT: the accessibility problems in each message
emoji_a11y_check(data, text, max_run = 2, max_emoji = 5)
#> .emoji_a11y_ok (logical), .emoji_a11y_issues (character, "|"-separated),
#> .emoji_longest_run, .emoji_n_interrupting

# render-safe labels and a device diagnostic (absorbed from the old Theme L)
emoji_label(x, fallback = c("name", "shortcode", "codepoint"))
emoji_render_check(x, device = NULL)
```

**Design notes.**

- `emoji_speak()` is `emoji_to_text(format = "name")` with a spacing rule and
  an honest name. It is worth having anyway, because "what will a screen reader
  say?" is the question users have, and `emoji_to_text` does not answer it in
  the help index.
- `emoji_a11y_check()` composes shipped verbs: longest emoji run from
  `emoji_ngrams()`, interrupting (non-final) emoji from `emoji_position()`,
  density from `emoji_ratio()`. **No new engine code.**
- **Follow PREVIEW, not ALERT, in framing.** The 2024 study found people
  preferred being shown the transcript over being told their message was
  inadequate. So `emoji_a11y_check()` reports *what a reader will encounter*
  and leaves the judgement to the user; thresholds are arguments, and their
  defaults are documented as conventions, not standards.
- This also gives the package a real answer to "why would I use
  `emoji_to_text()`?" beyond NLP preprocessing.

**Deps** none. **Effort** S. **Risk** low. **Value** high — no R package does
this, the literature is clear, and the cost is a weekend.

### 4.4 Unicode property surface

Now that `qualified`, `points`, `runes` and `nrunes` come from upstream
**(verify)**, this shrinks to exposing what we join to:

```r
emoji_properties(x)      # one row per glyph: qualification, modifiable,
                         # component, group/subgroup, version, codepoints
as_emoji_canonical(x)    # export the internal canonicaliser
```

`as_emoji_canonical()` has been on the backlog since 0.3.0 and is one `@export`
away: users doing their own joins hit exactly the qualified/unqualified trap the
package already solves internally. **Effort** S.

### 4.5 The `{stringi}` grapheme engine

`emoji_ratio()` is documented as character-based because base R has no grapheme
segmentation. Resolve it as an opt-in rather than a permanent caveat:

- `Suggests: stringi`
- `engine = c("auto", "base", "stringi")` on the affected verbs
- `auto` uses `{stringi}` when installed and base otherwise, and reports which
  it used rather than choosing silently

Two code paths and two sets of tests forever is the cost; a documented
limitation that never goes away is the alternative. **Effort** M.

---

## 5. Explicitly not in 0.5.0

Keeping this list honest is what stopped 0.4.0 from sprawling.

- **Text sentiment scoring** — defer to `{tidytext}` / `{sentimentr}` /
  `{vader}` permanently. `emoji_incongruity()`'s `text_score` contract is the
  position.
- **A rendering engine** — `{ragg}` solved it (§2.3).
- **`emoji_image()` / twemoji downloads** — deflated by §2.3; the download
  infrastructure is no longer worth building for this.
- **Pretrained embeddings** — `emoji_embed_corpus()` (PPMI + `base::svd`)
  first, in a later release; pretrained is a maintenance tail.
- **CLDR multilingual names** — needs the download-and-cache helper, the single
  biggest piece of infrastructure left. Decide it once (§7.2), then do CLDR,
  embeddings and any image set together or not at all.
- **Any bundled clinical or risk glyph set** — the mechanism
  (`emoji_flag_set()` / `emoji_set_register()`) is fine and cheap; the data is
  not ours to ship.
- **Emoji generation or recommendation** — out of scope permanently.

---

## 6. Design decisions to lock before coding

1. **Minimum `{emoji}` version.** Reading `qualified` or `emoji_modifiers`
   makes us version-dependent. Pin it in DESCRIPTION and add a test that fails
   loudly if the columns are absent, rather than producing `NA` silently.
2. **`modifiers = "keep"` as the default** everywhere it is threaded, with
   `"strip"` opt-in. Changing existing users' counts is worse than a slightly
   awkward default.
3. **Tone levels are a fixed vocabulary**, lower-case snake: `default`,
   `light`, `medium_light`, `medium`, `medium_dark`, `dark`. Never `NA` for
   default.
4. **`emoji_a11y_check()` thresholds are arguments with documented defaults**,
   never presented as a standard the user is failing.
5. **Flags return ISO-2, not names, as the join key.** Names are a display
   convenience; the code is what other packages take.
6. **Group support**: `emoji_tone_summary(group_by =)` is a per-verb argument,
   not the grouped-df fix. Do not let 0.5.0 half-solve the 1.0 promise.

---

## 7. Risks and open questions

1. **Upstream coupling.** Everything in §2.1 is a bet on `{emoji}`'s data
   shape. Mitigation: pin the version, test the columns, and keep `emoji_key()`
   as the only join path so a shape change breaks in one place. **(Verify all
   of §2.1 before scheduling.)**
2. **The download helper — build it once, or not at all.** CLDR (§5),
   pretrained embeddings and any image set all need the same machinery: a cache
   under `tools::R_user_dir()`, a version stamp, an offline test mode, clear
   failure messages, and nothing fetched at build or check time. Either write
   it once as infrastructure or drop all three. Do not write it three times.
3. **Sensitive framing.** The modifier work is the one place this package can
   do harm. Every verb in §4.1 needs the "describes glyph usage, never infers
   identity" statement on its own help page — help pages are what people read.
4. **Test surface.** 0.5.0's fixtures are the hard part: mixed-tone
   multi-person sequences, ♀/♂ versus ZWJ gender forms, subdivision tag
   sequences, professions. Budget as much time for the fixture table as for the
   code.
5. **Unicode churn.** Emoji 17.0 is out and 18.0 will follow. The refresh must
   be a checklist item (§8), not a habit.
6. **`{text2emotion}` overlap** — read it before writing docs, and state
   plainly where the packages differ. **(verify)**

---

## 8. Quality bar for the release

Carried-forward debts to pay *during* 0.5.0 rather than defer again:

- [ ] **Refresh `data-raw/` against the current `{emoji}`** and record the
      Unicode version in NEWS. Make this the first item of every release
      checklist.
- [ ] **{covr} coverage job + badge**, and `urlchecker` + `spelling` as
      scheduled workflows. Promised since 0.2.0. 0.4.0 deferred it because a
      red job is worse than a missing one — which is an argument for
      configuring it properly, not for skipping it a fourth time.
- [ ] **`data-raw/benchmark.R`** tracking the millions-of-rows target release
      over release. `emoji_context()` and `emoji_collocations()` are the new
      hot paths.
- [ ] **Snapshot tests** (`expect_snapshot()`) over printed output, to catch
      silent column and ordering changes cheaply.
- [ ] **An "emoji networks" vignette** built on `emoji_pairs()` (ggraph /
      tidygraph in Suggests) — the data source has existed since 0.3.0.
- [ ] **Re-run `devtools::document()` from a real R install** and commit any
      difference. 0.4.0's help pages were generated by a stand-in converter
      because no R was available in the authoring environment; they pass
      `R CMD check` on five platforms, but roxygen2 is the source of truth.

---

## 9. Release ledger

| Work package | State | Where |
|---|---|---|
| 0.2.1 correctness patch | ✅ shipped | folded into package 0.3.0 |
| 0.3.0 affect & translation | ✅ shipped | package 0.3.0 |
| "0.4.0 phase" relational & structure | ✅ shipped | folded into package 0.3.0 |
| `features.md` wave 1 — risk, context, time, mismatch, type, LLM, provenance | ✅ shipped | **package 0.4.0** |
| **Identity, place & access** (this document) | ⏳ **next** | **package 0.5.0** |
| Affect breadth & coverage honesty (wave 3) | ⏳ | blocked on the batched licence review |
| Semantics — `emoji_embed_corpus()`, similarity, clustering (wave 4) | ⏳ | after the download decision (§7.2) |
| Locale / CLDR, pragmatics, drift (wave 5) | ⏳ | after the download decision (§7.2) |
| 1.0.0 — grouped-df guarantees, performance, API freeze | ⏳ | one full cycle with *no* new verbs |

**Version numbering.** CRAN's published version is 0.2.0 **(verify — the CRAN
page exists, but the published version could not be confirmed in this round)**;
the repo has shipped 0.3.0 and 0.4.0. Phase names in older documents refer to
work packages, not package versions.

**The three audits, and the pattern in them.** Each release has found its own
crop of defects in the code written just before it, and they rhyme:

- **0.2.1** — key-normalisation asymmetry: one join path was normalised, the
  others were not.
- **0.3.0** — locale-dependent shortcode choice; a dead `wrap` argument; regex
  injection in `emoji_search()`.
- **0.4.0** — locale-dependent document ordering in `emoji_dfm()`, *the same
  bug class as 0.3.0's in a different axis*, plus nine arguments that absorbed
  invalid values instead of rejecting them.

The lesson to carry into 0.5.0: **the bug is rarely unique to the verb it was
found in. When one turns up, grep the package for its shape before fixing just
the one.** That is how 0.4.0 turned three reported gaps into nine fixed ones.

---

## 10. References

New or updated in this round. `features.md` (issue #5) holds the fuller
bibliography.

**Accessibility (new theme, §4.3)**

- Emoji Accessibility for Visually Impaired People. *CHI 2020*.
  <https://doi.org/10.1145/3313831.3376267>
- "Party Face Congratulations!" Exploring Design Ideas to Help Sighted Users
  with Emoji Accessibility when Messaging with Screen Reader Users.
  *PACM HCI / CSCW 2024*. <https://doi.org/10.1145/3641014>

**Skin tone, identity and bias (§4.1)**

- Digital Skin, Digital Bias: Uncovering Tone-Based Biases in LLMs and Emoji
  Embeddings. *ACM Web Conference 2026*.
  <https://doi.org/10.1145/3774904.3792508>
- Digital Colourism? Understanding Emoji Skin Tone Preferences Among
  Indian-Origin Users. *BCS HCI 2025*.
- Robertson et al. (2018 ICWSM; 2020 ACM TSC 3(2)) — the 42% modified ÷
  modifiable result. <https://doi.org/10.1145/3377479>
- Black or White but Never Neutral. *CSCW 2021*.
  <https://doi.org/10.1145/3476091>
- Barbieri & Camacho-Collados (2018). <https://aclanthology.org/S18-2011/>

**LLM era (0.4.0 shipped the plumbing; these strengthen it)**

- EMODIS: A Benchmark for Context-Dependent Emoji Disambiguation in LLMs.
  *AAAI 2026*. <https://arxiv.org/abs/2511.07193> — human 88.5% vs GPT-4 58.8%.
- Small Symbols, Big Risks: Emoticon Semantic Confusion in LLMs (2026).
  <https://arxiv.org/abs/2601.07885> — >38% confusion, >90% silent failures.
- When Smiley Turns Hostile: How Emojis Trigger LLMs' Toxicity (2025).
  <https://arxiv.org/abs/2509.11141>

**Applied domains (syntheses; no new API pressure)**

- Emojis in Marketing and Advertising: A Systematic Literature Review.
  *Behavioral Sciences* (2025). <https://doi.org/10.3390/bs15111490>
- Emoji-based marketing in consumer behavior: a systematic literature review.
  *Cogent Business & Management* (2026).
  <https://doi.org/10.1080/23311975.2026.2669001>
- Chakraborty et al. (2025). *Journal of Consumer Behaviour*.
  <https://doi.org/10.1002/cb.70017>

**Standards and ecosystem**

- Unicode Emoji 17.0, released 2025-09-09; 163 additions, RGI total 3,953.
  <https://www.unicode.org/emoji/charts-17.0/emoji-released.html>
- UTS #51 and `emoji-test.txt`. <https://www.unicode.org/reports/tr51/>
- CLDR emoji annotations.
  <https://cldr.unicode.org/translation/characters/short-names-and-keywords>
- Regional indicator symbols and ISO 3166-1.
  <https://en.wikipedia.org/wiki/Regional_indicator_symbol>
- `{emoji}` (CRAN, updated 2026-05-08, tracks Unicode 16.0).
  <https://cran.r-project.org/package=emoji>
- `{ragg}` — native colour emoji rendering in R graphics.
- `{text2emotion}` — emotion analysis and emoji mapping for text.
  <https://cran.r-project.org/package=text2emotion>
- EmojiSentR (JBDS). <https://jbds.isdsa.org/public/journals/1/html/v6n1/tong/>
