# Emoji name, unicode and category crosswalk

A table with one row per (name, glyph) *pair*, not one row per name and
not one row per glyph. 5761 rows cover 4698 distinct names and 4853
distinct glyphs, because the mapping is many-to-many in both directions:

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

## Details

- a glyph appears once for every GitHub-style name it is known by (the
  grinning face is both "grinning" and "grinning_face"), and

- a name appears once for every *spelling* of the emoji it names – 973
  do, because the qualified and unqualified forms of an emoji are
  separate rows that share one alias (`A_button_blood_type_` names both
  `U+1F170 U+FE0F` and the bare `U+1F170`).

So a join by `emoji_name` duplicates rows for those 973 names. Join on
`key` – which collapses the spellings – or
[`dplyr::distinct()`](https://dplyr.tidyverse.org/reference/distinct.html)
the columns you need first.
