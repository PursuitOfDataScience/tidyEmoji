# Coverage: what a lexicon could not score, as a number a methods section can
# quote.
#
# Every scoring verb reports `.emoji_n_scored` per row, which is the right
# distinction (0 when the row's emoji could not be scored, NA when it had
# none), but nothing reported the corpus-level figure. On the bundled
# example corpus the sentiment lexicon scores 75.0% of the emoji occurrences
# and leaves 135 of the 750 emoji-bearing rows with no score at all, so a
# user who filters `!is.na(.emoji_sentiment)` before a group comparison drops
# a sixth of their emoji-bearing rows, and not at random, since the unscored
# ones are the tail, where the domain-specific glyphs live.

# The code-point keys a lexicon can score: keys with at least one usable value
# in the columns the lexicon is scored on.
.emoji_lexicon_scorable_keys <- function(name) {
  rec <- .emoji_lexicon_lookup(name)
  if (identical(rec$type, "sentiment")) {
    m <- emoji_sentiment_map()
    return(unique(names(m)[!is.na(m)]))
  }
  if (identical(rec$type, "emotion")) {
    m <- emoji_emotion_map()
    return(unique(rownames(m)[rowSums(!is.na(m)) > 0L]))
  }
  tbl <- rec$tbl
  # The columns the scoring verbs read by default: the score emoji_score()
  # and emoji_sentiment() take (`sentiment_score`, else `score`) and the
  # emotion columns emoji_emotion() takes. Any numeric column used to count,
  # so a rater count made an emoji "scorable" that emoji_score() then left
  # unscored, and the two verbs disagreed about the same lexicon.
  dims <- c(intersect(c("sentiment_score", "score"), names(tbl))[1L],
            intersect(emoji_emotion_dims(), names(tbl)))
  dims <- dims[!is.na(dims)]
  dims <- dims[vapply(tbl[dims], function(v) is.numeric(v) || is.logical(v),
                      logical(1))]
  keys <- as.character(tbl$key)
  if (!length(dims)) return(character(0))
  ok <- Reduce(`|`, lapply(tbl[dims], function(v) !is.na(v) & is.finite(v)))
  unique(keys[ok & !is.na(keys) & nzchar(keys)])
}


#' How much of a corpus can each lexicon score?
#'
#' `emoji_coverage()` reports, for each lexicon, how many of the emoji in a
#' text column it can score: as a share of the emoji *occurrences*, as a share
#' of the distinct emoji *types*, and as the number of emoji-bearing rows it
#' leaves without any score at all. It is the figure to report beside any
#' lexicon-based emoji result, because a lexicon that scores the common emoji
#' and none of the rare ones can look complete on one of those measures and
#' patchy on the other.
#'
#' @details
#' **Report two numbers, never one.** Emoji use is heavily skewed: a few
#' glyphs make up most occurrences, and a long tail of glyphs turns up once or
#' twice each. So a lexicon built from the common glyphs covers most
#' *occurrences* and few *types*, and the two figures answer different
#' questions:
#'
#' * `occurrence_coverage`: what share of the emoji a reader of this corpus
#'   saw can be scored. This is the flattering one.
#' * `type_coverage`: what share of the emoji vocabulary of this corpus can
#'   be scored. This is the one that says whether the rare, domain-specific
#'   glyphs are measured at all.
#'
#' On the example corpus, [oasst_messages], the two differ by fourteen points
#' for the bundled sentiment lexicon, 75.0% of occurrences against 61.3% of
#' types, and the third number is the one with consequences: 135 of the 750
#' rows that hold an emoji have none the lexicon can score, so their
#' `.emoji_sentiment` is `NA`. Dropping those rows before a comparison drops
#' a sixth of the data, and not at random.
#'
#' `lexicon_size` and `catalogue_share` describe the lexicon rather than the
#' corpus: how many distinct emoji it scores, and what share of the emoji in
#' the catalogue those are. Skin-tone and hair components are not emoji
#' occurrences (see the *Detection* section of [tidyEmoji]) and are left out
#' of the catalogue's count.
#'
#' A registered lexicon can score an emoji when it holds a value for it in a
#' column the scoring verbs read by default: the score [emoji_score()] and
#' [emoji_sentiment()] take (`sentiment_score`, else `score`), or an emotion
#' column [emoji_emotion()] takes. Its other numeric columns, such as a count
#' of raters, do not count. A score chosen with `score =` can cover a
#' different set.
#'
#' @section What `presentation` costs:
#' The default detection requires emoji presentation, so a bare `U+2764`
#' heart is not counted, nor, since 0.7.0, a glyph the writer followed with
#' `U+FE0E` to ask for its text form. `n_text_presentation` is how many such
#' text-presentation glyphs the corpus holds (the occurrences
#' `presentation = "any"` would add), and `n_text_presentation_scorable` is
#' how many of those this lexicon could score. Under the default they are
#' outside every other count here; under `presentation = "any"` they are
#' inside `n_occurrences`. Either way the two columns describe the same
#' glyphs, so the effect of the choice can be read straight off the table.
#'
#' @inheritParams emoji_summary
#' @param lexicon `NULL` (the default) for every lexicon: the two bundled ones
#'   and any registered with [register_emoji_lexicon()]. Otherwise a character
#'   vector of lexicon names; see [emoji_lexicons()]. To measure a data frame
#'   you have not registered, register it first.
#' @return A tibble with one row per lexicon and columns `lexicon`,
#'   `n_occurrences` (emoji in the corpus), `n_scorable` (those the lexicon can
#'   score), `occurrence_coverage` (`n_scorable / n_occurrences`), `n_types`
#'   (distinct emoji in the corpus), `n_types_scorable`, `type_coverage`,
#'   `n_rows_with_emoji`, `n_rows_unscored` (rows holding emoji none of which
#'   the lexicon can score), `lexicon_size` (distinct emoji the lexicon
#'   scores), `catalogue_share` (`lexicon_size` as a share of the
#'   catalogue's emoji), `n_text_presentation` and
#'   `n_text_presentation_scorable` (see the section above). The two
#'   coverages are `NA` for a corpus with no emoji. Types are counted by
#'   code-point key, so two spellings of one emoji are one type.
#' @seealso [emoji_sentiment()], [emoji_emotion()] and [emoji_score()], whose
#'   `.emoji_n_scored` is the per-row version; [emoji_lexicons()].
#' @examples
#' df <- data.frame(text = c("love it \U0001f60d", "new \U0001fae0 here",
#'                           "no emoji", "bare \u2764 heart"))
#' emoji_coverage(df, text)
#' emoji_coverage(df, text, presentation = "any")
#' @concept coverage
#' @concept sentiment
#' @export
emoji_coverage <- function(data, text, lexicon = NULL,
                           presentation = "emoji") {
  presentation <- .emoji_check_presentation(presentation)
  .emoji_warn_grouped(data, "emoji_coverage", "0.6.0")
  if (is.null(lexicon)) {
    lexicon <- emoji_lexicons()$name
  } else if (!is.character(lexicon) || !length(lexicon) || anyNA(lexicon)) {
    stop(paste0("`lexicon` must be NULL or a character vector of lexicon ",
                "names. Register a data frame with register_emoji_lexicon() ",
                "to measure it."), call. = FALSE)
  }
  lexicon <- unique(lexicon)
  v <- .emoji_text_col(data, {{ text }})
  sp <- .emoji_spans(v, "any")
  w <- v
  w[is.na(w)] <- ""
  keys <- vector("list", length(v))
  text_keys <- vector("list", length(v))
  for (i in seq_along(v)) {
    m <- sp$locs[[i]]
    if (!nrow(m)) {
      keys[[i]] <- character(0)
      text_keys[[i]] <- character(0)
      next
    }
    # an unrecommended ZWJ sequence counts as its parts, as everywhere else
    cnt <- .emoji_counted(sp, i)
    m <- cnt$m
    kind <- cnt$k
    k <- emoji_key(.emoji_slice(m, w[[i]]))
    counted <- if (presentation == "any") kind <= 2L else kind == 1L
    keys[[i]] <- k[counted]
    text_keys[[i]] <- k[kind == 2L]
  }
  all_keys <- unlist(keys, use.names = FALSE)
  types <- unique(all_keys)
  txt <- unlist(text_keys, use.names = FALSE)
  with_emoji <- lengths(keys) > 0L
  ref <- emoji_reference()
  catalogue <- unique(ref$key[ref$status != "component"])

  rows <- lapply(lexicon, function(nm) {
    ok <- .emoji_lexicon_scorable_keys(nm)
    hit <- all_keys %in% ok
    t_hit <- types %in% ok
    unscored <- with_emoji & !vapply(keys, function(k) any(k %in% ok),
                                     logical(1))
    size <- length(ok)
    tibble::tibble(
      lexicon = nm,
      n_occurrences = length(all_keys),
      n_scorable = sum(hit),
      occurrence_coverage = if (length(all_keys)) mean(hit) else NA_real_,
      n_types = length(types),
      n_types_scorable = sum(t_hit),
      type_coverage = if (length(types)) mean(t_hit) else NA_real_,
      n_rows_with_emoji = sum(with_emoji),
      n_rows_unscored = sum(unscored),
      lexicon_size = size,
      catalogue_share = sum(catalogue %in% ok) / length(catalogue),
      n_text_presentation = length(txt),
      n_text_presentation_scorable = sum(txt %in% ok)
    )
  })
  out <- dplyr::bind_rows(rows)
  int_cols <- c("n_occurrences", "n_scorable", "n_types", "n_types_scorable",
                "n_rows_with_emoji", "n_rows_unscored", "lexicon_size",
                "n_text_presentation", "n_text_presentation_scorable")
  for (cl in int_cols) out[[cl]] <- as.integer(out[[cl]])
  out
}
