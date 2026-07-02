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
#' into one document; the id column keeps its name. Emoji columns are named by
#' the glyph itself, canonicalised through the package's codepoint key (so
#' qualified and unqualified forms count as one feature), and ordered by
#' descending total count (ties broken by glyph).
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
#'   column) followed by one numeric column per emoji. Zero emoji in the
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
  if (dplyr::is_grouped_df(data)) {
    lifecycle::deprecate_warn(
      "0.4.0", "emoji_dfm(data = \"must be ungrouped data\")",
      details = "emoji_dfm() currently ignores groups. Use doc_id to define documents."
    )
    data <- dplyr::ungroup(data)
  }

  lst <- emoji_glyph_list(dplyr::pull(data, {{ text }}))
  lst <- lapply(lst, emoji_canonical)

  q <- rlang::enquo(doc_id)
  if (rlang::quo_is_null(q)) {
    doc_col <- ".row_number"
    doc_vals <- seq_along(lst)
    docs <- lst
  } else {
    ids <- dplyr::pull(data, !!q)
    doc_col <- names(dplyr::select(data, !!q))
    f <- factor(ids, exclude = NULL)
    split_idx <- split(seq_along(lst), f)
    docs <- lapply(split_idx, function(i) unlist(lst[i], use.names = FALSE))
    # levels(f) stringifies the ids; index back into the originals instead
    doc_vals <- ids[vapply(split_idx, `[`, integer(1), 1L)]
  }

  glyphs <- unique(unlist(docs, use.names = FALSE))
  out <- tibble::tibble(doc = doc_vals)
  names(out) <- doc_col
  if (!length(glyphs)) {
    return(out)
  }

  counts <- vapply(docs, function(g) {
    tabulate(match(g, glyphs), nbins = length(glyphs))
  }, integer(length(glyphs)))
  counts <- matrix(counts, nrow = length(glyphs))   # glyphs x docs

  # column order: descending total count, ties by glyph
  ord <- order(-rowSums(counts), glyphs)
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
