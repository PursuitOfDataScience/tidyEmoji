# data-raw/emoji_emotion_lexicon.R
# -----------------------------------------------------------------------------
# Builds the bundled `emoji_emotion_lexicon` dataset from EmoTag1200
# (Shoeb & de Melo 2020, EMNLP).
#
#   Abu Awal Md Shoeb, Gerard de Melo (2020). EmoTag1200: Understanding the
#   Association between Emojis and Emotions. EMNLP 2020.
#   https://aclanthology.org/2020.emnlp-main.720/
#
# Data:    https://github.com/abushoeb/EmoTag  (data/EmoTag1200-scores.csv)
# License: MIT
#
# EmoTag1200 contains human-annotated emotion-association scores in [0, 1] for
# the 8 Plutchik emotions (anger, anticipation, disgust, fear, joy, sadness,
# surprise, trust) for the 150 most popular Twitter emoji. We keep the glyph and
# all eight scores, drop the redundant hex code, and normalise the glyph through
# the same codepoint key (stripping U+FE0F) used everywhere else in the package
# so qualified text joins cleanly (see next_release.md §4.1).
#
#   source("data-raw/emoji_emotion_lexicon.R")
# -----------------------------------------------------------------------------

library(dplyr)

url <- "https://raw.githubusercontent.com/abushoeb/EmoTag/master/data/EmoTag1200-scores.csv"

raw <- readr::read_csv(url, show_col_types = FALSE)

# Codepoint key (strip U+FE0F) so qualified glyphs in user text resolve to the
# (unqualified) emoji stored in the lexicon.
emoji_key2 <- function(glyphs) {
  vapply(glyphs, function(g) {
    if (is.na(g) || !nzchar(g)) return(NA_character_)
    cp <- utf8ToInt(g)
    cp <- cp[cp != 0xFE0F]
    paste(sprintf("%X", cp), collapse = " ")
  }, character(1), USE.NAMES = FALSE)
}

emotions <- c("anger", "anticipation", "disgust", "fear",
              "joy", "sadness", "surprise", "trust")

emoji_emotion_lexicon <- raw %>%
  transmute(
    emoji = emoji,
    name  = name,
    anger        = as.numeric(anger),
    anticipation = as.numeric(anticipation),
    disgust      = as.numeric(disgust),
    fear         = as.numeric(fear),
    joy          = as.numeric(joy),
    sadness      = as.numeric(sadness),
    surprise     = as.numeric(surprise),
    trust        = as.numeric(trust)
  ) %>%
  filter(!is.na(emoji), emoji != "") %>%
  mutate(key = emoji_key2(emoji)) %>%
  # If two stored glyphs collapse to the same key, keep the first.
  group_by(key) %>%
  slice(1L) %>%
  ungroup() %>%
  select(key, emoji, name, all_of(emotions)) %>%
  as.data.frame(stringsAsFactors = FALSE)

message("emoji_emotion_lexicon: ", nrow(emoji_emotion_lexicon), " emoji across ",
        length(emotions), " emotions")
stopifnot(all(emotions %in% names(emoji_emotion_lexicon)))
stopifnot(!anyDuplicated(emoji_emotion_lexicon$key))

save(emoji_emotion_lexicon,
     file = "data/emoji_emotion_lexicon.rda", compress = "xz")
