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

save(emoji_sentiment_lexicon,
     file = "data/emoji_sentiment_lexicon.rda", compress = "xz")
