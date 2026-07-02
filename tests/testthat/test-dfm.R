# Tests for emoji_dfm().

laugh <- "\U0001f602"
rage  <- "\U0001f621"

test_that("emoji_dfm builds a count matrix with all documents kept", {
  df <- data.frame(text = c(paste0(laugh, laugh, " fun"), rage, "no emoji"))
  out <- emoji_dfm(df, text)
  expect_equal(names(out)[1], ".row_number")
  expect_equal(nrow(out), 3L)                        # zero rows kept
  expect_equal(out[[laugh]], c(2L, 0L, 0L))
  expect_equal(out[[rage]],  c(0L, 1L, 0L))
  # columns ordered by total count (laugh 2 > rage 1)
  expect_equal(names(out)[-1], c(laugh, rage))
})

test_that("emoji_dfm weighting = binary and tfidf", {
  df <- data.frame(text = c(paste0(laugh, laugh), paste0(laugh, rage)))
  bin <- emoji_dfm(df, text, weighting = "binary")
  expect_equal(bin[[laugh]], c(1, 1))
  expect_equal(bin[[rage]], c(0, 1))
  tf <- emoji_dfm(df, text, weighting = "tfidf")
  # laugh appears in every doc -> idf 0
  expect_equal(tf[[laugh]], c(0, 0))
  expect_equal(tf[[rage]], c(0, 1 * log(2 / 1)))
})

test_that("emoji_dfm aggregates by doc_id and keeps the column name", {
  df <- data.frame(author = c("a", "a", "b"),
                   text = c(laugh, laugh, rage))
  out <- emoji_dfm(df, text, doc_id = author)
  expect_equal(names(out)[1], "author")
  expect_equal(out$author, c("a", "b"))
  expect_equal(out[[laugh]], c(2L, 0L))
  expect_equal(out[[rage]], c(0L, 1L))
})

test_that("emoji_dfm canonicalises qualified/unqualified twins to one column", {
  # bare (U+270C) and qualified (U+270C U+FE0F) victory hands extract as
  # different glyphs; the dfm must merge them into one feature column
  df <- data.frame(text = c("✌️", "✌"))
  out <- emoji_dfm(df, text)
  expect_equal(ncol(out), 2L)   # .row_number + one victory-hand column
  expect_equal(out[[2L]], c(1L, 1L))
})

test_that("emoji_dfm on an emoji-free corpus returns just the doc column", {
  out <- emoji_dfm(data.frame(text = c("a", "b")), text)
  expect_named(out, ".row_number")
  expect_equal(out$.row_number, 1:2)
})

test_that("emoji_dfm warns on grouped input", {
  df <- data.frame(g = c("a", "b"), text = c(laugh, rage))
  expect_warning(emoji_dfm(dplyr::group_by(df, g), text),
                 class = "lifecycle_warning_deprecated")
})
