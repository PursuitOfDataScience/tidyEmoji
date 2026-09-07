# tidyEmoji 0.4.0

This release delivers the first wave of the feature roadmap filed as
[issue #5](https://github.com/PursuitOfDataScience/tidyEmoji/issues/5):
the items that are cheap, research-grounded, and need no new dataset and no
new dependency. Most of them are recombinations of machinery the package
already had — the Novak lexicon's annotation counts, the reference table's
Unicode version column, the grapheme-aware locator — read out in a way no R
package exposed before.

## New features

### Interpretation risk (roadmap theme B)

Miller et al. (2016) found that readers of the *same* rendering disagree about
whether an emoji is positive, neutral or negative roughly a quarter of the
time. The bundled Emoji Sentiment Ranking keeps the raw
`negative`/`neutral`/`positive` annotation counts behind its collapsed score,
so that disagreement was already inside the package as an empirical
distribution. It is now a number.

* `emoji_ambiguity()` reports per-glyph annotation shares and one of four
  disagreement statistics — Shannon `entropy` (the default), `gini`,
  `neutral_share` or `ci_width` — with a rank over the whole lexicon.
* `emoji_risk()` is the per-row version: `.emoji_ambiguity_mean`,
  `.emoji_ambiguity_max` and `.emoji_n_ambiguous`.
* `emoji_flag_ambiguous()` is the content-QA shortlist: the emoji in *your*
  corpus most likely to be misread.
* `emoji_sentiment(se = TRUE)` adds `.emoji_sentiment_se`, so a glyph annotated
  eight times no longer carries the same authority as one annotated eight
  thousand times.

### Context (roadmap theme C)

* `emoji_context()` returns one row per emoji occurrence with a window of the
  surrounding text, in words or characters. All other emoji are blanked out of
  the window, and character offsets stay exact.
* `emoji_collocations()` aggregates those windows into an emoji-word table
  scored by pointwise mutual information, shaped like `widyr::pairwise_count()`
  output. Corpus-derived senses have neither the licence problem nor the
  staleness problem of an imported sense inventory.

### Time (roadmap theme H)

* `emoji_trend()` counts emoji per period (`"day"`, `"week"`, `"month"`,
  `"quarter"`, `"year"`) and returns a *complete* period-by-emoji grid, so a
  trend line does not silently skip its zeros.
* `emoji_turnover()` reports vocabulary churn between consecutive periods:
  `jaccard`, `n_new`, `n_lost`, `n_core`.
* `emoji_version_profile()` breaks a corpus down by the Unicode emoji version
  that introduced each glyph, and `emoji_adoption_lag()` compares first use in
  the corpus with the release date. Both come almost free from the `version`
  column the reference table already carries.
* `emoji_seasonality()` aggregates by month, weekday or hour, returning every
  level of the cycle including the empty ones, with fixed English labels so a
  script's output does not change with the machine that runs it.
* `emoji_unicode_releases()` is the version-to-release-date lookup behind the
  two verbs above. It is a function rather than a bundled dataset: at a few
  dozen rows it belongs beside the code that uses it.

### Text-emoji mismatch (roadmap theme E)

* `emoji_incongruity()` measures the signed gap between a row's text sentiment
  and its emoji sentiment — the sarcasm feature in NLP, the (in)congruence
  variable in marketing research. `emoji_congruence()` is the same engine under
  the marketing framing; `emoji_incongruity_profile()` reports which glyphs go
  against the grain of their host text.
* tidyEmoji still does not score text: you supply `text_score` from
  tidytext, sentimentr, vader or a model. Because those live
  on incompatible scales, `scale` has **no default** — you have to say how the
  two sides were made comparable.
* Rows with no scorable emoji get `NA`, never `0`, in every new column.

### Functional type (roadmap theme K)

* `as_emoji_type()`, `emoji_type()` and `emoji_faceness()` recode the Unicode
  group and subgroup into `face`, `gesture`, `person`, `nature`, `food`,
  `place`, `activity`, `object`, `symbol`, `flag` and `component`. The
  emotional (face) versus semantic (object) contrast is the key variable in the
  consumer-behaviour literature and is now a one-liner.

### Language-model plumbing (roadmap theme J)

* `emoji_sanitize()` applies one named policy — `"keep"`, `"strip"`, `"name"`,
  `"shortcode"` or `"placeholder"` — to a text column. The capability mostly
  existed; the value is an argument that shows up in a script diff and in a
  methods section.
* `emoji_token_cost()` reports exact `.emoji_bytes`, `.emoji_codepoints` and
  `.emoji_graphemes` plus a clearly-labelled `.emoji_token_estimate`, or the
  real count if you pass your own `tokenizer`.

### Provenance (roadmap theme M)

* `emoji_provenance()` puts every version an emoji result depends on in one
  row: tidyEmoji, the emoji package, the Unicode emoji version, the size
  of the detectable emoji set, and the lexicons.
* `emoji_unicode_version()` reports that Unicode version on its own.
* `inst/CITATION` now credits the package and the two lexicon papers users have
  to cite anyway.

## Improvements and fixes

This section is long because the release was audited exhaustively rather than
spot-checked, and both kinds of finding are recorded: changes you can observe,
and verifications that confirmed existing behaviour was already right. The
second kind is kept deliberately -- knowing that a figure was re-derived from
the data, or that a formula was checked against an independent implementation,
is worth as much to the next maintainer as knowing what moved.

Entries whose first sentence is **bold** are the ones where something was
actually wrong and got fixed -- in the package, in its documentation, or in a
test that was passing for the wrong reason. There are sixty-six of them, and
reading just those leads gives the release without the verification detail.
Not all sixty-six changed observable behaviour: several record a test that
could not have failed, or a figure the documentation quoted incorrectly, which
are worth the same prominence because both meant something was unverified.

* The whole of this release's polish was audited against the version it
  started from, by installing both side by side and comparing 57 verb calls
  over the bundled 2000-row corpus. **54 are byte-identical**, and the three
  that differ are exactly the three intended behaviour changes, in exactly the
  places they should be: `emoji_emotion() |> emoji_emotion_label()` gains the
  eight emotion columns and nothing else (every shared column identical, and
  the scores equal `emoji_emotion()`'s own); and
  `emoji_incongruity(scale = "rank")` and `"zscore"` change on precisely the
  373 scored rows, with `NA` placement untouched, `scale = "none"` and
  `emoji_congruence()` byte-identical, and the rank-scale mean gap now
  0 (-2.1e-17) where it had been -0.0042. Every guard, message and validation
  change in this release leaves valid input alone.

  The same comparison over 29 adversarial inputs -- list, matrix and
  data-frame columns, duplicated and missing column names, a wide frame, a
  non-finite score, `dd/mm/yyyy` dates, an unknown `measure`, an
  emotion-shaped `lexicon`, `NA` search queries -- shows **no guard was
  loosened**: nothing that was rejected before is accepted now. Five inputs
  that used to produce a plausible-looking result are refused (the list and
  data-frame text columns, a bare list to `emoji_tokens()`, a whole `dd/mm/yyyy`
  column, an unrecognised `measure`); two now warn and drop instead of
  answering from bad data; eight kept erroring but say something useful
  instead of surfacing dplyr's, tibble's or `match.arg()`'s internals; and
  twelve are unchanged in value, message and warning alike.

* **A duplicated column name silently resolved to the first column.** The
  bare-name fast path added earlier this release tested
  `nm %in% names(data)`, which is true even when the name appears twice, and
  `[[` then returns the first -- so `emoji_summary()` and `emoji_frequency()`
  answered from whichever column came first while the verbs that convert
  `data` to a tibble failed with tibble's own message instead.
  `dplyr::select()`, which that path replaced, had rejected the ambiguity for
  all of them. A data frame really can carry the name twice --
  `read.csv(check.names = FALSE)` on a sheet with repeated headers does it --
  and picking one of two columns unasked is a wrong answer that looks right.
  All ten verbs tried now report the ambiguity, naming the argument and the
  count, for every column argument.
* Checked that this release's type guards have not caught anything a caller
  might reasonably hold text in: `difftime`, `complex`, `AsIs`, `noquote`, a
  factor with an `NA` level and a custom-classed double all still work as a
  `text` column, and `difftime` is still refused as `time` or `text_score`
  with the type message rather than a coercion.
* Verified `emoji_context()`'s window *content*, which no test had checked.
  The earlier round proved the bounded-slice optimisation agrees with the
  package's own naive version -- but two implementations that cut the window
  in the same wrong place would agree just as well. It is now compared
  against a reference sharing no code with the package: every glyph span is
  masked to spaces, the two sides are split by a character-at-a-time
  whitespace splitter, and the nearest `window` tokens are taken. **5160
  windows over `window` values 0, 1, 2, 4 and 9 match exactly**, and the
  documented promise holds -- with three emoji in a row, the middle one's
  window reaches past its neighbours to real words and never quotes the
  neighbours. `emoji_collocations()`'s word list was checked the same way
  against an independent tokenisation (400 comparisons, no difference), along
  with each rule its documentation states: lower-cased, leading and trailing
  punctuation stripped but internal punctuation and digits kept, and a word
  counted once per occurrence however often it repeats in the window. No
  defect was found in either; both are now pinned.
* Pinned the version cluster's behaviour against a **future \pkg{emoji}
  release**, the one way this package can break without anything here
  changing. `emoji_version_profile()` and `emoji_adoption_lag()` read the
  introducing `version` out of the installed reference table and join it to a
  release-date table kept in tidyEmoji's own source; the day Unicode 18 ships,
  that label will not be in the table. `R CMD check` cannot reveal this,
  because it runs against today's \pkg{emoji}. Injecting `18.0`, the
  data-file spelling `E18.0`, an absurd `99.9` and a missing version now
  confirms all four degrade rather than fail: the glyph keeps its row, its
  `release_date` and `lag_days` are `NA` instead of invented, `share_tokens`
  still sums to 1, the other glyphs are untouched, and
  `emoji_unicode_version()` follows the new label. Also pinned the release
  table itself -- `version` unique across both numbering series, `version_num`
  equal to the parsed label (string ordering would put `10.0` before `9.0`),
  no missing dates, and within each series a later version never released
  earlier.
* Closed the gaps in the grouping contract. Grouping is what makes
  `group_by() |> verb() |> summarise()` work, and it is upheld by two separate
  mechanisms: `.emoji_as_tibble()` passing a `grouped_df` through untouched,
  and `.emoji_regroup()` re-deriving the indices for the three verbs that
  rewrite the text column. Only 13 row verbs were pinned; the seven omitted
  ones -- `emoji_emotion()`, `emoji_emotion_label()`, `emoji_incongruity()`,
  `emoji_congruence()`, `emoji_sanitize()`, `emoji_to_text()` and
  `text_to_emoji()`, which is *all three* of the rewriting verbs -- are now
  covered too, so a stray `ungroup()` cannot change semantics silently. The
  mirror case is pinned as well: `emoji_summary()`,
  `emoji_extract_unnest()` and `emoji_flag_ambiguous()` must *not* be grouped,
  because they do not return the caller's rows and so have no group column to
  carry. And `.emoji_regroup()` is now tested in the case it was written for,
  in its sharpest form -- grouped by the text column where
  `policy = "strip"` maps two distinct texts onto one, collapsing three groups
  into two and shifting every index. All four rewrites leave each group's
  indices pointing at rows that really carry its key, and are
  indistinguishable from regrouping from scratch. No defect was found; the
  behaviour was already right in all 22 verbs.

* **A `"bytes"`-encoded text column failed with R's message, not the
  package's.** A character vector whose `Encoding()` is `"bytes"` is a bag of
  bytes R refuses to read as characters: `nchar(type = "chars")`, `gsub()`,
  `tolower()` and `substr()` each stop on one. Emoji detection is built out of
  precisely those, so 22 verbs already failed on such a column -- but they
  failed with `"bytes encoding is not supported by this function"`, thrown
  from inside R, naming no argument, no column and no remedy. Strings arrive
  marked this way from `readBin()`/`rawToChar()` and from text decoded with
  the wrong encoding upstream. The shared text resolver now catches it, so all
  22 give one message that names the argument, the column, how many values
  carry the mark, and the fix. Coercing was rejected deliberately: a string is
  usually marked `"bytes"` *because* it is not valid UTF-8, so `enc2utf8()`
  cannot repair it and would substitute replacement characters. Only the
  caller knows what the bytes meant, which is why the message says `iconv()`
  and says why `enc2utf8()` will not do.
* The same mark on a string *argument* is now refused as well -- `sep`,
  `placeholder` and `query`, which reached `gsub()` and `tolower()` with R's
  message. `wrap` was the worst of them and the only one that did not error at
  all: `emoji_to_text(format = "shortcode")` pasted the template into the
  rewritten text, which marked the **output column** `"bytes"` too. The verb
  returned a perfectly ordinary-looking tibble whose text column would then
  stop the next thing that touched it, arbitrarily far from the cause. That
  `emoji_to_text()` never returns a bytes-encoded column is now a test in its
  own right. `latin1`- and unknown-marked text, and factors, are unaffected --
  they are readable, and the guard is only about the encoding R will not read.

* **The collation test had a field that asserted nothing.** The snapshot
  guarding "no ordered output depends on `LC_COLLATE`" compared
  `emoji_pairs()`'s output across locales -- but over a fixture whose every
  row held a single emoji, and both `emoji_pairs()` and
  `emoji_cooccurrence()` pair *within* a row. The field was `character(0)`,
  which compares equal to itself in every locale, so the ordering of those
  two verbs had never been tested. `collocs` was nearly as empty: its fixture
  was `paste("good", ...)`, so the word column was three copies of `"good"`
  and no permutation of it could differ either. Both now use fixtures that
  produce real output, and the test refuses any field that is empty *or
  constant* -- the two shapes that make a comparison vacuous.
* The same test only tried `C` and `en_US.UTF-8`, which order the fixture
  identically, so it could not have caught a collation bug even in a
  populated field. It now also runs under Danish, Czech and Estonian
  collation, which disagree with `C` about where a-ring, `ch` and o-tilde
  sort, and it *asserts* that the fixture words re-order under at least one
  locale it reached -- so a fixture that stops being collation-sensitive
  fails instead of passing quietly. Coverage went from 16 outputs to 31,
  adding `emoji_trend()`, `emoji_turnover()`, `emoji_seasonality()`,
  `emoji_cooccurrence()`, `emoji_tokens()`, `emoji_extract_unnest()`,
  `emoji_type()`, `emoji_version_profile()` and `emoji_adoption_lag()`. It
  runs faster than before despite that (8.9s to 3.9s): the old shape called
  `emoji_search("hand")` three times per locale and six other verbs twice.
* Documented why the head of `emoji_ambiguity()`'s ranking can show something
  that is not an emoji. The docs already explained the tie at `rank = 1` by
  annotation count, which is right as far as it goes -- but three of those
  five rows are box-drawing and dingbat characters, not emoji. The lexicon was
  built from 2015 tweets and 233 of its 969 rows are absent from the reference
  table, so no corpus this package analyses can yield them. They carry 6% of
  the lexicon's annotations, and 86% have fewer than 50, so the
  `n_annotations` filter the page already recommends removes 200 of the 233 as
  a side effect. Every figure is pinned twice, from the data and from the
  rendered Rd; the coverage figures on [emoji_sentiment_lexicon] (736 in the
  reference table, 233 not, 3790 distinct keys, "about 19%") were re-derived
  and all hold.

* **A non-numeric score column registered happily and then scored nothing.**
  `register_emoji_lexicon()` resolves the score column at registration
  precisely so a bad table fails there rather than later -- but it checked
  only that the column *existed*, not that it held numbers. A `score` column
  of text (which is what a stray `"NA"` or a decimal comma makes of a whole
  column) therefore registered without complaint, and at scoring time reached
  `mean()`, which returns `NA` with R's own "argument is not numeric or
  logical" warning. Meanwhile `.emoji_n_scored` still counted the emoji as
  scored, so the row claimed a score it did not have -- contradicting that
  column's documented meaning, where `0` is exactly "had emoji the lexicon
  could not score". Both the registration path and the bare-data-frame path
  now refuse it and say what to look for. A logical column still works, and a
  genuinely `NA` numeric score is still counted as unscored.
* **Two lexicon rows for one emoji let the row order pick the score.**
  Spellings that differ only by a variation selector share one code-point key,
  so a table listing both `U+2764` and `U+2764 U+FE0F` holds one emoji twice.
  The lookup took whichever came first: swapping two rows of the caller's own
  table changed `.emoji_score` from `0.5` to `-0.5`, silently -- the same
  failure as the duplicated column name fixed earlier this release. Identical
  scores are the normal case and still collapse quietly, and an `NA` beside a
  value is not a disagreement; only genuinely conflicting scores are refused,
  naming the key. Neither bundled lexicon has a duplicated key at all, which
  is now asserted so the guard cannot start reaching them.
* `by` is validated as a single string. It reaches `%in%`, so
  `by = c("emoji", "other")` surfaced R's own "the condition has length > 1"
  from inside `register_emoji_lexicon()` and `emoji_score()`, naming neither
  the argument nor the verb.
* Checked the suite the way a suite should be checked: by breaking the package
  and seeing whether it notices. Nine mutations were applied one at a time to
  the numeric and ordering core -- weakening `emoji_position()`'s
  short-text guard, making whitespace-only text score `NA` per token, dropping
  `emoji_dfm()`'s glyph tiebreaker, shifting its tf-idf denominator, moving
  the Monday the week buckets to, moving the month a quarter starts on,
  ordering `emoji_unicode_releases()` by version *string* instead of number,
  turning off `fixed = TRUE` in `emoji_search()`, and removing the
  `"bytes"`-encoding guard. **All nine were caught**, by 1 to 92 failing tests
  each; none survived. Three were caught by a single test apiece, which is the
  thin margin worth knowing about rather than a defect.
* Verified `emoji_context(unit = "char")`, the half of that verb an earlier
  round left alone. The word unit was checked against a reference sharing no
  code with the package; the character unit has its own bounded-slice
  optimisation and its own "enough characters after trimming" fallback, and
  neither had been checked against anything but itself. **4135 windows over
  `window` values 0, 1, 3, 7 and 25 match exactly**, including the doubling
  fallback that whitespace-heavy input triggers. Also pinned that a masked
  neighbour can pad a character window but can never appear in it.
* Tied together `top_n_emojis()`'s two naming branches, which had nothing
  connecting them. `emoji_name` comes from `emoji_frequency()`'s `shortcode`
  when `duplicated = FALSE` and from a many-to-many join onto
  `emoji_unicode_crosswalk` when `TRUE`, so a change to either could leave
  them disagreeing about what an emoji is called -- and only the expanded
  branch was exercised anywhere. Over a corpus holding every catalogued glyph,
  the single name is the *first* of the expanded names for all 4830 of them,
  and neither branch leaves a glyph nameless: 189 reference rows carry no
  alias, but canonicalisation matches on the codepoint key, so such a glyph
  borrows the alias of its other spelling. Also pinned that `n` cuts on
  distinct emoji rather than rows, so a glyph with several aliases cannot eat
  another glyph's slot, and that `n = 0` gives a typed zero-row tibble in both
  branches.
* Verified the declared `R (>= 4.1.0)` floor exactly rather than by
  inspection: every base-package function the code calls -- collected by
  walking the syntax tree of `R/` and `tests/`, 443 distinct call names --
  exists in a real R 4.1.0 installation. The only name that resolves on 4.4
  but not 4.1 is `%||%`, which entered base R in 4.4.0 and which this package
  has always defined for itself.
* **`emoji_turnover()` could not tell `new` from `lost`.** Mutation testing
  found this one: swapping `n_new` to compute `setdiff(a, b)` instead of
  `setdiff(b, a)` -- so that "new emoji" reports the *lost* count -- passed
  the entire suite. Two tests looked like they covered it and neither could.
  One asserts `n_new == 1` and `n_lost == 1`; the other checks each against
  set arithmetic done by hand, but over a fixture whose first period pair
  gains exactly one glyph and loses exactly one. Both numbers are 1, so no
  permutation of them is observable. The assertions were right; the fixtures
  had no teeth -- the same failure as the empty snapshot field fixed above,
  in a subtler form. There is now a deliberately asymmetric case (three
  glyphs arrive, none leaves), the reverse of it, an assertion that the
  fixture *can* distinguish the two, and the identity that fixes the
  direction: `n_new + n_core` is the later period's vocabulary and
  `n_lost + n_core` the earlier one's. The implementation was correct
  throughout; only the test was blind. Re-running the mutation now fails four
  assertions.
* **`emoji_provenance()` mis-described its own headline number.**
  `n_emoji` was documented as "the size of the detectable emoji set" but
  reports `nrow(emoji_reference())` -- rows of the reference table, which are
  *spellings*. With \pkg{emoji} 16.0.0 that is 5042 rows carrying only 3790
  distinct code-point keys, because an emoji whose presentation can be
  selected appears both with and without `U+FE0F`, and 212 of the 5042 are
  not detectable in text as written. This is a function built to be pasted
  into a methods section, so "5042 detectable emoji" is a number that would
  have gone into papers overstating the vocabulary by 1252. The value is
  unchanged -- it is the table's size, which is the right thing for a
  provenance row to record -- and the documentation now names the quantity,
  points at `length(unique(emoji_reference()$key))` for the count of distinct
  emoji, and notes that the lexicon strings count rows the same way. Also
  established the fact that makes the overstatement harmless rather than a
  defect: no emoji is lost to an undetectable spelling, because every one of
  the 3790 keys is reachable through at least one spelling that is detected.
* **`emoji_version_profile()` could not tell type shares from token shares.**
  Found by extending round 79's search from one column pair to every pair a
  verb could swap: exchanging the expressions behind `share_types` and
  `share_tokens` passed the whole suite. The only assertion either column
  ever had was `sum(share_tokens) == 1` -- and *both* columns sum to 1, so
  the swap was invisible. There is now a fixture where the two genuinely
  differ (one glyph three times, another once, so `share_types` is 0.5 where
  `share_tokens` is 0.75), each column checked against its own count, and an
  assertion that the fixture separates them. Re-running the swap fails four
  assertions. As with `n_new`/`n_lost`, the implementation was right and only
  the test was blind.
* The same sweep exchanged nine other pairs -- `.emoji_first`/`.emoji_last`,
  `.emoji_per_char`/`.emoji_per_token`, `.emoji_only`'s polarity,
  `.emoji_n_typed`/`.emoji_n_face`, `n_types`/`n_tokens`,
  `release_date`/`first_seen`, `n_texts`/`n_with_emoji`, `p_neg`/`p_pos` and
  `emoji_summary()`'s two counts -- and every one was caught. The
  seasonality pair was the closest call: its own fixture reads 2 for both
  columns, and the month where they differ is asserted for neither, but two
  unrelated tests fail on the swap anyway. It now has a fixture that
  separates them directly rather than relying on that.
* Audited every guard in the package by shadowing `stop` inside its own
  namespace, which makes one suite run log every error the tests actually
  trigger. 53 of the 54 guards fired; the one that never did was
  `emoji_sentiment()`'s fallback for a lexicon it cannot use, and reaching it
  exposed two message defects rather than one.
* **`emoji_sentiment(lexicon = "emotag1200")` said the name was invalid.** The
  bundled emotion lexicon is the only input that reaches that guard, and the
  message was "`lexicon` must be 'novak2015', a registered lexicon, or a data
  frame" -- telling a user whose name is a perfectly valid bundled lexicon
  that it is not, and pointing nowhere. It now says the lexicon is an emotion
  lexicon, that this verb needs one score per emoji, and names both
  [emoji_emotion()] for the per-emotion profile and
  `emoji_score(lexicon = ...)` for the mean over its dimensions -- the answer
  `emoji_score()` already gave its own callers. `emoji_emotion()`'s reciprocal
  case now mirrors it instead of only listing what it wants.
* **A guard offered an option it rejects.** `.emoji_lexicon_lookup()`'s type
  message read "`lexicon` must be a name (string), a data frame, or NULL for
  the default" -- and `NULL` fails that very guard, since `is.character(NULL)`
  is `FALSE`. No verb accepts or documents `lexicon = NULL`. The message now
  describes what is taken and names what was passed. Tightening it to a
  *single* name also fixed two messages that were R's rather than the
  package's: a length-2 name reached `%in%` inside an `if` and produced "the
  condition has length > 1", `character(0)` produced "argument is of length
  zero", and `NA_character_` fell through to a misleading "Unknown lexicon
  `NA`".
* Two guards remain that no test can reach, and deliberately so: the final
  `else` in each of `emoji_sentiment()` and `emoji_emotion()`.
  `.emoji_lexicon_lookup()` returns one of four shapes -- a data frame, or a
  record of type sentiment, emotion or custom -- and both verbs now handle all
  four, so those branches are unreachable defence against a fifth rather than
  untested behaviour.

* **The deprecated `duplicated_unicode` was more permissive than its
  replacement, and silently so.** It converted with
  `isTRUE(x) || identical(x, "yes")`, which collapses everything it does not
  recognise to `FALSE`. So `duplicated_unicode = "TRUE"` and
  `duplicated_unicode = 1` -- both entirely plausible for an argument that
  once took a string -- returned the *opposite* of what was asked, without a
  word, while `NA`, `"Yes"`, `character(0)` and a length-2 vector all passed
  unnoticed too. The current `duplicated` rejects every one of them through
  `.emoji_check_flag()`, so migrating *to* the deprecated spelling was a
  downgrade in safety. It now accepts exactly the four values it ever meant --
  `TRUE`, `FALSE`, `"yes"`, `"no"` -- each still giving what the modern
  spelling gives, and errors on anything else naming the replacement. Found by
  extending the guard audit to warnings: both bare `warning()` sites fire in
  the suite, and probing the deprecation surface instead turned this up.

* **Fifteen enum arguments answered a typo by naming a variable the caller
  never wrote.** `match.arg()` reports its own formal, so
  `emoji_context(unit = "words")` said *"'arg' should be one of "word",
  "char""* and `emoji_sanitize(policy = c("keep", "strip"))` said *"'arg'
  must be of length 1"*. `emoji_turnover()` had already been given a
  hand-rolled check for precisely this, with a comment saying it exists to
  name `measure` "rather than match.arg()'s own `'arg'`" -- and the fix was
  never carried to the other fifteen call sites, the same
  written-where-noticed-and-never-grepped pattern that left seven aggregators
  without a grouped-input guard in 0.3.0. They now share
  `.emoji_match_arg()`: `unit`, `policy`, `format`, `weighting`, `period`,
  `by` (twice), `measure` (five verbs), `method`, `where` and `scale` all name
  themselves and list their options.
* That conversion changes no accepted value. `match.arg()`'s behaviours are
  preserved deliberately and pinned: a value identical to the whole choice
  vector still means "no value supplied" and takes the first (which is why
  `emoji_context(unit = c("word", "char"))` is accepted and
  `emoji_sanitize(policy = c("keep", "strip"))` is not), exact matches win,
  and unambiguous prefixes still resolve, so `by = "mon"` keeps working while
  an ambiguous one is refused rather than guessed. The accept/reject matrix
  over full values, prefixes, wrong case, unknown values and length-2 vectors
  is unchanged across all fifteen.
* Converting them meant writing each choice set at the call site, since
  `match.arg(x)` reads it from the formal and a helper cannot. That is the one
  risk the change introduces, so a test now derives every choice set from the
  function's own formals and requires the error message to list exactly it --
  no more, no fewer. (`emoji_incongruity()`'s `scale` is deliberately
  defaultless, so it has no formal to derive from and is covered by the
  message test instead.)

* Closed the last gap in the grouping story. `.emoji_warn_grouped()` exists
  because "silently ignoring a grouping turns a per-group question into a
  global one", and an earlier round pinned which verbs keep a grouping and
  which drop it -- but not whether the droppers *say so*. Three do not:
  `emoji_ngrams()`, `emoji_extract_unnest()` and `emoji_context()` discard the
  grouping, and the grouping column with it, without a word. All three are
  defensible, and for a reason worth stating: each returns `.row_number`
  instead of the caller's columns, and none of them pools rows, so there is no
  per-group answer being quietly globalised -- unlike the thirteen verbs that
  do pool and therefore warn. That distinction was recorded nowhere. Of 37
  help pages exactly two mentioned grouping, both promising it is kept. All
  four reshapers now say which side they are on, and point at `.row_number`
  as the way to join your columns back.
* The three-way classification is now a contract rather than an accident:
  every data-first verb must either keep the grouping (and the column it
  names), or warn and ignore it, or be one of the three named reshapers that
  return `.row_number` and none of the caller's columns. The silent set is
  asserted to be exactly those three, so a new verb cannot join it by
  accident; both other groups are asserted non-empty so the classification
  cannot go vacuous; and a verb that warns is required *not* to return the
  grouping, which would be the confusing middle case of warning about
  something it went on to keep.

* Verified the statistical core against the raw annotation counts rather than
  against itself, since these are numbers that reach papers. All four
  ambiguity measures recompute exactly over all 969 rows -- Shannon entropy in
  nats with `0 log 0` taken as 0, Gini impurity, the neutral share, and the
  standard error from `Var(X) = E[X^2] - E[X]^2` for `X` in `{-1, 0, 1}` --
  and every documented figure on the page holds: the median glyph has 18
  annotations, 69.0% have fewer than 50, 11 of the top 20 do, the five rows
  tied at `rank = 1` carry 3, 3, 3, 9 and 15, and the entropy/count Spearman
  correlation is 0.556, which is the "0.56" the page quotes. `gini`'s
  documented 2/3 ceiling is now asserted alongside `entropy`'s `log(3)` one,
  which already was.
* Pinned the invariant that makes `emoji_sentiment(se = TRUE)` meaningful: the
  score map and the standard-error map cover exactly the same emoji, with no
  `NA` in either. The row mean drops glyphs the *score* map cannot score and
  the standard error drops glyphs the *se* map cannot, so if those two sets
  ever diverged the reported error would be the error of a mean nobody
  computed. `.emoji_n_scored` is now checked to equal the standard error's own
  denominator over a many-glyph corpus, and the propagation
  (`sqrt(sum(se^2)) / n_scored`) re-derived independently. Nothing was wrong;
  nothing had been checking.

* `emoji_type()`'s `.emoji_type` is `NA` for two different reasons -- a row
  with no emoji, and a row whose every emoji the recode cannot type -- and the
  page documented only the first. The recode maps the ten Unicode groups the
  catalogue currently uses and starts from `NA`, so a glyph in a group added
  to Unicode after your \pkg{emoji} package was built has no type. It is the
  same conflation [emoji_categorize()] already describes for
  `.emoji_category`, and the fix is the same: say both, and say how to tell
  them apart -- [emoji_faceness()]'s `.emoji_n_typed` is `NA` when the row had
  no emoji and `0` when it had emoji that could not be typed.
* Pinned the recode's coverage and its behaviour on the untypable path.
  Nothing falls through today: all 5042 catalogue rows type, every type
  produced is one of the eleven declared levels, and all eleven are reachable
  so none is dead. An unknown group yields `NA` rather than erroring or
  landing silently in a catch-all. Forcing a glyph untyped confirms the rest
  of the contract holds around it: the row keeps its other emoji's type
  instead of being dropped, `.emoji_n` still counts the glyph because it is
  still an emoji, `.emoji_n_typed` falls to match, and `.emoji_faceness` is
  the share among *typable* emoji -- `NA` rather than a division by zero when
  none of them is.

* Swept the "`NA` for two reasons" class across every verb instead of meeting
  it one at a time. Over a fixture holding all three causes -- a row with no
  emoji, a row whose emoji the lexicon or the recode cannot use, and an `NA`
  text -- the design turns out uniform and sound: every *answer* column is
  `NA` for all three, and every *count* column (`.emoji_n_scored`,
  `.emoji_n_typed`, `.emoji_n_ambiguous`) is `0` for "had emoji I could not
  use" and `NA` for "had no emoji". That is the contract
  [emoji_sentiment()] states, and [emoji_score()], [emoji_emotion()] and
  [emoji_risk()] each restate it. Two verbs carrying the same count column
  never said it: [emoji_faceness()] and [emoji_incongruity()]. Both do now,
  and the whole pattern is pinned rather than left as a coincidence of six
  separate implementations.
* **A documentation-pinning helper reported gaps that did not exist.** Rd
  prose is line-wrapped, so a sentence written as one line in the roxygen
  source arrives from `tools::Rd_db()` with a newline in the middle -- and a
  `fixed = TRUE` match for that sentence fails. Three of this round's own
  assertions failed exactly that way, on pages whose wording was already
  correct. The test helper gained `rd_flat()`, which collapses whitespace
  first, and the thirteen existing assertions that matched a multi-word phrase
  against unflattened text were converted to it. None of them was failing --
  each passed only because its phrase happened not to straddle a break, so any
  edit to the surrounding prose could have turned a correct page into a red
  test. The pass count is unchanged by the conversion, which is the point.

* **The suite's dependency on one \pkg{emoji} release was undeclared and
  unexplained.** About seventy counts derived from the catalogue are pinned
  here -- 5042 rows, 3790 distinct keys, 969 lexicon rows, 736/233, 212
  undetectable spellings, 1252 carrying `U+FE0F`, 216, 200 -- deliberately,
  because the documentation quotes them and the pinning is what catches
  doc-vs-data drift. But nothing recorded which release they came from and
  nothing checked it, so a new Unicode version would have surfaced as dozens
  of unrelated-looking failures with no statement of the cause, plus four help
  pages quietly naming a release the user does not have. There is now a single
  constant, a canary test that fails loudly and says exactly which figures
  need re-deriving, and an assertion that no help page names a *different*
  release. Simulating the update confirms three tests fail, all three named so
  the cause is legible, rather than seventy that are not.
* Declared `emoji (>= 16.0.0)`, which had no version floor at all. The other
  floors in `DESCRIPTION` are keyed to *arguments* the code calls, which is
  why \pkg{emoji} was not among them -- tidyEmoji reads its data, not its
  functions. The reason it needs one is different and just as real: every
  catalogue figure in the documentation describes a single release, and an
  older \pkg{emoji} has fewer rows, so those figures would simply be wrong.
  The floor, the version the help pages name and the pinned counts are now
  governed by one constant and asserted to agree.

* **`cran-comments.md` asserted something a reviewer could test and find
  false.** Its explanation of the one "possibly invalid URL" note said "The
  site itself is up: `curlGetHeaders(url, verify = FALSE)` returns `200`".
  That was true when written and is not now: the redirect target refuses TCP
  connections outright, with or without TLS verification, so the claim would
  not reproduce for anyone checking it. The passage now separates what the
  package can vouch for from what it cannot. The documented URL is healthy and
  that is the part that matters -- `https://hdl.handle.net/11356/1048` returns
  `HTTP/2 302` to `https://www.clarin.si/repository/xmlui/handle/11356/1048`,
  verified again for this release -- and the note describes a third-party
  CLARIN.SI host reached only by following that redirect. Both observed
  failure modes are recorded, the original certificate-chain one and the
  present timeout, precisely because they differ: the point is that the
  failure is not the package's and not stable enough to characterise. No claim
  is made about the target's availability.
* Re-checked every other URL in the package over the network: the two
  citations, the EmoTag repository, the pkgdown site and its introduction
  article, the issue tracker, the CRAN page and the three badges all return
  `200`, and only `doi.org` and the CRAN page redirect (both to their expected
  canonical targets). The `t.co` links the URL sweep turns up are rows of
  `vignettes/ata_tweets.csv`, not documentation, and are not fetched.
* Added the offline half as a test, since the network half cannot run on CRAN:
  every URL in the help pages and `DESCRIPTION` must be well formed -- `https`,
  no whitespace, no stray backtick or quote swept in from the surrounding
  markup, no trailing punctuation, and a parseable host and path. That is the
  class of defect that turns a working link into a reported one.

* **A second stale claim in `cran-comments.md`.** It said "Two tests skip: one
  gated on `readr (>= 2.0.0)` ... and one `skip_on_cran()` maintenance check"
  -- written when the suite was much smaller, and describing a suite that no
  longer exists: there are now seven `skip_on_cran()` tests. The passage
  reports the re-measured inventory and names all seven, marks the R 4.1.0
  figure as history rather than a current measurement (that tree cannot be
  rebuilt here, so asserting a fresh number would be inventing one), and
  explains why a tarball check skips three more than a source check -- they
  read `README.Rmd`, the `R/` tree and the vignette corpus, none of which a
  tarball carries.
* The rest of the file was re-verified rather than trusted. The marked-UTF-8
  breakdown is exact -- `emoji_unicode_crosswalk$unicode` 5761,
  `emoji_sentiment_lexicon$emoji` 969, `emoji_emotion_lexicon$emoji` 150,
  `category_unicode_crosswalk$unicodes` 10, summing to the 6890 it quotes --
  and no other column in any bundled dataset carries a marked string, as it
  claims. Against a live CRAN index: still no reverse dependencies, the
  published version is still 0.3.0, and \pkg{emoji} is still 16.0.0, which
  confirms the version floor added above is satisfiable and that the
  documented catalogue figures describe the release CRAN currently ships. The
  package count was refreshed from 24,744 to 24,748.
* Those figures are now derived in a test rather than asserted in prose, so
  they cannot drift again: the skip count, each component of the UTF-8
  breakdown and their total, the claim that no non-glyph column is marked, and
  the licence. Writing it caught its own bug first -- counting occurrences of
  the string `skip_on_cran()` in the test sources returns nine, because the
  literal appears in the counting code and in comments. It counts lines that
  *are* the call, and the runtime skip count confirms the figure independently.

* `README.md` is knitted from `README.Rmd`, so every `#>` line in it is output
  the package produced at some past moment. An existing test compares the two
  files' *prose*, which catches an edit made to `README.md` instead of to its
  source -- but not the likelier rot: prose and code both untouched while the
  package's output moves underneath them. This release changed several
  messages and added columns, so it was worth checking. **It had not gone
  stale** -- a fresh `github_document` render is byte-identical to the shipped
  file -- but nothing was checking, and now something does.
* That test compares the `#>` lines rather than the whole render, deliberately.
  The prose is re-wrapped by pandoc, whose line breaking differs between
  versions, so diffing whole files would fail on a different pandoc even when
  the README is perfectly current. Three cosmetic markers are normalised for
  the same reason: testthat forces `cli.unicode = FALSE`, so pillar decorates
  its tibbles in ASCII (`x`, `~`, `i`) where a maintainer's render uses
  Unicode (`\u00d7`, `\u2026`, `\u2139`). Each was found by running the
  comparison and reading what differed rather than by guessing. Everything
  that can actually go stale -- row and column counts, column names, values --
  is compared byte for byte.

* Fixed a loop in last round's own new test that iterated zero times. Its
  "no non-glyph column carries a marked string" check ran over a hand-written
  list of datasets that included `emoji_tweets` -- which is the deprecated
  synonym for [emoji_filter()], a *function*, whose `names()` is empty. That
  entry therefore asserted nothing, the same vacuity that left
  `emoji_pairs()`'s collation untested for a release. The list is now derived
  from `utils::data()`, so it is exactly the four datasets the package ships
  and a fifth would be covered automatically, and the number of character
  columns visited is pinned at 13 rather than bounded below -- a new one fires
  the test and has to be classified as a glyph column or not.
* Measured where the check's time goes, since this release's suite has grown
  by roughly 2,100 assertions. `R CMD check --as-cran` is 158s of CPU: 100s
  tests, 12s re-building the vignette, 7s incoming feasibility (its 143s of
  wall time is network, not compute). Inside the suite no single test
  dominates -- the slowest is 4.5s and 21 tests over a second account for 64%
  of the total -- so there is nothing pathological to trim, and the whole
  check sits comfortably inside CRAN's per-flavour budget.

* Audited the suite for assertions that cannot fail, since the last two rounds
  each found a defect in a test rather than in the package. Two sweeps, both
  clean. Comparing every block's `expect_*` count in its source against the
  number it actually executes at runtime found **one** shortfall across all
  478 blocks, and that one is a genuine either/or: the `tolower()` audit
  asserts against the `R/` sources when they are present and against the
  installed namespace when they are not, so exactly one of its two assertions
  runs. Scanning for assertions whose two operands are syntactically identical
  -- `expect_equal(x, x)`, `expect_true(TRUE)` -- found none.
* The second sweep is cheap and the test sources ship, so it is now a test
  rather than a one-off: no assertion in the suite may compare something to
  itself, and every `test_that` block must contain at least one expectation
  (testthat warns about an empty block but does not fail, which is easy to
  miss in a suite this size). Both were verified by injecting the defects they
  look for and confirming each fires.

* Added metamorphic tests -- properties that must hold *between* related
  inputs. They catch a class unit tests cannot, because they need no known
  answer: a verb can be wrong in a way no fixture reveals and still be caught
  by "these two corpora must agree". Four families, all of which the package
  already satisfied:
  **additivity** (every glyph's count over a concatenated corpus is its count
  in the parts, and `emoji_summary()`'s two counters add);
  **scale invariance** (doubling every row doubles `emoji_frequency()`,
  `emoji_pairs()` and `n_tokens` exactly, while `share_types`, `share_tokens`
  and `emoji_collocations()`'s PMI -- all ratios -- do not move at all);
  **padding invariance** (adding emoji-free rows leaves `emoji_frequency()`,
  `emoji_pairs()`, `top_n_emojis()` and the version profile *identical*, and
  moves only the `n_total` those rows belong to); and
  **row independence**.
* Row independence is the sharpest of the four, and it is now a contract: for
  thirteen row verbs, `verb(data)[i, ]` must equal `verb(data[i, ])`. Exactly
  one row verb is allowed to break it -- `emoji_incongruity(scale = "rank")`,
  whose whole purpose is to map each score to its percentile *within the
  corpus* -- and the test requires it to differ, so that if rank scaling ever
  quietly became `scale = "none"` the suite would say so. Verified by
  injecting a corpus coupling into `emoji_ratio()` (dividing by the corpus
  maximum) and confirming the test fails.

* Extended the same four families to the calendar arithmetic and to
  `emoji_dfm()`. Translation invariance is a strong property for a cycle, and
  a bucketing bug would show up as a shift leaking into the counts: a whole
  number of years cannot move a month cycle, a whole number of weeks cannot
  move a weekday cycle, and in a zone without DST whole days of seconds
  cannot move an hour cycle. `emoji_trend()` keeps its counts and shifts every
  period by one constant offset; `emoji_turnover()`, which compares periods to
  each other, is unmoved entirely. None of the four time verbs depends on the
  order of the rows.
* Pinned the DST case as behaviour rather than leaving it implicit. Adding
  86400 seconds twice across spring forward is *not* adding two calendar days,
  so the displayed hours move by one and the cycle moves with them -- correct,
  because the verb buckets by the timestamp's own zone as documented. The
  test asserts the buckets *are* the displayed hours on both sides of the
  shift, and that the emoji total is conserved across it. (That area turned
  out to be well defended already: injecting a UTC-instead-of-local hour read
  fails six tests.)
* `emoji_dfm()` conserves its cells: aggregating rows into documents with
  `doc_id` redistributes them without creating any, the total equals
  `emoji_frequency()`'s, permuting rows permutes the matrix rows identically,
  and duplicating the corpus leaves the first copy's rows untouched -- tf-idf
  included, since `N` and `df` both double and `log(N / df)` cancels.

* Checked the session cache, which nothing had examined. The package memoises
  six things -- the reference table, its key set, the sentiment and emotion
  maps, the ambiguity table and the type map -- plus the user-writable lexicon
  registry. A memoised accessor has a failure mode no other test could see:
  computing one value, storing another, and so answering differently the first
  time than afterwards. All six now assert that the first call equals the
  second and third with the slot cleared beforehand, and that the call
  actually populates its slot, so the memo is real rather than decorative.
  Clearing a derived slot is safe because each repopulates from a source that
  cannot change within a session.
* The registry is the one slot a caller can rewrite, so it gets a coherence
  check: registering a second table under a name already used must replace the
  first rather than be shadowed by it, `emoji_lexicons()` must list the name
  once and report the new row count, and re-registering with a *different*
  glyph column must still resolve -- which it does, because
  `register_emoji_lexicon()` stores a computed `key` column. Verified the
  whole guard by making `emoji_reference()` memoise a table one row shorter
  than the one it returns; the new test fails.

* Verified the pkgdown reference index, since a new exported verb that nobody
  adds to `_pkgdown.yml` breaks `pkgdown::build_site()` with "topics missing
  from index" -- after the release, on someone else's machine.
  `pkgdown::check_pkgdown()` reports no problems: all 51 help topics are
  reachable. A hand-rolled version of that check flagged two entries the real
  one accepts, because an alias counts as covering its topic (`emoji_tweets`
  lives on `emoji_filter`'s page) and the package-level doc is excluded by
  design -- asking the tool rather than reimplementing its rules was the
  difference between two false alarms and a clean answer.
* That check is deliberately *not* in the test suite. Adding it raised a
  second `R CMD check` WARNING -- "'::' or ':::' import not declared from
  'pkgdown'" -- and the only way to clear it is to declare \pkg{pkgdown} in
  `Suggests`, which would make every CRAN check machine install a heavy
  dependency for a test that can never run there: `_pkgdown.yml` is
  build-ignored, so the test would skip in the tarball every time. The site
  index is verified here instead, and `build_site()` catches a regression on
  the first run after one.
* The `cran-comments.md` skip-count assertion no longer hardcodes the number
  in two places. It counts the `skip_on_cran()` call sites and derives the
  word the file must contain, so adding a skipped test forces the submission
  notes to be updated -- which is the point of the coupling -- without also
  forcing an edit to the test.

* The missing-column message added earlier this release listed every column in
  `data`, which is the caller's data and can be wide. A 500-column frame
  produced a **5074-character** error and a 40-column survey export 665 --
  burying the one name that is wrong behind the hundreds that are not -- and a
  frame with no columns at all trailed off as `Available: .`. Five names are
  now listed and the rest counted (`and 495 more`), so the message is 84-118
  characters whatever the data looks like, and a frame with no columns says so.
* A test pins that `?register_emoji_lexicon`'s example is the only one that
  registers a lexicon. `R CMD check` runs every example in one session, so a
  registration is visible to every topic sorting after it, and
  `emoji_lexicons()` reports what is registered -- today that verb sorts before
  `register_emoji_lexicon()` and the printed output is unaffected, which is
  alphabetical luck rather than design. Running all 46 topics' examples
  forward and in reverse also errors nowhere, so nothing else depends on the
  order.

* `?emoji_pairs` now says what `doc_id` costs. The result has a row per pair,
  so it grows with the *square* of the distinct emoji in a document -- a
  conversation or a day is cheap, pooling a whole corpus under one id is not.
  Measured: 800 distinct emoji in one document is 319,600 pairs and 3.5s, and
  the bundled corpus pooled into a single document (187 distinct emoji) is
  17,391 pairs in 0.27s. The behaviour is inherent to the question rather than
  a defect, but the shape of the cost was not written down.
* `emoji_incongruity_profile()`'s statistics are now derived independently in
  the tests -- the last formula in the package that no test computed for
  itself. `n`, `mean_incongruity`, `sd_incongruity` and `n_flips` all match
  crediting every glyph in a row with that row's gap, across all three
  `scale` values, along with `flip_rate`, the documented sort order, the `NA`
  standard deviation for a single occurrence, and `min_n` selecting rows
  without changing a statistic. No defect found.
* Two scale limits nothing had reached are now tested: `emoji_dfm()` at its
  widest -- one document holding every distinct emoji, 3791 columns, all
  names distinct and non-empty, tf-idf zero everywhere as `log(N/df)` requires
  for a single document -- and a wide multi-document table keeping its
  documented column ordering and row sums. Also that a missing column is
  reported identically for all four column arguments, naming the argument and
  the column and never a same-named variable from the caller's session.

* **A misspelled column name could be reported as the contents of one of your
  variables.** tidyselect falls back to an *external vector* when a bare name
  is not a column, and `text` is a common variable name -- so
  `emoji_sentiment(df, text)`, on a data frame whose column had been renamed,
  in a session where `text` was also a character vector, gave
  ``Can't select columns that don't exist. Columns `from the global ...` and
  ...`` -- naming the contents of the caller's variable as though they were
  column names -- plus a tidyselect deprecation warning advising `all_of()`,
  which is not what the caller meant. That is the same failure mode this
  resolver was written to replace, arriving by another route. A bare name is
  now checked against `names(data)` directly: the message names the argument
  and the missing column and lists the ones that exist, with no spurious
  deprecation warning. Where the column *does* exist it still wins over a
  variable of the same name, and every other tidyselect form -- a string, a
  position, `all_of()`, `starts_with()` -- still resolves through
  `dplyr::select()`, two-column selections included.
* That also makes the commonest call much cheaper. Resolving a bare column name
  no longer runs `dplyr::select()`: **2000 resolutions went from 2.0s to
  0.058s**, and a realistic loop of 500 per-group `emoji_sentiment()` calls
  from 1.32s to 0.93s. Large-corpus timings are unchanged, being detection
  bound. It also retires the note added earlier this release about five verbs
  resolving the name twice -- at 0.03ms a resolution there is nothing left to
  restructure.

* **The time verbs' buckets follow the session timezone when the column has
  none, and nothing said so.** `?emoji_trend` promised that a date-time is
  bucketed by the day it "displays as in its own timezone" -- but a `POSIXct`
  built by `as.POSIXct("2024-01-01 23:30")`, which is what most CSV readers
  give you, has no `tzone` of its own, so R displays it in the session's. The
  same column reports hour 23 in one session and hour 4 in another; measured
  across UTC, America/New_York, Asia/Tokyo and Pacific/Kiritimati, the
  hour-of-day buckets came out 0/23, 0/1, 13/14 and 18/19. That is correct
  `POSIXct` behaviour rather than a defect -- a column with no timezone has
  none to display in -- but it is the same reproducibility trap as the
  collation and ctype dependence this release fixed, and it was undocumented.
  `?emoji_trend`'s `time` now says to tag the column
  (`as.POSIXct(x, tz = "UTC")`) when the result has to be reproducible.
* Three tests pin the timezone axis, which nothing had varied: a *tagged*
  `POSIXct` gives byte-identical days, hours and months across four timezones
  spanning a date line and a DST boundary; a `Date` column is immune across all
  five bucket widths; and an untagged `POSIXct` demonstrably follows the
  session, so the documented warning cannot quietly stop being true.

* **A `time` column written `dd/mm/yyyy` was read as dates in the year 1, and
  nothing said so.** `as.Date()`'s `%Y` accepts a one- or two-digit year, so
  `as.Date("01/02/2024", format = "%Y/%m/%d")` is `0001-02-20` -- year 1, month
  2, day 20. The character branch tried `"%Y/%m/%d"` as a fallback, so a whole
  column in `dd/mm/yyyy` or `mm/dd/yyyy` form -- most CSVs written outside
  ISO-land -- parsed without complaint, and every time verb bucketed on years
  1, 3, 12 and so on. The four-digit year is now required before parsing, which
  sends those values to the paths that already existed for unreadable dates:
  mixed with real dates they warn and are dropped, and a column where nothing
  reads as a date errors. Every form that worked still works, including
  `"2024-1-1"` and a trailing time.
* The error for a wholly unreadable `time` column now diagnoses what it found
  instead of restating the argument's type, quotes the value it choked on, and
  points at `as.Date(format = )` -- so the `dd/mm/yyyy` case above arrives with
  a route out. `?emoji_trend`'s `time` documents the accepted forms, that a
  column with nothing readable is an error rather than all-`NA`, and names
  `"01/02/2024"` as the case to convert first.

* **A bad `lexicon` was reported against `tbl`, an argument the scoring verbs
  do not have.** `emoji_score()`, `emoji_sentiment()` and `emoji_emotion()`
  share their lexicon validation with `register_emoji_lexicon()`, whose own
  formal is called `tbl` -- so passing a data frame as `lexicon` produced
  ``No score column found in `tbl`; supply `score` ``, telling the user to fix
  an argument that function does not take. That is the same failure mode the
  column resolver's `arg` parameter was added for, and the helpers now take one
  too: all six messages reachable through `lexicon =` name `lexicon`, and the
  three reachable through `tbl =` still name `tbl`. Two of them also read
  better for it -- ``Lexicon has no score column `nope` `` is now
  ``` `lexicon` has no column `nope` to take the score from ```.
* Found by inspecting all 43 `stop()` messages in the package for whether each
  names something a caller can actually type. The lexicon helpers were the only
  exception; every other message either names a real argument or fills a `%s`
  with one at run time. A test now enforces it, allowing the argument-with-value
  form (`period = "hour"`) that two messages use.

* `.emoji_text_col()` resolved the text column's name twice. The
  one-value-per-row check added this release routed the read back through
  `.emoji_col()`, which resolves the name again -- and resolving it runs
  `dplyr::select()`, about a millisecond a call. Invisible next to detection on
  a real corpus (20,000 rows is unchanged at 0.26-0.86s a verb), but the whole
  cost of a verb called once per group in a loop over a split data frame. The
  check now takes the name it already has, so the read is back to one
  resolution.

* **`emoji_turnover(measure = )` swallowed a value it did not recognise.** It
  is the only argument in the package that takes several values at once, and
  `match.arg(several.ok = TRUE)` returns the ones it matches without a word
  about the rest -- so `measure = c("jaccard", "flip")` produced the `jaccard`
  column and no hint that the second name was wrong. That is the
  absorbed-argument failure mode this release swept everywhere else. An
  unrecognised value is now an error that names `measure` and the value, and
  an empty, `NULL`, `NA` or non-character `measure` gets one message instead of
  `match.arg()`'s internal `'arg' must be of length >= 1`. What had to survive
  does: abbreviations (`"jac"`) still match, duplicates are still ignored, the
  four-measure default is unchanged, and the columns still come back in the
  fixed statistic order rather than the order asked for. `?emoji_turnover` now
  says all four of those things.

* **A matrix column passed as `time`, `doc_id` or `text_score` failed four
  different ways -- including not failing.** A matrix holds one element per
  *cell*, so a 2x2 column carries four values for two rows, and nothing
  downstream noticed: a character `time` gave `emoji_trend()` and
  `emoji_adoption_lag()` ``invalid 'times' argument``, `emoji_seasonality()`
  ``missing value where TRUE/FALSE needed``, and **`emoji_turnover()` a
  result**, computed over periods that were not in the data. A `doc_id` made
  `emoji_dfm()` report four documents for a two-row frame, with the id column
  filled from rows that do not exist. A `text_score` passed the type guard
  outright -- a matrix *is* numeric -- and reached tibble as
  ``Assigned data `gap` must be compatible with existing data``. The
  one-value-per-row check added for `text` last round now lives in the shared
  column reader, so all four arguments get it and all ten verbs give the same
  message. `emoji_dfm()` was the one column read that bypassed that helper;
  it no longer does, and a test asserts no other does either.
* The type and length checks now report in the informative order. A
  data-frame column's `length()` is its *column* count, so the length check
  fired first and said nothing about the real problem; the type check runs
  before it. A `POSIXlt` column is unaffected -- R's `length()` method counts
  times rather than list components -- so `emoji_seasonality(period = "hour")`
  still accepts one.

* **A list column passed as `text` was scored from its own deparsed source
  code.** Every verb reads the text column through one helper that calls
  `as.character()` -- which is exactly what lets a `factor` column work, and is
  harmless on a numeric, `Date` or logical one. On a list column it deparses:
  a column holding `list(c("a", "<U+1F600>"))` was read as the *source text*
  `c("a", "<U+1F600>")`, the emoji inside that was detected, and the row came
  back with a real-looking `.emoji_sentiment` of 0.5718 for data that never
  contained an emoji. A data-frame column deparsed the same way. Both are now
  refused, with a message that says why; every atomic column still works
  exactly as before.
* **A matrix column errored opaquely in two verbs and silently over-counted in
  a third.** A matrix holds one element per *cell*, not per row, so a 2x2
  matrix column gave `emoji_sentiment()` and `emoji_tokens()` a tibble error
  naming a variable from this package's own source
  (``Assigned data `glyphs` must be compatible with existing data``) while
  `emoji_frequency()` happily counted all four cells against two rows. The
  shared reader now requires one value per row, so all six verbs tried give the
  same message; a single-column matrix has one element per row and still works.
* **`emoji_score()` sent an emotion-lexicon user down a dead end.** It
  averages the eight emotion dimensions into one number for the bundled
  `"emotag1200"`, but that averaging is special-cased to the bundled table: a
  *registered* or inline lexicon of exactly the same shape has no score column,
  so the call failed with "No score column found in `tbl`; supply `score`" --
  advice that cannot help, since `score` names a single column and the user
  wants the mean. The message now names both real routes (`emoji_emotion()`
  for the profile, or `score = "joy"` to score on one dimension) and says the
  averaging is specific to the bundled lexicon; `?emoji_score` says the same. A
  table with neither a score nor an emotion column keeps the original message.
  No behaviour changed beyond the message.
* **`emoji_emotion() |> emoji_emotion_label()` silently threw away all eight
  emotion scores.** The label verb computes the scores internally and then
  drops every `.emoji_<emotion>` column by name -- which cannot tell a column
  it just added from one that was already in `data`. So the obvious way to get
  the profile *and* the label kept only the label, and a caller's own column of
  one of those names was deleted rather than overwritten. Both contradict a
  `@return` that says the label is *added*. It now drops only the columns that
  call introduced: `emoji_emotion_label()` on plain data returns exactly what
  it always did, and the chain now returns all thirteen columns with the label
  and the scores agreeing with the standalone calls. `?emoji_emotion_label`
  says so.
* Found by sweeping the pipelines a user would actually write, which nothing
  had checked -- every verb had only ever been tested on its own, against a
  package whose headline claim is that the verbs "compose naturally with the
  pipe". Fourteen chains are now tests, along with the grouped contract end to
  end (`group_by()` through a row verb into `summarise()`, grouping surviving a
  chain, and a text-rewriting verb re-deriving the groups when the user grouped
  by that very column), re-running ten row verbs on their own output, and
  feeding four aggregators a row verb's output column.

* **`?emoji_cooccurrence` said it "is `emoji_pairs()` under another name, with
  one addition", and it also silently drops an argument.** There is no
  `directed` on `emoji_cooccurrence()`, so a reader taking that sentence
  literally gets `unused argument (directed = TRUE)` with no explanation. The
  omission is right -- a co-occurrence matrix is symmetric, so an ordered pair
  has no meaning on it, and neither would the diagonal the verb exists to add
  -- but only the addition was documented. The description now states both,
  with the reason and where to go for `directed`, and a test pins the two
  signatures as differing by exactly `directed` and `diagonal`.
* Found by a cross-product sweep of every enum and flag argument -- 182
  combinations across seventeen verbs, now a test. `method` x `scale` x `where`
  for the three mismatch verbs, `weighting` x `doc_id` for `emoji_dfm()`,
  `directed` x `sort` x `diagonal` x `doc_id` for the relational pair, `by` x
  `measure` x `top_n` for `emoji_trend()`, all four `measure` subsets of
  `emoji_turnover()`, and the rest. Every combination that exists returns a
  data frame with nameable columns; the one that did not is the item above.
* **`emoji_tokens()` was the one verb that did not validate `data`, and a bare
  list or a character matrix silently succeeded.** It called
  `.emoji_as_tibble()` *before* resolving the text column, and
  `tibble::as_tibble()` converts a list or a matrix quite happily -- so the
  `is.data.frame(data)` guard every other verb enforces never saw the original
  object. `emoji_tokens(list(text = c("a", "b")), text)` returned a result
  where the other twenty-five verbs error, and `NULL`, a number, a function and
  an environment reached dplyr's or R's own internals
  (`cannot coerce class "function" to a data.frame`) rather than the package's
  message. The column is now resolved first, so all twenty-six verbs give
  ``` `data` must be a data frame ``` for all seven wrong shapes. A data frame
  that simply lacks the column stays a different error, delegated to
  `dplyr::select()` so the message names the column.
* **The detection figures this release quotes were wrong, in NEWS.md and in
  `cran-comments.md` both.** They read "exact detection of the reference table
  goes from 80.1% to 95.8%" and "spellings that lose a joiner from 793 to 2",
  which pairs a no-repair baseline with an after-rules-1-and-2 one. Staging the
  rules and measuring each: no repair gives **63.2%** (3189 of 5042 spellings
  read as exactly one emoji equal to the whole spelling) and 1643 orphaned
  joiners; rule 1 alone, which is UAX #29's GB11, gives 75.5% and 1025; rule 2
  leaves 793; rule 3 takes those to 2. No staging produces 80.1%, and 793 is
  where rule 3 *starts*, not where the three rules together do. Both documents
  now give 63.2% to 95.8% and 1643 to 2, with the intermediate figures stated
  so each is attributable, and a test derives all six from the rules.
* **Four help topics had no `@seealso` at all** -- and they were the four other
  pages point *at*: `emoji_categorize()`, `emoji_emotion_label()`,
  `emoji_extract_unnest()` and `emoji_filter()`. A reader arriving at one from
  the reference index or a search had no route onward, while the other 44
  exports did. Each now points at its pair and its neighbours, and a test
  requires every exported topic to carry one.
* **`?emoji_sanitize`'s reversibility table promised more than `wrap` allows.**
  It says `policy = "shortcode"` restores the original text, calls it "the only
  policy that permits it", and quotes a 100% byte-exact figure -- but the
  section never mentioned `wrap`, an argument of the same function that voids
  the promise. `text_to_emoji()` looks for exactly `:shortcode:`, so measured
  across eleven templates: the default `":{x}:"` restores the text exactly; a
  decorating wrap (`"[:{x}:]"`, `":{x}:!"`) brings the emoji back but leaves
  the decoration; a wrap with no `:token:` (`"{x}"`, `"<{x}>"`, `"@{x}@"`,
  `":{x}"`, `"{x}:"`, `"a{x}b"`) **restores nothing at all and does so
  silently**, leaving the shortcode in the text as an ordinary word; and
  `"::{x}::"` brings the emoji back wrapped in leftover colons, so it is not
  even stable under a second pass. All four cases are now in the section, with
  the precondition stated on `?emoji_to_text`'s `wrap` and in
  `?text_to_emoji`'s opening sentence, and pinned by a test.
* The grouped-input warning is now asserted for all fourteen cross-row
  aggregators at once: each warns exactly once, names *itself* rather than the
  helper or the verb it delegates to, and does not tell the user to report a
  bug in tidyEmoji. Previously one verb was spot-checked.

* **The introduction vignette could not be built without its Suggests
  packages, so `R CMD build` failed outright on a library tree lacking one.**
  It read its example corpus with `readr::read_csv()` and drew its charts with
  \pkg{ggplot2}, \pkg{forcats} and \pkg{stringr}, all unconditionally --
  optional dependencies used as if they were required. Verified by building on
  an R 4.6.0 tree with neither 'readr' nor 'forcats': `Error: Vignette
  re-building failed`. The corpus is now read with `utils::read.csv()` wrapped
  in `tibble::as_tibble()` (byte-identical `full_text`, same encodings, same
  900 emoji tokens, identical verb output), and the nine plotting chunks are
  gated on a `requireNamespace()` flag. The vignette builds either way, and
  the readr Suggests entry now exists only for one guarded test.
* **Five documentation-pinning tests were silently inert on every CRAN
  flavour.** They read `../../man/*.Rd`, which exists only when the suite runs
  from the source tree; inside `R CMD check` the tests execute from
  `<pkg>.Rcheck/tests/testthat/` and skipped with "man/ not available". So
  every assertion that a figure or a column name really appears in the rendered
  help page -- the mechanism several of this release's fixes rely on -- was
  never actually checked where it mattered. They now read the installed help
  database via `tools::Rd_db()`, whose `as.character()` reconstructs the
  markup, so `\code{...}` matches still work. Two more tests were reaching for
  `NEWS.md`, `DESCRIPTION` and the vignette source the same way; all three are
  installed with the package, so they read the installed copy when the source
  tree is absent. Skips inside `R CMD check` drop from 14 to 6 -- two
  deliberate `skip_on_cran()` maintenance checks, three that genuinely need
  `R/*.R`, and one that needs the vignette's CSV -- and 160 more assertions run
  there than before.
* `cran-comments.md` contradicted itself about this host's check result,
  reporting both "1 WARNING and 3 NOTEs" and, three paragraphs later, "one
  WARNING and two NOTEs" for the same run. The duplicate paragraph is gone. Its
  other stale figures are corrected or removed: R 4.6.0 gives `Status: 2 NOTEs`
  rather than `Status: OK`, the package has 16 URLs rather than the 12 claimed
  (so the count is no longer asserted -- only the one URL that is reported),
  and the CRAN-index size is dated as a snapshot. The three new dependency
  floors and the vignette change above are now described there too.

* **`?emoji_density` said "emoji per character" without saying that a
  character is a code point**, which reads as per-grapheme and is not. A
  multi-code-point emoji inflates the denominator by all of its code points, so
  the same visible text gives different answers: `"hi <emoji>"` is four
  graphemes either way, but `.emoji_per_char` is `0.25` for a
  single-code-point smiley, `0.200` for a two-code-point flag and `0.100` for a
  seven-code-point ZWJ family. 115 of the 560 emoji-bearing rows in the
  vignette's corpus contain a multi-code-point emoji, so it is not an edge
  case. `emoji_ratio()` had always stated this basis and `emoji_position()`
  states the opposite one (each emoji counts as one position, because a
  proportion of a message has to); `emoji_density()` sat between them saying
  neither. It now states the basis, gives those three figures, and points at
  `.emoji_per_token`, which does not move with an emoji's internal length. This
  closes the last open action from the audit that fixed
  `.emoji_rel_position`: "grep for other `nchar()` uses on user text". All
  thirteen are now accounted for -- four feed a documented user-facing figure,
  nine are internal offsets.
* **The reproducibility claim behind the bundled data is now verified.** Every
  dataset's `@source` names the `data-raw/` script that builds it and the
  vignette says they "are regenerated from the current Unicode emoji list by
  the scripts in `data-raw/`", but nothing had ever re-run them. All four
  reproduce their `.rda` byte-for-byte against \pkg{emoji} 16.0.0:
  `emoji_unicode_crosswalk` (5761 rows), `category_unicode_crosswalk` (10),
  `emoji_sentiment_lexicon` (969) and `emoji_emotion_lexicon` (150). The two
  crosswalks derive purely from `emoji::emojis`, so a `skip_on_cran()` test now
  rebuilds them and requires an exact match -- which will also flag the
  datasets as stale the next time \pkg{emoji} ships new glyphs.
* `data-raw/emoji_emotion_lexicon.R` cited `next_release.md §4.1` for why the
  lexicon is keyed on a selector-stripped code point. That file is a planning
  document rewritten each release, and §4.1 is now about skin-tone modifiers,
  so the pointer had gone stale. The reason is stated in the script instead.

* **Two dependency arguments the package relies on had no declared version
  floor, and one of them would have stopped the vignette building.** Found by
  running the suite on R 4.1.0 -- the version DESCRIPTION declares as the
  minimum -- and on R 4.6.0.
    * `lifecycle::deprecate_warn(env=, user_env=)` does not exist in lifecycle
      1.0.0; it arrived in 1.0.3, whose release notes are exactly the
      caller-environment work those arguments were added for. Every
      grouped-input call in the package goes through `.emoji_warn_grouped()`,
      so on an older lifecycle a dozen verbs would have failed with "unused
      argument". Now `lifecycle (>= 1.0.3)`.
    * `readr::read_csv(show_col_types=)` arrived in readr 2.0.0. R 4.1.0 here
      ships readr 1.4.0, where the introduction vignette fails to *build* and
      the corpus regression test errored instead of skipping -- its guard
      checked that readr was installed, not that it was new enough. Now
      `readr (>= 2.0.0)` in Suggests, and the test gates on
      `minimum_version = "2.0.0"`.
  The suite now passes on R 4.1.0, 4.4.1 and 4.6.0.
* Two tests guard the class. One walks the AST of every `R/` file and checks
  that each named argument passed to a `pkg::fun()` call is a formal of that
  function, so an "unused argument" cannot hide until someone runs against the
  version that lacks it. The other holds a table of the five arguments the
  package would break without -- lifecycle's `env`/`user_env`, dplyr's
  `relationship` and `.locale`, tidyr's `delim`, readr's `show_col_types` --
  and requires DESCRIPTION to declare a floor at least as high as each one
  needs.

* **`?emoji_unicode_crosswalk` and the vignette both called it "one row per
  emoji name", and a join by that column silently duplicates rows.** The
  mapping is many-to-many in *both* directions: 5761 rows cover 4698 distinct
  names and 4853 distinct glyphs. A glyph repeats for every alias it has (the
  documented direction), and a name repeats for every *spelling* of the emoji it
  names -- 973 do, because the qualified and unqualified forms are separate rows
  sharing one alias, so `A_button_blood_type_` names both `U+1F170 U+FE0F` and
  the bare `U+1F170`. Both places now give the row unit as a (name, glyph) pair
  and say to join on `key`, which collapses the spellings. A test pins all three
  counts and that a repeated name never spans two different emoji.
* **The introduction vignette said two time verbs need no timestamp; only one
  does.** `emoji_version_profile()` runs without a `time` column;
  `emoji_adoption_lag()` uses the same version lookup but still has to find each
  glyph's first appearance, so it requires one -- as the vignette's own next
  sentence says two lines later. The claim came from misreading `emoji-time.R`'s
  "two of these are almost free", which meant needing no new dataset. Both the
  sentence and the comment that caused it are fixed, and a test derives the
  count from the verbs' formals.
* The vignette no longer teaches a superseded function. It reached for
  `tidyr::separate_rows()`, which tidyr marks **[Superseded]** and says will
  "only receive critical bug fixes", pointing at `separate_longer_delim()`
  instead; since the vignette is the package's primary teaching document, that
  is the call a reader copies. Switched, with `tidyr (>= 1.3.0)` now declared to
  match -- the same release vintage as the existing `dplyr (>= 1.1.0)` floor. A
  test scans the vignette, the README and every `R/` file for fourteen
  superseded tidyverse calls so none creeps back, and the vignette's overview
  table is asserted to name every export bar the soft-deprecated
  `emoji_tweets()`.

* **`emoji_ambiguity()`'s entropy column held negative zero on 166 of its 969
  rows.** `-sum(1 * log(1))` is `-0` for a glyph its annotators were unanimous
  about. It compares equal to zero and prints as `0`, so nothing downstream was
  wrong -- but `sprintf("%.3f", x)` renders it `-0.000`, and formatting a table
  for a paper is the commonest thing anyone does with that column. An entropy
  of `-0.000` reads as a bug in the package.
* **`?emoji_ambiguity` never warned that the head of its ranking is an artefact
  of thin evidence.** The lexicon's annotation counts run from 1 to 14622 --
  median 18, and 69% below 50 -- and entropy, Gini and neutral share are shape
  statistics that do not care how many annotations produced the shape. Three
  annotators splitting one-one-one score the maximum entropy of `log(3)`, which
  is why five of the rows tied at `rank = 1` have 3, 3, 3, 9 and 15
  annotations, and why 11 of the top 20 have fewer than 50. So
  `head(emoji_ambiguity())` -- the help page's own first example -- returned
  box-drawing characters and arrows, which reads as the function being broken.
  The details now say to filter on `n_annotations` first (as the introduction
  vignette already did), and the example demonstrates the filter. They also say
  where the bias is *not*: entropy is positively correlated with the annotation
  count overall (Spearman 0.56), because a thinly annotated glyph is usually
  unanimous. What three annotators can do that thousands cannot is hit the
  exact maximum. `"ci_width"` is named as the measure that accounts for thin
  evidence by construction, being a Wald interval that scales as `1 / sqrt(n)`
  at a given spread -- its marginal correlation with the count is only -0.19,
  so the formula is the claim, not the correlation. Behaviour is unchanged.

* **`?tidyEmoji` told readers to supply "the emoji-presentation (qualified)
  form" to fix an undetected glyph, and for 12 emoji that advice does not
  work.** The variation selector does not always go at the end. For 200 of the
  212 catalogue spellings detection skips, appending `U+FE0F` repairs them; the
  exceptions are the keycap sequences -- `#`, `*` and `0` to `9` followed by the
  enclosing keycap mark `U+20E3` -- where the selector belongs *between* the
  two. `U+0031 U+FE0F U+20E3` is detected; `U+0031 U+20E3 U+FE0F` is not, so a
  reader who appended got the same zero count and no hint why. The page now
  gives the rule that repairs all 212 (insert `U+FE0F` after the first code
  point) and names the exception. It also now states the 212 figure alongside
  the existing 216, since those count different things -- spellings that are
  themselves undetectable, versus spellings that break when the selector is
  dropped -- and an unequal pair of numbers about the same subject invites one
  being "corrected" into the other.
* Detection is now tested in context, not only on bare glyphs. Every one of the
  5042 catalogue spellings is checked beside words, punctuation, brackets, a
  bare letter, an orphan joiner, a stray selector and another emoji on either
  side: the glyph count never changes, and next to a second emoji the split is
  exactly the two of them (bar the 212 undetectable spellings, which contribute
  nothing). Span well-formedness -- ordered, non-overlapping, inside the string,
  and slicing back to the glyph -- is asserted over five string shapes. No
  defect found; the invariant every verb rests on simply had no test outside the
  bare case.

* **One infinite `text_score` made every row's mismatch result infinite.**
  `scale = "zscore"` takes `sd()` of the column, which is `NaN` as soon as any
  value is infinite; the degenerate branch then subtracted an infinite mean, so
  the whole column came back `Inf` or `NaN`. Measured on 100 rows with a single
  `Inf`: **0 of the 60 scorable rows had a finite gap.** A non-finite
  `text_score` is now treated as missing -- which is what `NaN` already was,
  since `na.rm = TRUE` drops it -- and reported, in the style of the
  unreadable-date warning. The damage stays on its own row: the same 100 rows
  now give 59 finite gaps under all three scales.
* `?emoji_emotion`'s `@return` said the long form carries `.emoji_emotion` and
  `.emoji_score` "instead of the eight columns", which reads as a promise that
  `.emoji_n` and `.emoji_n_scored` survive. They do not -- `long = TRUE`
  returns neither. That matters because the same help page opens by telling you
  to read `.emoji_n_scored` alongside `.emoji_n` before concluding a corpus
  carries no emotion, advice a long-form user could not follow on a lexicon
  covering 4% of emoji. The `@return` now says the counts are dropped and where
  to get them. Behaviour is unchanged: the long form has had this shape since
  0.3.0.
* Three claimed equivalences now have the differential tests they never had.
  `.emoji_window_at()` slices a bounded piece of the masked text rather than
  the whole side, on the argument that only the nearest `window` tokens can
  matter; `.emoji_final_glyphs()` walks back over blank gaps rather than
  searching for the longest qualifying suffix directly. Both are now compared
  against a naive implementation over randomly generated text (thousands of
  comparisons each, across `window` 0 to 13 and both `unit` values), and the
  eight worked examples in `?emoji_incongruity`'s "ends the text" paragraph are
  asserted one by one. No defect found in either -- but neither was tested, and
  an optimisation that is only nearly equivalent is the kind that survives a
  release.

* **`scale = "rank"` and `scale = "zscore"` in the text-emoji mismatch verbs
  were scaled over the wrong population, and reported mismatch that was not
  there.** Each side was ranked (or standardised) over its own non-missing
  rows. `text_score` is normally present on every row, while the emoji score
  is missing wherever a row has no scorable emoji, so the two percentiles
  referred to different populations and the emoji-free rows -- which
  contribute nothing to the output, their own gap being `NA` -- shifted the
  answer for the rows that do. On 100 rows whose emoji sentiment equals their
  text score exactly, so the true gap is `0` throughout, adding 100 emoji-free
  rows with higher text scores moved the mean `.emoji_incongruity` to `+0.50`
  on the rank scale and `+0.92` on the z-score scale, and made
  `.emoji_incongruent` flag **54 of the 100 as mismatched**. Both scales are
  now computed over the rows the comparison is defined on, so subsetting to
  the scored rows gives the same numbers as calling on everything.
  `emoji_congruence()` and `emoji_incongruity_profile()` share the engine and
  are fixed with it. `scale = "none"` was never affected and is unchanged --
  which is why this survived: 34 of the 40 `scale =` arguments in the test
  suite were `"none"`, and the six that were not asserted only bounds, `NA`
  placement and the degenerate one-row branch, never a value against a known
  truth. That is now tested.
* **`?tidyEmoji`'s naming contract described two classes of output column and
  the package has three.** Five dotted names are not `.emoji_*` --
  `.row_number`, `.position`, `.period`, `.period_prev` and `.period_label` --
  and they are the ones a reader is most likely to meet first, since
  `emoji_extract_unnest()`, `emoji_context()`, `emoji_dfm()` and the three time
  verbs lead with them. The page now names all three shapes, says the
  structural-index list is complete, notes that `emoji_dfm()`'s column names
  are glyphs, and says that the reserved-prefix rule applies to the text column
  too if you happen to have named it `.emoji_n`. A test asserts no verb invents
  a fourth dotted name and that the page lists the five.
* **`emoji_search(NA_character_)` failed with R's own "missing value where
  TRUE/FALSE needed"** instead of the verb's own message. `nzchar()` defaults
  to `keepNA = FALSE`, which reads `NA_character_` as the two-character string
  `"NA"`, so the non-empty guard passed and the `NA` propagated to an internal
  `if (!any(hit))`. The guard now tests `is.na()` first, as the other
  string-argument checks in the package already did.
* **`?text_to_emoji` gave the right round-trip figure with the wrong reason.**
  It said the emojize/demojize round trip returns "identical bytes for the 79%
  that were already fully qualified". The 79% is correct (4002 of 5042
  entries), but those are not the fully-qualified entries, and stating it that
  way invites the number being "corrected" to the fully-qualified share
  (3790/5042 = 75%). Which spelling comes back is decided by the shortcode
  table, not by the input's selectors, so the two sets differ in both
  directions: 212 unqualified entries keep their bytes -- the bare heart
  `U+2764` among them, because that is the spelling `:heart:` maps to -- and 92
  already-qualified ones do not, such as the man detective
  `U+1F575 U+FE0F U+200D U+2642`, which comes back with a second selector on
  the gender sign. The details now say which question is which, add the
  guarantee that matters -- the 1040 differ by `U+FE0F` alone, never by more --
  and point at `?emoji_sanitize`, which already tabulated both denominators
  correctly. Every figure and both worked examples are pinned to the data.
* **`?emoji_search` listed 11 of the 17 strings that resolve differently**
  through `as_emoji()` than through `text_to_emoji()`, punctuated as if that
  were the whole set. It now names all 17 and says so; `camel`, `satellite`
  and `train` were missing from every list in the package. The set is derived
  from the data in the tests, so a new `emoji` release cannot leave it stale.
* **`?emoji_search` promised that its `shortcode` column "recovers every row
  exactly" through `text_to_emoji()`, and for some rows there is nothing to
  recover it from.** 189 of the catalogue's 5042 rows carry no GitHub-style
  alias, so `emoji_search()` reports `shortcode = NA` for them -- 7 of the 198
  rows `emoji_search("face")` returns, for one. Neither the details nor the
  `@return` said the column could be `NA`; the `@return` had gone out of its
  way to say that `keyword` is the empty string rather than `NA`, which made
  the omission read as a guarantee. Both now say so, and point at the `emoji`
  column or `as_emoji_shortcode()` -- which does answer for all 189, borrowing
  the alias of the glyph's other spelling -- as the way through.
* **`as_emoji_shortcode()` was documented as returning the glyph's "first
  shortcode", and for 175 of the catalogue's 5042 rows it does not.** It
  returns one shortcode per *emoji*, resolved through the codepoint key -- the
  first alias of the fully-qualified (RGI) spelling -- which is what makes it
  agree with `emoji_to_text()` and survive a round trip. 344 keys carry a
  different first alias on each of their two spellings, so
  `as_emoji_shortcode("\u2764")` is `"heart"` where the bare `U+2764` row's
  own first alias is `"red_heart"`. `emoji_search()` reports the other one, the
  matched row's own alias, since a search result is a row -- so the two verbs
  can disagree about the same glyph. Both resolve back to the same emoji
  through `text_to_emoji()`, so nothing was broken, but neither help page said
  which it gave. Both now do, and the 344/175 split is derived from the data in
  the tests. No behaviour changed.
* `?emoji_score` and `?emoji_emotion` now state the `.emoji_n_scored`
  convention that `?emoji_sentiment` and `?emoji_risk` already spelled out:
  `0` means the row had emoji the lexicon could not score, `NA` that it had no
  emoji to score. All five verbs behaved this way; two of them did not say so.
* `?emoji_ratio` now covers empty text, which is neither of the two cases it
  described: `.emoji_ratio` is `NA` (no characters to take a share of) while
  `.emoji_only` is `FALSE` (an empty string is not a row of emoji).
  Whitespace-only text, by contrast, has a real ratio of 0.
* `?emoji_pairs` now says what `sort = FALSE` does. It sorts by `item1` then
  `item2` in the C locale -- a fixed order, not the order the pairs happened to
  be counted in -- which the parameter name alone did not suggest.
* **Grouped data frames no longer break six verbs, and no longer lose their
  grouping in the rest.** Two independent bugs, found by calling every verb on
  a grouped input:
  `emoji_to_text()`, `text_to_emoji()`, `emoji_sanitize()`, `emoji_context()`
  and `emoji_collocations()` resolved their text column with
  `dplyr::select()`, which silently re-adds the grouping columns, so a grouped
  data frame made the selection return two names and the call failed with
  ``` `text` must select exactly one column ``` — an error blaming an argument
  the user had got right. And the verbs that work a row at a time returned
  `tibble::as_tibble(data)`, which strips the `grouped_df` class, so
  `group_by(author) |> emoji_sentiment(text) |> summarise(...)` quietly
  collapsed to one corpus-wide row instead of one row per author. Those verbs
  now carry the grouping through, as `dplyr::mutate()` and `dplyr::filter()`
  do; the three that rewrite the text column in place re-derive the group
  indices if the user grouped by that column. See `?tidyEmoji` for the
  contract.
* **Seven cross-row aggregators were silently pooling grouped input.**
  `emoji_version_profile()`, `emoji_trend()`, `emoji_turnover()`,
  `emoji_seasonality()`, `emoji_adoption_lag()`, `emoji_collocations()` and
  `emoji_incongruity_profile()` had no grouped-input guard, so a user grouping
  by author, platform or date got a corpus-wide answer that looked like a
  per-group one. All seven now warn. `emoji_cooccurrence()` and
  `emoji_flag_ambiguous()` warned under the name of the verb they delegate to
  (`emoji_pairs()`, `emoji_frequency()`) and now warn under their own. The
  guard lives in one helper rather than being copy-pasted into each verb —
  that copy-paste is why the seven were missed — and the helper reports the
  warning against the caller's frame, so it no longer appends "Please report
  the issue" to a warning about the user's own data.
* **A missing, ambiguous or misspelled column argument now names the argument
  the user actually wrote.** Every verb resolved its column with
  `dplyr::pull()`, whose errors are phrased in terms of `var` — a formal of
  `pull()` that appears in no tidyEmoji signature. `emoji_sentiment(df)` said
  ``` `var` is absent but must be supplied ```, `emoji_trend(df, text)` said
  the same about the missing `time`, a two-column selection said
  ``` `!!enquo(var)` must select exactly one column ```, and a typo was
  reported as `object 'txet' not found`, as if the user's own code had a free
  variable in it. All 38 call sites now go through one resolver: the messages
  name `text`, `time`, `text_score` or `doc_id`, and a misspelling is reported
  as `Column \`txet\` doesn't exist`.
* **`emoji_extract_nest()` accepted a missing text column.** It resolved
  `{{ text }}` in the data mask rather than as a column selection, so
  `emoji_extract_nest(df)` returned a bogus empty list-column instead of
  erroring, and a misspelled column was not caught either. It now uses the
  same resolver as every other verb, and still returns `data` with its class
  and grouping intact.
* The package's own help page was stale relative to `DESCRIPTION`: the
  paragraph describing interpretation risk, context, time, incongruity and the
  sanitiser was missing from `?tidyEmoji`. The build no longer ships the
  `.claude` directory, which `R CMD check --as-cran` flagged as a hidden file
  included in error.
* **Zero-row input now really does return a *typed* zero-row tibble.** Five
  verbs built their output columns with `ifelse()`, which takes the result's
  type from its arguments, so `emoji_density()`, `emoji_ratio()`,
  `emoji_faceness()` and `emoji_risk()` returned `logical` columns where a
  populated call returns `double` or `integer`, and `emoji_tokens()` returned
  an unspecified `.emoji` instead of `character`. Splitting a corpus, mapping a
  verb and binding the pieces back therefore produced a different schema
  depending on whether any chunk was empty. The values are unchanged.
* **A fractional count errors instead of being silently truncated.**
  `top_n_emojis(n = 2.5)` returned two rows, `emoji_context(window = 2.7)` used
  a window of two, `emoji_ngrams(n = 2.9)` built bigrams: in each case the
  number the user wrote was not the number that was used — the same failure
  mode as the `head(n = -1)` this release already caught, in the other
  direction. `n`, `top_n`, `window` and `min_n` now require a whole number;
  `NULL` and `Inf` keep their "all of them" meanings where they had one.
  `emoji_ngrams(sep = )` is checked too: it reached `paste(collapse = )`, which
  failed with `invalid 'collapse' argument` and an internal call stack for `NA`
  or a number, and silently used only the first element of a longer vector.
* `emoji_extract_nest()` now returns a tibble, like every other verb.
  `?tidyEmoji` promises "every verb ... returns a tibble", but this was the one
  row verb that did not route its output through the shared helper, so a plain
  `data.frame` in gave a plain `data.frame` back while the other seventeen
  returned a tibble — which also meant a list-column printing badly instead of
  as `<list>`. A grouped input still stays grouped. The whole output contract is
  now asserted across every verb at once rather than verb by verb.
* Test line coverage went from 96.6% to 99.4%, and closing the gap found four
  **documented features that no test exercised**: `emoji_score()` with the
  `"emotag1200"` lexicon (the mean over its eight emotion dimensions),
  `emoji_sentiment(lexicon = )` given a data frame or a registered lexicon,
  `emoji_trend(by = "quarter")`, and `sort = FALSE` on the relational verbs.
  Also now covered: the lexicon aliases `"sentiment"` and
  `"emoji_sentiment_lexicon"`, a `factor` time column, the degenerate branches
  of the rank and z-score rescalings, `emoji_incongruity_profile()`'s zero-row
  return, and every argument-validation error on the lexicon surface — each of
  which had been checked by hand in an earlier round and never written down.
  The nine lines still uncovered are guards whose callers validate first.
* `commonmark` and `xml2` join `Suggests`. The test that checks `NEWS.md`
  parses calls `utils::news()`, and R's Markdown news reader calls both of them
  unguarded — packages that were present in the development library only
  because roxygen2 and testthat pull them in. Declaring them means CI installs
  them and the test runs, rather than skipping everywhere but the maintainer's
  machine. `NEWS.md`'s version headings are now *also* checked directly,
  without parsing Markdown at all, so that invariant holds even where the
  reader is unavailable.
* `DESCRIPTION` declares `Language: en-GB`. The field was missing, so
  `spelling::spell_check_package()` defaulted to `en-US` and flagged 55 correct
  British spellings — `licence`, `normalised`, `analysed`, `summarise`,
  `behaviour`, `neighbouring` — as errors, which made the check unusable as a
  gate. The prose was already consistently British: across ten British/American
  word pairs, the R sources, help pages, vignette, README, NEWS and
  `cran-comments.md` contain **zero** American spellings. The only American
  tokens are the exported names `emoji_categorize()` and `emoji_sanitize()`,
  which follow R convention and stay.
* A new `inst/WORDLIST` records the 84 remaining terms the dictionary cannot
  know — author surnames, package names, and vocabulary like `codepoint`,
  `grapheme`, `shortcode`, `keycaps`, `ZWJ`, `Plutchik`, `idf`. With the
  language declared and the wordlist in place, `spell_check_package()` now
  reports zero, so a future typo is visible instead of buried in 139 lines of
  false positives.
* The test suite now passes in a non-UTF-8 locale. Ten test files carried 114
  literal non-ASCII characters inside string literals — zero-width joiners,
  gender signs, hearts, the no-break and ideographic spaces — and R parses a
  source literal byte-wise under `LC_ALL=C`, so each became a run of
  replacement characters and every fixture built from one silently tested the
  wrong string. All 114 are now `\u` / `\U` escapes, and the suite gives
  identical results under `LC_ALL=C` and a UTF-8 locale. Two new tests keep it
  that way: one asserts `R/` is pure ASCII (the invariant 0.4.0 introduced so
  the PDF manual builds, checked by hand until now), the other that test string
  literals stay escaped. The package's own detection was never affected —
  verified by re-running the whole-catalogue sweep under `LC_ALL=C`, which
  gives exactly the same 4830 of 5042 as a UTF-8 locale.
* The test suite no longer attaches `dplyr`. One test file called
  `library(dplyr)`, which in a single `testthat` session leaks into every
  alphabetically-later file and masks `filter()`, `lag()`, `intersect()`,
  `setdiff()`, `setequal()`, `union()` and `testthat::matches()` for all of
  them — so nine set-operation call sites were resolving to dplyr's generics
  purely because of filename order. They worked, but by accident. The attach is
  gone, those calls are `base::`-qualified, and the suite's behaviour no longer
  depends on the order its files happen to sort in.
* `as_emoji()` and `text_to_emoji()` accept **every** GitHub alias, not just
  the primary one each emoji is listed under, and that is now tested. The
  reference table keeps only an emoji's first alias as its `shortcode`, so 751
  of the 4698 aliases — `"grinning_face"`, `"satisfied"`,
  `"face_with_tears_of_joy"` — resolve solely through `as_emoji()`'s fallback
  to `emoji::emoji_name`. Nothing exercised that path.
* `emoji_incongruity(threshold =)` is documented as the gap "at or above which"
  `.emoji_incongruent` is `TRUE`, and the boundary is now tested. A row sitting
  exactly on the threshold is classified as incongruent; nothing had pinned
  that, so the comparison could have drifted to a strict one and silently
  reclassified every borderline row.
* `emoji_search()`'s three search fields are now tested separately. It is
  documented to match against keywords, name *and* shortcodes, and some
  queries match on one field only — `"grinning_face"` and `"thumbsup"` appear
  in no name (names use spaces, not underscores) and in no keyword — so a
  regression that dropped the shortcode field would have gone unnoticed. Also
  pinned: the search is case-insensitive, a query matching nothing returns a
  typed zero-row tibble, and the `+1` shortcode's regex metacharacter is safe.
* `emoji_dfm()`'s column order is now guaranteed independent of the order the
  rows arrive in. Columns are sorted by descending total count with the glyph
  as tiebreak; without that tiebreak, tied columns fell back to the order the
  glyphs happened to appear in the data, so the same corpus sorted differently
  produced a differently-ordered feature matrix. The behaviour was already
  correct — this release pins it, along with row-order independence for
  `emoji_frequency()`, `top_n_emojis()`, `emoji_version_profile()`,
  `emoji_pairs()`, `emoji_cooccurrence()` and `emoji_collocations()`.
* `?emoji_emotion_label` now documents that ties are broken in Plutchik order,
  so the winning emotion is deterministic and does not depend on a row's
  position in the data — it was a code comment only. The help page also points
  at `emoji_emotion()` for the profile the label collapses, since a near-tie is
  invisible in a single winning name.
* The introduction vignette's "design choices" list now mentions how grouping
  composes, which became a design choice in this release and was documented
  only on `?tidyEmoji`.
* `?emoji_incongruity` now says what "ends the text" means for
  `where = "final"`. Only whitespace may follow the last glyph, so
  `"great \U0001f602"` has a final run and `"great \U0001f602."` does not — a
  trailing full stop, bracket or quote mark disqualifies it, which is easy to
  meet unaware in a punctuated corpus. The behaviour is unchanged; it was
  simply not stated.
* **A `POSIXct` time column was bucketed by its UTC day, not its own.**
  `as.Date()` on a date-time converts in UTC whatever the object's `tzone`
  says, so an emoji posted at 23:30 New York time was counted on the *next*
  calendar day — and for an evening-heavy corpus, systematically so. It also
  made the package disagree with itself: `emoji_seasonality(period = "hour")`
  reads `format(x, "%H")` and had always used the timestamp's own zone, so the
  same row could be hour 23 and the following day at once. `emoji_trend()`,
  `emoji_turnover()`, `emoji_adoption_lag()` and
  `emoji_seasonality(period = "month" / "weekday")` now all take the calendar
  day the timestamp displays as. The session's `TZ` does not affect any of
  them, before or after.
* **A time column of strings silently shrank the corpus.** A value that would
  not parse as a date became `NA`, and the time verbs then dropped the row —
  indistinguishable, in the result, from a row whose date was genuinely
  missing. `emoji_trend()`, `emoji_turnover()`, `emoji_seasonality()` and
  `emoji_adoption_lag()` now say how many values were unreadable and show the
  first one; a real `NA` still passes without comment, and a column where
  nothing parses still errors.
* **`?emoji_sanitize` now documents which policies can be undone.** The five
  policies were presented as five parallel options; they are a ladder of
  information loss, and how far down it you stepped only became visible when
  you tried to restore the emoji after a model call. The help page gains the
  table: `"shortcode"` is the only rewriting policy that round-trips (losslessly,
  including skin tones, flags, ZWJ sequences, keycaps and `U+FE0F` forms),
  `"placeholder"` keeps *where* but not *which*, and `"strip"` keeps neither.
* **232 of the catalogue's 2501 zero-width-joiner sequences were detected as
  their component emoji rather than as one emoji.** The repair that rejoins
  sequences the upstream regex does not know required the gap between two
  matches to be exactly one joiner. In a sequence whose middle component is a
  text-presentation code point, that component is not matched either, so the
  gap is `ZWJ + component + ZWJ` and the rule declined. The damage was a
  *wrong* count, not a missing one — `🚶` `U+200D` `U+2640` `U+200D`
  `U+27A1` `U+FE0F`, "woman walking facing right", arrived as two emoji,
  "person walking" and "right arrow", neither of which the text contains, and
  most of the 232 are 2023-2024 additions. The repair now also merges when the
  gap holds a joiner and the union of the two spans is itself a catalogued
  emoji: exact, so it can only join code points that really do spell one emoji,
  and the original rule still covers everything the catalogue has not heard of.
  2499 of the 2501 now detect as one glyph; the two that do not are unqualified
  spellings whose every component needs `U+FE0F`, and their qualified forms are
  found. This changes `.emoji_n`, frequency tables and every count derived from
  them for corpora containing these sequences.

  A second, subtler form of the same defect needed a second rule. Both merge
  rules need *two* matches to work with, and a sequence whose only detectable
  component is one of its parts yields a single match — so there was no pair to
  merge and the sequence arrived as that part. `U+2764 U+200D U+1F525` ("heart
  on fire") with its selectors omitted read as `U+1F525` ("fire"), and
  `U+1F9D4 U+200D U+2642` ("man: beard") as "person with beard". Counting
  glyphs cannot see this — one match is still one glyph — so the test for it
  looks for a joiner left *outside* every detected span. A lone match beside
  such a joiner is now grown outwards while the span stays a catalogued emoji,
  bounded by the longest catalogued emoji (10 code points), never crossing a
  neighbouring match, and skipped entirely unless the string actually has an
  orphaned joiner.

  Together the three rules take exact detection of the reference table from
  **63.2% to 95.8%** (3189 of 5042 spellings read as exactly one emoji equal to
  the whole spelling, against 4830 now) and orphaned joiners from **1643 to
  2** — the two being spellings with no detectable component at all, both of
  which have a canonical form that is found. Staged, so each figure is
  attributable: rule 1 alone, which is UAX #29's GB11, gives 75.5% and leaves
  1025 orphaned joiners; rule 2 leaves 793; rule 3 takes those to 2.
  Well-formed text costs about 6% more; text that was broken now costs more and
  is right.
* `emoji_dfm()` names one column per emoji glyph, so a `doc_id` column named
  with one of those glyphs was overwritten by the count column and the document
  identifiers vanished without a word. It is now an error that says which
  column to rename.
* **`emoji_categorize()` silently dropped rows that do contain emoji.** It
  filtered on `.emoji_category` being non-`NA`, and that column is `NA` for two
  different reasons: the row has no emoji, or the row's emoji are not in the
  reference table. The second case is real and grows with every Unicode
  release — detection is grapheme-aware, so a zero-width-joiner sequence newer
  than your installed \pkg{emoji} is found as one emoji but cannot be
  categorised — and those rows vanished from the result. 0.2.1 fixed one
  instance of this (a `U+FE0F`-qualified heart went missing) by repairing that
  particular join; the conflation behind it survived. The filter is now on
  "contains at least one emoji", so such a row is kept with
  `.emoji_category = NA`, and `nrow(emoji_categorize())` now always equals
  `nrow(emoji_filter())`.
* **`emoji_risk()` treated the same row two ways.** A row holding emoji the
  ambiguity lexicon cannot score — anything added to Unicode after 2015 —
  correctly got `.emoji_n_scored = 0`, but `.emoji_n_ambiguous = NA`, where the
  count of ambiguous glyphs found is genuinely zero. The `@return` had promised
  `NA` only for rows with no emoji at all, so the documentation was right and
  the code was wrong. `.emoji_ambiguity_mean` and `.emoji_ambiguity_max` stay
  `NA` there, because there is nothing to average.
* `emoji_key()`, the codepoint key every glyph-to-metadata join goes through,
  had two "no key here" values: `NA` for empty or missing input, but `""` for a
  string made of nothing but variation selectors. Every consumer had to
  remember to filter both. It is now `NA` in all three cases; a lexicon row
  whose glyph is a stray `U+FE0F` is ignored rather than keyed on `""`.
* `?emoji_sanitize`'s reversibility claim is now measured rather than
  asserted, and the measurement is stronger than the old wording: for all 3790
  emoji in their canonical spelling — the spelling a keyboard emits — the
  `"shortcode"` round trip **returns the original text byte for byte, 100% of
  the time**. Feed it one of Unicode's shorter spellings, with the `U+FE0F`
  selectors omitted, and it returns the canonical one instead; across all 4853
  catalogued spellings that is 79.5% byte-identical, with every difference
  being `U+FE0F` alone and never more. Tests assert the exact claim rather than
  a byte-identity threshold, because that rate falls each time detection
  improves — a spelling that used to fragment now merges and normalises.
* **The lexicon coverage ceilings are now on the help pages, with the right
  denominator.** `emoji_emotion()` can score 150 glyphs — about **4%** of the
  3790 distinct emoji tidyEmoji can detect — and `emoji_sentiment()` about
  **19%**, with nothing added to Unicode after 2015. A user who does not know
  that reads a column of `NA` as "no emotional content" rather than "not in the
  lexicon". Both verbs and both dataset pages now state the figure, name the
  `{emoji}` version it is computed against, and point at `.emoji_n_scored` as
  the per-row answer. (The internal roadmap had quoted 3.0% and 19.2% against
  the reference table's 5042 *rows*; the table stores the qualified and
  unqualified forms of an emoji separately, so the denominator is 3790 distinct
  codepoint keys.)
* `?emoji_emotion` and `?emoji_emotion_label` named fewer columns than they
  return: the eight emotion columns and the `.emoji_n` / `.emoji_n_scored`
  counts were missing, and the completely different shape of `long = TRUE`
  (one row per row *per emotion*) was not in the `@return` at all.
* `README.md` is now byte-for-byte what `README.Rmd` renders to, so it cannot
  drift from its source unnoticed.
* **The lexicon registry accepted two registrations it could never honour.**
  `register_emoji_lexicon("novak2015", ...)` succeeded, showed up in
  `emoji_lexicons()` as a second row with the same `name`, and was then
  unreachable, because a bundled name resolves before the registry is
  consulted — so `lexicon = "novak2015"` still got the bundled table. All six
  bundled names are now refused with the list of them. And a lexicon with no
  usable score column registered happily and only failed at first use, from
  inside `emoji_score()`, in a message naming `tbl` — an argument of a call
  that had long since returned; the score column is resolved at registration.
  An `NA` name is rejected too.
* **The detection contract is now on the help pages.** Code points that are
  emoji only when they carry `U+FE0F` — the bare heart `U+2764` being the one
  people meet — are not detected, which was documented on
  `?emoji_sentiment_lexicon` but nowhere a user counting emoji would look.
  `?tidyEmoji` gains a *Detection* section with the measured size of the
  exclusion (1252 of 5042 catalogue emoji carry `U+FE0F`; 216 of those are
  undetectable without it), the reason the default does not change (`U+00A9`,
  `U+00AE` and `U+2122` are in the same set), and the fact that it affects
  detection only and never the `U+FE0F`-stripped join. The `.emoji_*` prefix is
  documented as reserved: a verb overwrites a column of its own output name
  without warning, which is what makes the verbs chainable.
* **`emoji_dfm(doc_id = )` no longer orders its rows by the session's
  collation.** Documents were grouped with `factor()`, whose levels are sorted
  with the locale's collation, so the row order of the result could differ
  between machines — the same class of bug 0.3.0 fixed for glyph ordering in
  `emoji_pairs()` and the dfm's columns. Documents now appear in the order
  their id is first seen in the data. `emoji_pairs()`,
  `emoji_cooccurrence()` and `emoji_dfm()` share one grouping helper, so they
  cannot drift apart again.
* `emoji_sanitize(policy = "strip")` tidies only the whitespace left behind by
  a removed glyph, and only on rows that actually contained one.
* **Arguments given nonsense now error instead of quietly returning a
  different answer.** An audit of every argument that reaches a base R function
  without validation found one shape of bug repeated across the package: a
  value the function cannot honour was absorbed rather than rejected.
  `emoji_to_text(wrap = )` now requires the `{x}` placeholder, since a template
  without it replaces every emoji with the same literal string;
  `top_n_emojis(n = )` rejects a negative `n`, which `head()` had silently read
  as "drop the last row"; and every `TRUE`/`FALSE` argument
  (`emoji_pairs(directed = , sort = )`, `emoji_cooccurrence(diagonal = )`,
  `emoji_emotion(long = )`, `emoji_context(keep_text = )`,
  `top_n_emojis(duplicated = )`, `emoji_sentiment(se = )`) is now checked,
  because `isTRUE()` reads every non-`TRUE` value as `FALSE` — so
  `long = "yes"` used to return the wide form without complaint. The deprecated
  `top_n_emojis(duplicated_unicode = "yes")` still works: the check runs after
  the lifecycle conversion.
* `emoji_score()` gains the `lexicon = "novak2015"` default that
  `emoji_sentiment()` always had, so calling it without a lexicon works instead
  of raising a missing-argument error.
* The reference-manual sources are ASCII throughout, so the PDF manual builds
  everywhere.
* `next_release.md`, the repo's release ledger, gains a section 13 recording
  what wave 1 shipped, the third-audit defect, and the design decisions locked
  at implementation.
* Three test assertions that were weaker than the behaviour they described are
  now exact. Two counted the residual of the ZWJ segmentation work with
  `<= 2` -- the catalogued spellings that go undetected, and those that leave a
  joiner orphaned -- where the true number is exactly two, and one bounded a
  row count that is exactly two. An inequality in that position accepts a
  regression back up to the bound without reporting it, and a count cannot see
  the residual *set* change while its size stays the same. The two residual
  spellings (`U+1F441 U+200D U+1F5E8` and `U+1F3F3 U+200D U+26A7`) are now
  named, with the reason they are irreparable asserted alongside them: neither
  carries `U+FE0F`, and each one's fully-qualified sibling is detected as a
  single glyph, so the residual is confined to the spelling and never reaches
  the emoji. No package code changed.
* `emoji_search()` and `emoji_collocations()` no longer change answer with the
  session's locale. Both fold case before matching, and `tolower()` honours
  `LC_CTYPE`: under a Turkish or Azerbaijani locale it maps `"I"` to a dotless
  i (`U+0131`) rather than `"i"`, so any query containing a capital I stopped
  matching the catalogue's ASCII text. Measured under `tr_TR.utf8`,
  `emoji_search("FIRE")` returned 0 rows instead of 27, `"SMILING"` 0 instead
  of 23, `"INDIA"` 0 instead of 2, and `"I"` 37 instead of 4640;
  `emoji_collocations()` counted `"BIG"` and `"big"` as two different words.
  Matching now folds `A-Z` with `chartr()` before `tolower()`, which settles
  ASCII deterministically while still folding non-ASCII, so a query for
  `"VICUÑA"` or `"O’CLOCK"` keeps working. This is not a behaviour change in an
  ASCII or Western locale: the new fold agrees with `tolower()` on all 5042
  catalogue names, 10701 keywords and 5761 aliases. `emoji_type()`'s
  group-to-type recode was checked and was never affected -- its subgroups are
  already lower-case and none of the literals it matches contains an `i`.
* `emoji_version_profile()` and `emoji_adoption_lag()` now resolve a Unicode
  version for every emoji they detect. The upstream `emoji::emojis` table
  records the introducing version on the *unqualified* member of a variation
  pair and leaves it `NA` on the fully-qualified one, so 1252 of 5042 reference
  rows carried no version -- among them everyday glyphs like the red heart
  (`U+2764 U+FE0F`), the smiling face (`U+263A U+FE0F`) and the skull and
  crossbones (`U+2620 U+FE0F`). Those all fell into
  `emoji_version_profile()`'s `version = NA` bucket, which is precisely what
  that verb exists to report, and `emoji_adoption_lag()` returned `NA` for
  them. A version describes the emoji, not one spelling of it, so the reference
  table now fills `version` across every glyph sharing a codepoint key -- the
  same normalisation the rest of the package already applied to names,
  shortcodes, types and lexicon joins. No key carries two different versions,
  so this only ever fills gaps; every one of the 1252 is recovered and the
  unknown-version row disappears for the full catalogue. Profile counts shift
  accordingly (Emoji 0.6 goes from 656 to 719 types), and `lag_days` is now
  computed where it previously could not be. A glyph with a genuinely unknown
  version is still reported rather than dropped.
* The ordering verbs now document how they settle ties, which several of them
  enforced in code without promising. `emoji_frequency()` already said
  "descending `n` with ties broken by the glyph so the order is deterministic";
  `top_n_emojis()`, `emoji_dfm()`, `emoji_ambiguity()` and
  `emoji_flag_ambiguous()` applied the same discipline but said nothing.
  `top_n_emojis()`'s `@return` now records the sort order, that the glyph order
  decides which side of the cut a straddling tie falls on, and that a corpus
  with fewer than `n` distinct emoji returns all of them rather than padding.
  `emoji_dfm()`'s records that emoji columns run in descending corpus total
  with ties broken by the glyph, computed in the C locale so the column order
  is safe to index by position and does not follow the session's collation.
  Both ambiguity verbs now state that `rank` uses `ties.method = "min"`: tied
  glyphs share the lowest rank of their group and the next distinct value skips
  ahead, so ranks are deliberately not consecutive. No behaviour changed.
* `?emoji_sentiment_lexicon` stated its coverage inconsistently. It read "969
  rows, covering about 19% of the distinct emoji tidyEmoji can detect (3790
  distinct codepoint keys)", but 969/3790 is 25.6%. The 19% is the right
  figure and the attribution was wrong: only 736 of the 969 rows resolve to a
  detectable emoji, and 736/3790 is 19.4% -- which is also exactly how many of
  the 3790 detectable emoji `emoji_sentiment()` scores. The paragraph now says
  so, and its arithmetic is checkable against the sentence that follows it
  (736 resolving + 233 absent = 969). The `?emoji_emotion_lexicon` figure
  needed no change: all 150 of its rows resolve, so 150/3790 = 4.0% was
  already exact.
* `emoji_search()`'s documentation now says how to get back from its
  `shortcode` column to a glyph. The column is the emoji's first alias, and
  passing it to `text_to_emoji()` recovers every row exactly, while `as_emoji()`
  resolves a bare string by Unicode name first and so returns a different emoji
  for the eleven strings that name one emoji and alias another (`dog`, `cat`,
  `cow`, `pig`, `tiger`, `mouse`, `rabbit`, `horse`, `whale`, `kiss`,
  `sunglasses`). That is the documented precedence rather than a defect, but
  `emoji_search()` advertised its result as ready for "piping into other verbs"
  without saying which path is safe. Its `@return` also now records that
  `keyword` is the empty string, not `NA`, when the query matched the name or a
  shortcode rather than a keyword.
* `emoji_lexicons()` no longer returns columns carrying stray element names
  after `register_emoji_lexicon()`. The registry is a named list, so the
  `lapply()`/`vapply()` that built the `dimensions` and `n` columns returned
  named results and `dplyr::bind_rows()` then padded the bundled rows with
  `""`. The tibble printed normally, which is why this went unnoticed, but
  extracting a column showed it: `emoji_lexicons()$n` printed a stray name
  header above the values. Both columns are now unnamed, and a test asserts
  that no verb returns a column with element names -- checked across the 42
  exported functions that return a data frame, with a custom lexicon
  registered.
* The declared R dependency is raised from `R (>= 3.5.0)` to `R (>= 4.1.0)`,
  which is the oldest R the package can actually be installed on. The old value
  was a promise it could not keep: the current `dplyr` and `tidyr` both require
  `R >= 4.1.0`, and `install.packages()` serves only current versions, so a user
  on R 3.5 or 4.0 got an opaque dependency-resolution failure instead of a clear
  message about their R version. Nothing in the package's own code needed more
  than R 3.5 -- the floor comes entirely from the dependency chain -- and no
  behaviour changed. A test now checks the declared minimum against the
  installed hard dependencies' own floors, since the CI matrix only reaches
  oldrel-1 and so cannot detect this class of drift.
* The introduction vignette described 68% of emoji-bearing entries as "the
  overwhelming majority" (and "the vast majority" in a figure's alt text) where
  the measured share carrying exactly one emoji is 68.2%. Both now say "about
  two-thirds".
* `text_to_emoji()` no longer claims flatly to be the inverse of
  `emoji_to_text()`. It is the inverse *up to the presentation selector*:
  because both directions resolve through the `U+FE0F`-stripped code-point key,
  an unqualified glyph and its fully-qualified form share one shortcode and the
  fully-qualified form is what comes back. Feeding the whole catalogue through
  and back preserves the key for all 5042 entries and the exact bytes for 79%
  of them; a second pass changes nothing. The details now say so, and say to
  compare with `emoji_key()` rather than string equality. They no longer
  attribute that 79% to the entries "that were already fully qualified": the
  two sets differ -- 212 unqualified entries keep their bytes and 92 qualified
  ones do not -- because which spelling comes back is decided by the shortcode
  table, not by the input's selectors.
* `as_emoji()`'s resolution order is now documented. It accepts names and
  shortcodes in one argument, and 464 strings belong to both namespaces -- the
  exact Unicode name of one emoji and a shortcode alias of another. It has
  always tried the exact Unicode name first, so `as_emoji("dog")` is the emoji
  named "dog" (`U+1F415`) rather than the one aliased `:dog:` (a dog face,
  `U+1F436`). For 17 of the 464 the namespaces disagree and `as_emoji()`
  differs from `text_to_emoji()` by design, since a `:dog:` token is explicitly
  a shortcode; both places now say which is which and how to ask for one
  namespace specifically. No behaviour changed.
* Emoji-dense rows no longer cost quadratic time. Five hot paths reached a
  character offset with `substr()`/`substring()`, which rescans a multi-byte
  string from its first byte on every call, so the work grew with the square of
  the emoji in a row: glyph slicing (used by nearly every verb), the splice in
  the translation verbs, the residual test in `emoji_ratio()`, the
  trailing-run walk-back behind `emoji_incongruity()`, and the per-occurrence
  window loop in `emoji_context()`, which handed the whole prefix and suffix to
  a windowing function that only ever needed the few tokens next to the glyph.
  The four that cut text around glyph spans now share one helper that converts
  the string once and slices code points past a threshold, keeping ordinary
  rows on the existing path; `emoji_context()` reads a bounded slice anchored
  at the glyph. Measured on a row holding 6400 emoji: `emoji_ratio()` about
  thirteen times faster, `emoji_summary()` and `emoji_sentiment()` about ten,
  the trailing-run walk-back about seven, `emoji_context()` about four, and
  every stage of the engine now scales linearly. Results are unchanged -- the
  fast paths are pinned to the slow ones by tests that compare them directly,
  and fall back whenever `utf8ToInt()` cannot represent the string.
* `README.md`'s `emoji_ambiguity()` line gained the annotation-count caveat
  that `?emoji_ambiguity` and the vignette already carried.
* Test coverage for this release, in one place rather than scattered through
  the notes above. The suite now also pins: every one of the 49 exports called
  as the *first* thing in a fresh session (several populate a shared cache
  lazily, which a suite running them in order cannot expose); the functional
  type recode as a clean partition of all 32 Unicode subgroups in *Smileys &
  Emotion* and *People & Body*; the pluggable-lexicon API through every
  consumer that documents it, registered and inline, sentiment- and
  emotion-shaped, full and partial; non-syntactic column names (`"my text"`,
  `"2024"`, `"if"`, `"x-y"`) and every tidyselect form that resolves to one
  column; 182 combinations of the enum and flag arguments; fourteen verb
  pipelines and the grouped contract end to end; the two internal
  optimisations that claim exact equivalence, against naive implementations;
  and `README.md` against `README.Rmd`'s prose, so it cannot drift unnoticed.
  Three tests that scanned `R/*.R` now walk the namespace instead, so they run
  inside `R CMD check` rather than skipping: skips there are down from 14 to 5,
  262 more assertions than at the start of the pass, and the five that remain
  cannot be reached from an installed package.


# tidyEmoji 0.3.0

## New features

* `emoji_emotion()` scores each row's emoji across the eight Plutchik emotions
  (anger, anticipation, disgust, fear, joy, sadness, surprise, trust), using the
  new bundled `emoji_emotion_lexicon` (EmoTag1200, Shoeb & de Melo 2020, MIT).
  Supports a long form (`long = TRUE`) with one row per (row, emotion).
* `emoji_emotion_label()` adds the dominant emotion per row.
* A pluggable lexicon API: `emoji_lexicons()` lists bundled and registered
  lexicons, `register_emoji_lexicon()` adds your own, and `emoji_score()` is the
  generic scorer all the verbs share. `emoji_sentiment()` gains a `lexicon`
  argument (default `"novak2015"`, unchanged behaviour).
* Relational analysis. `emoji_pairs()` returns a tidy, graph-ready edge list
  (`item1`, `item2`, `n`) of the emoji that co-occur in the same document —
  each row is a document, or supply `doc_id` to pool rows — with
  `directed = TRUE` to order pairs by first appearance. `emoji_cooccurrence()`
  is the same with an optional `diagonal` (each emoji's document frequency).
  `emoji_ngrams()` slides a window over each row's emoji in reading order and
  returns one row per consecutive n-gram.
* Structural metrics. `emoji_position()` reports where emoji sit in each text
  (first/last character position and mean relative position in `[0, 1]`),
  `emoji_density()` reports emoji per character and per token, and
  `emoji_ratio()` reports the share of the text's characters that are emoji
  plus an `.emoji_only` flag.
* `emoji_dfm()` builds a document-by-emoji feature table (weightings: counts,
  binary, tf-idf), keeping every document — including emoji-free ones — so the
  result binds row-for-row to outcome columns in modelling workflows.
* The corpus-level verbs above (`emoji_pairs()`, `emoji_cooccurrence()`,
  `emoji_ngrams()`, `emoji_dfm()`) canonicalise glyphs through the package's
  codepoint key, so qualified and unqualified forms of the same emoji (for
  example the victory hand with and without `U+FE0F`) count as one
  node/feature. `emoji_frequency()` intentionally still reports the exact
  extracted glyph.
* `emoji_to_text()` replaces emoji in a text column with their Unicode names or
  shortcodes (demojize — useful for accessibility and NLP preprocessing), and
  `text_to_emoji()` is the inverse (emojize).
* Vector helpers `as_emoji_name()`, `as_emoji_shortcode()` and `as_emoji()` for
  ad-hoc conversion.
* `emoji_search()` finds emoji by keyword, name or shortcode and returns a tidy
  tibble of matches.
* New bundled dataset `emoji_emotion_lexicon`.
* tidyEmoji has a hex logo! It appears in the README and on the pkgdown site
  (`man/figures/logo.svg` is the vector master, `logo.png` the raster copy).

## Improvements and fixes

* **Grapheme-aware detection now covers newer zero-width-joiner sequences.**
  The upstream emoji regex only knows the ZWJ sequences that were current when
  it was built, so it reported later ones — face exhaling, face with spiral
  eyes, heart on fire, people holding hands, the skin-toned handshakes,
  "woman: blond hair", and around 630 others — as their *component* emoji.
  tidyEmoji now re-joins them (a ZWJ between two emoji always binds them into
  one grapheme cluster). Previously such an emoji inflated counts, resolved to
  the wrong name, split into several co-occurrence nodes and stopped
  `emoji_ratio()` recognising an emoji-only row; all of that is fixed. Emoji
  separated by anything other than a ZWJ are unaffected.
* Extraction and location are now sliced from the same spans, so no verb can
  disagree with another about where an emoji starts and ends.
* `text_to_emoji()` no longer misses a `:shortcode:` that follows an unrelated
  colon. `"meet at 10:30 :grinning:"` and `"https://example.org :grinning:"`
  previously came back unchanged, because the permissive `:...:` pattern
  consumed the shortcode's opening colon; shortcode tokens are now matched on
  the character set GitHub-style aliases actually use.
* `emoji_pairs()` and `emoji_dfm()` order glyphs in the C locale, so which
  glyph lands in `item1` and the order of a dfm's tied columns no longer depend
  on the session's collation. Results are now reproducible across machines.
* `emoji_lexicons()` no longer reports the glyph column as a score dimension
  for a lexicon registered with a `by` other than `"emoji"`.
* `emoji_emotion(long = TRUE)` no longer drops a user column named
  `.row_number`.
* `emoji_ngrams(n = Inf)` gives the documented error instead of a coercion
  warning followed by "missing value where TRUE/FALSE needed".
* `emoji_to_text()` is several times faster: it locates emoji once for the
  whole column rather than once per row.
* `emoji_density()` returns `.emoji_per_token = 0` (not `NA`) for
  whitespace-only text, matching `.emoji_per_char` and the documented
  "no emoji -> 0" contract (#1).
* `as_emoji()` accepts the spaced Unicode names produced by `as_emoji_name()`
  (routing through the reference table), so `as_emoji(as_emoji_name(x))`
  round-trips instead of returning `NA` (#2).
* `?emoji_sentiment_lexicon` now explains which lexicon entries are stored as
  unqualified, text-presentation code points (the bare heart `U+2764` without
  `U+FE0F`, the white smiling face, the heavy check mark, ...) and are
  therefore not detected in text, and notes that the qualified form resolves to
  the same entry (#3).
* The help pages no longer embed raw emoji glyphs, so the reference manual
  builds as PDF; `?register_emoji_lexicon` no longer points at an internal
  development file.
* `emoji_search()` matches literally, so queries containing regex
  metacharacters (for example the `+1` alias) are safe and cannot error.
* `emoji_to_text(format = "shortcode")` now always emits the emoji's canonical
  (first) GitHub-style alias — the same one reported by `emoji_frequency()` and
  `as_emoji_shortcode()` — and the `wrap` template is honoured. Emoji with no
  known name/shortcode are left in place rather than dropped from the text.
* `emoji_to_text()` and `text_to_emoji()` keep `NA` text entries as `NA`.
* `emoji_emotion()` and `emoji_emotion_label()` accept registered or
  data-frame emotion lexicons (any subset of the eight Plutchik dimensions),
  not just the bundled `"emotag1200"`.
* Registered lexicons resolve through their stored normalised key, so
  `register_emoji_lexicon(by = )` works with any glyph column name in
  `emoji_sentiment()` and `emoji_emotion()`.
* `emoji_frequency()` (and therefore `top_n_emojis()`) breaks count ties by
  the glyph, making the output order deterministic.
* `emoji_lexicons()` no longer lists a custom lexicon's glyph/key columns among
  its score dimensions.
* The package help page (`?tidyEmoji`) documents the output and naming
  contract shared by all verbs.
* rlang moved from Suggests to Imports (tidy-eval capture of the new optional
  `doc_id` argument); it was already a hard transitive dependency, so the
  installed footprint is unchanged.
* Grouped data frames passed to `emoji_pairs()`, `emoji_cooccurrence()` or
  `emoji_dfm()` warn that grouping is ignored — use `doc_id` to express
  per-group structure.
* The vignette header no longer carries a build date.
* DESCRIPTION Title and Description broadened to cover emotions, translation,
  search, co-occurrence, structural metrics and feature tables; version bumped
  to 0.3.0.

# tidyEmoji 0.2.1

## Improvements and fixes

* Emoji name, shortcode and category now resolve through the same
  codepoint-normalised key as sentiment, so emoji carrying the `U+FE0F` variation
  selector no longer get `NA` metadata, are no longer dropped by
  `emoji_categorize()`, and no longer disappear from `top_n_emojis(duplicated =
  TRUE)`.
* The whole package now agrees on what "contains an emoji" means:
  `emoji_summary()` and `emoji_filter()` use the same detection as the extraction
  verbs.
* `emoji_sentiment()` gains `.emoji_n_scored` (emoji actually found in the
  lexicon), distinct from `.emoji_n`.
* `top_n_emojis(n =)` counts distinct emoji rather than rows, breaks ties
  deterministically, keeps emoji that have no GitHub-style alias, and preserves
  the exact extracted glyph in `duplicated` mode (one row per distinct alias;
  `left_join` instead of `inner_join`).
* `emoji_extract_unnest()` now uses `.row_number` (dotted) to avoid collision
  with user columns and `dplyr::row_number`.
* `emoji_summary()` column names renamed from `emoji_tweets`/`total_tweets` to
  `n_with_emoji`/`n_total`. The old names are no longer available in this
  release.
* `emoji_tweets()` is soft-deprecated in favour of `emoji_filter()`.
* Faster on large corpora: codepoint keys are computed once over the unique glyph
  set rather than per row in `emoji_sentiment()` and `emoji_categorize()`.
* Grouped data frames passed to `emoji_summary()`, `emoji_frequency()` and
  `top_n_emojis()` now warn that grouping is ignored (per-group results land in
  1.0).
* Lifecycle badge downgraded from stable to maturing.
* Vignette sample renamed from `ata_tweets.rda` (a CSV misnamed `.rda`) to
  `ata_tweets.csv` and downsampled from 10k to 2k rows. Vignette language
  updated to be less Twitter-specific.
* Crosswalk datasets rebuilt with a `key` column for normalised joins.

# tidyEmoji 0.2.0

tidyEmoji is now positioned as a general toolkit for emoji in **any** text
column (social-media posts, reviews, chat logs, survey responses, ...), not just
tweets.

## New features

* `emoji_sentiment()` scores the emoji in each row using the bundled
  `emoji_sentiment_lexicon` (the Emoji Sentiment Ranking of Kralj Novak et al.,
  2015), returning a mean sentiment in `[-1, 1]`.
* `emoji_frequency()` returns the count of *every* emoji in a text column, with
  name, shortcode and category. `top_n_emojis()` is now a thin wrapper over it.
* `emoji_tokens()` expands data to one row per emoji occurrence with its name,
  category and sentiment score — a tidy, "one-token-per-row" shape.
* `emoji_filter()` is a clearer, text-agnostic name for `emoji_tweets()` (which
  is kept as a synonym).
* New bundled dataset `emoji_sentiment_lexicon`.

## Improvements and fixes

* **Grapheme-aware detection.** Extraction now keeps skin-tone modifiers and
  zero-width-joiner sequences intact. Previously a family emoji
  (👨‍👩‍👧‍👦) was miscounted as four separate people and a skin-tone
  thumbs-up split into two "emoji"; both are now counted as one.
* **Much faster.** Detection and counting no longer build a multi-thousand-way
  regular expression on every call or scan the text once per known emoji;
  `top_n_emojis()` in particular is dramatically faster on large inputs.
* `top_n_emojis()` no longer emits a many-to-many join warning, and reports the
  emoji's canonical shortcode (e.g. `mask`) by default.
* All verbs now return tibbles consistently (`emoji_tweets()` previously
  returned a plain data frame), and `emoji_extract_unnest()` no longer prints a
  grouping message.
* Bundled emoji data refreshed against the current Unicode emoji list (via
  `data-raw/`).

## Breaking changes

* Arguments are renamed `tweet_tbl` -> `data` and `tweet_text` -> `text`. Code
  that passed these positionally (e.g. `df %>% emoji_summary(text_col)`) is
  unaffected; update any calls that named the old arguments.
* `top_n_emojis(duplicated_unicode = "yes"/"no")` is deprecated in favour of the
  logical `duplicated = TRUE/FALSE`. The old argument still works with a warning.

# tidyEmoji 0.1.1

- Changed the package metadata

# tidyEmoji 0.1.0

- Initial release to CRAN.
