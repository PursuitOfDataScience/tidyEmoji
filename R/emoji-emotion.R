#' Emoji emotion profiles (the 8 Plutchik emotions)
#'
#' `emoji_emotion()` scores each row's emoji across the eight Plutchik emotions
#' (anger, anticipation, disgust, fear, joy, sadness, surprise, trust) using the
#' bundled EmoTag1200 lexicon (Shoeb & de Melo, 2020). Scores each range from 0 to
#' 1 and are averaged over the emoji in the row that appear in the lexicon.
#'
#' @inheritParams emoji_summary
#' @param lexicon Lexicon to use. Either a string naming a bundled lexicon
#'   (`"emotag1200"`, the default) or a registered lexicon (see
#'   [register_emoji_lexicon()]). Currently only `"emotag1200"` ships.
#' @param long If `TRUE`, return one row per (row, emotion) in long form with
#'   columns `.emoji_emotion` (the emotion name) and `.emoji_score` (its mean).
#'   Default `FALSE` adds eight `.emoji_<emotion>` columns plus `.emoji_n` and
#'   `.emoji_n_scored`.
#' @return `data`, as a tibble, with emotion columns added. Rows without emoji,
#'   or whose emoji are absent from the lexicon, receive `NA` scores.
#' @references Shoeb AAM, de Melo G (2020). EmoTag1200: Understanding the
#'   Association between Emojis and Emotions. *EMNLP 2020*.
#'   <https://aclanthology.org/2020.emnlp-main.720/>. Data released under the MIT
#'   licence.
#' @seealso [emoji_emotion_lexicon] for the underlying scores;
#'   [emoji_emotion_label()] for the dominant emotion per row;
#'   [emoji_sentiment()] for valence.
#' @examples
#' df <- data.frame(text = c("love it \U0001f60d", "scary \U0001f628", "meh"))
#' emoji_emotion(df, text)
#' emoji_emotion(df, text, long = TRUE)
#' @export
emoji_emotion <- function(data, text, lexicon = "emotag1200", long = FALSE) {
  lex <- .emoji_lexicon_lookup(lexicon)
  if (!identical(lex$type, "emotion") && !is.data.frame(lex)) {
    stop("`emoji_emotion()` requires an emotion lexicon (use 'emotag1200').",
         call. = FALSE)
  }
  emap <- if (is.data.frame(lex)) {
    # custom registered emotion lexicon: rebuild a key-indexed matrix
    mat <- as.matrix(lex[, intersect(emoji_emotion_dims(), names(lex))])
    rownames(mat) <- emoji_key(lex[["emoji"]])
    mat
  } else {
    emoji_emotion_map()
  }
  dims <- colnames(emap)

  lst <- emoji_glyph_list(dplyr::pull(data, {{ text }}))
  all_glyphs <- unique(unlist(lst, use.names = FALSE))
  key_lookup <- stats::setNames(emoji_key(all_glyphs), all_glyphs)

    # Per-row mean over each emotion, over the emoji found in the lexicon.
  valid_keys <- rownames(emap)
  row_means <- vapply(lst, function(g) {
    if (!length(g)) return(rep(NA_real_, length(dims)))
    keys <- key_lookup[g]
    keys <- keys[!is.na(keys) & keys %in% valid_keys]
    if (!length(keys)) return(rep(NA_real_, length(dims)))
    sub <- emap[keys, , drop = FALSE]
    colMeans(sub, na.rm = TRUE)
  }, numeric(length(dims)))
  row_means <- t(row_means)
  colnames(row_means) <- dims

  n_total <- as.integer(lengths(lst))
  n_scored <- vapply(lst, function(g) {
    if (!length(g)) return(NA_integer_)
    keys <- key_lookup[g]
    sum(keys %in% rownames(emap))
  }, integer(1))

  out <- tibble::as_tibble(data)
  if (isTRUE(long)) {
    # Long form: one row per (original row, emotion), with the original columns
    # repeated and .emoji_emotion / .emoji_score added.
    long_df <- tibble::tibble(
      .row_number    = rep(seq_len(nrow(out)), each = length(dims)),
      .emoji_emotion = rep(dims, nrow(out)),
      .emoji_score   = as.numeric(t(row_means))
    )
    out <- out %>%
      dplyr::mutate(.row_number = dplyr::row_number()) %>%
      dplyr::left_join(long_df, by = ".row_number") %>%
      dplyr::select(-.row_number) %>%
      dplyr::relocate(.emoji_emotion, .emoji_score, .after = dplyr::last_col())
  } else {
    for (em in dims) {
      out[[paste0(".emoji_", em)]] <- row_means[, em]
    }
    out$.emoji_n <- n_total
    out$.emoji_n_scored <- n_scored
  }
  out
}


#' The dominant emoji emotion per row
#'
#' `emoji_emotion_label()` adds `.emoji_emotion`, the emotion with the highest
#' mean score among the row's emoji (using [emoji_emotion()]). Ties are broken
#' in Plutchik order; rows with no scored emoji receive `NA`.
#'
#' @inheritParams emoji_summary
#' @param lexicon Passed to [emoji_emotion()].
#' @return `data`, as a tibble, with a `.emoji_emotion` column added.
#' @examples
#' df <- data.frame(text = c("love it \U0001f60d", "scary \U0001f628", "meh"))
#' emoji_emotion_label(df, text)
#' @export
emoji_emotion_label <- function(data, text, lexicon = "emotag1200") {
  em <- emoji_emotion(data, {{ text }}, lexicon = lexicon, long = FALSE)
  dims <- emoji_emotion_dims()
  cols <- paste0(".emoji_", dims)
  mat <- as.matrix(em[, cols])
  # break ties in Plutchik order (first max wins via ties.method="first")
  idx <- max.col(mat, ties.method = "first")
  has_score <- rowSums(!is.na(mat)) > 0
  label <- dims[idx]
  label[!has_score] <- NA_character_
  em$.emoji_emotion <- label
  # drop the per-emotion columns, keep the label + counts
  em <- em[, setdiff(names(em), cols), drop = FALSE]
  em
}
