# Text-emoji mismatch.
#
# Two literatures want the same number. Sarcasm detection uses emoji-text
# sentiment incongruity as a feature; marketing research finds that text-emoji
# mismatch lowers perceived review helpfulness. Neither can get it in R without
# hand-rolling, and both need the *text* score to come from somewhere else --
# tidyEmoji deliberately does not score text.

# Percentile rank on [-1, 1], NA-preserving.
.emoji_rank_scale <- function(x) {
  ok <- !is.na(x)
  out <- rep(NA_real_, length(x))
  if (sum(ok) <= 1L) {
    out[ok] <- 0
    return(out)
  }
  r <- rank(x[ok], ties.method = "average")
  out[ok] <- 2 * (r - 1) / (sum(ok) - 1) - 1
  out
}

.emoji_zscore <- function(x) {
  s <- stats::sd(x, na.rm = TRUE)
  if (is.na(s) || s == 0) return(x - mean(x, na.rm = TRUE))
  (x - mean(x, na.rm = TRUE)) / s
}

.emoji_apply_scale <- function(x, scale) {
  switch(scale,
         none = x,
         rank = .emoji_rank_scale(x),
         zscore = .emoji_zscore(x))
}

# The trailing run of emoji: the glyphs that end the text, ignoring whitespace
# between and after them. A text that does not end in an emoji contributes no
# final glyphs, so it is scored as NA rather than as its mid-sentence emoji.
.emoji_final_glyphs <- function(v) {
  locs <- .emoji_locations(v)
  lapply(seq_along(v), function(i) {
    m <- locs[[i]]
    if (is.null(m) || nrow(m) == 0L) return(character(0))
    s <- v[[i]]
    # nothing but whitespace may follow the last emoji
    if (nzchar(gsub("[[:space:]]", "",
                    substr(s, m[nrow(m), "end"] + 1L, nchar(s))))) {
      return(character(0))
    }
    # walk back over the trailing run of emoji separated only by whitespace
    k <- nrow(m)
    while (k > 1L) {
      between <- substr(s, m[k - 1L, "end"] + 1L, m[k, "start"] - 1L)
      if (nzchar(gsub("[[:space:]]", "", between))) break
      k <- k - 1L
    }
    .emoji_slice(m[seq(k, nrow(m)), , drop = FALSE], s)
  })
}

.emoji_incongruity_impl <- function(data, text, text_score, method, scale,
                                    where, threshold) {
  method <- match.arg(method, c("difference", "sign_flip"))
  scale <- match.arg(scale, c("none", "rank", "zscore"))
  where <- match.arg(where, c("all", "final"))
  if (!is.numeric(threshold) || length(threshold) != 1L || is.na(threshold)) {
    stop("`threshold` must be a single number.", call. = FALSE)
  }

  v <- as.character(dplyr::pull(data, {{ text }}))
  v[is.na(v)] <- ""
  ts <- dplyr::pull(data, {{ text_score }})
  if (!is.numeric(ts)) {
    stop("`text_score` must be a numeric column of text sentiment scores. ",
         "tidyEmoji does not score text: produce it with tidytext, ",
         "sentimentr, vader or a model of your choice.", call. = FALSE)
  }

  score <- emoji_sentiment_map()
  lst <- emoji_glyph_list(v)
  all_glyphs <- unique(unlist(lst, use.names = FALSE))
  key_lookup <- stats::setNames(emoji_key(all_glyphs), all_glyphs)

  # the glyphs actually scored: everything, or only the trailing run. Both the
  # mean and the count come from the same list, so they can never disagree.
  use <- if (where == "final") .emoji_final_glyphs(v) else lst
  es <- vapply(use, function(g) {
    if (!length(g)) return(NA_real_)
    s <- score[key_lookup[g]]
    if (all(is.na(s))) NA_real_ else mean(s, na.rm = TRUE)
  }, numeric(1))
  n_scored <- vapply(use, function(g) {
    if (!length(g)) return(NA_integer_)
    sum(!is.na(score[key_lookup[g]]))
  }, integer(1))

  es_s <- .emoji_apply_scale(es, scale)
  ts_s <- .emoji_apply_scale(ts, scale)
  gap <- es_s - ts_s
  flip <- !is.na(es) & !is.na(ts) & sign(es) != 0 & sign(ts) != 0 &
    sign(es) != sign(ts)
  flip[is.na(es) | is.na(ts)] <- NA

  out <- tibble::as_tibble(data)
  out$.emoji_n <- as.integer(lengths(lst))
  out$.emoji_n_scored <- n_scored
  out$.emoji_sentiment <- es
  out$.emoji_incongruity <- gap
  out$.emoji_polarity_flip <- flip
  out$.emoji_incongruent <- if (method == "sign_flip") {
    flip
  } else {
    ifelse(is.na(gap), NA, abs(gap) >= threshold)
  }
  out
}


#' Text-emoji sentiment mismatch
#'
#' `emoji_incongruity()` measures the signed gap between the sentiment a row's
#' emoji carry and the sentiment of its text. It is the sarcasm-detection
#' feature the NLP literature keeps rediscovering, and the mismatch variable
#' the marketing literature calls (in)congruence.
#'
#' @section You supply the text score:
#' tidyEmoji deliberately does not score text. `text_score` is a column you
#' produce with \pkg{tidytext} and AFINN or Bing, \pkg{sentimentr},
#' \pkg{vader}, or a transformer -- which keeps the method choice visible in
#' your script instead of buried in this package, and keeps our dependency
#' footprint where it is.
#'
#' Because those methods live on wildly different scales (AFINN runs -5 to 5,
#' VADER -1 to 1, a model's logits on nothing in particular), `scale` has no
#' default: you have to say how the two sides were made comparable.
#' `"rank"` maps both to percentiles on `[-1, 1]` and is the safest choice for
#' cross-method comparison; `"zscore"` standardises both; `"none"` compares the
#' raw numbers, which is only meaningful if your text score already lives on
#' the emoji lexicon's -1 to 1 scale.
#'
#' @details
#' `.emoji_incongruity` is `emoji - text` after scaling, so it is positive when
#' the emoji is the more positive of the two. `"sign_flip"` is the categorical
#' version most sarcasm papers use and is computed on the *unscaled* scores,
#' where the sign means something.
#'
#' A row with no scorable emoji gets `NA`, never `0`: a neutral emoji and no
#' emoji at all are different states, and collapsing them silently biases every
#' downstream model. The same applies to a missing `text_score`.
#'
#' With `where = "final"` only the run of emoji that ends the text is scored:
#' both the illocutionary-force account of emoji and the P600 evidence on
#' ironic emoji are specifically about sentence-final glyphs. A text whose
#' emoji sit mid-sentence then has nothing eligible to score, so it gets `NA`
#' and `.emoji_n_scored = NA`, while `.emoji_n` still counts every emoji in the
#' row.
#'
#' @inheritParams emoji_summary
#' @param text_score Unquoted numeric column holding the text's own sentiment.
#' @param method `"difference"` (default) for the continuous gap, or
#'   `"sign_flip"` for the categorical polarity-flip feature.
#' @param scale How to make the two scores comparable: `"rank"`, `"zscore"` or
#'   `"none"`. Required -- there is no sensible default.
#' @param where `"all"` (default) scores every emoji in the row; `"final"`
#'   scores only the trailing run of emoji that ends the text.
#' @param threshold For `method = "difference"`, the absolute gap at or above
#'   which `.emoji_incongruent` is `TRUE`. Default `1`, a full polarity swing on
#'   the rank scale.
#' @return `data`, as a tibble, with added columns `.emoji_n`,
#'   `.emoji_n_scored`, `.emoji_sentiment`, `.emoji_incongruity`,
#'   `.emoji_polarity_flip` and `.emoji_incongruent`.
#' @references An emoji centric approach to sarcasm detection in online
#'   discourse. *Scientific Reports* (2025). The influence of emoji meaning
#'   multipleness on perceived online review helpfulness. *Journal of Business
#'   Research* (2022).
#' @seealso [emoji_congruence()] for the same engine under the marketing
#'   framing; [emoji_incongruity_profile()] for which glyphs go against the
#'   grain; [emoji_sentiment()] for the emoji side on its own.
#' @examples
#' df <- data.frame(
#'   text = c("this is wonderful \U0001f621", "awful \U0001f621", "great \U0001f600"),
#'   score = c(0.9, -0.8, 0.7)
#' )
#' emoji_incongruity(df, text, score, scale = "none")
#' emoji_incongruity(df, text, score, scale = "none", method = "sign_flip")
#' @export
emoji_incongruity <- function(data, text, text_score,
                              method = c("difference", "sign_flip"),
                              scale, where = c("all", "final"),
                              threshold = 1) {
  if (missing(scale)) {
    stop("`scale` has no default: say how the text score and the emoji score ",
         "were made comparable. Use \"rank\" (both to percentiles, the safest ",
         "cross-method choice), \"zscore\", or \"none\" if your text score is ",
         "already on the -1 to 1 emoji scale.", call. = FALSE)
  }
  .emoji_incongruity_impl(data, {{ text }}, {{ text_score }}, method = method,
                          scale = scale, where = where, threshold = threshold)
}


#' Text-emoji congruence
#'
#' `emoji_congruence()` is [emoji_incongruity()] under the framing used in the
#' marketing and eWOM literature, where the finding is that a *mismatch*
#' between a review's words and its emoji lowers perceived helpfulness and
#' authenticity. Same engine, same columns, plus `.emoji_congruent`.
#'
#' @inheritParams emoji_incongruity
#' @return `data`, as a tibble, with everything [emoji_incongruity()] adds plus
#'   `.emoji_congruent`, the negation of `.emoji_incongruent`.
#' @seealso [emoji_incongruity()].
#' @examples
#' df <- data.frame(
#'   text = c("lovely stay \U0001f600", "terrible room \U0001f600"),
#'   score = c(0.8, -0.9)
#' )
#' emoji_congruence(df, text, score, scale = "none")
#' @export
emoji_congruence <- function(data, text, text_score,
                             method = c("difference", "sign_flip"),
                             scale, where = c("all", "final"),
                             threshold = 1) {
  if (missing(scale)) {
    stop("`scale` has no default: say how the text score and the emoji score ",
         "were made comparable. Use \"rank\" (both to percentiles, the safest ",
         "cross-method choice), \"zscore\", or \"none\" if your text score is ",
         "already on the -1 to 1 emoji scale.", call. = FALSE)
  }
  out <- .emoji_incongruity_impl(data, {{ text }}, {{ text_score }},
                                 method = method, scale = scale, where = where,
                                 threshold = threshold)
  out$.emoji_congruent <- !out$.emoji_incongruent
  out
}


#' Which emoji go against the grain of their text?
#'
#' `emoji_incongruity_profile()` aggregates [emoji_incongruity()] by glyph: for
#' each emoji, how far from its host text's sentiment it typically sits, and how
#' often it appears with the opposite polarity. Those are the candidate irony
#' markers in your corpus.
#'
#' @details
#' Incongruity is a property of a row, so every emoji in a row is credited with
#' that row's gap. A glyph that habitually shares a message with a genuinely
#' incongruent one will therefore inherit some of its score; read `n` alongside
#' `flip_rate` before drawing conclusions from a handful of occurrences.
#'
#' @inheritParams emoji_incongruity
#' @param min_n Minimum number of scored occurrences for an emoji to be
#'   reported. Default `5`.
#' @return A tibble with one row per emoji: `emoji`, `name`, `n` (scored
#'   occurrences), `mean_incongruity`, `sd_incongruity`, `n_flips` and
#'   `flip_rate`, sorted by descending `flip_rate`.
#' @seealso [emoji_incongruity()].
#' @examples
#' df <- data.frame(
#'   text = c("great \U0001f621", "lovely \U0001f621", "awful \U0001f621"),
#'   score = c(0.8, 0.7, -0.9)
#' )
#' emoji_incongruity_profile(df, text, score, scale = "none", min_n = 1)
#' @export
emoji_incongruity_profile <- function(data, text, text_score,
                                      method = c("difference", "sign_flip"),
                                      scale, where = c("all", "final"),
                                      threshold = 1, min_n = 5) {
  if (missing(scale)) {
    stop("`scale` has no default: say how the text score and the emoji score ",
         "were made comparable. Use \"rank\" (both to percentiles, the safest ",
         "cross-method choice), \"zscore\", or \"none\" if your text score is ",
         "already on the -1 to 1 emoji scale.", call. = FALSE)
  }
  if (!is.numeric(min_n) || length(min_n) != 1L || is.na(min_n) || min_n < 0) {
    stop("`min_n` must be a single non-negative number.", call. = FALSE)
  }
  scored <- .emoji_incongruity_impl(data, {{ text }}, {{ text_score }},
                                    method = method, scale = scale,
                                    where = where, threshold = threshold)
  lst <- lapply(emoji_glyph_list(dplyr::pull(data, {{ text }})),
                emoji_canonical)
  n_per_row <- lengths(lst)
  glyphs <- unlist(lst, use.names = FALSE)
  gap <- rep(scored$.emoji_incongruity, n_per_row)
  flip <- rep(scored$.emoji_polarity_flip, n_per_row)
  keep <- !is.na(gap)
  glyphs <- glyphs[keep]
  gap <- gap[keep]
  flip <- flip[keep]
  if (!length(glyphs)) {
    return(tibble::tibble(emoji = character(), name = character(),
                          n = integer(), mean_incongruity = numeric(),
                          sd_incongruity = numeric(), n_flips = integer(),
                          flip_rate = numeric()))
  }
  gsplit <- split(seq_along(glyphs), glyphs)
  g <- names(gsplit)
  ref <- emoji_reference()
  n <- vapply(gsplit, length, integer(1), USE.NAMES = FALSE)
  out <- tibble::tibble(
    emoji = g,
    name = ref$name[match(emoji_key(g), ref$key)],
    n = n,
    mean_incongruity = vapply(gsplit, function(i) mean(gap[i]), numeric(1),
                              USE.NAMES = FALSE),
    sd_incongruity = vapply(gsplit,
                            function(i) if (length(i) < 2L) NA_real_ else
                              stats::sd(gap[i]),
                            numeric(1), USE.NAMES = FALSE),
    n_flips = vapply(gsplit, function(i) sum(flip[i], na.rm = TRUE),
                     integer(1), USE.NAMES = FALSE)
  )
  out$flip_rate <- out$n_flips / out$n
  out <- out[out$n >= min_n, , drop = FALSE]
  dplyr::arrange(out, dplyr::desc(flip_rate), dplyr::desc(n), emoji)
}
