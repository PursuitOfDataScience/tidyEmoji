## Submission notes

This is a feature release (0.3.0; previous CRAN version 0.2.0). It adds emoji
emotion scoring, a pluggable lexicon API, emoji<->text translation, and emoji
search, plus a new bundled emotion lexicon. It also includes the 0.2.1
correctness patch (key-normalisation, unified detection, `.emoji_n_scored`,
`top_n_emojis` fixes, grouped-df warnings). See NEWS.md for the full list.

Headline new features (see NEWS.md):

* `emoji_emotion()` / `emoji_emotion_label()` score the 8 Plutchik emotions via
  the new bundled `emoji_emotion_lexicon` (EmoTag1200, Shoeb & de Melo 2020,
  MIT-licensed).
* A pluggable lexicon API: `emoji_lexicons()`, `register_emoji_lexicon()`,
  `emoji_score()`; `emoji_sentiment()` gains a `lexicon` argument.
* `emoji_to_text()` / `text_to_emoji()` for demojize/emojize, plus vector
  helpers `as_emoji_name()`, `as_emoji_shortcode()`, `as_emoji()`.
* `emoji_search()` finds emoji by keyword, name or shortcode.

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
