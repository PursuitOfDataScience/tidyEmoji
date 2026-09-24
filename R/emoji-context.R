# Co-text: the words an emoji keeps company with.
#
# Every disambiguation, irony and pragmatics analysis needs the text *around*
# an emoji, and until now tidyEmoji reported which emoji occurred and threw the
# co-text away. emoji_context() is the missing primitive; emoji_collocations()
# is the corpus-level view of the same data.

# Blank every emoji span with spaces, keeping the string's length (and hence
# every character offset) intact. Context windows are then plain substrings of
# the masked text, with neighbouring emoji already removed.
.emoji_mask <- function(v, locs) {
  vapply(seq_along(v), function(i) {
    m <- locs[[i]]
    if (is.null(m) || nrow(m) == 0L) return(v[[i]])
    g <- .emoji_slice(m, v[[i]])
    .emoji_replace_in_order(v[[i]], m, g, strrep(" ", nchar(g)))
  }, character(1))
}

# Whitespace-delimited tokens of one string, empty strings dropped.
.emoji_words <- function(s) {
  if (!nzchar(s)) return(character(0))
  w <- strsplit(s, .emoji_ws)[[1L]]
  w[nzchar(w)]
}

# The `window` tokens (or characters) nearest the emoji, on the given side.
.emoji_window <- function(s, window, unit, side) {
  if (unit == "word") {
    w <- .emoji_words(s)
    if (!length(w)) return("")
    w <- if (side == "left") utils::tail(w, window) else utils::head(w, window)
    paste(w, collapse = " ")
  } else {
    s <- if (side == "left") sub(paste0(.emoji_ws, "$"), "", s) else
      sub(paste0("^", .emoji_ws), "", s)
    n <- nchar(s)
    if (!n) return("")
    if (side == "left") {
      substr(s, max(1L, n - window + 1L), n)
    } else {
      substr(s, 1L, min(window, n))
    }
  }
}


# The window on one side of an emoji, read from a slice of the masked text
# anchored at the glyph instead of the whole prefix/suffix.
#
# Handing `.emoji_window()` the entire side made emoji_context() quadratic in
# the emoji per row: every occurrence copied and re-tokenised each character
# before it, so a row with 1600 emoji cost ~1.5s where 100 cost 0.02s. The
# answer only ever depends on the `window` tokens (or characters) nearest the
# glyph, so a bounded slice is equivalent -- provided it demonstrably contains
# them. It does when the slice yields more than `window` tokens (the outermost
# one may be cut by the slice edge, the nearer `window` cannot be), or, for
# `unit = "char"`, when it still holds `window` characters after the
# emoji-adjacent whitespace is trimmed. Otherwise the budget doubles, and
# falling back to the full side keeps pathological all-whitespace input exact.
.emoji_window_at <- function(s, from, to, window, unit, side) {
  if (from > to) return("")
  span <- to - from + 1L
  # double, not integer: the budget doubles below and must not overflow
  need <- 4 * window + 16
  repeat {
    full <- need >= span
    if (full) {
      lo <- from
      hi <- to
    } else if (side == "left") {
      lo <- to - need + 1L
      hi <- to
    } else {
      lo <- from
      hi <- from + need - 1L
    }
    part <- substr(s, lo, hi)
    out <- .emoji_window(part, window, unit, side)
    if (full) return(out)
    enough <- if (unit == "word") {
      length(.emoji_words(part)) > window
    } else {
      nchar(out) >= window
    }
    if (enough) return(out)
    need <- need * 2
  }
}

# Per-row index for the context windows: the masked row as code points, plus
# the boundaries of its whitespace-delimited tokens and, for `unit = "char"`,
# the nearest non-whitespace position on either side of every offset.
#
# The bounded slice above keeps the *tokenising* cheap, but not the cutting:
# substr() on a multi-byte string rescans from the first byte to reach a
# character offset, so answering k occurrences still costs O(k * L). And on a
# row whose masked text is all spaces -- which is what a row of nothing but
# emoji becomes -- no slice ever yields a token, so the budget doubles up to
# the whole side every time and the verb is fully quadratic. That is the shape
# a chat or reaction corpus is full of, the same family of rows
# emoji_ratio()'s `.emoji_only` exists to find: 3200 emoji in one row took
# 7.1s, against 0.28s for the same 3200 spread over 320 rows.
#
# Building this once per row makes every window an index lookup. It is exact
# rather than an approximation of the slice path: emoji spans are masked to
# spaces, so the answers are identical by construction, and the substring path
# is still there for a row utf8ToInt() cannot represent.
#
# That last guard is belt and braces rather than a case anyone can construct.
# It was written for "a latin1-marked row", which does not work: latin1 has no
# emoji in it, so marking a string latin1 turns the glyph's bytes into
# mojibake and .emoji_locations() then finds nothing to index. Reaching here
# needs a row holding two detectable emoji that utf8ToInt() still refuses, and
# detection itself needs valid UTF-8, so the two conditions do not meet.
# Line coverage reports it unreached, correctly.
.emoji_row_index <- function(s) {
  cp <- tryCatch(utf8ToInt(s), error = function(e) NA_integer_)
  if (anyNA(cp)) return(NULL)
  nz <- !(cp %in% .emoji_ws_cps)
  # a token is a maximal run of non-whitespace; diff() of the padded run marks
  # where each one opens and closes
  d <- diff(c(FALSE, nz, FALSE))
  # cummax() over the non-whitespace offsets gives, at every position, the
  # nearest non-whitespace at or before it (0 when there is none); the
  # reversed pass gives the nearest at or after it (length + 1 when none).
  n <- length(cp)
  idx <- seq_len(n)
  prev_nz <- cummax(ifelse(nz, idx, 0L))
  next_nz <- rev(cummin(rev(ifelse(nz, idx, n + 1L))))
  list(cp = cp, n = n,
       start = which(d == 1L), end = which(d == -1L) - 1L,
       prev_nz = prev_nz, next_nz = next_nz)
}

# The window on one side of an emoji, answered from .emoji_row_index().
#
# `from`/`to` bound the side, exactly as they do for .emoji_window_at(), and
# the result matches what that function returns for the same arguments. Tokens
# overlapping the bound are clamped to it rather than dropped, which is what
# splitting the slice itself did.
.emoji_window_indexed <- function(ix, from, to, window, unit, side) {
  if (from > to || window < 1L) return("")
  take <- function(a, b) intToUtf8(ix$cp[a:b])
  if (unit == "char") {
    if (side == "left") {
      e <- ix$prev_nz[to]
      if (e < from) return("")
      return(take(max(from, e - window + 1L), e))
    }
    b <- ix$next_nz[from]
    if (b > to) return("")
    return(take(b, min(to, b + window - 1L)))
  }
  # word: the tokens overlapping [from, to] are contiguous, so binary search
  # for the two ends rather than scanning every token for every occurrence
  i0 <- findInterval(from - 1L, ix$end) + 1L
  i1 <- findInterval(to, ix$start)
  if (i0 > i1) return("")
  sel <- if (side == "left") {
    seq.int(max(i0, i1 - window + 1L), i1)
  } else {
    seq.int(i0, min(i1, i0 + window - 1L))
  }
  paste(vapply(sel, function(j) {
    take(max(ix$start[j], from), min(ix$end[j], to))
  }, character(1)), collapse = " ")
}

#' The text around each emoji occurrence
#'
#' `emoji_context()` returns one row per emoji occurrence with a window of the
#' text on either side of it. It is the primitive the context-dependent
#' analyses need: emoji are polysemous, and what a glyph means in a message is
#' decided by its co-text, not by a lexicon.
#'
#' @details
#' Windows are taken from the text with *all* emoji blanked out, so a
#' neighbouring emoji never lands in a context window and character offsets stay
#' exact. With `unit = "word"` a token is a maximal run of non-whitespace
#' characters, the same definition [emoji_density()] uses; with `unit = "char"`
#' the window is a literal code-point count after trimming the whitespace next
#' to the emoji.
#'
#' Tokenisation stops there on purpose. If you need stemming, stopword removal
#' or sentence splitting, pass the result to \pkg{tokenizers} or \pkg{tidytext}
#' rather than expecting this verb to grow a tokeniser.
#'
#' **Whitespace tokenisation has one consequence worth stating outright, because
#' it is invisible in the output.** A script that does not put spaces between
#' words (Chinese, Japanese, Thai, Khmer, Lao, Burmese) has no whitespace for a
#' token to end at, so a whole clause arrives as a single token and
#' `window = 5` reaches five clauses rather than five words. This is not
#' something the result can be passed to a tokeniser to repair: segmentation has
#' to happen *before* the text reaches this verb, by inserting the spaces (with
#' \pkg{tokenizers}, `jiebaR` or ICU) into the column you pass in. For a quick
#' look without that, `unit = "char"` sidesteps the question entirely and is the
#' better default on such text.
#'
#' @inheritParams emoji_summary
#' @param window Size of the context window on each side, in tokens
#'   (`unit = "word"`) or characters (`unit = "char"`). Default `5`.
#' @param unit `"word"` (default) or `"char"`. "Character" means *code
#'   point*, the unit [nchar()] and [substr()] count and the one
#'   [emoji_density()] and [emoji_ratio()] measure in. A character window can
#'   therefore begin or end part-way through a grapheme cluster: where an `e`
#'   carries a combining acute (`U+0065 U+0301`), `window = 1` returns the
#'   bare `U+0301`, a diacritic with nothing to sit on. Emoji themselves are
#'   safe from this, being masked out whole (see Details), and so is
#'   `unit = "word"`. If the window is going to be read by a person rather
#'   than tokenised, ask for words, or for a few more characters than you
#'   need.
#' @param keep_text If `TRUE`, also return the row's original text column.
#'   Default `FALSE`.
#' @return A tibble with one row per emoji occurrence, in reading order, and
#'   columns `.row_number` (position of the entry in `data`), `.position` (the
#'   code-point offset at which the emoji starts, the unit [substr()] takes,
#'   so `substr(text, .position, .position + nchar(.emoji) - 1)` is the glyph;
#'   [emoji_ngrams()]'s column of the same name counts emoji instead),
#'   `.emoji`,
#'   `.emoji_context_left`, `.emoji_context_right` and `.emoji_context` (the two
#'   sides joined by a space -- the co-text without the glyph). Rows with no
#'   emoji contribute nothing. The columns of `data` are not carried, so a
#'   grouping is not either -- join back on `.row_number` to recover them.
#' @seealso [emoji_collocations()] for the corpus-level view;
#'   [emoji_position()] for where emoji sit in a text.
#' @examples
#' df <- data.frame(text = c("the coffee was cold \U0001f622 again",
#'                           "no emoji here"))
#' emoji_context(df, text, window = 2)
#' emoji_context(df, text, window = 6, unit = "char")
#' @export
emoji_context <- function(data, text, window = 5, unit = c("word", "char"),
                          keep_text = FALSE) {
  unit <- .emoji_match_arg(unit, c("word", "char"), "unit")
  .emoji_check_flag(keep_text, "keep_text")
  if (!.emoji_is_count(window)) {
    stop("`window` must be a single finite whole number >= 0.", call. = FALSE)
  }
  # A validated window past integer range became NA here, with R's coercion
  # warning, and one big enough to stay in range still overflowed the window
  # arithmetic below (`4L * window`, `b + window - 1L`) and died on "missing
  # value where TRUE/FALSE needed". `window = 1e9` is a reasonable way to ask
  # for the whole text. No side of an emoji can hold more tokens or code
  # points than the longest text has code points, so capping the window there
  # changes no answer and keeps every sum in range.
  window <- as.integer(min(window, .Machine$integer.max))
  col_name <- .emoji_col_name(data, {{ text }})
  v <- .emoji_text_col(data, {{ text }})
  v[is.na(v)] <- ""
  locs <- .emoji_locations(v)
  masked <- .emoji_mask(v, locs)
  window <- min(window, max(c(0L, nchar(masked))))

  occ <- .emoji_occurrences(v)
  left <- character(nrow(occ))
  right <- character(nrow(occ))
  if (nrow(occ)) {
    len <- nchar(masked)
    rows <- occ$.row_number
    starts <- occ$.position
    ends <- occ$.end
    # One index per row holding more than one emoji, shared by every
    # occurrence in it. A row holding a single occurrence keeps the substring
    # path: the index is several vectorised passes over the row against the
    # two substr() calls it would replace, so it only starts paying from the
    # second occurrence on. Measured crossover is exactly there -- at one
    # occurrence per row the index costs 1.4x, at two it saves 1.3x, and it
    # goes on saving from there.
    dense <- which(tabulate(rows, nbins = length(masked)) > 1L)
    index <- vector("list", length(masked))
    index[dense] <- lapply(masked[dense], .emoji_row_index)
    for (i in seq_along(rows)) {
      r <- rows[i]
      ix <- index[[r]]
      if (is.null(ix)) {
        # In practice: the row holds a single occurrence, so no index was
        # built for it. In principle also a row utf8ToInt() cannot represent,
        # which is the unreachable half discussed above. Cut the text
        # instead, as .emoji_slice() does.
        left[i] <- .emoji_window_at(masked[r], 1L, starts[i] - 1L,
                                    window, unit, "left")
        right[i] <- .emoji_window_at(masked[r], ends[i] + 1L, len[r],
                                     window, unit, "right")
      } else {
        left[i] <- .emoji_window_indexed(ix, 1L, starts[i] - 1L,
                                         window, unit, "left")
        right[i] <- .emoji_window_indexed(ix, ends[i] + 1L, ix$n,
                                          window, unit, "right")
      }
    }
  }

  out <- tibble::tibble(
    .row_number = occ$.row_number,
    .position = occ$.position,
    .emoji = occ$.emoji,
    .emoji_context_left = left,
    .emoji_context_right = right,
    .emoji_context = .emoji_trimws(paste(left, right))
  )
  if (isTRUE(keep_text)) {
    txt <- .emoji_text_col(data, {{ text }})
    nm <- if (col_name %in% names(out)) paste0(col_name, ".text") else col_name
    out[[nm]] <- txt[occ$.row_number]
    out <- out[c(".row_number", nm,
                 setdiff(names(out), c(".row_number", nm)))]
  }
  out
}


#' Which words keep company with which emoji
#'
#' `emoji_collocations()` counts the words that appear near each emoji across a
#' corpus and scores the association with pointwise mutual information. It is
#' the corpus-derived alternative to importing a fixed sense inventory: the
#' senses come from *your* texts, so they cannot be stale and carry no licence
#' baggage.
#'
#' @details
#' Each emoji occurrence contributes its context window (see
#' [emoji_context()]). A word is counted once per occurrence however often it
#' repeats inside that window. Words are lower-cased and stripped of leading
#' and trailing characters that are not letters, digits or combining marks, and
#' a token left holding no letter and no digit at all is not a word. All three
#' rules read Unicode's own tables rather than the session's locale, so a
#' corpus in any script gives the same answer wherever it is run. No stopword
#' list is applied, because which stopwords are right is a decision for your
#' analysis, not for this package -- filter the result with
#' \pkg{tidytext}'s `stop_words` if you want one.
#'
#' PMI is `log(n(e, w) * N / (n(e) * n(w)))`, with `N` the total number of
#' emoji-word co-occurrence events. Marginals are computed over *all*
#' co-occurrences before `min_n` filters the rows, so a rare pairing is scored
#' against the full corpus rather than against the surviving subset.
#'
#' Glyphs are canonicalised through the package's codepoint key, so qualified
#' and unqualified forms of the same emoji share one row.
#'
#' **On a script without spaces between words this verb cannot find a
#' collocation at all, and it will not say so.** Its tokens are the
#' whitespace-delimited ones of [emoji_context()], so a Chinese, Japanese, Thai,
#' Khmer, Lao or Burmese clause is one token: three rows of Chinese reading
#' "the weather is good today", "my mood is good today" and "going to Beijing
#' tomorrow" yield three tokens, each a whole clause, each with `n = 1`, and
#' nothing clears `min_n`. The same three sentences in English yield `good`,
#' `is` and `today` at `n = 2`. Segment the column before it reaches this verb
#' (see [emoji_context()]); `min_n` cannot rescue a vocabulary in which every
#' type occurs once.
#'
#' @inheritParams emoji_summary
#' @param window Context window on each side, in words. Default `5`.
#' @param min_n Minimum number of co-occurrences for a pair to be reported.
#'   Default `3`.
#' @param measure Sort order: `"pmi"` (default) or `"count"`. Both columns are
#'   always returned.
#' @return A tibble with columns `emoji`, `word`, `n` (co-occurrences) and
#'   `pmi`, shaped like `widyr::pairwise_count()` output so it drops into
#'   existing tidytext workflows. Rows are sorted by `measure` descending,
#'   then by the other of the two descending, then by the glyph and the word,
#'   so the order is fully determined. Ties in `pmi` are common: every pair
#'   seen the same number of times with the same marginals scores alike.
#' @seealso [emoji_context()] for the occurrence-level windows this aggregates.
#' @examples
#' df <- data.frame(text = c("cold coffee \U0001f622",
#'                           "coffee again \U0001f622",
#'                           "warm tea \U0001f60a"))
#' emoji_collocations(df, text, min_n = 1)
#' @export
emoji_collocations <- function(data, text, window = 5, min_n = 3,
                               measure = c("pmi", "count")) {
  measure <- .emoji_match_arg(measure, c("pmi", "count"), "measure")
  if (!.emoji_is_count(min_n, finite = FALSE)) {
    stop("`min_n` must be a single non-negative whole number.", call. = FALSE)
  }
  .emoji_warn_grouped(data, "emoji_collocations", "0.4.0")
  empty <- tibble::tibble(emoji = character(), word = character(),
                          n = integer(), pmi = numeric())
  ctx <- emoji_context(data, {{ text }}, window = window, unit = "word")
  if (!nrow(ctx)) return(empty)

  glyph <- emoji_canonical(ctx$.emoji)
  words <- lapply(ctx$.emoji_context, function(s) {
    unique(.emoji_trim_words(.emoji_words(.emoji_fold(s))))
  })
  if (!sum(lengths(words))) return(empty)

  pairs <- tibble::tibble(
    emoji = rep(glyph, lengths(words)),
    word = unlist(words, use.names = FALSE)
  )
  counts <- dplyr::count(pairs, emoji, word, name = "n")
  total <- sum(counts$n)
  # marginals over every co-occurrence, before min_n prunes the table
  emoji_tot <- vapply(split(counts$n, counts$emoji), sum, numeric(1))
  word_tot <- vapply(split(counts$n, counts$word), sum, numeric(1))
  counts$pmi <- unname(log(
    counts$n * total / (emoji_tot[counts$emoji] * word_tot[counts$word])
  ))
  out <- counts[counts$n >= min_n, , drop = FALSE]
  out <- out[c("emoji", "word", "n", "pmi")]
  if (measure == "pmi") {
    .emoji_arrange(out, dplyr::desc(pmi), dplyr::desc(n), emoji, word)
  } else {
    .emoji_arrange(out, dplyr::desc(n), dplyr::desc(pmi), emoji, word)
  }
}
