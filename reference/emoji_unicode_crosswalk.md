# Emoji name, unicode and category crosswalk

A table with one row per (name, glyph) *pair*, not one row per name and
not one row per glyph. 5963 rows cover 4880 distinct names and 5055
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

The glyphs and categories come from Unicode's `emoji-test.txt`, the
catalogue
[`emoji_properties()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_properties.md)
reports, and the names from the GitHub-style aliases of the emoji
package, and, for the 182 emoji of Emoji 17.0 and 18.0 that emoji has
none for, from emojibase's CLDR-style shortcodes (since 0.7.0, which
added their 202 rows and changed no other); rebuilt by
`data-raw/crosswalks.R`.

## Details

- a glyph appears once for every GitHub-style name it is known by (the
  grinning face is both "grinning" and "grinning_face"), and

- a name appears once for every *spelling* of the emoji it names – 993
  do, because the qualified and unqualified forms of an emoji are
  separate rows that share one alias (`A_button_blood_type_` names both
  `U+1F170 U+FE0F` and the bare `U+1F170`).

So a join by `emoji_name` duplicates rows for those 993 names. Join on
`key` – which collapses the spellings – or
[`dplyr::distinct()`](https://dplyr.tidyverse.org/reference/distinct.html)
the columns you need first.
