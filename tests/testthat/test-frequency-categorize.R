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

test_that("emoji_frequency breaks ties deterministically (by glyph)", {
  a <- emoji_frequency(data.frame(text = c("\U0001f621", "\U0001f600")), text)
  b <- emoji_frequency(data.frame(text = c("\U0001f600", "\U0001f621")), text)
  expect_identical(a, b)
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

test_that("top_n_emojis n counts distinct emoji, not rows", {
  df <- data.frame(text = c("\U0001f600", "\U0001f600", "\U0001f621"))
  out <- top_n_emojis(df, text, n = 1)
  expect_equal(nrow(out), 1)
  expect_equal(out$n, 2L)
})

test_that("duplicated = TRUE settles the tie the @return rule leaves open", {
  # Several rows then share both `n` and `unicode`, so "ties broken by the
  # glyph" does not determine the order. ?top_n_emojis now says what does:
  # the crosswalk's order for the glyph's key, first row matching the name
  # `duplicated = FALSE` gives, and aliases collected across every spelling
  # of the emoji rather than only the one in the text.
  skip_if_catalogue_moved()
  ref <- asNamespace("tidyEmoji")$emoji_reference()
  ekey <- asNamespace("tidyEmoji")$emoji_key
  set.seed(7)
  glyphs <- sample(ref$emoji[!is.na(ref$shortcode)], 200L)
  d <- data.frame(text = glyphs, stringsAsFactors = FALSE)
  many <- top_n_emojis(d, text, n = 200L, duplicated = TRUE)
  one <- top_n_emojis(d, text, n = 200L)
  cw <- emoji_unicode_crosswalk
  for (u in unique(many$unicode)) {
    got <- many$emoji_name[many$unicode == u]
    expect_identical(got, unique(cw$emoji_name[cw$key == ekey(u)]), info = u)
    expect_identical(got[1L], one$emoji_name[one$unicode == u], info = u)
  }
  # and the order does not depend on the order of the rows it came from
  expect_identical(
    many,
    top_n_emojis(d[rev(seq_len(nrow(d))), , drop = FALSE], text, n = 200L,
                 duplicated = TRUE))

  # the worked example the help page gives: an unqualified spelling collects
  # the fully-qualified one's aliases too, because the join is on the key
  bounce <- "\u26F9\u200D\u2640"
  out <- top_n_emojis(data.frame(text = bounce, stringsAsFactors = FALSE),
                      text, duplicated = TRUE)
  expect_gt(nrow(out), 1L)
  expect_true("woman_bouncing_ball" %in% out$emoji_name)
  expect_match(rd_flat("top_n_emojis"),
               "aliases of \\emph{every} spelling of itself", fixed = TRUE)
})

test_that("top_n_emojis(duplicated = TRUE) uses left_join so alias-less emoji survive", {
  # Use an emoji that is known to have no alias
  df <- data.frame(text = "\U0001f600")
  dup <- top_n_emojis(df, text, n = 5, duplicated = TRUE)
  expect_true(nrow(dup) >= 1)
  expect_true("unicode" %in% names(dup))
})
