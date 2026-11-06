# Snapshots of the shape of the verbs whose output 0.6.0 changed or added.
#
# A unit test pins the values it names; a snapshot pins everything else that
# is visible, which is where silent drift lives: a column that moves, a new
# column nobody asked for, a sort order that changes under a new `measure`.
# Glyphs are recorded as their code-point keys and doubles to six significant
# digits, so the snapshot is plain ASCII and reads the same on every platform
# and in every locale. One test holds them all, so CRAN, where snapshots do
# not run, counts one skip rather than a dozen.

snap_corpus <- function() {
  utils::read.csv(system.file("extdata", "ata_tweets.csv",
                              package = "tidyEmoji"),
                  stringsAsFactors = FALSE, encoding = "UTF-8")
}

snap_shape <- function(df, n = 8L) {
  key <- asNamespace("tidyEmoji")$emoji_key
  top <- utils::head(as.data.frame(df), n)
  cols <- lapply(top, function(col) {
    if (inherits(col, "Date")) return(as.character(col))
    if (is.character(col)) {
      ascii <- is.na(col) | grepl("^[ -~]*$", col, useBytes = TRUE)
      out <- col
      out[!ascii] <- paste0("<", key(col[!ascii]), ">")
      return(out)
    }
    if (is.double(col)) return(signif(col, 6))
    col
  })
  list(names = names(df), nrow = nrow(df), head = cols)
}

test_that("the 0.6.0 output shapes hold", {
  # testthat compares no snapshot on CRAN, so stand down before building
  # anything: left to the first expect_snapshot_value(), the skip came after
  # the corpus was read and the snapshot machinery loaded, which took more
  # than a second on a GitHub runner for a test that then did nothing
  skip_on_cran()
  corpus <- snap_corpus()
  g <- function(...) intToUtf8(c(...))
  orphans <- data.frame(text = c(paste0(g(0x1F600), g(0x1F3FB)),
                                 g(0x1F1FD, 0x1F1FD), "plain",
                                 paste("I", g(0x2764), "R")))
  dated <- data.frame(
    when = as.Date(c("2024-01-05", "2024-01-20", "2024-02-03")),
    text = c(paste(g(0x1F600), g(0x1F600), g(0x1F602)),
             paste(g(0x2764, 0xFE0F), g(0x1F600)), g(0x1F602)))

  expect_snapshot_value(snap_shape(emoji_summary(corpus, full_text)),
                        style = "json2")
  expect_snapshot_value(snap_shape(emoji_summary(orphans, text,
                                                 presentation = "any")),
                        style = "json2")
  expect_snapshot_value(
    snap_shape(emoji_ratio(corpus, full_text)[, c(".emoji_n",
      ".emoji_codepoints", ".emoji_n_char", ".emoji_ratio", ".emoji_only")]),
    style = "json2")
  expect_snapshot_value(
    snap_shape(emoji_density(corpus, full_text)[, c(".emoji_n",
      ".emoji_n_char", ".emoji_n_token", ".emoji_per_char",
      ".emoji_per_token")]),
    style = "json2")
  expect_snapshot_value(snap_shape(emoji_trend(dated, text, when, top_n = 1)),
                        style = "json2")
  expect_snapshot_value(snap_shape(emoji_frequency(corpus, full_text)),
                        style = "json2")
  expect_snapshot_value(snap_shape(emoji_collocations(corpus, full_text)),
                        style = "json2")
  expect_snapshot_value(
    snap_shape(emoji_collocations(corpus, full_text, measure = "logdice")),
    style = "json2")
  expect_snapshot_value(snap_shape(emoji_pairs(corpus, full_text)),
                        style = "json2")
  expect_snapshot_value(
    snap_shape(emoji_pairs(corpus, full_text, measure = "dice")),
    style = "json2")
  expect_snapshot_value(snap_shape(emoji_coverage(corpus, full_text)),
                        style = "json2")
  expect_snapshot_value(
    snap_shape(emoji_ambiguity(measure = "polarisation")), style = "json2")
  expect_snapshot_value(snap_shape(emoji_properties(), n = 12L),
                        style = "json2")
  expect_snapshot_value(
    snap_shape(emoji_country(data.frame(text = c(
      paste(g(0x1F1EF, 0x1F1F5), g(0x1F1FD, 0x1F1FD)), "none")), text)),
    style = "json2")
  expect_snapshot_value(snap_shape(emoji_provenance()[, c("unicode_emoji",
    "unicode_emoji_date", "n_emoji")]), style = "json2")
})
