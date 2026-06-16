test_that("emoji_frequency counts every emoji and joins metadata", {
  df <- data.frame(text = c("\U0001f600\U0001f600", "\U0001f621"))
  out <- emoji_frequency(df, text)
  expect_named(out, c("emoji", "name", "shortcode", "group", "n"))
  expect_equal(out$n[out$emoji == "\U0001f600"], 2L)
  expect_equal(out$n[out$emoji == "\U0001f621"], 1L)
  # sorted by descending count
  expect_equal(out$n, sort(out$n, decreasing = TRUE))
})

test_that("emoji_frequency returns an empty, typed tibble when there are no emoji", {
  out <- emoji_frequency(data.frame(text = c("no", "emoji")), text)
  expect_equal(nrow(out), 0)
  expect_named(out, c("emoji", "name", "shortcode", "group", "n"))
})

test_that("top_n_emojis(duplicated = TRUE) lists multiple names per glyph", {
  df <- data.frame(text = "\U0001f637")
  dup <- top_n_emojis(df, text, duplicated = TRUE)
  expect_gt(nrow(dup), 1)
  expect_true(all(dup$unicode == "\U0001f637"))
})

test_that("deprecated duplicated_unicode still works but warns", {
  df <- data.frame(text = "\U0001f637")
  expect_warning(top_n_emojis(df, text, duplicated_unicode = "yes"),
                 class = "lifecycle_warning_deprecated")
})

test_that("emoji_categorize keeps emoji rows and labels categories", {
  df <- data.frame(text = c("smile \U0001f600",
                            "flag \U0001f3c1\U0001f600",
                            "nothing"))
  out <- emoji_categorize(df, text)
  expect_equal(nrow(out), 2)                      # the no-emoji row is dropped
  expect_true(".emoji_category" %in% names(out))
  expect_match(out$.emoji_category[2], "Flags")   # multi-category row
})
