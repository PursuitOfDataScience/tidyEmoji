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

# A faithful copy of the Emoji Sentiment Ranking 1.0 CSV, from the one commit
# of emosent-py that has ever touched it, committed xz-compressed under
# data-raw/lexicons/ so the dataset rebuilds offline and byte for byte (78,880
# bytes, md5 dd9960916aef9ac9411888534d60bc6f). TIDYEMOJI_FETCH=true downloads
# it again; TIDYEMOJI_LEXICONS names another directory to read it from.
url <- paste0("https://raw.githubusercontent.com/omkar-foss/emosent-py/",
              "5a18b51b9cc4f1087b810e2ec68f2078fffa2fac/emosent/data/",
              "Emoji_Sentiment_Data_v1.0.csv")
src <- file.path(Sys.getenv("TIDYEMOJI_LEXICONS",
                            file.path("data-raw", "lexicons")),
                 "Emoji_Sentiment_Data_v1.0.csv.xz")
if (identical(tolower(Sys.getenv("TIDYEMOJI_FETCH")), "true")) {
  tmp <- tempfile(fileext = ".csv")
  utils::download.file(url, tmp, mode = "wb", quiet = TRUE)
  con <- xzfile(src, open = "wb", compression = 9)
  writeBin(readBin(tmp, "raw", file.info(tmp)$size), con)
  close(con)
}

# Read as bytes and marked UTF-8, so the session's locale cannot touch the
# glyphs; empty fields and "NA" are missing, as readr::read_csv() had them.
raw <- utils::read.csv(xzfile(src), encoding = "UTF-8", check.names = FALSE,
                       na.strings = c("", "NA"), stringsAsFactors = FALSE,
                       colClasses = c(Position = "character"))

# R's own decimal parser, behind read.csv() and as.numeric(), is not
# correctly rounded: it reads one of the 969 positions below one unit in the
# last place off the nearest double, where readr, which built the bundled
# file, did not, and on a platform whose long double is a double it can miss
# more. Every value here is a plain decimal of at most nine places, so it is
# read exactly instead, as an integer over a power of ten: both are exact
# doubles, and IEEE division rounds correctly.
exact_decimal <- function(s) {
  stopifnot(all(grepl("^[0-9]+([.][0-9]{1,9})?$", s)))
  vapply(strsplit(s, ".", fixed = TRUE), function(p) {
    k <- if (length(p) > 1L) nchar(p[[2L]]) else 0L
    (as.numeric(p[[1L]]) * 10^k + if (k) as.numeric(p[[2L]]) else 0) / 10^k
  }, numeric(1))
}
raw$Position <- exact_decimal(raw$Position)

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

# Attribute order is part of the .rda but not of the value (identical()
# ignores it), and dplyr and tibble releases differ in it: dplyr 1.2 puts
# row.names first. Fix it at names, row.names, class, the order the bundled
# file has always had, so the rebuild is byte for byte whatever the toolchain.
emoji_sentiment_lexicon <- structure(
  unclass(emoji_sentiment_lexicon)[names(emoji_sentiment_lexicon)],
  row.names = c(NA, -nrow(emoji_sentiment_lexicon)), class = "data.frame")

if (!identical(tolower(Sys.getenv("TIDYEMOJI_WRITE")), "false")) {
  save(emoji_sentiment_lexicon,
       file = file.path("data", "emoji_sentiment_lexicon.rda"), compress = "xz")
}
