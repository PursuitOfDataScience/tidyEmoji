# Apply an explicit emoji policy to a text column

`emoji_sanitize()` rewrites a text column under one named policy: keep
the emoji, delete them, spell them out as names or shortcodes, or
replace them with a placeholder token. The value is not new capability –
most of it exists across
[`emoji_to_text()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_to_text.md)
and the extraction verbs – but a single argument that says which choice
was made, so that "we replaced emoji with their Unicode names" becomes a
reproducibility statement rather than a forgotten line of
[`gsub()`](https://rdrr.io/r/base/grep.html).

## Usage

``` r
emoji_sanitize(
  data,
  text,
  policy = "keep",
  placeholder = "[emoji]",
  wrap = ":{x}:",
  presentation = "emoji",
  hidden = c("remove", "keep")
)
```

## Arguments

- data:

  A data frame or tibble containing a text column. Grouped data frames
  are accepted. The verbs that work a row at a time (adding columns, or
  keeping and expanding rows) carry the grouping through to their
  result, as
  [`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html)
  and
  [`dplyr::filter()`](https://dplyr.tidyverse.org/reference/filter.html)
  do. The verbs that pool across rows – the counts, the co-occurrence
  edge lists, the time series – warn that they ignore the grouping and
  return one corpus-wide answer.

- text:

  The text column to scan, supplied unquoted. Any atomic column is
  accepted and read as character, so a `factor` works and a numeric,
  `Date` or logical one simply contains no emoji. A list column – or a
  data-frame column – is refused rather than coerced, because coercing
  one deparses it and the emoji found would be in the code rather than
  in your data. What counts as an emoji is the same in every verb; see
  the *Detection* section of
  [tidyEmoji](https://pursuitofdatascience.github.io/tidyEmoji/reference/tidyEmoji-package.md)
  for the one case that surprises people, code points that are emoji
  only when they carry `U+FE0F`.

- policy:

  One of `"keep"` (default), `"strip"`, `"name"`, `"shortcode"` or
  `"placeholder"`.

- placeholder:

  Replacement token for `policy = "placeholder"`. Default `"[emoji]"`.
  Ignored, and not even validated, under the other four policies.

- wrap:

  Template for `policy = "shortcode"`, with `{x}` standing for the
  shortcode. Default `":{x}:"`. Ignored under the other four policies,
  as it is in
  [`emoji_to_text()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_to_text.md)
  for `format = "name"`.

- presentation:

  Which code points count as emoji: `"emoji"` (the default) or `"any"`.

  - `"emoji"` requires emoji presentation, so `U+2764 U+FE0F` is an
    emoji and the bare `U+2764` is not. This is the default and it will
    stay the default: widening it would silently recount every corpus
    already analysed.

  - `"any"` also reads the text-presentation spellings Unicode lists for
    an emoji (the bare heart, `U+263A`, `U+2714`, a keycap without its
    selector), because several keyboards emit them. It never reads the
    copyright, registered and trade-mark signs (`U+00A9`, `U+00AE`,
    `U+2122`), which are typography far more often than they are emoji.

  `"any"` only ever adds occurrences: everything `"emoji"` finds, it
  finds too, in the same place.
  [`emoji_coverage()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_coverage.md)
  reports how many it adds and how many of those a lexicon can score,
  which is the cost of the choice in one number. Every verb that counts,
  scores or rewrites the emoji in a text column takes this argument, so
  counts still agree across the package for whichever value you use. The
  flag verbs do not need it, since a flag has no text-presentation form.

- hidden:

  What to do with hidden payloads: `"remove"` (the default, under every
  policy) deletes every variation selector and tag character that
  carries no visible meaning, the code points
  [`emoji_hidden()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_hidden.md)
  reports; `"keep"` leaves them, which is what every version before
  0.7.0 did. See *Hidden payloads* below.

## Value

`data`, as a tibble, with the text column rewritten in place (same
column name). `NA` entries stay `NA`.

## Details

The policies:

- `"keep"` returns the text untouched. It is the honest baseline for an
  A/B comparison, and it means the policy argument can stay in the
  script even when the answer is "do nothing".

- `"strip"` deletes the emoji. Because deleting a glyph can leave two
  spaces where there was one, `strip` also collapses runs of spaces and
  tabs and trims whitespace off both ends, using Unicode's `White_Space`
  set as the rest of the package does, so a no-break or ideographic
  space left at an end goes too. It is the only policy that touches
  anything but the emoji. Removing a span makes its two neighbours
  adjacent, and on malformed input those two can spell an emoji the
  original text did not contain (a bare `U+2603` beside an orphan
  `U+FE0F` becomes the qualified snowman), so `strip` repeats until
  there is nothing left to remove. It is the one policy whose result is
  emoji-free whatever you hand it.

- `"name"` and `"shortcode"` substitute the Unicode name ("grinning
  face") or the GitHub-style alias (":grinning:"), exactly as
  [`emoji_to_text()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_to_text.md)
  does – including its rule that a glyph with no known name or alias is
  **left in place unchanged**. A glyph the catalogue does not list, such
  as a family with a skin tone (a sequence Unicode allows but does not
  recommend), is detected but cannot be named, so these two policies can
  return a column that still holds emoji. A ZWJ sequence the catalogue
  does not list is named by its parts, in order. `"strip"` never does.
  Neither does `"placeholder"`, unless the token you supply is itself
  emoji-forming: one that *is* an emoji survives by definition, and a
  lone combining character such as `U+FE0F` binds to whatever the
  removed glyph was standing next to. `name` is also the accessibility
  answer: it is what a screen reader announces.

- `"placeholder"` substitutes a fixed token, which keeps the *position*
  of an emoji as a feature while removing its identity. An empty
  `placeholder` is a deletion rather than a substitution, so it gets
  `"strip"`'s repeat pass (but not its whitespace tidying).

Replacements go exactly where the glyph was, with no padding, so a
grinning face glued to the end of a word yields `"wordgrinning face"`.
If your tokeniser needs whitespace around them, use `"placeholder"` with
a padded placeholder such as `" [emoji] "`.

`placeholder` and `wrap` belong to one policy each and are ignored by
the rest, silently and without being validated. That is deliberate
rather than an oversight: the point of this verb is that `policy` can be
a variable, so a script sweeping all five with one `placeholder =` set
would otherwise be warned at four fifths of its calls. Nothing is lost
either way, since an ignored argument cannot change the answer. Contrast
[`emoji_incongruity()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_incongruity.md)'s
`threshold`, which *does* warn when `method = "sign_flip"` makes it
inert: that one is a number the caller chose in order to change a
result, not a companion belonging to a branch.

## Which policies can be undone

The five policies are not five parallel options: they are a ladder of
information loss, and how far down it you step is invisible until you
try to put the emoji back after the model call.

|  |  |  |  |
|----|----|----|----|
| `policy` | `"great <U+1F600> work"` becomes | Restorable with [`text_to_emoji()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/text_to_emoji.md)? | What is lost |
| `"keep"` | `great <U+1F600> work` | yes | nothing |
| `"shortcode"` | `great :grinning: work` | **yes** | nothing |
| `"name"` | `great grinning face work` | no | the delimiters; the name is now ordinary words |
| `"placeholder"` | `great [emoji] work` | no | *which* emoji – the position survives |
| `"strip"` | `great work` | no | that there was an emoji at all |
| any, with `hidden = "remove"` | the same, less any hidden payload | no | the payload, by design |

So if the pipeline has to restore emoji downstream, `"shortcode"` is the
only policy that permits it, and it holds up on the awkward cases:
skin-tone modifiers, flags, ZWJ sequences and keycaps all come back.
Measured against the whole catalogue: for all 3972 emoji, in their
canonical (fully qualified) spelling, which is the spelling a keyboard
emits and text normally holds, **the round trip returns the original
text byte for byte, 100% of the time**.

**Every emoji has a shortcode since 0.7.0.** The 182 of Emoji 17.0 and
18.0, which the emoji package's aliases stop short of, take emojibase's
CLDR-style ones (`:distorted_face:`), so `"shortcode"` no longer leaves
them in the text as it did; no shortcode an earlier release wrote has
changed.

**That row of the table assumes the default `wrap`.** Restoring the text
means
[`text_to_emoji()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/text_to_emoji.md)
can find the token, and it reads exactly `:shortcode:` – a colon, the
alias, a colon. So `wrap` is part of the reversibility contract, not a
cosmetic choice:

- `wrap = ":{x}:"` (the default) restores the original text exactly.

- A `wrap` that decorates the token – `"[:{x}:]"`, `":{x}:!"` – brings
  the emoji back but leaves the decoration behind, so the emoji is
  restored and the text is not.

- A `wrap` with no `:token:` at all – `"{x}"`, `"<{x}>"`, `"@{x}@"`,
  `":{x}"` – restores nothing: the shortcode stays in the text as an
  ordinary word. This is the case to watch, because it fails silently.

- `wrap = "::{x}::"` is worse than either: the inner `:grinning:`
  matches, so the emoji comes back wrapped in the leftover colons
  (`:<U+1F600>:`) and a further round trip keeps adding to them.

Change `wrap` for readability by all means, but not on a column you
intend to restore.

**The default `wrap` also assumes something about the input text, and
this is the one failure mode that choosing it does not remove.**
[`text_to_emoji()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/text_to_emoji.md)
cannot tell a `:shortcode:` token this verb wrote from one the text
already held, so a corpus that arrives with literal shortcode tokens in
it gains an emoji where it had none. That is not a corner case: it is
how people type in the Slack, Discord and GitHub exports the
LLM-preprocessing workflow is aimed at.

- `"nice work :thumbsup:"` sanitises unchanged, and restores as
  `"nice work "` plus `U+1F44D`. Emoji count 0 before the round trip, 1
  after.

- It compounds with real emoji rather than replacing them:
  `"nice work :thumbsup:"` followed by `U+1F600` restores with two
  emoji.

- The damage is bounded at one pass. A second round trip changes
  nothing, because by then the token is a glyph.

The colon hazards
[`text_to_emoji()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/text_to_emoji.md)
*does* handle are the ones that are not shortcode-shaped: a clock time
(`"meet at 10:30"`) and a ratio (`"ratio 3:4"`) both survive untouched,
because the token it matches is a colon, alias characters, and a closing
colon. So the contract is precise: the round trip restores the original
text exactly when the only `:shortcode:`-shaped tokens in it are the
ones this verb wrote. If your text may hold real ones, compare
[`emoji_density()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_density.md)'s
`.emoji_n` before and after, which is the cheapest way to see the
inflation.

Unicode also lists shorter spellings of the same emoji, with the
`U+FE0F` presentation selectors omitted. Feed one of those in and the
round trip returns the *canonical* spelling instead: `U+270C` comes back
as `U+270C U+FE0F`. Across all 5055 spellings that have a shortcode that
is 79.9% byte-identical, and the remaining 20.1% differ by `U+FE0F`
alone, never by more. The emoji is always the same emoji, and every
tidyEmoji lookup treats the two spellings as one, so this matters only
if you are diffing raw bytes on text that had its selectors stripped
upstream.

`"placeholder"` keeps *where* but not *which*, which is enough to use
"an emoji was here" as a model feature and not enough to reconstruct the
text. `"name"` is the accessibility answer rather than the reversible
one – it is what a screen reader announces.

## Hidden payloads

A run of variation selectors after an emoji, or a string of Unicode tag
characters, is invisible in every renderer and survives copy and paste,
and each of those code points can carry a byte of a message to whatever
reads the text next. That is the best-documented emoji attack on
language model pipelines: smuggling a prompt this way evaded six
production guardrails in up to 100% of attempts (Hackett et al., 2025).
Since 0.7.0 every policy, `"keep"` included, deletes those code points
by default: `"keep"` means keep the emoji, and a payload is not part of
any emoji. The rules are exact, so a lone `U+FE0E` or `U+FE0F`, the
selectors of Japanese names, Unicode's standardized variants and the
England, Scotland and Wales flags all stay. Text with nothing hidden in
it comes back byte for byte as before; `hidden = "keep"` restores 0.6.0
exactly.
[`emoji_hidden()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_hidden.md)
reports what was there, and decodes it.

## Why a policy, and why written down

An emoji reaching a language model unexamined is a measurable risk
rather than a matter of taste, and three independent lines of work now
say so. Models read emoji in context poorly: on the EMODIS benchmark
even the strongest of them frequently fail to tell an emoji's meanings
apart when only subtle cues in the text distinguish them (Huang et al.,
2025). Emoji also move a model's safety behaviour: prompts that carry
toxic intent in emoji readily induce toxic generations across seven
mainstream models (Cui et al., 2025), and a 2026 evaluation of four
open-weight models found emoji-augmented adversarial prompts succeeding
against three of them, a weakness an evaluation using plain text prompts
does not measure (Gopinadh, 2026). None of these says which policy is
right for a given pipeline; all of them say the choice is worth
recording.

## References

Hackett W, Birch L, Trawicki S, Suri N, Garraghan P (2025). Bypassing
LLM Guardrails: An Empirical Analysis of Evasion Attacks against Prompt
Injection and Jailbreak Detection Systems. arXiv:2504.11168.

Huang J, Yu N, Yi X (2025). EMODIS: A Benchmark for Context-Dependent
Emoji Disambiguation in Large Language Models. arXiv:2511.07193.

Cui S, Feng X, Wang Y, Yang J, Zhang Z, Sikdar B, Wang H, et al. (2025).
When Smiley Turns Hostile: Interpreting How Emojis Trigger LLMs'
Toxicity. arXiv:2509.11141.

Gopinadh MPVS (2026). Are LLMs Safe Beyond Text: Do Emojis Expose Gaps
in Safety Evaluation. arXiv:2608.18164.

## See also

[`vignette("reversible-preprocessing", package = "tidyEmoji")`](https://pursuitofdatascience.github.io/tidyEmoji/articles/reversible-preprocessing.md)
runs this ladder end to end, including the round trip on skin tones,
flags, keycaps and ZWJ sequences;
[`emoji_token_cost()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_token_cost.md)
for what the emoji are costing you;
[`emoji_to_text()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_to_text.md)
for the name/shortcode rewrite on its own.

## Examples

``` r
df <- data.frame(text = c("ship it \U0001f680", "no emoji"))
emoji_sanitize(df, text, policy = "strip")
#> # A tibble: 2 × 1
#>   text    
#>   <chr>   
#> 1 ship it 
#> 2 no emoji
emoji_sanitize(df, text, policy = "name")
#> # A tibble: 2 × 1
#>   text          
#>   <chr>         
#> 1 ship it rocket
#> 2 no emoji      
emoji_sanitize(df, text, policy = "placeholder")
#> # A tibble: 2 × 1
#>   text           
#>   <chr>          
#> 1 ship it [emoji]
#> 2 no emoji       
```
