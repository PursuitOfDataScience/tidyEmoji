## Submission notes

This is a feature release (0.3.0; previous CRAN version 0.2.0). It contains
the 0.2.1 correctness patch (documented separately in NEWS.md: codepoint-
normalised metadata joins, unified emoji detection, `.emoji_n_scored`,
`top_n_emojis()` fixes, warnings on grouped input) plus the 0.3.0 features:

* Emoji emotion scoring (`emoji_emotion()`, `emoji_emotion_label()`) with the
  new bundled EmoTag1200 lexicon, and a pluggable lexicon API
  (`emoji_lexicons()`, `register_emoji_lexicon()`, `emoji_score()`).
* Relational analysis (`emoji_pairs()`, `emoji_cooccurrence()`,
  `emoji_ngrams()`), structural metrics (`emoji_position()`,
  `emoji_density()`, `emoji_ratio()`), and `emoji_dfm()` document-by-emoji
  feature tables.
* Emoji<->text translation (`emoji_to_text()`, `text_to_emoji()`,
  `as_emoji*()` helpers) and `emoji_search()`.

## Test environments

* Local: R 4.4.1 on Linux
* GitHub Actions:
  - ubuntu-latest: R-release, R-devel, R-oldrel-1
  - macOS-latest: R-release
  - windows-latest: R-release
* win-builder: R-devel and R-release

## R CMD check results

0 errors | 0 warnings | 1 NOTE

* NOTE: `checking data for non-ASCII characters` -- "found marked UTF-8 strings"
  in the bundled emoji datasets. The crosswalks and lexicons contain emoji
  glyphs, which are inherently non-ASCII UTF-8, so this note is expected and
  unavoidable for emoji data; it is tolerated by CRAN.

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
