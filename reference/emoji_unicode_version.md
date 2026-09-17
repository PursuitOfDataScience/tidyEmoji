# Which Unicode emoji version does this build reflect?

`emoji_unicode_version()` reports the highest emoji version present in
the reference table tidyEmoji detects against, i.e. how current your
installed emoji package is. Anything newer than this simply will not be
recognised as an emoji.

## Usage

``` r
emoji_unicode_version()
```

## Value

A single string, `"16.0"` with emoji 16.0.0, or `NA` if the reference
table carries no usable version information. It reports the catalogue
you have installed rather than anything about tidyEmoji, so it moves
when you upgrade that package and not when you upgrade this one.

## See also

[`emoji_provenance()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_provenance.md)
for the full provenance row;
[`emoji_unicode_releases()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_unicode_releases.md)
for release dates.

## Examples

``` r
emoji_unicode_version()
#> [1] "16.0"
```
