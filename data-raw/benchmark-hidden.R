# data-raw/benchmark-hidden.R
# The cost of the hidden-payload scan (0.7.0, D8), measured the only way a
# speed claim is worth making here: paired and interleaved, warm-up discarded,
# a percentile bootstrap CI on the median ratio and a Wilcoxon signed-rank
# test, with the number of pairs and the worst ratio reported. Run on
# 2026-11-06 on one amd core of midway3: "strip" +2.2% (median ratio 1.022,
# 95% CI [1.017, 1.025], 40 pairs, worst 0.984), "name" +2.1% (1.021,
# [1.015, 1.030], 30 pairs, worst 0.984), inside the 5% the plan allows, and
# "keep" 30 ms on 50,000 rows, the scan alone, since without it "keep" does
# nothing.

# Paired, interleaved benchmark: emoji_sanitize() with hidden = "remove" (the
# 0.7.0 default) against hidden = "keep" (0.6.0's path, no scan), 50,000 rows.
# Run from the package root: Rscript data-raw/benchmark-hidden.R [library]
lib <- commandArgs(TRUE)[1]; if (is.na(lib)) lib <- NULL
library(tidyEmoji, lib.loc = lib)
tw <- utils::read.csv(system.file("extdata", "ata_tweets.csv", package = "tidyEmoji"),
                      encoding = "UTF-8", stringsAsFactors = FALSE)$full_text
set.seed(20261106)
d <- data.frame(text = sample(tw, 50000L, replace = TRUE), stringsAsFactors = FALSE)
run <- function(policy, n_pairs, warm = 3L) {
  a <- function() emoji_sanitize(d, text, policy = policy)
  b <- function() emoji_sanitize(d, text, policy = policy, hidden = "keep")
  stopifnot(identical(a(), b()))
  for (i in seq_len(warm)) { a(); b() }           # discarded
  ta <- tb <- numeric(n_pairs)
  for (i in seq_len(n_pairs)) {
    if (i %% 2L) {
      ta[i] <- system.time(a())[["elapsed"]]; tb[i] <- system.time(b())[["elapsed"]]
    } else {
      tb[i] <- system.time(b())[["elapsed"]]; ta[i] <- system.time(a())[["elapsed"]]
    }
  }
  r <- ta / tb
  set.seed(1)
  boot <- replicate(20000L, stats::median(sample(r, replace = TRUE)))
  w <- stats::wilcox.test(ta, tb, paired = TRUE, exact = FALSE)
  cat(sprintf(paste0("policy=%s pairs=%d median(remove)=%.4fs median(keep)=%.4fs ",
                     "median ratio=%.4f 90%% CI [%.4f, %.4f] 95%% CI [%.4f, %.4f] ",
                     "min ratio=%.4f max ratio=%.4f Wilcoxon p=%.3g median diff=%.4fs\n"),
              policy, n_pairs, stats::median(ta), stats::median(tb), stats::median(r),
              stats::quantile(boot, .05), stats::quantile(boot, .95),
              stats::quantile(boot, .025), stats::quantile(boot, .975),
              min(r), max(r), w$p.value, stats::median(ta - tb)))
}
run("strip", 40L)
run("name", 30L)
run("keep", 60L)
