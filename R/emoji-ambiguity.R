# Interpretation risk: how much do people disagree about what an emoji means?
#
# Miller et al. (2016) found that readers of the *same* rendering disagreed on
# whether an emoji was positive, neutral or negative about a quarter of the
# time. The Emoji Sentiment Ranking already bundled with tidyEmoji keeps the
# raw annotation counts behind its collapsed `sentiment_score`, so that
# disagreement is an empirical distribution sitting inside the package. These
# verbs read it out.

# Per-glyph annotation distribution and its ambiguity statistics, keyed by
# emoji_key(). Cached for the session.
emoji_ambiguity_table <- function() {
  if (is.null(.tidyEmoji_cache$ambiguity)) {
    lex <- emoji_sentiment_lexicon
    neg <- as.numeric(lex$negative)
    neu <- as.numeric(lex$neutral)
    pos <- as.numeric(lex$positive)
    n <- neg + neu + pos
    ok <- !is.na(n) & n > 0
    p_neg <- ifelse(ok, neg / n, NA_real_)
    p_neu <- ifelse(ok, neu / n, NA_real_)
    p_pos <- ifelse(ok, pos / n, NA_real_)
    p <- cbind(p_neg, p_neu, p_pos)
    # Shannon entropy over the three annotation classes, in nats: 0 when the
    # annotators were unanimous, log(3) when they split three ways evenly.
    # 0 * log(0) is taken as 0, its limit.
    ent <- -rowSums(ifelse(is.na(p) | p <= 0, 0, p * log(p)))
    ent[!ok] <- NA_real_
    gini <- 1 - rowSums(p^2)
    # score = (positive - negative) / n, and its binomial-style standard error
    # from the same counts: Var(X) = E[X^2] - E[X]^2 with X in {-1, 0, 1}.
    score <- p_pos - p_neg
    v <- p_pos + p_neg - score^2
    v[!is.na(v) & v < 0] <- 0
    se <- sqrt(v / n)
    tbl <- tibble::tibble(
      emoji = lex$emoji,
      key = emoji_key(lex$emoji),
      n_annotations = as.integer(round(n)),
      p_neg = p_neg,
      p_neu = p_neu,
      p_pos = p_pos,
      entropy = ent,
      gini = gini,
      neutral_share = p_neu,
      ci_width = 2 * stats::qnorm(0.975) * se,
      se = se
    )
    tbl <- tbl[!is.na(tbl$key) & !duplicated(tbl$key), , drop = FALSE]
    .tidyEmoji_cache$ambiguity <- tbl
  }
  .tidyEmoji_cache$ambiguity
}

# Named vector mapping emoji_key() -> standard error of the glyph's sentiment
# score, for emoji_sentiment(se = TRUE).
emoji_sentiment_se_map <- function() {
  tbl <- emoji_ambiguity_table()
  stats::setNames(tbl$se, tbl$key)
}

# The ambiguity measures a user may ask for, in one place.
emoji_ambiguity_measures <- function() {
  c("entropy", "gini", "neutral_share", "ci_width")
}


#' How ambiguous is each emoji?
#'
#' `emoji_ambiguity()` reports, for every emoji in the Emoji Sentiment Ranking
#' (see [emoji_sentiment_lexicon]), how much its human annotators disagreed
#' about whether it was negative, neutral or positive. Miller et al. (2016)
#' found that readers of the same rendering disagree about a quarter of the
#' time; the bundled lexicon keeps the raw annotation counts behind its
#' collapsed score, so that disagreement can be reported as a number rather
#' than described as a caveat.
#'
#' @details
#' The four measures are computed from the annotation shares
#' `(p_neg, p_neu, p_pos)`:
#'
#' * `"entropy"` (the default) is Shannon entropy in nats: 0 when the
#'   annotators were unanimous, `log(3)` (about 1.0986) when they split evenly
#'   three ways.
#' * `"gini"` is the Gini impurity, `1 - sum(p^2)`: 0 when unanimous, 2/3 at
#'   maximum disagreement.
#' * `"neutral_share"` is `p_neu` on its own, for the "is this emoji simply
#'   uninformative?" question.
#' * `"ci_width"` is the width of a 95% Wald interval around the glyph's
#'   sentiment score. Unlike the other three it shrinks as the number of
#'   annotations grows, so it answers "how well do we know this score?" rather
#'   than "how much do readers disagree?".
#'
#' `rank` is always computed over the whole lexicon (1 = most ambiguous), so a
#' rank keeps its meaning when `x` selects a handful of glyphs.
#'
#' @param x Optional character vector of emoji glyphs to report on. The default,
#'   `NULL`, returns every emoji in the lexicon, most ambiguous first. Glyphs
#'   absent from the lexicon come back with `NA` statistics.
#' @param measure Which ambiguity statistic to put in the `ambiguity` column:
#'   one of `"entropy"` (default), `"gini"`, `"neutral_share"` or `"ci_width"`.
#' @return A tibble with columns `emoji`, `key` (the codepoint-normalised join
#'   key), `n_annotations`, `p_neg`, `p_neu`, `p_pos`, `ambiguity` and `rank`.
#'   With `x` supplied the result has one row per element of `x`, in the same
#'   order.
#' @references Miller H, Thebault-Spieker J, Chang S, Johnson I, Terveen L,
#'   Hecht B (2016). "Blissfully Happy" or "Ready to Fight": Varying
#'   Interpretations of Emoji. *ICWSM 2016*.
#' @seealso [emoji_risk()] for the per-row version, [emoji_flag_ambiguous()]
#'   for the emoji in your own corpus, and [emoji_sentiment()] with
#'   `se = TRUE` for the uncertainty around a score.
#' @examples
#' head(emoji_ambiguity())
#' emoji_ambiguity(c("\U0001f602", "\U0001f643"))
#' head(emoji_ambiguity(measure = "ci_width"))
#' @export
emoji_ambiguity <- function(x = NULL, measure = "entropy") {
  measure <- match.arg(measure, emoji_ambiguity_measures())
  tbl <- emoji_ambiguity_table()
  amb <- tbl[[measure]]
  out <- tibble::tibble(
    emoji = tbl$emoji,
    key = tbl$key,
    n_annotations = tbl$n_annotations,
    p_neg = tbl$p_neg,
    p_neu = tbl$p_neu,
    p_pos = tbl$p_pos,
    ambiguity = amb,
    rank = as.integer(rank(-amb, na.last = "keep", ties.method = "min"))
  )
  if (is.null(x)) {
    return(dplyr::arrange(out, rank, emoji))
  }
  # index columns rather than rows: an unknown glyph gives NA statistics
  # without relying on NA row subscripts
  x <- as.character(x)
  keys <- emoji_key(x)
  idx <- match(keys, out$key)
  tibble::tibble(
    emoji = x,
    key = keys,
    n_annotations = out$n_annotations[idx],
    p_neg = out$p_neg[idx],
    p_neu = out$p_neu[idx],
    p_pos = out$p_pos[idx],
    ambiguity = out$ambiguity[idx],
    rank = out$rank[idx]
  )
}


#' Interpretation risk per row
#'
#' `emoji_risk()` scores how likely each row's emoji are to be *misread*, using
#' the annotation-disagreement statistics of [emoji_ambiguity()]. It is the
#' content-QA counterpart of [emoji_sentiment()]: a row can carry a confident
#' positive score built entirely out of glyphs its annotators fought over.
#'
#' @details
#' `threshold` decides what counts as an ambiguous glyph for
#' `.emoji_n_ambiguous`. The default, `NULL`, uses the upper quartile of the
#' chosen measure across the whole lexicon, i.e. "in the most-disputed quarter
#' of all emoji". Supply your own number to make the cut-off explicit in your
#' script.
#'
#' Emoji absent from the lexicon cannot be scored and are excluded from the
#' means; `.emoji_n` and `.emoji_n_scored` together show how much of the row
#' was actually measured.
#'
#' @inheritParams emoji_summary
#' @param measure Ambiguity statistic to use; see [emoji_ambiguity()].
#' @param threshold Value at or above which a glyph counts as ambiguous.
#'   `NULL` (default) uses the lexicon's upper quartile of `measure`.
#' @return `data`, as a tibble, with added columns `.emoji_n`,
#'   `.emoji_n_scored`, `.emoji_ambiguity_mean`, `.emoji_ambiguity_max` and
#'   `.emoji_n_ambiguous`. Rows with no emoji get `NA` throughout. A row that
#'   has emoji the lexicon cannot score gets `.emoji_n_scored = 0`,
#'   `.emoji_n_ambiguous = 0` and `NA` for the two averages -- there is nothing
#'   to average, but the count of ambiguous glyphs found is genuinely zero.
#' @seealso [emoji_ambiguity()], [emoji_flag_ambiguous()].
#' @examples
#' df <- data.frame(text = c("thanks \U0001f643", "great \U0001f600", "plain"))
#' emoji_risk(df, text)
#' @export
emoji_risk <- function(data, text, measure = "entropy", threshold = NULL) {
  measure <- match.arg(measure, emoji_ambiguity_measures())
  tbl <- emoji_ambiguity_table()
  if (is.null(threshold)) {
    threshold <- unname(stats::quantile(tbl[[measure]], 0.75, na.rm = TRUE))
  } else if (!is.numeric(threshold) || length(threshold) != 1L ||
             is.na(threshold)) {
    stop("`threshold` must be a single number, or NULL for the lexicon's ",
         "upper quartile.", call. = FALSE)
  }
  amb_map <- stats::setNames(tbl[[measure]], tbl$key)

  lst <- emoji_glyph_list(.emoji_text_col(data, {{ text }}))
  all_glyphs <- unique(unlist(lst, use.names = FALSE))
  key_lookup <- stats::setNames(emoji_key(all_glyphs), all_glyphs)
  vals <- lapply(lst, function(g) {
    if (!length(g)) return(numeric(0))
    v <- unname(amb_map[key_lookup[g]])
    v[!is.na(v)]
  })
  has_emoji <- lengths(lst) > 0L

  out <- .emoji_as_tibble(data)
  out$.emoji_n <- as.integer(lengths(lst))
  # typed allocate-then-fill: ifelse() returned logical(0) for a zero-row input
  n_scored <- rep(NA_integer_, length(has_emoji))
  n_scored[has_emoji] <- as.integer(lengths(vals))[has_emoji]
  out$.emoji_n_scored <- n_scored
  out$.emoji_ambiguity_mean <- vapply(
    vals, function(v) if (!length(v)) NA_real_ else mean(v), numeric(1)
  )
  out$.emoji_ambiguity_max <- vapply(
    vals, function(v) if (!length(v)) NA_real_ else max(v), numeric(1)
  )
  # A *count* of ambiguous glyphs, so a row with emoji that the lexicon cannot
  # score has 0 of them, not an unknown number -- the same rule
  # `.emoji_n_scored` already follows two lines up, and what the @return
  # promises ("rows with no emoji get NA throughout"). Keying this off
  # length(vals) instead made the two counts disagree about the same row.
  n_amb <- rep(NA_integer_, length(has_emoji))
  n_amb[has_emoji] <- vapply(
    vals[has_emoji], function(v) sum(v >= threshold), integer(1)
  )
  out$.emoji_n_ambiguous <- n_amb
  out
}


#' Which emoji in this corpus are most likely to be misread?
#'
#' `emoji_flag_ambiguous()` crosses the emoji actually present in a text column
#' with their annotation-disagreement statistics and returns the most ambiguous
#' ones first. It is the content-QA shortlist: the glyphs worth a second look
#' before a campaign ships or a coding scheme is fixed.
#'
#' @inheritParams emoji_summary
#' @param top_n Number of emoji to return, most ambiguous first. `NULL` returns
#'   all of them.
#' @param measure Ambiguity statistic to rank by; see [emoji_ambiguity()].
#' @return A tibble with columns `emoji`, `name`, `n` (occurrences in the
#'   corpus), `n_annotations`, `ambiguity` and `rank` (the glyph's rank in the
#'   whole lexicon). Emoji absent from the lexicon cannot be ranked and are
#'   dropped.
#' @seealso [emoji_ambiguity()], [emoji_risk()].
#' @examples
#' df <- data.frame(text = c("ok \U0001f643", "yay \U0001f600 \U0001f643",
#'                           "hmm \U0001f612"))
#' emoji_flag_ambiguous(df, text, top_n = 3)
#' @export
emoji_flag_ambiguous <- function(data, text, top_n = 10,
                                 measure = "entropy") {
  measure <- match.arg(measure, emoji_ambiguity_measures())
  if (!is.null(top_n) && !.emoji_is_count(top_n, finite = FALSE)) {
    stop("`top_n` must be a single non-negative whole number, ",
         "or NULL for all.", call. = FALSE)
  }
  # as in emoji_cooccurrence(): warn under this verb's name, then ungroup so
  # the delegated emoji_frequency() does not warn about itself instead
  if (.emoji_warn_grouped(data, "emoji_flag_ambiguous", "0.4.0")) {
    data <- dplyr::ungroup(data)
  }
  freq <- emoji_frequency(data, {{ text }})
  amb <- emoji_ambiguity(measure = measure)
  idx <- match(emoji_key(freq$emoji), amb$key)
  out <- tibble::tibble(
    emoji = freq$emoji,
    name = freq$name,
    n = freq$n,
    n_annotations = amb$n_annotations[idx],
    ambiguity = amb$ambiguity[idx],
    rank = amb$rank[idx]
  )
  out <- out[!is.na(out$ambiguity), , drop = FALSE]
  out <- dplyr::arrange(out, dplyr::desc(ambiguity), dplyr::desc(n), emoji)
  if (!is.null(top_n) && is.finite(top_n)) {
    out <- utils::head(out, top_n)
  }
  out
}
