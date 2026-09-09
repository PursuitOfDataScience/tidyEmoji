# data-raw/emoji_sentiment_lexicon.R
# -----------------------------------------------------------------------------
# Builds the bundled `emoji_sentiment_lexicon` dataset from the
# *Emoji Sentiment Ranking 1.0* (Kralj Novak, Smailovic, Sluban & Mozetic 2015).
#
#   Kralj Novak P, Smailovic J, Sluban B, Mozetic I (2015) Sentiment of Emojis.
#   PLoS ONE 10(12): e0144296. doi:10.1371/journal.pone.0144296
#
# Data:    http://hdl.handle.net/11356/1048  (CLARIN.SI) / figshare 1600931
# License: Creative Commons Attribution-ShareAlike 4.0 International (CC BY-SA 4.0)
#
# The sentiment score is the standard measure from the paper:
#   score = (positive - negative) / occurrences ,   in [-1, +1]
# and `sentiment_label` is derived from the sign of that score.
#
#   source("data-raw/emoji_sentiment_lexicon.R")
# -----------------------------------------------------------------------------

library(dplyr)

# A faithful copy of the Emoji Sentiment Ranking 1.0 CSV.
url <- "https://raw.githubusercontent.com/omkar-foss/emosent-py/master/emosent/data/Emoji_Sentiment_Data_v1.0.csv"

raw <- readr::read_csv(url, show_col_types = FALSE)

emoji_sentiment_lexicon <- raw %>%
  transmute(
    emoji          = Emoji,
    occurrences    = as.integer(Occurrences),
    position       = Position,
    negative       = as.integer(Negative),
    neutral        = as.integer(Neutral),
    positive       = as.integer(Positive),
    sentiment_score = (positive - negative) / occurrences,
    sentiment_label = dplyr::case_when(
      sentiment_score > 0 ~ "positive",
      sentiment_score < 0 ~ "negative",
      TRUE                ~ "neutral"
    ),
    unicode_name   = `Unicode name`,
    unicode_block  = `Unicode block`
  ) %>%
  arrange(desc(occurrences)) %>%
  as.data.frame(stringsAsFactors = FALSE)

message("emoji_sentiment_lexicon: ", nrow(emoji_sentiment_lexicon), " emoji")
stopifnot(all(c("emoji", "sentiment_score", "sentiment_label") %in%
              names(emoji_sentiment_lexicon)))

# The two invariants the package relies on and never checked. The emotion
# script asserts both of its analogues; this one asserted only that three
# columns exist.
#
# 1. The class counts have to add up to `occurrences`. emoji_ambiguity_table()
#    recomputes n as negative + neutral + positive while the lexicon carries
#    `occurrences`, so if they ever disagreed emoji_sentiment() and
#    emoji_ambiguity() would report different evidence for the same glyph.
stopifnot(all(emoji_sentiment_lexicon$occurrences ==
              emoji_sentiment_lexicon$negative +
              emoji_sentiment_lexicon$neutral +
              emoji_sentiment_lexicon$positive))

# 2. No two rows may canonicalise to one code-point key. emoji_sentiment_map()
#    and emoji_ambiguity_table() both resolve duplicates first-wins, silently,
#    so a duplicate would make the score depend on row order -- exactly what
#    .emoji_lexicon_record() refuses to accept from a *user's* table.
local({
  k <- tidyEmoji:::emoji_key(emoji_sentiment_lexicon$emoji)
  stopifnot(!anyDuplicated(k[!is.na(k)]))
})

save(emoji_sentiment_lexicon,
     file = "data/emoji_sentiment_lexicon.rda", compress = "xz")
