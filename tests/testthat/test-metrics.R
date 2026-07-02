# Tests for the structural metrics: emoji_position / emoji_density /
# emoji_ratio.

test_that("emoji_position reports first/last/relative positions", {
  df <- data.frame(text = c("\U0001f600 leading",     # emoji at char 1
                            "trailing \U0001f600",    # emoji at char 10
                            "none"))
  out <- emoji_position(df, text)
  expect_equal(out$.emoji_n, c(1L, 1L, 0L))
  expect_equal(out$.emoji_first, c(1L, 10L, NA))
  expect_equal(out$.emoji_last, c(1L, 10L, NA))
  expect_equal(out$.emoji_rel_position[1], 0)
  expect_equal(out$.emoji_rel_position[2], 1)
  expect_true(is.na(out$.emoji_rel_position[3]))
})

test_that("emoji_position averages over occurrences and handles 1-char text", {
  out <- emoji_position(data.frame(text = "\U0001f600"), text)
  expect_equal(out$.emoji_rel_position, 0)
  mid <- emoji_position(data.frame(text = "\U0001f600a\U0001f600"), text)
  expect_equal(mid$.emoji_first, 1L)
  expect_equal(mid$.emoji_last, 3L)
  expect_equal(mid$.emoji_rel_position, 0.5)   # mean of 0 and 1
})

test_that("emoji_density computes per-char and per-token densities", {
  df <- data.frame(text = c("hi \U0001f600",              # 4 chars, 2 tokens
                            "\U0001f600\U0001f600",       # 2 chars, 1 token
                            "plain text",
                            NA))
  out <- emoji_density(df, text)
  expect_equal(out$.emoji_n, c(1L, 2L, 0L, 0L))
  expect_equal(out$.emoji_per_char[1], 1 / 4)
  expect_equal(out$.emoji_per_char[2], 1)
  expect_equal(out$.emoji_per_char[3], 0)
  expect_true(is.na(out$.emoji_per_char[4]))
  expect_equal(out$.emoji_per_token[1], 1 / 2)
  expect_equal(out$.emoji_per_token[2], 2)
  expect_equal(out$.emoji_per_token[3], 0)
  expect_true(is.na(out$.emoji_per_token[4]))
})

test_that("emoji_ratio reports the emoji share and emoji-only rows", {
  df <- data.frame(text = c("\U0001f600\U0001f389",   # all emoji
                            "\U0001f600 \U0001f389",  # emoji + whitespace only
                            "half \U0001f600",
                            "no emoji",
                            NA))
  out <- emoji_ratio(df, text)
  expect_equal(out$.emoji_ratio[1], 1)
  expect_equal(out$.emoji_only[1:4], c(TRUE, TRUE, FALSE, FALSE))
  expect_true(out$.emoji_ratio[3] > 0 && out$.emoji_ratio[3] < 1)
  expect_equal(out$.emoji_ratio[4], 0)
  expect_true(is.na(out$.emoji_ratio[5]))
  expect_true(is.na(out$.emoji_only[5]))
})

test_that("emoji_ratio counts all characters of multi-codepoint emoji", {
  family <- "\U0001F468‍\U0001F469‍\U0001F467‍\U0001F466"
  out <- emoji_ratio(data.frame(text = family), text)
  expect_equal(out$.emoji_ratio, 1)
  expect_true(out$.emoji_only)
})
