test_that("emoji_extract_nest adds a list-column of glyphs", {
  df <- data.frame(text = c("hi \U0001f600\U0001f603", "none"))
  out <- emoji_extract_nest(df, text)
  expect_true(is.list(out$.emoji_unicode))
  expect_identical(out$.emoji_unicode[[1]], c("\U0001f600", "\U0001f603"))
  expect_identical(out$.emoji_unicode[[2]], character(0))
})

test_that("emoji_extract_unnest counts emoji per row in long form", {
  df <- data.frame(text = c("hi \U0001f600\U0001f600", "none", "\U0001f44b"))
  out <- emoji_extract_unnest(df, text)
  expect_named(out, c("row_number", ".emoji_unicode", ".emoji_count"))
  expect_equal(out$.emoji_count[out$row_number == 1], 2L)
  expect_false(2 %in% out$row_number)            # the no-emoji row is dropped
})

test_that("emoji_tokens yields one row per occurrence with metadata", {
  df <- data.frame(id = 1:2, text = c("great \U0001f600", "bad \U0001f621"))
  out <- emoji_tokens(df, text)
  expect_equal(nrow(out), 2)
  expect_true(all(c(".emoji", ".emoji_name", ".emoji_category",
                    ".emoji_sentiment") %in% names(out)))
  expect_true("id" %in% names(out))              # original columns preserved
})

test_that("detection is grapheme-aware: ZWJ and skin-tone stay intact", {
  # Regression test for the pre-0.2.0 bug where a family emoji split into four
  # people and a skin-tone thumbs-up split into thumb + modifier.
  family <- "\U0001F468‍\U0001F469‍\U0001F467‍\U0001F466"
  thumb  <- "\U0001F44D\U0001F3FD"
  df <- data.frame(text = c(paste("a family", family), paste("a", thumb)))

  out <- emoji_extract_unnest(df, text)
  expect_equal(nrow(out), 2)
  expect_equal(out$.emoji_count, c(1L, 1L))
  expect_identical(out$.emoji_unicode, c(family, thumb))
})
