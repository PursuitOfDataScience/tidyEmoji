## Submission notes

This is a **feature release**. The current CRAN version is 0.6.0, published
on 2026-11-05. Its check page reported OK on all 13 flavours when read on
2026-11-09, so nothing there asks for an early fix, and this submission
waits out the interval CRAN asks between updates of an established package.
NEWS.md gives every change with a worked example.

* **Eight new exported functions**: `emoji_hidden()`, which finds, measures
  and decodes hidden payloads; `emoji_decompose()`, `emoji_skin_tone()`,
  `emoji_gender()` and `emoji_retone()`, which read what a glyph depicts and
  never infer anything about the person writing it; and `emoji_runs()`,
  `emoji_features()` and `emoji_a11y_check()`, for runs of emoji, the cues
  around each one and the facts behind their accessibility.
* **Results users can observe changing**: `emoji_sanitize()` and
  `emoji_to_text()` remove hidden payloads (variation selectors and tag
  characters that carry no visible meaning) by default, and
  `hidden = "keep"` restores 0.6.0's output; the catalogue now decides
  three detection questions, so a symbol with a stray `U+FE0F` counts only
  if it is listed, a `U+FE0E` asking for the text form is honoured, and a
  zero-width-joiner sequence Unicode does not recommend counts as its
  parts. Counts can therefore move in both directions, and
  `emoji_summary()` reports each change. The verbs also now work without
  `library(tidyEmoji)`: package code read its bundled datasets by bare
  name, which only an attached package resolves.
* **Lifecycle**: `emoji_tweets()` and `top_n_emojis(duplicated_unicode = )`
  are defunct, as 0.6.0's deprecation warnings announced.
* **Dependencies**: `emoji` moves from Imports to Suggests. The package
  bundles an attributed snapshot of the frozen data and regex of `emoji`
  16.0.0 (MIT) instead of importing it. `readr` leaves Suggests, and
  `ISOcodes` and `jsonlite` join it. The declared floors are unchanged.
* **Bundled data and licence**: the example corpus
  `inst/extdata/ata_tweets.csv`, which had no recorded source or licence,
  is replaced by `oasst_messages` and `oasst_reactions`, a screened sample
  of OpenAssistant Conversations (Apache License 2.0); `R/sysdata.rda`
  adds the `emoji` snapshot, the CLDR 49 keywords, the shortcodes of
  emojibase 18.0.0 and Unicode's standardized variation sequences. Each
  source and its notice are under *Bundled data and licence* below, and
  this submission adds the authors of the two bundled lexicons to
  `Authors@R` as copyright holders. The package's own licence is
  unchanged.
* **Check time**: 0.6.0's tests took 219 to 237 s of CPU on CRAN's x86_64
  flavours; 0.7.0 holds them to a budget, measured under *Check time*
  below, Windows and macOS included.
* **The last review**: 0.6.0 was accepted as first submitted, so there is
  no reviewer request to answer.

## Test environments

*Re-run all of these. The list is the environments to cover, not a record of a
run that has happened for this version.*

* Local: R 4.1.0 (the declared minimum), R 4.4.1 and R 4.6.0 on Linux
* Locale: `R CMD check --as-cran` end to end under `LC_ALL=C`, examples,
  vignettes and tests included, with the skip inventory explained
* GitHub Actions, six GitHub Actions flavours in the check matrix:
  - ubuntu-latest: R-release, R-devel, R-oldrel-1, R 4.1
  - macOS-latest: R-release
  - windows-latest: R-release
* GitHub Actions, additionally: two collation jobs running the same check with
  `LC_COLLATE` set to `C` and to `en_US.UTF-8` and nothing else varied, a
  `ctype` job running it under `LC_ALL=C`, a `cran-mode` job running
  `R CMD check --as-cran` with `NOT_CRAN` unset, as CRAN does, on
  windows-latest (R-devel and release) and macos-latest (release), a
  `cran-budget` job timing the suite in CRAN mode against a ceiling, a weekly
  URL, spelling and catalogue job, and a coverage job
* win-builder: R-devel and R-release
* macOS builder: R-release on an Apple M1, the setup of CRAN's
  r-release-macos-arm64

## R CMD check results

The package's own result is the same everywhere: **0 errors, 0 warnings and
one NOTE**, from the incoming feasibility check, saying "Days since last
update: 4", since 0.6.0 was published on 2026-11-05. The rest of what this
host reports is the host: no `qpdf` (a WARNING), no HTML Tidy, an
unverifiable system clock, and the CLARIN.SI URL discussed below, which R
itself marks "Status without verification: OK". Each run is of the 0.7.0
tarball, with `NOT_CRAN` unset and the remote incoming checks on.

* **R 4.4.1 on Linux** (x86_64, an AMD EPYC 7702): Status 1 WARNING, 3
  NOTEs. The WARNING (`qpdf`) and two NOTEs (the clock, HTML Tidy) are this
  host's; the third NOTE is the incoming one, holding the days since the
  update and the URL. Tests: 0 failures, 66 skipped (see the skip
  inventory). The PDF reference manual builds, which only this local run
  checks.
* **The same under `LC_ALL=C`**: the same result. Tests: 0 failures, 68
  skipped, the 66 above and two that read the session's encoding and stand
  down outside UTF-8: a glyph as a column name, and the fold compared with
  `tolower()`.
* **R 4.1.0**, the declared minimum: Status 1 WARNING, 3 NOTEs: `qpdf`, the
  clock, the incoming NOTE, and `spelling` not installed in that library,
  which `_R_CHECK_FORCE_SUGGESTS_=false` lets through. Tests: 0 failures, 66
  skipped.
* **R 4.6.0**, with `forcats`, `igraph`, `ISOcodes` and `spelling` absent,
  so the check runs without four of its Suggests as some CRAN flavours do:
  Status 2 NOTEs, the incoming NOTE and HTML Tidy. Tests: 0 failures, 67
  skipped, the 66 and one that needs `ISOcodes`.

* **Spelling**: `spelling::spell_check_package()` reports 0 unknown words
  across the help pages, the four vignettes, README.md and NEWS.md, with the
  270 entries in `inst/WORDLIST`.
* **The incoming spell check of DESCRIPTION**: win-builder's NOTE named four
  words its aspell check did not know: CLDR, Kopf, OpenAssistant and
  shortcodes. That check runs only where `_R_CHECK_CRAN_INCOMING_USE_ASPELL_`
  is set, as on CRAN and win-builder, so neither our runs nor the `cran-mode`
  job raised it. DESCRIPTION now spells out CLDR (the Unicode Common Locale
  Data Repository) and quotes 'OpenAssistant' as the project's name. The two
  words left are spelt correctly: Kopf is the first author of the OASST2
  paper, and shortcodes is the usual name for codes such as `:smile:`. The
  same check, run here with R's own function and the GNU aspell English
  dictionaries, reports those two and nothing else on the current
  DESCRIPTION.

## The skip inventory

Run as CRAN runs it, **66** tests skip on R 4.4.1, and none of them
is a test that might fail.

* **49 are sweeps, behind `skip_sweep()`**: the exhaustive tests (every
  catalogue spelling, every verb, hundreds of random strings) that took most
  of CRAN's check time before 0.7.0. Each names its *twin*, a test that does
  run on CRAN and asserts the same property over a deterministic sample of
  the catalogue, always including a fixed list of hard cases (keycaps, country
  and tag flags, the code points newer than the bundled detection regex, ZWJ
  families, toned couples), so no property goes unchecked there. A test fails
  if a sweep names a twin that does not exist, and every sweep runs on every
  push in CI, where `NOT_CRAN` is true.
* **eleven are `skip_on_cran()`**: ten read the checking machine rather than
  the package. The declared R minimum against an installable tree, a
  `select()`-avoidance benchmark comparing two wall-clock timings, six that
  read files a tarball does not carry (`data-raw/` twice, for rebuilding the
  catalogue, crosswalks and lexicons and for rebuilding the example datasets,
  `README.Rmd` for re-rendering it, `_pkgdown.yml` for the site's reference
  index, and this file twice for its own claims),
  one asserting the installed `emoji` release is
  the one the bundled snapshot of its data was taken from, and the
  catalogue canary, which is also gated on an environment variable only the
  weekly job sets. The eleventh holds the output snapshots, which testthat does
  not compare on CRAN in any case.
* **Five stand down because the tarball does not carry the file they read**,
  and each says which file. Their messages are, on one line each so they stay
  greppable:
  `README sources not available`
  `package sources not available; scanned the namespace instead`
  `workflow not available`
  `roxygen sources not available`
  The first accounts for two of the five: one compares `README.md` against
  `README.Rmd`'s prose, the other runs every chunk of `README.Rmd`, and
  `README.Rmd` is build-ignored. The second scans the installed namespace
  instead, the third is coupled to `.github/`, also build-ignored, and the
  fourth reads the roxygen comments in `R/`, which an installed package
  keeps only as the rendered help pages.
* **One is an acceptance test for a verb a later release will add**, naming
  its target: `emoji_sentiment_role()`. It lives in
  `test-acceptance-pending.R`, deliberately not named for a version, and
  stands down by name until the verb exists rather than failing. Eight that
  used to live there have landed: six in 0.6.0, now in
  `test-regression-0.6.0.R`, and those for `emoji_skin_tone()` and
  `emoji_runs()` in this release, now in `test-regression-0.7.0.R`.

Count this from the run rather than copying the number forward: it changes
whenever a verb lands or a test is added.

## Marked UTF-8 strings

The bundled datasets contain emoji glyphs and are therefore marked UTF-8, and a
plain `R CMD check` (without `--as-cran`, which suppresses it) reports
`Note: found 8208 marked UTF-8 strings`. Every one of those strings is an emoji
glyph in a glyph column or a message in the example corpus:
`emoji_unicode_crosswalk$unicode` 5963, `emoji_sentiment_lexicon$emoji` 969,
`emoji_emotion_lexicon$emoji` 150, `category_unicode_crosswalk$unicodes` 10,
and `oasst_messages$text` 1116, the messages that hold emoji or are written
in a script other than ASCII. No other column in any dataset carries a marked
string. It is recorded because it is inherent to emoji data
rather than a defect, and because the figure should be verifiable rather than
asserted.

## The one URL note, and what it is not

`?emoji_sentiment_lexicon` links to <https://hdl.handle.net/11356/1048>, the
canonical CLARIN.SI handle for the Emoji Sentiment Ranking data. It is the only
URL `R CMD check --as-cran` reports with remote checks enabled, and only on our
machine.

The documented URL itself is healthy, which is the part that matters: it
returns `HTTP/2 302` with
`location: https://www.clarin.si/repository/xmlui/handle/11356/1048`. What the
checker cannot reach is that redirect target, a third-party CLARIN.SI host,
rather than `hdl.handle.net` or anything the package controls.

So we make no claim about the target's current availability: it is not ours to
make. The claim is narrower and checkable. The URL the package documents
resolves and redirects correctly, and the note describes a third-party host
reached only by following that redirect. A checking host that can reach
CLARIN.SI reports nothing. We keep the canonical handle rather than a mirror,
because it is the citable identifier the data is published under.

## Detection figures, carried forward

These are properties of the package rather than of one submission, and the test
suite asserts that this file still quotes them. On the Emoji 18.0 catalogue
every one of the 3963 fully-qualified and 1029 minimally-qualified spellings is
detected as exactly one emoji. The figures for the 0.4.0 grapheme repair are
measured on the 5042 spellings of Emoji 16.0 it was built against, and the
suite still reproduces them: exact detection is **95.8%**, which is 4830 of
5042, up from **63.2%** (3189 of 5042) before the repair, and the number of
spellings that lose a zero-width joiner went from **1643** to 2.
`test-invariants.R` derives all of these from the installed package, so re-run
the suite rather than copying them forward if the catalogue moves.

## Bundled data and licence

The package bundles two lexicons and one catalogue, each documented and
attributed:

* The Emoji Sentiment Ranking lexicon (Kralj Novak et al., 2015,
  <doi:10.1371/journal.pone.0144296>), released under CC BY-SA 4.0.
* The EmoTag1200 emotion lexicon (Shoeb & de Melo, 2020,
  <https://aclanthology.org/2020.emnlp-main.720/>), released under the MIT
  licence. The MIT licence is compatible with the package's GPL (>= 3); the
  source and licence are attributed in `?emoji_emotion_lexicon` and rebuilt by
  `data-raw/emoji_emotion_lexicon.R`.
* The emoji catalogue in `R/sysdata.rda`, derived from Unicode's
  `emoji-test.txt` for Emoji 18.0 under the Unicode License V3, which is
  permissive and asks only that its notice accompany the data; the notice is
  reproduced in full in `inst/LICENSE.note`. Since 0.7.0 the same licence
  covers the UCD's variation-sequence files and the CLDR 49 keywords that
  sit beside it.
* New in 0.7.0: the example data `oasst_messages` and `oasst_reactions`, a
  screened sample of OpenAssistant Conversations (Kopf et al., 2023,
  <doi:10.48550/arXiv.2304.07327>) under the Apache License 2.0, whose text
  is reproduced in `inst/LICENSE.note`; it replaces a corpus of posts with no
  recorded licence. Also new: a snapshot of the frozen data of the `emoji`
  package 16.0.0 (MIT), which moves from Imports to Suggests, and the
  shortcodes of emojibase-data 18.0.0 (MIT). Each MIT notice is in
  `inst/LICENSE.note`, and each copyright holder is in `Authors@R`.

## Check time

0.6.0's tests took 219 to 237 s of CPU on CRAN's x86_64 flavours, and the
whole check 680 s on r-release-macos-x86_64. 0.7.0 holds the suite to a
budget. Run as CRAN runs it, on byte-compiled installs on one core of an AMD
EPYC 7702 on Linux, the 0.7.0 suite takes a median 58.4 s of CPU (58.1
to 64.3 s) where 0.6.0's takes 155.4 s: 2.65 times less, 95% CI 2.64 to
2.68, over 12 paired, interleaved runs of the two with a warm-up pair
discarded, and 2.44 times in the worst pair (Wilcoxon signed-rank
p = 0.00049). That is the suite of this submission, regression tests for
the pre-submission repairs included; the same design gave 55.0 s and 2.83
times less on 2026-11-08, before them. No test block takes a second. A
`cran-budget` job in CI fails over 82.5 s, 1.5 times the median of five
runs of it at the release commit (52.7, 55.0, 55.0, 56.7 and 57.2 s elapsed
on GitHub's ubuntu-latest), or over 1 s for any one block. The exhaustive
tests run in CI on every push and stand down on CRAN through
`skip_sweep()`, each with a sampled twin that does run there (the skip
inventory above).

Windows and macOS, in CRAN mode: the `cran-mode` job runs
`R CMD check --as-cran` with `NOT_CRAN` unset on GitHub's runners, as
win-builder and the macOS builder do. On commit a1d1dd4 the tests took 86 s
on windows-latest with R-devel (2026-11-05 r90840), 83 s with R 4.6.2 and
34 s on macos-latest (arm64, R 4.6.2); the vignettes 20, 21 and 11 s; the
whole check 188, 180 and 95 s, with 0 failures and 69, 69 and 71 tests
skipped. CRAN's own check times for 0.6.0, read on 2026-11-09, are 452 s on
r-devel-windows-x86_64, 516 s on r-release-windows-x86_64 and 397 s on
r-oldrel-windows-x86_64, 116 s on r-release-macos-arm64 and 674 s on
r-release-macos-x86_64. All three jobs gave one NOTE, from the incoming
feasibility check: the days since the last update, and a request to cite the
OASST2 paper by its arXiv DOI, which DESCRIPTION now does.
The macOS builder checked the 6fbe954 tarball twice on 2026-11-08. One run
asked for R-release and one for R-devel, and it ran both on its
r-release-macosx-arm64 setup (R 4.6.1 patched, macOS 26.6, an Apple M1):
Status OK with no NOTE, the tests 28 s, the vignettes 14 and 13 s, and the
whole check 86 and 68 s of wall clock, against CRAN's 116 s for 0.6.0 on the
same flavour. win-builder checked the same tarball on 2026-11-07 with R-devel
(2026-11-06 r90845) and R 4.6.2: the tests 79 and 73 s, the vignettes 20 and
19 s, and the whole check 192 s on each, well under CRAN's Windows figures
above. Each gave one NOTE, from the incoming feasibility check: the days
since the last update, and the four words of DESCRIPTION discussed under the
check results. Since that tarball the package has changed by that wording
and by the pre-submission repairs NEWS.md lists, so both builders check the
final tarball again before it is submitted; the `cran-mode` jobs have
checked every commit in between.

## Downstream dependencies

There are no reverse dependencies. Verified against a live CRAN index
(25,529 packages on 2026-11-09, which list tidyEmoji at 0.6.0) with
`tools::package_dependencies("tidyEmoji", db = available.packages(),
reverse = TRUE, which = c("Depends", "Imports", "LinkingTo", "Suggests",
"Enhances"))`, which returns none. Re-run this against a live index before
submitting, and state the published version it reports.

The DOI in DESCRIPTION and on `?emoji_sentiment_lexicon`
(<doi:10.1371/journal.pone.0144296>) resolves to the PLoS ONE article.
