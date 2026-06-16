# Emoji Sentiment Ranking lexicon

Sentiment scores for emoji, from the *Emoji Sentiment Ranking 1.0*,
computed from ~70,000 tweets in 13 European languages annotated for
sentiment. The `sentiment_score` is
`(positive - negative) / occurrences`, ranging from -1 (negative) to +1
(positive); `sentiment_label` is derived from its sign.

## Usage

``` r
emoji_sentiment_lexicon
```

## Format

A data frame with one row per emoji and the columns:

- emoji:

  The emoji glyph.

- occurrences:

  Number of times the emoji was observed.

- position:

  Mean position of the emoji within its text (0-1).

- negative, neutral, positive:

  Annotation counts for each class.

- sentiment_score:

  Sentiment score from -1 to 1.

- sentiment_label:

  "negative", "neutral" or "positive".

- unicode_name:

  The official Unicode character name.

- unicode_block:

  The Unicode block.

## Source

Kralj Novak P, Smailovic J, Sluban B, Mozetic I (2015) Sentiment of
Emojis. PLoS ONE 10(12): e0144296.
[doi:10.1371/journal.pone.0144296](https://doi.org/10.1371/journal.pone.0144296)
. Data from <https://hdl.handle.net/11356/1048>, released under the
Creative Commons Attribution-ShareAlike 4.0 International (CC BY-SA 4.0)
licence. Processed by `data-raw/emoji_sentiment_lexicon.R`.
