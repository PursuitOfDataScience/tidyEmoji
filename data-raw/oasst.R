# data-raw/oasst.R
# -----------------------------------------------------------------------------
# Builds the two example datasets, `oasst_messages` and `oasst_reactions`,
# from a sample of OpenAssistant OASST2 (Kopf et al. 2023, Apache-2.0). They
# replace inst/extdata/ata_tweets.csv, which had no recorded source, date or
# licence, carried full post texts that X's developer policy does not let a
# package redistribute, and printed a slur in the introduction vignette's
# first table.
#
# Two stages, so the build repeats offline:
#
#   1. TIDYEMOJI_FETCH=true: download the "ready" messages file at a pinned
#      Hugging Face revision, check it, apply the eligibility screens, and
#      write the eligible rows (and nothing else) to data-raw/oasst2-eligible.rds,
#      which is committed. Never the 54 MB original.
#   2. Always: draw the sample from that extract with a fixed seed and write
#      data/oasst_messages.rda and data/oasst_reactions.rda.
#
# Usage, from the package root with the current tidyEmoji installed:
#
#   source("data-raw/oasst.R")                        # rebuild from the extract
#   Sys.setenv(TIDYEMOJI_FETCH = "true")              # rebuild the extract first
#   source("data-raw/oasst.R")
#
# TIDYEMOJI_WRITE=false builds the objects without writing them, which is what
# the test suite does.
# -----------------------------------------------------------------------------

oasst_revision <- "179dd21fc55192153d94adb0e0ce8f69e222bf75"
oasst_file <- "2023-11-05_oasst2_ready.messages.jsonl.gz"
oasst_md5 <- "8eea9ffa10ddd49b22b01a1a62d70025"
oasst_url <- sprintf(
  "https://huggingface.co/datasets/OpenAssistant/oasst2/resolve/%s/%s",
  oasst_revision, oasst_file)
extract_path <- Sys.getenv("TIDYEMOJI_OASST_EXTRACT",
                           file.path("data-raw", "oasst2-eligible.rds"))
screen_path <- Sys.getenv("TIDYEMOJI_OASST_SCREEN",
                          file.path("data-raw", "oasst-screen.txt"))
max_len <- 600L
max_toxicity <- 0.1
seed <- 20261106L

# Stage 1: the eligible extract ---------------------------------------------------
if (identical(tolower(Sys.getenv("TIDYEMOJI_FETCH")), "true")) {
  stopifnot(requireNamespace("jsonlite", quietly = TRUE))
  raw_path <- Sys.getenv("TIDYEMOJI_OASST_RAW", tempfile(fileext = ".jsonl.gz"))
  if (!file.exists(raw_path)) {
    utils::download.file(oasst_url, raw_path, mode = "wb", quiet = TRUE)
  }
  got <- unname(tools::md5sum(raw_path))
  if (!identical(got, oasst_md5)) {
    stop("The downloaded ", oasst_file, " has md5 ", got, ", not ", oasst_md5,
         ": the pinned revision no longer serves the file this was built from.")
  }
  con <- gzfile(raw_path, open = "rb")
  lines <- readLines(con, encoding = "UTF-8", warn = FALSE)
  close(con)
  recs <- lapply(lines, jsonlite::fromJSON, simplifyVector = FALSE)
  field <- function(name, missing) {
    lapply(recs, function(r) if (is.null(r[[name]])) missing else r[[name]])
  }
  msg <- data.frame(
    message_id = unlist(field("message_id", NA_character_)),
    parent_id = unlist(field("parent_id", NA_character_)),
    created_date = unlist(field("created_date", NA_character_)),
    role = unlist(field("role", NA_character_)),
    lang = unlist(field("lang", NA_character_)),
    text = enc2utf8(unlist(field("text", NA_character_))),
    synthetic = unlist(field("synthetic", FALSE)),
    deleted = unlist(field("deleted", FALSE)),
    stringsAsFactors = FALSE)
  msg$toxicity <- vapply(recs, function(r) {
    d <- r$detoxify
    if (is.null(d) || !length(d)) NA_real_ else max(unlist(d))
  }, numeric(1))
  msg$emojis <- lapply(recs, function(r) {
    e <- r$emojis
    if (is.null(e) || !length(e)) integer(0) else
      vapply(e, as.integer, integer(1))
  })
  rm(recs, lines)

  # The screens, in order, each counted over every message and over the
  # emoji-bearing ones, which are the rows the help page quotes.
  msg$has_emoji <- tidyEmoji:::emoji_has(msg$text)
  words <- readLines(screen_path, warn = FALSE)
  words <- chartr("abcdefghijklmnopqrstuvwxyz", "nopqrstuvwxyzabcdefghijklm",
                  words[nzchar(words) & !startsWith(words, "#")])
  word_rx <- paste0("\\b(", paste(words, collapse = "|"), ")\\b")
  pii_rx <- paste(
    "[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}",   # an e-mail address
    "\\+?[0-9][0-9 ().-]{8,}[0-9]",                      # a phone-number shape
    "https?://[^\\s]+\\?[^\\s]+",                         # a URL with a query
    sep = "|")
  screens <- list(
    deleted = msg$deleted,
    synthetic = msg$synthetic,
    toxicity = !is.na(msg$toxicity) & msg$toxicity >= max_toxicity,
    word_list = stringi::stri_detect_regex(msg$text, word_rx,
                                           case_insensitive = TRUE),
    pii = stringi::stri_detect_regex(msg$text, pii_rx),
    length = stringi::stri_length(msg$text) > max_len
  )
  left <- rep(TRUE, nrow(msg))
  removed <- data.frame(screen = names(screens), all = 0L, emoji = 0L)
  for (k in seq_along(screens)) {
    hit <- left & screens[[k]]
    removed$all[k] <- sum(hit)
    removed$emoji[k] <- sum(hit & msg$has_emoji)
    left <- left & !hit
  }
  eligible <- msg[left, c("message_id", "parent_id", "created_date", "role",
                          "lang", "text", "toxicity", "has_emoji", "emojis")]
  rownames(eligible) <- NULL
  attr(eligible, "oasst") <- list(
    revision = oasst_revision, file = oasst_file, md5 = oasst_md5,
    messages = nrow(msg), emoji_messages = sum(msg$has_emoji),
    removed = removed, max_len = max_len, max_toxicity = max_toxicity,
    detected_with = as.character(utils::packageVersion("tidyEmoji")))
  saveRDS(eligible, extract_path, compress = "xz")
  message("OASST2 extract: ", nrow(eligible), " eligible of ", nrow(msg),
          " messages, ", sum(eligible$has_emoji), " carrying emoji")
}

# Stage 2: the sample -------------------------------------------------------------
stopifnot(file.exists(extract_path))
eligible <- readRDS(extract_path)
meta <- attr(eligible, "oasst")

# Messages read by hand and taken out before the data was committed, with the
# rule that removed each. The detoxify scores and the word list are
# English-centred and leave some messages unscored, so every unscored
# emoji-bearing message, and every row an example or vignette prints, was read
# in full; a message is removed if it is sexual, hateful, harassing, or holds
# personal data the automatic screen missed. Read again at the 0.7.0 release
# gate (2026-11-06): the 106 unscored emoji messages that ship, and the nine
# rows the final vignettes, README and examples print or begin to print;
# nothing further was removed.
read_out <- utils::read.csv(file.path("data-raw", "oasst-read-out.csv"),
                            stringsAsFactors = FALSE)
eligible <- eligible[!eligible$message_id %in% read_out$message_id, ,
                     drop = FALSE]

eligible$created_at <- as.POSIXct(substr(eligible$created_date, 1L, 19L),
                                  format = "%Y-%m-%dT%H:%M:%S", tz = "UTC")
stopifnot(!anyNA(eligible$created_at))
eligible$month <- format(eligible$created_at, "%Y-%m")

with_emoji <- eligible[eligible$has_emoji, , drop = FALSE]
without <- eligible[!eligible$has_emoji, , drop = FALSE]

# An equal number of emoji-free messages, allocated across month by role by
# language in proportion to the emoji-free population, drawn with a fixed
# seed. Strata are visited in code-point order of their key, never in the
# session's collation, so the draw is the same everywhere.
stratum <- paste(without$month, without$role, without$lang, sep = "|")
sizes <- table(stratum)
keys <- sort(names(sizes), method = "radix")
alloc <- round(nrow(with_emoji) * as.numeric(sizes[keys]) / nrow(without))
names(alloc) <- keys
set.seed(seed)
drawn <- unlist(lapply(keys, function(k) {
  pool <- which(stratum == k)
  pool <- pool[order(without$message_id[pool], method = "radix")]
  if (alloc[[k]] == 0L) return(integer(0))
  pool[sample.int(length(pool), alloc[[k]])]
}), use.names = FALSE)

sampled <- rbind(with_emoji, without[drawn, , drop = FALSE])
sampled <- sampled[order(sampled$created_at, sampled$message_id,
                         method = "radix"), , drop = FALSE]

oasst_messages <- tibble::tibble(
  message_id = sampled$message_id,
  parent_id = sampled$parent_id,
  created_at = sampled$created_at,
  role = sampled$role,
  lang = sampled$lang,
  text = sampled$text
)

reactions <- sampled$emojis
names(reactions) <- sampled$message_id
long <- do.call(rbind, lapply(names(reactions), function(id) {
  e <- reactions[[id]]
  if (!length(e)) return(NULL)
  nm <- names(e)
  o <- order(nm, method = "radix")
  data.frame(message_id = id, reaction = nm[o], n = as.integer(e[o]),
             stringsAsFactors = FALSE)
}))
oasst_reactions <- tibble::as_tibble(long)

message("oasst_messages:  ", nrow(oasst_messages), " rows (",
        sum(sampled$has_emoji), " carrying emoji), ",
        format(min(oasst_messages$created_at), "%Y-%m-%d"), " to ",
        format(max(oasst_messages$created_at), "%Y-%m-%d"), ", ",
        length(unique(oasst_messages$lang)), " languages")
message("oasst_reactions: ", nrow(oasst_reactions), " rows over ",
        length(unique(oasst_reactions$message_id)), " messages")

if (!identical(tolower(Sys.getenv("TIDYEMOJI_WRITE")), "false")) {
  save(oasst_messages, file = file.path("data", "oasst_messages.rda"),
       compress = "xz")
  save(oasst_reactions, file = file.path("data", "oasst_reactions.rda"),
       compress = "xz")
}
