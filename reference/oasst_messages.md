# OpenAssistant messages: a dated, multilingual example corpus

1,485 messages from OpenAssistant Conversations (OASST2): every eligible
message that carries an emoji (750) and as many emoji-free ones (735),
written between 2023-01-17 and 2023-10-30 in 17 languages, by people
asking (`"prompter"`, 508) and by people writing the assistant's replies
(`"assistant"`, 977). It is the example data of the vignettes and help
pages since 0.7.0, and the reaction tallies on the same messages are in
[oasst_reactions](https://pursuitofdatascience.github.io/tidyEmoji/reference/oasst_reactions.md).

## Usage

``` r
oasst_messages
```

## Format

A tibble with 1,485 rows and 6 columns:

- message_id:

  OASST2's identifier for the message.

- parent_id:

  The message this one replies to, so replies can be told from opening
  prompts (117 have `NA`). The parent need not be in the sample: 1,315
  rows reply to a message that is not.

- created_at:

  When the message was written, a `POSIXct` in UTC.

- role:

  `"prompter"` or `"assistant"`. Both are written by people; OASST2's
  model-written messages are excluded with the synthetic ones.

- lang:

  The language OASST2 records, as a BCP 47 tag (`"en"`, `"pt-BR"`).

- text:

  The message as written, line breaks included.

## Source

Kopf A, Kilcher Y, von Rutte D, Anagnostidis S, Tam ZR, Stevens K, et
al. (2023). OpenAssistant Conversations: Democratizing Large Language
Model Alignment. *NeurIPS 2023 Datasets and Benchmarks*.
<https://arxiv.org/abs/2304.07327>. Data from
<https://huggingface.co/datasets/OpenAssistant/oasst2>, file
`2023-11-05_oasst2_ready.messages.jsonl.gz` at revision
`179dd21fc55192153d94adb0e0ce8f69e222bf75`, released under the Apache
License 2.0, whose text `inst/LICENSE.note` reproduces. Processed by
`data-raw/oasst.R`, which rebuilds the sample offline from a committed
extract of the eligible messages.

## Details

Emoji are rare in real text, so the sample is stratified on them: about
half the rows carry one, where 1.03% of all OASST2 messages do. Figures
computed on it describe this sample, not OASST2, and not chat in
general.

## How the sample was drawn

From the 135,174 messages of the "ready" release, in this order:
messages marked deleted (4,376) and synthetic (0) were dropped; then
those whose largest detoxify score is 0.1 or more (2,092); those
matching a word-list screen for slurs (23); those holding an e-mail
address, a phone-number shape or a URL with a query string (1,021); and
those longer than 600 code points (36,614), so printed examples stay
readable. That left 91,048 messages, 751 of them carrying an emoji.

The toxicity scores and the word list are English-centred, and 107 of
the 751 emoji-bearing messages had no detoxify score at all (Portuguese,
Chinese, German, Japanese and Ukrainian among them). Each of those was
read in full before the data was committed, as was every row an example
or a vignette prints, and a message was to be removed if it was sexual,
hateful or harassing or held personal data the automatic screens missed:
one was, for describing the sexual abuse of minors.
`data-raw/oasst-read-out.csv` lists it with its rule.

The sample is every remaining emoji-bearing message and an equal number
of emoji-free ones, allocated across month by role by language in
proportion to the emoji-free messages and drawn with
`set.seed(20261106)`. "Carries an emoji" is the package's own detection
when the extract was built.

## See also

[oasst_reactions](https://pursuitofdatascience.github.io/tidyEmoji/reference/oasst_reactions.md)
for the tallies;
[`emoji_trend()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_trend.md)
and
[`emoji_from_counts()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_from_counts.md)
for the verbs that need what the old example corpus lacked, a date and a
tally.

## Examples

``` r
emoji_summary(oasst_messages, text)
#> # A tibble: 1 × 5
#>   n_with_emoji n_total n_orphan_components n_invalid_flags n_hidden
#>          <int>   <int>               <int>           <int>    <int>
#> 1          750    1485                   0               0        0
table(oasst_messages$role)
#> 
#> assistant  prompter 
#>       977       508 
```
