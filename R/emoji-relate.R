# Relational analysis: which emoji appear together, and in what order.
# All three verbs canonicalise glyphs through emoji_canonical(), so qualified
# and unqualified forms of the same emoji count as one item / node.

# Internal: list of canonicalised glyph vectors, one element per document.
# With `doc_id = NULL` every row is its own document; otherwise rows sharing a
# doc_id value are concatenated (in row order) into one document. Rows whose
# doc_id is NA form their own single document.
.emoji_doc_glyphs <- function(data, text, doc_id) {
  lst <- emoji_glyph_list(dplyr::pull(data, {{ text }}))
  lst <- lapply(lst, emoji_canonical)
  q <- rlang::enquo(doc_id)
  if (rlang::quo_is_null(q)) {
    return(lst)
  }
  ids <- dplyr::pull(data, !!q)
  split_idx <- split(seq_along(lst), factor(ids, exclude = NULL))
  lapply(split_idx, function(i) unlist(lst[i], use.names = FALSE))
}

#' Co-occurring emoji pairs
#'
#' `emoji_pairs()` returns a tidy edge list of the emoji that appear together
#' in the same document: one row per pair with the number of documents in which
#' the pair co-occurs. By default every row of `data` is a document; give
#' `doc_id` to treat all rows sharing an id (a conversation, a user, a day) as
#' one document. The output mirrors `widyr::pairwise_count()` (`item1`,
#' `item2`, `n`) and pipes straight into
#' `igraph::graph_from_data_frame()`, tidygraph or ggraph.
#'
#' Glyphs are canonicalised through the package's codepoint key, so qualified
#' and unqualified forms of the same emoji (with/without `U+FE0F`) count as one
#' node. Pairs are between *distinct* emoji: repeats of the same emoji in a
#' document do not pair with themselves (see [emoji_cooccurrence()] for the
#' diagonal).
#'
#' @inheritParams emoji_summary
#' @param doc_id Optional unquoted column identifying documents. Rows sharing
#'   a value are treated as one document. Default: each row is a document.
#' @param directed If `TRUE`, pairs are ordered by first appearance: a
#'   document where the tears-of-joy emoji appears before the heart-eyes emoji
#'   counts towards (tears-of-joy, heart-eyes), not the reverse. Default
#'   `FALSE` (unordered pairs, with `item1` sorted before `item2`).
#' @param sort If `TRUE` (default), sort by descending `n` (ties broken by
#'   `item1`, `item2` so the order is deterministic).
#' @return A tibble with columns `item1`, `item2` and `n`. Empty (but typed)
#'   when no document contains two distinct emoji.
#' @seealso [emoji_cooccurrence()] for the same counts with an optional
#'   diagonal; [emoji_ngrams()] for consecutive sequences.
#' @examples
#' df <- data.frame(text = c("fun \U0001f602\U0001f60d",
#'                           "\U0001f602\U0001f60d\U0001f389",
#'                           "just \U0001f602"))
#' emoji_pairs(df, text)
#' emoji_pairs(df, text, directed = TRUE)
#' @export
emoji_pairs <- function(data, text, doc_id = NULL, directed = FALSE,
                        sort = TRUE) {
  if (dplyr::is_grouped_df(data)) {
    lifecycle::deprecate_warn(
      "0.4.0", "emoji_pairs(data = \"must be ungrouped data\")",
      details = "emoji_pairs() currently ignores groups. Use doc_id to define documents."
    )
    data <- dplyr::ungroup(data)
  }
  docs <- .emoji_doc_glyphs(data, {{ text }}, {{ doc_id }})

  pair_list <- lapply(docs, function(g) {
    u <- unique(g)
    if (length(u) < 2L) return(NULL)
    if (!directed) u <- sort(u)
    # all index pairs i < j; for directed input, u is in first-appearance
    # order, so i < j means "i appears before j"
    idx <- utils::combn(length(u), 2L)
    cbind(u[idx[1L, ]], u[idx[2L, ]])
  })
  pair_list <- pair_list[!vapply(pair_list, is.null, logical(1))]
  if (!length(pair_list)) {
    return(tibble::tibble(item1 = character(), item2 = character(),
                          n = integer()))
  }
  m <- do.call(rbind, pair_list)
  out <- tibble::tibble(item1 = m[, 1L], item2 = m[, 2L]) %>%
    dplyr::count(item1, item2, name = "n")
  if (isTRUE(sort)) {
    out <- dplyr::arrange(out, dplyr::desc(n), item1, item2)
  } else {
    out <- dplyr::arrange(out, item1, item2)
  }
  out
}


#' Emoji co-occurrence counts, with an optional diagonal
#'
#' `emoji_cooccurrence()` is [emoji_pairs()] under another name, with one
#' addition: `diagonal = TRUE` also returns the `item1 == item2` rows, whose
#' `n` is the number of documents containing that emoji (the diagonal of the
#' co-occurrence matrix, i.e. its document frequency).
#'
#' @inheritParams emoji_pairs
#' @param diagonal If `TRUE`, include one `item1 == item2` row per emoji with
#'   its document frequency. Default `FALSE`.
#' @return A tibble with columns `item1`, `item2` and `n`.
#' @seealso [emoji_pairs()], [emoji_ngrams()].
#' @examples
#' df <- data.frame(text = c("\U0001f602\U0001f60d", "\U0001f602"))
#' emoji_cooccurrence(df, text, diagonal = TRUE)
#' @export
emoji_cooccurrence <- function(data, text, doc_id = NULL, diagonal = FALSE,
                               sort = TRUE) {
  out <- emoji_pairs(data, {{ text }}, doc_id = {{ doc_id }},
                     directed = FALSE, sort = sort)
  if (isTRUE(diagonal)) {
    docs <- .emoji_doc_glyphs(
      if (dplyr::is_grouped_df(data)) dplyr::ungroup(data) else data,
      {{ text }}, {{ doc_id }}
    )
    present <- unlist(lapply(docs, unique), use.names = FALSE)
    if (length(present)) {
      diag_tbl <- tibble::tibble(item1 = present, item2 = present) %>%
        dplyr::count(item1, item2, name = "n")
      out <- dplyr::bind_rows(out, diag_tbl)
      out <- if (isTRUE(sort)) {
        dplyr::arrange(out, dplyr::desc(n), item1, item2)
      } else {
        dplyr::arrange(out, item1, item2)
      }
    }
  }
  out
}


#' Consecutive emoji sequences (n-grams)
#'
#' `emoji_ngrams()` slides a window of `n` over each row's emoji, in reading
#' order (any text between the emoji is ignored), and returns one row per
#' n-gram occurrence. Repeated emoji are kept: a row containing the same emoji
#' twice in a row yields a bigram of that emoji with itself. This is the emoji
#' analogue of `tidytext::unnest_tokens(..., token = "ngrams")` and feeds
#' sequence / Markov-style analyses of how emoji chain together.
#'
#' @inheritParams emoji_summary
#' @param n Length of the n-gram window. Default `2` (bigrams).
#' @param sep Separator between the glyphs of an n-gram. Default a space.
#' @return A tibble with columns `.row_number` (position of the entry in
#'   `data`), `.position` (where the n-gram starts within the row's emoji
#'   sequence) and `.emoji_ngram`. Rows with fewer than `n` emoji contribute
#'   nothing.
#' @seealso [emoji_pairs()] for order-free co-occurrence;
#'   [emoji_extract_unnest()] for the underlying one-emoji-per-row form.
#' @examples
#' df <- data.frame(text = c("\U0001f602\U0001f60d\U0001f389", "\U0001f602"))
#' emoji_ngrams(df, text)
#' emoji_ngrams(df, text, n = 3)
#' @export
emoji_ngrams <- function(data, text, n = 2, sep = " ") {
  if (!is.numeric(n) || length(n) != 1L || is.na(n) || n < 1) {
    stop("`n` must be a single integer >= 1.", call. = FALSE)
  }
  n <- as.integer(n)
  lst <- emoji_glyph_list(dplyr::pull(data, {{ text }}))
  lst <- lapply(lst, emoji_canonical)

  per_row <- lapply(seq_along(lst), function(i) {
    g <- lst[[i]]
    k <- length(g) - n + 1L
    if (k < 1L) return(NULL)
    grams <- vapply(seq_len(k), function(j) {
      paste(g[j:(j + n - 1L)], collapse = sep)
    }, character(1))
    tibble::tibble(.row_number = i, .position = seq_len(k),
                   .emoji_ngram = grams)
  })
  per_row <- per_row[!vapply(per_row, is.null, logical(1))]
  if (!length(per_row)) {
    return(tibble::tibble(.row_number = integer(), .position = integer(),
                          .emoji_ngram = character()))
  }
  dplyr::bind_rows(per_row)
}
