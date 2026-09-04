#' Emoji emotion profiles (the 8 Plutchik emotions)
#'
#' `emoji_emotion()` scores each row's emoji across the eight Plutchik emotions
#' (anger, anticipation, disgust, fear, joy, sadness, surprise, trust) using the
#' bundled EmoTag1200 lexicon (Shoeb & de Melo, 2020). Scores each range from 0 to
#' 1 and are averaged over the emoji in the row that appear in the lexicon.
#'
#' **The lexicon is 150 glyphs, about 4% of the distinct emoji tidyEmoji can
#' detect**, so a row of post-2018 emoji will score `NA` and still be a row
#' full of emoji. Read `.emoji_n_scored` alongside `.emoji_n` before concluding
#' a corpus carries no emotion; see [emoji_emotion_lexicon] for the figure and
#' its denominator.
#'
#' @inheritParams emoji_summary
#' @param lexicon Lexicon to use. Either a string naming a bundled lexicon
#'   (`"emotag1200"`, the default), the name of a registered lexicon (see
#'   [register_emoji_lexicon()]), or a data frame. A custom lexicon must have an
#'   `emoji` column and one column per emotion (any subset of the eight Plutchik
#'   emotions); it is joined through the same codepoint-normalised key as the
#'   bundled one.
#' @param long If `TRUE`, return one row per (row, emotion) in long form with
#'   columns `.emoji_emotion` (the emotion name) and `.emoji_score` (its mean).
#'   Default `FALSE` adds eight `.emoji_<emotion>` columns plus `.emoji_n` and
#'   `.emoji_n_scored`.
#' @return `data`, as a tibble. With `long = FALSE` (the default), eight
#'   emotion columns -- `.emoji_anger`, `.emoji_anticipation`,
#'   `.emoji_disgust`, `.emoji_fear`, `.emoji_joy`, `.emoji_sadness`,
#'   `.emoji_surprise`, `.emoji_trust` -- plus `.emoji_n` and
#'   `.emoji_n_scored`, one row per input row. With `long = TRUE`, one row per
#'   input row *per emotion*, carrying `.emoji_emotion` and `.emoji_score`
#'   instead of the eight columns. Rows without emoji, or whose emoji are
#'   absent from the lexicon, receive `NA` scores.
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
  .emoji_check_flag(long, "long")
  lex <- .emoji_lexicon_lookup(lexicon)
  if (is.list(lex) && !is.data.frame(lex) && identical(lex$type, "custom")) {
    lex <- lex$tbl
  }
  if (is.data.frame(lex)) {
    # custom emotion lexicon (a data frame or a registered one): rebuild a
    # key-indexed matrix over whichever emotion columns it supplies
    dims_avail <- intersect(emoji_emotion_dims(), names(lex))
    if (!length(dims_avail) || !any(c("emoji", "key") %in% names(lex))) {
      stop(paste0(
        "A custom emotion lexicon needs an `emoji` column and at least one ",
        "emotion column (anger, anticipation, disgust, fear, joy, sadness, ",
        "surprise, trust)."
      ), call. = FALSE)
    }
    emap <- as.matrix(lex[, dims_avail, drop = FALSE])
    rownames(emap) <- .emoji_lexicon_keys(lex)
  } else if (identical(lex$type, "emotion")) {
    emap <- emoji_emotion_map()
  } else {
    stop(paste0(
      "`emoji_emotion()` requires an emotion lexicon: 'emotag1200', a ",
      "registered emotion lexicon, or a data frame with emotion columns."
    ), call. = FALSE)
  }
  dims <- colnames(emap)

  lst <- emoji_glyph_list(.emoji_text_col(data, {{ text }}))
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
  # vapply returns a plain vector when there is a single emotion column
  row_means <- if (length(dims) == 1L) matrix(row_means, ncol = 1L) else t(row_means)
  colnames(row_means) <- dims

  n_total <- as.integer(lengths(lst))
  n_scored <- vapply(lst, function(g) {
    if (!length(g)) return(NA_integer_)
    keys <- key_lookup[g]
    sum(keys %in% rownames(emap))
  }, integer(1))

  out <- .emoji_as_tibble(data)
  if (isTRUE(long)) {
    # Long form: one row per (original row, emotion), with the original columns
    # repeated and .emoji_emotion / .emoji_score added. Repeat by index rather
    # than joining on a helper column, so a user column called `.row_number`
    # survives untouched.
    n_row <- nrow(out)
    out <- out[rep(seq_len(n_row), each = length(dims)), , drop = FALSE]
    out$.emoji_emotion <- rep(dims, times = n_row)
    out$.emoji_score <- as.numeric(t(row_means))
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
#' @details
#' Ties are broken in Plutchik order -- the order the eight emotions are listed
#' in throughout the package (anger, anticipation, disgust, fear, joy, sadness,
#' surprise, trust) -- so the winner is deterministic and does not depend on
#' the row's position in the data. Read `.emoji_n_scored` alongside the label:
#' a tie, or a near-tie, is invisible in a single winning name, and
#' [emoji_emotion()] gives the full profile the label collapses.
#'
#' @return `data`, as a tibble, with `.emoji_emotion` (the winning emotion, or
#'   `NA` when nothing was scorable) added, alongside the `.emoji_n` and
#'   `.emoji_n_scored` counts it inherits from [emoji_emotion()].
#' @examples
#' df <- data.frame(text = c("love it \U0001f60d", "scary \U0001f628", "meh"))
#' emoji_emotion_label(df, text)
#' @export
emoji_emotion_label <- function(data, text, lexicon = "emotag1200") {
  em <- emoji_emotion(data, {{ text }}, lexicon = lexicon, long = FALSE)
  # a custom lexicon may supply only a subset of the eight emotions
  cols <- intersect(paste0(".emoji_", emoji_emotion_dims()), names(em))
  dims <- sub("^\\.emoji_", "", cols)
  mat <- as.matrix(em[, cols, drop = FALSE])
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
