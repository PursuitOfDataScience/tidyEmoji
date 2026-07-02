# Tests for the relational verbs: emoji_pairs / emoji_cooccurrence /
# emoji_ngrams.

laugh <- "\U0001f602"   # face with tears of joy
heart <- "\U0001f60d"   # heart-eyes
party <- "\U0001f389"   # party popper

test_that("emoji_pairs counts document co-occurrence of distinct emoji", {
  df <- data.frame(text = c(paste0("fun ", laugh, heart),
                            paste0(laugh, heart, party),
                            paste0("just ", laugh)))
  out <- emoji_pairs(df, text)
  expect_named(out, c("item1", "item2", "n"))
  # laugh+heart co-occur in two rows; the others once
  expect_equal(out$n[out$item1 == sort(c(laugh, heart))[1] &
                     out$item2 == sort(c(laugh, heart))[2]], 2L)
  expect_equal(nrow(out), 3L)   # {laugh,heart}, {laugh,party}, {heart,party}
  # repeats within a row do not create self-pairs
  self <- emoji_pairs(data.frame(text = paste0(laugh, laugh)), text)
  expect_equal(nrow(self), 0L)
})

test_that("emoji_pairs is deterministic and sorted by n", {
  df <- data.frame(text = c(paste0(laugh, heart), paste0(heart, laugh),
                            paste0(laugh, party)))
  out <- emoji_pairs(df, text)
  expect_equal(out$n, sort(out$n, decreasing = TRUE))
  # unordered: the pair is recorded once whatever the reading order
  expect_equal(max(out$n), 2L)
})

test_that("emoji_pairs(directed = TRUE) respects first-appearance order", {
  df <- data.frame(text = c(paste0(laugh, heart), paste0(laugh, heart),
                            paste0(heart, laugh)))
  out <- emoji_pairs(df, text, directed = TRUE)
  expect_equal(out$n[out$item1 == laugh & out$item2 == heart], 2L)
  expect_equal(out$n[out$item1 == heart & out$item2 == laugh], 1L)
})

test_that("emoji_pairs supports doc_id grouping", {
  df <- data.frame(id = c(1, 1, 2),
                   text = c(laugh, heart, party))
  out <- emoji_pairs(df, text, doc_id = id)
  # laugh and heart share doc 1; party is alone in doc 2
  expect_equal(nrow(out), 1L)
  expect_equal(out$n, 1L)
  expect_setequal(c(out$item1, out$item2), c(laugh, heart))
})

test_that("emoji_pairs canonicalises qualified/unqualified twins to one node", {
  # The extractor returns the bare victory hand (U+270C) unqualified but the
  # qualified form (U+270C U+FE0F) as-is; both must become one node.
  qualified   <- "✌️"
  unqualified <- "✌"
  df <- data.frame(text = c(paste0(qualified, laugh),
                            paste0(unqualified, laugh)))
  out <- emoji_pairs(df, text)
  expect_equal(nrow(out), 1L)   # one victory-hand node, one pair
  expect_equal(out$n, 2L)
})

test_that("emoji_pairs returns an empty typed tibble when nothing co-occurs", {
  out <- emoji_pairs(data.frame(text = c("plain", laugh)), text)
  expect_equal(nrow(out), 0L)
  expect_named(out, c("item1", "item2", "n"))
})

test_that("emoji_pairs warns on grouped input", {
  df <- data.frame(g = c("a", "b"), text = c(paste0(laugh, heart), party))
  expect_warning(emoji_pairs(dplyr::group_by(df, g), text),
                 class = "lifecycle_warning_deprecated")
})

test_that("emoji_cooccurrence(diagonal = TRUE) adds document frequencies", {
  df <- data.frame(text = c(paste0(laugh, heart), laugh))
  out <- emoji_cooccurrence(df, text, diagonal = TRUE)
  expect_equal(out$n[out$item1 == laugh & out$item2 == laugh], 2L)
  expect_equal(out$n[out$item1 == heart & out$item2 == heart], 1L)
  expect_equal(out$n[out$item1 != out$item2], 1L)
  # and matches emoji_pairs when diagonal = FALSE
  expect_identical(emoji_cooccurrence(df, text), emoji_pairs(df, text))
})

test_that("emoji_ngrams returns consecutive n-grams in reading order", {
  df <- data.frame(text = c(paste0(laugh, heart, party), laugh))
  out <- emoji_ngrams(df, text)
  expect_named(out, c(".row_number", ".position", ".emoji_ngram"))
  expect_equal(out$.emoji_ngram,
               c(paste(laugh, heart), paste(heart, party)))
  expect_equal(out$.position, c(1L, 2L))
  expect_equal(unique(out$.row_number), 1L)   # the 1-emoji row contributes none
  tri <- emoji_ngrams(df, text, n = 3)
  expect_equal(tri$.emoji_ngram, paste(laugh, heart, party))
})

test_that("emoji_ngrams keeps repeats and validates n", {
  df <- data.frame(text = paste0(laugh, laugh))
  out <- emoji_ngrams(df, text)
  expect_equal(out$.emoji_ngram, paste(laugh, laugh))
  uni <- emoji_ngrams(df, text, n = 1)
  expect_equal(nrow(uni), 2L)
  expect_error(emoji_ngrams(df, text, n = 0), ">= 1")
  empty <- emoji_ngrams(data.frame(text = "plain"), text)
  expect_equal(nrow(empty), 0L)
  expect_named(empty, c(".row_number", ".position", ".emoji_ngram"))
})
