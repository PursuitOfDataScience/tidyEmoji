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
  w <- strsplit(s, "[[:space:]]+")[[1L]]
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
    s <- if (side == "left") sub("[[:space:]]+$", "", s) else
      sub("^[[:space:]]+", "", s)
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
  need <- 4L * window + 16L
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
    need <- need * 2L
  }
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
#' the window is a literal character count after trimming the whitespace next
#' to the emoji.
#'
#' Tokenisation stops there on purpose. If you need stemming, stopword removal
#' or sentence splitting, pass the result to \pkg{tokenizers} or \pkg{tidytext}
#' rather than expecting this verb to grow a tokeniser.
#'
#' @inheritParams emoji_summary
#' @param window Size of the context window on each side, in tokens
#'   (`unit = "word"`) or characters (`unit = "char"`). Default `5`.
#' @param unit `"word"` (default) or `"char"`.
#' @param keep_text If `TRUE`, also return the row's original text column.
#'   Default `FALSE`.
#' @return A tibble with one row per emoji occurrence, in reading order, and
#'   columns `.row_number` (position of the entry in `data`), `.position` (the
#'   character position at which the emoji starts), `.emoji`,
#'   `.emoji_context_left`, `.emoji_context_right` and `.emoji_context` (the two
#'   sides joined by a space -- the co-text without the glyph). Rows with no
#'   emoji contribute nothing.
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
  unit <- match.arg(unit)
  .emoji_check_flag(keep_text, "keep_text")
  if (!.emoji_is_count(window)) {
    stop("`window` must be a single finite whole number >= 0.", call. = FALSE)
  }
  window <- as.integer(window)
  col_name <- .emoji_col_name(data, {{ text }})
  v <- .emoji_text_col(data, {{ text }})
  v[is.na(v)] <- ""
  locs <- .emoji_locations(v)
  masked <- .emoji_mask(v, locs)

  occ <- .emoji_occurrences(v)
  left <- character(nrow(occ))
  right <- character(nrow(occ))
  if (nrow(occ)) {
    len <- nchar(masked)
    for (i in seq_len(nrow(occ))) {
      r <- occ$.row_number[i]
      left[i] <- .emoji_window_at(
        masked[r], 1L, occ$.position[i] - 1L, window, unit, "left"
      )
      right[i] <- .emoji_window_at(
        masked[r], occ$.end[i] + 1L, len[r], window, unit, "right"
      )
    }
  }

  out <- tibble::tibble(
    .row_number = occ$.row_number,
    .position = occ$.position,
    .emoji = occ$.emoji,
    .emoji_context_left = left,
    .emoji_context_right = right,
    .emoji_context = trimws(paste(left, right))
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
#' repeats inside that window. Words are lower-cased and stripped of leading and
#' trailing punctuation; no stopword list is applied, because which stopwords
#' are right is a decision for your analysis, not for this package -- filter the
#' result with \pkg{tidytext}'s `stop_words` if you want one.
#'
#' PMI is `log(n(e, w) * N / (n(e) * n(w)))`, with `N` the total number of
#' emoji-word co-occurrence events. Marginals are computed over *all*
#' co-occurrences before `min_n` filters the rows, so a rare pairing is scored
#' against the full corpus rather than against the surviving subset.
#'
#' Glyphs are canonicalised through the package's codepoint key, so qualified
#' and unqualified forms of the same emoji share one row.
#'
#' @inheritParams emoji_summary
#' @param window Context window on each side, in words. Default `5`.
#' @param min_n Minimum number of co-occurrences for a pair to be reported.
#'   Default `3`.
#' @param measure Sort order: `"pmi"` (default) or `"count"`. Both columns are
#'   always returned.
#' @return A tibble with columns `emoji`, `word`, `n` (co-occurrences) and
#'   `pmi`, shaped like `widyr::pairwise_count()` output so it drops into
#'   existing tidytext workflows.
#' @seealso [emoji_context()] for the occurrence-level windows this aggregates.
#' @examples
#' df <- data.frame(text = c("cold coffee \U0001f622",
#'                           "coffee again \U0001f622",
#'                           "warm tea \U0001f60a"))
#' emoji_collocations(df, text, min_n = 1)
#' @export
emoji_collocations <- function(data, text, window = 5, min_n = 3,
                               measure = c("pmi", "count")) {
  measure <- match.arg(measure)
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
    w <- .emoji_words(.emoji_fold(s))
    w <- gsub("^[^[:alnum:]]+|[^[:alnum:]]+$", "", w)
    unique(w[nzchar(w)])
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
    dplyr::arrange(out, dplyr::desc(pmi), dplyr::desc(n), emoji, word)
  } else {
    dplyr::arrange(out, dplyr::desc(n), dplyr::desc(pmi), emoji, word)
  }
}
