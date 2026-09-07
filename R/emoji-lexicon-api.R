#' List bundled emoji lexicons
#'
#' `emoji_lexicons()` returns a tibble describing the lexicons bundled with
#' tidyEmoji and any user-registered ones: their name, type (sentiment or
#' emotion), dimensions, number of emoji, source and licence.
#'
#' @return A tibble with columns `name`, `type`, `dimensions`, `n`, `source`,
#'   `licence`.
#' @seealso [register_emoji_lexicon()] to add your own;
#'   [emoji_score()] to score text against any lexicon.
#' @examples
#' emoji_lexicons()
#' @export
emoji_lexicons <- function() {
  dims <- emoji_emotion_dims()
  bundled <- tibble::tibble(
    name = c("novak2015", "emotag1200"),
    type = c("sentiment", "emotion"),
    dimensions = I(list("sentiment_score", dims)),
    n = c(nrow(emoji_sentiment_lexicon), nrow(emoji_emotion_lexicon)),
    source = c(
      "Kralj Novak et al. (2015), PLoS ONE 10(12): e0144296",
      "Shoeb & de Melo (2020), EMNLP 2020"
    ),
    licence = c("CC BY-SA 4.0", "MIT")
  )
  reg <- .tidyEmoji_cache$lexicons %||% list()
  if (length(reg)) {
    custom <- tibble::tibble(
      name = names(reg),
      type = "custom",
      # unname(): `reg` is a named list, so lapply()/vapply() over it return
      # named results and bind_rows() then pads the bundled rows with "".
      # `emoji_lexicons()$n` printed a stray name header as a result.
      dimensions = I(unname(lapply(reg, function(x) {
        # drop the glyph column (whatever it was called at registration), the
        # normalised key and any label column -- they are not score dimensions
        setdiff(names(x), c(attr(x, "tidyEmoji_by") %||% "emoji",
                            "emoji", "key", "name"))
      }))),
      n = unname(vapply(reg, nrow, integer(1))),
      source = "user-registered",
      licence = NA_character_
    )
    bundled <- dplyr::bind_rows(bundled, custom)
  }
  bundled
}


#' Register a custom emoji lexicon
#'
#' `register_emoji_lexicon()` adds a user-supplied lexicon to the in-session
#' registry so it can be referenced by name in [emoji_score()],
#' [emoji_sentiment()] or [emoji_emotion()]. The lexicon is normalised through
#' the package's codepoint key (`U+FE0F` stripped), so a lexicon keyed on
#' unqualified glyphs still matches qualified text.
#'
#' Registration lasts for the session; it is not written to disk.
#'
#' @param name Name to register the lexicon under.
#' @param tbl A data frame. Must contain a glyph column named `by` (default
#'   `"emoji"`) and at least one score column, and every score column present
#'   must be numeric or logical -- a text column is rejected here rather than
#'   returning `NA` for every score at first use. See [emoji_score()] for the
#'   one-row-per-emoji requirement, which is checked when the lexicon is used.
#' @param by Name of the column holding the emoji glyph, as a single string.
#'   Default `"emoji"`.
#' @return Invisibly, the registered lexicon (with an added `key` column).
#' @seealso [emoji_lexicons()] to list lexicons; [emoji_score()] to use one.
#' @examples
#' my_lex <- data.frame(
#'   emoji = c("\U0001f600", "\U0001f621"),
#'   score = c(0.9, -0.8)
#' )
#' register_emoji_lexicon("mine", my_lex)
#' emoji_lexicons()
#' emoji_score(data.frame(text = "great \U0001f600"), text, lexicon = "mine")
#' @export
register_emoji_lexicon <- function(name, tbl, by = "emoji") {
  if (!is.character(name) || length(name) != 1L || is.na(name) ||
      !nzchar(name)) {
    stop("`name` must be a single non-empty string.", call. = FALSE)
  }
  # A bundled name resolves to the bundled table before the registry is
  # consulted, so registering under one succeeded and then did nothing.
  if (name %in% .emoji_reserved_lexicons()) {
    stop(sprintf(
      paste0("`%s` is a name one of the bundled lexicons answers to, so a ",
             "lexicon registered under it could never be reached. Reserved: ",
             "%s. Pick another name."),
      name, paste(sprintf("`%s`", .emoji_reserved_lexicons()), collapse = ", ")
    ), call. = FALSE)
  }
  if (!is.data.frame(tbl)) stop("`tbl` must be a data frame.", call. = FALSE)
  # before the `%in%` below, for the same reason as in .emoji_lexicon_keys()
  .emoji_check_string(by, "by")
  if (!by %in% names(tbl)) {
    stop(sprintf("`tbl` has no column `%s`.", by), call. = FALSE)
  }
  # Resolve the score column now rather than at first use: a lexicon with no
  # usable score column registered happily and only failed later, from inside
  # emoji_score(), where the message named `tbl` -- an argument of the call
  # that had long since returned.
  if (!length(intersect(c("sentiment_score", "score", emoji_emotion_dims()),
                        names(tbl)))) {
    stop(sprintf(
      paste0("`tbl` has no score column. Supply one named `score` or ",
             "`sentiment_score`, or emotion columns (%s)."),
      paste(emoji_emotion_dims(), collapse = ", ")
    ), call. = FALSE)
  }
  # Same reasoning as the presence check above, applied to the type: a
  # character score column registered happily and produced all-NA scores at
  # first use, from inside emoji_score(). Check every candidate column, since
  # which one gets used depends on `score` at scoring time.
  cand <- intersect(c("sentiment_score", "score", emoji_emotion_dims()),
                    names(tbl))
  bad <- cand[!vapply(tbl[cand],
                      function(v) is.numeric(v) || is.logical(v), logical(1))]
  if (length(bad)) {
    stop(sprintf(
      paste0("`tbl`'s score column%s %s %s not numeric. A score has to be a ",
             "number; as text it would report emoji as scored while every ",
             "score came back `NA`."),
      if (length(bad) > 1L) "s" else "",
      paste(sprintf("`%s`", bad), collapse = ", "),
      if (length(bad) > 1L) "are" else "is"
    ), call. = FALSE)
  }
  tbl <- as.data.frame(tbl)
  tbl$key <- emoji_key(tbl[[by]])
  # remember which column held the glyphs so emoji_lexicons() does not report
  # it as a score dimension
  attr(tbl, "tidyEmoji_by") <- by
  if (is.null(.tidyEmoji_cache$lexicons)) {
    .tidyEmoji_cache$lexicons <- list()
  }
  .tidyEmoji_cache$lexicons[[name]] <- tbl
  invisible(tbl)
}


#' Score emoji in a text column against any lexicon
#'
#' `emoji_score()` is the generic scorer that the friendly verbs
#' ([emoji_sentiment()], [emoji_emotion()]) sit on top of. It joins each row's
#' emoji to `lexicon` through \code{emoji_key()} and returns the per-row mean of the
#' `score` column, plus the number of emoji scored. Bring your own lexicon, or
#' name a bundled / registered one.
#'
#' @inheritParams emoji_summary
#' @param lexicon Either a string naming a bundled or registered lexicon, or a
#'   data frame. For data frames, `by` names the glyph column and `score` the
#'   score column. Defaults to `"novak2015"`, matching [emoji_sentiment()].
#'
#'   Two requirements on a data frame, both refused rather than worked around.
#'   The score column must be numeric or logical: as text every score comes
#'   back `NA` while the emoji still counts as scored, which contradicts
#'   `.emoji_n_scored` below. And no two rows may give one emoji *different*
#'   scores -- spellings differing only by a variation selector share a single
#'   code-point key, so a table listing both `U+2764` and `U+2764 U+FE0F` has
#'   one emoji twice. Identical scores are fine and collapse silently; when
#'   they differ, the row order would be choosing the answer.
#' @param by Glyph column name when `lexicon` is a data frame, as a single
#'   string. Default `"emoji"`.
#' @param score Score column name when `lexicon` is a data frame. If `NULL`,
#'   `"sentiment_score"` then `"score"` are tried.
#' @return `data`, as a tibble, with `.emoji_score` (per-row mean),
#'   `.emoji_n_scored` (emoji found in the lexicon) and `.emoji_n` (total emoji)
#'   added. For the multi-dimensional `"emotag1200"` lexicon the score is the
#'   mean over its eight emotion dimensions; use [emoji_emotion()] for the
#'   per-emotion profile.
#'
#'   That averaging is specific to the bundled lexicon. A *registered* or
#'   inline lexicon carrying emotion columns has no score column, so
#'   `emoji_score()` cannot collapse it and says so: pass it to
#'   [emoji_emotion()] instead, or name one dimension with
#'   `score = "joy"` to score on that alone.
#'
#'   `.emoji_n_scored` distinguishes the two ways a score can be missing, as in
#'   [emoji_sentiment()]: `0` means the row had emoji that the lexicon could not
#'   score, `NA` that it had no emoji to score. `.emoji_n` counts every emoji
#'   either way.
#' @seealso [emoji_lexicons()], [register_emoji_lexicon()].
#' @examples
#' df <- data.frame(text = c("love \U0001f60d", "angry \U0001f621", "meh"))
#' emoji_score(df, text, lexicon = "novak2015")
#'
#' # a bring-your-own lexicon
#' own <- data.frame(emoji = c("\U0001f600", "\U0001f621"),
#'                   score = c(0.9, -0.8))
#' emoji_score(df, text, lexicon = own)
#' @export
emoji_score <- function(data, text, lexicon = "novak2015", by = "emoji",
                        score = NULL) {
  if (is.data.frame(lexicon)) {
    rec <- .emoji_lexicon_record(lexicon, by = by, score = score,
                                 arg = "lexicon")
    score_map <- rec
  } else {
    lex <- .emoji_lexicon_lookup(lexicon)
    if (identical(lex$type, "sentiment")) {
      score_map <- emoji_sentiment_map()
    } else if (identical(lex$type, "emotion")) {
      # mean of the 8 emotion scores as a single valence-ish number
      m <- emoji_emotion_map()
      score_map <- rowMeans(m, na.rm = TRUE)
    } else {
      rec <- .emoji_lexicon_record(lex$tbl, by = by, score = score,
                                   arg = "lexicon")
      score_map <- rec
    }
  }

  lst <- emoji_glyph_list(.emoji_text_col(data, {{ text }}))
  all_glyphs <- unique(unlist(lst, use.names = FALSE))
  key_lookup <- stats::setNames(emoji_key(all_glyphs), all_glyphs)

  means <- vapply(lst, function(g) {
    if (!length(g)) return(NA_real_)
    s <- score_map[key_lookup[g]]
    if (all(is.na(s))) NA_real_ else mean(s, na.rm = TRUE)
  }, numeric(1))

  n_scored <- vapply(lst, function(g) {
    if (!length(g)) return(NA_integer_)
    s <- score_map[key_lookup[g]]
    sum(!is.na(s))
  }, integer(1))

  out <- .emoji_as_tibble(data)
  out$.emoji_score <- means
  out$.emoji_n_scored <- n_scored
  out$.emoji_n <- as.integer(lengths(lst))
  out
}
