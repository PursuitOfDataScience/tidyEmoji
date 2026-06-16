# Emoji category to unicode crosswalk

A table with one row per Unicode category, listing every emoji glyph in
that category as a single `|`-separated string.

## Usage

``` r
category_unicode_crosswalk
```

## Format

A data frame with two columns:

- category:

  The Unicode category (10 categories).

- unicodes:

  The emoji glyphs in the category, separated by `|`.

## Source

Derived from the `emojis` table of the emoji package; rebuilt by
`data-raw/crosswalks.R`.
