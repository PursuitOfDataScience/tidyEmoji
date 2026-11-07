# data-raw/hidden-corpora.R
# -----------------------------------------------------------------------------
# The hidden-payload scan (0.7.0, D8) on real text: how many rows it flags,
# and whether every rewriting policy returns the rest byte for byte. The
# release gate re-measures this rather than trusting the roadmap's figure.
#
# Inputs, none of them bundled (pass the paths as arguments):
#
#   1. the 2,000 posts of the retired corpus, inst/extdata/ata_tweets.csv in
#      `git show v0.6.0`, column full_text;
#   2. OASST2's "ready" messages file, 2023-11-05_oasst2_ready.messages.jsonl.gz
#      (data-raw/oasst.R pins the release), 135,174 messages;
#   3. WildChat-1M's first shard, data/train-00000-of-00014.parquet, as one row
#      per turn in an Arrow IPC stream (hash, role, content). pyarrow does it in
#      a few lines: read conversation_hash and conversation, list_flatten the
#      conversations, and drop the four NUL characters the shard holds, which
#      an R string cannot.
#
#   Rscript data-raw/hidden-corpora.R tweets.csv ready.jsonl.gz turns.arrows
#
# Run on 2026-11-06: 482,010 rows; 0, 0 and 1 flagged. The one is an assistant
# turn in WildChat holding a stray U+E0001, the deprecated language tag, among
# decorative letters; removing it is the only change to that row. Every other
# row checked comes back byte for byte under all five policies and under
# emoji_to_text(): all of the first two corpora and the 2,809 other WildChat
# turns that carry an emoji, a selector or a tag, 139,983 rows. Selector runs
# of two or more: none anywhere. Tag characters: only the Scotland and Wales
# flags, and that U+E0001.

args <- commandArgs(TRUE)
stopifnot(length(args) == 3L)
library(tidyEmoji)
cat("tidyEmoji", as.character(utils::packageVersion("tidyEmoji")), "\n")

tw <- utils::read.csv(args[1], encoding = "UTF-8", stringsAsFactors = FALSE)$full_text
con <- gzfile(args[2], open = "rb")
ol <- readLines(con, encoding = "UTF-8", warn = FALSE)
close(con)
oa <- vapply(ol, function(l) jsonlite::fromJSON(l, simplifyVector = FALSE)$text,
             character(1), USE.NAMES = FALSE)
rm(ol)
wc <- as.data.frame(nanoarrow::read_nanoarrow(args[3]))$content

vs_rx <- "[\\x{FE00}-\\x{FE0F}\\x{E0100}-\\x{E01EF}]"
tag_rx <- "[\\x{E0000}-\\x{E007F}]"

measure <- function(name, v, check_all = TRUE) {
  v[is.na(v)] <- ""
  d <- tibble::tibble(text = v)
  h <- emoji_hidden(d, text)
  flagged <- h$.emoji_n_hidden > 0L
  has_vs <- stringi::stri_detect_regex(v, vs_rx)
  has_tag <- stringi::stri_detect_regex(v, tag_rx)
  bearing <- has_vs | has_tag |
    stringi::stri_detect_regex(v, "\\p{Extended_Pictographic}") |
    tidyEmoji:::emoji_has(v)
  cat(sprintf(paste0("%s: %d rows, %d flagged, %d with a selector, %d with a run ",
                     "of two or more, %d with a tag character\n"),
              name, length(v), sum(flagged), sum(has_vs),
              sum(stringi::stri_detect_regex(v, paste0(vs_rx, "{2,}"))),
              sum(has_tag)))
  tags <- unique(unlist(stringi::stri_extract_all_regex(
    v[has_tag], paste0("\\x{1F3F4}?", tag_rx, "+"))))
  for (t in tags) cat("  tag sequence:", sprintf("%X", utf8ToInt(t)), "\n")
  # a flagged row loses exactly its hidden code points, and nothing else
  for (i in which(flagged)) {
    kept <- emoji_sanitize(d[i, ], text, policy = "keep")$text
    hid <- utf8ToInt(v[[i]])[tidyEmoji:::.emoji_hidden_scan(v[[i]])$pos[[1L]]]
    cat("  flagged row", i, ": removes", sprintf("%X", hid), "and nothing else:",
        identical(utf8ToInt(kept), setdiff_once(utf8ToInt(v[[i]]), hid)), "\n")
  }
  keep <- !flagged & (check_all | bearing)
  d <- d[keep, , drop = FALSE]
  same <- c(
    vapply(c("keep", "strip", "name", "shortcode", "placeholder"), function(p)
      identical(emoji_sanitize(d, text, policy = p),
                emoji_sanitize(d, text, policy = p, hidden = "keep")),
      logical(1)),
    to_text = identical(emoji_to_text(d, text),
                        emoji_to_text(d, text, hidden = "keep")))
  cat(sprintf("  %d rows checked, byte for byte with and without the scan: %s\n",
              nrow(d), paste(names(same), same, sep = "=", collapse = " ")))
  c(rows = length(v), flagged = sum(flagged), checked = nrow(d))
}

# drop one occurrence of each hidden code point, in order
setdiff_once <- function(x, drop) {
  for (h in drop) x <- x[-match(h, x)]
  x
}

r <- rbind(measure("tweets (0.6.0)", tw), measure("OASST2", oa),
           measure("WildChat-1M shard 0", wc, check_all = FALSE))
cat("in all:", sum(r[, "rows"]), "rows,", sum(r[, "flagged"]), "flagged,",
    sum(r[, "checked"]), "checked byte for byte\n")
