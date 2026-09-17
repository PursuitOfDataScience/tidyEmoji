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

test_that("a char window counts code points, so it can split a grapheme", {
  # ?emoji_context's `unit` now says so, and this is the case it names: an
  # `e` carrying a combining acute is two code points, so window = 1 hands
  # back the accent on its own. emoji_density() and emoji_ratio() document
  # the same code-point basis; this verb is the one where it shows up in the
  # output rather than only in a denominator.
  glyph <- "\U0001F600"
  txt <- paste0("caf", "e\u0301", " ", glyph)
  expect_identical(utf8ToInt(substr(txt, 4, 5)), c(0x65L, 0x301L))
  left <- function(w) {
    emoji_context(data.frame(text = txt, stringsAsFactors = FALSE), text,
                  window = w, unit = "char")$.emoji_context_left
  }
  expect_identical(utf8ToInt(left(1L)), 0x301L)
  expect_identical(utf8ToInt(left(2L)), c(0x65L, 0x301L))
  expect_identical(left(5L), "caf\u0065\u0301")
  # a word window never splits one
  wordy <- emoji_context(data.frame(text = txt, stringsAsFactors = FALSE),
                         text, window = 1L, unit = "word")$.emoji_context_left
  expect_identical(wordy, "caf\u0065\u0301")
  # and an emoji is masked whole, so it is never the thing that gets split
  fam <- "\U0001F468\u200D\U0001F469\u200D\U0001F467"
  both <- emoji_context(
    data.frame(text = paste0(fam, glyph), stringsAsFactors = FALSE), text,
    window = 3L, unit = "char")
  expect_true(all(!nzchar(both$.emoji_context_left)))
  rd <- rd_flat("emoji_context")
  expect_match(rd, "bare \\code{U+0301}", fixed = TRUE)
  expect_match(rd, "begin or end part-way through a grapheme cluster",
               fixed = TRUE)
  expect_match(rd, "literal code-point count", fixed = TRUE)
})

test_that(".position means a code-point offset here and an emoji index there", {
  # Same dotted name, two units. ?tidyEmoji's contract used to gloss all five
  # structural indices in one breath, which was right for emoji_context() and
  # wrong for emoji_ngrams().
  A <- "\U0001F600"
  B <- "\U0001F621"
  fam <- "\U0001F468\u200D\U0001F469\u200D\U0001F467"
  txt <- paste0("hello ", A, " world ", fam, " end ", B)
  d <- data.frame(text = txt, stringsAsFactors = FALSE)

  cx <- emoji_context(d, text)
  expect_identical(nrow(cx), 3L)
  # the documented round trip, for a one-code-point glyph and a five-point one
  for (i in seq_len(nrow(cx))) {
    p <- cx$.position[i]
    expect_identical(substr(txt, p, p + nchar(cx$.emoji[i]) - 1L),
                     cx$.emoji[i], info = i)
  }
  # so it is an offset into the text, not a count of emoji
  expect_true(all(cx$.position > 3L))
  expect_identical(cx$.position[1L], 7L)

  ng <- emoji_ngrams(d, text)
  expect_identical(nrow(ng), 2L)
  expect_identical(ng$.position, 1:2)
  # the two columns share a name and disagree, which is the whole point
  expect_false(identical(sort(unique(cx$.position)), sort(unique(ng$.position))))

  pkg <- rd_flat("tidyEmoji-package")
  expect_match(pkg, "whose unit depends on the verb", fixed = TRUE)
  expect_match(rd_flat("emoji_context"), "code-point offset at which the emoji",
               fixed = TRUE)
  expect_match(rd_flat("emoji_ngrams"), "within the row's emoji", fixed = TRUE)
})

test_that("the indexed window path answers exactly what cutting the text did", {
  # emoji_context() used to cut the masked text once per occurrence with
  # substr(), which rescans a multi-byte string from its first byte, so the
  # verb was quadratic in the emoji per row -- 3200 emoji in one row cost
  # 7.1s against 0.28s for the same 3200 spread over 320 rows. Each row now
  # gets one index and every window is read off it.
  #
  # The risk in that change is not speed, it is a window that quietly differs
  # on an input nobody thought of, so the two paths are pinned to each other
  # here rather than the new one being pinned to hand-written expectations.
  # A timing assertion would be flaky on a shared runner; this is exact.
  ns <- asNamespace("tidyEmoji")
  window_at <- ns$.emoji_window_at
  window_indexed <- ns$.emoji_window_indexed
  row_index <- ns$.emoji_row_index

  fam <- paste0("\U0001f468\u200d\U0001f469\u200d",
                "\U0001f467\u200d\U0001f466")
  emo <- c(grin, cry, fam, "\U0001f44d\U0001f3fd", "\U0001f1fa\U0001f1f8",
           "1\ufe0f\u20e3", "\u2764\ufe0f")
  # the separators matter as much as the glyphs: the no-break and ideographic
  # spaces are whitespace to this package and not to iswspace() everywhere,
  # and a zero-width space is deliberately not whitespace at all
  seps <- c("", " ", "  ", "\t", "\u00a0", "\u3000", "\u200b", "\n")
  words <- c("the", "caf\u00e9", "\u4f60\u597d", "re-do", "x.y", "!!!", "a")

  set.seed(20260917)
  txt <- vapply(seq_len(400), function(i) {
    paste(sample(c(emo, words), sample(0:10, 1L), replace = TRUE),
          collapse = sample(seps, 1L))
  }, character(1))
  # and the shapes the random corpus will not reliably produce
  txt <- c(txt, "", " ", grin, strrep(grin, 25L), paste0("w", grin, "w"),
           paste0("  ", grin, "  "), paste0(grin, " \u00a0\u3000 x"),
           paste0("x\u200b", grin), paste0("\t", grin, "\t"))

  locs <- ns$.emoji_locations(txt)
  masked <- ns$.emoji_mask(txt, locs)
  occ <- ns$.emoji_occurrences(txt)
  len <- nchar(masked)
  expect_gt(nrow(occ), 500L)

  index <- lapply(masked, row_index)
  # every row here is valid UTF-8, so the index path must be available for
  # all of them; a NULL would silently turn this into a no-op
  expect_false(any(vapply(index, is.null, logical(1))))

  for (unit in c("word", "char")) {
    for (window in c(0L, 1L, 2L, 5L, 13L)) {
      cut_l <- ind_l <- cut_r <- ind_r <- character(nrow(occ))
      for (i in seq_len(nrow(occ))) {
        r <- occ$.row_number[i]
        ix <- index[[r]]
        from_r <- occ$.end[i] + 1L
        cut_l[i] <- window_at(masked[r], 1L, occ$.position[i] - 1L,
                              window, unit, "left")
        ind_l[i] <- window_indexed(ix, 1L, occ$.position[i] - 1L,
                                   window, unit, "left")
        cut_r[i] <- window_at(masked[r], from_r, len[r], window, unit, "right")
        ind_r[i] <- window_indexed(ix, from_r, ix$n, window, unit, "right")
      }
      info <- paste(unit, window)
      expect_identical(ind_l, cut_l, info = info)
      expect_identical(ind_r, cut_r, info = info)
    }
  }
})
