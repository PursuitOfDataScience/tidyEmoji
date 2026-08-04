# Tests for emoji_context() and emoji_collocations().

cry  <- "\U0001f622"
grin <- "\U0001f600"

test_that("emoji_context returns one row per occurrence with word windows", {
  df <- data.frame(text = c("the coffee was cold \U0001f622 again",
                            "no emoji here"))
  out <- emoji_context(df, text, window = 2)
  expect_named(out, c(".row_number", ".position", ".emoji",
                      ".emoji_context_left", ".emoji_context_right",
                      ".emoji_context"))
  expect_equal(nrow(out), 1L)
  expect_equal(out$.row_number, 1L)
  expect_equal(out$.position, 21L)
  expect_equal(out$.emoji, cry)
  expect_equal(out$.emoji_context_left, "was cold")
  expect_equal(out$.emoji_context_right, "again")
  expect_equal(out$.emoji_context, "was cold again")
})

test_that("emoji_context counts characters when asked", {
  df <- data.frame(text = "the coffee was cold \U0001f622 again")
  out <- emoji_context(df, text, window = 6, unit = "char")
  expect_equal(out$.emoji_context_left, "s cold")
  expect_equal(out$.emoji_context_right, "again")
})

test_that("emoji_context keeps neighbouring emoji out of the window", {
  # the grinning face must not appear in the crying face's context
  df <- data.frame(text = paste0("good ", grin, " bad ", cry, " end"))
  out <- emoji_context(df, text, window = 10)
  expect_equal(nrow(out), 2L)
  expect_false(any(grepl(grin, out$.emoji_context, fixed = TRUE)))
  expect_false(any(grepl(cry, out$.emoji_context, fixed = TRUE)))
  expect_equal(out$.emoji_context[1], "good bad end")
})

test_that("emoji_context positions agree with emoji_position", {
  df <- data.frame(text = c(paste0("ab ", grin, " cd ", cry), "none", NA))
  ctx <- emoji_context(df, text)
  pos <- emoji_position(df, text)
  expect_equal(min(ctx$.position[ctx$.row_number == 1]), pos$.emoji_first[1])
  expect_equal(max(ctx$.position[ctx$.row_number == 1]), pos$.emoji_last[1])
  expect_equal(nrow(ctx), sum(pos$.emoji_n))
})

test_that("emoji_context handles empty, NA and window = 0 input", {
  expect_equal(nrow(emoji_context(data.frame(text = character(0)), text)), 0L)
  expect_equal(nrow(emoji_context(data.frame(text = c(NA, "plain")), text)), 0L)
  out <- emoji_context(data.frame(text = paste0("hi ", grin)), text,
                       window = 0)
  expect_equal(out$.emoji_context_left, "")
  expect_equal(out$.emoji_context, "")
  expect_error(emoji_context(data.frame(text = "a"), text, window = -1),
               ">= 0")
})

test_that("emoji_context(keep_text = TRUE) returns the source text", {
  df <- data.frame(id = 1:2, body = c(paste0("hi ", grin), "plain"))
  out <- emoji_context(df, body, keep_text = TRUE)
  expect_equal(names(out)[1:2], c(".row_number", "body"))
  expect_equal(out$body, paste0("hi ", grin))
})

test_that("emoji_collocations scores emoji-word association with pmi", {
  df <- data.frame(text = c(paste0("cold coffee ", cry),
                            paste0("coffee again ", cry),
                            paste0("warm tea ", grin)))
  out <- emoji_collocations(df, text, min_n = 1)
  expect_named(out, c("emoji", "word", "n", "pmi"))
  expect_equal(nrow(out), 5L)
  n_coffee <- out$n[out$emoji == cry & out$word == "coffee"]
  expect_equal(n_coffee, 2L)
  # 6 co-occurrences in total; "warm" only ever occurs with the grinning face
  expect_equal(out$pmi[out$emoji == grin & out$word == "warm"], log(3),
               tolerance = 1e-8)
  expect_equal(out$pmi[out$emoji == cry & out$word == "coffee"], log(1.5),
               tolerance = 1e-8)
  # sorted by descending pmi
  expect_false(is.unsorted(rev(out$pmi)))
})

test_that("emoji_collocations filters by min_n and can sort by count", {
  df <- data.frame(text = c(paste0("cold coffee ", cry),
                            paste0("coffee again ", cry)))
  expect_equal(nrow(emoji_collocations(df, text, min_n = 2)), 1L)
  by_n <- emoji_collocations(df, text, min_n = 1, measure = "count")
  expect_equal(by_n$n[1], 2L)
  expect_error(emoji_collocations(df, text, min_n = -1), "non-negative")
})

test_that("emoji_collocations lower-cases and trims punctuation", {
  df <- data.frame(text = paste0("Coffee, please ", cry))
  out <- emoji_collocations(df, text, min_n = 1)
  expect_true("coffee" %in% out$word)
  expect_false("Coffee," %in% out$word)
})

test_that("emoji_collocations returns a typed empty tibble when it can", {
  out <- emoji_collocations(data.frame(text = c("plain", "text")), text)
  expect_equal(nrow(out), 0L)
  expect_named(out, c("emoji", "word", "n", "pmi"))
  bare <- emoji_collocations(data.frame(text = grin), text, min_n = 1)
  expect_equal(nrow(bare), 0L)
})
