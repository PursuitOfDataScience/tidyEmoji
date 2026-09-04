# Emoji emotion lexicon (EmoTag1200)

Human-annotated emotion-association scores (each from 0 to 1) for the
eight Plutchik emotions (anger, anticipation, disgust, fear, joy,
sadness, surprise, trust), for the 150 most popular Twitter emoji, from
EmoTag1200.

## Usage

``` r
emoji_emotion_lexicon
```

## Format

A data frame with one row per emoji and the columns:

- key:

  Codepoint-normalised key (U+FE0F stripped) for robust joining.

- emoji:

  The emoji glyph (unqualified form, as stored by the source).

- name:

  The emoji's Unicode name.

- anger, anticipation, disgust, fear, joy, sadness, surprise, trust:

  Emotion-association scores, each from 0 to 1.

## Source

Shoeb AAM, de Melo G (2020). EmoTag1200: Understanding the Association
between Emojis and Emotions. *EMNLP 2020*.
<https://aclanthology.org/2020.emnlp-main.720/>. Data from
<https://github.com/abushoeb/EmoTag>, released under the MIT licence.
Processed by `data-raw/emoji_emotion_lexicon.R`.

## How much of the catalogue this covers

**150 glyphs, about 4% of the distinct emoji tidyEmoji can detect**
(3790 distinct codepoint keys in the reference table of emoji 16.0.0;
see
[`emoji_provenance()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_provenance.md)
for the version you have). That is not a defect – EmoTag1200 is a
carefully annotated 150-glyph resource – but it is worth knowing
*before* concluding that a corpus carries no emotion: a modern corpus is
mostly post-2018 glyphs that no bundled lexicon has seen.
[`emoji_emotion()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_emotion.md)
reports this per row rather than hiding it: `.emoji_n_scored` is `0`
when a row has emoji the lexicon cannot score, and `NA` only when the
row has no emoji at all.
