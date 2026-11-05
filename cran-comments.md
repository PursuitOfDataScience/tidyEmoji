## Submission notes

This is a **feature release**. The current CRAN version is 0.4.0, published
on 2026-09-17. Version 0.5.0 was prepared but never published on CRAN, so
this submission carries the changes of both; NEWS.md lists each release under
its own heading.

* **Ten new exported functions**: `emoji_coverage()`, `emoji_properties()`,
  `as_emoji_canonical()`, `emoji_identical()`, `emoji_find()`,
  `emoji_keywords()`, `emoji_country()`, `emoji_subdivision()`,
  `emoji_flag()` and `emoji_from_counts()`.
* **New arguments, all with defaults that keep earlier behaviour**: every
  verb that reads a text column gains `presentation = "emoji"`, placed last
  so no positional call changes meaning; `emoji_collocations()` and
  `emoji_pairs()` gain association measures; `emoji_ambiguity()` and its two
  companions gain `measure = "polarisation"`.
* **Results users can observe changing, all documented in NEWS.md with
  worked examples**: the emoji catalogue moved from the `emoji` package's
  table (Emoji 16.0) to Unicode's own `emoji-test.txt` (Emoji 18.0), so 182
  more emoji are detected; and a skin-tone swatch standing alone, or a pair of
  regional indicators that spells no country, is no longer counted as an
  emoji. `emoji_summary()` reports both, so a changed count can be explained.
  `emoji_ratio()`, `emoji_density()`, `emoji_trend()`, `emoji_summary()` and
  `emoji_provenance()` gain columns; none loses one.
* **Lifecycle**: `emoji_tweets()`, soft-deprecated since 0.2.1, now warns
  through `lifecycle::deprecate_warn()` and names 0.7.0 as its removal.
* **Dependencies**: `stringi` joins Imports. It was already installed with
  every copy of tidyEmoji, through `emoji`, which imports `stringr`; the
  detector now calls it directly with the extended pattern. `igraph` joins
  Suggests, for the new networks vignette, whose `igraph` chunks are skipped
  when it is absent. The declared floors are unchanged.
* **Bundled data**: one new internal file, `R/sysdata.rda` (31 KB), holding
  the Unicode catalogue. It is derived from Unicode data under the Unicode
  License V3, whose full text `inst/LICENSE.note` now reproduces, as the
  licence asks. The two crosswalk datasets are rebuilt from the same file:
  `emoji_unicode_crosswalk` keeps its 5761 rows and
  `category_unicode_crosswalk` gains the 202 new spellings. The two lexicons
  are unchanged.
* **Nothing is fetched at build, check, test or run time.** The catalogue is
  built by `data-raw/crosswalks.R`, run by hand, from a copy of the Unicode
  file committed beside it. One test asks unicode.org whether a newer emoji
  version exists; it runs only when `TIDYEMOJI_CANARY=true`, which only the
  repository's weekly job sets, and it is also skipped on CRAN.
* **One new vignette**, `emoji-networks`, and additions to the introduction
  vignette and to the help pages. No Rd content was removed.

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
  `ctype` job running it under `LC_ALL=C`, a weekly URL, spelling and
  catalogue job, and a coverage job
* win-builder: R-devel and R-release

## R CMD check results

Reported per environment rather than as one headline, and separating the
package's own results from this host's artefacts. The four that recur on our
machine, and are not the package, are: no `qpdf`, no `tidy`, an unverifiable
system clock, and the URL discussed below. The PDF reference manual is only
built locally, so the local run is the one that covers it: do not skip it.

* **Local, R 4.4.1 on Linux, `R CMD check --as-cran` with
  `_R_CHECK_CRAN_INCOMING_REMOTE_=true`:** 1 WARNING, 3 NOTEs, and all four are the host artefacts above: no `qpdf`,
  no `tidy`, the unverifiable clock, and the CLARIN.SI redirect target.
  **Zero from the package.** The suite runs 16751 assertions with 0 failures
  and the 17 skips inventoried below, and the PDF reference manual builds.
  (Run from the source tree with `NOT_CRAN=true` the same suite reports 16867
  assertions and 5 skips: the tests that stand down for a file the tarball
  does not carry, or because the run is a CRAN one, run there.)

* **Local, R 4.1.0 on Linux, the declared minimum:** the suite runs clean
  from the source tree, 16863 assertions and 0 failures, with 6 skips: the
  three acceptance tests, the tangled vignette script (not installed from a
  source tree), the `readr (>= 2.0.0)` gate (that tree carries 1.4.0) and the
  catalogue canary.
* **Local, R 4.6.0 on Linux:** clean too, 16863 assertions, 0 failures and the
  same 6 skips, `readr` being absent there.
* **Local, R 4.4.1, the suite under `LC_ALL=C`:** 16858 assertions, 0
  failures, 8 skips: the five a UTF-8 source run has, plus three that measure
  R's own transliteration or case mapping rather than the package, and say
  so. The new detection code reads text through `stringi`, which does not
  depend on the locale.
* **Coverage:** 98.4% by `covr::package_coverage()`, run the way the coverage
  job runs it, against that job's 95% floor.

* **Spelling**: `spelling::spell_check_package()` reports 0 unknown words
  across the help pages, the three vignettes, README.md and NEWS.md, with the
  208 entries in `inst/WORDLIST`.

**Still to run before submitting**: the six GitHub Actions flavours with the
two collation jobs and the `ctype` job, and win-builder on R-devel and
R-release. Record each result here as it comes back rather than carrying this
paragraph forward.

## The skip inventory

Run as CRAN runs it, **seventeen** tests skip on R 4.4.1, and none of them
is a test that might fail.

* **eight are `skip_on_cran()`**: they read the checking machine rather than
  the package. The declared R minimum against an installable tree, a
  `select()`-avoidance benchmark comparing two wall-clock timings, four that
  read files a tarball does not carry (`data-raw/` for rebuilding the
  catalogue and crosswalks, `README.Rmd` for re-rendering it, and this file
  twice for its own claims), one asserting the installed `emoji` release is
  the exact one the documented vocabulary figures came from, and the
  catalogue canary, which is also gated on an environment variable only the
  weekly job sets.
* **One holds the output snapshots**, which testthat does not compare on
  CRAN.
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
`Note: found 6890 marked UTF-8 strings`. Every one of those strings is an emoji
glyph in a glyph column: `emoji_unicode_crosswalk$unicode` 5761,
`emoji_sentiment_lexicon$emoji` 969, `emoji_emotion_lexicon$emoji` 150,
`category_unicode_crosswalk$unicodes` 10. No other column in any dataset
carries a marked string. It is recorded because it is inherent to emoji data
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
