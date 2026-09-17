# Timing baseline for the verbs that do the most work per row.
#
# Why this exists: the roadmap carried "no committed benchmark script" as a debt
# for three releases, and a number measured once in a session is not a baseline.
# Run this before and after any change to the extraction or context engines and
# compare. It is deliberately plain: no dependency beyond the package itself, so
# it runs anywhere the package installs.
#
#   Rscript data-raw/benchmark.R              # 1k, 10k, 50k rows
#   Rscript data-raw/benchmark.R 1000 5000    # your own sizes
#
# Interpretation: the shape matters more than the seconds, which are host
# specific. There are two axes and a verb has to stay linear in both. Cost
# should grow no faster than the row count, and -- at a fixed total number of
# emoji -- it should not move at all when those emoji are packed into fewer,
# denser rows. A verb that fails the first is quadratic in the corpus; one
# that fails the second is quadratic within a row, which the row axis cannot
# see. Either is the finding, not the absolute time.

library(tidyEmoji)

sizes <- as.integer(commandArgs(trailingOnly = TRUE))
if (!length(sizes) || anyNA(sizes)) sizes <- c(1000L, 10000L, 50000L)

# A corpus with the properties that drive cost: a realistic share of rows with
# no emoji at all, multi-codepoint sequences, and enough distinct glyphs that
# the joins are not answering from a two-row lookup.
make_corpus <- function(n, seed = 20260917) {
  set.seed(seed)
  glyphs <- c("\U0001f600", "\U0001f602", "\U0001f60d", "\U0001f621",
              "\U0001f389", "\U0001f44d", "\U0001f44d\U0001f3fd",
              "\U0001f1fa\U0001f1f8", "\u2764\ufe0f",
              paste0("\U0001f468\u200d\U0001f469\u200d",
                     "\U0001f467\u200d\U0001f466"))
  words <- c("great", "awful", "shipped", "late", "again", "thanks", "broken",
             "love", "the", "best", "worst", "today", "never", "works")
  vapply(seq_len(n), function(i) {
    body <- paste(sample(words, sample(4:14, 1), replace = TRUE), collapse = " ")
    k <- sample(0:3, 1, prob = c(0.35, 0.4, 0.15, 0.1))
    if (!k) return(body)
    paste(body, paste(sample(glyphs, k, replace = TRUE), collapse = " "))
  }, character(1))
}

# One row per (verb, size). Timed with elapsed seconds from system.time(), which
# is what a user waits; user+sys would hide any parallel or I/O cost.
verbs <- list(
  emoji_summary      = function(d) emoji_summary(d, text),
  emoji_frequency    = function(d) emoji_frequency(d, text),
  emoji_position     = function(d) emoji_position(d, text),
  emoji_sentiment    = function(d) emoji_sentiment(d, text),
  emoji_dfm          = function(d) emoji_dfm(d, text),
  emoji_context      = function(d) emoji_context(d, text),
  emoji_collocations = function(d) emoji_collocations(d, text)
)

cat("tidyEmoji", as.character(utils::packageVersion("tidyEmoji")),
    "|", R.version.string, "\n")
cat("emoji", as.character(utils::packageVersion("emoji")),
    "| sizes:", paste(sizes, collapse = ", "), "\n\n")

# Warm up first. The reference table and the lexicons are lazy-loaded on first
# use, so without this the smallest size pays for loading them and the scaling
# ratios come out below 1: an artefact that reads like a speed-up.
invisible(lapply(verbs, function(f) f(data.frame(text = make_corpus(50L)))))

results <- list()
for (n in sizes) {
  d <- data.frame(text = make_corpus(n), stringsAsFactors = FALSE)
  for (nm in names(verbs)) {
    el <- system.time(verbs[[nm]](d))[["elapsed"]]
    results[[length(results) + 1L]] <-
      data.frame(verb = nm, n = n, elapsed = el, stringsAsFactors = FALSE)
  }
}
res <- do.call(rbind, results)

# Markdown, so the table can go straight into a release note or the roadmap.
cat("| Verb | ", paste(sprintf("%s rows", format(sizes, big.mark = ",", trim = TRUE)),
                        collapse = " | "), " | per 1k rows at largest |\n", sep = "")
cat("|---|", paste(rep("---", length(sizes) + 1L), collapse = "|"), "|\n", sep = "")
for (nm in names(verbs)) {
  row <- res[res$verb == nm, ]
  row <- row[match(sizes, row$n), ]
  biggest <- row$elapsed[length(sizes)] / (sizes[length(sizes)] / 1000)
  cat(sprintf("| `%s()` | %s | %.3f s |\n", nm,
              paste(sprintf("%.2f", row$elapsed), collapse = " | "), biggest))
}

# The scaling check, which is the actual regression signal.
cat("\nScaling, largest over smallest (rows grew",
    sprintf("%.0fx", max(sizes) / min(sizes)), "):\n")
for (nm in names(verbs)) {
  row <- res[res$verb == nm, ]
  small <- row$elapsed[row$n == min(sizes)]
  big   <- row$elapsed[row$n == max(sizes)]
  ratio <- if (small > 0) big / small else NA_real_
  cat(sprintf("  %-20s %.1fx%s\n", nm, ratio,
              if (!is.na(ratio) && ratio > max(sizes) / min(sizes) * 1.5)
                "   <- superlinear, investigate" else ""))
}

# The second axis: emoji *per row*, at a fixed row count.
#
# Everything above scales the corpus in rows, and make_corpus() caps a row at
# three emoji, so a verb that is quadratic in the emoji within one row scales
# perfectly linearly here and looks healthy. emoji_context() was exactly that
# for three releases -- 3200 emoji in one row cost 7.1s against 0.28s for the
# same 3200 spread over 320 rows -- and this script, which exists to catch it,
# could not see it. A chat or reaction corpus is full of emoji-dense rows, so
# this axis is not a synthetic worry.
#
# Held at a constant *total* emoji count, so a verb linear in the emoji it
# sees should take the same time in every column, and the ratio below is the
# regression signal rather than the seconds.
cat("\nEmoji per row, at a constant", format(3200L, big.mark = ","),
    "emoji in total:\n")
dense_k <- c(1L, 10L, 100L, 1600L)
dense <- lapply(dense_k, function(k) {
  data.frame(text = rep(strrep("\U0001f600", k), 3200L %/% k),
             stringsAsFactors = FALSE)
})
cat("| Verb | ", paste(sprintf("%d/row", dense_k), collapse = " | "),
    " | worst/best |\n", sep = "")
cat("|---|", paste(rep("---", length(dense_k) + 1L), collapse = "|"), "|\n",
    sep = "")
for (nm in names(verbs)) {
  el <- vapply(dense, function(d) system.time(verbs[[nm]](d))[["elapsed"]],
               numeric(1))
  ratio <- if (min(el) > 0) max(el) / min(el) else NA_real_
  cat(sprintf("| `%s()` | %s | %s |\n", nm,
              paste(sprintf("%.2f", el), collapse = " | "),
              if (is.na(ratio)) "-" else
                sprintf("%.1fx%s", ratio,
                        if (ratio > 4) "  <- quadratic in emoji per row" else "")))
}

invisible(res)
