# Which Unicode emoji version does this build reflect?

`emoji_unicode_version()` reports the Unicode Emoji version of the
catalogue tidyEmoji detects and joins against. Anything newer than this
simply will not be recognised as an emoji.

## Usage

``` r
emoji_unicode_version()
```

## Value

A single string, such as `"18.0"`.

## Details

The catalogue is Unicode's own `emoji-test.txt`, bundled with the
package and rebuilt by `data-raw/crosswalks.R` when Unicode ships, so
this moves when you upgrade tidyEmoji. Until 0.5.0 the catalogue was the
one inside the emoji package, which stayed at Emoji 16.0 for two Unicode
releases. The version is read from the file's own `# Version:` header
when the data is built, not inferred from where it was downloaded:
Unicode serves the current file at an unversioned address, so the
address says nothing about what it held.
[`emoji_provenance()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_provenance.md)
adds the file's date.

The shortcodes and keywords still come from emoji, so a glyph newer than
that package's own catalogue is detected and named but has no shortcode
and no keywords.

## See also

[`emoji_provenance()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_provenance.md)
for the full provenance row;
[`emoji_unicode_releases()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_unicode_releases.md)
for release dates;
[`emoji_properties()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_properties.md)
for the version of each glyph.

## Examples

``` r
emoji_unicode_version()
#> [1] "18.0"
```
