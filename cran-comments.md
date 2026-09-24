## Submission notes

This is a **maintenance release**. The previous CRAN version, 0.4.0, was
published on 2026-09-17.

* **No new exported functions.** What a user can observe changing comes in
  four parts, all in NEWS.md. The first is speed: `emoji_context()` was
  quadratic in the emoji per row, and `emoji_collocations()` inherited it, so
  a row of 3200 emoji cost 7.1s against 0.28s for the same 3200 spread over
  320 rows. Each row now gets one index of its code points and token
  boundaries instead of being cut once per occurrence, and the output is
  byte-identical, checked across eight `window`/`unit` combinations. The
  second is `emoji_collocations()` on a non-Latin-script corpus, which it
  answered wrongly in a non-UTF-8 locale and now answers the same in every
  locale. The third is eleven smaller defects a source reading found before
  submission, each a wrong, order-dependent or crashing answer on an input
  the documentation already covered, each fixed with a test. The fourth is
  one error message: a data frame carrying the same column name twice used to
  fail with tibble's own wording, which named an argument (`.name_repair`)
  that no verb here has, and now gets an authored one. No input that worked
  before fails now. The only inputs that failed before and succeed now are
  counts past integer range (`emoji_ngrams(n = 1e10)`, a `window` of `1e10`),
  which now mean "all of it".
* **One new vignette**, `reversible-preprocessing`, and documentation
  additions to the introduction vignette and four help pages. No Rd content
  was removed.
* **Dependencies:** `spelling` added to Suggests, and the declared `testthat`
  minimum raised from `>= 3.0.0` to `>= 3.1.5`, which is the release that
  added the `expect_no_error()` and `expect_no_warning()` the suite has used
  since 0.4.0. Imports are unchanged.
* **Bundled data and licence are unchanged**, and the crosswalks still
  reproduce exactly from `data-raw/crosswalks.R` against `emoji` 16.0.0.
* **Nothing was flagged by a reviewer on the 0.4.0 submission**, so there is
  no carried-over correction. The single URL note this check produces is the
  one discussed below, and it predates that submission.
* **On `Days since last update`.** The incoming check will report a small
  number, and it is accurate: 0.4.0 was published on 2026-09-17. The
  performance defect above was found immediately after it shipped, on a corpus
  shape the benchmark script could not see, and it is the reason for the short
  interval rather than an oversight. We are happy to hold the submission if the
  timing is unwelcome.

## Test environments

*Re-run all of these. The list is the environments to cover, not a record of a
run that has happened for this version.*

* Local: R 4.1.0 (the declared minimum), R 4.4.1 and R 4.6.0 on Linux
* Locale: `R CMD check --as-cran` end to end under `LC_ALL=C`, examples,
  vignette and tests included, with the skip inventory explained
* GitHub Actions, six GitHub Actions flavours in the check matrix:
  - ubuntu-latest: R-release, R-devel, R-oldrel-1, R 4.1
  - macOS-latest: R-release
  - windows-latest: R-release
* GitHub Actions, additionally: two collation jobs running the same check with
  `LC_COLLATE` set to `C` and to `en_US.UTF-8` and nothing else varied, a
  `ctype` job running it under `LC_ALL=C`, a weekly URL and spelling job, and
  a coverage job
* win-builder: R-devel and R-release

## R CMD check results

Reported per environment rather than as one headline, and separating the
package's own results from this host's artefacts. The four that recur on our
machine, and are not the package, are: no `qpdf`, no `tidy`, an unverifiable
system clock, and the URL discussed below. The PDF reference manual is only
built locally, so the local run is the one that covers it: do not skip it.

* **Local, R 4.4.1 on Linux, `R CMD check --as-cran` with
  `_R_CHECK_CRAN_INCOMING_REMOTE_=true`:** 1 WARNING, 3 NOTEs, and all four
  are the host artefacts above -- no `qpdf`, no `tidy`, the unverifiable
  clock, and the CLARIN.SI redirect target. **Zero from the package.** The
  suite runs 16150 assertions with 0 failures and the 19 skips inventoried
  below, and the PDF reference manual builds. (Run from the source tree with
  `NOT_CRAN=true` the same suite reports 16269 assertions and 8 skips. Twelve
  of the nineteen stand down only because the run is a CRAN one, or for want
  of a file the tarball does not carry, and one test goes the other way: the
  tangled vignette script exists only in a package installed from the
  tarball. The 119-assertion difference is theirs, net. The figure above is
  the one this bullet's own environment prints.)

* **Local, R 4.1.0 on Linux, the declared minimum:** the suite runs clean,
  0 failures, 9 skips. Seven are the acceptance tests for verbs not yet
  written, one is the tangled vignette script (not installed from a source
  tree), and one is the `readr (>= 2.0.0)` gate, that tree carrying 1.4.0.
* **Local, R 4.6.0 on Linux:** the suite runs clean there too, 0 failures and
  the same 9 skips. That tree genuinely lacks `spelling`, `readr` and
  `forcats`, so it is also where the missing-Suggests path can be exercised
  for real rather than simulated: with `_R_CHECK_FORCE_SUGGESTS_=false` the
  check is **2 NOTEs** (the URL below and the missing `tidy`) with 0 test
  failures and 16146 assertions. Two of the four artefacts this machine
  reports do not arise there at all, because it has `qpdf` and a verifiable
  clock, which is the clearest demonstration available that those two are the
  host rather than the package.

* **Local, R 4.4.1, the same check end to end under `LC_ALL=C`**, examples,
  vignette rebuild and tests included: the same 1 WARNING and 3 NOTEs, the
  same four host artefacts, 0 test failures and 16144 assertions. Three tests
  stand down in a non-UTF-8 session, each because it measures R's own
  transliteration or case mapping rather than the package, and each says so.
  One of the three is already a `skip_on_cran()`, so the check prints 21 skips
  where a UTF-8 run prints 19.

  Separately from the check, 110 verb calls covering every exported verb on
  the bundled corpus and on an eleven-row multi-script fixture were captured
  under `en_US.UTF-8` and under `LC_ALL=C`, each proved to have run rather
  than errored, and compared: **110 of 110 identical**. The same 110 against
  0.4.0 differ in exactly the calls NEWS.md describes: the
  `emoji_collocations()` fix (two calls in UTF-8, four under `LC_ALL=C`),
  `emoji_incongruity_profile(where = "final")`, and `policy = "strip"` on a
  row ending in an ideographic space. No call gains or loses an error.
* **Spelling**: `spelling::spell_check_package()` reports 0 unknown words
  across the help pages, both vignettes, README.md and NEWS.md, with the 167
  entries in `inst/WORDLIST`.
* **URLs**: `urlchecker::url_check()` resolves 12 of the 13 addresses in the
  package. The thirteenth is the CLARIN.SI handle discussed below, and it
  fails here for the same certificate reason the check reports.
* **Declared dependency floors are real ones.** Checked against the source
  tarballs of the declared versions rather than the installed ones: every
  `dplyr::`, `tidyr::` and `lifecycle::` function the package calls is
  exported by dplyr 1.1.0, tidyr 1.3.0 and lifecycle 1.0.3, and every named
  argument it passes to a callee without `...` is a formal there, which
  covers `lifecycle::deprecate_soft(env=, user_env=)`, the pair the floor was
  raised for. `rlang` and `tibble` carry no floor; the eight functions used
  from them are present as far back as rlang 1.0.0 and tibble 3.0.0.

**Still to run before submitting**: the six GitHub Actions flavours with the
two collation jobs and the `ctype` job, and win-builder on R-devel and
R-release. Record each result here as it comes back rather than carrying this
paragraph forward.

## The skip inventory

Run as CRAN runs it, **nineteen** tests skip on R 4.4.1, and none of them is a
test that might fail.

* **seven are `skip_on_cran()`**: they read the checking machine rather than
  the package. The declared R minimum against an installable tree, a
  `select()`-avoidance benchmark comparing two wall-clock timings, four that
  read files a tarball does not carry (`data-raw/` for regenerating the
  crosswalks, `README.Rmd` for re-rendering it, and this file twice for its own
  claims), and one asserting the installed `emoji` release is the exact one the
  documented catalogue figures came from.
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
* **Seven are acceptance tests for verbs the next release will add**, each
  naming its target: `emoji_country()`, `emoji_skin_tone()`,
  `emoji_coverage()`, `emoji_keywords()`, `as_emoji_canonical()`,
  `emoji_identical()` and a `presentation =` argument. They live in
  `test-acceptance-pending.R`, deliberately not named for a version, so the
  specification sits where it will run and does not have to be re-labelled at
  every release; they stand down by name until the verb exists rather than
  failing.

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
suite asserts that this file still quotes them. Exact detection of the reference
table is **95.8%**, which is 4830 of its 5042 spellings, up from **63.2%**
(3189 of 5042) before the 0.4.0 grapheme repair. The number of spellings that
lose a zero-width joiner went from **1643** to 2. `test-invariants.R` derives
all four numbers from the installed catalogue, so re-run the suite rather than
copying them forward if the catalogue moves.

## Bundled data and licence

The package bundles two lexicons, both documented on their help pages and in the
DESCRIPTION:

* The Emoji Sentiment Ranking lexicon (Kralj Novak et al., 2015,
  <doi:10.1371/journal.pone.0144296>), released under CC BY-SA 4.0.
* The EmoTag1200 emotion lexicon (Shoeb & de Melo, 2020,
  <https://aclanthology.org/2020.emnlp-main.720/>), released under the MIT
  licence. The MIT licence is compatible with the package's GPL (>= 3); the
  source and licence are attributed in `?emoji_emotion_lexicon` and rebuilt by
  `data-raw/emoji_emotion_lexicon.R`.

## Downstream dependencies

There are no reverse dependencies. Verified against a live CRAN index
(24,748 packages when last re-checked) with
`tools::package_dependencies("tidyEmoji", db = available.packages(),
reverse = TRUE, which = c("Depends", "Imports", "LinkingTo", "Suggests",
"Enhances"))`, which returns none. Re-run this against a live index before submitting, and state the published
version it reports.

The DOI in DESCRIPTION and on `?emoji_sentiment_lexicon`
(<doi:10.1371/journal.pone.0144296>) resolves to the PLoS ONE article.
