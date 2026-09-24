# Reversible emoji preprocessing for language models

## The decision nobody writes down

Every pipeline that sends user text to a language model makes a choice
about emoji, and most make it by accident: a regex in a cleaning script
drops anything non-ASCII, and the decision never appears in the methods
section.

It is a consequential choice. An emoji is two or more tokens rather than
one character (estimated below: 2 for a plain smiley, 13 for a family),
models disambiguate them poorly, and the glyphs readers disagree about
are not the obvious ones. In the bundled Emoji Sentiment Ranking,
annotator disagreement runs *against* the strength of the sentiment:
[`emoji_ambiguity()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_ambiguity.md)’s
entropy correlates -0.31 with the absolute sentiment score, and averages
0.53 over the 374 glyphs scoring `abs(sentiment_score) >= 0.5` against
0.76 over the other 595. So a sentiment score alone does not tell you
which emoji are risky to strip.

Worse, most ways of removing emoji are one-way. If the pipeline has to
hand text back to a human, show a highlighted excerpt, or reconstruct
what was sent, a stripped emoji is gone.

[`emoji_sanitize()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sanitize.md)
turns that accident into one named argument, and this article is about
the property the argument’s values do *not* share: **reversibility**.
Only one policy both removes the emoji and survives a round trip.

``` r

library(tidyEmoji)
library(dplyr)
```

Everything here runs on the package’s declared dependencies. There are
no optional packages and no network calls.

## A corpus built to break things

A round trip that works on a smiley proves very little. The cases that
matter are the multi-code-point ones: an emoji with a skin-tone
modifier, a flag built from two regional indicators, a family built from
four people and three joiners, a keycap built from a digit plus a
presentation selector plus a combining enclosing mark, and a glyph whose
canonical spelling carries an invisible presentation selector.

``` r

awkward <- tibble::tibble(
  case = c("plain", "skin tone", "flag", "ZWJ family", "keycap",
           "bare heart", "no emoji"),
  text = c(
    "ship it \U0001f600 today",
    "nice work \U0001f44d\U0001f3fd",
    "landed in \U0001f1fa\U0001f1f8 already",
    paste("the whole",
          intToUtf8(c(0x1F468, 0x200D, 0x1F469, 0x200D,
                      0x1F467, 0x200D, 0x1F466)),
          "came"),
    paste("step", intToUtf8(c(0x31, 0xFE0F, 0x20E3)), "first"),
    paste("love it", intToUtf8(0x2764)),
    "nothing to see here"
  )
)

awkward %>%
  emoji_token_cost(text) %>%
  select(case, .emoji_n, .emoji_codepoints, .emoji_bytes,
         .emoji_token_estimate)
#> # A tibble: 7 × 5
#>   case       .emoji_n .emoji_codepoints .emoji_bytes .emoji_token_estimate
#>   <chr>         <int>             <int>        <int>                 <int>
#> 1 plain             1                 1            4                     2
#> 2 skin tone         1                 2            8                     4
#> 3 flag              1                 2            8                     4
#> 4 ZWJ family        1                 7           25                    13
#> 5 keycap            1                 3            7                     4
#> 6 bare heart        0                 0            0                     0
#> 7 no emoji          0                 0            0                     0
```

Note the third column. One visible emoji is not one code point, which is
the whole reason a hand-rolled substitution gets this wrong: the family
is seven code points and the keycap is three. The last column is why a
prompt budget notices: a plain smiley is estimated at two tokens and the
family at thirteen.

## The ladder, run rather than described

The five policies form a ladder of information loss.
[`?emoji_sanitize`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sanitize.md)
tabulates it; here it is executed on one row, so you can see what a
model would actually receive.

``` r

one <- awkward %>% filter(case == "ZWJ family")

for (p in c("keep", "shortcode", "name", "placeholder", "strip")) {
  cat(format(p, width = 12), "|",
      emoji_sanitize(one, text, policy = p)$text, "\n")
}
#> keep         | the whole 👨‍👩‍👧‍👦 came 
#> shortcode    | the whole :family_man_woman_girl_boy: came 
#> name         | the whole family: man, woman, girl, boy came 
#> placeholder  | the whole [emoji] came 
#> strip        | the whole came
```

Now put them back.
[`text_to_emoji()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/text_to_emoji.md)
is the inverse of the shortcode form, and the question is which policies
it can recover from.

``` r

restores <- function(policy, data = one) {
  sent <- emoji_sanitize(data, text, policy = policy)
  back <- text_to_emoji(sent, text)$text
  identical(back, data$text)
}

vapply(c("keep", "shortcode", "name", "placeholder", "strip"),
       restores, logical(1))
#>        keep   shortcode        name placeholder       strip 
#>        TRUE        TRUE       FALSE       FALSE       FALSE
```

Two policies survive, and only one of them is a real preprocessing step:
`"keep"` changes nothing, so the interesting answer is `"shortcode"`. It
is the only policy that both removes the emoji from the model’s input
and lets you reconstruct the user’s text afterwards.

### It holds on the awkward cases

``` r

awkward %>%
  mutate(
    sanitized = emoji_sanitize(., text, policy = "shortcode")$text,
    restored  = text_to_emoji(tibble::tibble(text = sanitized), text)$text,
    exact     = restored == text
  ) %>%
  select(case, sanitized, exact)
#> # A tibble: 7 × 3
#>   case       sanitized                                  exact
#>   <chr>      <chr>                                      <lgl>
#> 1 plain      ship it :grinning: today                   TRUE 
#> 2 skin tone  nice work :thumbs_up_medium_skin_tone:     TRUE 
#> 3 flag       landed in :us: already                     TRUE 
#> 4 ZWJ family the whole :family_man_woman_girl_boy: came TRUE 
#> 5 keycap     step :one: first                           TRUE 
#> 6 bare heart love it ❤                                  TRUE 
#> 7 no emoji   nothing to see here                        TRUE
```

All seven come back byte for byte, but the last two rows are exact for a
reason worth separating out: nothing was substituted in them at all. The
`"no emoji"` row is obvious. The `"bare heart"` row is the interesting
one, because it looks like an emoji and is not detected as one.

``` r

hearts <- tibble::tibble(
  spelling = c("bare U+2764", "qualified U+2764 U+FE0F"),
  text = c(paste("love it", intToUtf8(0x2764)),
           paste("love it", intToUtf8(c(0x2764, 0xFE0F))))
)

hearts %>% emoji_summary(text)
#> # A tibble: 1 × 2
#>   n_with_emoji n_total
#>          <int>   <int>
#> 1            1       2
```

One of the two is counted. Detection asks for emoji presentation, and a
bare `U+2764` carries text presentation, so it passes through
[`emoji_sanitize()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sanitize.md)
untouched and survives the round trip by never being touched. The fully
qualified spelling, which is what a keyboard emits, is detected and
restores byte for byte:

``` r

sanitized_hearts <- emoji_sanitize(hearts, text, policy = "shortcode")
sanitized_hearts$text
#> [1] "love it ❤"       "love it :heart:"
text_to_emoji(sanitized_hearts, text)$text == hearts$text
#> [1] TRUE TRUE
```

This is a detection limitation rather than a reversibility one, and it
is described under *Detection* in
[`?tidyEmoji`](https://pursuitofdatascience.github.io/tidyEmoji/reference/tidyEmoji-package.md).
It matters here because text that had its presentation selectors
stripped upstream will quietly keep its emoji through a policy that was
supposed to remove them.

## `wrap` is part of the contract, not a style choice

[`emoji_sanitize()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sanitize.md)
writes the shortcode as `:name:`, and
[`text_to_emoji()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/text_to_emoji.md)
looks for exactly that. Decorate the token and the emoji still comes
back, but the decoration stays behind. Remove the colons and nothing
comes back at all, silently, because the shortcode is now an ordinary
word.

``` r

show_wrap <- function(w) {
  sent <- emoji_sanitize(one, text, policy = "shortcode", wrap = w)
  back <- text_to_emoji(sent, text)$text
  cat(format(w, width = 9), "|",
      if (identical(back, one$text)) "restored    " else "NOT restored",
      "|", back, "\n")
}

invisible(lapply(c(":{x}:", "[:{x}:]", "<{x}>", "::{x}::"), show_wrap))
#> :{x}:     | restored     | the whole 👨‍👩‍👧‍👦 came 
#> [:{x}:]   | NOT restored | the whole [👨‍👩‍👧‍👦] came 
#> <{x}>     | NOT restored | the whole <family_man_woman_girl_boy> came 
#> ::{x}::   | NOT restored | the whole :👨‍👩‍👧‍👦: came
```

The restored text in the last column separates the two failures. With a
decorating wrap the emoji does come back and the decoration is left
stranded around it. With `<{x}>` nothing comes back at all: the
shortcode stays in the text as an ordinary word. That third row is the
one to watch for in a code review, because nothing errors, the text
looks cleaner, and the emoji are unrecoverable.

## Do not throw away the signal you just removed

Sanitising for the model does not mean losing the emoji information. The
point of doing this in tidyEmoji rather than with a regex is that the
same pipeline can carry the emoji-derived features forward as ordinary
columns, while the text column that goes to the model holds no emoji at
all.

``` r

corpus <- tibble::as_tibble(
  utils::read.csv(
    system.file("extdata", "ata_tweets.csv", package = "tidyEmoji"),
    encoding = "UTF-8", stringsAsFactors = FALSE
  )
)

prepared <- corpus %>%
  emoji_sentiment(full_text) %>%          # how positive were the emoji
  emoji_risk(full_text) %>%               # how much annotators disagreed
  emoji_token_cost(full_text) %>%         # what they cost in the prompt
  mutate(prompt_text = emoji_sanitize(., full_text,
                                      policy = "shortcode")$full_text)

prepared %>%
  filter(.emoji_n > 0) %>%
  select(.emoji_n, .emoji_sentiment, .emoji_ambiguity_mean,
         .emoji_token_estimate, prompt_text) %>%
  head(3)
#> # A tibble: 3 × 5
#>   .emoji_n .emoji_sentiment .emoji_ambiguity_mean .emoji_token_estimate
#>      <int>            <dbl>                 <dbl>                 <int>
#> 1        1          -0.0934                  1.06                     2
#> 2        1          -0.0934                  1.06                     2
#> 3        1          NA                      NA                        2
#> # ℹ 1 more variable: prompt_text <chr>
```

`prompt_text` is what you send. The four columns beside it are what you
would have destroyed, and they are the ones a model reads poorly anyway:
a disagreement score computed from how the lexicon’s human annotators
actually split over each glyph is not something a prompt recovers.

## What it saves, and how to measure it honestly

``` r

before <- corpus %>% emoji_token_cost(full_text)
after  <- prepared %>%
  select(full_text = prompt_text) %>%
  emoji_token_cost(full_text)

tibble::tibble(
  stage = c("original", "shortcode"),
  emoji = c(sum(before$.emoji_n), sum(after$.emoji_n)),
  emoji_bytes = c(sum(before$.emoji_bytes), sum(after$.emoji_bytes)),
  est_tokens = c(sum(before$.emoji_token_estimate),
                 sum(after$.emoji_token_estimate))
)
#> # A tibble: 2 × 4
#>   stage     emoji emoji_bytes est_tokens
#>   <chr>     <int>       <int>      <int>
#> 1 original    900        4437       2245
#> 2 shortcode     0           0          0
```

The sanitised column holds no emoji at all, so its emoji cost is zero.
That is not quite guaranteed: `"shortcode"` leaves a glyph it cannot
name in place, so a corpus carrying a ZWJ sequence too new for the
installed catalogue would still show a cost here. This one does not,
which is worth checking rather than assuming. `"strip"` is the policy
that clears the column whatever it is handed. (The bare heart above is a
different case: it is never detected, so it costs nothing here and
passes through every policy untouched.)

Treat the token figures as what they are called: `.emoji_token_estimate`
is an estimate. Pass your real tokeniser through
`emoji_token_cost(tokenizer = )` when the number goes in a budget, and
read `.emoji_bytes` and `.emoji_codepoints` when you want a fact rather
than a model of one.

## Which policy, by intent

| If the pipeline needs to | Use | Why |
|----|----|----|
| reconstruct the user’s text afterwards | `"shortcode"` | the only reversible removal |
| feed a screen reader or a human reading a log | `"name"` | reads as words, not as a token |
| record that an emoji was present, not which | `"placeholder"` | keeps position, drops identity |
| discard emoji entirely and never look back | `"strip"` | leaves no trace, and no way back |
| leave the text alone | `"keep"` | the explicit no-op, visible in a diff |

The middle three are not lesser versions of `"shortcode"`. They answer
different questions, and each is the right answer to one of them. What
matters is that the choice is now written down in the script rather than
implied by a regex.

## Put the versions in the methods section

Which glyphs exist, what they are called, and which shortcode maps to
which emoji all depend on versions. A round trip is reproducible only
against the catalogue that performed it.

``` r

emoji_provenance() %>% glimpse()
#> Rows: 1
#> Columns: 7
#> $ tidyEmoji         <chr> "0.5.0"
#> $ emoji_pkg         <chr> "16.0.0"
#> $ unicode_emoji     <chr> "16.0"
#> $ n_emoji           <int> 5042
#> $ sentiment_lexicon <chr> "novak2015 (969 emoji)"
#> $ emotion_lexicon   <chr> "emotag1200 (150 emoji)"
#> $ R                 <chr> "4.6.1"
```

## See also

- [`vignette("introduction", package = "tidyEmoji")`](https://pursuitofdatascience.github.io/tidyEmoji/articles/introduction.md)
  for the rest of the package: counting, categorising, sentiment and
  emotion scoring, co-occurrence, time series and model features.
- [`?emoji_sanitize`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_sanitize.md)
  for the reversibility table and the full `wrap` contract.
- [`?emoji_token_cost`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_token_cost.md)
  for what the estimate is and is not.
