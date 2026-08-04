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

A single string such as `"15.1"`, or `NA` if the reference table carries
no usable version information.

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
