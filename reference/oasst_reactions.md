# Reaction tallies on the OpenAssistant messages

The reactions OASST2 records on the messages in
[oasst_messages](https://pursuitofdatascience.github.io/tidyEmoji/reference/oasst_messages.md),
in long form: 2,469 rows over 1,294 of the messages, one per message and
name, with the number of people who used it.

## Usage

``` r
oasst_reactions
```

## Format

A tibble with 2,469 rows and 3 columns:

- message_id:

  The message, as in
  [oasst_messages](https://pursuitofdatascience.github.io/tidyEmoji/reference/oasst_messages.md).

- reaction:

  The name OASST2 records.

- n:

  How many times it was used on the message, an integer.

## Source

As
[oasst_messages](https://pursuitofdatascience.github.io/tidyEmoji/reference/oasst_messages.md):
the `emojis` field of the same OASST2 file, Apache License 2.0,
processed by `data-raw/oasst.R`.

## Details

The names are OASST2's own, and they are realistically messy. `"+1"`
(2,323 uses), `"-1"` (802) and `"red_flag"` (48) are reactions, the
first two under GitHub's names. `"_skip_reply"` (1,365),
`"_skip_labeling"` (857) and `"_skip_ranking"` (396) are not: they are
the interface's skip actions, stored beside the reactions, and kept here
because a real tally holds such things and an analysis has to decide
what to do with them.
[`emoji_from_counts()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_from_counts.md)
refuses a name it cannot resolve, by name, rather than counting it as
nothing.

## See also

[`emoji_from_counts()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_from_counts.md),
which turns a tally into text the other verbs read.

## Examples

``` r
head(oasst_reactions)
#> # A tibble: 6 × 3
#>   message_id                           reaction     n
#>   <chr>                                <chr>    <int>
#> 1 c5d1ac81-3370-44f6-bed6-ed02a016bb72 -1           1
#> 2 d121645a-6d6e-488e-bc4a-6208f93109c7 +1           1
#> 3 d121645a-6d6e-488e-bc4a-6208f93109c7 -1           1
#> 4 e7aa0bcf-82af-4589-b903-4af455b058bf -1           1
#> 5 960f1b99-9433-41c0-abf1-a2331a4773ed +1           1
#> 6 960f1b99-9433-41c0-abf1-a2331a4773ed -1           9
# the reactions alone, as text every verb can read
votes <- oasst_reactions[oasst_reactions$reaction %in% c("+1", "-1"), ]
emoji_frequency(emoji_from_counts(votes, reaction, n, id = message_id), text)
#> # A tibble: 2 × 5
#>   emoji name        shortcode group             n
#>   <chr> <chr>       <chr>     <chr>         <int>
#> 1 👍    thumbs up   +1        People & Body  2323
#> 2 👎    thumbs down -1        People & Body   802
```
