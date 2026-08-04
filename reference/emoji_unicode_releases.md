# Unicode and Unicode Emoji release dates

`emoji_unicode_releases()` returns the publication date of each Unicode
Emoji (UTS \#51) data-file release, plus the earlier Unicode versions
that introduced emoji before the emoji series was numbered separately.
It is the lookup that turns the `version` carried by the emoji reference
table into a date, and hence into a time axis.

## Usage

``` r
emoji_unicode_releases()
```

## Value

A tibble with columns `version` (character, the normalised label with
any leading `E` removed), `version_num` (the same parsed as a number,
for ordering), `series` (`"emoji"` or `"unicode"`) and `release_date` (a
`Date`).

## Details

Two numbering series exist and both turn up in emoji reference data. The
Unicode Emoji series (`series = "emoji"`) runs 1.0, 2.0, ... 5.0 and
then jumps to 11.0 to line up with the Unicode version; the Unicode
series (`series = "unicode"`) covers the 6.0-10.0 releases that added
emoji before the alignment. The two do not collide, so `version` is a
unique key.

The table is kept in code rather than as a bundled `.rda`: it is a few
dozen rows, it changes only when Unicode ships, and keeping it beside
the verbs that use it means it can never drift out of sync with them.

## See also

[`emoji_version_profile()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_version_profile.md)
and
[`emoji_adoption_lag()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_adoption_lag.md),
which join to this table;
[`emoji_unicode_version()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_unicode_version.md)
for the version this build reflects.

## Examples

``` r
emoji_unicode_releases()
#> # A tibble: 23 × 4
#>    version version_num series  release_date
#>    <chr>         <dbl> <chr>   <date>      
#>  1 0.6             0.6 emoji   2010-10-11  
#>  2 0.7             0.7 emoji   2014-06-16  
#>  3 1.0             1   emoji   2015-06-09  
#>  4 2.0             2   emoji   2015-11-12  
#>  5 3.0             3   emoji   2016-06-21  
#>  6 4.0             4   emoji   2016-11-22  
#>  7 5.0             5   emoji   2017-06-20  
#>  8 6.0             6   unicode 2010-10-11  
#>  9 6.1             6.1 unicode 2012-01-31  
#> 10 7.0             7   unicode 2014-06-16  
#> # ℹ 13 more rows
```
