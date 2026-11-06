# data-raw/crosswalks.R
# -----------------------------------------------------------------------------
# Builds the emoji catalogue tidyEmoji detects and joins against, and the two
# crosswalk datasets derived from it:
#   * R/sysdata.rda              the catalogue itself (.emoji_catalogue) and
#                                where it came from (.emoji_catalogue_meta),
#                                the standardized variation sequences the
#                                hidden-payload scanner reads (0.7.0), and the
#                                snapshot of the {emoji} package's frozen data
#                                (.emoji_upstream, 0.7.0)
#   * emoji_unicode_crosswalk    one row per (shortcode, glyph) pair
#   * category_unicode_crosswalk one row per category, glyphs collapsed by "|"
#
# SOURCE OF TRUTH, decided for 0.6.0 and not to be re-merged:
#
#   the CATALOGUE comes from Unicode's emoji-test.txt: every glyph, its
#   qualification status, the emoji version that introduced it, its CLDR
#   short name, its group and its subgroup;
#
#   the VOCABULARY comes from the {emoji} package: the CLDR keywords and the
#   GitHub-style shortcode aliases, which emoji-test.txt does not carry.
#   Since 0.7.0 it is read from an attributed snapshot of that package's
#   frozen data, data-raw/emoji-upstream.rds, so tidyEmoji no longer imports
#   it.
#
# Until 0.5.0 both came from emoji::emojis, so the catalogue could only be as
# current as {emoji}, which stayed at Emoji 16.0 through two Unicode releases.
# Unicode publishes the RGI list at a stable, unversioned URL; reading it here
# makes every future Unicode release a rerun of this script rather than a wait.
#
# Nothing is fetched at build, check, test or run time. This script is run by
# a human, its input is committed beside it as data-raw/emoji-test.txt, and its
# output is committed as .rda.
#
# Usage, from the package root with the current tidyEmoji installed:
#
#   source("data-raw/crosswalks.R")                      # rebuild from the copy
#   Sys.setenv(TIDYEMOJI_FETCH = "true")                 # refresh the copy from
#   source("data-raw/crosswalks.R")                      #   Unicode's latest/ first
#
# TIDYEMOJI_EMOJI_TEST=<path> builds from another file instead (the 16.0 one,
# say), which is how the switch from emoji::emojis was shown to reproduce the
# shipped crosswalks exactly. TIDYEMOJI_WRITE=false builds the objects without
# writing them, which is what the test suite does.
#
# Record the version you GOT, not the one you asked for. From Emoji 17.0 on the
# per-version directories stopped (/Public/emoji/17.0/ is 404) and only
# latest/ is maintained, so the URL says nothing about what it served. The
# version and date are read out of the file's own header instead.
# -----------------------------------------------------------------------------

library(dplyr)
library(tidyr)

stopifnot(requireNamespace("emoji", quietly = TRUE))

latest_url <- "https://www.unicode.org/Public/emoji/latest/emoji-test.txt"
input <- Sys.getenv("TIDYEMOJI_EMOJI_TEST",
                    file.path("data-raw", "emoji-test.txt"))
if (identical(tolower(Sys.getenv("TIDYEMOJI_FETCH")), "true")) {
  utils::download.file(latest_url, input, mode = "wb", quiet = TRUE)
}
stopifnot(file.exists(input))

# Parse ------------------------------------------------------------------------
# A data line is
#   1F600  ; fully-qualified  # <glyph> E1.0 grinning face
# under "# group:" and "# subgroup:" headers. The glyph in the comment is
# checked against the code points, so a file mangled in transit (an editor
# re-encoding it, a proxy) stops the build instead of shipping.
lines <- readLines(input, encoding = "UTF-8", warn = FALSE)
header <- function(field) {
  hit <- grep(paste0("^# ", field, ":"), lines, value = TRUE)[1L]
  if (is.na(hit)) stop("emoji-test.txt has no `# ", field, ":` header.")
  trimws(sub(paste0("^# ", field, ":"), "", hit))
}
file_version <- header("Version")
file_date <- sub(",.*$", "", header("Date"))

rx <- paste0("^([0-9A-F]+(?: [0-9A-F]+)*)\\s*;\\s*",
             "(component|fully-qualified|minimally-qualified|unqualified)",
             "\\s*#\\s*(\\S+)\\s+E([0-9]+\\.[0-9]+)\\s+(.+)$")
group <- subgroup <- NA_character_
rows <- vector("list", length(lines))
k <- 0L
for (ln in lines) {
  if (startsWith(ln, "# group: ")) {
    group <- sub("^# group: ", "", ln)
    next
  }
  if (startsWith(ln, "# subgroup: ")) {
    subgroup <- sub("^# subgroup: ", "", ln)
    next
  }
  if (!grepl("^[0-9A-F]", ln)) next
  m <- regmatches(ln, regexec(rx, ln, perl = TRUE))[[1L]]
  if (length(m) != 6L) stop("Cannot parse emoji-test.txt line: ", ln)
  cps <- strtoi(strsplit(m[2L], " ", fixed = TRUE)[[1L]], 16L)
  glyph <- intToUtf8(cps)
  if (!identical(enc2utf8(m[4L]), glyph)) {
    stop("The glyph does not match its code points on line: ", ln)
  }
  k <- k + 1L
  rows[[k]] <- list(glyph, m[3L], m[5L], m[6L], group, subgroup)
}
rows <- rows[seq_len(k)]
col <- function(j) vapply(rows, `[[`, character(1), j)
.emoji_catalogue <- tibble::tibble(
  emoji    = col(1L),
  status   = col(2L),
  version  = col(3L),
  name     = col(4L),
  group    = col(5L),
  subgroup = col(6L)
)

# The file states its own totals; hold the parse to them.
counts <- table(.emoji_catalogue$status)
for (s in c("fully-qualified", "minimally-qualified", "unqualified",
            "component")) {
  hit <- grep(paste0("^# ", s, " *: *[0-9]+"), lines, value = TRUE)
  stated <- as.integer(sub(".*: *", "", hit[length(hit)]))
  if (!identical(as.integer(counts[[s]]), stated)) {
    stop(sprintf("Parsed %d %s rows; the file states %d.",
                 as.integer(counts[[s]]), s, stated))
  }
}
stopifnot(!anyDuplicated(.emoji_catalogue$emoji),
          !anyNA(.emoji_catalogue$group), !anyNA(.emoji_catalogue$subgroup))

# The highest version in the file is the version the header names. If they
# ever disagree, the header is the one recorded, and this says so.
top <- max(as.numeric(.emoji_catalogue$version))
if (!isTRUE(all.equal(top, as.numeric(file_version)))) {
  warning(sprintf("Header says Emoji %s, newest row is E%s.",
                  file_version, format(top, nsmall = 1L)))
}

.emoji_catalogue_meta <- list(
  emoji_version = file_version,
  file_date = file_date,
  source = latest_url,
  rows = nrow(.emoji_catalogue)
)

# Standardized variation sequences (0.7.0) -----------------------------------
# The hidden-payload scanner (R/emoji-hidden.R) calls a variation selector in
# U+FE00..U+FE0D hidden when the sequence it forms with the code point before
# it is not one Unicode defines, and StandardizedVariants.txt in the UCD is
# the list of the ones it defines (mathematical symbols, CJK compatibility
# forms, Mongolian, Phags-pa and the rest). U+FE0E and U+FE0F are not in it:
# emoji presentation sequences are in emoji-variation-sequences.txt, and a
# single one of those two is never hidden anyway. Read from the UCD of the
# same Unicode version as the catalogue, committed beside it, and refreshed
# with it.
sv_input <- Sys.getenv("TIDYEMOJI_STD_VARIANTS",
                       file.path("data-raw", "StandardizedVariants.txt"))
if (identical(tolower(Sys.getenv("TIDYEMOJI_FETCH")), "true")) {
  utils::download.file(
    paste0("https://www.unicode.org/Public/", file_version,
           ".0/ucd/StandardizedVariants.txt"),
    sv_input, mode = "wb", quiet = TRUE)
}
stopifnot(file.exists(sv_input))
sv_lines <- readLines(sv_input, encoding = "UTF-8", warn = FALSE)
sv_head <- sv_lines[1L]
if (!grepl(paste0("^# StandardizedVariants-", file_version, "\\.0\\.txt$"),
           sv_head)) {
  stop("StandardizedVariants.txt is not the UCD file for Unicode ",
       file_version, ".0: its first line is ", sv_head)
}
sv_data <- grep("^[0-9A-F]+ [0-9A-F]+;", sv_lines, value = TRUE)
sv_pair <- sub(";.*$", "", sv_data)
sv_cps <- lapply(strsplit(trimws(sv_pair), " ", fixed = TRUE), strtoi, 16L)
stopifnot(all(lengths(sv_cps) == 2L))
sv_vs <- vapply(sv_cps, `[[`, integer(1), 2L)
keep <- sv_vs >= 0xFE00L & sv_vs <= 0xFE0DL
# "base selector" in upper-case hex without padding, the shape emoji_key()
# writes, so a lookup is one paste() away
.emoji_std_variants <- unique(vapply(sv_cps[keep], function(c) {
  paste(sprintf("%X", c), collapse = " ")
}, character(1)))
.emoji_std_variants_meta <- list(
  file = sub("^# ", "", sv_head),
  date = sub("^# Date: ([0-9-]+).*$", "\\1",
             grep("^# Date:", sv_lines, value = TRUE)[1L]),
  sequences = length(.emoji_std_variants)
)
message("standardized variants:      ", .emoji_std_variants_meta$file, ", ",
        length(.emoji_std_variants), " sequences with U+FE00..U+FE0D")

# Emoji variation sequences (0.7.0, D10) ------------------------------------
# emoji-variation-sequences.txt lists every base that has a text-style
# (U+FE0E) and an emoji-style (U+FE0F) sequence. Detection asks it about a
# detected glyph followed by U+FE0E: that is the writer asking for the text
# form, so under presentation = "emoji" the glyph is text, not an emoji. Same
# Unicode version as the catalogue, refreshed with it.
evs_input <- Sys.getenv("TIDYEMOJI_EMOJI_VARIATIONS",
                        file.path("data-raw", "emoji-variation-sequences.txt"))
if (identical(tolower(Sys.getenv("TIDYEMOJI_FETCH")), "true")) {
  utils::download.file(
    paste0("https://www.unicode.org/Public/", file_version,
           ".0/ucd/emoji/emoji-variation-sequences.txt"),
    evs_input, mode = "wb", quiet = TRUE)
}
stopifnot(file.exists(evs_input))
evs_lines <- readLines(evs_input, encoding = "UTF-8", warn = FALSE)
evs_version <- sub("^# Version: ", "",
                   grep("^# Version:", evs_lines, value = TRUE)[1L])
if (!identical(evs_version, paste0(file_version, ".0"))) {
  stop("emoji-variation-sequences.txt is for Unicode ", evs_version,
       ", not ", file_version, ".0 as the catalogue is.")
}
evs_text <- grep("^[0-9A-F]+ FE0E +; text style;", evs_lines, value = TRUE)
.emoji_text_style_bases <- strtoi(sub(" .*$", "", evs_text), 16L)
stopifnot(!anyNA(.emoji_text_style_bases),
          !anyDuplicated(.emoji_text_style_bases))
message("emoji variation sequences:  ", length(.emoji_text_style_bases),
        " bases with a text-style sequence")

# Vocabulary -------------------------------------------------------------------
# The GitHub-style aliases, by exact spelling. A glyph newer than {emoji} has
# none, and keeps none: shortcodes are not invented here.
#
# The {emoji} package has not changed since 16.0.0 (2024-10-28) and stops at
# Emoji 16.0, so since 0.7.0 tidyEmoji reads a snapshot of the four objects it
# used from it, the aliases and keywords of emoji::emojis, emoji::emoji_name
# and emoji::emoji_rx, under {emoji}'s MIT licence (inst/LICENSE.note). It is
# committed as data-raw/emoji-upstream.rds, so the build repeats offline, and
# TIDYEMOJI_SNAPSHOT=true takes it again from the installed {emoji}; a test
# compares the two whenever {emoji} is installed, so a new release is noticed.
upstream_path <- Sys.getenv("TIDYEMOJI_EMOJI_UPSTREAM",
                            file.path("data-raw", "emoji-upstream.rds"))
if (identical(tolower(Sys.getenv("TIDYEMOJI_SNAPSHOT")), "true")) {
  stopifnot(requireNamespace("emoji", quietly = TRUE))
  e <- emoji::emojis
  saveRDS(list(version = as.character(utils::packageVersion("emoji")),
               emoji = e$emoji, aliases = e$aliases, keywords = e$keywords,
               name = emoji::emoji_name, rx = emoji::emoji_rx),
          upstream_path, compress = "xz")
}
stopifnot(file.exists(upstream_path))
.emoji_upstream <- readRDS(upstream_path)
stopifnot(identical(names(.emoji_upstream),
                    c("version", "emoji", "aliases", "keywords", "name", "rx")))
message("{emoji} snapshot:            ", .emoji_upstream$version, ", ",
        length(.emoji_upstream$emoji), " glyphs")
aliases <- .emoji_upstream$aliases[match(.emoji_catalogue$emoji,
                                         .emoji_upstream$emoji)]
aliases[vapply(aliases, is.null, logical(1))] <- list(character(0))

# emoji_unicode_crosswalk -----------------------------------------------------
# Historically this table has one row per *alias* (GitHub-style shortcode), so a
# single glyph can appear under several names (e.g. "grinning", "grinning_face").
emoji_unicode_crosswalk <- tibble::tibble(
  emoji_name = aliases,
  unicode = .emoji_catalogue$emoji,
  emoji_category = .emoji_catalogue$group
) %>%
  tidyr::unnest_longer(emoji_name) %>%
  filter(!is.na(emoji_name), emoji_name != "") %>%
  distinct(emoji_name, unicode, emoji_category) %>%
  as.data.frame(stringsAsFactors = FALSE)

# Add codepoint-normalised key (strip U+FE0F) for robust joining
# The package's own key function, not a copy of it. Two verbatim copies used
# to live in data-raw/, and both had drifted: neither had the guard that makes
# a selector-only string key to NA rather than "" (one sentinel, not two), and
# neither coerced or rejected undecodable input. The bundled `key` columns
# were therefore generated by a function that no longer matched the one used
# to look them up.
emoji_key2 <- function(glyphs) tidyEmoji:::emoji_key(glyphs)
emoji_unicode_crosswalk$key <- emoji_key2(emoji_unicode_crosswalk$unicode)

# category_unicode_crosswalk --------------------------------------------------
category_unicode_crosswalk <- .emoji_catalogue %>%
  distinct(group, emoji) %>%
  group_by(category = group) %>%
  summarise(unicodes = paste(emoji, collapse = "|"), .groups = "drop") %>%
  as.data.frame(stringsAsFactors = FALSE)

message("catalogue:                  Emoji ", file_version, " (", file_date,
        "), ", nrow(.emoji_catalogue), " rows")
message("emoji_unicode_crosswalk:    ", nrow(emoji_unicode_crosswalk), " rows")
message("category_unicode_crosswalk: ", nrow(category_unicode_crosswalk),
        " rows")

if (!identical(tolower(Sys.getenv("TIDYEMOJI_WRITE")), "false")) {
  save(.emoji_catalogue, .emoji_catalogue_meta, .emoji_std_variants,
       .emoji_std_variants_meta, .emoji_text_style_bases, .emoji_upstream,
       file = file.path("R", "sysdata.rda"), compress = "xz")
  save(emoji_unicode_crosswalk,
       file = file.path("data", "emoji_unicode_crosswalk.rda"), compress = "xz")
  save(category_unicode_crosswalk,
       file = file.path("data", "category_unicode_crosswalk.rda"),
       compress = "xz")
}
