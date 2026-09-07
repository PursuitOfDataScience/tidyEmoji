## Submission notes

This is a feature release (0.4.0; previous CRAN version 0.3.0, published
2026-08-04). The 0.2.1 correctness patch and the 0.3.0 features shipped in that
0.3.0 release and are documented separately in NEWS.md. New in 0.4.0:

* Interpretation risk (`emoji_ambiguity()`, `emoji_risk()`,
  `emoji_flag_ambiguous()`, `emoji_sentiment(se = TRUE)`), computed from the
  annotation counts already carried by the bundled Emoji Sentiment Ranking.
* Context windows and corpus-derived collocations (`emoji_context()`,
  `emoji_collocations()`).
* Time verbs (`emoji_trend()`, `emoji_turnover()`, `emoji_seasonality()`,
  `emoji_version_profile()`, `emoji_adoption_lag()`,
  `emoji_unicode_releases()`).
* Text-emoji mismatch (`emoji_incongruity()`, `emoji_congruence()`,
  `emoji_incongruity_profile()`).
* Functional type (`emoji_type()`, `emoji_faceness()`, `as_emoji_type()`).
* Preprocessing policies and token accounting for language-model pipelines
  (`emoji_sanitize()`, `emoji_token_cost()`).
* Provenance (`emoji_provenance()`, `emoji_unicode_version()`) and a new
  `inst/CITATION`.

No new dependencies and no new bundled data. No verb gains or loses an output
column, but a pre-submission audit produced several behavioural fixes, all
detailed in NEWS.md. The ones a user could notice:

* Detection: 232 of the 2501 zero-width-joiner sequences in the reference
  table were split into their component emoji instead of being read as one.
  The 2023-2024 sequences built around a bare gender sign are the clearest
  case: "woman walking facing right" arrived as "person walking" plus "right
  arrow". The grapheme repair now also rejoins a pair whose union is itself a
  catalogued emoji, and grows a lone match outwards when its sequence has no
  second match to merge with. Exact detection of the reference table goes from
  63.2% to 95.8% (3189 of 5042 spellings, against 4830) and the number of
  spellings that lose a joiner from 1643 to 2.
  Counts change only for corpora holding one of the affected spellings: the
  bundled 2000-tweet corpus used in the vignette has 38 rows containing a
  joiner and its counts are unchanged, and `README.md` re-renders byte for
  byte, so well-formed text is unaffected.
* The time verbs bucketed a `POSIXct` column by its UTC day rather than by the
  day it shows in its own timezone, so a 23:30 timestamp in a western zone was
  counted on the following day. Day, month, quarter, year and weekday buckets
  change for date-time columns outside UTC; `Date` columns are unaffected.
* `emoji_categorize()` filtered on "has a categorisable emoji" rather than "has
  an emoji", so a row whose only glyph was newer than the installed 'emoji'
  package was dropped from the result. It is now kept with `.emoji_category`
  set to NA.
* `emoji_position()`'s `.emoji_rel_position` counted code points, so a
  multi-code-point emoji (a flag, a ZWJ family) inflated the denominator and an
  emoji that ended the text scored well under 1. Each emoji now counts as one
  position. `.emoji_first` / `.emoji_last` are unchanged and remain code-point
  offsets.
* `emoji_dfm(doc_id = )` previously ordered its rows with the session's
  collation and now uses first-appearance order of the id.
* The verbs that work a row at a time now carry a grouped data frame's grouping
  through to their result, as `dplyr::mutate()` and `dplyr::filter()` do;
  previously the grouping was dropped, so a later `summarise()` silently gave
  one corpus-wide row. Six verbs also stopped rejecting grouped input outright.
* Zero-row input now returns the documented column *types*; five verbs built
  them with `ifelse()` and returned `logical` columns where a populated call
  returns `double` or `integer`. No value changed.
* Arguments that were absorbed now error: a fractional `n` / `top_n` /
  `window` / `min_n` (each was silently truncated), a non-string
  `emoji_ngrams(sep = )`, and a `register_emoji_lexicon()` name that a bundled
  lexicon already answers to (the registration used to succeed and then be
  unreachable).
* A character `time` column now warns about values it cannot read as dates
  before the rows are dropped; previously they were dropped silently.

The package makes no network requests, at check time or at run time.

`emoji_version_profile()` and `emoji_adoption_lag()` change output for
variation-selector emoji. The upstream `emoji::emojis` table attaches the
introducing Unicode version to the unqualified member of a variation pair and
leaves it `NA` on the fully-qualified one, so 1252 of 5042 reference rows had
no version and were reported as unknown. The reference table now fills
`version` across glyphs sharing a codepoint key, which is the normalisation
already used for every other glyph-to-metadata join in the package. No
codepoint key carries two different versions, so the change only fills gaps.


The declared R dependency is raised from `R (>= 3.5.0)` to `R (>= 4.1.0)`. This
is a correction, not a new requirement: the package's own code uses nothing
newer than R 3.5, but `dplyr` and `tidyr` -- both hard dependencies -- declare
`R (>= 4.1.0)`, so R 4.1.0 is the oldest version on which `tidyEmoji` can in
fact be installed. The previous value produced an opaque dependency-resolution
error on R 3.5 to 4.0 rather than a clear message about the R version.

Three package floors are also newly declared, each for a specific argument the
package would otherwise fail on. None adds a dependency; all three name a
version from 2021-2023, no newer than the existing `dplyr (>= 1.1.0)`.

* `lifecycle (>= 1.0.3)` -- `deprecate_warn(env=, user_env=)`. These arguments
  do not exist in lifecycle 1.0.0. Every grouped-input warning in the package
  goes through one helper that passes them, so on an older lifecycle a dozen
  verbs would fail with "unused argument".
* `tidyr (>= 1.3.0)` -- `separate_longer_delim()`, used in the vignette in
  place of the superseded `separate_rows()`.
* `readr (>= 2.0.0)` in Suggests -- `read_csv(show_col_types=)`, absent in
  readr 1.4.0. Used only by one test, which now also gates on the version
  rather than on mere presence.

The introduction vignette no longer requires any Suggests package to build.
It read its example corpus with `readr::read_csv()` and drew its charts with
\pkg{ggplot2}, \pkg{forcats} and \pkg{stringr} unconditionally, so
`R CMD build` failed outright on a library tree without them. The corpus is now
read with `utils::read.csv()`, and the nine plotting chunks are gated on a
`requireNamespace()` flag, so the vignette builds with or without them.


## Test environments

* Local: R 4.1.0 (the declared minimum), R 4.4.1 and R 4.6.0 on Linux
* GitHub Actions:
  - ubuntu-latest: R-release, R-devel, R-oldrel-1
  - macOS-latest: R-release
  - windows-latest: R-release
* win-builder: R-devel and R-release

## R CMD check results

0 errors | 0 warnings | 0 notes

Locally, a full `R CMD check --as-cran` with the remote incoming checks
*enabled* (`_R_CHECK_CRAN_INCOMING_REMOTE_=true`) reports 1 WARNING and 3
NOTEs, and all four are artefacts of this host rather than the package: no
`qpdf`, no `tidy`, an unverifiable system clock, and the URL below. The
substantive checks all pass there: installation, examples, the `testthat`
suite, vignette re-building and the PDF manual.

On R 4.6.0 (the newest release available locally), the same check reports
`Status: 2 NOTEs` -- the URL below and the missing `tidy` -- with everything
else OK, including vignette re-building and the PDF manual. That tree has
neither 'readr' nor 'forcats' installed, so it doubles as the check that the
package and its vignette build without their Suggests packages;
`_R_CHECK_FORCE_SUGGESTS_=false` is needed there, since a complete check
requires them by default.

On R 4.1.0, the declared minimum, the `testthat` suite passed in full when
last run there; that tree has `readr` 1.4.0, so the test gated on
`readr (>= 2.0.0)` skips. The figure is from that run and the suite has grown
since, so it is stated as history rather than as a current measurement.

The skip inventory itself is current and was re-measured for this submission
on R 4.4.1. Run as CRAN runs it, eight tests skip, all eight
`skip_on_cran()` and all eight maintenance checks rather than checks of
package behaviour: the declared R minimum against an installable tree,
regenerating the bundled crosswalks from `data-raw/`, a `select()`-avoidance
check on the whole catalogue, `emoji_dfm()` at its widest, an examples audit
of the lexicon registry, re-rendering `README.Rmd` to confirm the output
`README.md` shows is current, and two that read this file and check its own
claims. Checking a built tarball skips three
more, because they read sources a tarball does not carry -- `README.Rmd`, the
`R/` tree, and the vignette's corpus -- each of which asserts against the
installed package instead when the source is absent. Nothing skips for want of
a Suggests package on a complete tree.

The bundled datasets contain emoji glyphs and are therefore marked UTF-8, and
a plain `R CMD check` (without `--as-cran`, which suppresses it) does report
`Note: found 6890 marked UTF-8 strings`. That count is fully accounted for and
every one of the strings is an emoji glyph in a glyph column:
`emoji_unicode_crosswalk$unicode` 5761, `emoji_sentiment_lexicon$emoji` 969,
`emoji_emotion_lexicon$emoji` 150, `category_unicode_crosswalk$unicodes` 10.
No other column in any dataset carries a marked string. The note did not appear
on any of the 13 CRAN check flavours for 0.2.0 and 0.4.0 adds no further data,
so it is not expected here; it is recorded because it is inherent to emoji data
rather than a defect, and because the figure should be verifiable rather than
asserted.

The reference manual builds as PDF. Help pages refer to emoji by code point
(for example `U+2764 U+FE0F`) rather than embedding the glyph, so pdfLaTeX has
no unmapped characters to typeset.

`?emoji_sentiment_lexicon` links to <https://hdl.handle.net/11356/1048>, the
canonical CLARIN.SI handle for the Emoji Sentiment Ranking data. Every URL in
the package was checked by `R CMD check --as-cran` with remote checks enabled,
and this is the only one reported -- on our machine only. The precise cause follows.

The documented URL itself is healthy, and this is the part that matters: it
returns `HTTP/2 302` with
`location: https://www.clarin.si/repository/xmlui/handle/11356/1048`. What
`R CMD check` cannot reach is that redirect target -- a third-party CLARIN.SI
host -- not `hdl.handle.net`, and not anything the package controls.

Why the target fails has changed between our own check runs, which is itself
the point. It first failed verification: the chain `clarin.si` <-
`GEANT TLS RSA 1` (HARICA) ends at an intermediate, and `openssl s_client`
reported `Verify return code: 20 (unable to get local issuer certificate)`
because this host is CentOS 8 carrying `ca-certificates-2020.2.41` with no
current HARICA root; R's wording then was
`Status: Error ... (Status without verification: OK)`. On the most recent run
the host does not answer at all: DNS resolves `www.clarin.si` to
`95.87.154.205`, but a TCP connect times out after 40s, with or without TLS
verification, while other European academic hosts (`aclanthology.org`,
`doi.org`) respond normally from the same machine in the same session.

So we make no claim about the target's current availability -- it is not ours
to make. The claim is narrower and checkable: the URL the package documents
resolves and redirects correctly, and the note describes a third-party host
reached only by following that redirect. A checking host that can reach
CLARIN.SI reports nothing. We have kept the canonical handle rather than
substituting a mirror, because it is the citable identifier the data is
published under.

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
"Enhances"))`, which returns none. The same index confirms the currently
published version is 0.3.0.

The DOI in DESCRIPTION and on `?emoji_sentiment_lexicon`
(<doi:10.1371/journal.pone.0144296>) resolves to the PLoS ONE article.
