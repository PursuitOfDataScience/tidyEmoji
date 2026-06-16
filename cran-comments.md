## Submission notes

This is a feature release (0.2.0; previous CRAN version 0.1.1, August 2023).
It generalises tidyEmoji from a tweet-specific tool to a general toolkit for
emoji in any text, adds emoji sentiment scoring (`emoji_sentiment()`),
corpus-frequency and tidy "token" verbs (`emoji_frequency()`, `emoji_tokens()`),
and makes detection grapheme-aware so zero-width-joiner sequences and skin-tone
emoji are counted as single emoji. See NEWS.md for the full list, including the
documented breaking changes (argument renames and a deprecated argument).

## Test environments

* Local: R 4.4.1 on Linux (RHEL 8)
* GitHub Actions:
  - ubuntu-latest: R-release, R-devel, R-oldrel-1
  - macOS-latest: R-release
  - windows-latest: R-release
* win-builder: R-devel and R-release

## R CMD check results

0 errors | 0 warnings | 0 notes

## Bundled data and licence

The package bundles the Emoji Sentiment Ranking lexicon (Kralj Novak et al.,
2015, <doi:10.1371/journal.pone.0144296>), released under CC BY-SA 4.0. This is
stated in the DESCRIPTION and on the dataset's help page
(`?emoji_sentiment_lexicon`). The package code itself remains GPL (>= 3).

## Downstream dependencies

There are no reverse dependencies (checked with
`tools::package_dependencies(reverse = TRUE)`).
