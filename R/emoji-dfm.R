#' Document-by-emoji feature matrix
#'
#' `emoji_dfm()` turns a text column into a wide, model-ready table with one
#' row per document and one column per emoji, weighted by raw counts, binary
#' presence or tf-idf. All documents are kept, including those with no emoji
#' (all-zero rows), so the result aligns row-for-row with the corpus and can be
#' bound to outcome columns for tidymodels-style workflows.
#'
#' By default every row of `data` is a document and the first output column,
#' `.row_number`, is its position in `data` (matching
#' [emoji_extract_unnest()]). Give `doc_id` to aggregate rows sharing an id
#' into one document; the id column keeps its name, and documents appear in the
#' order their id is first seen in `data`, never in the session's collation
#' order. Emoji columns are named by the glyph itself, canonicalised through
#' the package's codepoint key (so qualified and unqualified forms count as one
#' feature), and ordered by descending total count (ties broken by glyph).
#'
#' For `weighting = "tfidf"`, the cell for emoji *e* in document *d* is
#' `count(d, e) * log(N / df(e))`, where `N` is the number of documents and
#' `df(e)` the number of documents containing *e*. An emoji that appears in
#' every document therefore scores 0.
#'
#' @inheritParams emoji_summary
#' @param doc_id Optional unquoted column identifying documents; rows sharing
#'   a value are aggregated into one document. Default: each row is a
#'   document.
#' @param weighting One of `"count"` (default), `"binary"` or `"tfidf"`.
#' @return A tibble with one row per document: `.row_number` (or the `doc_id`
#'   column) followed by one numeric column per emoji, ordered by descending
#'   total count across the corpus with ties broken by the glyph. That ordering
#'   is computed in the C locale, so the column order does not depend on the
#'   session's collation and is safe to index by position. Zero emoji in the
#'   corpus yields just the document column.
#' @seealso [emoji_frequency()] for corpus totals; [emoji_tokens()] for the
#'   long form this widens.
#' @examples
#' df <- data.frame(text = c("\U0001f600\U0001f600 fun", "\U0001f621",
#'                           "no emoji"))
#' emoji_dfm(df, text)
#' emoji_dfm(df, text, weighting = "binary")
#' emoji_dfm(df, text, weighting = "tfidf")
#' @export
emoji_dfm <- function(data, text, doc_id = NULL,
                      weighting = c("count", "binary", "tfidf")) {
  weighting <- match.arg(weighting)
  if (.emoji_warn_grouped(
        data, "emoji_dfm", "0.3.0",
        details = "emoji_dfm() ignores groups. Use doc_id to define documents.")) {
    data <- dplyr::ungroup(data)
  }

  lst <- emoji_glyph_list(.emoji_text_col(data, {{ text }}))
  lst <- lapply(lst, emoji_canonical)

  q <- rlang::enquo(doc_id)
  if (rlang::quo_is_null(q)) {
    doc_col <- ".row_number"
    doc_vals <- seq_along(lst)
    docs <- lst
  } else {
    doc_col <- .emoji_col_name(data, !!q, arg = "doc_id")
    ids <- data[[doc_col]]
    # documents come out in first-appearance order of the id: factor() would
    # sort the levels with the session's collation, making the row order of the
    # result locale-dependent
    split_idx <- .emoji_id_split(ids)
    docs <- lapply(split_idx, function(i) unlist(lst[i], use.names = FALSE))
    # index back into the original ids so their type (Date, factor, ...) and
    # their exact value survive
    doc_vals <- ids[vapply(split_idx, `[`, integer(1), 1L)]
  }

  glyphs <- unique(unlist(docs, use.names = FALSE))
  out <- tibble::tibble(doc = doc_vals)
  names(out) <- doc_col
  if (!length(glyphs)) {
    return(out)
  }
  # Every emoji becomes a column named with the glyph itself, so a doc_id
  # column that happens to be named with one of those glyphs would be
  # overwritten by the count column and the document identifiers would vanish
  # silently. There is no room for both names, so say so.
  if (doc_col %in% glyphs) {
    stop(sprintf(
      paste0("`doc_id` names the column `%s`, which is also an emoji in the ",
             "corpus, and the result needs that name for the emoji's count ",
             "column. Rename the column."),
      doc_col
    ), call. = FALSE)
  }

  counts <- vapply(docs, function(g) {
    tabulate(match(g, glyphs), nbins = length(glyphs))
  }, integer(length(glyphs)))
  counts <- matrix(counts, nrow = length(glyphs))   # glyphs x docs

  # column order: descending total count, ties by glyph. radix = C-locale
  # ordering, so the column order does not depend on the session's collation
  ord <- order(-rowSums(counts), glyphs, method = "radix")
  glyphs <- glyphs[ord]
  counts <- counts[ord, , drop = FALSE]

  m <- t(counts)                                     # docs x glyphs
  if (weighting == "binary") {
    m[m > 0] <- 1L
  } else if (weighting == "tfidf") {
    df_e <- colSums(m > 0)
    idf <- log(nrow(m) / df_e)
    m <- sweep(m, 2L, idf, `*`)
  }

  for (j in seq_along(glyphs)) {
    out[[glyphs[j]]] <- if (weighting == "count") as.integer(m[, j]) else as.numeric(m[, j])
  }
  out
}
