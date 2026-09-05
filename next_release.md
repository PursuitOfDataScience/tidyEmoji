# tidyEmoji — Roadmap for 0.5.0

*Planning document, written after 0.4.0 landed. It replaces the
0.2.0-era roadmap of the same name, which had become an archaeological
record: its maintenance audit (§4) is fully discharged, its phased plan
(§9) is three releases out of date, and its ship reports (§12, §13)
describe work that is now in `git log`. That document is preserved in
the history — `git show f8989ef:next_release.md` — and its durable parts
(the ledger, the design principles, the lesson from each audit) are
carried forward here in §1 and §9.*

*This file is build-ignored and is not part of the package.*

------------------------------------------------------------------------

## Contents

- [How to read this](#how-to-read-this)
- [0. TL;DR — what to do next](#id_0-tldr-what-to-do-next)
- [1. Where the package stands after
  0.4.0](#id_1-where-the-package-stands-after-040)
  - [1.1 A defect found while re-planning — `emoji_position()` is
    codepoint-based](#id_11-a-defect-found-while-re-planning-emoji_position-is-codepoint-based)
  - [1.2 Detection edge cases — measured, and three of them change
    0.5.0’s
    specs](#id_12-detection-edge-cases-measured-and-three-of-them-change-050s-specs)
  - [1.3 The reversibility contract — tested, and worth
    advertising](#id_13-the-reversibility-contract-tested-and-worth-advertising)
  - [1.4 Locale robustness — the twice-broken invariant now
    holds](#id_14-locale-robustness-the-twice-broken-invariant-now-holds)
  - [1.5 The grouped-input guard is missing from three
    aggregators](#id_15-the-grouped-input-guard-is-missing-from-three-aggregators)
  - [1.6 The remaining §1 invariants — swept, and they
    hold](#id_16-the-remaining-1-invariants-swept-and-they-hold)
  - [1.7 Lexicon coverage ceilings — the number that should be on every
    help
    page](#id_17-lexicon-coverage-ceilings-the-number-that-should-be-on-every-help-page)
  - [1.8 Two past fixes verified, one cosmetic
    inconsistency](#id_18-two-past-fixes-verified-one-cosmetic-inconsistency)
  - [1.9 `emoji_sanitize()` has a reversibility hierarchy, and it is
    undocumented](#id_19-emoji_sanitize-has-a-reversibility-hierarchy-and-it-is-undocumented)
  - [1.10 The audit in one table](#id_110-the-audit-in-one-table)
  - [1.11 The pre-submission polish pass — what it fixed, and what the
    audit got
    wrong](#id_111-the-pre-submission-polish-pass-what-it-fixed-and-what-the-audit-got-wrong)
- [2. What changed in the world since `features.md` was
  written](#id_2-what-changed-in-the-world-since-featuresmd-was-written)
  - [2.1 `{emoji}` moved — verified against the
    install](#id_21-emoji-moved-verified-against-the-install)
  - [2.2 Unicode Emoji 17.0 shipped](#id_22-unicode-emoji-170-shipped)
  - [2.3 Colour emoji now render natively in
    R](#id_23-colour-emoji-now-render-natively-in-r)
  - [2.4 New literature, 2024-2026](#id_24-new-literature-2024-2026)
  - [2.5 R ecosystem — the confirmed
    gaps](#id_25-r-ecosystem-the-confirmed-gaps)
  - [2.6 A second axis: audience, not just
    features](#id_26-a-second-axis-audience-not-just-features)
- [3. What 0.5.0 should be](#id_3-what-050-should-be)
  - [3.1 Recommendation — make 0.5.0 a correctness release and move the
    theme to
    0.6.0](#id_31-recommendation-make-050-a-correctness-release-and-move-the-theme-to-060)
- [4. Feature specifications](#id_4-feature-specifications)
  - [4.1 Modifiers, identity and
    representation](#id_41-modifiers-identity-and-representation)
  - [4.2 Geography: flags and
    countries](#id_42-geography-flags-and-countries)
  - [4.3 Accessibility — new in this
    roadmap](#id_43-accessibility-new-in-this-roadmap)
  - [4.4 Unicode property surface](#id_44-unicode-property-surface)
  - [4.5 The `{stringi}` grapheme engine — now a prerequisite, not an
    option](#id_45-the-stringi-grapheme-engine-now-a-prerequisite-not-an-option)
  - [4.6 The keyword and alias surface — newly
    cheap](#id_46-the-keyword-and-alias-surface-newly-cheap)
  - [4.7 Presentation selectors — a documented limitation, now
    quantified](#id_47-presentation-selectors-a-documented-limitation-now-quantified)
  - [4.8 Zero-inflation and compositional structure — a statistical
    duty](#id_48-zero-inflation-and-compositional-structure-a-statistical-duty)
- [5. Explicitly not in 0.5.0](#id_5-explicitly-not-in-050)
- [6. Design decisions to lock before
  coding](#id_6-design-decisions-to-lock-before-coding)
- [7. Risks and open questions](#id_7-risks-and-open-questions)
- [8. Quality bar for the release](#id_8-quality-bar-for-the-release)
- [9. Release ledger](#id_9-release-ledger)
- [10. Audience expansion — who else analyses emoji
  corpora](#id_10-audience-expansion-who-else-analyses-emoji-corpora)
  - [10.1 Legal, eDiscovery and forensic linguistics —
    **build**](#id_101-legal-ediscovery-and-forensic-linguistics-build)
  - [10.2 Software-engineering research — **build (the input-shape
    gap)**](#id_102-software-engineering-research-build-the-input-shape-gap)
  - [10.3 Mental health and crisis informatics — document, and refuse
    the
    lexicon](#id_103-mental-health-and-crisis-informatics-document-and-refuse-the-lexicon)
  - [10.4 Content moderation and algospeak — sharpens the existing
    plan](#id_104-content-moderation-and-algospeak-sharpens-the-existing-plan)
  - [10.5 Cross-cultural and locale research — reframe now, build after
    §7.2](#id_105-cross-cultural-and-locale-research-reframe-now-build-after-72)
  - [10.6 Survey methodology and psychometrics — a genuinely new
    audience](#id_106-survey-methodology-and-psychometrics-a-genuinely-new-audience)
  - [10.7 Corpus annotation methodology — a recipe, and a debt we
    already
    owe](#id_107-corpus-annotation-methodology-a-recipe-and-a-debt-we-already-owe)
  - [10.8 Authorship attribution and forensic stylometry — recipe plus
    one
    verb](#id_108-authorship-attribution-and-forensic-stylometry-recipe-plus-one-verb)
  - [10.9 Finance and market sentiment — the case for the lexicon
    API](#id_109-finance-and-market-sentiment-the-case-for-the-lexicon-api)
  - [10.10 Education and L2 acquisition — already served, badly
    advertised](#id_1010-education-and-l2-acquisition-already-served-badly-advertised)
  - [10.11 Political communication — typed function, not
    valence](#id_1011-political-communication-typed-function-not-valence)
  - [10.12 AAC and assistive communication — watch, do not
    build](#id_1012-aac-and-assistive-communication-watch-do-not-build)
  - [10.13 Multimodal and retrieval — emoji as a stimulus
    set](#id_1013-multimodal-and-retrieval-emoji-as-a-stimulus-set)
  - [10.14 Crisis and disaster communication — served, and nobody
    knows](#id_1014-crisis-and-disaster-communication-served-and-nobody-knows)
  - [10.15 Workplace and organizational communication — the interaction,
    and a half-kept
    promise](#id_1015-workplace-and-organizational-communication-the-interaction-and-a-half-kept-promise)
- [11. References](#id_11-references)
- [12. Appendix — the audit’s regression fixtures, as
  code](#id_12-appendix-the-audits-regression-fixtures-as-code)
  - [12.1 Part A — behaviour verified correct, now
    defended](#id_121-part-a-behaviour-verified-correct-now-defended)
  - [12.2 Part B — the defects, written as the target
    behaviour](#id_122-part-b-the-defects-written-as-the-target-behaviour)
  - [12.3 Two cautions carried from the audit
    method](#id_123-two-cautions-carried-from-the-audit-method)

------------------------------------------------------------------------

## How to read this

*This document grew across twelve audit rounds and is long. Nobody needs
all of it. Pick a path:*

| If you are… | Read |
|----|----|
| **Deciding what 0.5.0 is** | §0 TL;DR, then **§3.1** (the authoritative plan) |
| **About to write code** | **§3.1**, then **§12** (executable fixtures — Part B is your spec), then the relevant §4.x |
| **Reviewing the audit’s claims** | **§1.10** (summary table), drilling into §1.1-§1.9 only where you doubt a finding |
| **Asking “does this package serve my field?”** | **§10** — fifteen research communities, table first |
| **Looking for what we deliberately will not do** | §5, plus the recorded refusals in §10.3 and §10.4 |
| **Checking scheduling** | **§3.1** wins; §9 is the running provenance list |

**Two things to know before trusting any measurement here.** All
[emoji](https://emilhvitfeldt.github.io/emoji/) facts in §2.1 were
verified against a real install (`emoji` 16.0.0, R 4.4.1) on 2026-08-30,
not inferred from documentation. And two audit methods produce
convincing false results — see the traps in §1.4 and §1.5 before
re-running anything.

------------------------------------------------------------------------

## 0. TL;DR — what to do next

1.  **[emoji](https://emilhvitfeldt.github.io/emoji/) has been surveyed
    — the answers are in §2.1, not pending.** `emoji` 16.0.0 ships a
    5042 x 19 table. The modifier foundation is real (`emoji_modifiers`,
    4468 rows, **454 modifiable base glyphs** — that is the denominator
    §4.1 needs), so the expensive part of the modifier theme is now a
    thin tidy layer.
2.  **Two findings flip a decision each.** `keywords` and `aliases` are
    populated for all 5042 rows, so **English keyword search needs no
    download helper** — a new, cheap verb group (§4.6). And all eight
    `vendor_*` columns are empty (`TRUE = 0`), so
    **`emoji_vendor_support()` is dead** on this data source and moves
    to §5.
3.  **⚠️ The recommendation changed during this document’s own audit:
    make 0.5.0 a correctness release and move the identity/place/access
    theme to 0.6.0 (§3.1).** Eight audit rounds (§1.1-§1.8) found four
    real defects, and **three of them block a planned feature group** —
    the grapheme fix blocks §4.3, flag validation blocks §4.2,
    orphan-modifier accounting blocks §4.1. Building the features on
    primitives being repaired in the same release is the worst available
    ordering, and §9’s own principle is that the maintenance patch
    leads.
4.  **Do not reimplement upstream.** tidyEmoji’s contribution is the
    *tidy verb*, the *denominator discipline* and the *corpus-level
    summary* — never the codepoint arithmetic.
5.  **Unicode 17.0 is upstream’s problem first.** 17.0 landed 2025-09-09
    with 163 additions, but the installed
    [emoji](https://emilhvitfeldt.github.io/emoji/) tops out at 16.0, so
    our crosswalks are bounded by upstream. Make the refresh a checklist
    item (§8) and report the version honestly rather than chasing it
    (§2.2).
6.  **The audience is wider than the current verb set serves.** §10 is
    new: seven research communities that already analyse emoji corpora,
    what each needs, and which are worth a verb. Legal/eDiscovery and
    software-engineering communication are the two with real pull and
    near-zero new machinery.

------------------------------------------------------------------------

## 1. Where the package stands after 0.4.0

49 exported functions. Bundled data unchanged since 0.3.0:
`emoji_sentiment_lexicon`, `emoji_emotion_lexicon`,
`emoji_unicode_crosswalk`, `category_unicode_crosswalk`.

| Job | Exports |
|----|----|
| Detect / extract | [`emoji_summary()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_summary.md), [`emoji_filter()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_filter.md), [`emoji_extract_nest()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_extract_nest.md), [`emoji_extract_unnest()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_extract_unnest.md), [`emoji_tokens()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_tokens.md) |
| Count | [`emoji_frequency()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_frequency.md), [`top_n_emojis()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/top_n_emojis.md) |
| Categorise | [`emoji_categorize()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_categorize.md), [`emoji_type()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_type.md), [`as_emoji_type()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/as_emoji_type.md), [`emoji_faceness()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_faceness.md) |
| Affect | [`emoji_sentiment()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sentiment.md), [`emoji_emotion()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_emotion.md), [`emoji_emotion_label()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_emotion_label.md), [`emoji_score()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_score.md) |
| Interpretation risk | [`emoji_ambiguity()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_ambiguity.md), [`emoji_risk()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_risk.md), [`emoji_flag_ambiguous()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_flag_ambiguous.md) |
| Lexicon API | [`emoji_lexicons()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_lexicons.md), [`register_emoji_lexicon()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/register_emoji_lexicon.md) |
| Context | [`emoji_context()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_context.md), [`emoji_collocations()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_collocations.md) |
| Relate | [`emoji_pairs()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_pairs.md), [`emoji_cooccurrence()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_cooccurrence.md), [`emoji_ngrams()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_ngrams.md) |
| Measure | [`emoji_position()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_position.md), [`emoji_density()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_density.md), [`emoji_ratio()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_ratio.md) |
| Mismatch | [`emoji_incongruity()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_incongruity.md), [`emoji_congruence()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_congruence.md), [`emoji_incongruity_profile()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_incongruity_profile.md) |
| Time | [`emoji_trend()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_trend.md), [`emoji_turnover()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_turnover.md), [`emoji_seasonality()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_seasonality.md), [`emoji_version_profile()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_version_profile.md), [`emoji_adoption_lag()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_adoption_lag.md), [`emoji_unicode_releases()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_unicode_releases.md) |
| Model features | [`emoji_dfm()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_dfm.md) |
| LLM pipelines | [`emoji_sanitize()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sanitize.md), [`emoji_token_cost()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_token_cost.md) |
| Translate & search | [`emoji_to_text()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_to_text.md), [`text_to_emoji()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/text_to_emoji.md), [`as_emoji_name()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/as_emoji_name.md), [`as_emoji_shortcode()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/as_emoji_name.md), [`as_emoji()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/as_emoji_name.md), [`emoji_search()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_search.md) |
| Provenance | [`emoji_provenance()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_provenance.md), [`emoji_unicode_version()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_unicode_version.md) |

**Invariants earned across three releases. Do not break these.**

- `verb(data, text, ...)`, unquoted column, tibble in / tibble out.
- Columns added to user data are dotted `.emoji_*`; new summary tibbles
  use bare names.
- Every glyph-to-metadata join goes through the `U+FE0F`-stripped
  codepoint key.
- `NA` text is never an emoji. Empty input returns a typed zero-row
  tibble.
- `.emoji_n_scored` is `NA` only when the row has no emoji at all, `0`
  when it has emoji the lexicon cannot score. **One documented
  exception, verified 2026-09-03:** under
  `emoji_incongruity(where = "final")` a row whose emoji are all
  mid-sentence has nothing *eligible* to score, and gets `NA` with
  `.emoji_n > 0`. That is deliberate and on the help page, but it means
  the invariant is “`NA` = nothing was scored”, not “`NA` = no emoji”,
  once `where` is in play. Use `.emoji_n > 0 & is.na(.emoji_n_scored)`
  to tell the two apart.
- **No user-visible ordering may depend on the session’s collation.**
  This has bitten twice —
  [`emoji_to_text()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_to_text.md)’s
  shortcode choice in 0.3.0 and `emoji_dfm(doc_id =)`’s row order in
  0.4.0. [`factor()`](https://rdrr.io/r/base/factor.html) and
  [`sort()`](https://rdrr.io/r/base/sort.html) on character are
  `sort(method = "radix")` waiting to happen.
- **Invalid argument values error; they are not absorbed.** 0.4.0 swept
  the package for arguments that reached a base R call with different
  semantics (`head(n = -1)`,
  [`isTRUE()`](https://rdrr.io/r/base/Logic.html) on a non-logical, a
  `wrap` with no placeholder). New verbs validate on the way in.

**Known gaps carried forward:** grouped data frames are not honoured
(the 1.0 promise) — and the guard that warns about them is missing from
three aggregators, see §1.5;
[`emoji_ratio()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_ratio.md)
counts characters, not graphemes, as does
[`emoji_position()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_position.md)
(§1.1); no committed benchmark script (a baseline now exists, §8); no
{covr}/spelling CI.

*The nine subsections below are the audit record. **§1.10 summarises all
of it in one table** — start there and drill in only where you want the
evidence.*

### 1.1 A defect found while re-planning — `emoji_position()` is codepoint-based

*Found 2026-08-30 by reading the source, then measured. This is the
fourth audit in the pattern §9 describes, and it arrived before the
release rather than during it.*

[`emoji_position()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_position.md)
computes `len <- nchar(v)` and takes `start` offsets from the match
matrix. Both are **codepoint** counts, so every multi-codepoint emoji
inflates the denominator. Measured, for an emoji that is genuinely the
last thing in the string:

| Input | `nchar` | graphemes | reported `.emoji_rel_position` | correct |
|----|----|----|----|----|
| `"hi 😀"` | 4 | 4 | **1.000** | 1.000 |
| `"hi 🇺🇸"` (flag, 2 cp) | 5 | 4 | **0.750** | 1.000 |
| `"hi 👨‍👩‍👧‍👦"` (ZWJ family, 7 cp) | 10 | 4 | **0.333** | 1.000 |

A family emoji at the very end of a message is reported as one third of
the way through it. This is the same bug class as the documented
[`emoji_ratio()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_ratio.md)
caveat, but
[`emoji_ratio()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_ratio.md)
is *labelled* character-based whereas `.emoji_rel_position` reads as a
proportion of the message and is silently wrong. `.emoji_first` and
`.emoji_last` are affected identically.

**It also invalidates a 0.5.0 spec as written.** §4.3’s
`emoji_a11y_check()` is specified to derive “interrupting (non-final)
emoji” from
[`emoji_position()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_position.md).
Built on the current implementation it would systematically misreport
sentence-final flags and ZWJ sequences as mid-sentence interruptions —
in an *accessibility* verb, whose whole purpose is to be trustworthy
about placement. **§4.5 is therefore a prerequisite for §4.3, not an
independent nicety.**

**Second, unrelated axis: right-to-left text.** The offsets are
*logical* (storage) order. Under UAX \#9 a right-to-left run renders
right-to-left, so in `"مرحبا 😀"` the emoji is logically last
(`rel = 1.0`) but appears at the reader’s **left**. Every
position-derived claim — placement, “interrupting”, sentence-final
convention — therefore means something different for Arabic, Hebrew,
Persian and Urdu corpora than for English ones, and §10.5’s
cross-cultural users are exactly the people likely to hit it. There is
no cheap fix (visual order requires running the bidi algorithm), so the
deliverable is an explicit statement in the help page that positions are
logical-order, plus a note in the §10.5 documentation pass. Do not
silently imply visual order.

**Action:** fix the denominator in §4.5’s work, add the three cases
above as regression fixtures, and grep for other
[`nchar()`](https://rdrr.io/r/base/nchar.html) uses on user text before
assuming these are the only two verbs affected.

### 1.2 Detection edge cases — measured, and three of them change 0.5.0’s specs

*Also 2026-08-30. `.emoji_locations()` delegates to
[`emoji::emoji_locate_all()`](https://emilhvitfeldt.github.io/emoji/reference/emoji_locate.html)
plus a ZWJ merge, so the engine’s behaviour on awkward sequences is
largely upstream’s. Probed directly:*

| Sequence | Detected as | Verdict |
|----|----|----|
| `1️⃣` keycap (digit + FE0F + 20E3) | 1 unit | ✅ correct |
| `#️⃣` keycap | 1 unit | ✅ correct |
| `❤️` heart, emoji presentation (2764 FE0F) | 1 unit | ✅ correct |
| `❤︎` heart, **text** presentation (2764 FE0E) | **0 — not detected** | documented; impact understated (§4.7) |
| `❤` heart, **bare** (2764, no selector) | **0 — not detected** | documented; impact understated (§4.7) |
| `🇺🇸` valid flag | 1 unit | ✅ correct |
| `🇽🇽` **invalid** regional-indicator pair | **1 unit — detected as an emoji** | ⚠️ breaks §4.2 as specified |
| `😀‍😀` non-RGI ZWJ sequence | **2 separate emoji** | ⚠️ §4.1 must define this |
| `😀🏻` skin tone on a **non-modifiable** base | **2 emoji: `😀` + orphan `🏻`** | ⚠️ §4.1 must define this |
| `👋🏻` valid tone on a modifiable base | 1 unit | ✅ correct |

**Consequence 1 — §4.2’s “no external data is needed” is wrong.** `🇽🇽`
is a well-formed regional-indicator pair that is not a country, and the
engine hands it to us as an emoji. The pure-arithmetic mapping in §4.2
would happily return ISO-2 `"XX"`. The verb must validate against the
real set — §2.1 verified there are exactly **259** `country-flag` rows
and **3** `subdivision-flag` rows, so the valid set is small, bundled
and cheap to check. Invalid pairs return `NA` with the glyph preserved,
never a fabricated code.

**Consequence 2 — orphan modifiers are counted as emoji.** A skin-tone
modifier applied to a base that cannot take one is detected as its own
occurrence, so
[`emoji_frequency()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_frequency.md)
today reports a bare `🏻` as an emoji in its own right. That is
defensible as raw detection and misleading as a corpus statistic — and
it directly corrupts §4.1’s `n_modifiable` / `n_modified` accounting,
which is the methodological point of the whole group.
`emoji_skin_tone()` must decide, and document, whether an orphan
modifier is dropped, attributed to the preceding glyph, or surfaced in
its own column. **Recommend a dedicated `.emoji_n_orphan_modifiers`
column** — silently dropping data is how the 0.2.1 asymmetry happened.

**Consequence 3 — non-RGI ZWJ sequences split.** `😀‍😀` becomes two emoji,
which matches how it renders, so the behaviour is right. But
`emoji_zwj_components()` (§4.1) must state that it decomposes *RGI*
sequences and that non-RGI joins are already separate occurrences
upstream — otherwise the verb looks broken on exactly the inputs a user
would test it with.

### 1.3 The reversibility contract — tested, and worth advertising

*Also 2026-08-30, and the first audit item in three rounds that is good
news.*

Round-tripping
[`emoji_to_text()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_to_text.md)
-\>
[`text_to_emoji()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/text_to_emoji.md)
over the hard cases:

| Glyph | `format = "shortcode"` | `format = "name"` |
|----|----|----|
| `😀` grinning | `:grinning:` -\> ✅ lossless | `grinning face` -\> ✗ |
| `👋🏻` wave + tone | `:waving_hand_light_skin_tone:` -\> ✅ | ✗ |
| `🇺🇸` flag | `:us:` -\> ✅ | ✗ |
| `👨‍👩‍👧` ZWJ family | `:family_man_woman_girl:` -\> ✅ | ✗ |
| `❤️` heart + FE0F | `:heart:` -\> ✅ | ✗ |
| `1️⃣` keycap | `:one:` -\> ✅ | ✗ |
| `👍` thumbs up | `:+1:` -\> ✅ | ✗ |

**The shortcode path is lossless on every case tested, including the
ones that break naive implementations** — skin-tone modifiers,
regional-indicator pairs, ZWJ sequences, keycaps and the `U+FE0F` heart
all survive the trip exactly.

**This is an unadvertised selling point, and it belongs in the LLM
story.** §2.4’s LLM literature is about emoji breaking model pipelines,
and 0.4.0 shipped
[`emoji_sanitize()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sanitize.md)
for it. The reversible move — strip emoji to shortcodes, send the text
to a model, restore the glyphs afterwards — is *exactly* what those
pipelines need, and tidyEmoji can already do it losslessly. Nothing in
the documentation says so.

**The `name` format is one-way, by design and correctly.**
[`text_to_emoji()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/text_to_emoji.md)
matches `:delimited:` tokens, and bare names like `red heart` are
unrecoverable because they are ordinary English words in ordinary text.
That asymmetry is the right call — but it is currently implicit, and a
user doing NLP preprocessing may reasonably assume symmetry.

**One caveat worth recording now, because it constrains a future
release.** The round-trip works because shortcodes are *unique* — CLDR
requires emoji names to be unique within a locale and treats a duplicate
as an error. **That uniqueness is a per-locale property, not a universal
one.** CLDR’s own translator guidance notes languages that lack a
distinction English makes — some Nordic languages do not separate
*octopus* from *squid*, so translators must invent a disambiguating
phrase. So if the multilingual CLDR work behind §7.2 ever lands, **the
reversibility guarantee must be re-verified per locale rather than
assumed**: a locale where two glyphs collapse to one name has no
lossless round-trip, and §1.9’s “shortcode is the reversible policy”
advice would need qualifying. English is safe; other locales are an open
question.

**Actions, all cheap:**

1.  **State the contract explicitly:** `format = "shortcode"` is
    reversible; `format = "name"` is not, and is intended for display
    and screen-reader preview (§4.3’s `emoji_speak()`).
2.  **Add the seven cases above as round-trip regression tests.** This
    property is worth defending — it will silently break the first time
    a shortcode lookup changes.
3.  **Add a vignette section on reversible LLM preprocessing** — it is
    the highest-value undocumented capability found in four rounds of
    auditing.

### 1.4 Locale robustness — the twice-broken invariant now holds

*2026-08-30. Two negative findings, recorded because closing a worry is
worth as much as opening one, and because the §9 lesson says this bug
class recurs.*

**The collation invariant holds.** §1’s invariant list says “no
user-visible ordering may depend on the session’s collation”, and §9
records it breaking twice —
[`emoji_to_text()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_to_text.md)’s
shortcode choice in 0.3.0, `emoji_dfm(doc_id =)`’s row order in 0.4.0.
Tested by running seven verbs over a fixture with deliberately
collation-sensitive content (mixed-case `Apple`/`apple`,
`Zebra`/`zebra`, `ärger`) under `LC_COLLATE=en_US.UTF-8` and
`LC_COLLATE=C` with `LC_CTYPE` held at UTF-8:

| Verb | en_US.UTF-8 vs C |
|----|----|
| [`emoji_frequency()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_frequency.md), [`top_n_emojis()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/top_n_emojis.md), `emoji_dfm(doc_id=)` | identical |
| [`emoji_categorize()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_categorize.md), [`emoji_collocations()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_collocations.md), [`emoji_context()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_context.md) | identical |
| `emoji_to_text(format = "shortcode")` | identical |

**Byte-identical across all seven.** The third instance of the bug is
not there.

**Detection is also locale-robust.** `LC_CTYPE=C` detects the same 5 of
6 rows and the same 5 distinct glyphs as `en_US.UTF-8`, including the
flag, the tone sequence, the `U+FE0F` heart and the ZWJ family. This
follows from
[`emoji::emoji_locate_all()`](https://emilhvitfeldt.github.io/emoji/reference/emoji_locate.html)
working on code points rather than locale-dependent character classes,
but it is worth having tested: a package whose whole subject is
non-ASCII text should know it survives a container with no locale set.

> **⚠️ Methodological trap — read this before re-running the check.**
> The obvious way to test locale sensitivity is to set `LC_ALL=C` and
> compare. **It produces a false positive on every verb.** Under a
> non-UTF-8 `LC_CTYPE`, R mis-reads UTF-8 *source files*, so a fixture
> built from literal non-ASCII strings in the script is silently mangled
> before any package code runs — the inputs differ, so naturally the
> outputs differ, and it looks like seven broken verbs. This happened on
> the first attempt here. **Vary only `LC_COLLATE`, keep `LC_CTYPE` at
> UTF-8, and build fixtures from `\U` escapes rather than literal
> glyphs.** If §8’s CI work adds a locale matrix, it must be built this
> way or it will chase ghosts.

### 1.5 The grouped-input guard is missing from three aggregators

*2026-08-30. This is the §9 lesson applied to itself: the guard was
written for the verbs where the bug was noticed and never grepped across
the package.*

§1’s gap list says “grouped data frames still warn rather than being
honoured”. That is imprecise in **both** directions, and the precise
version matters.

**Most verbs correctly do not warn**, because grouping cannot change
their answer:

- *Row-preserving* —
  [`emoji_sentiment()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sentiment.md),
  [`emoji_position()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_position.md),
  [`emoji_emotion()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_emotion.md),
  [`emoji_ratio()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_ratio.md),
  [`emoji_density()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_density.md),
  [`emoji_type()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_type.md)
  add columns to each row independently.
- *Row-reshaping but per-row independent* —
  [`emoji_filter()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_filter.md),
  [`emoji_tokens()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_tokens.md),
  [`emoji_extract_unnest()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_extract_unnest.md)
  change the row count by transforming each input row on its own.

Neither class pools anything across rows, so silence is right.

**The verbs that matter are the cross-row aggregators**, where ignoring
groups silently converts a per-group answer into a global one. Tested
with a fixture designed so the two answers *must* differ — group `a`
contains only faces, group `b` only flags — **one fresh R process per
verb**:

| Aggregator | Grouped input |
|----|----|
| [`emoji_frequency()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_frequency.md), [`top_n_emojis()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/top_n_emojis.md), [`emoji_dfm()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_dfm.md) | warns |
| [`emoji_pairs()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_pairs.md), [`emoji_cooccurrence()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_cooccurrence.md) | warns |
| [`emoji_flag_ambiguous()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_flag_ambiguous.md), [`emoji_summary()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_summary.md) | warns |
| **[`emoji_categorize()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_categorize.md)** | **silent — pools groups** |
| **[`emoji_version_profile()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_version_profile.md)** | **silent — pools groups** |
| **[`emoji_ngrams()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_ngrams.md)** | **silent — pools groups** |

**Seven of ten guarded, three missed.** All three verifiably return the
pooled result for grouped input with no warning, so a user who groups by
author, platform or date gets a corpus-wide answer that looks like a
per-group one.

**Action:** add the existing guard to those three. It is a two-line
change per verb using the helper the other seven already share, and it
should land in 0.5.0 — not deferred to the 1.0 grouped-df work, because
a wrong number now is worse than an unimplemented feature later. Then
rewrite §1’s gap sentence to name the two classes above, so the next
reader does not have to re-derive which verbs the promise is even about.

> **⚠️ Second methodological trap, and it will bite §8’s test work.** Do
> **not** check “does this verb warn?” for many verbs inside one R
> session. These are `lifecycle` warnings, which **deduplicate per call
> site**, so a loop that calls every verb from the same line reports
> only the first few as warning and the rest as silent. That produced
> three different, mutually inconsistent answers here before the method
> was fixed — including one run where
> [`emoji_frequency()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_frequency.md)
> appeared silent despite being correctly guarded.
> `options(lifecycle_verbosity = "always")` did **not** reliably
> suppress the dedup. **The only method that gave stable results was one
> fresh R process per verb.** Any regression test asserting these
> warnings must be written that way (or with
> [`testthat::expect_warning()`](https://testthat.r-lib.org/reference/expect_error.html)
> at distinct call sites), or it will pass while the guard is broken.

**A smaller inconsistency found in the same sweep.** Four time verbs
report a missing required argument using an internal name the user
cannot see:

    emoji_trend / emoji_turnover / emoji_seasonality / emoji_adoption_lag
      -> "`var` is absent but must be supplied."

The user’s argument is `time`, not `var`, so the message names something
that does not appear in the signature. Compare
[`emoji_congruence()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_congruence.md),
which does this well: *“`scale` has no default: say how the text score
and the emoji score were made comparable.”* The 0.4.0 audit’s “invalid
values error, they are not absorbed” invariant is satisfied — the call
does fail — but the message leaks an implementation detail. **Effort**
XS; fix with the §1.5 guard work.

**Confirmed sound in the same sweep:** every one of the 38
`verb(data, text)` exports returns a typed zero-row tibble for zero-row
input and handles an all-`NA` text column without error. The seven that
appeared to fail do so only because they have genuinely required
arguments (`time`, or `text_score` + `scale`), which is correct
behaviour.

### 1.6 The remaining §1 invariants — swept, and they hold

*2026-08-30, completing the audit. §1 asserts five invariants “earned
across three releases”. §1.1 found one broken (grapheme counting) and
§1.5 found the grouped-input guard incomplete. The other three are now
tested rather than asserted.*

**✅ Dotted-column naming.** “Columns added to user data are dotted
`.emoji_*`.” Swept across 12 row-preserving verbs —
[`emoji_sentiment()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sentiment.md),
[`emoji_emotion()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_emotion.md)
(10 new columns),
[`emoji_emotion_label()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_emotion_label.md),
[`emoji_position()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_position.md),
[`emoji_ratio()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_ratio.md),
[`emoji_density()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_density.md),
[`emoji_type()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_type.md),
[`emoji_faceness()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_faceness.md),
[`emoji_risk()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_risk.md),
[`emoji_score()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_score.md),
[`emoji_token_cost()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_token_cost.md),
[`emoji_extract_nest()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_extract_nest.md).
**Zero violations.** Every new column is dotted.

**✅ `.emoji_n_scored` semantics.** The contract is precise — `NA` only
when the row has no emoji, `0` when it has emoji the lexicon cannot
score — and it holds exactly. Using pleading face (`U+1F97A`, Emoji
11.0, absent from the 2015-era Emoji Sentiment Ranking):

| Input        | `.emoji_n` | `.emoji_n_scored` | `.emoji_sentiment` |
|--------------|------------|-------------------|--------------------|
| `"no emoji"` | 0          | `NA`              | `NA`               |
| `"hi 😀"`    | 1          | 1                 | 0.5718             |
| `"new 🥺"`   | **1**      | **0**             | `NA`               |
| `NA`         | 0          | `NA`              | `NA`               |

The distinction the invariant exists to make — *no emoji* versus *emoji
the lexicon does not cover* — is exactly what the columns report. This
is also the column §10.7’s `emoji_coverage()` should aggregate.

**✅ The `U+FE0F`-stripped codepoint key.** Qualified and unqualified
forms resolve to the same lexicon row: `👍️` (`U+1F44D U+FE0F`) and `👍`
(`U+1F44D`) both score **0.5221143**, identical to seven decimal places.
The 0.2.1 key-normalisation fix is holding.

**⚠️ One new gap: `.emoji_*` is a reserved namespace, and nothing says
so.** A user whose data already contains `.emoji_n` has it **silently
overwritten** — tested with `.emoji_n = 999`, which came back as the
computed count with no warning. Two mitigating facts keep this small:
the prefix is a documented package convention, so collisions are
unlikely by accident; and **chaining verbs is harmless** —
[`emoji_sentiment()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sentiment.md)
then
[`emoji_position()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_position.md)
both write `.emoji_n` with the same value and the same meaning, so the
overwrite is benign in the normal workflow. **Action:** one sentence in
the package-level help stating that `.emoji_*` is reserved and will be
overwritten without warning. Not worth a runtime check.

**A note on fixtures, since it cost a cycle.** The first attempt at the
`.emoji_n_scored` test used `U+1FA7F` as a “recent but unscoreable”
glyph. It returned `.emoji_n = 0`, which looked like a detection failure
and was not — **`U+1FA7F` is not an assigned emoji at all** and is
absent from
[`emoji::emojis`](https://emilhvitfeldt.github.io/emoji/reference/emojis.html).
Verify a fixture glyph exists in the upstream table before concluding
anything from its absence; §10.13’s `emoji_sample()` would make this
class of mistake impossible, which is a further argument for it.

### 1.7 Lexicon coverage ceilings — the number that should be on every help page

*2026-08-30/31. §1.6 verified that `.emoji_n_scored` correctly
distinguishes “no emoji” from “emoji the lexicon cannot score”. This
asks the obvious next question: how often is the second case?*

| Lexicon | Rows | Keys in the reference table | Share of the 3790 distinct emoji | Undetectable by the engine |
|----|----|----|----|----|
| `emoji_sentiment_lexicon` (Emoji Sentiment Ranking, 2015) | 969 | 736 | **19.4%** | 270 (§4.7) |
| `emoji_emotion_lexicon` (EmoTag1200) | **150** | 150 | **4.0%** | 16 (10.7%) |

**⚠️ The denominator in this table was wrong and is corrected above
(measured 2026-09-03).** It read “share of the 5042 RGI emoji”, giving
19.2% and 3.0%. But 5042 is the *row* count of the reference table, and
that table carries the qualified and unqualified forms of the same emoji
as separate rows: there are only **3790 distinct codepoint keys**, which
is the number of distinct emoji identities the package can actually
detect and therefore the only denominator that answers “what fraction of
emoji can I score?”. The numerator was wrong in the other direction — it
counted lexicon *rows*, and 233 of the 969 are not in the reference
table at all. Corrected: sentiment **19.4%** (barely moved, by luck) and
emotion **4.0%** (not 3.0%). Any figure quoted downstream, including
`emoji_coverage()`’s, must use distinct keys.

**[`emoji_emotion()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_emotion.md)
can score four percent of the emoji that exist.** That is not a defect —
EmoTag1200 is a carefully annotated 150-glyph resource and the package
is right to bundle it — but it is a fact a user needs *before* they
conclude their corpus has no emotional content. A modern corpus is full
of post-2018 glyphs that no bundled lexicon has ever seen, and today the
only signal is a quiet `NA`.

**This makes §10.7’s `emoji_coverage()` the highest-value verb in the
whole document per line of code.** It is a `dplyr` summary over columns
that already exist:

``` r

emoji_coverage(data, text, lexicon = NULL)
#> n_occurrences, n_scoreable, coverage_rate,
#> n_distinct_glyphs, n_distinct_scoreable,
#> top_unscored  (the glyphs costing you the most, by frequency)
```

`top_unscored` is the part that turns a caveat into an action: it tells
a user exactly which glyphs to add via
[`register_emoji_lexicon()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/register_emoji_lexicon.md)
(§10.9) to fix their own analysis. **Promote it from wave 3 to 0.5.0** —
it is smaller than anything in §4 and it is what makes every affect verb
honest.

**Also state the ceiling in the help pages.** ✅ **Done 2026-09-03**,
with the corrected denominator:
[`?emoji_sentiment_lexicon`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sentiment_lexicon.md)
and
[`?emoji_emotion_lexicon`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_emotion_lexicon.md)
each open with a *How much of the catalogue this covers* section giving
the share of the 3790 distinct keys, naming the
[emoji](https://emilhvitfeldt.github.io/emoji/) version the figure is
computed against, and pointing at `.emoji_n_scored` as the per-row
answer. §10.5 and §10.9 already ask for locale- and domain-boundedness
statements; this is the same discipline applied to coverage, and it is
the one users are most likely to be silently burned by.

### 1.8 Two past fixes verified, one cosmetic inconsistency

**✅ The
[`emoji_search()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_search.md)
regex injection fix (0.3.0) holds.** Seven hostile patterns all return
safely rather than erroring or being interpreted:

| Pattern                | Result                                           |
|------------------------|--------------------------------------------------|
| `"("`                  | 11 hits (matched literally)                      |
| `"["`, `"a(b"`, `"\\"` | 0 hits, no error                                 |
| `".*"`                 | **0 hits** — proving literal matching, not regex |
| `"smil"`               | 28 hits                                          |

`".*"` returning zero rather than everything is the decisive check.
**Carry this into §4.6:** widening
[`emoji_search()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_search.md)
with `fields = c("name", "keywords", "aliases")` adds two new match
surfaces, and the escaping must be applied to each. Add these seven
patterns as regression fixtures against the widened verb.

**✅
[`emoji_score()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_score.md)
agrees with the specific scorers.** `emoji_score(lexicon = "sentiment")`
and
[`emoji_sentiment()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sentiment.md)
produce identical values (`all.equal` TRUE), so the generic is not a
second implementation that can drift.

**⚠️ But their column order differs**, which is the kind of thing an API
freeze should catch:

    emoji_sentiment() -> .emoji_n, .emoji_n_scored, .emoji_sentiment
    emoji_score()     -> .emoji_score, .emoji_n_scored, .emoji_n

Same three columns, reversed. Harmless for `dplyr` users who select by
name, and a nuisance for anyone using positional access or comparing
printed output. **Fix before 1.0’s freeze** (§9), not in 0.5.0 —
reordering columns is a user-visible change and should ride with the
release that is explicitly about API stability.

### 1.9 `emoji_sanitize()` has a reversibility hierarchy, and it is undocumented

*2026-08-31. §1.3 established that the shortcode round-trip is lossless
and that this is the package’s best undocumented capability.
[`emoji_sanitize()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sanitize.md)
is the verb built for LLM pipelines, so the question is which of its
policies preserve enough to restore.*

Reading the source answers half of it: `policy = "shortcode"` delegates
straight to `emoji_to_text(format = "shortcode")`, the path §1.3 proved
lossless. Tested against `"great 😀 work 👍 today"`:

| `policy` | Output | Restores original? | What is lost |
|----|----|----|----|
| `"keep"` | `great 😀 work 👍 today` | ✅ | nothing |
| `"shortcode"` | `great :grinning: work :+1: today` | ✅ | **nothing** |
| `"name"` | `great grinning face work thumbs up today` | ✗ | the delimiters — names are ordinary words |
| `"placeholder"` | `great [emoji] work [emoji] today` | ✗ | **which** emoji (position survives) |
| `"strip"` | `great work today` | ✗ | that an emoji was there at all |

**This is a graded hierarchy, and users need it stated as one.** The
policies are currently presented as five parallel options. They are not
parallel — they form a ladder of information loss, and the choice has a
consequence that is invisible until you try to put the emoji back:

> If your pipeline needs to restore emoji after the model call,
> `"shortcode"` is the **only** policy that permits it. `"placeholder"`
> keeps *where* but not *which*. `"strip"` keeps neither.

Put that in
[`?emoji_sanitize`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sanitize.md)
as a table, and use it as the spine of §1.3’s reversible-preprocessing
vignette section. It costs a help-page table and turns a five-way choice
into an informed one.

**Also verified clean:** `"strip"` does **not** leave double spaces
behind (`"great 😀 work"` -\> `"great work"`, not `"great work"`), which
is the obvious way this kind of rewriting goes wrong.

**And
[`emoji_context()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_context.md)’s
window edges are correct** — worth recording since it is the
second-hottest path in §8’s benchmark and windowing is easy to get
wrong:

| Input (`window = 2`, words)        | left context | right context |
|------------------------------------|--------------|---------------|
| `😀 starts here now` (emoji first) | *(empty)*    | `starts here` |
| `ends here now 😀` (emoji last)    | `here now`   | *(empty)*     |
| `a 😀 b 👍 c` (two emoji)          | `a` / `a b`  | `b c` / `c`   |

Each emoji gets its own row with its own asymmetric window, and boundary
cases yield empty strings rather than `NA` or an error. No action
needed.

------------------------------------------------------------------------

### 1.10 The audit in one table

Twelve rounds, 2026-08-30/31. **Four defects, one gap, five contracts
confirmed.** Every row is reproducible from §12’s fixtures.

| § | Finding | Status | Lands in |
|----|----|----|----|
| 1.1 | `.emoji_rel_position` is codepoint-based: a final family emoji reports **0.333** | ✅ **fixed 0.4.0** (§1.11) | shipped |
| 1.2 | `🇽🇽` (invalid RI pair) is detected and would map to a fabricated ISO code | 🔴 **defect** | 0.5.0 — blocks §4.2 |
| 1.2 | Orphan skin-tone modifiers counted as emoji, corrupting modified÷modifiable | 🔴 **defect** | 0.5.0 — blocks §4.1 |
| 1.5 | Aggregators pool grouped data **silently** — the count was 7, not 3, and 2 of the 3 named were misdiagnosed | ✅ **fixed 0.4.0** (§1.11) | shipped |
| 1.5 | Missing / ambiguous / misspelled column reported as internal `` `var` `` — package-wide, not four verbs | ✅ **fixed 0.4.0** (§1.11) | shipped |
| 1.6 | `.emoji_*` is a reserved namespace; user columns overwritten, undocumented | 🟠 gap | 0.5.0 (one sentence) |
| 1.7 | Emotion lexicon covers **150 glyphs — 3.0% of RGI**; sentiment 19.2% | 🟠 honesty | 0.5.0 — `emoji_coverage()` |
| 1.8 | [`emoji_score()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_score.md) and specific scorers return the same columns **reversed** | 🟠 cosmetic | 1.0.0 (API freeze) |
| 1.9 | [`emoji_sanitize()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sanitize.md)’s five policies form an undocumented **loss ladder** | 🟠 docs | 0.5.0 |
| 1.3 | Shortcode round-trip is **lossless** on tone, flags, ZWJ, keycaps, FE0F | ✅ confirmed | advertise it (§1.3) |
| 1.4 | Collation invariance holds across 7 verbs; detection survives `LC_CTYPE=C` | ✅ confirmed | — |
| 1.6 | Dotted-column naming: 0 violations / 12 verbs | ✅ confirmed | — |
| 1.6 | `.emoji_n_scored` distinguishes *no emoji* from *unscoreable* exactly | ✅ confirmed | — |
| 1.6 | `U+FE0F`-stripped key: bare and qualified 👍 both score 0.5221143 | ✅ confirmed | — |
| 1.8 | 0.3.0’s [`emoji_search()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_search.md) regex-injection fix holds (`".*"` → 0 hits) | ✅ confirmed | extend to §4.6’s `fields=` |
| 1.9 | [`emoji_context()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_context.md) window edges correct; `"strip"` leaves no double space | ✅ confirmed | — |
| 4.8 | Emoji counts are compositional and zero-inflated; structural ≠ count zeros | 🔵 new duty | 0.5.0 / 0.6.0 |

### 1.11 The pre-submission polish pass — what it fixed, and what the audit got wrong

*2026-09-03, while 0.4.0 sat waiting for CRAN. Method: call **every**
export with a deliberately awkward input — grouped, column omitted,
column misspelled, column selecting two — and read what comes back.
Three of the findings below are not in §1.1-§1.9 at all, which is the
point: the audit read the source, and this pass ran it.*

**Two grouped-data bugs that the §1.5 sweep walked straight past.**

1.  **Six verbs hard-errored on grouped input.**
    [`emoji_to_text()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_to_text.md),
    [`text_to_emoji()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/text_to_emoji.md),
    [`emoji_sanitize()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sanitize.md)
    (every policy),
    [`emoji_context()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_context.md)
    and
    [`emoji_collocations()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_collocations.md)
    resolved their column through
    [`dplyr::select()`](https://dplyr.tidyverse.org/reference/select.html),
    which re-adds the grouping columns, so the selection returned two
    names and the verb died with
    `` `text` must select exactly one column `` — blaming an argument
    the user had got right. §1.5 tested only whether verbs *warn*, so a
    verb that errors before it can warn read as “does not warn”.
2.  **The row-at-a-time verbs silently dropped the grouping.**
    `tibble::as_tibble(data)` strips `grouped_df`, so
    `group_by(author) |> emoji_sentiment(text) |> summarise(...)`
    collapsed to one corpus-wide row. §1.5 concluded these verbs were
    right to stay silent because “grouping cannot change their answer” —
    true of the verb, false of the pipeline it sits in. They now carry
    groups through, as `mutate()` and
    [`filter()`](https://rdrr.io/r/stats/filter.html) do.

**§1.5’s aggregator count was wrong in both directions.** It named three
silent poolers; the real list is **seven** —
[`emoji_version_profile()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_version_profile.md),
[`emoji_trend()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_trend.md),
[`emoji_turnover()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_turnover.md),
[`emoji_seasonality()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_seasonality.md),
[`emoji_adoption_lag()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_adoption_lag.md),
[`emoji_collocations()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_collocations.md),
[`emoji_incongruity_profile()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_incongruity_profile.md)
— and two of its three
([`emoji_categorize()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_categorize.md),
[`emoji_ngrams()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_ngrams.md))
are *not* aggregators: both emit one row per input row (or per n-gram
*of* an input row) and pool nothing, so a guard there would be noise.
The lesson is that the fixture (“group `a` is faces, group `b` is
flags”) only distinguishes verbs whose output shape can hide the
pooling; it cannot tell a per-row verb from an aggregator. Classify by
output shape first, then test.

Two more, in the same shape as §1.5’s own lesson:
[`emoji_cooccurrence()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_cooccurrence.md)
and
[`emoji_flag_ambiguous()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_flag_ambiguous.md)
warned under the name of the verb they delegate to, so the message named
a function the user never called and lifecycle’s per-topic dedup then
silenced it for anyone who had already called
[`emoji_pairs()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_pairs.md)
/
[`emoji_frequency()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_frequency.md).
And the guard is now **one helper**, not ten copies — which is the only
change that stops the count being wrong again. Two mechanical traps it
has to handle, both found by testing: lifecycle’s `env`/`user_env`
default to the *helper’s* frames, which made it append “Please report
the issue at …” to a warning about the user’s own data; and because
`what` carries the verb’s name, dedup is per verb, so all fourteen
aggregators warn in one session — §1.5’s “one fresh R process per verb”
is no longer needed to test them.

**The `` `var` `` leak was package-wide.** §1.5 found it in four time
verbs. It was in all 38 column-resolution sites, because every one of
them used
[`dplyr::pull()`](https://dplyr.tidyverse.org/reference/pull.html),
whose formal is `var`. Three messages, all naming an argument that
appears in no tidyEmoji signature: omitted (`` `var` is absent ``), two
columns (`` `!!enquo(var)` must select exactly one column ``), and — the
common one — misspelled, reported as `object 'txet' not found`, as if
the user’s own code had a free variable in it. One resolver now handles
all of them, names `text` / `time` / `text_score` / `doc_id`, and hands
the not-found case to `select()`, whose message says which column is
missing.

**[`emoji_extract_nest()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_extract_nest.md)
accepted a missing column.** It was the one verb that resolved
`{{ text }}` in the data mask instead of as a selection, so
`emoji_extract_nest(df)` returned a bogus empty list-column rather than
erroring — the exact failure mode the 0.4.0 “invalid values error, they
are not absorbed” invariant exists to prevent, in the one verb the sweep
that established that invariant did not reach.

**§1.1 is fixed, and it needed no
[stringi](https://stringi.gagolewski.com/).** `.emoji_rel_position` now
counts each *located emoji* as one position and every other code point
as one, which is exactly the denominator the §1.1 table calls correct:
`"hi 🇺🇸"` and `"hi 👨‍👩‍👧‍👦"` both score 1.000. `.emoji_first` / `.emoji_last`
stay in code points, because they are documented as
[`substr()`](https://rdrr.io/r/base/substr.html) offsets and are correct
as such. **This unblocks §4.3 without §4.5**: full UAX \#29 segmentation
is still the right long-term engine, but it is no longer a prerequisite
for the accessibility verbs. The logical-vs-visual-order caveat §1.1
raises is now in the help page.

**Housekeeping the same pass found:** `R CMD check --as-cran` was
reporting `.claude` as a hidden directory shipped in error, and
[`?tidyEmoji`](https://pursuitofdatascience.github.io/tidyEmoji/reference/tidyEmoji-package.md)
was stale relative to `DESCRIPTION` (missing the whole paragraph about
interpretation risk, context, time, incongruity and the sanitiser).

**Round 2, same day — degenerate inputs, argument absorption, the
registry.**

- **“Empty input returns a *typed* zero-row tibble” was false in five
  verbs.**
  [`emoji_density()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_density.md),
  [`emoji_ratio()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_ratio.md),
  [`emoji_faceness()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_faceness.md)
  and
  [`emoji_risk()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_risk.md)
  built their columns with
  [`ifelse()`](https://rdrr.io/r/base/ifelse.html), which takes the
  result’s type from its arguments, so a zero-row call returned
  `logical` where a populated one returns `double` or `integer`;
  [`emoji_tokens()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_tokens.md)
  returned an unspecified `.emoji`. Split-map-bind over a corpus
  therefore produced a different schema depending on whether any chunk
  happened to be empty. The fix is allocate-then-fill, and it changed no
  value — §12 has the fixture pinning all seven columns of the three
  affected verbs.

- **The `head(n = -1)` bug class had a second half nobody swept:
  fractional counts.** `top_n_emojis(n = 2.5)` returned two rows,
  `emoji_context(window = 2.7)` used a window of two,
  `emoji_ngrams(n = 2.9)` built bigrams. Identical failure mode — the
  number the user wrote is not the number used — and it survived the
  0.4.0 audit because that audit looked for *negative* and
  *non-numeric*, not *non-integral*. `n`, `top_n`, `window` and `min_n`
  now require a whole number, with `Inf` still meaning “all” where
  head() is the consumer. `emoji_ngrams(sep = )` was unchecked entirely:
  `NA` or a number reached `paste(collapse = )` and surfaced as
  `invalid 'collapse' argument` over an internal `vapply` stack, and a
  length-2 `sep` silently used the first element.

- **The lexicon registry accepted two registrations it could never
  honour.** A name the bundled lexicons answer to (`novak2015`,
  `sentiment`, `emotion`, …) registered successfully, appeared in
  [`emoji_lexicons()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_lexicons.md)
  as a *duplicate `name`*, and was unreachable, because
  `.emoji_lexicon_lookup()` resolves the bundled names before it
  consults the registry. And a `tbl` with no usable score column
  registered happily, failing only at first use with a message naming
  `tbl` — an argument of a call that had already returned. Both are now
  refused at registration.

- **The presentation-selector limitation was documented in the one place
  a user counting emoji would not look**
  ([`?emoji_sentiment_lexicon`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sentiment_lexicon.md)).
  It is now a *Detection* section on
  [`?tidyEmoji`](https://pursuitofdatascience.github.io/tidyEmoji/reference/tidyEmoji-package.md),
  with the catalogue-wide measurement (§4.7, corrected there) and the
  reason the default cannot change. **Round 3, same day — the time
  verbs, the numeric transforms, and doc drift.**

- **A string time column silently shrank the corpus.**
  `.emoji_as_date()` errors only when *nothing* parses; a column with a
  few `"2020-13-45"` or `"Jan 5 2020"` values turned those into `NA`,
  and every time verb then dropped the row — indistinguishable in the
  result from a genuinely missing date. It now reports the count and the
  first unreadable value. A real `NA` still passes silently, which is
  the distinction that matters.

- **[`?emoji_sanitize`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sanitize.md)
  now carries §1.9’s loss ladder**, re-verified independently:
  `"shortcode"` is the only rewriting policy that round-trips, and it
  survives skin tones, flags, ZWJ families, keycaps and `U+FE0F` forms.
  §1.9’s action item is discharged.

- **Two `@return` sections named fewer columns than the verb returns.**
  [`emoji_emotion()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_emotion.md)
  omitted all eight emotion columns plus `.emoji_n` / `.emoji_n_scored`,
  and said nothing about `long = TRUE` returning a different *shape*;
  [`emoji_emotion_label()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_emotion_label.md)
  omitted two columns. Found by a mechanical cross-check — parse every
  `\value`, run every `\examples`, diff the dotted column names — which
  is worth keeping as a release check because `R CMD check` cannot see
  this class of error.

- **I introduced a regression and caught it the same round**, worth
  recording because the invariant is easy to break: em-dashes in a
  roxygen comment made `R/tidyEmoji.R` non-ASCII, which 0.4.0 had
  specifically cleaned up so the PDF manual builds everywhere. Use `--`
  in roxygen, and grep `grep -lP "[^\x00-\x7F]" R/*.R` before calling a
  doc pass done.

- **`README.md` was not reproducible from `README.Rmd`** — one
  hand-edited straight apostrophe where the render produces a curly one.
  Re-rendered, so it is now byte-identical to its source and drift
  becomes visible.

- **Checked and found sound this round, so it need not be re-audited:**
  the `tfidf`, `binary`, rank-scaling, z-scoring, PMI and entropy paths
  all match hand computation, including their degenerate cases (single
  document, all-tied scores, one non-`NA` value, zero-length input); the
  ISO-Monday week bucket is correct across a year boundary and `%u` /
  `month.abb` are locale-independent; collation invariance still holds
  across nine ordered outputs under `C` and `en_US.UTF-8` after the
  [`emoji_dfm()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_dfm.md)
  doc-column rewrite, and detection survives `LC_CTYPE=C`;
  [`emoji_context()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_context.md)
  character windows and offsets stay exact with a seven-code-point emoji
  in the string; and 20k rows costs ~1.2s per verb (3.1s for
  [`emoji_context()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_context.md))
  with no super-linear term.

- **One conflict resolved as documentation, not code:** under
  `emoji_incongruity(where = "final")` a row whose emoji are all
  mid-sentence gets `.emoji_n_scored = NA` with `.emoji_n > 0`, which
  contradicts §1’s invariant as it was worded. The verb’s help page
  states this deliberately, so §1’s wording is what was wrong; it is now
  corrected there rather than the behaviour being changed.

**Round 4, same day — the packaging surface and the bundled data.**

- **§1.7’s coverage denominator was wrong, and the corrected figure is
  now on the help pages.** It divided by 5042, the reference table’s
  *row* count; the table stores an emoji’s qualified and unqualified
  forms as separate rows, so there are only **3790 distinct codepoint
  keys** — the number of distinct emoji the package can actually detect,
  and the only denominator that answers “what fraction can I score?”.
  The numerator was wrong the other way, counting lexicon rows when 233
  of the sentiment lexicon’s 969 are not in the reference table at all.
  Corrected: sentiment **19.4%** (barely moved, by luck), emotion
  **4.0%** rather than 3.0%. §1.7’s action item is discharged without
  building `emoji_coverage()`:
  [`?emoji_sentiment`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sentiment.md),
  [`?emoji_emotion`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_emotion.md)
  and both dataset pages now state the share, name the
  [emoji](https://emilhvitfeldt.github.io/emoji/) version it is measured
  against, and point at `.emoji_n_scored`.
- **`cran-comments.md` claimed no behavioural change beyond
  [`emoji_dfm()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_dfm.md).**
  Three rounds of polish had made that false — the `.emoji_rel_position`
  denominator, grouping preservation, zero-row column types, the newly
  rejected arguments and the new date warning are all user-visible. The
  submission note now lists them, because a reviewer reading an
  inaccurate “no change” line is worse than one reading a longer
  accurate list.
- **The bundled data’s own arithmetic is now pinned by tests**, having
  been verified by hand: `negative + neutral + positive == occurrences`,
  `sentiment_score == (positive - negative) / occurrences`,
  `sentiment_label` agrees with the sign, `position` and the eight
  emotion scores are in range, both lexicons have unique non-missing
  keys,
  [`emoji_ambiguity()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_ambiguity.md)’s
  `n_annotations` *is* the lexicon’s `occurrences` and its shares sum to
  1 with entropy bounded by `log(3)`, and the category crosswalk matches
  the reference table’s ten groups. A `data-raw/` rebuild that quietly
  changed one of these would previously have surfaced only as slightly
  wrong scores.
- **Checked and found sound this round:** every export has an `Rd`
  alias, is named in the test suite, and is reachable from
  `_pkgdown.yml` (the only unlisted export,
  [`emoji_tweets()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_filter.md),
  is an alias inside `emoji_filter.Rd`, and pkgdown indexes topics); all
  63
  [`utils::globalVariables()`](https://rdrr.io/r/utils/globalVariables.html)
  entries are still referenced in `R/`; every `Suggests` package is
  actually used;
  [`emoji_search()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_search.md)
  is regex-safe on every metacharacter (`fixed = TRUE` throughout), so
  0.3.0’s injection fix holds; the vignette’s “10 categories” claim
  matches the installed reference table.
- **One API wart recorded rather than fixed, because fixing it breaks
  the interface:** `by` means two unrelated things — the time bucket in
  [`emoji_trend()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_trend.md)
  /
  [`emoji_turnover()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_turnover.md),
  the glyph-column name in
  [`emoji_score()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_score.md)
  /
  [`register_emoji_lexicon()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/register_emoji_lexicon.md)
  — and `top_n_emojis(n = )` is the row limit that two other verbs call
  `top_n`. Both belong in §9’s 1.0 API freeze, not in a patch to a
  release that is already at CRAN’s door.

**Round 5, same day — reversibility measured, and the engine’s own
edges.**

- **The reversibility claim round 3 put in
  [`?emoji_sanitize`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sanitize.md)
  was an overclaim, and is now a measurement.** “Lossless … round-trip
  exactly” is false at the byte level: run over every glyph in the
  reference table that has a shortcode (4853), 23 do not come back
  byte-identical. Every one of the 23 differs by exactly one code point,
  `U+FE0F`, which the round trip may add or drop – `U+270C` returns as
  `U+270C U+FE0F`, and the unqualified detective / golfer /
  weight-lifter ZWJ sequences gain it before the joiner. **Emoji
  identity is preserved for 100% of the 4853**; byte-identity for 99.5%.
  That is the stronger claim and it is the one on the help page now,
  with a test over the whole catalogue holding it there. §1.3’s
  “lossless” finding needs the same qualification wherever it is quoted.
- **`emoji_key()` had two “no key” sentinels.** `NA` for empty or
  missing input, `""` for a string of nothing but variation selectors –
  so every consumer had to remember to filter both, and only
  `.emoji_lexicon_record()` actually did (`keys != ""`). Now `NA` in all
  three cases.
- **`data-raw/crosswalks.R` genuinely reproduces the bundled data.**
  Both crosswalks rebuild byte-identically against
  [emoji](https://emilhvitfeldt.github.io/emoji/) 16.0.0, so the
  `@source` claim on the two dataset pages is true. Worth recording
  because it had never been checked. Two notes for the next rebuild: the
  script carries its own copy of `emoji_key()` as `emoji_key2()`, which
  will drift from the package’s if one changes without the other; and
  the *sentiment* script fetches a third-party GitHub mirror of the
  CLARIN.SI release rather than the canonical handle the help page cites
  – the arithmetic checks out (round 4), but the provenance chain runs
  through a mirror that could vanish.
- **The ZWJ repair is correct on every edge case**, which matters
  because `.emoji_merge_zwj()` is a hand-rolled patch over upstream’s
  regex: a joiner binds only *between* two emoji, so a leading,
  trailing, doubled or space-separated ZWJ correctly does not merge, and
  a three-emoji chain does. Pinned by tests, along with
  `emoji_canonical()`’s unknown-glyph passthrough and
  `.emoji_id_split()`’s first-appearance / NA-group behaviour.
- **Also checked and sound:** no help-page example emits a warning,
  message or error; chaining six row verbs produces no duplicate or
  inconsistent column;
  [`emoji_sentiment()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sentiment.md)
  and
  [`emoji_to_text()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_to_text.md)
  are idempotent; every rewriting
  [`emoji_sanitize()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sanitize.md)
  policy leaves a corpus that
  [`emoji_summary()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_summary.md)
  reads as zero emoji; and `emoji_context(keep_text = TRUE)` renames the
  kept column when it collides with one of its own outputs.
- **Test-suite polish:** four `expect_error()` calls had no message
  pattern, so they passed on *any* error, including one raised for the
  wrong reason. Given patterns.

**Round 6, same day — a cross-verb invariant suite, and what it
caught.**

The method changed this round. Rounds 1-5 asked “does this verb
behave?”; this one asks “do two verbs still agree?”, which is the
question no per-verb test file can answer. 33 relations were written
down and run over one fixture, and they are now
`tests/testthat/test-invariants.R` – a deliberately separate file,
because it is the only one that fails when the shared engine drifts
while every individual verb’s own tests still pass.

- **It caught a real inconsistency inside
  [`emoji_risk()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_risk.md).**
  A row holding emoji the ambiguity lexicon cannot score got
  `.emoji_n_scored = 0` (right) but `.emoji_n_ambiguous = NA` (wrong) –
  two counts, one row, opposite treatments of the same situation, and
  the `@return` already promised `NA` only for rows with no emoji. The
  count of ambiguous glyphs *found* is zero; the two averages stay `NA`
  because there is nothing to average. **Note the contrast with §1.11
  round 3’s `where = "final"` case**: there the help page documented the
  `NA` deliberately and §1’s wording was what needed fixing, here the
  help page was right and the code was wrong. Reading the `@return`
  first is what distinguishes the two.
- **Everything else in the sweep held**, and it is worth listing because
  these are the relations a future change is most likely to break: six
  independent paths agree on the corpus total
  ([`emoji_tokens()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_tokens.md)
  rows,
  [`emoji_context()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_context.md)
  rows, `sum(emoji_extract_unnest()$.emoji_count)`,
  `sum(emoji_frequency()$n)`, `sum(emoji_dfm()[, -1])`,
  `nrow(emoji_ngrams(n = 1))`, plus
  [`emoji_version_profile()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_version_profile.md),
  [`emoji_trend()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_trend.md)
  and
  [`emoji_seasonality()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_seasonality.md)
  totals); every verb reporting `.emoji_n` reports the same one; the
  counts nest (`n_face <= n_typed <= n`, `n_scored <= n`,
  `n_ambiguous <= n`);
  [`emoji_pairs()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_pairs.md)
  is identical to `emoji_cooccurrence(diagonal = FALSE)` and the
  diagonal equals the binary dfm’s document frequency; the aggregate
  shares sum to 1; and a seven-code-point family is one emoji in all
  four places that count it.
- **The shortcode grammar is exactly right, and no shortcode is
  ambiguous.** All 4853 reference shortcodes and all 4698 GitHub aliases
  fit the documented `[A-Za-z0-9_+-]+` token, so none is unrecoverable
  by
  [`text_to_emoji()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/text_to_emoji.md);
  and although 825 shortcodes map to more than one reference row,
  **every one of those 825 groups shares a single codepoint key** – they
  are the `U+FE0F` pairs again. That is the mechanism behind round 5’s
  23 byte-level exceptions, and it means
  [`as_emoji()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/as_emoji_name.md)
  is deterministic rather than merely lucky.
  [`as_emoji()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/as_emoji_name.md)
  resolves all 4698 aliases.
- **Also checked and sound:** `inst/CITATION` parses into three entries
  with the right conditional-citation guidance;
  [`emoji_provenance()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_provenance.md)
  matches reality on all five fields and
  [`emoji_unicode_version()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_unicode_version.md)
  agrees with the reference table’s maximum; every glyph-bearing output
  column is marked UTF-8, ASCII-only results are marked unknown (which
  is correct), a mixed latin1/UTF-8 input column survives every verb,
  and [`identical()`](https://rdrr.io/r/base/identical.html) /
  [`match()`](https://rdrr.io/r/base/match.html) still work across the
  encoding difference.

**Round 7, same day — the NA-conflation family, chased to its end.**

Rounds 3 and 6 each found one verb conflating “no emoji” with “nothing
scorable” in a column that means something different for each. This
round asked the question of every verb at once, using a glyph that is
*detected but not catalogued* – a ZWJ sequence UAX \#29 GB11 makes one
grapheme and no reference table lists, which is precisely what a corpus
newer than the installed [emoji](https://emilhvitfeldt.github.io/emoji/)
contains. It is the sharpest available probe, because
`.emoji_merge_zwj()` exists to detect exactly these.

- **[`emoji_categorize()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_categorize.md)
  silently dropped rows that contain emoji.** It filtered on
  `!is.na(cats)`, and `cats` is `NA` both for “no emoji” and for “emoji
  absent from the reference table”. So a row whose only glyph is newer
  than your catalogue disappeared – and it is the rows a user with stale
  Unicode coverage most needs to see. **0.2.1 already shipped a fix for
  one instance of this** (“emoji_categorize keeps qualified emoji
  (U+FE0F) rather than dropping the row”, still in the regression file):
  the *join* was repaired, the conflation was not, so the bug simply
  waited for a different glyph. Filter is now on `lengths(lst) > 0L`,
  and §1’s `nrow(emoji_categorize()) <= nrow(emoji_filter())` becomes an
  equality – strengthened in the round-6 invariant file.
- **Every other verb was already honest about the same glyph**, and that
  is now pinned so nobody “tidies” the `NA`s away:
  [`emoji_position()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_position.md)
  counts it,
  [`emoji_type()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_type.md)
  keeps the row with `NA`,
  [`emoji_faceness()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_faceness.md)
  reports `n_typed = 0`,
  [`emoji_sentiment()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sentiment.md)
  reports `n_scored = 0`,
  [`emoji_frequency()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_frequency.md)
  lists the glyph with `name = NA`,
  [`emoji_version_profile()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_version_profile.md)
  puts it in the documented `version = NA` row, and the rewriting verbs
  leave it alone rather than dropping it. Reporting an unknown glyph
  *with* `NA` metadata is what tells a user their catalogue is behind;
  dropping it tells them nothing.
- **The taxonomy this family has produced, worth keeping for the next
  audit.** Three verbs conflated the two states and each needed a
  different resolution: `emoji_incongruity(where = "final")` – help page
  documented the `NA` deliberately, so §1’s *wording* was wrong (round
  3);
  [`emoji_risk()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_risk.md)’s
  `.emoji_n_ambiguous` – help page promised `NA` only for no-emoji rows,
  so the *code* was wrong (round 6);
  [`emoji_categorize()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_categorize.md)
  – help page promised “rows containing emoji”, so the *code* was wrong
  and a row went missing entirely (round 7). **Read the `@return` before
  deciding which side to fix**, and treat a dropped row as strictly
  worse than a wrong `NA`.
- **Checked and sound:** no `|>` or `\(x)` in executable code, so the
  sources still parse under the declared `R (>= 3.5.0)`; every reference
  glyph has both a functional type and a Unicode group, so
  [`emoji_type()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_type.md)
  /
  [`emoji_faceness()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_faceness.md)
  /
  [`emoji_categorize()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_categorize.md)
  can only produce `NA` for a row with no emoji or an uncatalogued one.
- **One inconsistency recorded rather than changed.**
  `Depends: R (>= 3.5.0)` is right for the package’s own code and for
  the `LazyData` serialisation floor, but the *installed* dplyr 1.2.1
  and tidyr 1.3.2 need R \>= 4.1.0 and rlang 1.3.0 needs R \>= 4.0.0.
  Resolution is supposed to fetch older dependency versions for an old
  R, and `dplyr (>= 1.1.0)` is satisfiable on R 3.5 in principle – but
  CRAN serves only the newest, so an R 3.5 install fails in practice.
  Raising the floor would restrict users for no gain today; it belongs
  in the same 1.0 pass as the API freeze.

**Round 8, same day — the biggest defect of the eight rounds, in
detection.**

Round 7’s probe was “a glyph that is detected but not catalogued”. This
round inverted it: **a glyph that IS catalogued but whose components are
not all detectable**. That set turns out to be large, and the failure in
it is the worst kind the package can have.

- **232 of the catalogue’s 2501 ZWJ sequences were read as their
  component emoji.** `.emoji_merge_zwj()` implemented GB11 as “the gap
  between two matches is exactly one ZWJ”. When a sequence’s middle
  component is a text-presentation code point it is not matched either,
  so the gap becomes `ZWJ + component + ZWJ` and the rule declined.
  **The damage was a wrong count, not a missing one.** The 2023-2024
  “facing right” additions are the clearest case:

  ``` R
  U+1F6B6 U+200D U+2640 U+200D U+27A1 U+FE0F  "woman walking facing right"
  ```

  arrived as two emoji, `person walking` and `right arrow` – neither of
  which the text contains. A frequency table, a dfm column, a
  co-occurrence edge and a sentiment score were all computed on emoji
  that were never written.

  **Fix:** also merge when the gap contains a joiner *and the union of
  the two spans is itself a catalogued emoji*. That test is exact – it
  can only join code points that really do spell one emoji – and rule 1
  still covers sequences newer than the catalogue, which is the reason
  the repair exists. 2499 of 2501 now read as one glyph; the two that do
  not are unqualified spellings whose every component needs `U+FE0F`,
  and their qualified forms are found. Cost is +12% on ZWJ-bearing
  strings only. Verified against all 2501, and against a set of things
  that must *not* merge.

  **This is the third time the presentation-selector limitation (§4.7)
  has surfaced as a different bug.** Round 2: glyphs not detected at
  all. Round 5: 23 byte-level round-trip exceptions. Round 8: 232
  sequences mis-split. §4.7 should be re-read as a *root cause* with
  several symptoms, not one documented caveat – and the 0.5.0
  `presentation =` work should be scoped against all three.

- **A round-5 measurement had to be re-derived because of the fix**,
  which is the honest consequence and worth recording as a pattern: the
  shortcode round trip’s byte-identity rate fell from 99.5% to **94.8%**
  (23 exceptions to 252), because a merged sequence now resolves to the
  catalogue’s *qualified* spelling where its split components had been
  byte-exact by accident. **Identity is still preserved for 100% of
  4853**, and every exception is still `U+FE0F` alone. The help page and
  the test threshold were re-measured rather than the fix being
  softened.

- **`emoji_dfm(doc_id = )` silently destroyed the id column on a name
  collision.** The result names one column per glyph, so a `doc_id`
  column named with a glyph in the corpus was overwritten by the count
  column and the identifiers vanished. Now an error naming the column to
  rename.

- **Checked and sound:** 189 catalogued glyphs have no GitHub alias, and
  every verb handles them – `emoji_to_text(format = "shortcode")` leaves
  them as the glyph rather than emitting `:NA:`, and
  `top_n_emojis(duplicated = TRUE)` keeps them (0.4.0’s left_join fix
  holds). A lone skin-tone modifier is detected, typed `component` and
  reported as `medium skin tone` – honest, and the denominator question
  §1.2 raises is a 0.5.0 accounting decision rather than a current wrong
  number.

**Round 9, same day — the round-8 test was too weak, and the sharp test
found more.**

Round 8 asserted `sum(n > 1L) == 0` over the catalogue’s ZWJ sequences:
*did it come back as one glyph?* That is the wrong question. **A
sequence whose only detectable component is its first still yields
exactly one match**, so the test passed while the answer was a different
emoji. Sweeping all 5042 spellings for *identity* rather than count
found **791 that return one glyph which is not the input** –
`U+2764 U+200D U+1F525` (“heart on fire”) arriving as `U+1F525`
(“fire”), `U+1F9D4 U+200D U+2642` (“man: beard”) as `U+1F9D4`.

- **The sharp invariant is an *orphaned joiner*: a `U+200D` left outside
  every detected span.** It cannot be satisfied by a partial match, and
  it is what the test now asserts. Under it:
  - **All 3790 canonical (fully-qualified) spellings segment cleanly** –
    zero orphaned joiners, and each is detected as exactly itself. This
    is the spelling a keyboard emits, so it is the one that matters.
  - **The real 2000-tweet corpus has 38 rows containing a joiner and
    zero mis-segmented**, and every glyph it yields resolves to a known
    name.
  - **793 alternate spellings still lose a joiner** – 745 without
    `U+FE0F` and 48 partially qualified. Every affected emoji has a
    canonical spelling that is exact, so nothing is unreachable.
- **Decision: do not extend the algorithm now, document and measure
  instead.** Fixing the residual needs a *lone-match extension* pass
  (grow a match over a `ZWJ + undetected` run while the span stays
  catalogued) – exact, but a new search on the hottest path, for a case
  with zero exposure in real text and no unreachable emoji. It belongs
  with 0.5.0’s `presentation =` work, which now has all four symptoms of
  §4.7 to cover. The residual is stated in
  [`?tidyEmoji`](https://pursuitofdatascience.github.io/tidyEmoji/reference/tidyEmoji-package.md)
  and pinned by a test with a bound, so a change to it is visible.
- **A methodological correction worth recording, because I made the
  mistake mid-round.** Checking “does the real corpus contain a
  misdetected spelling?” with `grepl(spelling, text, fixed = TRUE)`
  reported 32 hits – all spurious, because a minimally-qualified
  spelling is a *prefix* of the fully-qualified one the text actually
  holds. Substring containment cannot answer a question about
  segmentation. The orphaned-joiner test can, and gave zero.

**Round 10, same day — round 9’s deferral was wrong, and reversing it
landed the strongest claim in the file.**

Round 9 measured a 793-spelling residual and chose to document it rather
than fix it, on the grounds that the fix would put “a new search on the
hottest path” for a case with no real-corpus exposure. **That estimate
was made without measuring.** Measured: the fix is gated on the string
actually having an orphaned joiner, so well-formed text pays for one
scan and nothing else – **+6.6% on a 20k-row mixed corpus** – and it
takes orphaned joiners from 793 to 2 and exact detection of the
reference table from 80.1% to **95.8%**. That is an easy trade, and the
deferral was simply a bad call.

- **Rule 3: grow a lone match outwards.** Both merge rules need two
  matches; a sequence whose only detectable component is one of its
  parts gives one, so there is no pair and it arrives as that part.
  Bounded by the longest catalogued emoji (10 code points, measured),
  never crossing a neighbouring match, longest-match-wins, and skipped
  unless there is an orphaned joiner. `U+2764 U+200D U+1F525` is now
  “heart on fire” rather than “fire”; `U+1F9D4 U+200D U+2642` is “man:
  beard” rather than “person with beard”. False-positive safety checked
  against twelve cases that must not merge, including
  `laugh + bare-heart-on-fire`, which correctly stays two glyphs.
- **The round-trip figure stopped drifting once the claim was stated
  correctly.** It moved three times across rounds 3, 5, 8 and 10 (exact
  -\> 99.5% -\> 94.8% -\> 79.5%) and each move was *caused by detection
  getting better*: a spelling that used to fragment now merges and
  normalises to canonical. Restricting the measurement to what real text
  holds gives the strong, stable claim: **over all 3790 canonical
  spellings the round trip is 100% byte-identical**, and over the
  alternates every difference is `U+FE0F` alone. **The lesson is about
  test design**: a threshold on an aggregate rate is not an invariant,
  and asserting one forced three edits that each looked like a
  regression. The tests now assert the exact property (byte-exact on
  canonical spellings; identity preserved and every difference `U+FE0F`
  on the rest) with only a sanity bound on the rate.
- **§4.7’s symptom list is now four, three of them fixed.** Not detected
  at all (round 2, documented, deliberate); round-trip normalisation
  (round 5, reframed as correct behaviour); 232 sequences split (round
  8, fixed); 791 sequences read as a component (rounds 9-10, fixed).
  What remains for 0.5.0’s `presentation =` argument is only the first,
  which is a policy choice rather than a defect.

**Round 11, same day — re-verifying what rounds 8 and 10 could have
invalidated.**

Changing detection changes the basis of every number the docs quote
about detection. Rather than assume the fixes were confined, every such
figure was re-measured against the installed catalogue.

- **All of them still hold**, because the fixes touched only joined
  sequences while the documented figures are about single
  text-presentation code points: 1252 catalogue emoji carry `U+FE0F` and
  216 of those are undetectable without it; 270 sentiment-lexicon rows
  (27.9%) are undetectable, of which 57 are RGI in text-presentation
  form and 213 are not emoji at all; 233 lexicon rows are absent from
  the reference table; the coverage shares are 19.4% and 4.0% of 3790
  distinct keys. No doc edit needed – which is the point of checking
  rather than assuming.
- **The blast radius on well-formed text is zero, and that is the number
  a reviewer wants.** The bundled 2000-tweet corpus has 38 rows
  containing a joiner and its counts are unchanged (560 of 2000 rows
  with emoji, 187 distinct emoji, 900 occurrences, no `NA` names, 18 ZWJ
  glyphs totalling 39 occurrences); `README.md` re-renders byte for
  byte. The corpus already used fully-qualified spellings, which rule 1
  always handled. Stated in `cran-comments.md`.
- **The span arithmetic the repair feeds is now pinned**, because a
  change to segmentation can silently break offsets in five verbs at
  once: a repaired span slices back to exactly its glyph;
  [`emoji_context()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_context.md)
  masking keeps the left/right windows and `.position` exact around a
  7-code-point glyph;
  [`emoji_token_cost()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_token_cost.md)
  separates code points from graphemes correctly;
  [`emoji_position()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_position.md)
  treats a repaired glyph as one position wherever it sits; `strip`
  removes it whole; and six counting verbs agree it is one emoji.
- **Collation invariance is now a test, not a convention.** The roadmap
  recorded it as “holds across 7 verbs”, checked by hand. It is now 16
  ordered outputs asserted under `C` and `en_US.UTF-8`, including two
  that had never been checked:
  [`emoji_search()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_search.md)
  (which simply preserves catalogue order) and
  [`emoji_collocations()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_collocations.md).
  Tied counts also break deterministically and independently of input
  row order.

**Round 12, same day — timezones, and a disagreement inside the
package.**

- **A `POSIXct` time column was bucketed by its UTC day.**
  [`as.Date()`](https://rdrr.io/r/base/as.Date.html) on a date-time
  converts in UTC whatever the object’s `tzone` says, so an emoji posted
  at `2020-01-01 23:30` New York was counted on **2020-01-02**. For a
  social-media corpus, where posting is evening-heavy, that misassigns a
  systematic slice of every day boundary – exactly the shape of error a
  trend line hides.

  **What made it findable was an internal disagreement**, not the
  absolute answer: `emoji_seasonality(period = "hour")` reads
  `format(x, "%H")`, which *does* use the object’s own zone, so the same
  row could be hour 23 and the following day at once. Two views of one
  timestamp that cannot both be right is a stronger signal than either
  view alone, and it also settled which one to change: the day a post
  displays as is the day it was posted. `.emoji_as_date()` now takes
  `as.Date(format(x, "%Y-%m-%d"))`, which fixes
  [`emoji_trend()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_trend.md),
  [`emoji_turnover()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_turnover.md),
  [`emoji_adoption_lag()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_adoption_lag.md)
  and `emoji_seasonality(period = "month" / "weekday")` together, and
  makes the hour and day views agree by construction.

- **The session’s `TZ` was never a factor, before or after**, which is
  worth recording because it is the failure mode one expects here and it
  is absent: `as.Date.POSIXct` and `format(x, "%H")` both read the
  object’s `tzone`, not the session’s, so `TZ` set to UTC, New York,
  Tokyo or Kiritimati gives identical day, month, hour, weekday and
  adoption-lag answers. Now asserted. §1’s collation invariant should be
  read as covering timezone too – same category of session state, and
  the time verbs are the only place it can bite.

- **Degenerate cases checked and unchanged** by the fix: `NA` date-times
  stay `NA`, a zero-length column returns a zero-length `Date`, a `Date`
  column passes through identically, and `POSIXlt` works.

**Round 13, same day — the internal-disagreement hunt, run to
exhaustion.**

Round 12 found its defect by noticing two views of one timestamp that
could not both be right. This round enumerated the remaining candidates
– every quantity the package computes by more than one code path – and
checked them all. **Nothing was broken.** That is a result worth
recording, because it closes the method rather than leaving it half-run,
and because these are now tests instead of coincidences.

- **Four independent paths compute `.emoji_sentiment` /
  `.emoji_n_scored`** from the same lexicon:
  [`emoji_sentiment()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sentiment.md),
  [`emoji_score()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_score.md),
  `emoji_incongruity(where = "all")` and
  [`emoji_risk()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_risk.md)
  (the last via the ambiguity table, which is the same 969 rows). All
  four agree exactly, including on the `0`-vs-`NA` distinction for a
  post-2015 glyph, and
  [`emoji_tokens()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_tokens.md)’s
  per-glyph score is the lexicon value for that glyph. Nothing forced
  this; it is now asserted.
- **The two tokenisers are genuinely the same.**
  [`?emoji_context`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_context.md)
  claims “the same definition
  [`emoji_density()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_density.md)
  uses”, but they are separate implementations –
  `strsplit(s, "[[:space:]]+")` against `strsplit(trimws(s), "\\s+")`.
  They agree on all eleven cases tried, including no-break space, em
  space, ideographic space, ogham space mark and zero-width space,
  because R’s TRE engine treats `\s` and `[[:space:]]` as identical.
  Worth knowing that **`U+00A0` and `U+200B` are not whitespace to
  either** – HTML-scraped text with `&nbsp;` under-counts tokens – but
  both verbs under-count identically, so it is a documented definition
  rather than a disagreement.
- **[`emoji_trend()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_trend.md)’s
  completeness claim holds**: rows are exactly periods x emoji, the
  zeros a trend line needs are present, `share` sums to 1 within each
  period, `sum(n)` equals the corpus total, and `measure = "share"`
  changes the emphasis without changing the shape.
- **[`emoji_turnover()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_turnover.md)’s
  `several.ok = TRUE` is consistent across all 15 subsets of
  `measure`**: each yields a subset of the full column set with
  identical values and row count, so asking for one statistic cannot
  change another. `jaccard`, `n_new`, `n_lost` and `n_core` match set
  arithmetic done by hand on the first period pair.
- **One test-writing note.**
  [`tapply()`](https://rdrr.io/r/base/tapply.html) returns a 1-d array,
  so `expect_equal(tapply(...), rep(1, n))` fails on `dim` even when the
  values match – the probe using `abs(x - 1) < 1e-9` had passed. Wrap in
  [`as.numeric()`](https://rdrr.io/r/base/numeric.html).

**Round 14, same day — the last three unexamined behaviours, all
sound.**

Second consecutive round with no defect found, which is itself
information: after twelve rounds of fixes the remaining surface is
behaving. What this round adds is *pinned* semantics for three things
that were correct but unasserted, plus one documentation gap.

- **`.emoji_final_glyphs()`, behind `where = "final"`, is coherent** –
  whitespace-tolerant, punctuation-strict, and it walks the trailing run
  back over whitespace-separated glyphs correctly (16 cases). **But the
  rule was not documented**, and it is easy to meet unaware:
  `"great X."` has *no* final run, because a trailing full stop, bracket
  or quote mark disqualifies the glyph. In a punctuated corpus that
  silently turns most rows into `NA`.
  [`?emoji_incongruity`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_incongruity.md)
  now states it and says what to do instead (strip trailing punctuation,
  or use `where = "all"`). Behaviour unchanged – the definition is a
  research choice and the literature it cites is about sentence-final
  glyphs, so redefining it would be a study-design decision rather than
  a fix.
- **`emoji_pairs(directed = TRUE)` is a re-orientation, not a different
  count**: the directed and undirected totals agree, neither emits
  self-pairs, and the same emoji twice in one document is correctly not
  a pair.
- **[`emoji_ngrams()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_ngrams.md)’s
  `.position` indexes the row’s emoji sequence**, a window wider than
  the row contributes nothing, and `n = 1` gives one row per occurrence.
- **Pathological input holds up**, so there is no hidden quadratic: 5000
  emoji in a single row costs 0.05s for
  [`emoji_position()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_position.md),
  0.10s for
  [`emoji_frequency()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_frequency.md),
  0.12s for
  [`emoji_dfm()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_dfm.md),
  0.14s for
  [`emoji_ngrams()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_ngrams.md)
  and 1.49s for
  [`emoji_context()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_context.md)
  (the only verb that is per-occurrence work); a 100k-character text is
  0.01s; 500 ZWJ families are detected as exactly 500 in 0.03s; and
  `emoji_search("a")`, which matches 4638 glyphs, is 0.11s.
- **One shared limitation confirmed to be shared, not divergent.**
  `U+00A0` is not whitespace to R’s regex, so a no-break space between
  two trailing glyphs breaks the run – exactly as it breaks a token in
  [`emoji_density()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_density.md)
  and
  [`emoji_context()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_context.md)
  (round 13). Three separate implementations, one consistent definition
  of whitespace.

**Round 15, same day — the user-facing prose, and three untested code
paths.**

Third consecutive round without a defect. The remaining work is closing
gaps between what the code does and what the docs say it does.

- **The vignette’s prose was audited against every behaviour rounds 1-14
  changed** – grouping, `.emoji_rel_position`,
  [`emoji_categorize()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_categorize.md)’s
  filter, date bucketing, detection – and it holds. One passage is
  *newly* true rather than still true:
  “[`emoji_categorize()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_categorize.md)
  keeps the emoji-bearing rows” was **false before round 7** (it kept
  only the rows it could also categorise), so the fix retro-fitted the
  documentation. Worth noting as a reason to audit prose against
  behaviour in both directions.
- **The vignette’s own “two design choices worth highlighting” list was
  incomplete**, because round 1 made grouping a third one. Extended the
  “tidy by default” bullet rather than adding a section: row-at-a-time
  verbs carry `group_by()` through, cross-row aggregators warn and pool.
- **[`emoji_emotion_label()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_emotion_label.md)’s
  tie-breaking was a code comment, not documentation.** Ties go to the
  first emotion in Plutchik order, which makes the winner deterministic
  and independent of row position – a real property a user modelling the
  label needs, and one they cannot infer. Now on the help page, with a
  pointer to
  [`emoji_emotion()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_emotion.md)
  for the profile the label collapses.
- **Three code paths were correct but untested, now pinned:**
  - `emoji_dfm(weighting = "tfidf")` over *aggregated* documents. The
    count path had been checked with one document per row; aggregating
    with `doc_id` changes `N` and `df` together. Verified as
    `count * log(N/df)` per column, with an emoji present in every
    document carrying zero weight.
  - `emoji_emotion(long = TRUE)` is exactly the wide form reshaped: rows
    x 8, Plutchik order repeated per row, input row order preserved,
    values equal to the wide columns read across.
  - [`as_emoji_type()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/as_emoji_type.md)
    is total over the catalogue – no `NA`, and all eleven declared
    levels are actually used, so there is no dead level and no
    fallthrough bucket.

**Round 16 (2026-09-04) — the four affect formulas round 3 left
unchecked.**

Round 3 verified `tfidf`, the rank and z-score rescalings, PMI and
entropy against hand computation. Four families were never checked, and
they are the ones behind published numbers. All four verify.

- **The ambiguity measures** are exactly their definitions: `p_neg` /
  `p_neu` / `p_pos` from the raw counts, `entropy` as `-sum(p log p)`
  with `0 log 0` taken as its limit, `gini` as `1 - sum(p^2)`,
  `neutral_share` as `p_neu`. Both sit inside the bounds a three-class
  distribution cannot exceed (`log(3)` and `2/3`).

- **The glyph standard error is a genuine variance over `{-1, 0, 1}`**,
  not a plausible-looking expression: `Var = E[X^2] - E[X]^2` with
  `E[X] = p_pos - p_neg` and `E[X^2] = p_pos + p_neg`, non-negative
  everywhere, `se = sqrt(Var/n)`, and
  `ci_width = 2 * qnorm(0.975) * se`. It is also *behaving* like a
  standard error: rank correlation with the annotation count is
  negative, so more annotations give a tighter estimate. And the
  lexicon’s own `sentiment_score` is the same expectation,
  `p_pos - p_neg`, so the score and its error come from one model rather
  than two.

- **`emoji_risk(threshold = NULL)` is the measure’s upper quartile** for
  all four measures – asserted by comparing against an explicit
  `quantile(., 0.75)`, so the default cannot drift from its
  documentation.

- **`emoji_sentiment(se = TRUE)` propagates as
  `sqrt(sum(se^2)) / n_scored`.**

- **A trap worth recording, because I fell into it.** My first check of
  the SE propagation failed, and the code was right: I had taken the
  lexicon’s first two rows as test glyphs, and row 2 is the bare
  `U+2764`, which is deliberately undetected (§4.7). The row scored one
  glyph, not two. **Any test that draws glyphs from
  `emoji_sentiment_lexicon` must filter to detectable ones first** – the
  lexicon is ordered by frequency and its leading rows are exactly where
  the text-presentation forms live. The test now does that explicitly,
  with a comment saying why.

**Round 17 (2026-09-04) — the version machinery, and a collation gap the
round-11 sweep had missed.**

- **[`emoji_adoption_lag()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_adoption_lag.md)’s
  arithmetic had never been verified.** It is correct: `first_seen` is
  the earliest date the glyph appears, `release_date` comes from the
  version lookup, `lag_days` is their integer difference, and `n` counts
  occurrences rather than rows. Checked glyph by glyph against dates
  computed independently.
- **A negative lag is reported rather than clamped**, and is documented
  as “usually a vendor shipping early”. Worth keeping: it is also how a
  corpus with wrong dates announces itself, so clamping would hide a
  data-quality signal. Pinned.
- **[`emoji_unicode_releases()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_unicode_releases.md)
  looks non-monotonic and is not wrong.** Reading its dates as one list
  gives a 2444-day jump *backwards* at 5.0 -\> 6.0. That is real
  history: **Emoji versions 0.6-5.0 and Unicode versions 6.0-10.0 ran in
  parallel** until they unified at 11.0, and the table records both
  numbering schemes with a `series` column. Verified properly: each
  series is monotonic in its own numbering, the two agree on all three
  release dates they share (emoji 0.7 = unicode 7.0, 3.0 = 9.0, 5.0 =
  10.0), and the installed catalogue labels its glyphs with the *emoji*
  series only. **This is the kind of structure a later “tidy the table
  into one sorted column” would silently destroy**, so it is now
  asserted rather than merely correct.
- **`.emoji_version_num()`’s numeric conversion is load-bearing**, not
  decoration: numeric and lexical order over the catalogue’s labels
  genuinely differ (`0.6, 0.7, 1.0, 2.0, 3.0` against
  `0.6, 0.7, 1.0, 11.0, 12.0`), so ordering on the string would put 11.0
  before 2.0. Asserted.
- **A real gap closed:
  [`emoji_adoption_lag()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_adoption_lag.md)
  and
  [`emoji_version_profile()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_version_profile.md)
  were not in round 11’s collation sweep.** Both
  [`split()`](https://rdrr.io/r/base/split.html) by glyph, and
  [`split()`](https://rdrr.io/r/base/split.html) takes its factor levels
  from [`sort()`](https://rdrr.io/r/base/sort.html), so both were
  candidates for exactly the locale dependence §1’s invariant forbids.
  They are invariant – the values align because both splits use the same
  factor, and the final
  [`dplyr::arrange()`](https://dplyr.tidyverse.org/reference/arrange.html)
  re-sorts in the C locale – but that was luck rather than design, and
  it is now covered. The sweep is 16 outputs plus these 7.
- **1252 of 5042 catalogue glyphs carry no version**, across every
  group. They are reported in
  [`emoji_version_profile()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_version_profile.md)’s
  documented `version = NA` row rather than dropped; my first probe read
  that as three failures before I checked the docs.

**Round 18 (2026-09-04) — the last shallow-verified formula, and
NEWS.md.**

- **PMI was verified against a fixture that could not have failed.**
  Round 3 checked
  [`emoji_collocations()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_collocations.md)
  on a symmetric corpus where every marginal was equal, so *any* formula
  of roughly that shape would have passed. Re-checked on a deliberately
  asymmetric fixture, where the six values come out as `log(2)`,
  `log(1.5)` and `log(0.5)`: correct, and the negative PMI for a word
  shared between two emoji confirms both marginals enter the
  denominator. The formula is `log(n * N / (n_emoji * n_word))`. **A
  test whose fixture cannot distinguish the right answer from a wrong
  one is not a test** – worth remembering for the rest of §8’s test
  work.
- **`min_n` prunes *after* the marginals are computed**, so a pruned
  table still describes the whole corpus and the surviving rows’ PMI is
  unchanged. That was a code comment; it is now asserted, because the
  opposite (recomputing marginals on the pruned table) is the more
  obvious implementation and would silently change every published PMI.
- **The rest of
  [`emoji_collocations()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_collocations.md)
  verifies**: `min_n` is inclusive, `measure` changes the ordering and
  not the rows, a wider window is a superset of a narrower one, and no
  value is `NaN` or `Inf`.
- **`NEWS.md` parses.** It has been edited in nearly every round of this
  loop, and it is read by
  [`utils::news()`](https://rdrr.io/r/utils/news.html) and rendered on
  the CRAN package page, so a broken heading is user-visible and
  `R CMD check` will not catch it.
  [`news()`](https://rdrr.io/r/utils/news.html) returns 12 entries
  across all six released versions with no version-less entry. Now a
  test.
- **The [`tapply()`](https://rdrr.io/r/base/tapply.html) 1-d array trap
  bit me a second time** (round 13 was the first), and the note needs
  sharpening: **[`unname()`](https://rdrr.io/r/base/unname.html) does
  not remove `dim`,
  [`as.numeric()`](https://rdrr.io/r/base/numeric.html) does.**
  Subsetting a 1-d array with a character vector returns a 1-d array, so
  the attribute propagates through arithmetic and `expect_equal` fails
  on `dim` while `max(abs(difference))` is exactly 0. Both times the
  code was right and the check was wrong.

**Round 19 (2026-09-04) — mutation-testing the suite this loop built.**

Round 18’s lesson was that a fixture which cannot distinguish right from
wrong is not a test. The obvious next move is to point that at the 120
tests these nineteen rounds added: **inject a plausible bug into each
fix and check that something actually fails.** 25 mutants, one per
defect fixed in rounds 1-18 plus nine that are not straight reverts.

**23 of 25 were caught**, most by several tests: the timezone bucketing
(4 failures),
[`emoji_categorize()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_categorize.md)’s
filter (3),
[`emoji_risk()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_risk.md)’s
`.emoji_n_ambiguous` (3), the `.emoji_rel_position` denominator (7), the
`emoji_key()` sentinel (2), detection rules 2 and 3 (2 and 18), the
column resolver’s `ungroup()` (7), grouping preservation (17), PMI’s
denominator (4), the standard error’s `/n` (2), tfidf’s `log(N/df)` (3),
the zero-row types (2), the reserved-lexicon guard (7), the whole-number
check (6), the dfm doc_id collision (1), and the subtler ones – the
rel_position *shift* as distinct from its denominator, `min_n`’s `>=`,
`emoji_key()`’s `U+FE0F` stripping (20), first-appearance document
splitting (10),
[`emoji_pairs()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_pairs.md)’s
radix sort, `final_glyphs()`’s trailing-text rule, and version ordering
by number.

**Two survived, and they are different kinds of survivor.**

- **A real gap:
  [`emoji_dfm()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_dfm.md)’s
  glyph tiebreak.** Deleting
  `order(-rowSums(counts), glyphs, method = "radix")`’s second key
  passed the entire suite. The tiebreak’s comment says it defends
  against *collation*, and the collation test does cover the column
  names – but `method = "radix"` is already locale-independent, so what
  the tiebreak really protects is **row-order independence**: without
  it, tied columns fall back to `unique(unlist(docs))`, i.e. the order
  the glyphs happen to appear in the data, so the same corpus sorted
  differently yields a differently-ordered feature matrix.
  Reproducibility is two invariants, not one, and only the first was
  tested. Row-permutation tests added for the dfm and six other
  aggregates; the mutant is now caught by four tests.
- **An *equivalent* mutant: the `lo` bound in `.emoji_extend_zwj()`.**
  Removing the “never cross a neighbouring match” bound changes **no**
  detection outcome across the entire reference table or an 8000-row
  corpus of adjacent emoji pairs – because rule 2 has already merged
  every adjacent pair whose union is catalogued, so a crossing span
  cannot pass the catalogue test. **The right response is a comment, not
  a test**: writing one would be exactly the can’t-fail fixture round 18
  warned about. The bound stays, because the guarantee should come from
  the loop rather than from what happens to be in the catalogue, and the
  comment now says so and records the measurement.

**Method note for future rounds.** The harness backs `R/` up to the
scratchpad and restores from that copy, never `git checkout` – the
working tree holds all of this loop’s uncommitted work. Each mutant is
applied, installed to a throwaway library, tested, and reverted; a
control mutant that changes nothing confirms the clean tree reports zero
failures.

**Round 20 (2026-09-04) — mutation-testing the code this loop never
touched.**

Round 19 mutated the fixes and found one gap. The obvious extension is
to mutate the *original* logic: any survivor there is a coverage hole in
code that shipped correct and was never exercised. 17 mutants across
[`emoji_summary()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_summary.md),
[`emoji_filter()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_filter.md),
[`emoji_context()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_context.md),
[`emoji_sanitize()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sanitize.md),
[`emoji_to_text()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_to_text.md),
[`text_to_emoji()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/text_to_emoji.md),
[`emoji_type()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_type.md),
[`emoji_faceness()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_faceness.md),
[`emoji_search()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_search.md),
[`emoji_score()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_score.md),
[`emoji_tokens()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_tokens.md)
and
[`emoji_extract_unnest()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_extract_unnest.md).

- **One real gap:
  [`emoji_search()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_search.md)’s
  shortcode field.** Deleting `al_hit` from `kw_hit | nm_hit | al_hit`
  passed the entire suite. The verb is documented to match keywords,
  name *and* shortcodes, and **some queries match on one field only**:
  `"grinning_face"` has four alias-only hits and `"thumbsup"` one,
  because names use spaces rather than underscores and neither string is
  a keyword. So the field is load-bearing and nothing tested it. Tests
  added for each field in isolation, plus case-insensitivity, the
  zero-hit typed tibble, and the `+1` metacharacter. All four field
  mutants now die.
- **Two equivalent mutants, both defensive code, both now commented.**
  Round 19’s principle applies: a test that cannot fail is worse than a
  comment that explains why.
  - [`emoji_filter()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_filter.md)’s
    `keep[is.na(keep)] <- FALSE` is **unreachable**: `emoji_has()`
    cannot return `NA`, because `emoji_glyph_list()` maps `NA` text to
    `""` before counting. The invariant “NA text is never an emoji” is
    enforced upstream, so the guard only makes the subscript *provably*
    safe here rather than safe-by-consequence.
  - [`emoji_extract_unnest()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_extract_unnest.md)’s
    `arrange(.row_number, .emoji_unicode)` has a redundant second key,
    because
    [`dplyr::count()`](https://dplyr.tidyverse.org/reference/count.html)
    already returns its group keys in order. Stated anyway: row order is
    part of the verb’s contract and should not depend on `count()`
    continuing to sort.
- **Fourteen caught**, including the ones worth knowing are covered: the
  context window’s word count, its masking of neighbouring emoji,
  `emoji_sanitize(policy = "strip")`’s whitespace tidy (9 failures),
  `emoji_to_text(wrap =)`’s template (20),
  [`text_to_emoji()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/text_to_emoji.md)’s
  token grammar,
  [`emoji_type()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_type.md)’s
  level ordering,
  [`emoji_faceness()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_faceness.md)’s
  face predicate,
  [`emoji_score()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_score.md)’s
  mean, and
  [`emoji_tokens()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_tokens.md)’s
  metadata join.
- **Two mutants I designed badly**, worth recording as a method note:
  one was arithmetically a no-op (`+ 0L * length(has)`) and two failed
  to apply because I guessed the source text instead of reading it. A
  mutant that cannot change behaviour teaches nothing, and “NOT APPLIED”
  is not “survived” – the harness distinguishes them, and it should.

**Round 21 (2026-09-04) — finishing the mutation sweep.**

Rounds 19 and 20 covered the fixes and twelve verbs. This round finished
the remaining logic:
[`emoji_summary()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_summary.md),
[`emoji_incongruity()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_incongruity.md)’s
core,
[`emoji_trend()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_trend.md)’s
grid,
[`emoji_turnover()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_turnover.md)’s
set arithmetic,
[`emoji_seasonality()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_seasonality.md)’s
share denominator,
[`emoji_ambiguity()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_ambiguity.md)’s
rank direction,
[`top_n_emojis()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/top_n_emojis.md)’s
head-before-expansion, and
[`as_emoji()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/as_emoji_name.md)’s
three-tier lookup. **Two more real gaps, both closed.**

- **[`as_emoji()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/as_emoji_name.md)’s
  third-tier fallback is load-bearing for 751 aliases**, and deleting it
  passed the whole suite. The reference table keeps only an emoji’s
  *first* alias as its `shortcode`, so `grinning_face`, `satisfied` and
  `face_with_tears_of_joy` resolve only via the fallback to
  [`emoji::emoji_name`](https://emilhvitfeldt.github.io/emoji/reference/emoji_name.html).
  [`text_to_emoji()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/text_to_emoji.md)
  reaches all 751 as well. So both verbs accept the full 4698-alias
  surface – a genuinely useful property that had never been asserted,
  and one a “simplify the lookup” refactor would have quietly removed.
  This is the largest untested behaviour the sweep found.
- **[`emoji_incongruity()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_incongruity.md)’s
  threshold boundary was untested**: flipping `abs(gap) >= threshold` to
  `>` survived. The help page says “at or above which”, so a strict
  comparison would silently reclassify every row sitting exactly on the
  line. Pinned with an exactly-on-the-boundary fixture –
  `scale = "none"` and `text_score = 0` make the gap equal the emoji
  score, so setting `threshold` to that same double lands precisely on
  it – plus one step either side.
- **Eight caught**, including the ones worth knowing are covered:
  [`emoji_summary()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_summary.md)’s
  `n_total`, the incongruity gap’s sign and its polarity-flip predicate
  (5 failures),
  [`emoji_trend()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_trend.md)’s
  zero cells (4),
  [`emoji_turnover()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_turnover.md)’s
  per-period vocabulary (10),
  [`emoji_seasonality()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_seasonality.md)’s
  share denominator,
  [`emoji_ambiguity()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_ambiguity.md)’s
  descending rank, and
  [`top_n_emojis()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/top_n_emojis.md)
  taking [`head()`](https://rdrr.io/r/utils/head.html) before alias
  expansion (8).

**The sweep is now complete: 59 mutants across three rounds, 5 real gaps
found and closed, 4 equivalent mutants identified and commented rather
than tested.** The gaps clustered where a behaviour is *documented but
incidental* – a fallback lookup, a boundary comparison, a tiebreak, one
field of a three-field match. None was in a headline code path; all four
headline paths (detection, grouping, dates, affect) were already covered
several times over.

**Round 22 (2026-09-04) — test-suite hygiene, and the one axis still
untested.**

- **The suite was order-dependent, and had been since before this
  loop.** `test-dimensions.R` opened with
  [`library(dplyr)`](https://dplyr.tidyverse.org). `testthat` runs every
  file in one session, so that attach leaks into every
  alphabetically-later file and masks
  [`filter()`](https://rdrr.io/r/stats/filter.html),
  [`lag()`](https://rdrr.io/r/stats/lag.html),
  [`intersect()`](https://rdrr.io/r/base/sets.html),
  [`setdiff()`](https://rdrr.io/r/base/sets.html),
  [`setequal()`](https://rdrr.io/r/base/sets.html),
  [`union()`](https://rdrr.io/r/base/sets.html) and
  `testthat::matches()` for all of them. **Nine set-operation call sites
  in the newer test files were resolving to dplyr’s generics purely
  because “dimensions” sorts before “invariants” and “regression”.**
  They gave the right answers – dplyr dispatches to base for plain
  vectors – but by accident, and renaming a test file could have changed
  which implementation ran. The attach is removed
  ([`dplyr::pull()`](https://dplyr.tidyverse.org/reference/pull.html)
  qualified instead; note `%>%` is imported but not exported, so it was
  only available *because* of the attach), and the set operations are
  now `base::`-qualified.
- **The suite’s cost is fine for CRAN and worth recording so it is not
  re-measured:** 16.0s for 279 `test_that` blocks and 1235 expectations,
  the slowest single block 1.05s (the whole-catalogue shortcode round
  trip). No pathological test, and the whole-catalogue sweeps added in
  rounds 8-21 cost about 3s in total.
- **Suggests are handled correctly.** Only `readr` is referenced from
  `Suggests`, in one test, guarded by `skip_if_not_installed()`; every
  other namespace the tests touch (`dplyr`, `emoji`, `tibble`, `rlang`,
  `stats`, `utils`) is in `Imports`. So the suite degrades to a skip
  rather than an error on a machine without Suggests.
- **The one axis still untested, stated plainly: the package has only
  ever been run on R 4.4.1.** CRAN checks r-devel, and `R/4.5.1`,
  `R/4.5.3` and `R/4.6.0` are available on this machine – but
  [emoji](https://emilhvitfeldt.github.io/emoji/) is absent from both
  the 4.5 and 4.6 library trees, so a cross-version run needs a
  dependency install first. Risk looks low (the package uses no post-3.5
  syntax, avoids RNG in fixtures, and its ordering is explicitly
  radix/C-locale), but “looks low” is not “measured”. **This is the
  highest-value remaining pre-submission check**, and the GitHub Actions
  matrix in `.github/workflows/R-CMD-check.yaml` already covers
  R-release, R-devel and R-oldrel-1 – so pushing the branch would answer
  it without any local installs.

**Round 23 (2026-09-04) — the cross-version check, done. The last open
item from round 22 is closed.**

Round 22 named this the highest-value remaining pre-submission check and
deferred it because [emoji](https://emilhvitfeldt.github.io/emoji/) is
absent from the 4.5 and 4.6 library trees. It turned out to cost one
package install: **R 4.6.0 already has every other dependency** (dplyr,
tibble, tidyr, rlang, lifecycle, testthat, and the whole
vctrs/pillar/cli stack), and
[emoji](https://emilhvitfeldt.github.io/emoji/) 16.0.0 is pure R needing
only glue, stringr and tibble. Installed into a disposable scratch
library rather than the persistent `Rlibs/4.6`, so the user’s
environment is untouched.

- **The full suite passes on R 4.6.0**: 1235 expectations, zero
  failures, one skip – the `readr`-guarded real-corpus test. That skip
  is a bonus result: it **live-confirms the Suggests handling round 22
  only audited statically**. The suite degrades to a skip, not an error,
  on a tree without Suggests.
- **`R CMD check` on R 4.6.0 reports `Status: OK`** – no errors, no
  warnings, no notes. Recorded in `cran-comments.md`, which now names
  both R versions. (Run with `--ignore-vignettes`, because the vignette
  needs ggplot2, readr and forcats; the vignette build is verified on
  4.4.1 every round.)
- **So the package is verified on 4.4.1 and 4.6.0** – a two-year span of
  R releases, with 4.6.0 the closest thing available to r-devel. The
  residual risk that motivated the check (a regex, sort or date-coercion
  change between versions) is now measured rather than assumed.

**A plumbing trap worth recording, because it cost most of this round
and I had been ignoring its warning for twenty-two of them.**
`~/.bashrc` defines `Rscript` as a *shell function* that sets
`LD_LIBRARY_PATH="$(_r_ldpath)"`. `_r_ldpath` does not exist in this
session’s shell snapshot, so the function silently sets the path to the
**empty string**, discarding whatever the caller exported – which is why
`testthat.so` failed to find `GLIBCXX_3.4.26` even though `ldd` resolved
it correctly one command earlier. The `_r_ldpath: command not found`
line printed on every single R call all loop, and I had filtered it out
as noise. **A warning that appears on every invocation is not thereby
harmless.** The fix is a wrapper *script* (functions are not inherited
by scripts) or `command Rscript`; `$SP/rs` had been working by accident
of being a script all along.

**Round 24 (2026-09-04) — reading what I had only ever grepped.**

Round 23’s lesson was that a warning printed on every invocation is not
thereby harmless. Applied to the rest of the loop’s habits: the check
log had only ever been grepped, and one CRAN check mode had never been
run.

- **The full 4.4.1 check log, read end to end (84 lines): clean.** Every
  check `OK` bar the three known environment items, and **no `\donttest`
  or `\dontrun` anywhere**, so CRAN runs every example on every flavour.
  Nothing was hiding behind the grep.
- **`_R_CHECK_DEPENDS_ONLY_=true` had never been run**, and it is the
  mode that catches a package quietly leaning on a `Suggests` package.
  With only `Depends` + `Imports` visible: examples OK, tests OK,
  `Status: 1 NOTE`. So nothing in `R/`, the examples or the tests
  reaches outside the declared imports – which is what round 22
  concluded statically and round 23 confirmed for `readr` alone.
- **That run turned a hypothetical in `cran-comments.md` into a
  measurement.** The submission note said “*should* a checking host
  report ‘found marked UTF-8 strings’”. It does – a plain `R CMD check`
  reports **6890**, while `--as-cran` suppresses the same check. The
  count is now fully attributed: `emoji_unicode_crosswalk$unicode` 5761,
  `emoji_sentiment_lexicon$emoji` 969, `emoji_emotion_lexicon$emoji`
  150, `category_unicode_crosswalk$unicodes` 10 = 6890 exactly, with no
  other column in any dataset carrying a marked string.
  `cran-comments.md` now states the number and its breakdown instead of
  hedging, because a reviewer reading “should a host report” cannot tell
  whether the maintainer checked.
- **A discrepancy worth knowing for future runs:** `--as-cran` is not
  uniformly stricter. It reports the qpdf WARNING and the
  HTML-validation NOTE that a plain check does not, and it *suppresses*
  the marked-UTF-8 NOTE that a plain check emits. Running only one mode
  leaves a blind spot in either direction.

**Round 25 (2026-09-04) — the locale axis, and a rule applied to only
half the package.**

Round 24 ended on “running one mode leaves a blind spot in either
direction”. The untried mode here was the *locale*: round 3 confirmed
detection survives `LC_CTYPE=C` for four verbs, but the suite had only
ever run in UTF-8.

- **Under `LC_ALL=C` the suite failed immediately** – and the failures
  showed `\ufffd` replacement characters, which points at the fixtures
  rather than the code. Confirmed by the decisive measurement: **the
  whole-catalogue detection sweep gives exactly the same 4830 / 5042
  under `LC_ALL=C` as under UTF-8**, because
  [`emoji::emojis`](https://emilhvitfeldt.github.io/emoji/reference/emojis.html)
  strings are properly marked and the engine never touches the locale.
  **The package is locale-independent; the test suite was not.**
- **Ten test files carried 114 literal non-ASCII characters inside
  string literals.** R parses a source literal byte-wise in a non-UTF-8
  locale, so a literal ZWJ becomes three replacement characters and
  every fixture built from it silently tests a different string than
  intended – the fixture reads correctly and asserts the wrong thing.
  All 114 converted to `\u` / `\U` escapes; the suite is now
  byte-identical in both locales (281 blocks, 0 failures each).
- **The underlying miss: round 3’s ASCII-source rule was applied to `R/`
  and never to `tests/`.** It was introduced for a different reason – so
  pdfLaTeX can typeset the reference manual – and the locale consequence
  for fixtures was never drawn. Same rule, two motivations, one half
  done. **A rule adopted for one reason should be checked against every
  directory it could apply to**, not just the one where the symptom
  appeared.
- **Both invariants are now tested rather than remembered:** `R/` is
  asserted pure ASCII (I had been re-running that grep by hand every
  single round), and test string literals are asserted escaped. Verified
  the second guard fires by injecting a literal into a test file – one
  failure, as intended.
- **A fitting detail:** the heredoc I first used to *write* the guard
  was itself rejected for containing a stray non-ASCII byte. The tooling
  caught in one keystroke the exact class of mistake the guard exists to
  catch.

**Round 26 (2026-09-04) — spell-checking 25 rounds of prose, and one
real packaging omission.**

Thousands of words of documentation were written across this loop and
none of it had ever been spell-checked.
[spelling](https://ropensci.r-universe.dev/spelling) and
[hunspell](https://docs.ropensci.org/hunspell/) were already installed.

- **No typos.** All 139 flagged words are legitimate: author surnames,
  package names, acronyms, domain vocabulary, and one word I had to look
  up – `multipleness`, which is the authors’ own coinage in a real paper
  title (*Journal of Business Research*, 2022), not an error.
- **The real find: `DESCRIPTION` had no `Language` field.** So the check
  defaulted to `en-US` and flagged 55 *correct* British spellings as
  errors, which is what made a 139-word noise list out of a gate that
  should read zero. Declaring `Language: en-GB` – which CRAN itself
  reads – drops the count to 84, all genuinely unknowable.
- **`inst/WORDLIST` added** with those 84, so `spell_check_package()`
  now reports **zero**. The point is not the current state but the next
  typo: it will be visible instead of buried.
- **The prose was already consistently British**, verified across ten
  British/American pairs over `R/`, `man/`, the vignette, `README`,
  `NEWS.md` and `cran-comments.md`: **zero** American spellings. The
  only American tokens are the exported
  [`emoji_categorize()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_categorize.md)
  and
  [`emoji_sanitize()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sanitize.md),
  which follow R convention and must not change.

**A method error of mine, worth recording because it nearly became a
“finding”.** I first audited spelling with `grep -r` over `vignettes/`,
which reported 20 American spellings and looked like a real
inconsistency inside one file. `vignettes/` contains `ata_tweets.csv` –
150 KB of **real tweet text**. The hits were in the corpus, not the
documentation. **Grepping a directory that holds data files to draw a
conclusion about prose is not a valid measurement**; scope to the source
files by name. Same lesson as round 9’s substring/prefix mistake, in a
new disguise: the tool answered a different question than I asked.

**Not done, deliberately:** wiring the spell check into CI needs
[spelling](https://ropensci.r-universe.dev/spelling) in `Suggests` plus
a `tests/spelling.R`. §1’s gap list already scopes “{covr}/spelling CI”
as future work, so the wordlist makes the manual check correct now and
the CI wiring stays where the roadmap put it.

**Round 27 (2026-09-04) — CI caught a defect two of my own audits had
cleared, and the first fix was the wrong one.**

Pushing PR \#8 failed on all five platforms with one error, identical
everywhere:

``` R
[ FAIL 1 | WARN 0 | SKIP 2 | PASS 1228 ]
Error in loadNamespace(x): there is no package called 'commonmark'
```

[`utils::news()`](https://rdrr.io/r/utils/news.html) parses a Markdown
`NEWS.md` through **commonmark**, which is neither an `Imports` nor a
`Suggests` of this package. It was simply present in the development
library because roxygen2 depends on it. The round-18 test that checks
`NEWS.md` parses therefore passed here and could not pass anywhere else.

**Two of my own audits had cleared this, and both were structurally
incapable of catching it.**

- Round 24 ran `_R_CHECK_DEPENDS_ONLY_=true`, saw it pass, and concluded
  “nothing reaches outside the declared imports”. **That mode masks
  `Suggests`.** `commonmark` is in neither field, so there was nothing
  to mask – the mode cannot detect a package you never declared at all.
- Round 22’s static audit grepped for `pkg::` and
  [`library()`](https://rdrr.io/r/base/library.html) in the tests. **The
  reach is inside
  [`utils::news()`](https://rdrr.io/r/utils/news.html)**, so no amount
  of grepping the test sources would have found it.

**My first fix was the wrong one.**
`skip_if_not_installed("commonmark")` turned the failure green – by
making the test skip on CI *permanently*, so the `NEWS.md` check would
never again run anywhere but this machine. A guard that silences the
only environment you care about is not a fix. **`commonmark` is now in
`Suggests`**, so CI installs it and the test actually runs; the guard
stays for minimal installs, which is what guards are for.

**And a check that would have caught it, which is the part worth
keeping.** Diff the namespaces the suite loads against the recursive
closure of the declared dependencies, computed from installed metadata
so it needs no network:

``` r
after   <- loadedNamespaces()                    # after test_dir()
closure <- <recursive Depends/Imports/LinkingTo of Imports+Suggests+Depends>
setdiff(after, c(closure, base_packages))
```

Before the fix that printed `commonmark rstudioapi xml2`; after it, only
`rstudioapi xml2`. **Those two are in testthat’s own `Suggests`** –
testthat probes for them itself and degrades without them, which is why
CI reported one failure and not three. So the check needs a reader who
can tell “our test needs this” from “testthat probed for this”, which is
why it belongs in the release checklist rather than in the suite as an
assertion.

**The general lesson, and it is the third time this loop has produced
it:** a verification that passes tells you nothing until you know what
it is capable of failing on. `--as-cran` versus a plain check (round
24), a symmetric PMI fixture (round 18), and now `DEPENDS_ONLY` against
an undeclared package.

**Round 28 (2026-09-04) — the same audit applied to the other two
artifacts.**

Round 27’s `commonmark` failure came from a *test* reaching a package
that is in neither `Imports` nor `Suggests`. `R CMD check` runs three
things – tests, examples, the vignette – and CI installs every
`Suggests` plus their whole dependency closure, so the same blind spot
could hide in the other two and still pass. So the audit was pointed at
them.

The check, for the record, is: render or run the artifact in a live
session, then diff
[`loadedNamespaces()`](https://rdrr.io/r/base/ns-load.html) against the
recursive `Depends`/`Imports`/`LinkingTo` closure of the declared
dependencies, computed from installed metadata so it needs no network.

- **Vignette: clean.**
  [`rmarkdown::render()`](https://pkgs.rstudio.com/rmarkdown/reference/render.html)
  on `introduction.Rmd` loads nothing outside the 83-package closure.
- **Examples: clean.** All 46 example blocks across the help pages run
  without error and load nothing outside the closure.
- **The tests’ reach was two packages, not one, and this section
  originally said otherwise.** See round 29: `xml2` was in the audit’s
  output all along and I dismissed it on the grounds that “CI reported
  one failure and not three”. That inference was invalid and cost a
  second CI round.

This closes the thread round 27 opened. The audit belongs in the release
checklist, run against all three artifacts, with the caveat recorded
there: `rstudioapi` and `xml2` will always appear for the tests because
they are in *testthat’s* `Suggests` and testthat probes for them itself
– a reader has to tell that apart from a genuine reach, which is why it
is a checklist item and not a suite assertion.

**Round 29 (2026-09-04) — the same test failed CI twice, and the second
failure was my reasoning, not my code.**

`22bbe3b` failed on all five platforms again, same test, different
package:

``` R
Error in loadNamespace(x): there is no package called 'xml2'
```

**My round-28 audit had listed `xml2`.** I dismissed it, in writing,
because “CI reported one failure and not three, so `xml2` and
`rstudioapi` are loaded incidentally by testthat and present there”.
**That inference is invalid: a missing dependency stops at the first
one.** CI could not have distinguished “xml2 is present” from “xml2 was
never reached”. I had the correct answer from my own measurement and
argued myself out of it with evidence that could not bear on the
question – the exact error round 27 had just finished writing up.

**Determined the complete set instead of discovering it one push at a
time.** `tools:::.build_news_db_from_package_NEWS_md` and its neighbours
reference exactly `commonmark` and `xml2`, with **no `requireNamespace`
guards**, so either one missing is a hard error. Both are now in
`Suggests`; the test guards on both.

**And the invariant no longer depends on that stack at all.** The point
of the test is that `NEWS.md`’s version headings are well formed – so
that is now asserted directly, with no Markdown parsing: every top-level
heading matches `# tidyEmoji <version>`, versions are unique, sorted
newest-first, and the leading one equals `DESCRIPTION`’s `Version`.
Verified to have teeth by rewriting a heading to `# tidyEmoji v0.4.0` –
one failure. The [`news()`](https://rdrr.io/r/utils/news.html) test
stays alongside it, because
[`news()`](https://rdrr.io/r/utils/news.html) is what CRAN and users
actually call, but it is no longer the only thing standing between a
malformed heading and the CRAN page.

**The rule this loop keeps re-deriving, now stated as bluntly as I
can:** before treating a passing check as evidence, name the thing it
would have failed on. `--as-cran` versus plain (round 24), the symmetric
PMI fixture (round 18), `DEPENDS_ONLY` against an undeclared package
(round 27), and now a one-error-at-a-time CI run standing in for a
three-package audit.

**Round 30 (2026-09-04) — line coverage, which found what mutation
testing structurally could not.**

`main` went green on all five platforms plus pkgdown, so the CI gate was
clear. [covr](https://covr.r-lib.org) was already installed and had
never been run.

**96.59%, 53 uncovered lines – and four of them were documented features
with no test at all:**

- `emoji_score(lexicon = "emotag1200")`, whose help page promises “the
  mean over its eight emotion dimensions”.
- `emoji_sentiment(lexicon = )` given a data frame or a registered
  lexicon.
- `emoji_trend(by = "quarter")`.
- `sort = FALSE` on
  [`emoji_pairs()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_pairs.md)
  /
  [`emoji_cooccurrence()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_cooccurrence.md).

**This is precisely the complement to rounds 19-21.** Mutation testing
can only probe a line you thought to mutate; it told me the suite had
teeth on everything I had considered. Coverage names the code nothing
runs at all – and `by = "quarter"` had never occurred to me to mutate,
because I did not know it was untested. **The two techniques answer
different questions and neither substitutes for the other.**

A second class in the same list: **every argument-validation error on
the lexicon surface was uncovered.** Unknown lexicon name, non-character
lexicon, sentiment lexicon passed to
[`emoji_emotion()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_emotion.md),
non-data-frame `tbl`, missing glyph column, missing score column,
misnamed `by`. I had checked all of them by hand in rounds 2 and 11 and
written none of them down, so removing a validation would have passed
the suite. Same for the degenerate branches of `.emoji_rank_scale()` and
`.emoji_zscore()`, verified in a round-3 probe and never asserted. **A
probe is not a test; the finding evaporates when the session ends.**

**Now 99.42%, 9 lines uncovered, 296 test blocks.** The nine are guards
whose callers validate first – `.emoji_lexicon_record()`’s data-frame
check, `.emoji_replace_in_order()`’s empty-input guards, the final
`else` in
[`emoji_sentiment()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sentiment.md)’s
lexicon dispatch that `.emoji_lexicon_lookup()` errors before. Left
alone deliberately: chasing them would mean testing through internals
rather than the interface, and round 19 settled that a test which cannot
fail is worse than a comment.

**Also this round:**
[`pkgdown::check_pkgdown()`](https://pkgdown.r-lib.org/reference/check_pkgdown.html)
reports no problems (round 4 audited the reference index by hand; this
is the tool agreeing), and the site builds locally with no warnings.
Both build artefacts – `docs/` at 5.8 MB and a `pkgdown/favicon/`
directory – were removed, since neither was in the repo before.

**Round 31 (2026-09-04) — the check I had disabled in every previous
round.**

Every `R CMD check` this loop has run set
`_R_CHECK_CRAN_INCOMING_REMOTE_=false`, because a memory note says it
hangs on this host. **That is precisely the flag that validates URLs**,
and a dead URL is one of the commonest reasons CRAN bounces a
submission. So URLs had never been checked – thirty rounds of “clean”
checks with the URL check switched off.

`urlchecker::url_check()` instead: **11 of 12 pass.** The twelfth is the
CLARIN.SI handle that `cran-comments.md` already anticipated – but the
note named the wrong host, and the real diagnosis is sharper:

- `https://hdl.handle.net/11356/1048` **verifies fine** and returns
  `302` to `https://www.clarin.si/repository/xmlui/handle/11356/1048`.
- It is the *redirect target* that fails. The chain is `clarin.si` \<-
  `GEANT TLS RSA 1` (Hellenic Academic and Research Institutions CA) and
  `openssl s_client` gives
  `Verify return code: 20 (unable to get local issuer certificate)`.
- **The cause is this host, not the URL.** CentOS 8 with
  `ca-certificates-2020.2.41` – a 2020 bundle with no current HARICA
  root. `curlGetHeaders(url, verify = FALSE)` returns `200`, so the site
  is up.

`cran-comments.md` now states the redirect target, the chain, the
openssl verify code, the bundle version and the unverified `200`, so a
reviewer can reproduce it rather than take a hedge on trust. **The old
wording blamed `hdl.handle.net`, which verifies perfectly well** – a
plausible-sounding diagnosis nobody had tested.

**Also checked and sound:** the `https://example.org` in
[`text_to_emoji()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/text_to_emoji.md)’s
example is deliberate and correct – it is the IANA-reserved example
domain, used to show that a URL’s colons do not swallow a following
`:shortcode:`. `cran-comments.md`’s claim of no reverse dependencies
still needs verifying against a live CRAN index, which this host’s stale
trust store also blocks.

**Round 32 (2026-09-04) — the memory note that cost 31 rounds of URL
checking.**

Round 31 found that every check had
`_R_CHECK_CRAN_INCOMING_REMOTE_=false`, and blamed a memory note saying
it hangs on this host. **This round tried it. It does not hang – it
completes in 19 seconds.** The note was simply wrong, or had stopped
being true, and nobody had re-measured it.

So the full CRAN-equivalent check has now actually been run, remote half
enabled, vignettes built: **1 WARNING, 3 NOTEs**, and the
incoming-feasibility NOTE contains nothing but the maintainer line and
the one CLARIN.SI URL – with R’s own wording
`(Status without verification: OK)`, which is verbatim what
`cran-comments.md` had been claiming on trust. All four results are host
artefacts.

- **The memory note is corrected**, with the flag flipped, the 19-second
  measurement, and an explicit warning that the flag is what validates
  URLs and DOIs. The standing check script now enables it, so every
  future round validates URLs.
- **Two claims in `cran-comments.md` are now verified rather than
  asserted.** No reverse dependencies – checked against a live CRAN
  index of 24,739 packages across
  `Depends`/`Imports`/`LinkingTo`/`Suggests`/`Enhances`, which returns
  none; and the same index confirms the published version is 0.3.0, so
  0.4.0 is the correct next number. The DOI resolves to the PLoS ONE
  article.
- **A round-31 claim of mine was wrong and is corrected.** I said the
  stale trust store “also blocks” the CRAN index. It does not –
  `cloud.r-project.org` verifies fine. Only `clarin.si` fails. I had
  generalised from one TLS failure to “the network is unusable”, which
  is the same shape of error as the one I had just finished writing up
  in round 29.
- **The `no prebuilt vignette index` note seen mid-round was my own
  artefact**, from running with
  `--no-build-vignettes --ignore-vignettes`. It disappears in a full
  check. Worth recording so it is not mistaken for a real finding later.

**The pattern across rounds 24, 27, 29, 31 and 32 is now unmistakable,
and it is not about verification technique – it is about inherited
belief.** Each time, something was excluded from checking by a setting
or an assumption that had never been re-tested: `--as-cran` suppressing
a note, `DEPENDS_ONLY` masking Suggests, a one-error CI run standing in
for an audit, a disabled flag, and a memory note. **Re-measure the thing
that tells you not to look.**

**Round 33 (2026-09-04) — what actually ships, and the last inherited
beliefs.**

Two things had never been measured, only assumed.

- **The tarball’s contents, listed against the repo.** Round 1 caught
  `.claude` shipping by accident; nothing has verified the whole
  manifest since. It is correct: `inst/WORDLIST` and `inst/doc/` ship,
  `vignettes/ata_tweets.csv` ships because the vignette needs it, and
  everything build-ignored is genuinely development-only –
  `cran-comments.md`, `next_release.md`, `data-raw/`, `_pkgdown.yml`,
  the `.github` workflows, the `.Rproj`. **`LICENSE.md` is excluded, and
  that is right**: `License: GPL (>= 3)` is a standard licence, so
  shipping the text is discouraged. It would be *required* only if the
  field read `+ file LICENSE`, which it does not. 576 KB total.
- **`man/figures/logo.png` is byte-identical reproducible from
  `logo.svg`.** Rendered through the pipeline `[[svg-rendering-hpc]]`
  documents – python3 + GObject librsvg 2.42 + pycairo at width 480 –
  the output has the same md5 as the shipped file. So the logo has the
  same provenance guarantee round 5 established for `data-raw/`: the
  binary in the repo is derivable from its source, not a one-off nobody
  can rebuild.

**Memory audit, prompted by round 32’s discovery that a stale note had
suppressed URL checking for 31 rounds.** Every factual claim in the
project’s memory notes was re-tested:

- `[[svg-rendering-hpc]]` – accurate. `rsvg-convert`, `magick`,
  `convert` and `inkscape` are all still absent; the pycairo route still
  works.
- `[[r-cmd-check-hpc]]` – corrected last round; the gcc paths it names
  still exist.
- `[[fetch-before-claiming-repo-state]]` – clone is current.
- `[[r-environment-hpc]]` – **one inaccuracy, and it was mine.** My
  round-1 edit said `Rlibs/4.4` “HAS `emoji` 16.0.0”. It does not:
  `emoji` is in the R 4.4.1 **site** library, and `R_LIBS=Rlibs/4.4`
  only works because the site library is searched too. That wording is
  exactly what made round 23 briefly conclude a cross-version check was
  impractical when `emoji` turned out to be missing for R 4.6.
  Corrected, with the fix recorded: `emoji` is pure R and installs into
  a scratch library in seconds.

**Nothing in the package changed this round.** At this maturity that is
the expected outcome, and the value is in the two provenance facts now
being measured rather than assumed.

**Round 34 (2026-09-04) — auditing the invariant list itself, and one it
caught.**

§1’s invariant list has already been wrong three times (§1.5 in both
directions, §1.7’s denominator, §4.7’s symptom list). This round
re-tested every remaining claim in it, mechanically, against the
installed package.

**Six of seven hold. One was broken, and by the invariant’s own
wording:**

- **“tibble in / tibble out” –
  [`emoji_extract_nest()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_extract_nest.md)
  returned a plain `data.frame` for a plain `data.frame`.** It was the
  only row verb not routing its output through `.emoji_as_tibble()`, the
  helper round 1 added for exactly this; the other seventeen all use it.
  [`?tidyEmoji`](https://pursuitofdatascience.github.io/tidyEmoji/reference/tidyEmoji-package.md)
  states “every verb … returns a tibble” without qualification, so the
  verb was wrong rather than the doc. Fixed through the helper, which
  also keeps a `grouped_df` passing straight through, so the round-1
  grouping guarantee is unaffected. The practical cost of the old
  behaviour: a list-column in a plain `data.frame` prints its contents
  inline instead of as `<list>`. **Note this predates the loop** – the
  previous implementation used
  [`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html),
  which is equally class-preserving, so round 2’s rewrite carried the
  behaviour forward rather than introducing it.
- The other six hold: dotted columns on user data and bare names on
  summary tibbles; every glyph join through the `U+FE0F`-stripped key;
  `NA` text never an emoji and zero-row output correctly typed;
  `.emoji_n_scored` `0` for unscorable and `NA` for no-emoji; ordering
  identical under `C` and `en_US.UTF-8`; and eight nonsense arguments
  all erroring.

**The invariant is now a test rather than a paragraph.** One block
asserts the tibble contract over all 38 data-first verbs at once, one
asserts grouping survives thirteen row verbs, one asserts the
dotted/bare column split. Verified to bite by reverting the fix – one
failure. **Nothing compared the verbs to each other before**, which is
exactly how a single verb drifts from a contract all the others keep.

**Also this round: every error message, rendered and read.** 42
[`stop()`](https://rdrr.io/r/base/stop.html) /
[`warning()`](https://rdrr.io/r/base/warning.html) sites; 40 name the
offending argument in backticks and the two that do not are clear anyway
([`emoji_emotion()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_emotion.md)’s
lexicon message names the function;
[`emoji_sentiment()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sentiment.md)’s
names `se = TRUE`). Sixteen were triggered and read as a user would see
them – all state what is wrong *and* what to do, and several name the
fix explicitly (“Pick another name”, “Rename the column”, “produce it
with tidytext, sentimentr, vader”). No change needed.

**One thing that looked like a defect and is not.**
`emoji_to_text(wrap = "<>")` raises no error, because `wrap` is
validated only when `format = "shortcode"`. That is documented –
“Ignored for `format = "name"`” – and the same conditional pattern is
consistent across the family: `wrap` under `policy = "shortcode"`,
`placeholder` under `policy = "placeholder"`, each validated exactly
where it applies.

- **Two things round 2 checked and found sound**, worth recording so
  they are not re-audited: every `verb(data, text)` export survives
  zero-row, all-`NA`, empty-string, `factor` and `numeric` text columns
  without error; and the counts agree across verbs on a mixed fixture —
  [`emoji_summary()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_summary.md)’s
  `n_with_emoji` equals `nrow(emoji_filter())`, and
  `sum(emoji_frequency()$n)` equals
  `sum(emoji_extract_unnest()$.emoji_count)` equals
  `nrow(emoji_tokens())` equals `sum(.emoji_n)` from every row verb that
  reports one equals `sum(emoji_version_profile()$n_tokens)`.
  [`emoji_type()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_type.md)
  deliberately adds no `.emoji_n`, which its `@return` says.

------------------------------------------------------------------------

**Round 35 (2026-09-04) — cost, the one axis 34 rounds never measured.**

Every earlier round asked whether the verbs were *correct*. None asked
what they *cost*. Six cross-verb correctness probes opened this round
and all six came back clean, which is the useful signal — recorded here
so they are not re-audited:

- User column order and count are preserved by all fifteen row verbs.
- The `NA`-vs-`0` discipline on count columns is uniform *and* already
  documented: `.emoji_n` counts everything, derived counts are `NA` for
  a no-emoji row (`emoji-ambiguity.R:176`, `emoji-type.R:118`,
  `emoji-incongruity.R:154`).
- Output-column order matches every `@return`.
- Silent overwrite of a colliding dotted column is the documented
  reserved-prefix contract (`R/tidyEmoji.R:11`), applied uniformly
  across twelve verbs; duplicate input names already error through
  tibble.
- Declared encodings (UTF-8, unknown, latin1) all read correctly, and
  latin1 round-trips through the three text-rewriting verbs without
  mojibake.
- [`emoji_context()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_context.md)’s
  `.position` agrees with
  [`emoji_position()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_position.md)’s
  `.emoji_first` across all five sequence classes, and `.emoji_mask()`
  is length-preserving, so character offsets stay exact.

**The defect, which was structural rather than local.** Three hot paths
reached a character offset with
[`substr()`](https://rdrr.io/r/base/substr.html)/[`substring()`](https://rdrr.io/r/base/substr.html).
R rescans a multi-byte string from its first byte to reach a character
offset, so each call is O(offset) — and all three called it once per
emoji, giving O(m\*L) in a row holding m emoji. Ratios for a 4x input
increase (4.0 is linear, ~16 quadratic):

| stage | before | after |
|----|----|----|
| `.emoji_locations()` | 4.1 | 4.1 (already linear) |
| `.emoji_mask()` | 14.1 | 5.0 |
| `.emoji_occurrences()` | 12.0 | 3.5 |
| [`emoji_context()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_context.md) window loop | ~12 | 4.0 |

The window loop was the most wasteful: it handed `.emoji_window()` the
*entire* prefix and suffix, and re-evaluated `nchar(masked[r])` every
iteration, when the answer only ever depends on the `window` tokens
nearest the glyph. And because `.emoji_slice()` sits under
`emoji_glyph_list()`, `.emoji_mask()` and `.emoji_occurrences()`, the
cost was **shared** —
[`emoji_summary()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_summary.md)
and
[`emoji_sentiment()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sentiment.md)
paid it too, not just
[`emoji_context()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_context.md).

**The fixes.** `.emoji_slice()` and `.emoji_replace_in_order()` index
code points ([`utf8ToInt()`](https://rdrr.io/r/base/utf8Conversion.html)
once, then integer slices) past `.emoji_cp_threshold` (512 spans). The
threshold matters: measured crossover is a few hundred spans, below
which [`substring()`](https://rdrr.io/r/base/substr.html) is genuinely
faster, so ordinary rows stay byte for byte on the path every other verb
was built against, and [`anyNA()`](https://rdrr.io/r/base/NA.html) on
the conversion falls back for anything
[`utf8ToInt()`](https://rdrr.io/r/base/utf8Conversion.html) cannot
represent.
[`emoji_context()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_context.md)
reads a bounded slice anchored at the glyph, widening the budget until
it demonstrably contains the answer — more than `window` tokens (the
outermost may be cut by the slice edge, the nearer ones cannot be), or
for `unit = "char"` still `window` characters after the emoji-adjacent
whitespace is trimmed; falling back to the full side keeps pathological
all-whitespace input exact. At 6400 emoji in one row:
[`emoji_summary()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_summary.md)
and
[`emoji_sentiment()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sentiment.md)
~10x faster,
[`emoji_context()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_context.md)
~4x, `.emoji_mask()` 1.164s to 0.106s.

**Two measurement lessons.**

- **The obvious culprit was the wrong one.** After fixing the window
  loop the residual was still super-linear, and the natural hypothesis —
  that [`substr()`](https://rdrr.io/r/base/substr.html) on a small slice
  still rescans, so slicing should go through a character vector — was
  *measured and rejected*: the char-vector variant was slower on every
  input size tried, realistic and extreme. Profiling the stages
  separately, rather than reasoning about which was likely, is what
  found the real cost in `.emoji_slice()`/`.emoji_replace_in_order()`.
- **A fast path pinned against a slow path is only pinned if the
  comparison can fail.** The new tests compare `.emoji_slice()` against
  [`substring()`](https://rdrr.io/r/base/substr.html) and
  `.emoji_window_at()` against `.emoji_window()` on the whole side. Both
  were verified to bite by mutation — an off-by-one in the code-point
  index and a removed widen loop each produce failures. Without that
  step they would have passed just as happily against a broken fast
  path. This is the same meta-lesson §1 keeps relearning: **name the
  thing a passing check would have failed on.**

**Then a sweep for the same defect class, which found two more instances
and one consolidation.** Having fixed three sites, the obvious next
question was whether the pattern occurred elsewhere: every
[`substr()`](https://rdrr.io/r/base/substr.html)/[`substring()`](https://rdrr.io/r/base/substr.html)
call in `R/` was read. Two more had it —
[`emoji_ratio()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_ratio.md)’s
residual loop (does anything but emoji remain?) and
`.emoji_final_glyphs()`’s walk-back over the trailing emoji run behind
[`emoji_incongruity()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_incongruity.md).
All four sites that cut text *around* glyph spans were doing the same
thing with their own loop, so they now share `.emoji_gaps(s, m)`, which
returns the `nrow(m) + 1` stretches outside the spans and holds the
threshold logic once instead of three times. `gaps[i]` is the text
between glyph `i - 1` and glyph `i`, so a caller indexing glyph pairs
and one indexing the tail agree by construction.

**The measurement lesson that only showed up here: a ratio can hide a
quadratic.**
[`emoji_ratio()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_ratio.md)
measured a 2.7x increase for 4x input, which reads as comfortably
linear, and on that basis it was nearly left alone. It was in fact the
slowest per-row verb in the package — both measurement points were
*already* deep in the quadratic regime, so the ratio between them
understated the growth. Consolidating it made it **13x faster** (0.326s
to 0.024s at 1600 emoji). Ratios locate super-linear growth only when
one endpoint is still in the linear regime; absolute cost is what says
whether a path is worth fixing. Both numbers were needed, and the ratio
alone would have closed the investigation early.

| site | before | after |
|----|----|----|
| [`emoji_ratio()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_ratio.md) (6400 emoji) | 0.867s | 0.068s |
| `.emoji_final_glyphs()` (6400) | 0.469s | 0.069s, ratio 8.8 to 4.1 |
| `.emoji_mask()` (6400) | 1.164s | 0.106s |
| [`emoji_context()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_context.md) (1600) | 1.50s | 0.32s |

**Verification.** Differential equivalence: 10/10 `(unit, window)`
combinations identical over 407 generated strings, including 500-space
runs, adjacent emoji, leading and trailing whitespace and pure-emoji
strings. The code-point path is exact on every sequence class (astral,
ZWJ, `U+FE0F`, regional indicator, keycap, skin tone) and on
latin1-marked input. Threshold crossing: verb output proportional and
translations identical at 508, 512 and 520 glyphs. Suite 304 blocks, 0
failures. Local `--as-cran` with remote checks enabled: 1 WARNING, 3
NOTEs — the four documented host artefacts, unchanged.

------------------------------------------------------------------------

**Round 36 (2026-09-05) — composing the verbs, which no round had
done.**

Rounds 1-34 tested verbs one at a time; round 34 compared them to each
other. This round *composed* them and asserted algebraic properties of
the pair, which is the next step out and reaches things single-verb
tests structurally cannot.

**The shortcode round trip, over the entire catalogue.** Feeding all
5042 reference glyphs through `emoji_to_text(format = "shortcode")` and
back recovers only **79.4%** byte-identically. Every one of the 1040
apparent failures turns out to share its code-point key with the
original: they are unqualified forms returning as their fully-qualified
equivalents, because both directions resolve through the
`U+FE0F`-stripped key, so a variant pair shares one shortcode and the
qualified row is the one carrying it (the unqualified row’s `shortcode`
is `NA`). Strip `U+FE0F` from both sides and the round trip is the exact
identity on all 5042, and a second pass is a fixed point. So the
behaviour is right and the **documentation was wrong**:
[`text_to_emoji()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/text_to_emoji.md)
claimed flatly to be “the inverse of
[`emoji_to_text()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_to_text.md)”,
a claim it satisfies only up to the presentation selector — and a user
round-tripping a corpus would see a fifth of their glyphs change bytes.
Note the vector helpers **already documented this correctly** (“All
three resolve through `emoji_key()`, so qualified emoji … resolve
identically”); the data-frame verb was the one member that had drifted,
which is the same shape as round 34’s finding, in docs rather than code.

**A second, sharper inconsistency: the two emojize paths disagree on 17
strings.** `as_emoji("dog")` returns a dog (`U+1F415`) while
`text_to_emoji(":dog:")` returns a dog face (`U+1F436`). 464 strings are
both the exact Unicode name of one emoji and a shortcode alias of
another; for 17 of them the namespaces point at different emoji. The
pattern is a bare noun versus its “… face” variant (`cat`, `cow`, `pig`,
`tiger`, `mouse`, `rabbit`, `horse`, `whale`, `camel`, `kiss`) or a
plain object versus a decorated one (`umbrella`, `snowman`, `calendar`,
`sunglasses`, `satellite`, `train`).

**This was judged not to be a behaviour defect, and the reasoning
matters.** The tempting fix — make
[`as_emoji()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/as_emoji_name.md)
prefer shortcodes so the two agree — is wrong: `"dog"` really is the
Unicode name of `U+1F415`, an exact name match is a stronger signal than
an alias, and `:dog:` is *explicitly delimited* as a shortcode, so the
two inputs genuinely mean different things. Changing the order would
make
[`as_emoji()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/as_emoji_name.md)
stop returning the emoji actually named by its argument. What was
actually broken was documentary in three ways: the precedence chain
(exact name, then shortcode, then ’s table) was unstated, the doc listed
the namespaces in the opposite order to the code (“shortcodes/names”),
and
[`text_to_emoji()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/text_to_emoji.md)’s
`@seealso` called
[`as_emoji()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/as_emoji_name.md)
“the vector helper” while they disagree on 17 inputs. All three are
fixed; no behaviour changed.

**Also verified clean, and recorded so they are not re-audited:**

- [`emoji_dfm()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_dfm.md)
  row sums equal `.emoji_n` per document, with presentation variants
  folded into a single column and no duplicated column names.
- [`emoji_pairs()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_pairs.md)
  totals `choose(j, 2)` over the distinct canonical glyphs per document;
  `emoji_ngrams(n = k)` yields exactly `max(k_row - k + 1, 0)` rows for
  k = 2, 3, 4 and never builds an n-gram spanning two rows. Round 6’s
  count-agreement sweep covered the frequency/tokens family but **not**
  these three, so this closes that gap.
- Every rewriting policy except the default `"keep"` (`strip`, `name`,
  `placeholder`, `shortcode`) and both
  [`emoji_to_text()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_to_text.md)
  formats compose to `.emoji_n == 0`; `"keep"` leaves the text
  byte-identical.
- All three text-rewriting verbs are idempotent.
- Every ratio column sits inside its documented range.
  `.emoji_ambiguity_mean` and `_max` reach 1.0983, which looked like a
  bounds violation until the doc was read: entropy is in **nats**, so
  the ceiling is `log(3)` = 1.0986, exactly as documented. The bug was
  in the audit’s assumption, not the code.
- Every catalogue name (5042) and every catalogue shortcode (4853)
  emojizes to an emoji with the right key, including the **175 alternate
  aliases**
  [`emoji_to_text()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_to_text.md)
  never emits and the round-trip test therefore cannot reach.

**Two wrong hypotheses, both killed by measurement rather than
argument.** I predicted the qualified form won the round trip through a
row-ordering dependence in `setNames(ref$emoji, ref$shortcode)`, and
mutated the table order to prove the new test guarded it — the mutation
did not bite, because the unqualified row simply has no shortcode and
the key lookup does the work. And three expectations in the composition
probe were mine, not the package’s:
[`emoji_ngrams()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_ngrams.md)
returns occurrence rows rather than counts,
[`emoji_sanitize()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sanitize.md)
defaults to `policy = "keep"` so an unchanged `.emoji_n` is correct, and
the entropy ceiling above. **When a probe disagrees with the package,
the probe is the more likely culprit** — check the documented contract
before writing a finding.

------------------------------------------------------------------------

**Round 37 (2026-09-05) — the axis CI structurally cannot see.**

Rounds 35 and 36 exhausted the properties a test on this machine can
check. This round asked a different question: **what would CI never
catch, however green it is?** The matrix is macOS/Windows release plus
Ubuntu devel, release and oldrel-1 — so anything about *older* R, or
about files CI regenerates rather than compares, is invisible to it.

**The finding: the declared R minimum was unachievable.** `DESCRIPTION`
said `R (>= 3.5.0)`. The hard dependencies say otherwise:

| hard dependency | its own R floor |
|-----------------|-----------------|
| dplyr 1.2.1     | **R \>= 4.1.0** |
| tidyr 1.3.2     | **R \>= 4.1.0** |
| rlang 1.3.0     | R \>= 4.0.0     |
| lifecycle 1.0.5 | R \>= 3.6       |
| emoji 16.0.0    | R \>= 3.5       |
| tibble 3.3.x    | R \>= 3.4.0     |

[`install.packages()`](https://rdrr.io/r/utils/install.packages.html)
serves only current versions, so on R 3.5 to 4.0 the resolver fetches a
`dplyr` that refuses to install and the user gets an opaque dependency
failure instead of “this package needs a newer R”. The package’s own
code needs nothing newer than 3.5 — checked explicitly for the native
pipe, `\(x)` lambdas,
[`sort_by()`](https://rdrr.io/r/base/sort_by.html),
[`...names()`](https://rdrr.io/r/base/dots.html) and `%||%`; none
appear, and `%||%` turned out to be **defined locally** at
`R/emoji-engine.R:447` with a comment saying why, so it does not
silently depend on base R 4.4. The floor is purely dependency-driven, so
the honest value is **4.1.0**, and that is now declared, explained in
`cran-comments.md`, and guarded by a test that compares the declared
minimum against the installed hard dependencies’ floors.

**A test that passes because it never ran is worth nothing.** The guard
test carries `skip_on_cran()`, and my first mutation of it — lowering
the declared minimum back to 3.5.0 — produced **no failure at all**. The
reason was not that the test was weak but that it was *skipped*:
`NOT_CRAN` is unset in a bare
[`testthat::test_file()`](https://testthat.r-lib.org/reference/test_file.html)
run. Re-running with `NOT_CRAN=true` then exposed a second, worse
problem: the test errored **even in the correct state**, because
`expect_gte()` subtracts its arguments to build a failure message and
`-` is not defined for `numeric_version`. So the assertion was replaced
with `expect_true(a >= b, info = ...)`. Two defects in one small test,
both invisible to a green run.

That prompted an audit of the whole suite’s skip behaviour, which came
back clean: without `NOT_CRAN` exactly **one** block skips (the new
one), and 5480 assertions still execute, so no earlier round’s “0
failures” was vacuous. The other `skip_if_*` guards are all conditioned
on genuinely absent resources and none fire on this host.
`skip_on_cran()` is nonetheless the right call here, because the check
reads *third-party* metadata: if `dplyr` later raises its own floor,
that should not turn into a CRAN check failure for tidyEmoji.

**Also verified clean, and recorded so they are not re-audited:**

- **`README.md`’s committed output is not stale.** It carries 117 lines
  of `#>` snapshots generated from `README.Rmd`, and round 34 changed
  [`emoji_extract_nest()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_extract_nest.md)
  from a `data.frame` to a tibble — which prints differently — so this
  was a live staleness risk. Re-knitting and diffing *only the output
  blocks* (prose line-wrapping differs because `knit()` skips the
  `github_document` pandoc pass, which made a whole-file diff useless)
  shows **zero** differences.
- Every checkable claim in the introduction vignette holds: the
  crosswalk really has 10 categories and
  [`emoji_categorize()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_categorize.md)
  emits exactly those 10 over the whole catalogue; the emotion lexicon’s
  eight dimensions all sit in `[0, 1]` as stated; `breaks = seq(1, 15)`
  does not clip anything (the plotted quantity is the per-entry total,
  correctly derived with
  `group_by(.row_number) |> summarise(sum(.emoji_count))`, and its
  maximum is 33 — but `scale_x_continuous(breaks =)` sets ticks, not
  limits); and the
  [`top_n_emojis()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/top_n_emojis.md)
  sentence attributing `n = 20` reads correctly once the whole sentence
  is read rather than a grep window.
- All four `?topic` cross-references in the vignette and README resolve
  to real documented objects, including
  [`?category_unicode_crosswalk`](https://pursuitofdatascience.github.io/tidyEmoji/reference/category_unicode_crosswalk.md),
  which is a bundled dataset rather than an export and so easy to
  mistake for a dead link.
- All nine figure chunks carry `fig.alt`.

One prose correction: 68.2% of emoji-bearing entries carry exactly one
emoji, which the vignette called “the overwhelming majority” and a
figure’s alt text called “the vast majority”. Both now say “about
two-thirds”.

**Closing the verification loop: the guard test does run in CI.** The CI
log reports `[ FAIL 0 | WARN 0 | SKIP 3 | PASS 5473 ]` against 0 skips
locally, so the three skips were checked rather than assumed benign.
They are all source-availability guards, and the new R-minimum test is
**not** among them – which also confirms empirically that
`r-lib/actions/check-r-package@v2` sets `NOT_CRAN=true`:

| skipped in CI                 | what it checks            |
|-------------------------------|---------------------------|
| `test-invariants.R:876`       | NEWS.md headings          |
| `test-invariants.R:1116`      | non-ASCII in test sources |
| `test-regression-0.4.0.R:962` | the vignette corpus       |

All three inspect **repo files**, which are absent when `R CMD check`
runs the tests from the installed package, so skipping is the correct
behaviour and not a coverage gap. One consequence is worth knowing
rather than fixing: the ASCII-source guard – which caught literal ZWJ
characters in new test code twice this session – protects only when the
suite is run from the source tree. `R/` is covered natively by
`R CMD check`’s own non-ASCII check; `tests/` is covered only locally.
Relocating it so CI could see it would mean shipping repo files in the
tarball, which is worse. **So: keep running the suite locally before
every commit; a green CI does not exercise those three.**

**The lesson to carry forward.** Three rounds running, the productive
move has been to ask what the *current* verification cannot see: round
35 found cost because every test asserted values and none measured time;
round 36 found doc drift because every test called one verb and none
composed two; round 37 found mis-declared metadata because CI never runs
an R older than oldrel-1. **Green does not mean checked — it means
checked by whatever is currently checking.**

------------------------------------------------------------------------

**Round 38 (2026-09-05) — state, the last thing every test had
avoided.**

Every round up to here ran verbs on fresh data in isolation. Nothing
asked whether one call leaves behind state that changes the next. The
package has two pieces of session state: a cache environment
(`reference`, `sentiment`, `ref_keys`, `emotion`, `ambiguity`, `type`,
`lexicons`) and a user-writable lexicon registry. Either could in
principle make an answer depend on call order, and no test would have
noticed.

**The finding:
[`emoji_lexicons()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_lexicons.md)
returned columns with stray element names.** The registry is a *named*
list, so `lapply(reg, ...)` and `vapply(reg, nrow, integer(1))` returned
named results, and
[`dplyr::bind_rows()`](https://dplyr.tidyverse.org/reference/bind_rows.html)
padded the bundled rows with `""`. The result:

    > emoji_lexicons()$n
              mine
     969  150    2

The tibble itself printed normally – tibble ignores element names –
which is exactly why 37 rounds missed it. It only shows when a user
extracts a column, which is what programmatic use does.
[`sum()`](https://rdrr.io/r/base/sum.html),
[`filter()`](https://rdrr.io/r/stats/filter.html) and indexing all still
worked, so this was cosmetic, but the `""` padding is the unmistakable
signature of [`c()`](https://rdrr.io/r/base/c.html) mixing named and
unnamed parts and it was plainly unintended. Fixed with
[`unname()`](https://rdrr.io/r/base/unname.html) on both, and
generalised: a new test asserts **no verb returns a column carrying
element names**, over every exported function that returns a data frame,
with a custom lexicon registered so the registry path is live.

**Everything else about the state came back clean, and is recorded so it
is not re-audited:**

- **Warm cache equals cold.** Nineteen verbs called twice in one session
  return [`identical()`](https://rdrr.io/r/base/identical.html) results.
  Nothing is mutated in place through the cache’s environment reference.
- **`emoji_ambiguity(measure =)` does not leak one measure into
  another.** The cached table holds every measure as a column and
  `measure` selects one afterwards, so `gini`, `entropy` and
  `neutral_share` are distinct and asking in either order gives the same
  answers.
- **Registration is isolated.** Registering an unrelated lexicon leaves
  [`emoji_sentiment()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sentiment.md),
  [`emoji_score()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_score.md),
  [`emoji_emotion()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_emotion.md),
  [`emoji_risk()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_risk.md),
  [`emoji_summary()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_summary.md),
  [`emoji_tokens()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_tokens.md),
  [`emoji_ambiguity()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_ambiguity.md)
  and
  [`emoji_provenance()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_provenance.md)
  bit-identical.
- **Re-registering a name replaces it** – one row, and the new scores
  are the ones in force – and naming a lexicon is equivalent to passing
  the same table inline.
- **Bundled names are protected**:
  `register_emoji_lexicon("novak2015", ...)` errors, so the
  separately-cached `$sentiment` slot can never be shadowed by a
  registration and go incoherent.
- **A zero-row lexicon is accepted, and that is correct.** It was the
  one thing that looked like a validation gap. Checking the behaviour
  first (round 36’s lesson) showed it is indistinguishable from a
  lexicon that matches nothing: both give `NA` scores,
  `.emoji_n_scored = 0` where the row had emoji and `NA` where it had
  none, and the right `.emoji_n`. That is the documented convention, so
  rejecting it would have invented a restriction rather than fixed a
  defect.

**Two of my own measurement errors, both of the same kind.** The class
sweep first reported “42 verbs, no offenders” – but it wrapped each call
in `tryCatch(..., error = function(e) NULL)` and skipped the failures
silently, so two entries never ran and the count was inflated. Rebuilt
to report what actually executed, it was 41 of 43; and one of the two
exclusions turned out to be **my** error, not a non-data-frame verb:
`emoji_unicode_releases` is a *function* returning a tibble and I had
referenced it without `()`. True coverage is 42 of 43, the only genuine
exclusion being
[`emoji_unicode_version()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_unicode_version.md),
which returns a length-1 character. **A sweep that swallows its own
errors reports coverage it does not have** – the same failure mode as
round 37’s skipped test, one level up.

------------------------------------------------------------------------

**Round 39 (2026-09-05) — the documentation surface, where a green check
proves least.**

`R CMD check` passes an example that *runs*, whatever it returns, and
never executes a `\dontrun` block at all. So example quality and example
coverage are both invisible to a green check – the round-37 lens pointed
at docs.

**The state of it is good, and that is worth recording.** There are
**no** `\dontrun` or `\donttest` blocks anywhere in `man/`, so every
shipped example really executes under check; all 49 exports have
examples; and evaluating every example expression produced **100 data
frames, 0 errors and 0 degenerate results** – nothing returns zero rows
or an all-`NA` result set, so no example quietly teaches the wrong
thing. Both facts are now tests, each verified to bite (injecting a
`\dontrun` and deleting an `\examples` block each produce a failure).

**The finding:
[`emoji_search()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_search.md)
did not say how to get back from its `shortcode` column.** Searching
then emojizing is the obvious chain – the doc literally advertised the
result as “ready for … piping into other verbs” – and of 1341 shortcodes
returned across a spread of queries,
[`as_emoji()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/as_emoji_name.md)
recovers 1326 and
**[`text_to_emoji()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/text_to_emoji.md)
recovers all 1341**. The 15 misses (11 distinct) were checked against
round 36’s set rather than assumed new: every one is in it, so this is
the documented name-first precedence surfacing in a *third* place, not a
fresh defect. The fix is to name the safe path in
[`emoji_search()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_search.md)’s
`@details` and list the eleven strings. Its `@return` also now records
that `keyword` is `""` and never `NA` when the match came from the name
or a shortcode – 588 of 1363 rows in the probe, previously undocumented,
and a user filtering on `!is.na(keyword)` would have got every row back.

**Two defect classes checked and found already handled** – worth
recording so they are not re-audited:

- **Regex injection through user-supplied strings.** Every
  `grepl`/`sub`/`gsub`/ `strsplit` pattern in `R/` is a package-authored
  literal; no user string is ever used as a pattern.
  [`emoji_search()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_search.md)
  matches with `fixed = TRUE` throughout and carries a comment
  explaining why (the `+1` alias), and `emoji_to_text(wrap =)` is
  validated to contain `{x}` and substituted with `fixed = TRUE`.
  `placeholder` reaches only [`rep()`](https://rdrr.io/r/base/rep.html).
- **Stray names on vector returns.** Round 38 swept data-frame
  *columns*; the vector- and list-returning exports were outside that
  sweep, and [`vapply()`](https://rdrr.io/r/base/lapply.html) over a
  character vector self-names its result by default, so the same class
  could hide there. All four `as_emoji_*` helpers,
  [`emoji_unicode_version()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_unicode_version.md),
  and the inner elements of both list-columns (`.emoji_unicode`,
  `dimensions`) are unnamed. Now pinned, closing the round-38 sweep’s
  blind side.
- **[`emoji_search()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_search.md)
  is coherent with the rest of the package**: it reads
  [`emoji::emojis`](https://emilhvitfeldt.github.io/emoji/reference/emojis.html)
  directly rather than `emoji_reference()`, which was the reason to
  check it, but the two are the same 5042 rows, every glyph it returns
  has a key the package knows, and its `name` matches
  [`as_emoji_name()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/as_emoji_name.md)
  on all 1363 hits.

**A note on the new example-coverage test.** It reads `man/`, so like
the three guards round 37 identified it will skip under `R CMD check`
(which runs tests from the installed package, where `man/` has become
`help/`). Expect CI to report **SKIP 4**, not 3 – that is the correct
behaviour for a source-tree check, not a regression.

------------------------------------------------------------------------

**Round 40 (2026-09-05) — the dependency’s data, which no round had
questioned.**

Round 37 checked the declared **R** floor. It never checked *package*
floors, and `Imports: emoji` carries no version constraint at all while
the package reads that dependency’s data structures directly. Following
that thread found the most consequential defect of the loop so far – not
in the declaration, but in an assumption about the data behind it.

**The finding: 1252 of 5042 emoji had no Unicode version, including the
red heart.**
[`emoji::emojis`](https://emilhvitfeldt.github.io/emoji/reference/emojis.html)
records the introducing version on the **unqualified** member of a
variation pair and leaves it `NA` on the fully-qualified one:

| glyph           | `qualified`     | `version` |
|-----------------|-----------------|-----------|
| `U+2764 U+FE0F` | fully-qualified | **NA**    |
| `U+2764`        | unqualified     | 0.6       |

`emoji_reference()` copied `version` per row, so every fully-qualified
glyph inherited the `NA`. The consequences landed on the two verbs that
exist to use it:
[`emoji_version_profile()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_version_profile.md)
filed 207 types / 216 tokens – the red heart, the smiling face, the
skull and crossbones, the speech bubble – into its `version = NA`
bucket, and
[`emoji_adoption_lag()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_adoption_lag.md)
returned `NA` for all of them. For a user profiling a real corpus by
Unicode vintage, the most common emoji in that corpus were reported as
unknown.

**This is a coherence failure against the package’s own central
principle.** Every other glyph-to-metadata join – names, shortcodes,
types, both lexicons – already resolves through the `U+FE0F`-stripped
codepoint key, and rounds 34 and 36 verified that repeatedly. `version`
was the one column that did not. The fix is `.emoji_fill_by_key()`: fill
a row’s version from any row sharing its key. Measured before
implementing, the fill is unambiguous – **0** keys have all-NA versions,
**0** keys carry two different versions, and all 1252 rows are
recoverable, so afterwards the reference has **zero** unknown versions.
[`min()`](https://rdrr.io/r/base/Extremes.html) is used anyway, since
first availability is what “introduced in” means if upstream ever does
disagree. The filler writes back through a matching existing row so
`"12.1"` stays `"12.1"` instead of becoming `12.100000`.

**An existing test was asserting the defect.**
`expect_gt(sum(is.na(labels)), 0L)` – commented “glyphs with an unknown
version are reported, not dropped (documented)” – failed after the fix.
Its *intent* was sound; its *mechanism* was to rely on the catalogue
having gaps, which was only true because of the bug. It is now split in
two: the catalogue must have **no** unknown versions, and the
unknown-version path is exercised **synthetically** (forcing three
reference rows to `NA` still yields an `NA` row with every token
accounted for). Worth noting for the next round: **a test can pin a bug
in place as firmly as it pins a feature**, and it reads exactly the same
either way. The tell was that the assertion demanded a *lower bound on
missing data* – a shape worth being suspicious of.

**Also verified clean:**

- The four structural contracts on `emoji` hold: `aliases` and
  `keywords` are list columns, `emoji_name` is a named name-to-glyph
  vector, `emoji_locate_all()` returns `start`/`end` matrices, and every
  column the package reads is present.
- [`emoji_unicode_releases()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_unicode_releases.md)
  listing versions absent from
  [`emoji::emojis`](https://emilhvitfeldt.github.io/emoji/reference/emojis.html)
  (`6.0`-`10.0`, `17.0`) is the **intentional two-series design** – 17
  emoji-spec rows plus 6 Unicode rows, with `series` distinguishing them
  – not staleness. Every version the profile now emits is present in the
  release table.
- `sum(n_tokens)` = 4830 equals the glyphs detection actually finds; the
  gap to 5042 is the known 95.8% standalone detection rate from rounds
  8-10, not a loss in the profile.

------------------------------------------------------------------------

**Round 41 (2026-09-05) – auditing the assertions themselves.**

Round 40 found, by accident, that a test was pinning a defect in place:
`expect_gt(sum(is.na(labels)), 0L)` *required* missing data, and passed
only because the version column had 1252 gaps. That was worth
generalising, because nothing in forty rounds had pointed the
verification at itself. This round swept the suite for assertions of the
same family – ones that require missing data, require a failure, or
bound a quantity loosely enough to hide a regression.

**Most of the `is.na` assertions are legitimate** and were left alone:
they pin the documented no-emoji convention on a named row, which is
exactly what they should do. One that looked suspicious after round 40 –
`expect_true(is.na(vp$version))` in `test-regression-0.4.0.R` – is
correct: its fixture is a *synthetic* glyph (grinning ZWJ grinning)
absent from the catalogue, so it has no version for a real reason and
round 40’s fill does not touch it.

**Three assertions were weaker than the truth**, all bounding a quantity
that is in fact exact:

| assertion | bound | actual |
|----|----|----|
| `sum(n == 0L)` – catalogued ZWJ spellings undetected | `<= 2` | exactly 2 |
| `sum(orphaned_joiners(zwj) > 0L)` – spellings losing a joiner | `<= 2` | exactly 2, the *same* two |
| `nrow(out)` – [`emoji_flag_ambiguous()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_flag_ambiguous.md) on a two-emoji fixture | `<= 2` | exactly 2 |

**Why an inequality is the wrong shape here.** These bounds are the
residual of rounds 8-10, which took orphaned joiners from 793 to 2.
Written as `<= 2` they accept 0, 1 or 2 – so if a future change
reintroduced one, the suite would stay green, and the comment explaining
“the only two” would quietly become wrong. Worse, no count can detect
the residual *set* changing while its size holds at two. So the two
spellings are now **named** (`U+1F441 U+200D U+1F5E8`,
`U+1F3F3 U+200D U+26A7`), and the reason they are irreparable is
asserted rather than only commented: neither carries `U+FE0F` – which is
why there is no detectable component to grow from – and each one’s
fully-qualified sibling is detected as a single glyph, so the residual
is a property of the spelling and never of the emoji. The two sets are
also asserted equal to each other, which the two separate count bounds
never established.

Mutation-verified individually: substituting one expected glyph **while
keeping the set size at two** fails (the case the old bound structurally
could not catch), adding a spurious member to the joiner-losing set
fails, and moving the row count to `3L` fails.

**Two loose bounds were deliberately left loose**, and that distinction
is the point. `expect_gt(length(zwj), 2000L)` and
`expect_gt(length(canonical), 3000L)` (actual 2501 and 3790) are lower
bounds on *fixture size*, not claims about the package’s correctness –
they exist to confirm the fixture is non-trivial, and pinning them
exactly would break the suite on any `emoji` package update that adds
glyphs. **A bound is right when the thing it bounds is genuinely allowed
to vary, and wrong when it is not**; the audit is about telling those
two apart, not about replacing every inequality.

No package code changed this round. Suite 331 blocks, 5887 assertions, 0
failures.

------------------------------------------------------------------------

**Round 42 (2026-09-05) — tie-breaking, which five green platforms
cannot compare.**

CI runs macOS, Windows and three Ubuntu R versions, and never compares
their *outputs* to each other. So an ordering that fell back on input
order, a hash, or the session’s collation would let every job pass while
producing a different answer on each platform. Round 33 established that
output does not depend on input row order; nothing had checked the
harder case – ties **within** an equal key, which is exactly where such
a fallback would surface.

**The ordering itself is already sound, and that is the finding.** Every
one of the ordering sites carries an explicit stable secondary key, and
every [`order()`](https://rdrr.io/r/base/order.html) call passes
`method = "radix"`, which is C-locale and so immune to collation.
Measured with a five-way exact tie (five glyphs, each appearing twice,
so `n` is tied throughout and the entire output order *is* the
tie-break):

- [`emoji_frequency()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_frequency.md),
  [`top_n_emojis()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/top_n_emojis.md),
  [`emoji_dfm()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_dfm.md)
  column order: tie order equals the C-locale glyph order exactly, and
  is unchanged under three different input permutations.
- [`emoji_pairs()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_pairs.md)
  /
  [`emoji_cooccurrence()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_cooccurrence.md):
  equal-`n` blocks in C-locale `item1`/`item2` order,
  permutation-stable.
- [`emoji_ambiguity()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_ambiguity.md):
  `rank` monotone, reproducible call to call, and C-locale glyph order
  within each tie group.
- `top_n_emojis(n = k)` returns exactly `min(k, distinct)` rows, cutting
  a straddling tie by glyph order and never padding.

**What was actually wrong was the promise, not the behaviour.**
[`emoji_frequency()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_frequency.md)’s
`@return` documents its tie rule in full;
[`top_n_emojis()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/top_n_emojis.md),
[`emoji_dfm()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_dfm.md)
and both ambiguity verbs apply the same discipline and documented none
of it.
[`emoji_dfm()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_dfm.md)’s
rule existed only as a code comment (“column order: descending total
count, ties by glyph. radix = C-locale ordering”) – a real contract,
since users index dfm columns by position, kept private. Same shape as
rounds 34 and 36, inverted: here one member *has* the documented
contract and four siblings lack it. All four `@return` blocks now state
it, including that `rank` uses `ties.method = "min"` so ranks are
deliberately non-consecutive – confirmed against the data: 76 tie groups
over 969 scorable emoji, all 75 mid-table groups skipping by exactly
their group size, ranks running 1 to 804.

**A mutation-testing mistake of my own, and the one it exposed.** Three
perturbations were run. Dropping the glyph key from
[`emoji_dfm()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_dfm.md)’s
column order produced 6 failures. Switching `ties.method` from `"min"`
to `"first"` appeared to produce **none** – until I checked, and found
the string occurs twice in the file and my edit had landed on the
roxygen comment I had *just written*, not on the code. Retargeted at the
code line it produces 2 failures and drops the tie groups to 0. **A
mutation that edits a comment proves nothing, and a doc fix in the same
file makes that mistake easy to make.**

The third mutation is the interesting one, because it genuinely does not
bite and should not be made to. Removing
[`emoji_frequency()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_frequency.md)’s
explicit `arrange(desc(n), emoji)` tie-break changes nothing, because
[`dplyr::count()`](https://dplyr.tidyverse.org/reference/count.html)
*already* returns its groups in C-locale glyph order and `arrange()` is
stable – two independent mechanisms produce the same order. The explicit
key stays, since it makes the guarantee local instead of resting on
`count()`’s ordering remaining what it is, but the test can only pin the
observable contract, not that particular line. Worth stating rather than
reporting a verification that did not happen.

------------------------------------------------------------------------

**The pattern worth carrying into 0.5.0.** §9 records that every release
found defects in the code written just before it. This audit found its
crop **before** the features were written — and three of the four block
a planned feature group, which is why §3.1 recommends resequencing
rather than folding the fixes in.

------------------------------------------------------------------------

## 2. What changed in the world since `features.md` was written

This section is the reason to re-plan rather than simply execute wave 2.
Four things moved, and three of them change the design.

*Verification status: the
[emoji](https://emilhvitfeldt.github.io/emoji/) facts in §2.1 were
**confirmed against a real install** (`emoji` 16.0.0, R 4.4.1) on
**2026-08-30**, discharging the “action before coding” that the previous
draft of this section carried. The literature in §2.4 and §10 comes from
web search; where a claim rests only on a search result and not on a
fetched document it is still marked **(verify)**.*

### 2.1 `{emoji}` moved — verified against the install

`emoji` **16.0.0**, `emojis` = **5042 rows x 19 columns**. The previous
draft guessed nine columns; there are nineteen, and the extra ten change
the plan in both directions.

    emoji  name  group  subgroup  version  points  nrunes  runes  qualified
    vendor_apple  vendor_google  vendor_twitter  vendor_one  vendor_facebook
    vendor_messenger  vendor_samsung  vendor_windows
    keywords  aliases

**Confirmed as hoped — the modifier foundation is real.**

- `qualified` has exactly the four expected levels: `fully-qualified`,
  `unqualified`, `minimally-qualified`, `component`. The
  qualified/unqualified asymmetry that 0.2.1 patched anecdotally can now
  be handled exhaustively.
- `emoji_modifiers` is a **4468-row** tibble of `emoji_modifiers` /
  `emoji` / `modifiers`, covering **454 unique modifiable base glyphs**
  — that 454 *is* the denominator §4.1 insists on, available as data
  rather than as a heuristic.
- `component` rows carry the five skin tones **and** red / curly / white
  / bald hair, so `emoji_hair()` (§4.1) is a join, not an
  implementation.
- `emoji_modifier_extract()` and `emoji_modifier_remove()` both exist.
- 2735 of 5042 rows have “skin tone” in `name`.
- Flags: `subgroup` is `country-flag` for **259** rows and
  `subdivision-flag` for **3**, which sizes §4.2 exactly and confirms
  subdivision tags are a three-case problem, not a long tail.

**A new unblock — `keywords` and `aliases` are fully populated.**

Both are non-empty for **all 5042 rows**. `keywords` is the CLDR English
keyword set (`grinning face` -\> *cheerful, cheery, face, grin,
grinning, happy, laugh, nice, smile, smiling, teeth*); `aliases` is the
shortcode set (`grinning, grinning_face`).

This partially dissolves the CLDR blocker in §5. **English** keyword
search and tag-based lookup need *no* download helper — the data is
already bundled and
[`emoji_search()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_search.md)
is currently not using it. Only *multilingual* CLDR still needs the
fetch-and-cache decision in §7.2. See §4.6.

**A new dead end — all eight `vendor_*` columns are empty.**

Every one of them: `TRUE = 0`, `FALSE = 1910`, `NA = 3132`. The columns
exist but no glyph is marked as supported by any vendor.

**So `emoji_vendor_support()` cannot be built on
[emoji](https://emilhvitfeldt.github.io/emoji/)** — it was parked for a
later release on the assumption that this data would arrive with the
package. It has not. Building it means sourcing vendor-support data
ourselves (Emojipedia scrapes, `emoji-test.txt` does not carry it),
which is a licence and maintenance tail well outside 0.5.0. **Move it to
“explicitly not” (§5)** and say why, so this is not rediscovered a
fourth time.

**One caveat that matters for the refresh.** `unique(version)` tops out
at **16.0** — the installed data does *not* contain Emoji 17.0’s 163
additions (§2.2). Any crosswalk refresh is bounded by upstream’s Unicode
version, not by ours, so
[`emoji_provenance()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_provenance.md)
reporting 16.0 is correct behaviour rather than a staleness bug. Pin a
minimum [emoji](https://emilhvitfeldt.github.io/emoji/) version the
moment we read `qualified`, `keywords` or `emoji_modifiers`, with a test
that fails loudly if a column disappears.

### 2.2 Unicode Emoji 17.0 shipped

Released **2025-09-09** alongside Unicode 17.0: **163 new emoji**,
raising the RGI total to **3,953** including skin-tone and gender
variations. New glyphs include distorted face, fight cloud, hairy
creature, ballet dancer, orca, landslide, trombone, treasure chest and
expanded people sequences.

Two consequences:

- [`emoji_unicode_releases()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_unicode_releases.md)
  already carries `17.0 -> 2025-09-09`; that entry is confirmed correct.
  The table needs one new row per Unicode release, forever.
- The bundled crosswalks are only as current as the installed
  [emoji](https://emilhvitfeldt.github.io/emoji/).
  [`emoji_provenance()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_provenance.md)
  exists so a user can *see* this, but the `data-raw/` refresh needs to
  become a release-checklist item rather than a remembered habit (§8).

### 2.3 Colour emoji now render natively in R

[ragg](https://ragg.r-lib.org) renders colour emoji in ggplot2 output.
That substantially deflates `features.md` §14 (Theme L, visualization),
which was built on the premise that plotting real emoji is “perennially
awkward” and that tidyEmoji should supply image URLs for
[ggimage](https://github.com/YuLab-SMU/ggimage).

**Revised position:** do not build `emoji_image()`. The remaining real
needs are two diagnostics, and they are cheap:

- `emoji_render_check()` — “will this glyph draw on this device?”, the
  answer to “why are my axis labels tofu boxes?”
- `emoji_label()` — a render-safe label that degrades to name or
  shortcode.

Both belong with the accessibility work in §4.3, not in a visualization
theme of their own.
[emojifont](https://guangchuangyu.github.io/emojifont/) remains
showtext-based and RStudio-incompatible, which is a reason to point
users at `ragg`, not to wrap
[emojifont](https://guangchuangyu.github.io/emojifont/).

### 2.4 New literature, 2024-2026

Grouped by whether it changes what we build.

**Changes the plan — accessibility is a first-class theme, not a
footnote.**

- *Emoji Accessibility for Visually Impaired People* (CHI 2020,
  <doi:10.1145/3313831.3376267>) established the problem: screen readers
  speak each emoji’s Unicode name, so runs of emoji and mid-sentence
  emoji make messages hard to follow.
- *“Party Face Congratulations!”* (PACM HCI / CSCW 2024,
  <doi:10.1145/3641014>) tested two interventions with sighted senders:
  **PREVIEW** (show the sender the transcript a screen reader would
  narrate) and **ALERT** (summarise the accessibility problems in the
  message). Participants preferred PREVIEW, because it leaves the
  judgement to the human.
- Practitioner guidance converges on the same two rules: avoid runs of
  emoji, and prefer sentence-final placement over emoji sandwiched
  between words.

This is the finding of the round, because **tidyEmoji already has every
primitive it needs**: `emoji_to_text(format = "name")` *is* PREVIEW, and
[`emoji_position()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_position.md) +
[`emoji_ngrams()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_ngrams.md) +
[`emoji_ratio()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_ratio.md)
are ALERT. See §4.3.

**Reinforces the modifier theme.**

- *Digital Skin, Digital Bias: Uncovering Tone-Based Biases in LLMs and
  Emoji Embeddings* (ACM Web Conference 2026,
  <doi:10.1145/3774904.3792508>) — the first large-scale comparative
  study of skin-tone bias across emoji embedding models (emoji2vec,
  emoji-sw2v) and four modern LLMs. Skin tone is not a cosmetic
  attribute of a glyph; it propagates into downstream representations.
- *Digital Colourism? Understanding Emoji Skin Tone Preferences Among
  Indian-Origin Users* (BCS HCI 2025) — tone preference is culturally
  patterned well beyond the US/UK samples the earlier work used.
- 2025 work reports that women are more likely than men to use tones
  matching their own and to value the range of options — a *group
  difference*, which is exactly what `emoji_tone_summary(group_by =)`
  should make a one-liner.

**Reinforces the LLM theme (0.4.0 shipped the plumbing; the case got
stronger).**

- **EMODIS** is now published at **AAAI 2026** (arXiv 2511.07193) with a
  number worth quoting: human annotators 88.5% versus GPT-4 58.8% on
  context-dependent emoji disambiguation — a roughly 30-point gap.
- *Small Symbols, Big Risks: Emoticon Semantic Confusion in LLMs* (arXiv
  2601.07885, 2026) — six LLMs, average confusion ratio above 38%, and
  **over 90% of confused responses are “silent failures”**:
  syntactically valid output that deviates from intent. This is the
  strongest argument yet that
  [`emoji_sanitize()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sanitize.md)
  should be an explicit, recorded decision.
- *Emoji-Based Jailbreaking of Large Language Models* — supports the
  defensive framing of a future `emoji_obfuscation_scan()`, and the
  discipline of reporting structural anomalies rather than shipping
  attack patterns.

**Applied domains — new syntheses, no new API pressure.**

- *Emojis in Marketing and Advertising: A Systematic Literature Review*
  (Behavioral Sciences 2025, <doi:10.3390/bs15111490>), T-C-C-M
  framework; the field is “growing in volume yet immature”.
- *Emoji-based marketing in consumer behavior: a systematic literature
  review* (Cogent Business & Management 2026,
  <doi:10.1080/23311975.2026.2669001>), 45 articles, ADO framework.
- Health-communication reviews cover food safety, behaviour guidance and
  doctor-patient communication. None of this asks for a new verb:
  [`emoji_type()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_type.md)
  /
  [`emoji_faceness()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_faceness.md)
  and
  [`emoji_congruence()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_congruence.md)
  already carry the variables these literatures use. **Continue to ship
  no clinical instrument.**

**Semantics and embeddings — still not urgent.**

EmoSim508 remains the intrinsic benchmark; a 2025 evaluation puts GPT-4o
at 79.23% semantics preservation. Nothing here beats the plan of
building `emoji_embed_corpus()` (dependency-free PPMI + SVD) before
touching pretrained downloads.

### 2.5 R ecosystem — the confirmed gaps

| Capability | State of the R ecosystem | tidyEmoji’s position |
|----|----|----|
| Emoji data + string helpers | [emoji](https://emilhvitfeldt.github.io/emoji/), current and actively maintained | **Depend on it.** Do not duplicate |
| Modifier extraction / base glyph | [emoji](https://emilhvitfeldt.github.io/emoji/) has it | Wrap as tidy verbs |
| ISO 3166 \<-\> flag emoji | **Nothing on CRAN.** A gist, and non-R libraries | **Real gap — fill it** (§4.2) |
| Colour emoji in plots | [ragg](https://ragg.r-lib.org) natively; [emojifont](https://guangchuangyu.github.io/emojifont/) (showtext, RStudio-incompatible) | Point at `ragg`; ship diagnostics only |
| Emoji + text sentiment | `{EmojiSentR}` (integrated), `{text2emotion}` (emotion + emoji mapping) | Stay composable; document the recipe |
| Grapheme segmentation | [stringi](https://stringi.gagolewski.com/) only | Suggests-gated opt-in engine (§4.5) |
| Tidy emoji verbs over a text column | **tidyEmoji** | The differentiator. Defend it |

`{text2emotion}` is new to this survey and should be read before 0.5.0
ships: it maps text to emotion *and* emoji, so there may be overlap with
[`emoji_emotion()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_emotion.md)
worth acknowledging in the docs. **(verify)**

### 2.6 A second axis: audience, not just features

Everything above asks “what has changed in the emoji tooling and
literature we already track?”. A separate question — **which research
communities work with emoji data that our input shape does not fit?** —
turned out to be the more productive one, and it now has its own
section. See **§10**. The headline is that the package assumes a text
column of prose, and **four** active literatures hold *pre-aggregated
tallies* instead — GitHub reaction studies (§10.2), survey psychometrics
(§10.6), retail-investor boards (§10.9) and workplace messaging (§10.15)
— which no current verb accepts. That count rising from two to four over
the survey is the strongest single argument in this document for
`emoji_from_counts()`.

------------------------------------------------------------------------

## 3. What 0.5.0 should be

**Theme: identity, place and access — the human attributes of a glyph.**

Three feature groups plus two pieces of infrastructure. It is coherent
(everything answers “what does this glyph say about a person or a place,
and who can read it?”), it is the long-planned phase, and §2.1 has made
the expensive part cheap.

| Group | Why now |
|----|----|
| §4.1 Modifiers & representation | Long planned; upstream now supplies the primitives; 2025-26 literature strengthens the case |
| §4.2 Flags \<-\> countries | Confirmed gap in the R ecosystem; pure arithmetic, no new data |
| §4.3 Accessibility | **New.** Highest value-to-effort left; every primitive already shipped |
| §4.4 Unicode property surface | Now a join, not a parser (§2.1) |
| §4.5 [stringi](https://stringi.gagolewski.com/) grapheme engine | Retires a documented limitation; gives exact ratios |

**Size discipline — reconciled after the audit (§1.1-§1.8).** 0.4.0
added 21 verbs in one release, which was a lot to review at once. This
document opened by targeting **10-14 verbs** for 0.5.0. Eight rounds of
auditing have since added nine *correctness* items to the release, and
several of them are prerequisites for the features rather than
independent work. The honest position:

**New verbs proposed (§4.1-§4.6 plus §1.7):**

| Group | Verbs | Count |
|----|----|----|
| §4.1 Modifiers | `emoji_skin_tone()`, `emoji_gender()`, `emoji_hair()`, `emoji_base()`, `emoji_zwj_components()`, `emoji_tone_summary()`, `emoji_diversity()` | 7 |
| §4.2 Flags | `emoji_country()`, `emoji_flag()`, `emoji_subdivision()` | 3 |
| §4.3 Accessibility | `emoji_speak()`, `emoji_a11y_check()`, `emoji_label()`, `emoji_render_check()` | 4 |
| §4.4 Properties | `emoji_properties()`, `as_emoji_canonical()` | 2 |
| §4.6 Keywords | `emoji_keywords()`, `emoji_find()` | 2 |
| §1.7 Coverage | `emoji_coverage()` | 1 |
|  | **total** | **19** |

**Correctness work the audit added, none of it optional:**

| Item | Why it cannot wait | Blocks |
|----|----|----|
| [`emoji_position()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_position.md) grapheme fix (§1.1) | reports a final family emoji at 0.333 | **§4.3** |
| Flag validation, 259+3 set (§1.2) | `🇽🇽` maps to a fabricated ISO code | **§4.2** |
| Orphan-modifier accounting (§1.2) | corrupts the modified÷modifiable ratio | **§4.1** |
| Grouped guard on 3 aggregators (§1.5) | silent cross-group pooling | — |
| Rate/denominator audit (§4.8) | makes existing output CoDA-safe | — |
| Round-trip tests (§1.3), `var` message (§1.5), `.emoji_*` reserved (§1.6) | cheap, and each defends a stated contract | — |

**Three of the six block a feature group.** That is the finding that
should drive the release shape, and it points at a conclusion this
document did not start with.

### 3.1 Recommendation — make 0.5.0 a correctness release and move the theme to 0.6.0

The roadmap’s own §9 states the principle: *“the maintenance patch leads
— it fixes correctness before we build on the engine.”* That is exactly
what 0.2.1 did, and §9’s “three audits” note observes that every release
has found defects in the code written just before it. **The eight audit
rounds in §1 found a fourth crop, and they found it *before* the
features were written rather than after.** Acting on that is cheaper
than the alternative.

**This table is the authoritative plan.** Where §9’s ledger or an
individual section says something different about scheduling, §3.1 wins
— the ledger is a running list, this is the reconciliation.

**0.5.0 — Correctness & honesty**

| Kind | Items |
|----|----|
| *Correctness (§1)* | [`emoji_position()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_position.md) grapheme fix (§1.1); flag-set validation (§1.2); orphan-modifier accounting (§1.2); grouped guard on 3 aggregators (§1.5); `time`/`var` message (§1.5); `.emoji_*` reserved, documented (§1.6) |
| *Engine* | §4.5 grapheme engine (`engine =` on affected verbs) |
| *Honesty* | §4.8 rate/denominator principle + audit; `emoji_coverage()` (§1.7) |
| *Additions on verified data* | `emoji_keywords()`, `emoji_find()` (§4.6); `emoji_properties()`, `as_emoji_canonical()` (§4.4); **`presentation = "any"` (§4.7 — its own text says ship with §4.4)**; **`emoji_identical()` (§10.1 — S-sized, rides §4.4)** |
| *Documentation* | round-trip tests + reversible-LLM vignette (§1.3); [`?emoji_sanitize`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sanitize.md) policy ladder (§1.9); one real `text_score` recipe at `eval = FALSE` (§10.15); research-question index + `\concept{}` tags (§10.14) |
| **New verbs** | **6** — `emoji_coverage()`, `emoji_keywords()`, `emoji_find()`, `emoji_properties()`, `as_emoji_canonical()`, `emoji_identical()` |

**0.6.0 — Identity, place & access, plus the input-shape widening**

| Kind | Items |
|----|----|
| *The theme* | §4.1 modifiers, §4.2 flags, §4.3 accessibility — now on a fixed [`emoji_position()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_position.md), a validated flag set and correct modifier accounting |
| *Input shape* | **`emoji_from_counts()` (§10.2)** — requested by four literatures (§2.6); **`emoji_sample()` (§10.13)** — stratified stimulus draw |
| *Zeros* | structural-vs-count zeros, `zeros =` / `.emoji_available` (§4.8) |
| **New verbs** | **12-15** (10-13 themed + 2 input-shape) — apply iteration-1’s cut if this exceeds review capacity |

**Why this is better than shipping 19 verbs with the fixes folded in:**

1.  **The features get built on correct primitives.** §4.3’s
    `emoji_a11y_check()` is specified to derive interrupting-emoji
    counts from
    [`emoji_position()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_position.md).
    If both ship together, the accessibility verb is being written
    against a primitive that is being repaired in the same release — the
    most error-prone possible ordering.
2.  **The fixes are user-visible and deserve their own NEWS entry.**
    “Your `.emoji_rel_position` values were wrong for multi-codepoint
    emoji” is a headline, not a footnote under nineteen new verbs.
3.  **`emoji_coverage()` reframes the existing package** rather than
    extending it. Users learn that the emotion lexicon covers 3% of RGI
    (§1.7) — that changes how they read output they already have, which
    is a correctness release’s job.
4.  **It restores the 10-14 target honestly** instead of quietly
    abandoning it. 0.5.0 becomes 5 verbs plus substantial repair; 0.6.0
    lands the themed group at 10-13.
5.  **Risk is lower in both.** A correctness release is reviewable
    against a fixture table; a feature release on trusted primitives is
    reviewable against its specs. Merging them produces a release where
    a reviewer cannot tell which changed number is a fix and which is a
    bug.

**Cost of this recommendation:** the long-planned identity/place/access
theme slips one release, and §10’s audiences wait longer for the verbs
they asked for — none of which are urgent, since §10.3, §10.10 and
§10.14 showed the biggest wins there are documentation rather than code.
**If instead the theme must ship in 0.5.0**, then apply iteration-1’s
cut — drop `emoji_zwj_components()`, `emoji_diversity()`,
`emoji_render_check()` and `emoji_subdivision()` — and accept 15 verbs
plus six correctness items in one review.

------------------------------------------------------------------------

## 4. Feature specifications

### 4.1 Modifiers, identity and representation

``` r

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

- **`n_modifiable` is a returned column, not an internal.** Robertson et
  al.’s 42% is modified ÷ modifiable. Reporting modified ÷ all emoji is
  the single most likely misuse, and the API should make it hard to do
  by accident.
- **`default` is not “unknown”.** Choosing the yellow default is itself
  a choice readers interpret (*Black or White but Never Neutral*, CSCW
  2021). Name the level `default`, never `NA` or `none`, and say why in
  the help page.
- **Never infer identity.** The API describes *glyph usage*. Robertson
  et al. found many tone-modified uses depict other people. This belongs
  in each help page and in the vignette, not only in a footnote.
- **`modifiers = c("keep", "strip")` threaded through
  [`emoji_frequency()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_frequency.md),
  [`emoji_dfm()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_dfm.md)
  and
  [`emoji_pairs()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_pairs.md)**
  rather than forcing pre-processing. Default `keep`, because Barbieri &
  Camacho-Collados show modifiers change semantics — and because `keep`
  is today’s behaviour, so the default is not a silent break. Document
  loudly in NEWS.
- Reuse [emoji](https://emilhvitfeldt.github.io/emoji/)’s
  `emoji_modifiers` / `emoji_modifier_remove()`; write no codepoint
  arithmetic we do not have to. Still needs a fixture table for cases
  upstream may not cover: family combinations, kiss/couple with *mixed*
  tones, the ♀/♂ versus ZWJ gender forms, professions.
- **Orphan modifiers must have a defined fate (§1.2).** A tone modifier
  on a non-modifiable base is detected as its own emoji occurrence
  today, which corrupts the `n_modifiable` / `n_modified` ratio this
  group exists to get right. Surface them in `.emoji_n_orphan_modifiers`
  rather than dropping them.
- **`emoji_zwj_components()` decomposes RGI sequences only (§1.2).**
  Non-RGI ZWJ joins arrive as separate occurrences from the engine; say
  so in the help page so the verb does not look broken on
  hand-constructed test input.

**Effort** M (was L). **Risk** medium — reputational, not technical.

### 4.2 Geography: flags and countries

``` r

emoji_country(data, text)      # adds .emoji_iso2, .emoji_country_name
emoji_flag(x)                  # ISO-2 <-> flag emoji, vectorised, both ways
emoji_subdivision(data, text)  # tag sequences: the Scotland flag -> GB-SCT
```

Regional-indicator pairs map mechanically to ISO 3166-1 alpha-2: the
offset between an ASCII capital and its regional indicator is constant
(`A` = 65, `U+1F1E6` = 127462, difference 127397).

**The arithmetic is necessary but not sufficient — §1.2 disproved the
original “no external data is needed” claim.** `🇽🇽` is a well-formed RI
pair that the detector returns as an emoji and the arithmetic maps to
`"XX"`, a country that does not exist. So the verb needs the **valid
set** as well as the offset: §2.1 counted 259 `country-flag` and 3
`subdivision-flag` rows upstream, which is small enough to bundle.
Unmatched pairs return `NA` with the glyph preserved. A name lookup is
still needed and ISO-2 to name is small enough to inline.

Two things not to miss:

- **Subdivision tag sequences** are a different encoding — a base flag
  plus tag characters — and are easy to overlook. Handle them in the
  same verb family or document their absence explicitly.
- **Cross-package recipe, not a dependency.** Hand `.emoji_iso2` to
  `countrycode::countrycode()` or `countryatlas` and a corpus of flag
  emoji becomes a choropleth in two lines. Document the recipe; import
  nothing.

This is the clearest unfilled gap in the R ecosystem (§2.5). **Effort**
S-M. **Risk** low.

### 4.3 Accessibility — new in this roadmap

Screen readers announce each emoji’s Unicode name, so a run of six emoji
becomes six spoken names, and an emoji between two words interrupts the
sentence. The CHI 2020 and CSCW 2024 work above turned that into two
concrete interventions, and tidyEmoji already has the machinery for
both.

``` r

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

- `emoji_speak()` is `emoji_to_text(format = "name")` with a spacing
  rule and an honest name. It is worth having anyway, because “what will
  a screen reader say?” is the question users have, and `emoji_to_text`
  does not answer it in the help index.
- `emoji_a11y_check()` composes shipped verbs: longest emoji run from
  [`emoji_ngrams()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_ngrams.md),
  interrupting (non-final) emoji from
  [`emoji_position()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_position.md),
  density from
  [`emoji_ratio()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_ratio.md).
  **No new engine code.**
- **Follow PREVIEW, not ALERT, in framing.** The 2024 study found people
  preferred being shown the transcript over being told their message was
  inadequate. So `emoji_a11y_check()` reports *what a reader will
  encounter* and leaves the judgement to the user; thresholds are
  arguments, and their defaults are documented as conventions, not
  standards.
- This also gives the package a real answer to “why would I use
  [`emoji_to_text()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_to_text.md)?”
  beyond NLP preprocessing.

**Deps** none externally, **but §4.5 is a hard prerequisite** — see
§1.1. `emoji_a11y_check()`’s “interrupting emoji” count is derived from
[`emoji_position()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_position.md),
which is codepoint-based and misreports sentence-final flags and ZWJ
sequences as mid-sentence. Shipping the a11y verb on the current
primitive would put a wrong number in the one place users are least able
to check it. **Effort** S once §4.5 lands. **Risk** low. **Value** high
— no R package does this, the literature is clear, and the cost is a
weekend.

### 4.4 Unicode property surface

Now that `qualified`, `points`, `runes` and `nrunes` are **confirmed
present** upstream (§2.1), this shrinks to exposing what we join to:

``` r

emoji_properties(x)      # one row per glyph: qualification, modifiable,
                         # component, group/subgroup, version, codepoints
as_emoji_canonical(x)    # export the internal canonicaliser
```

`as_emoji_canonical()` has been on the backlog since 0.3.0 and is one
`@export` away: users doing their own joins hit exactly the
qualified/unqualified trap the package already solves internally.
**Effort** S.

### 4.5 The `{stringi}` grapheme engine — now a prerequisite, not an option

**Scope grew.** This was filed as retiring a documented
[`emoji_ratio()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_ratio.md)
caveat. §1.1 showed
[`emoji_position()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_position.md)
has the same defect *without* the documentation, and that §4.3 cannot be
built correctly on top of it. So this is no longer the optional item in
0.5.0 — it is the one that unblocks the accessibility group, and it must
land first or alongside.

Affected verbs:
[`emoji_ratio()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_ratio.md)
(documented),
[`emoji_position()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_position.md)
(§1.1, silent), and any other
[`nchar()`](https://rdrr.io/r/base/nchar.html)-on-user-text site the
audit turns up.

Resolve it as an opt-in engine rather than a permanent caveat:

- `Suggests: stringi`
- `engine = c("auto", "base", "stringi")` on the affected verbs
- `auto` uses [stringi](https://stringi.gagolewski.com/) when installed
  and base otherwise, and reports which it used rather than choosing
  silently

Two code paths and two sets of tests forever is the cost; a documented
limitation that never goes away is the alternative. **Effort** M.

### 4.6 The keyword and alias surface — newly cheap

§2.1 found `keywords` and `aliases` populated for all 5042 glyphs. Today
[`emoji_search()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_search.md)
matches on `name` only, so a user searching “happy” misses
`grinning face`, whose keywords include *happy* — the data to fix that
is already installed.

``` r

emoji_keywords(x)                    # long: one row per (glyph, keyword)
emoji_find(terms, match = c("any", "all"))   # keywords -> glyphs, vectorised

emoji_search(pattern, fields = c("name", "keywords", "aliases"))
#> widen the existing verb; default gains keywords, which changes results
```

**Design notes.**

- **This is a behaviour change to a shipped verb.** Widening
  [`emoji_search()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_search.md)’s
  default fields returns more matches than 0.4.0 did. Either default to
  `fields = "name"` and let users opt in, or widen and announce it
  loudly in NEWS. Prefer opt-in: silent recall changes are the kind of
  thing that breaks someone’s pinned test.
- `emoji_find()` is the inverse direction and is the one users actually
  ask for (“which emoji mean *celebration*?”). It is a grouped join, no
  new engine.
- **English only, and say so in the help page.** These keywords are the
  CLDR *English* set. Multilingual keywords remain behind the §7.2
  download decision; do not let this verb imply locale coverage it does
  not have.

**Deps** none beyond the pinned
[emoji](https://emilhvitfeldt.github.io/emoji/). **Effort** S. **Risk**
low, except for the default-fields decision above.

### 4.7 Presentation selectors — a documented limitation, now quantified

[`?emoji_sentiment_lexicon`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sentiment_lexicon.md)
already documents that text-presentation code points (the bare heart
`U+2764`, the white smiling face `U+263A`, the heavy check mark
`U+2714`) are not treated as emoji by the detector, and that this
affects detection only, never the join. §1.2 confirmed the behaviour.
**What no one had measured is how much of the lexicon it covers:**

> **270 of the 969 rows in `emoji_sentiment_lexicon` (28%) cannot be
> detected by `.emoji_locations()` at all.**

**The 28% was re-measured 2026-09-03 and the split is not what this
section said.** Of the 270, only **57** are RGI emoji in
text-presentation form; the other **213** are not in the RGI catalogue
at any qualification. The example list below originally mixed the two
buckets — `♡`, `★`, `♫`, `☆`, `♪` are in the *non-emoji* 213, not the
recoverable 57. The honest reading, corrected:

- **213 are not emoji and never were** — `█` box drawing, the
  replacement character `�`, `►`, `━`, `│`, and the dingbat
  hearts/stars/notes `♡ ★ ♫` — inherited from the tweets the lexicon was
  built from. These *should* be undetectable, and they are four fifths
  of the 270, so the 28% must never be quoted as lost emoji coverage.
- **57 are real emoji in text-presentation form** —
  `❤ ♥ ☺ ☯ ☀ ❄ ✈ ✔ ➡ ✖ ▪`. These are genuinely missed, and the bare
  `U+2764` in particular is common in the wild because several keyboards
  emit it without `U+FE0F`.

**The catalogue-wide figure is the better headline**, because it does
not depend on one lexicon’s provenance: of the 5042 RGI emoji, **1252
carry `U+FE0F`, and 216 of those become undetectable if it is dropped.**
That is the number the help page now states.

**One caution the `presentation = "any"` design must handle.** `©`, `®`
and `™` are inside the recoverable set — they are RGI emoji as `©️`,
`®️`, `™️`. Matching them unqualified would count the copyright sign in
a legal footer as emoji use, which is a worse error than the one being
fixed. Whatever the opt-in looks like, those three (and anything else
whose bare form is ordinary punctuation) need excluding, or the argument
needs a third level.

**Proposal — make it an argument, not a footnote.**

``` r

emoji_summary(data, text, presentation = c("emoji", "any"))
#> "emoji" (default, today's behaviour): require emoji presentation
#> "any": also match unqualified / text-presentation code points that are
#>        RGI emoji, using the `qualified` column verified in §2.1
```

`qualified` makes this newly cheap: `minimally-qualified` and
`unqualified` rows are exactly the set to opt into, and `component` rows
are exactly the set to keep excluding (which also gives §1.2’s
orphan-modifier problem a principled answer). **Do not change the
default** — it would alter every existing user’s counts. Ship it as
opt-in, and report the count of skipped-but-scorable glyphs so a user
can see what the choice costs them; that number is the natural headline
for §10.7’s `emoji_coverage()`.

**Effort** S-M. **Risk** low if opt-in, high if the default changes.
**Note the dependency:** this is the same “expose what upstream already
knows” pattern as §4.4, and the two should be implemented together.

### 4.8 Zero-inflation and compositional structure — a statistical duty

*New in this round, and it cuts across every section of §10 rather than
serving one audience. It is the only item here that is about the
**validity** of what users do with our output rather than about what we
compute.*

Emoji count data has two properties the statistical literature treats as
hazards, and tidyEmoji hands users both without comment.

**It is compositional.**
[`emoji_frequency()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_frequency.md)
proportions and
[`emoji_dfm()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_dfm.md)
rows are shares of a total, so they are constrained to a simplex: the
components are not independent, and raising one necessarily lowers the
others. Ordinary regression on such proportions is a known error, and
compositional data analysis (CoDA) exists to handle it.

**It is heavily zero-inflated.** A document-by-emoji matrix is mostly
zeros — §1.7 sharpens why: any given corpus uses a tiny fraction of 5042
glyphs. The CoDA literature’s central practical problem is exactly this,
because the log-ratio transforms it depends on are undefined at zero,
and the discreteness of counts violates their continuity assumptions.

**The good news: the package’s instincts are already right.** The
“denominator discipline” §4.1 insists on for skin tone, and
`.emoji_n_scored` alongside every score, are precisely the CoDA-safe
pattern — **return counts and their denominator, never a bare
proportion.** Generalise that into a stated principle rather than a
per-verb habit:

> Every rate tidyEmoji returns ships with the numerator and denominator
> it was computed from, so a user can fit a count model instead of a
> linear model on a ratio.

Audit
[`emoji_ratio()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_ratio.md),
[`emoji_density()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_density.md)
and
[`emoji_frequency()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_frequency.md)
against it; `.emoji_per_char` / `.emoji_per_token` should be accompanied
by the character and token counts, not just the quotient.

**And the genuinely novel part — tidyEmoji can distinguish structural
zeros from count zeros, and almost nothing else can.** CoDA separates
*structural* zeros (the component genuinely cannot occur) from *count*
zeros (it could occur but was not observed), and warns that conflating
them biases everything downstream. In emoji time series the distinction
is not a modelling assumption — **it is a matter of record**:

> A zero for 🫠 in 2019 is a **structural** zero. Melting face did not
> exist until Emoji 14.0 (2021). A zero for 😀 in 2019 is a **count**
> zero.

[`emoji_unicode_releases()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_unicode_releases.md)
already carries the release dates and
[`emoji_version_profile()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_version_profile.md)
already knows each glyph’s version, so the package has everything needed
to label this — and
[`emoji_adoption_lag()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_adoption_lag.md)
is already doing adjacent arithmetic.

``` r

emoji_trend(data, text, time, zeros = c("observed", "structural"))
#> "structural" adds .emoji_available (logical): was this glyph even
#>   encodable at this timestamp?

emoji_dfm(data, text, doc_id, mark_unavailable = FALSE)
#> optionally NA rather than 0 for glyph-period cells that could not occur
```

**Why this matters more than it sounds.** Every adoption-curve, turnover
and diachronic-drift analysis in the roadmap (§9’s wave 5,
[`emoji_turnover()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_turnover.md),
[`emoji_seasonality()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_seasonality.md))
is fitted over a window that spans Unicode releases. Left alone, a new
glyph’s pre-release zeros are read as evidence of non-use, which
flattens the very adoption curve the analysis is measuring. This is a
*silent inferential error in work the package already enables today*.

**Deps** none — the data is bundled. **Effort** M (the labelling is
small; the tests and the vignette section are the work). **Risk** low.
**Value** high and unusual: it is a correctness contribution to users’
statistics rather than a feature, and no other emoji tooling is
positioned to offer it.

------------------------------------------------------------------------

## 5. Explicitly not in 0.5.0

Keeping this list honest is what stopped 0.4.0 from sprawling.

- **Text sentiment scoring** — defer to
  [tidytext](https://juliasilge.github.io/tidytext/) /
  [sentimentr](https://github.com/trinker/sentimentr) / `{vader}`
  permanently.
  [`emoji_incongruity()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_incongruity.md)’s
  `text_score` contract is the position.
- **A rendering engine** — [ragg](https://ragg.r-lib.org) solved it
  (§2.3).
- **`emoji_image()` / twemoji downloads** — deflated by §2.3; the
  download infrastructure is no longer worth building for this.
- **Pretrained embeddings** — `emoji_embed_corpus()` (PPMI +
  [`base::svd`](https://rdrr.io/r/base/svd.html)) first, in a later
  release; pretrained is a maintenance tail.
- **CLDR *multilingual* names** — needs the download-and-cache helper,
  the single biggest piece of infrastructure left. Decide it once
  (§7.2), then do CLDR, embeddings and any image set together or not at
  all. **Note the narrowing:** §2.1 found the CLDR *English* keywords
  already bundled, so the English half of this is in scope now as §4.6.
  Only other locales are blocked.
- **`emoji_vendor_support()`** — newly moved here. §2.1 verified that
  all eight `vendor_*` columns in
  [emoji](https://emilhvitfeldt.github.io/emoji/) are empty (`TRUE = 0`
  for every one), so the data this feature assumed does not exist
  upstream. Building it means sourcing and maintaining vendor-support
  data ourselves, which is a licence and freshness tail, not a verb.
  Revisit only if upstream populates the columns.
- **Any bundled clinical or risk glyph set** — the mechanism
  (`emoji_flag_set()` / `emoji_set_register()`) is fine and cheap; the
  data is not ours to ship.
- **Emoji generation or recommendation** — out of scope permanently.

------------------------------------------------------------------------

## 6. Design decisions to lock before coding

1.  **Minimum [emoji](https://emilhvitfeldt.github.io/emoji/) version.**
    Reading `qualified` or `emoji_modifiers` makes us version-dependent.
    Pin it in DESCRIPTION and add a test that fails loudly if the
    columns are absent, rather than producing `NA` silently.
2.  **`modifiers = "keep"` as the default** everywhere it is threaded,
    with `"strip"` opt-in. Changing existing users’ counts is worse than
    a slightly awkward default.
3.  **Tone levels are a fixed vocabulary**, lower-case snake: `default`,
    `light`, `medium_light`, `medium`, `medium_dark`, `dark`. Never `NA`
    for default.
4.  **`emoji_a11y_check()` thresholds are arguments with documented
    defaults**, never presented as a standard the user is failing.
5.  **Flags return ISO-2, not names, as the join key.** Names are a
    display convenience; the code is what other packages take.
6.  **Group support**: `emoji_tone_summary(group_by =)` is a per-verb
    argument, not the grouped-df fix. Do not let 0.5.0 half-solve the
    1.0 promise.

------------------------------------------------------------------------

## 7. Risks and open questions

1.  **Upstream coupling.** Everything in §2.1 is a bet on
    [emoji](https://emilhvitfeldt.github.io/emoji/)’s data shape. The
    shape is now **verified** against `emoji` 16.0.0 (2026-08-30), so
    the risk is drift, not ignorance. Mitigation unchanged and now
    overdue: pin the version, add a test per column we read
    (`qualified`, `keywords`, `aliases`, `emoji_modifiers`) that fails
    loudly rather than yielding `NA`, and keep `emoji_key()` as the only
    join path so a shape change breaks in one place. Note that upstream
    tracks Unicode **16.0**, so our ceiling is theirs.
2.  **The download helper — build it once, or not at all.** CLDR (§5),
    pretrained embeddings and any image set all need the same machinery:
    a cache under
    [`tools::R_user_dir()`](https://rdrr.io/r/tools/userdir.html), a
    version stamp, an offline test mode, clear failure messages, and
    nothing fetched at build or check time. Either write it once as
    infrastructure or drop all three. Do not write it three times.
3.  **Sensitive framing.** The modifier work is the one place this
    package can do harm. Every verb in §4.1 needs the “describes glyph
    usage, never infers identity” statement on its own help page — help
    pages are what people read.
4.  **Test surface.** 0.5.0’s fixtures are the hard part: mixed-tone
    multi-person sequences, ♀/♂ versus ZWJ gender forms, subdivision tag
    sequences, professions. Budget as much time for the fixture table as
    for the code.
5.  **Unicode churn.** Emoji 17.0 is out and 18.0 will follow. The
    refresh must be a checklist item (§8), not a habit.
6.  **`{text2emotion}` overlap** — read it before writing docs, and
    state plainly where the packages differ. **(verify)**
7.  **§10 is a catalogue, not a plan.** The audience section exists so
    ideas stop being rediscovered, and it is deliberately larger than
    any one release. The failure mode is treating it as a backlog to
    burn down: 0.5.0’s cap is 13 verbs (§3), and §10’s only
    0.5.0-eligible item is the S-sized `emoji_identical()` in §10.1.
    Everything else is scheduled in §9 or later.
8.  **Forensic misuse (§10.1) is the sharpest new misuse risk.** A user
    who reads “emoji forensics” support as “tidyEmoji can tell me what
    the sender saw” will be wrong, and may be wrong in a legal filing.
    We have codepoints and Unicode versions; we have **no**
    vendor-rendering data (§2.1 verified the `vendor_*` columns empty).
    Every verb in that group states the limit on its own help page, in
    the same discipline §4.1 applies to identity.
9.  **Unicode normalisation is *not* a risk — checked, so nobody checks
    again.** A plausible worry is that NFC/NFD/NFKC normalisation of
    user text could split or recombine emoji sequences and break the
    codepoint join. Tested on tone sequences, ZWJ families, `U+FE0F`
    hearts, flags and keycaps: all five are **invariant** under all
    three normalisation forms, and detection counts are unchanged. Emoji
    code points have no canonical decompositions, so this is a property
    of Unicode rather than luck. Recorded here to close the question.
10. **Two permanent non-goals now have written reasons** (§10.3
    mental-health instruments, §10.4 a bundled hate-emoji codebook).
    Both are the kind of thing a well-meaning contributor proposes; the
    reasons are recorded so the answer does not have to be re-derived
    under time pressure.

------------------------------------------------------------------------

## 8. Quality bar for the release

Carried-forward debts to pay *during* 0.5.0 rather than defer again:

**Refresh `data-raw/` against the current
[emoji](https://emilhvitfeldt.github.io/emoji/)** and record the Unicode
version in NEWS. Make this the first item of every release checklist.

**{covr} coverage job + badge**, and `urlchecker` + `spelling` as
scheduled workflows. Promised since 0.2.0. 0.4.0 deferred it because a
red job is worse than a missing one — which is an argument for
configuring it properly, not for skipping it a fourth time.

**Baseline measured 2026-08-30** (below). Still to do: commit it as
`data-raw/benchmark.R` so it runs release over release. The debt’s guess
about which verbs are hot is **confirmed**.

Elapsed seconds, synthetic corpus, 0-3 emoji per row, R 4.4.1:

| Verb | 1k | 10k | 50k | linear est. 1M |
|----|----|----|----|----|
| [`emoji_summary()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_summary.md) | 0.02 | 0.13 | 0.68 | ~14 s |
| [`emoji_frequency()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_frequency.md) | 0.09 | 0.16 | 0.67 | ~13 s |
| [`emoji_position()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_position.md) | 0.02 | 0.20 | 0.92 | ~18 s |
| [`emoji_sentiment()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sentiment.md) | 0.03 | 0.29 | 1.43 | ~29 s |
| [`emoji_dfm()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_dfm.md) | 0.11 | 0.96 | 4.75 | ~95 s |
| [`emoji_context()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_context.md) | 0.14 | 1.24 | 6.50 | ~130 s |
| [`emoji_collocations()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_collocations.md) | 0.23 | 1.95 | 10.34 | **~207 s** |

**Three readings.** (1) **Scaling is linear, not quadratic** — 50x the
rows costs 30-45x the time across every verb, so there is no algorithmic
landmine waiting at scale; this is the most important thing the numbers
say. (2) The §8 debt correctly guessed the hot paths:
[`emoji_collocations()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_collocations.md)
and
[`emoji_context()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_context.md)
cost **10-15x**
[`emoji_summary()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_summary.md),
and they are the only two where a million rows means minutes rather than
seconds. (3) The millions-of-rows target is therefore *met* for the
detect/count/score core and *marginal* for the context pair — 3.5
minutes for
[`emoji_collocations()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_collocations.md)
on 1M rows is usable but is the obvious optimisation target, and it
should be the first thing a performance backend (§9’s 1.0.0 row)
touches.

Caveat: synthetic text with a short word pool understates
[`emoji_context()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_context.md)/[`emoji_collocations()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_collocations.md),
whose work scales with vocabulary as well as row count. Treat these as a
floor and re-measure on real corpora before quoting them.

**Snapshot tests** (`expect_snapshot()`) over printed output, to catch
silent column and ordering changes cheaply.

**An “emoji networks” vignette** built on
[`emoji_pairs()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_pairs.md)
(ggraph / tidygraph in Suggests) — the data source has existed since
0.3.0.

**Re-run `devtools::document()` from a real R install** and commit any
difference. 0.4.0’s help pages were generated by a stand-in converter
because no R was available in the authoring environment; they pass
`R CMD check` on five platforms, but roxygen2 is the source of truth.

------------------------------------------------------------------------

## 9. Release ledger

*Running list of every work package, in the order it entered the
roadmap. **For release scheduling, §3.1 is authoritative** — this table
records what exists and where it came from; §3.1 records what ships
when.*

| Work package | State | Where |
|----|----|----|
| 0.2.1 correctness patch | ✅ shipped | folded into package 0.3.0 |
| 0.3.0 affect & translation | ✅ shipped | package 0.3.0 |
| “0.4.0 phase” relational & structure | ✅ shipped | folded into package 0.3.0 |
| `features.md` wave 1 — risk, context, time, mismatch, type, LLM, provenance | ✅ shipped | **package 0.4.0** |
| **Correctness & honesty** (§3.1 — *recommended* 0.5.0) | ⏳ **next** | the six §1 items + §4.4/§4.6 + `emoji_coverage()` |
| **Identity, place & access** (§4.1-§4.3) | ⏳ | **recommended 0.6.0**, on repaired primitives (§3.1) |
| Affect breadth & coverage honesty (wave 3) | ⏳ | blocked on the batched licence review |
| Semantics — `emoji_embed_corpus()`, similarity, clustering (wave 4) | ⏳ | after the download decision (§7.2) |
| Locale / CLDR, pragmatics, drift (wave 5) | ⏳ | after the download decision (§7.2) |
| **Tally input** — `emoji_from_counts()` / `weights =` (§10.2) | ⏳ **0.6.0** (§3.1) | doubles the input surface; no new domain logic |
| **Evidentiary surface** — `emoji_identical()` (§10.1) | ⏳ **0.5.0** (§3.1) | S-sized; rides §4.4’s properties work |
| **Coverage honesty** — `emoji_coverage()` (§10.7, §1.7) | ⏳ **promoted to 0.5.0** | emotion lexicon covers 3% of RGI; users see only a quiet `NA` |
| **Column-order alignment** [`emoji_score()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_score.md)/specific scorers (§1.8) | ⏳ **1.0.0** | user-visible; ride the API freeze |
| **[`emoji_position()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_position.md) grapheme fix** (§1.1) | ⏳ **0.5.0, blocking** | prerequisite for §4.3; ship with §4.5 |
| **Distinctiveness** — `emoji_distinctive()` (§10.8) | ⏳ | wave 3; serves §10.8, §10.9 and the marketing literature |
| **Flag validation** — bundle the 259+3 valid set (§1.2) | ⏳ **0.5.0** | §4.2 is wrong without it |
| **Orphan-modifier accounting** (§1.2) | ⏳ **0.5.0** | §4.1’s ratio is wrong without it |
| **`presentation = "any"`** opt-in (§4.7) | ⏳ **0.5.0** (§3.1) | ships with §4.4; 270 lexicon rows currently unreachable |
| **`register_emoji_types()`** (§10.11) | ⏳ | wave 3; one mechanism serves §2.4, §10.11, §10.12 |
| **Round-trip regression tests** (§1.3) | ⏳ **0.5.0** | 7 cases; written and verified in §12.1 — ready to commit |
| **Commit `test-regression-0.5.0.R`** (§12) | ⏳ **0.5.0** | Part A green now; Part B is the correctness spec |
| **Reversible-LLM-preprocessing vignette** (§1.3) | ⏳ | highest-value undocumented capability found |
| **Commit `data-raw/benchmark.R`** (§8) | ⏳ | baseline now measured; needs to be repeatable |
| **`emoji_sample()`** stratified stimulus draw (§10.13) | ⏳ **0.6.0** (§3.1) | S-sized; serves §10.6, §10.10, §10.13 and our own fixtures |
| **Locale-matrix CI job** (§1.4) | ⏳ | must vary only `LC_COLLATE` — see the trap in §1.4 |
| **Grouped-input guard on 3 aggregators** (§1.5) | ⏳ **0.5.0** | [`emoji_categorize()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_categorize.md), [`emoji_version_profile()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_version_profile.md), [`emoji_ngrams()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_ngrams.md) pool silently |
| **`time`/`var` error-message leak** (§1.5) | ⏳ **0.5.0** | XS; 4 time verbs name an internal argument |
| **Document `.emoji_*` as reserved** (§1.6) | ⏳ | one sentence; user columns are silently overwritten |
| **Rate/denominator audit + stated principle** (§4.8) | ⏳ **0.5.0** | cheap; makes existing output CoDA-safe |
| **Structural vs count zeros** — `zeros=`, `.emoji_available` (§4.8) | ⏳ **0.6.0** | fixes a silent inferential error in adoption curves |
| **Research-question index + `\concept{}` tags** (§10.14) | ⏳ | fixes the discoverability pattern behind §10.3, §10.10, §10.14 |
| **Policy reversibility table in [`?emoji_sanitize`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sanitize.md)** (§1.9) | ⏳ **0.5.0** | five options are a loss ladder, not parallel choices |
| **One real `text_score` recipe, `eval = FALSE`** (§10.15) | ⏳ **0.5.0** | §5’s composability promise is currently half-kept |
| **Emoji scales** — `emoji_scale()` / `as_emoji_ordinal()` (§10.6) | ⏳ | wave 5+, build with §10.2’s tally work |
| Documentation-only debts from §10.3 / §10.4 / §10.5 / §10.8 / §10.9 / §10.10 | ⏳ | help-page + vignette wording; no code. §10.10 is XS and unblocks a whole literature |
| 1.0.0 — grouped-df guarantees, performance, API freeze | ⏳ | one full cycle with *no* new verbs |

**Version numbering.** CRAN’s published version is **0.3.0, published
2026-08-04** (verified against the CRAN package page on 2026-08-30). The
repo is at 0.4.0, which is complete but **not yet submitted** — so 0.4.0
is the next CRAN submission, and 0.5.0 (this document) is the next thing
to build. Phase names in older documents refer to work packages, not
package versions; note in particular that the “0.4.0” in commits from
2026-07-01 is a *different*, abandoned 0.4.0 — `DESCRIPTION` briefly
carried it for 22 minutes before `c85be8c` reverted it, and that work
shipped as 0.3.0 instead.

**The three audits, and the pattern in them.** Each release has found
its own crop of defects in the code written just before it, and they
rhyme:

- **0.2.1** — key-normalisation asymmetry: one join path was normalised,
  the others were not.
- **0.3.0** — locale-dependent shortcode choice; a dead `wrap` argument;
  regex injection in
  [`emoji_search()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_search.md).
- **0.4.0** — locale-dependent document ordering in
  [`emoji_dfm()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_dfm.md),
  *the same bug class as 0.3.0’s in a different axis*, plus nine
  arguments that absorbed invalid values instead of rejecting them.

The lesson to carry into 0.5.0: **the bug is rarely unique to the verb
it was found in. When one turns up, grep the package for its shape
before fixing just the one.** That is how 0.4.0 turned three reported
gaps into nine fixed ones.

------------------------------------------------------------------------

## 10. Audience expansion — who else analyses emoji corpora

*New in this round. Every verb tidyEmoji ships assumes one input shape:
a text column of naturalistic prose, usually social media. That shape
came from the literatures §2.4 surveys. This section asks the other
question the roadmap has never asked — **who else already works with
emoji data, and does our input shape fit them?** **Fifteen**
communities, surveyed 2026-08-30/31, roughly in descending order of what
they would cost us. **Seven** would produce a verb (§10.1, §10.2, §10.6,
§10.7, §10.8, §10.11, §10.13); **six** need documentation or an existing
mechanism advertised rather than new code (§10.3, §10.5, §10.9, §10.10,
§10.14, §10.15); **one** only sharpens a plan already made (§10.4); and
**one** is a watch-list entry (§10.12). Two permanent non-goals are
recorded with their reasons inside §10.3 and §10.4.*

| \# | Community | What they need | Verdict |
|----|----|----|----|
| 10.1 | Legal / eDiscovery / forensic linguistics | Codepoint-exact identity and an audit trail | **Build** — small, and we are 80% there |
| 10.2 | Software-engineering research | Reaction *tallies*, not text | **Build** — the one real input-shape gap |
| 10.3 | Mental health / crisis informatics | Features without a diagnosis claim | Document + refuse the lexicon |
| 10.4 | Content moderation / algospeak | Structural anomalies, not a codebook | Sharpens an existing plan |
| 10.5 | Cross-cultural / locale research | Interpretation variance by locale | Blocked on §7.2; reframe now |
| 10.6 | Survey methodology / psychometrics | Emoji-anchored ordinal scales | Real audience, later wave |
| 10.7 | Corpus annotation methodology | Agreement stats and coverage honesty | Recipe, not a verb |
| 10.8 | Authorship attribution / stylometry | Per-author distinctiveness, addressee conditioning | Recipe + one small verb |
| 10.9 | Finance / market sentiment | Domain lexicons and tally input | No verb — but the best argument for the lexicon API |
| 10.10 | Education / L2 acquisition | Stimulus sets by semantic field | Already served; a discoverability failure |
| 10.11 | Political communication | Function-typed emoji use, not valence | Needs [`emoji_type()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_type.md) extension, not a new verb |
| 10.12 | AAC and assistive communication | Emoji as visual prosody | Watch — literature too thin to build on |
| 10.13 | Multimodal / VLM evaluation | Emoji as a *stimulus set*, not a feature | Build the sampler — S, and nothing else offers it |
| 10.14 | Crisis / disaster communication | Face-vs-object split; solidarity over time | Already served — third discoverability case |
| 10.15 | Workplace / organizational | Text-valence x emoji-valence **interaction** | Makes §5’s composability promise urgent |

### 10.1 Legal, eDiscovery and forensic linguistics — **build**

Emoji litigation is growing and diversifying: contract formation (a
thumbs-up answering “are you prepared to buy?”), employment disputes,
criminal matters and IP. “Emoji forensics” is now a named subfield
(Danesi 2021), and courts are grappling with *variation* — the same
nominal emoji rendering differently across platforms is itself the
evidentiary problem (Nature HSSC 2022).

**Why this fits tidyEmoji specifically.** This community’s need is the
exact inverse of NLP’s. NLP wants glyphs normalised away; forensics
wants them pinned down: which codepoints exactly, with or without
`U+FE0F`, which Unicode version introduced it, could this glyph have
rendered differently on the sender’s device. tidyEmoji already has
[`emoji_provenance()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_provenance.md),
[`emoji_unicode_version()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_unicode_version.md),
the `U+FE0F`-stripped join key and `emoji_properties()` (§4.4). What is
missing is the *comparison* verb and the honest negative answer:

``` r

emoji_identical(x, y)      # do these two glyph occurrences share codepoints
                           # exactly? and if not, how do they differ?
emoji_codepoints(x)        # already implied by emoji_properties(); make the
                           # evidentiary use explicit in the help page
```

**And the disclaimer is part of the feature.** We can report what
codepoints a message contains and which Unicode version defines them. We
cannot report what the sender saw — that depends on their font and
platform, and the `vendor_*` columns are empty (§2.1), so tidyEmoji has
*no* vendor-rendering data. Say this plainly in the help page; a
forensic user who assumes otherwise is the worst failure mode this
package has.

**Effort** S. **Risk** low technically, but the help-page wording is the
deliverable as much as the code.

### 10.2 Software-engineering research — **build (the input-shape gap)**

The best-developed emoji literature we do not serve. Lu & Cao mined 66
months of GitHub; “More than React” analysed **365,811 pull requests
across 1,850 repositories** and found reaction counts correlate with
review time and that first-time contributors receive fewer reactions;
“Emotional Contagion in Code” (2025) analysed **106,743 reactions** over
2,098 issues, reporting 57.4% positive sentiment and positive cascades
outnumbering negative 23:1.

**The gap is structural, not thematic.** GitHub reaction data is not
text. It arrives as *(item, glyph, count)* — a tally. Every tidyEmoji
verb takes a text column and derives counts by extraction. A researcher
holding `(pr_id, "👍", 12)` cannot use
[`emoji_sentiment()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sentiment.md),
[`emoji_frequency()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_frequency.md)
or
[`emoji_dfm()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_dfm.md)
at all without fabricating synthetic strings, which is what they
currently do.

``` r

emoji_from_counts(data, emoji, n, id = NULL)
#> pivot a tally into the internal long form the scoring verbs consume,
#> so emoji_sentiment() / emoji_emotion() / emoji_dfm() work on reaction data

# equivalently: a `weights =` argument on the scoring verbs
```

This is the single highest-leverage item in this section: it does not
add a domain feature, it **doubles the input surface of the whole
package** — every existing scoring and summarising verb becomes
available to tally data, which covers GitHub/GitLab reactions, Slack
reacjis, poll results and any pre-aggregated corpus. It also composes
with §10.6.

**Effort** M — the work is in the internals (the long-form contract)
plus tests that a tally and its expanded text give identical scores.
**Risk** low. **Recommend for 0.6.0** and do not squeeze it into 0.5.0’s
13.

### 10.3 Mental health and crisis informatics — document, and refuse the lexicon

Real and active: **SuicidEmoji** (SIGIR 2024) derives a 25k-post emoji
dataset (2,329 suicide-related, 22,722 control) from ~1.3M Reddit posts;
depression detection work reports distinct emoji profiles (depressed
users favouring 😔 / 😢 / 💔, controls 😂 / 😊 / 😎) and BERT-family
models trained on emoji features.

**Position — unchanged and now written down.** Continue to ship **no
clinical instrument and no bundled risk-glyph lexicon.** The reasons are
that the mapping is population- and platform-specific, that a bundled
list invites use as a screening tool, and that a false negative here is
a different category of harm from a mis-scored tweet.

What we *should* do costs nothing: the
[`register_emoji_lexicon()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/register_emoji_lexicon.md)
mechanism already lets a research group load its own validated lexicon,
and §4.6’s keyword surface plus `emoji_frequency(group_by =)` already
produce the group-contrast profile these papers compute by hand. **Add a
vignette section naming this use case, the mechanism, and the refusal**
— researchers currently cannot tell from the docs that the package
supports them.

### 10.4 Content moderation and algospeak — sharpens the existing plan

Emoji are a documented content-moderation evasion channel. Meta’s
Oversight Board has taken cases specifically on emoji-encoded racial
targeting; CyberWell documents antisemitic emoji codes (🧃, 🐷, 🐀, 🐒
with code words) whose meaning is **language-specific** — the 🐒 pattern
appears in Arabic-language posts via a different route than in English.
“The Hidden Language of Harm” (2025) surveys the moderation problem
directly.

**This confirms the design rule the roadmap already chose** for
`emoji_obfuscation_scan()`: report *structural* anomalies — unusual
runs, substitution patterns, glyph-for-word positions — and **never ship
the codebook.** A bundled dictionary of hate-emoji patterns would be
stale in months, wrong across languages, and a ready-made evasion
checklist. The literature’s own recommendation (regionally appropriate,
continuously updated training data) is an argument for *not* freezing a
list into a CRAN package.

No change to scope; add the citation and the rule to the eventual help
page.

### 10.5 Cross-cultural and locale research — reframe now, build after §7.2

Interpretation varies by culture in ways that are documented and large:
a Malaysian study across Malay, Chinese and Indian participants found
shared *and* culture-specific readings of the same glyph;
Eastern/Western comparisons find collectivist users deploying emoji to
preserve social harmony where US/UK users deploy them for
self-expression; the thumbs-up is positive in much of the West and
offensive in parts of the Middle East. Comprehension also varies by age
and gender within a single language.

**The honest consequence is a documentation change available today, not
a verb.** tidyEmoji reports *usage*, and its bundled lexicons are
English-annotated. Every affect verb therefore carries an unstated
locale assumption. State it: the sentiment and emotion lexicons were
annotated by particular populations, and scores are not culture-neutral.
This is the same discipline §4.1 applies to skin tone, extended to
affect — and it costs a paragraph per help page.

The verb version (`emoji_interpretation_variance()`, or locale-aware
names) is blocked on the multilingual CLDR fetch (§7.2) and belongs with
wave 5.

### 10.6 Survey methodology and psychometrics — a genuinely new audience

Emoji are used as **scale anchors** in survey instruments, and the
psychometric literature has tested whether that works. Phan et
al. (2019) anchored vocational interest scales with emoji; İlhan et
al. (2022) compared emoji-labelled and verbally-labelled Likert
categories. Findings are mixed and that is the useful part:
emoji-anchored scales sometimes match verbal ones and sometimes are
*less* reliable, so instrument designers need to check rather than
assume.

This community holds ordinal data keyed by glyph — structurally the same
tally shape as §10.2, which is why the two should be built together.

``` r

emoji_scale(x, levels = NULL)   # declare an ordered emoji scale
as_emoji_ordinal(x, scale)      # glyph -> ordered factor, with unmapped
                                # glyphs surfaced rather than dropped
```

Small, and it opens a discipline that currently has no R tooling for
this at all. **Wave 5 or later**, bundled with §10.2’s tally work. Ship
no validated instrument — the same rule as §10.3.

### 10.7 Corpus annotation methodology — a recipe, and a debt we already owe

When researchers hand-annotate emoji meaning they need inter-annotator
agreement, and the measure has to match the task: Krippendorff’s alpha
for arbitrary rater counts and mixed measurement levels, Fleiss’ kappa
for fixed panels, with recent guidance (2026) stressing that the metric
must match the rater design and that uncertainty should be reported.

**Not our verb** — [irr](https://www.r-project.org) and
[DescTools](https://andrisignorell.github.io/DescTools/) do this well
and generally.

**But there is a tidyEmoji-shaped piece of it,** and it is already on
the ledger as “wave 3 coverage honesty”. Our bundled lexicons carry
annotation counts; 0.4.0 shipped `emoji_sentiment(se = TRUE)` off the
back of them. The natural extension is to make *coverage* as visible as
score: `.emoji_n_scored` exists, but a corpus-level “what fraction of
your emoji occurrences could any bundled lexicon score, and with what
annotation depth?” summary would let a paper report its own measurement
limits. That is one verb (`emoji_coverage()`) and it belongs with wave
3.

### 10.8 Authorship attribution and forensic stylometry — recipe plus one verb

Adjacent to §10.1 but a distinct task: not “what does this glyph mean?”
but “who wrote this?”. Researchers have attempted attribution of chat
messages **from emoji and emoticon use alone**, and find them useful,
individuating markers of authorship — emoji are part of an idiolect
(Frontiers in Communication 2022). Forensic stylometry reviews now list
emoji among idiosyncratic features, and microblog attribution work
treats them as first-class signal precisely because tweets are too short
for syntactic features to work.

**The methodological caveat is the interesting part, and it is a trap.**
The same work finds emoji use is subject to **accommodation** — authors
adjust their emoji choices to their addressee. So a per-author emoji
profile pooled across conversations mixes the author’s style with their
audience’s influence, and attribution built on the pooled profile will
be optimistic. Any credible analysis conditions on addressee or
conversation.

**What tidyEmoji already gives them:**
`emoji_frequency(group_by = author)` and `emoji_dfm(doc_id = author)`
produce the author-by-emoji matrix directly.

**What is missing is distinctiveness.** Raw frequency identifies the
corpus’s common emoji, not the author’s characteristic ones. The measure
wanted is TF-IDF-shaped — emoji over-represented in one author relative
to the corpus baseline — and
[`emoji_dfm()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_dfm.md)
already returns the matrix it needs:

``` r

emoji_distinctive(data, text, group, measure = c("tfidf", "log_odds", "keyness"))
#> per group: which emoji are characteristic, not merely frequent
```

This generalises well beyond authorship — the same verb answers “which
emoji distinguish these subreddits / these brands / these age cohorts”,
which is a question §2.4’s marketing literature and §10.9 both ask.
**Effort** S-M (it is arithmetic over an existing matrix). **Risk** low.
Schedule with wave 3.

**Documentation duty:** state the accommodation finding in the help
page. A user computing author profiles needs to know that pooling across
addressees biases the result, and the package is where they will look.

### 10.9 Finance and market sentiment — the case for the lexicon API

Emoji are a tracked signal in retail-investor research. Work on emoji
and stock returns finds emoji positively related to returns when heavily
discussed on Reddit boards, with price surges co-occurring with rocket
and fire emoji inside the same hour; sentiment tooling and trading
systems now track emoji frequency and density specifically.

**This is the sharpest illustration of a limit the package should state
loudly.** In r/wallstreetbets, 🚀 is a *directional bet* (“to the
moon”), 🐻 is a position rather than an animal, and 💎🙌 means holding
through a drawdown. The bundled Emoji Sentiment Ranking scores none of
these that way — it was annotated on general social media, so it will
score 🚀 as mildly positive and miss the entire semantic content. A
finance researcher who calls
[`emoji_sentiment()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sentiment.md)
on board data gets a number that looks fine and means nothing.

**The right response is not a finance lexicon** — it would be a
maintenance and licence tail, and the vocabulary shifts faster than CRAN
releases. It is:

1.  **[`register_emoji_lexicon()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/register_emoji_lexicon.md)
    is the answer, and should be advertised as such.** This community is
    the clearest use case the mechanism has, and the docs currently do
    not name a single one.
2.  **Say that bundled lexicons are domain-bound** on every affect
    verb’s help page — the same discipline §10.5 asks for regarding
    locale, applied to register. `.emoji_n_scored` already exposes how
    much of a corpus a lexicon could touch; §10.7’s `emoji_coverage()`
    would make it a headline number.
3.  **They also need §10.2’s tally input.** Board-level emoji counts
    arrive pre-aggregated, which is another independent constituency
    asking for `emoji_from_counts()` — that verb is requested by
    **four** sections (§10.2, §10.6, §10.9, §10.15), tallied in §2.6.

**No new verb.** A vignette section, two help-page paragraphs, and one
more vote for the tally work.

### 10.10 Education and L2 acquisition — already served, badly advertised

An active 2024-2026 literature. Experimental work finds a processing
advantage for emoji in **L2 vocabulary recognition** under semantic
congruency (Frontiers in Psychology 2025); Cambridge has a volume on
emoji literacy as a teaching tool; EFL studies test emoji feedback on
learner outcomes.

**tidyEmoji already ships what this community needs, under names that
hide it.** Their core measure is emoji-word *semantic congruency* — and
[`emoji_congruence()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_congruence.md)
shipped in 0.4.0. It was designed for irony and incongruity detection,
and its help page frames it that way, so a researcher designing a
vocabulary-matching experiment will never find it. Similarly, §4.6’s
`emoji_find()` is exactly the tool for assembling a stimulus set by
semantic field (“give me all emoji whose keywords include *animal*”),
which is how these studies build their materials.

**So the gap is discoverability, not capability** — which makes it the
cheapest item in this section:

- add an “experimental stimulus design” section to the vignette,
- add `\seealso` cross-links and a sentence to
  [`emoji_congruence()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_congruence.md)’s
  help page naming the congruency-experiment use,
- and note in §4.6 that `emoji_find()` serves stimulus construction.

**Effort** XS, documentation only. It is worth doing because a package
whose verbs are named for one literature is invisible to the next one,
and this is the second time this round that has turned out to be the
actual problem (see §10.3).

### 10.11 Political communication — typed function, not valence

Political actors use emoji to make institutional text informal and
accessible, and the research question is not “is this positive?” but
“what is the emoji *doing*?” — party branding, mobilisation,
credentialing, attack. There is an explicit *typology* effort in the
literature (IJOC, “Toward a Typology of Political Emoji Use”), and
adjacent work on emoji in the 2019 European Parliament election
campaigns. The broader 2024-25 polarisation literature is active but
treats emoji as one feature among many rather than as its object.

**Why this needs no new verb, but does need an extension.** tidyEmoji
already ships
[`emoji_type()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_type.md)
and
[`as_emoji_type()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/as_emoji_type.md)
— a functional-type classifier — and 0.4.0’s
[`emoji_faceness()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_faceness.md).
A political-communication typology is exactly a *registered type scheme*
over the same mechanism. So the right move mirrors §10.9’s conclusion
about lexicons:

- **Generalise the type vocabulary the way lexicons were generalised.**
  There is
  [`register_emoji_lexicon()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/register_emoji_lexicon.md)
  for affect; there is no `register_emoji_types()` for functional
  schemes. Adding it lets political-communication researchers, the
  marketing T-C-C-M literature (§2.4) and the AAC work (§10.12) each
  load their own scheme instead of asking us to bless one.
- **Ship no political type scheme.** Same reasoning as §10.3 and §10.4:
  the vocabulary is contested, national, and shifts with each election
  cycle.

``` r

register_emoji_types(name, mapping)   # mirror of register_emoji_lexicon()
emoji_types()                         # mirror of emoji_lexicons()
```

**Effort** S — it is the lexicon API’s shape applied to a second axis,
and the generic scorer
[`emoji_score()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_score.md)
already demonstrates the pattern. **Value** compounding: one mechanism
serves at least four literatures. Schedule with wave 3 alongside §10.8’s
`emoji_distinctive()`, which the same communities want.

### 10.12 AAC and assistive communication — watch, do not build

The thinnest of the twelve, and included because the framing is worth
borrowing. Augmentative and alternative communication serves people with
autism, cerebral palsy, intellectual disability, ALS, traumatic brain
injury and aphasia, using symbol systems that are highly individualised.
Practitioner work (Global Symbols) is beginning to combine AAC symbol
sets with emoji, on the argument that **emoji act as visual prosody** —
they do not carry the message’s content, they modify how it should be
understood.

**That phrase is the most useful thing in this section.** “Visual
prosody” is a better description of what
[`emoji_position()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_position.md),
[`emoji_density()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_density.md)
and
[`emoji_incongruity()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_incongruity.md)
actually measure than anything currently in the package’s own
documentation, and it connects the accessibility group (§4.3) to a
theoretical account rather than a list of heuristics. Borrow it in the
vignette.

**But do not build for this audience yet.** The evidence base is
practitioner guidance and product documentation, not empirical studies
with corpora to analyse; AAC symbol sets are mostly proprietary or
separately licensed; and the population is one where a wrong tool does
real harm. Revisit if peer-reviewed corpus work appears. **Effort**
none. **Action** one borrowed phrase, one watch-list entry.

### 10.13 Multimodal and retrieval — emoji as a stimulus set

§2.4 tracks what *text* LLMs do with emoji (EMODIS, the silent-failure
work). Vision-language models are a separate and newer question, because
an emoji is both a code point and a picture, so a VLM can be asked to
reason about it in either channel. **EmojiGrid** evaluates 25 leading
open and proprietary VLMs on emoji understanding and reports a large gap
between foundational perceptual tasks and higher-level cognition —
models handle “what is this glyph” and fail on abstraction,
compositional logic and emotional or semantic reasoning. Separately,
retrieval work uses emoji as visual cues in query autocompletion for
video search (ACM 2025), which is emoji as an *interface* element rather
than corpus content.

**The interesting inversion: this community does not want to analyse a
corpus. It wants to construct one.** Every other section in §10 hands
tidyEmoji a text column. VLM evaluation needs the opposite service — a
*principled stimulus set*: give me 200 emoji stratified by Unicode
version, group, modifiability and annotation depth, so my benchmark is
not accidentally 80% smileys. Right now researchers hand-pick these or
scrape Emojipedia, and both are unreproducible.

``` r

emoji_sample(n, strata = c("group", "version", "modifiable", "qualified"),
             seed = NULL)
#> reproducible, stratified draw from the RGI set, with the strata recorded
#> in the returned tibble so a paper can report exactly what it sampled
```

**Everything this needs was verified present in §2.1**: `group` /
`subgroup`, `version` (0.6 through 16.0), `qualified`, and the 454
modifiable bases. It is a stratified sample over a table we already join
to — arguably the smallest verb in this entire document relative to what
it unlocks.

**Why it is worth doing despite being outside the roadmap’s usual
remit:** reproducible stimulus construction is *also* what §10.6’s
psychometricians need (scale anchors sampled fairly), what §10.10’s L2
researchers need (vocabulary items by semantic field, via §4.6’s
`emoji_find()`), and what our own §7.4 fixture-table problem needs — the
“budget as much time for the fixture table as for the code” risk is
partly a sampling problem. **Four constituencies including ourselves.**

**Deps** none. **Effort** S. **Risk** low. **Recommend 0.6.0** with
§10.2’s tally input — together they make the package usable by people
who are not starting from a text column at all, which is the single
biggest widening available.

### 10.14 Crisis and disaster communication — served, and nobody knows

An established literature with a directly actionable finding. Work on
emoji and solidarity analysed three crisis events — Hurricane Irma
(2017), the November 2015 Paris attacks and the Charlottesville protests
— treating emoji as sociolinguistic markers of solidarity as events
unfold. Separately, a study of 2018 California Camp Fire tweets, framed
by uncertainty reduction theory, found that information uncertainty
depresses dissemination — **and that the effect was amplified when the
emoji depicted items and objects rather than facial expressions.**

**That moderator is
[`emoji_faceness()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_faceness.md),
which shipped in 0.4.0.** The face-versus-object distinction is the
crisis literature’s key emoji variable, and tidyEmoji already computes
it, along with
[`emoji_type()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_type.md)
for the finer functional split. The solidarity-over-time question is
[`emoji_trend()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_trend.md)
plus `emoji_frequency(group_by =)`. Nothing needs building.

**This is the third independent case of the same failure** — §10.3
(mental health), §10.10 (education), and now this — where the capability
exists and the audience cannot find it because the verb is named and
documented for the literature that motivated it. Three instances make it
a pattern worth fixing structurally rather than one help page at a time:

- **Add a “which verb answers my question?” table to the vignette**,
  indexed by *research question* rather than by verb name — “how
  prominent are emoji in this message?”, “do these two groups use
  different emoji?”, “are faces or objects being used?”, “what will a
  screen reader say?”.
- **Use `\concept{}` tags in roxygen** so
  [`help.search()`](https://rdrr.io/r/utils/help.search.html) finds
  verbs by domain vocabulary, not just by function name.

**Effort** S, documentation only, and it plausibly does more for
adoption than any verb in §4. A capability nobody can find is
indistinguishable from one that does not exist.

### 10.15 Workplace and organizational communication — the interaction, and a half-kept promise

A large and fast-growing practical literature. Experimental work on
emoji in workplace instant messages finds that **both sentence valence
and emoji valence affect perceived sender competence and appropriateness
— and that they interact**: positive emoji raise competence judgements
when paired with positive or neutral sentences, but have no such effect
on negative ones. Adjacent work covers emoji and workplace technology
adoption, and industry reporting puts workplace-messaging emoji use up
sharply year over year on platforms with tens of millions of daily
users.

**The measure this audience needs is an interaction term, not a main
effect.** That is precisely
[`emoji_congruence()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_congruence.md)
and
[`emoji_incongruity()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_incongruity.md),
shipped in 0.4.0. But both require the user to supply `text_score` — the
text’s own sentiment — because §5 defers text scoring to
[tidytext](https://juliasilge.github.io/tidytext/) /
[sentimentr](https://github.com/trinker/sentimentr) / `{vader}`
*permanently*, and rightly so.

**So this audience turns a promise into a dependency.** §5 says “stay
composable; document the recipe”. The recipe is currently
**half-documented**: `vignettes/introduction.Rmd` does demonstrate the
interface, but with — in its own words — “a deliberately crude word-list
scorer standing in for `tidytext` + AFINN, `sentimentr` or a
transformer”. That is fine for teaching the *shape* of the argument and
useless as something to cite in a paper. A researcher measuring the
competence interaction cannot publish a hand-rolled seven-word list.

**The fix, and why it is cheap:**

- **Add one worked recipe with a real package** — `tidytext` + AFINN is
  the obvious choice, and `sentimentr` for valence shifters — shown as a
  complete runnable pipeline into
  [`emoji_incongruity()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_incongruity.md).
- **Use `eval = FALSE`** so no new vignette-build dependency lands in
  `Suggests`. The recipe’s value is in being copyable and correct, not
  in being executed at check time. This keeps §5’s “import nothing”
  discipline intact.

**Two cross-links this section strengthens rather than repeats:**

- **§10.2’s tally input.** Slack and Teams reaction data are
  `(message, glyph, count)` tallies, so this is the fourth constituency
  for `emoji_from_counts()`.
- **§10.9’s domain-boundedness.** A workplace 👍 is not a
  consumer-review 👍 — the acknowledgement/dismissal reading is
  register-specific, and the bundled general-social-media lexicon will
  not carry it.
  [`register_emoji_lexicon()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/register_emoji_lexicon.md)
  again.

**Effort** S, documentation only. **Value** high relative to cost: it
converts a stated architectural principle into something a user can
actually execute.

------------------------------------------------------------------------

## 11. References

New or updated in this round. The fuller bibliography lives in the
`features.md` catalogue, which is **not in the working tree** — it is
preserved verbatim as GitHub **issue \#5**
(`gh issue view 5 --json body --jq '.body'`). References marked (verify)
rest on a search result rather than a fetched document.

**Accessibility (new theme, §4.3)**

- Emoji Accessibility for Visually Impaired People. *CHI 2020*.
  <https://doi.org/10.1145/3313831.3376267>
- “Party Face Congratulations!” Exploring Design Ideas to Help Sighted
  Users with Emoji Accessibility when Messaging with Screen Reader
  Users. *PACM HCI / CSCW 2024*. <https://doi.org/10.1145/3641014>

**Skin tone, identity and bias (§4.1)**

- Digital Skin, Digital Bias: Uncovering Tone-Based Biases in LLMs and
  Emoji Embeddings. *ACM Web Conference 2026*.
  <https://doi.org/10.1145/3774904.3792508>
- Digital Colourism? Understanding Emoji Skin Tone Preferences Among
  Indian-Origin Users. *BCS HCI 2025*.
- Robertson et al. (2018 ICWSM; 2020 ACM TSC 3(2)) — the 42% modified ÷
  modifiable result. <https://doi.org/10.1145/3377479>
- Black or White but Never Neutral. *CSCW 2021*.
  <https://doi.org/10.1145/3476091>
- Barbieri & Camacho-Collados (2018).
  <https://aclanthology.org/S18-2011/>

**LLM era (0.4.0 shipped the plumbing; these strengthen it)**

- EMODIS: A Benchmark for Context-Dependent Emoji Disambiguation in
  LLMs. *AAAI 2026*. <https://arxiv.org/abs/2511.07193> — human 88.5% vs
  GPT-4 58.8%.
- Small Symbols, Big Risks: Emoticon Semantic Confusion in LLMs (2026).
  <https://arxiv.org/abs/2601.07885> — \>38% confusion, \>90% silent
  failures.
- When Smiley Turns Hostile: How Emojis Trigger LLMs’ Toxicity (2025).
  <https://arxiv.org/abs/2509.11141>

**Applied domains (syntheses; no new API pressure)**

- Emojis in Marketing and Advertising: A Systematic Literature Review.
  *Behavioral Sciences* (2025). <https://doi.org/10.3390/bs15111490>
- Emoji-based marketing in consumer behavior: a systematic literature
  review. *Cogent Business & Management* (2026).
  <https://doi.org/10.1080/23311975.2026.2669001>
- Chakraborty et al. (2025). *Journal of Consumer Behaviour*.
  <https://doi.org/10.1002/cb.70017>

**Audience expansion (§10) — new this round**

*Legal and forensic (§10.1)*

- Danesi, M. The Law and Emojis: Emoji Forensics. *International Journal
  for the Semiotics of Law* (2021).
  <https://doi.org/10.1007/s11196-021-09854-6>
- Deciphering emoji variation in courts: a social semiotic perspective.
  *Humanities and Social Sciences Communications* (2022).
  <https://doi.org/10.1057/s41599-022-01453-5>

*Software-engineering communication (§10.2)*

- Lu, X. & Cao, Y. et al. A First Look at Emoji Usage on GitHub: An
  Empirical Study. <https://arxiv.org/abs/1812.04863>
- More than React: Investigating the Role of Emoji Reaction in GitHub
  Pull Requests. *Empirical Software Engineering* (2023).
  <https://doi.org/10.1007/s10664-023-10336-5> — 365,811 PRs, 1,850
  repos.
- Emotional Contagion in Code: How GitHub Emoji Reactions Shape
  Developer Collaboration (2025). <https://arxiv.org/abs/2511.02515> —
  106,743 reactions.

*Mental health and crisis informatics (§10.3)*

- SuicidEmoji: Derived Emoji Dataset and Tasks for Suicide-Related
  Social Content. *SIGIR 2024*.
  <https://doi.org/10.1145/3626772.3657852>

*Content moderation and algospeak (§10.4)*

- The Hidden Language of Harm: Examining the Role of Emojis in Harmful
  Online Communication and Content Moderation (2025).
  <https://arxiv.org/abs/2506.00583>
- Meta Oversight Board, emoji / coded-language cases.
  <https://www.oversightboard.com/pc/emojis-targeting-black-people/>

*Cross-cultural interpretation (§10.5)*

- Understanding Emoji Across Culture in Digital Communication. *IJRISS*
  (2025).
- Individual differences in emoji comprehension: gender, age and
  culture. <https://pmc.ncbi.nlm.nih.gov/articles/PMC10866486/>

*Survey methodology and psychometrics (§10.6)*

- Phan, W. M. J. et al. Contextualizing Interest Scales With Emojis:
  Implications for Measurement and Validity (2019).
  <https://doi.org/10.1177/1069072717748647>
- İlhan, M. et al. Effects of Category Labeling With Emojis on
  Likert-Type Scales on the Psychometric Properties of Measurements
  (2022). <https://doi.org/10.1177/07342829211047677>

*Annotation methodology (§10.7)*

- Counting on Consensus: Selecting the Right Inter-annotator Agreement
  Metric for NLP Annotation and Evaluation (2026).
  <https://arxiv.org/abs/2603.06865>

*Authorship attribution and stylometry (§10.8)*

- “Depends on Who I’m Writing To” — The Influence of Addressees and
  Personality Traits on the Use of Emoji and Emoticons, and Related
  Implications for Forensic Authorship Analysis. *Frontiers in
  Communication* (2022). <https://doi.org/10.3389/fcomm.2022.840646> —
  emoji are individuating, but subject to addressee accommodation.
- Forensic Authorship Analysis of Microblogging Texts.
  <https://arxiv.org/abs/2003.11545>
- Stylometry and forensic science: a literature review.
  <https://pmc.ncbi.nlm.nih.gov/articles/PMC11707938/>

*Finance and market sentiment (§10.9)*

- Emojis and stock returns (2023).
  <https://www.researchgate.net/publication/370669424_Emojis_and_stock_returns>

*Education and L2 acquisition (§10.10)*

- Disentangling the facilitation effect of emoji in vocabulary
  recognition: experimental evidence from semantic matching tasks.
  *Frontiers in Psychology* (2025).
  <https://doi.org/10.3389/fpsyg.2025.1629078>
- Emoji Literacy as a Teaching Tool, in *Emoji in Higher Education*.
  Cambridge University Press.
  <https://www.cambridge.org/core/books/emoji-in-higher-education/emoji-literacy-as-a-teaching-tool/312D5A682B962F187474F4A0781EFD51>

*Political communication (§10.11)*

- Toward a Typology of Political Emoji Use. *International Journal of
  Communication*.
  <https://ijoc.org/index.php/ijoc/article/download/20268/4259>
- Reranking partisan animosity in algorithmic social media feeds alters
  affective polarization. *Science* (2025).
  <https://doi.org/10.1126/science.adu5584> — context for the
  polarisation literature; emoji are a feature, not its object.

*AAC and assistive communication (§10.12)*

- Combining AAC Symbols and Emojis. Global Symbols.
  <https://globalsymbols.com/news/Combining%20AAC%20Symbols%20and%20Emojis>
- Augmentative and Alternative Communication. ASHA Practice Portal.
  <https://www.asha.org/practice-portal/professional-issues/augmentative-and-alternative-communication/>

*Multimodal and retrieval (§10.13)*

- EmojiGrid / Beyond Counting: Evaluating Abstract and Emotional
  Reasoning \[in vision-language models\]. *AAAI*.
  <https://ojs.aaai.org/index.php/AAAI/article/download/38389/42351> —
  25 VLMs; perceptual tasks pass, emotional and semantic reasoning
  fails.
- Emojis in Autocompletion: Enhancing Video Search with Visual Cues.
  *ACM* (2025). <https://dl.acm.org/doi/pdf/10.1145/3736733.3736745>

*Crisis and disaster communication (§10.14)*

- I Stand With You: Using Emojis to Study Solidarity in Crisis Events.
  <https://arxiv.org/abs/1907.08326> (also Springer, 2021,
  <doi:10.1007/978-3-030-80624-8_17>) — Hurricane Irma, Paris 2015,
  Charlottesville.
- Examining the Impact of Emojis on Disaster Communication: A
  Perspective from the Uncertainty Reduction Theory. *THCI* 15(4).
  <https://aisel.aisnet.org/thci/vol15/iss4/1/> — Camp Fire 2018; the
  object-vs-face moderator that
  [`emoji_faceness()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_faceness.md)
  computes.

*Zero-inflation and compositional structure (§4.8)*

- Compositional Data Analysis. *Annual Review of Statistics and Its
  Application*.
  <https://doi.org/10.1146/annurev-statistics-042720-124436>
- A critical comparison of handling zeros in high-dimensional
  compositional count data. <https://arxiv.org/html/2605.22181> —
  structural vs count zeros; log-ratio methods are undefined at zero.
- Principal component analysis for zero-inflated compositional data.
  *Computational Statistics & Data Analysis* 198 (2024).
  <https://doi.org/10.1016/j.csda.2024.107992>
- Zero-Inflated Text Data Analysis Using Imbalanced Data Sampling and
  Statistical Models. *Computers* 14(12), 527 (2025).
  <https://www.mdpi.com/2073-431X/14/12/527>

*Workplace and organizational communication (§10.15)*

- Emojis at Work: The Effects of Emoji Use on Perceptions of Competence
  and Appropriateness. *Collabra: Psychology*.
  <https://doi.org/10.1525/collabra.147309> — the valence x valence
  interaction.
- Embracing emojis: Bridging the gap in workplace technology adoption
  and elevating communication effectiveness. *SAGE* (2025).
  <https://doi.org/10.1177/20438869231220676>

**Standards and ecosystem**

- Unicode Emoji 17.0, released 2025-09-09; 163 additions, RGI total
  3,953. <https://www.unicode.org/emoji/charts-17.0/emoji-released.html>
- UTS \#51 and `emoji-test.txt`. <https://www.unicode.org/reports/tr51/>
- **UAX \#9, Unicode Bidirectional Algorithm** — the basis for the
  logical-vs- visual position limitation in §1.1.
  <https://www.unicode.org/reports/tr9/>
- CLDR emoji annotations — including the name-uniqueness rule and the
  translator guidance on languages lacking an English distinction
  (§1.3).
  <https://cldr.unicode.org/translation/characters/short-names-and-keywords>
- Regional indicator symbols and ISO 3166-1.
  <https://en.wikipedia.org/wiki/Regional_indicator_symbol>
- [emoji](https://emilhvitfeldt.github.io/emoji/) (CRAN, updated
  2026-05-08, tracks Unicode 16.0).
  <https://cran.r-project.org/package=emoji>
- [ragg](https://ragg.r-lib.org) — native colour emoji rendering in R
  graphics.
- `{text2emotion}` — emotion analysis and emoji mapping for text.
  <https://cran.r-project.org/package=text2emotion>
- EmojiSentR (JBDS).
  <https://jbds.isdsa.org/public/journals/1/html/v6n1/tong/>

------------------------------------------------------------------------

## 12. Appendix — the audit’s regression fixtures, as code

*Eleven rounds of auditing (§1.1-§1.9) each ended with “add this as a
fixture”. This appendix collects all of them into one runnable file,
following the repo’s existing convention (`test-regression-0.2.1.R`,
`-0.3.0.R`, `-0.4.0.R`), so the findings become executable rather than
prose. **It is split deliberately: Part A passes today and locks in
verified-correct behaviour; Part B fails today and is the TDD spec for
§3.1’s 0.5.0 correctness work.***

> **Both halves were executed, not just written (2026-08-31).** Part A
> runs green against the current tree — **12 tests, 53 assertions, 0
> failures**. Part B’s §1.1 fixture fails exactly as documented:
> `actual: 1.00 0.75 0.33` against `expected: 1.00 1.00 1.00`. The
> remaining Part B tests reference verbs that do not exist yet
> (`emoji_country()`, `emoji_skin_tone()`, `emoji_coverage()`, the
> `presentation =` argument), so they error rather than fail until those
> land — which is the normal state of a TDD spec, not a defect in the
> fixtures.

Save as `tests/testthat/test-regression-0.5.0.R`.

### 12.1 Part A — behaviour verified correct, now defended

``` r

# Fixtures for behaviour the 2026-08-30/31 audit confirmed correct.
# These should pass on the current tree; a failure here is a regression.

test_that("shortcode round-trip is lossless on hard cases (roadmap S1.3)", {
  glyphs <- c(
    "\U0001F600",                                     # grinning
    "\U0001F44B\U0001F3FB",                           # wave + light skin tone
    "\U0001F1FA\U0001F1F8",                           # regional-indicator flag
    "\U0001F468\u200D\U0001F469\u200D\U0001F467",   # ZWJ family
    "\u2764\uFE0F",                                   # heart + FE0F
    "1\uFE0F\u20E3",                                  # keycap
    "\U0001F44D"                                      # thumbs up
  )
  mid  <- emoji_to_text(tibble::tibble(text = glyphs), text, format = "shortcode")$text
  back <- text_to_emoji(tibble::tibble(text = mid), text)$text
  expect_identical(back, glyphs)
})

test_that("name format is one-way by design (roadmap S1.3)", {
  d    <- tibble::tibble(text = "\U0001F600")
  mid  <- emoji_to_text(d, text, format = "name")$text
  expect_identical(mid, "grinning face")
  # bare names are ordinary words; restoration is not attempted
  expect_identical(text_to_emoji(tibble::tibble(text = mid), text)$text, mid)
})

test_that("emoji_search() treats the pattern literally (roadmap S1.8)", {
  # ".*" must not behave as a regex wildcard
  expect_equal(nrow(emoji_search(".*")), 0L)
  for (pat in c("(", "[", "a(b", "\\")) {
    expect_no_error(emoji_search(pat))
  }
  expect_gt(nrow(emoji_search("smil")), 0L)
})

test_that("qualified and unqualified forms share a lexicon row (roadmap S1.6)", {
  d <- tibble::tibble(text = c("\U0001F44D\uFE0F", "\U0001F44D"))
  r <- emoji_sentiment(d, text)
  expect_equal(r$.emoji_sentiment[1], r$.emoji_sentiment[2])
})

test_that(".emoji_n_scored distinguishes absent from unscoreable (roadmap S1.6)", {
  # pleading face (Emoji 11.0) is detected but absent from the 2015 lexicon
  d <- tibble::tibble(text = c("no emoji", "hi \U0001F600", "new \U0001F97A", NA_character_))
  r <- emoji_sentiment(d, text)
  expect_identical(r$.emoji_n,        c(0L, 1L, 1L, 0L))
  expect_identical(r$.emoji_n_scored, c(NA_integer_, 1L, 0L, NA_integer_))
  expect_true(is.na(r$.emoji_sentiment[3]))
})

test_that("new columns on user data are dotted (roadmap S1.6)", {
  d <- tibble::tibble(id = 1:3, text = c("hi \U0001F600", "none", NA_character_))
  for (f in list(emoji_sentiment, emoji_position, emoji_ratio,
                 emoji_density, emoji_type, emoji_faceness)) {
    added <- setdiff(names(f(d, text)), names(d))
    expect_true(all(grepl("^\\.emoji", added)))
  }
})

test_that("emoji_score() agrees with the specific scorer (roadmap S1.8)", {
  d <- tibble::tibble(text = c("hi \U0001F600", "none"))
  expect_equal(emoji_sentiment(d, text)$.emoji_sentiment,
               emoji_score(d, text, lexicon = "sentiment")$.emoji_score)
})

test_that("emoji_sanitize() policies form the documented loss ladder (S1.9)", {
  orig <- "great \U0001F600 work \U0001F44D today"
  d <- tibble::tibble(text = orig)
  restore <- function(pol) {
    out <- emoji_sanitize(d, text, policy = pol)$text
    text_to_emoji(tibble::tibble(text = out), text)$text
  }
  expect_identical(restore("keep"), orig)        # reversible
  expect_identical(restore("shortcode"), orig)   # reversible -- the LLM path
  expect_false(identical(restore("name"), orig))
  expect_false(identical(restore("placeholder"), orig))
  expect_false(identical(restore("strip"), orig))
  # strip must not leave doubled whitespace
  expect_false(grepl("  ", emoji_sanitize(d, text, policy = "strip")$text))
})

test_that("emoji_context() windows handle both boundaries (roadmap S1.9)", {
  d <- tibble::tibble(text = c("\U0001F600 starts here now", "ends here now \U0001F600"))
  r <- emoji_context(d, text, window = 2, unit = "word")
  expect_identical(r$.emoji_context_left[1],  "")
  expect_identical(r$.emoji_context_right[2], "")
})

test_that("detection handles keycaps and valid tone sequences as single units (S1.2)", {
  one_unit <- c("1\uFE0F\u20E3", "#\uFE0F\u20E3", "\u2764\uFE0F",
                "\U0001F1FA\U0001F1F8", "\U0001F44B\U0001F3FB")
  for (g in one_unit) {
    expect_equal(emoji_summary(tibble::tibble(text = g), text)$n_with_emoji, 1L)
  }
})

test_that("emoji are invariant under Unicode normalisation (roadmap S1.4)", {
  skip_if_not_installed("stringi")
  glyphs <- c("\U0001F44B\U0001F3FB", "\u2764\uFE0F",
              "\U0001F1FA\U0001F1F8", "1\uFE0F\u20E3")
  for (g in glyphs) {
    expect_identical(stringi::stri_trans_nfc(g), g)
    expect_identical(stringi::stri_trans_nfd(g), g)
  }
})

test_that("zero-row and all-NA input are handled, not errored (roadmap S1.5)", {
  z  <- tibble::tibble(text = character(0))
  na <- tibble::tibble(text = rep(NA_character_, 3))
  for (f in list(emoji_sentiment, emoji_position, emoji_frequency,
                 emoji_ratio, emoji_type, emoji_tokens)) {
    expect_no_error(f(z, text))
    expect_no_error(f(na, text))
  }
})
```

### 12.2 Part B — the defects, written as the target behaviour

*These **fail on the current tree**. They are the acceptance criteria
for §3.1’s 0.5.0 correctness items, in the same order as §1.*

``` r

# TDD spec for the 0.5.0 correctness release. Each test names the roadmap
# section that found the defect. Expect failures until that item lands.

test_that("S1.1: rel_position is grapheme-based, so a final emoji reports 1.0", {
  d <- tibble::tibble(text = c(
    "hi \U0001F600",                                   # 1 codepoint  -> passes today
    "hi \U0001F1FA\U0001F1F8",                         # 2 codepoints -> reports 0.750
    "hi \U0001F468\u200D\U0001F469\u200D\U0001F467\u200D\U0001F466"  # 7 -> reports 0.333
  ))
  r <- emoji_position(d, text)
  expect_equal(r$.emoji_rel_position, c(1, 1, 1))
})

test_that("S1.2: an invalid regional-indicator pair is not given a country code", {
  d <- tibble::tibble(text = "a \U0001F1FD\U0001F1FD b")   # 'XX' -- not a country
  r <- emoji_country(d, text)
  expect_true(is.na(r$.emoji_iso2[1]))
  expect_false(identical(r$.emoji_iso2[1], "XX"))
})

test_that("S1.2: an orphan skin-tone modifier is accounted for, not counted as an emoji", {
  d <- tibble::tibble(text = "a \U0001F600\U0001F3FB b")  # tone on a non-modifiable base
  r <- emoji_skin_tone(d, text)
  expect_equal(r$.emoji_n_orphan_modifiers[1], 1L)
  expect_equal(r$.emoji_n_modified[1], 0L)
})

test_that("S1.5: the three unguarded aggregators warn on grouped input", {
  # NOTE: lifecycle warnings deduplicate per call site. Each expectation must
  # sit at its own call site, or run in a fresh process -- see the trap in S1.4.
  d <- dplyr::group_by(
    tibble::tibble(grp  = c("a", "a", "b", "b"),
                   text = c("x \U0001F600", "y \U0001F602",
                            "p \U0001F1FA\U0001F1F8", "q \U0001F1EF\U0001F1F5")),
    grp)
  expect_warning(emoji_categorize(d, text),      "ungrouped|group")
  expect_warning(emoji_version_profile(d, text), "ungrouped|group")
  expect_warning(emoji_ngrams(d, text),          "ungrouped|group")
})

test_that("S1.5: time verbs name `time`, not the internal `var`, when it is missing", {
  d <- tibble::tibble(text = "hi \U0001F600", when = Sys.Date())
  expect_error(emoji_trend(d, text), "time")
  expect_error(emoji_turnover(d, text), "time")
})

test_that("S4.7: presentation = 'any' reaches text-presentation glyphs", {
  d <- tibble::tibble(text = "bare \u2764 heart")        # U+2764, no FE0F
  expect_equal(emoji_summary(d, text, presentation = "emoji")$n_with_emoji, 0L)
  expect_equal(emoji_summary(d, text, presentation = "any")$n_with_emoji,   1L)
})

test_that("S1.7: emoji_coverage() reports what a lexicon could not score", {
  d <- tibble::tibble(text = c("hi \U0001F600", "new \U0001F97A", "none"))
  r <- emoji_coverage(d, text, lexicon = "sentiment")
  expect_equal(r$n_occurrences, 2L)
  expect_equal(r$n_scoreable,   1L)
  expect_equal(r$coverage_rate, 0.5)
  expect_true("\U0001F97A" %in% r$top_unscored[[1]])
})
```

### 12.3 Two cautions carried from the audit method

Both cost a cycle each to discover, and both will silently corrupt a
test suite rather than fail loudly:

1.  **`lifecycle` warnings deduplicate per call site (§1.5).** Any test
    looping over verbs from a single line will report only the first as
    warning. Use distinct call sites, or one process per verb.
2.  **Locale tests must vary only `LC_COLLATE` (§1.4).** Setting
    `LC_ALL=C` mangles UTF-8 *source files*, so the fixture changes
    before package code runs and every verb appears broken. Build
    fixture glyphs from `\U` escapes rather than literal characters — as
    this appendix does throughout, which is also why it is safe to run
    under any locale.
