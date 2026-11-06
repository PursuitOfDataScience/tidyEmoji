## Submission notes

*Skeleton for the next submission, opened 2026-11-06 after 0.6.0 was accepted.
Fill in the two TODO sections before submitting; everything below them is
carried forward because the test suite derives it and will fail if it goes
stale. The 0.6.0 text is in git history (`git show v0.6.0:cran-comments.md`)
if a paragraph is worth reusing.*

**TODO before submitting.** In this order:

* What kind of release this is, and the previous CRAN version with its
  publication date.
* The new verbs and the behaviour changes a user could notice, each in one
  sentence, pointing at NEWS.md for the detail.
* Whether dependencies, bundled data or the licence changed.
* The check times before and after the CRAN time budget, beside the CRAN
  figures, including Windows and macOS.
* Anything a CRAN reviewer flagged last time, and how it was addressed.

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
  `ctype` job running it under `LC_ALL=C`, a `cran-budget` job timing the
  suite in CRAN mode against a ceiling, a weekly URL, spelling and catalogue
  job, and a coverage job
* win-builder: R-devel and R-release

## R CMD check results

**TODO: fill in from an actual run.** Report per environment rather than as one
headline, and separate the package's own results from this host's artefacts.
The four that recur on our machine, and are not the package, are: no `qpdf`,
no `tidy`, an unverifiable system clock, and the URL discussed below. The PDF
reference manual is only built locally, so the local run is the one that covers
it: do not skip it.

* **Spelling**: `spelling::spell_check_package()` reports 0 unknown words
  across the help pages, the three vignettes, README.md and NEWS.md, with the
  208 entries in `inst/WORDLIST`.

## The skip inventory

Run as CRAN runs it, **61** tests skip on R 4.4.1, and none of them
is a test that might fail.

* **42 are sweeps, behind `skip_sweep()`**: the exhaustive tests (every
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
  catalogue and crosswalks and for rebuilding the example datasets,
  `README.Rmd` for re-rendering it, `_pkgdown.yml` for the site's reference
  index, and this file twice for its own claims),
  one asserting the installed `emoji` release is
  the exact one the documented vocabulary figures came from, and the
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
* **Three are acceptance tests for verbs a later release will add**, each
  naming its target: `emoji_skin_tone()`, `emoji_runs()` and
  `emoji_sentiment_role()`. They live in `test-acceptance-pending.R`,
  deliberately not named for a version, and stand down by name until the verb
  exists rather than failing. Six that used to live there landed in this
  release and now run in `test-regression-0.6.0.R`.

Count this from the run rather than copying the number forward: it changes
whenever a verb lands or a test is added.

## Marked UTF-8 strings

The bundled datasets contain emoji glyphs and are therefore marked UTF-8, and a
plain `R CMD check` (without `--as-cran`, which suppresses it) reports
`Note: found 8006 marked UTF-8 strings`. Every one of those strings is an emoji
glyph in a glyph column or a message in the example corpus:
`emoji_unicode_crosswalk$unicode` 5761, `emoji_sentiment_lexicon$emoji` 969,
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
  reproduced in full in `inst/LICENSE.note`.

## Downstream dependencies

There are no reverse dependencies. Verified against a live CRAN index
(25,479 packages on 2026-11-04, which list tidyEmoji at 0.4.0) with
`tools::package_dependencies("tidyEmoji", db = available.packages(),
reverse = TRUE, which = c("Depends", "Imports", "LinkingTo", "Suggests",
"Enhances"))`, which returns none. Re-run this against a live index before submitting, and state the published
version it reports.

The DOI in DESCRIPTION and on `?emoji_sentiment_lexicon`
(<doi:10.1371/journal.pone.0144296>) resolves to the PLoS ONE article.
