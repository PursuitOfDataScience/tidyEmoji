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

## Detection limitations

Many of the glyphs in this lexicon are stored in their *unqualified*,
text-presentation form: a single code point with no `U+FE0F`
emoji-presentation variation selector. The best-known is the bare heart,
`U+2764`; others include the white smiling face (`U+263A`), the heavy
check mark (`U+2714`) and the black rightwards arrow (`U+27A1`). The
lexicon also contains characters that are not emoji at all (box-drawing
characters, the copyright and registered signs, the replacement
character), inherited from the tweets it was built from.

The grapheme-aware detection used throughout the package does not treat
these text-presentation code points as emoji, so a row whose only
"emoji" is one of them is not counted or scored – it behaves as if it
contained no emoji. This affects detection only, never the join: supply
the qualified form (the red heart `U+2764 U+FE0F`, say) and it resolves
to the same lexicon entry, because every lookup goes through a codepoint
key that ignores `U+FE0F`.
