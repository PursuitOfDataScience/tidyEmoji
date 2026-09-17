## Submission notes

This is a **maintenance release**. The previous CRAN version, 0.4.0, was
published on 2026-09-17.

* **No new exported functions, and no behaviour changes.** Every verb returns
  what it returned in 0.4.0. The one change a user can observe is speed:
  `emoji_context()` was quadratic in the emoji per row, and
  `emoji_collocations()` inherited it, so a row of 3200 emoji cost 7.1s
  against 0.28s for the same 3200 spread over 320 rows. Each row now gets one
  index of its code points and token boundaries instead of being cut once per
  occurrence. The output is byte-identical, checked across eight
  `window`/`unit` combinations. See NEWS.md.
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
* **On `Days since last update: 0`.** The incoming check will report this,
  and it is accurate: 0.4.0 was published the same day. The performance
  defect above was found immediately after it shipped, on a corpus shape the
  benchmark script could not see, and it is the reason for the short
  interval rather than an oversight. We are happy to hold the submission if
  the timing is unwelcome.

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
  weekly URL and spelling job, and a coverage job
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
  suite runs 14736 assertions with 0 failures and the 17 skips inventoried
  below, and the PDF reference manual builds.

**Still to run before submitting**: R 4.1.0 and R 4.6.0 locally, the
`LC_ALL=C` end-to-end check, the six GitHub Actions flavours with the two
collation jobs, and win-builder on R-devel and R-release. Record each result
here as it comes back rather than carrying this paragraph forward.

## The skip inventory

Run as CRAN runs it, **seventeen** tests skip on R 4.4.1, and none of them is a
test that might fail.

* **seven are `skip_on_cran()`**: they read the checking machine rather than
  the package. The declared R minimum against an installable tree, a
  `select()`-avoidance benchmark comparing two wall-clock timings, four that
  read files a tarball does not carry (`data-raw/` for regenerating the
  crosswalks, `README.Rmd` for re-rendering it, and this file twice for its own
  claims), and one asserting the installed `emoji` release is the exact one the
  documented catalogue figures came from.
* **Three stand down because the tarball does not carry the file they read**,
  and each says which file. Their messages are, on one line each so they stay
  greppable:
  `README sources not available`
  `package sources not available; scanned the namespace instead`
  `workflow not available`
  The second scans the installed namespace instead, and the third is coupled to
  `.github/`, which is build-ignored.
* **Seven are acceptance tests for verbs the next release will add**, each
  naming its target: `emoji_country()`, `emoji_skin_tone()`,
  `emoji_coverage()`, `emoji_keywords()`, `as_emoji_canonical()`,
  `emoji_identical()` and a `presentation =` argument. They live in
  `test-regression-0.5.0.R` so the specification sits where it will run, and
  they stand down by name until the verb exists rather than failing.

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
