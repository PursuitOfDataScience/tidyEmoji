# Relational analysis: which emoji appear together, and in what order.
# All three verbs canonicalise glyphs through emoji_canonical(), so qualified
# and unqualified forms of the same emoji count as one item / node.

# Internal: list of canonicalised glyph vectors, one element per document.
# With `doc_id = NULL` every row is its own document; otherwise rows sharing a
# doc_id value are concatenated (in row order) into one document. Rows whose
# doc_id is NA form their own single document.
.emoji_doc_glyphs <- function(data, text, doc_id, presentation = "emoji") {
  lst <- emoji_glyph_list(.emoji_text_col(data, {{ text }}), presentation)
  lst <- lapply(lst, emoji_canonical)
  q <- rlang::enquo(doc_id)
  if (rlang::quo_is_null(q)) {
    return(lst)
  }
  ids <- .emoji_col(data, !!q, arg = "doc_id")
  split_idx <- .emoji_id_split(ids)
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
#'
#'   The result has a row per pair, so it grows with the *square* of the
#'   distinct emoji in a document: a day or a conversation is cheap, and
#'   pooling a whole corpus under one id is not. 800 distinct emoji in one
#'   document is 319,600 pairs and a few seconds; all 3963 would be 7.9 million.
#' @param directed If `TRUE`, pairs are ordered by first appearance: a
#'   document where the tears-of-joy emoji appears before the heart-eyes emoji
#'   counts towards (tears-of-joy, heart-eyes), not the reverse. Default
#'   `FALSE` (unordered pairs, with `item1` sorted before `item2`).
#' @param sort If `TRUE` (default), sort by descending `measure` (by
#'   descending `n` for `"count"`; ties broken by `n`, then `item1`, `item2`,
#'   so the order is deterministic). `FALSE` sorts by `item1` then `item2`
#'   instead, which is still a fixed order, computed in the C locale, not the
#'   order the pairs happened to be counted in.
#' @param measure `"count"` (default) for the raw co-occurrence counts, or an
#'   association measure to add as a column and sort by: `"ppmi"`,
#'   `"log_odds"` or `"dice"`. See *Counts are not associations*.
#' @section Counts are not associations:
#' Most emoji pairs in a real corpus are seen once: on the example corpus,
#' [oasst_messages], 4,044 of the 4,316 edges (93.7%) have `n = 1`. A graph
#' drawn from raw counts is mostly noise with a layout, and the common emoji
#' pair with everything simply because they are common. `measure` scores each
#' pair against what its two emoji's frequencies predict, over documents: `N`
#' is the number of documents holding at least one emoji, `n1` and `n2` the
#' number holding each item, and `n` the number holding both.
#'
#' * `"ppmi"` is positive pointwise mutual information,
#'   `max(0, log(n * N / (n1 * n2)))`: how much more often the two appear
#'   together than chance, floored at "no more often".
#' * `"log_odds"` is the log odds ratio of the two-by-two table of documents,
#'   with half a document added to every cell so a pair that never appears
#'   apart stays finite.
#' * `"dice"` is `2 * n / (n1 + n2)`, from 0 (never together) to 1 (never
#'   apart); unlike the other two it does not favour rare pairs.
#'
#' `N` counts only documents with an emoji, so adding emoji-free rows to a
#' corpus changes no measure. Under `directed = TRUE`, `n` counts documents
#' where `item1` comes first, and the measures score that ordered event
#' against the same marginals. For a network, filter on a frequency threshold
#' as well as on the measure, so the edges kept are both strong and seen more
#' than once.
#' @return A tibble with columns `item1`, `item2` and `n`, plus a column named
#'   after `measure` unless it is `"count"`. Empty (but typed) when no
#'   document contains two distinct emoji.
#' @seealso [emoji_cooccurrence()] for the same counts with an optional
#'   diagonal; [emoji_ngrams()] for consecutive sequences.
#' @examples
#' df <- data.frame(text = c("fun \U0001f602\U0001f60d",
#'                           "\U0001f602\U0001f60d\U0001f389",
#'                           "just \U0001f602"))
#' emoji_pairs(df, text)
#' emoji_pairs(df, text, directed = TRUE)
#' @concept networks and co-occurrence
#' @concept association measures
#' @export
emoji_pairs <- function(data, text, doc_id = NULL, directed = FALSE,
                        sort = TRUE, measure = c("count", "ppmi", "log_odds",
                                                 "dice"),
                        presentation = "emoji") {
  presentation <- .emoji_check_presentation(presentation)
  measure <- .emoji_match_arg(measure, c("count", "ppmi", "log_odds", "dice"),
                              "measure")
  .emoji_check_flag(directed, "directed")
  .emoji_check_flag(sort, "sort")
  if (.emoji_warn_grouped(
        data, "emoji_pairs", "0.3.0",
        details = "emoji_pairs() ignores groups. Use doc_id to define documents.")) {
    data <- dplyr::ungroup(data)
  }
  docs <- .emoji_doc_glyphs(data, {{ text }}, {{ doc_id }}, presentation)

  pair_list <- lapply(docs, function(g) {
    u <- unique(g)
    if (length(u) < 2L) return(NULL)
    # radix = C-locale ordering, matching .emoji_arrange() below, so which
    # glyph lands in item1 does not depend on the session's collation
    if (!directed) u <- sort(u, method = "radix")
    # all index pairs i < j; for directed input, u is in first-appearance
    # order, so i < j means "i appears before j"
    idx <- utils::combn(length(u), 2L)
    cbind(u[idx[1L, ]], u[idx[2L, ]])
  })
  pair_list <- pair_list[!vapply(pair_list, is.null, logical(1))]
  if (!length(pair_list)) {
    out <- tibble::tibble(item1 = character(), item2 = character(),
                          n = integer())
    if (measure != "count") out[[measure]] <- numeric()
    return(out)
  }
  m <- do.call(rbind, pair_list)
  out <- tibble::tibble(item1 = m[, 1L], item2 = m[, 2L]) %>%
    dplyr::count(item1, item2, name = "n")
  if (measure != "count") {
    # document frequencies over the documents that hold an emoji at all
    present <- lapply(docs, unique)
    n_docs <- sum(lengths(present) > 0L)
    df <- table(unlist(present, use.names = FALSE))
    n1 <- as.numeric(df[out$item1])
    n2 <- as.numeric(df[out$item2])
    out[[measure]] <- .emoji_association(measure, out$n, n1, n2, n_docs)
  }
  if (isTRUE(sort)) {
    if (measure == "count") {
      out <- .emoji_arrange(out, dplyr::desc(n), item1, item2)
    } else {
      out$.sort <- out[[measure]]
      out <- .emoji_arrange(out, dplyr::desc(.sort), dplyr::desc(n),
                            item1, item2)
      out$.sort <- NULL
    }
  } else {
    out <- .emoji_arrange(out, item1, item2)
  }
  out
}


#' Emoji co-occurrence counts, with an optional diagonal
#'
#' `emoji_cooccurrence()` is [emoji_pairs()] under the name the matrix form
#' goes by, with one argument added and two taken away.
#'
#' Added: `diagonal = TRUE` also returns the `item1 == item2` rows, whose `n`
#' is the number of documents containing that emoji (the diagonal of the
#' co-occurrence matrix, i.e. its document frequency).
#'
#' Taken away: there is no `directed` here. A co-occurrence matrix is
#' symmetric, so an ordered pair has no meaning on it and the diagonal this
#' verb exists to add would not either. Use [emoji_pairs()] when you want
#' `directed = TRUE`; the off-diagonal rows the two verbs return are otherwise
#' identical. Nor is there a `measure`: an association measure scores two
#' emoji against each other, and a diagonal cell has only one. Use
#' [emoji_pairs()] for the association-weighted edges.
#'
#' Glyphs are canonicalised through the package's codepoint key, so two
#' spellings of one emoji make one row rather than two; see
#' *Which spelling comes back* in [tidyEmoji].
#'
#' @inheritParams emoji_pairs
#' @param diagonal If `TRUE`, include one `item1 == item2` row per emoji with
#'   its document frequency. Default `FALSE`.
#' @return A tibble with columns `item1`, `item2` and `n`.
#' @seealso [emoji_pairs()], [emoji_ngrams()].
#' @examples
#' df <- data.frame(text = c("\U0001f602\U0001f60d", "\U0001f602"))
#' emoji_cooccurrence(df, text, diagonal = TRUE)
#' @concept networks and co-occurrence
#' @export
emoji_cooccurrence <- function(data, text, doc_id = NULL, diagonal = FALSE,
                               sort = TRUE, presentation = "emoji") {
  presentation <- .emoji_check_presentation(presentation)
  .emoji_check_flag(diagonal, "diagonal")
  # Warn under this verb's own name, then ungroup: delegating to emoji_pairs()
  # while still grouped named emoji_pairs() in the warning -- a function the
  # user never called -- and lifecycle's per-topic deduplication then silenced
  # the warning entirely for anyone who had already called emoji_pairs().
  if (.emoji_warn_grouped(
        data, "emoji_cooccurrence", "0.4.0",
        details = "emoji_cooccurrence() ignores groups. Use doc_id to define documents.")) {
    data <- dplyr::ungroup(data)
  }
  out <- emoji_pairs(data, {{ text }}, doc_id = {{ doc_id }},
                     directed = FALSE, sort = sort,
                     presentation = presentation)
  if (isTRUE(diagonal)) {
    docs <- .emoji_doc_glyphs(data, {{ text }}, {{ doc_id }}, presentation)
    present <- unlist(lapply(docs, unique), use.names = FALSE)
    if (length(present)) {
      diag_tbl <- tibble::tibble(item1 = present, item2 = present) %>%
        dplyr::count(item1, item2, name = "n")
      out <- dplyr::bind_rows(out, diag_tbl)
      out <- if (isTRUE(sort)) {
        .emoji_arrange(out, dplyr::desc(n), item1, item2)
      } else {
        .emoji_arrange(out, item1, item2)
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
#' Glyphs are canonicalised through the package's codepoint key, so two
#' spellings of one emoji make one n-gram token rather than two; see
#' *Which spelling comes back* in [tidyEmoji].
#'
#' @inheritParams emoji_summary
#' @param n Length of the n-gram window. Default `2` (bigrams).
#' @param sep Separator between the glyphs of an n-gram. Default a space.
#' @return A tibble with columns `.row_number` (position of the entry in
#'   `data`), `.position` (where the n-gram starts within the row's emoji
#'   sequence) and `.emoji_ngram`. Rows with fewer than `n` emoji contribute
#'   nothing. The columns of `data` are not carried, so a grouping is not
#'   either -- join back on `.row_number` to recover them. Unlike the
#'   corpus-wide verbs this one does not pool your rows, so there is no
#'   per-group answer being silently turned into a global one.
#' @seealso [emoji_pairs()] for order-free co-occurrence;
#'   [emoji_extract_unnest()] for the underlying one-emoji-per-row form;
#'   [emoji_runs()] for maximal runs rather than windows of a fixed length.
#' @examples
#' df <- data.frame(text = c("\U0001f602\U0001f60d\U0001f389", "\U0001f602"))
#' emoji_ngrams(df, text)
#' emoji_ngrams(df, text, n = 3)
#' @concept sequences
#' @export
emoji_ngrams <- function(data, text, n = 2, sep = " ",
                         presentation = "emoji") {
  presentation <- .emoji_check_presentation(presentation)
  if (!.emoji_is_count(n, min = 1)) {
    stop("`n` must be a single finite whole number >= 1.", call. = FALSE)
  }
  .emoji_check_string(sep, "sep")
  # A finite whole number past integer range is a valid "longer than any row"
  # and must give no n-grams, not NA: as.integer() of it warned "NAs
  # introduced by coercion to integer range" and the row loop then died on
  # "missing value where TRUE/FALSE needed". No row holds more emoji than
  # that, so capping it changes no answer.
  n <- as.integer(min(n, .Machine$integer.max))
  lst <- emoji_glyph_list(.emoji_text_col(data, {{ text }}), presentation)
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
