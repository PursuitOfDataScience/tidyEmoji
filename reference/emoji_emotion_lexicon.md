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
