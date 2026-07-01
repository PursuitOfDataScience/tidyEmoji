# data-raw/crosswalks.R
# -----------------------------------------------------------------------------
# Regenerates the two bundled crosswalk datasets that ship with tidyEmoji:
#   * emoji_unicode_crosswalk   (one row per emoji name / glyph / category)
#   * category_unicode_crosswalk (one row per category, glyphs collapsed by "|")
#
# Source of truth: the `emojis` table from the {emoji} package, which tracks the
# Unicode emoji list. Re-run this script after upgrading {emoji} to refresh the
# bundled data for newly released emoji.
#
#   source("data-raw/crosswalks.R")
# -----------------------------------------------------------------------------

library(dplyr)
library(tidyr)

stopifnot(requireNamespace("emoji", quietly = TRUE))
emojis <- emoji::emojis

# emoji_unicode_crosswalk -----------------------------------------------------
# Historically this table has one row per *alias* (GitHub-style shortcode), so a
# single glyph can appear under several names (e.g. "grinning", "grinning_face").
emoji_unicode_crosswalk <- emojis %>%
  transmute(emoji_name = aliases,
            unicode = emoji,
            emoji_category = group) %>%
  tidyr::unnest_longer(emoji_name) %>%
  filter(!is.na(emoji_name), emoji_name != "") %>%
  distinct(emoji_name, unicode, emoji_category) %>%
  as.data.frame(stringsAsFactors = FALSE)

# Add codepoint-normalised key (strip U+FE0F) for robust joining
emoji_key2 <- function(glyphs) {
  vapply(glyphs, function(g) {
    if (is.na(g) || !nzchar(g)) return(NA_character_)
    cp <- utf8ToInt(g)
    cp <- cp[cp != 0xFE0F]
    paste(sprintf("%X", cp), collapse = " ")
  }, character(1), USE.NAMES = FALSE)
}
emoji_unicode_crosswalk$key <- emoji_key2(emoji_unicode_crosswalk$unicode)

# category_unicode_crosswalk --------------------------------------------------
category_unicode_crosswalk <- emojis %>%
  distinct(group, emoji) %>%
  group_by(category = group) %>%
  summarise(unicodes = paste(emoji, collapse = "|"), .groups = "drop") %>%
  as.data.frame(stringsAsFactors = FALSE)

message("emoji_unicode_crosswalk:   ", nrow(emoji_unicode_crosswalk), " rows")
message("category_unicode_crosswalk: ", nrow(category_unicode_crosswalk), " rows")

save(emoji_unicode_crosswalk,
     file = "data/emoji_unicode_crosswalk.rda", compress = "xz")
save(category_unicode_crosswalk,
     file = "data/category_unicode_crosswalk.rda", compress = "xz")
