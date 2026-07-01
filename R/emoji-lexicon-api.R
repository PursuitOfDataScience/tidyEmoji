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
      dimensions = I(lapply(reg, function(x) names(x))),
      n = vapply(reg, nrow, integer(1)),
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
#' \code{emoji_key()} (U+FE0F stripped), so a lexicon keyed on unqualified glyphs
#' still matches qualified text (see next_release.md §4.1).
#'
#' @param name Name to register the lexicon under.
#' @param tbl A data frame. Must contain a glyph column named `by` (default
#'   `"emoji"`) and at least one score column.
#' @param by Name of the column holding the emoji glyph. Default `"emoji"`.
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
  if (!is.character(name) || length(name) != 1L || !nzchar(name)) {
    stop("`name` must be a single non-empty string.", call. = FALSE)
  }
  if (!is.data.frame(tbl)) stop("`tbl` must be a data frame.", call. = FALSE)
  if (!by %in% names(tbl)) {
    stop(sprintf("`tbl` has no column `%s`.", by), call. = FALSE)
  }
  tbl <- as.data.frame(tbl)
  tbl$key <- emoji_key(tbl[[by]])
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
#'   score column.
#' @param by Glyph column name when `lexicon` is a data frame. Default
#'   `"emoji"`.
#' @param score Score column name when `lexicon` is a data frame. If `NULL`,
#'   `"sentiment_score"` then `"score"` are tried.
#' @return `data`, as a tibble, with `.emoji_score` (per-row mean),
#'   `.emoji_n_scored` (emoji found in the lexicon) and `.emoji_n` (total emoji)
#'   added.
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
emoji_score <- function(data, text, lexicon, by = "emoji", score = NULL) {
  if (is.data.frame(lexicon)) {
    rec <- .emoji_lexicon_record(lexicon, by = by, score = score)
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
      rec <- .emoji_lexicon_record(lex$tbl, by = by, score = score)
      score_map <- rec
    }
  }

  lst <- emoji_glyph_list(dplyr::pull(data, {{ text }}))
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

  out <- tibble::as_tibble(data)
  out$.emoji_score <- means
  out$.emoji_n_scored <- n_scored
  out$.emoji_n <- as.integer(lengths(lst))
  out
}
