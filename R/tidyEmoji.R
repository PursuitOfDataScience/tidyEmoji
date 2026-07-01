#' @keywords internal
#' @aliases tidyEmoji-package
#' @importFrom dplyr %>%
"_PACKAGE"

# Quiet R CMD check notes about variables referenced via tidy evaluation and
# bundled datasets used inside package functions.
utils::globalVariables(c(
  ".",
  "emoji", "name", "shortcode", "group", "subgroup", "version", "n", "unicode",
  "emoji_name", "emoji_category", "key",
  ".row_number", ".emoji", ".emoji_unicode", ".emoji_count", ".emoji_category",
  ".emoji_name", ".emoji_sentiment", ".emoji_n", ".emoji_n_scored",
  ".emoji_score", ".emoji_emotion",
  ".emoji_anger", ".emoji_anticipation", ".emoji_disgust", ".emoji_fear",
  ".emoji_joy", ".emoji_sadness", ".emoji_surprise", ".emoji_trust",
  "anger", "anticipation", "disgust", "fear", "joy", "sadness", "surprise",
  "trust",
  "sentiment_score", "sentiment_label",
  "emoji_unicode_crosswalk", "category_unicode_crosswalk",
  "emoji_sentiment_lexicon", "emoji_emotion_lexicon"
))
