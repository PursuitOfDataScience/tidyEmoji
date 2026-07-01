# Emoji name, unicode and category crosswalk

A table with one row per emoji *name*: each emoji glyph appears once for
every GitHub-style name it is known by, so a single unicode can occur on
several rows (for example the grinning face is both "grinning" and
"grinning_face").

## Usage

``` r
emoji_unicode_crosswalk
```

## Format

A data frame with four columns:

- emoji_name:

  The emoji name / shortcode (e.g. "grinning").

- unicode:

  The emoji glyph.

- emoji_category:

  The Unicode category the emoji belongs to.

- key:

  Codepoint-normalised key (U+FE0F stripped) for robust joining.

## Source

Derived from the `emojis` table of the emoji package; rebuilt by
`data-raw/crosswalks.R`.
