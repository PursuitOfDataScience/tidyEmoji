## Submission notes

This is a feature release (0.4.0; previous CRAN version 0.2.0). It contains the
0.2.1 correctness patch and the 0.3.0 feature release, both documented
separately in NEWS.md, plus the 0.4.0 features:

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

No new dependencies, no new bundled data, and no change to the existing
verbs' output columns. One behavioural fix is noted in NEWS.md:
`emoji_dfm(doc_id = )` previously ordered its rows with the session's
collation and now uses first-appearance order of the id.

The package makes no network requests, at check time or at run time.

## Test environments

* Local: R 4.4.1 on Linux
* GitHub Actions:
  - ubuntu-latest: R-release, R-devel, R-oldrel-1
  - macOS-latest: R-release
  - windows-latest: R-release
* win-builder: R-devel and R-release

## R CMD check results

0 errors | 0 warnings | 0 notes

The bundled datasets contain emoji glyphs and are therefore marked UTF-8. This
did not produce a note on any of the 13 CRAN check flavours for 0.2.0; 0.4.0
adds no further data. Should a checking host report "found marked UTF-8
strings", it is inherent to emoji data rather than a defect.

The reference manual builds as PDF. Help pages refer to emoji by code point
(for example `U+2764 U+FE0F`) rather than embedding the glyph, so pdfLaTeX has
no unmapped characters to typeset.

`?emoji_sentiment_lexicon` links to <https://hdl.handle.net/11356/1048>, the
canonical CLARIN.SI handle for the Emoji Sentiment Ranking data. It resolves
correctly; a checking host whose certificate store cannot verify the
`hdl.handle.net` chain may report it as a possibly-invalid URL (R itself
reports "Status without verification: OK").

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

There are no reverse dependencies (checked with
`tools::package_dependencies(reverse = TRUE)`).
