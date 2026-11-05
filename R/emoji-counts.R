# Tally input: data that arrives as counts rather than as text.
#
# Every verb takes a text column and derives counts by extraction. Reaction
# data is not text: GitHub, Slack and Telegram hand over (item, glyph, count),
# and a researcher holding (pr_id, thumbs up, 12) could not call
# emoji_sentiment() at all without building synthetic strings by hand. This
# builds them, once and correctly, so every text verb reads a tally.

# GitHub's eight reaction types, as its REST and GraphQL APIs name them.
# Built from code points so the function body stays ASCII when deparsed.
.emoji_github_reactions <- function() {
  stats::setNames(
    vapply(list(0x1F44D, 0x1F44E, 0x1F604, 0x1F389, 0x1F615,
                c(0x2764, 0xFE0F), 0x1F680, 0x1F440),
           intToUtf8, character(1)),
    c("+1", "-1", "laugh", "hooray", "confused", "heart", "rocket", "eyes")
  )
}

# Resolve each distinct value of a tally's glyph column to one emoji, or NA.
.emoji_resolve_tally <- function(x) {
  u <- unique(x[!is.na(x)])
  out <- stats::setNames(rep(NA_character_, length(u)), u)
  if (!length(u)) return(out)
  ref <- emoji_reference()
  # a catalogue spelling, under any presentation, becomes its canonical form
  # so the default presentation detects it in the text built from it
  in_cat <- u %in% ref$emoji
  out[in_cat] <- as_emoji_canonical(u[in_cat])
  # one detected emoji, whatever the catalogue makes of it
  todo <- is.na(out)
  if (any(todo)) {
    gl <- emoji_glyph_list(u[todo])
    one <- lengths(gl) == 1L & vapply(seq_along(gl), function(i) {
      length(gl[[i]]) == 1L && identical(gl[[i]][[1L]], u[todo][[i]])
    }, logical(1))
    out[todo][one] <- u[todo][one]
  }
  # GitHub's reaction names, then Unicode names and shortcodes, with or
  # without the colons
  todo <- is.na(out)
  if (any(todo)) {
    gh <- .emoji_github_reactions()
    out[todo] <- unname(gh[u[todo]])
  }
  todo <- is.na(out)
  if (any(todo)) {
    bare <- sub("^:(.+):$", "\\1", u[todo])
    out[todo] <- as_emoji_canonical(as_emoji(bare))
  }
  out
}


#' Turn a tally of emoji into text the other verbs can read
#'
#' `emoji_from_counts()` takes data that records emoji as counts (one row per
#' item and emoji, with how many times it was used) and writes out, for each
#' item, a text holding each emoji that many times. Every verb in the package
#' then reads it like any other text column, so reaction data can be scored,
#' counted, profiled over time and turned into a document-by-emoji matrix.
#'
#' @details
#' **The contract is an identity.** The text written for a tally gives exactly
#' the counts, scores and matrix the original text would have given:
#' [emoji_frequency()], [emoji_sentiment()], [emoji_emotion()] and
#' [emoji_dfm()] cannot tell the two apart. The emoji are separated by single
#' spaces, so two tallied glyphs cannot fuse into a third (a tone and a hand
#' into a toned hand, two regional indicators into a flag), and nothing else
#' is added. Verbs that measure the *text* around emoji, such as
#' [emoji_position()], [emoji_context()] and [emoji_ratio()], are measuring
#' those spaces, and have nothing to say about a tally.
#'
#' The `emoji` column can hold glyphs in any spelling, the names of GitHub's
#' eight reactions (`"+1"`, `"-1"`, `"laugh"`, `"hooray"`, `"confused"`,
#' `"heart"`, `"rocket"`, `"eyes"`, as its API returns them), shortcodes with
#' or without their colons, or Unicode names. Every glyph is written in its
#' canonical spelling, so a bare `U+2764` in the tally is read by the default
#' `presentation`. A value that resolves to no emoji is an error naming it,
#' rather than a silent zero.
#'
#' `n` must be a whole number of at least 0. A fractional count, such as a
#' survey weight or an average, is refused rather than rounded: a text cannot hold
#' 2.5 emoji, and truncating it would change the answer without saying so.
#' An item whose counts are all zero keeps its row, with an empty text, so it
#' still counts as a document wherever the number of documents matters (the
#' inverse document frequency of [emoji_dfm()], for one).
#'
#' **What a reaction count measures.** A tally records which buttons were
#' pressed, and the set of buttons is the platform's: GitHub offers eight, so
#' "nobody reacted with a skull" says nothing about whether anyone thought it.
#' A study of Telegram reactions found them unreliable indicators of emotional
#' resonance, for that reason among others. The scores this makes possible are
#' scores of what the platform let people say.
#'
#' @param data A data frame with one row per (item, emoji) count.
#' @param emoji The unquoted column holding the emoji (see Details).
#' @param n The unquoted column holding the counts.
#' @param id Optional unquoted column identifying the item each count belongs
#'   to. Without it the whole table is one document.
#' @return A tibble with one row per item, in order of first appearance: the
#'   `id` column (under its own name) when given, and `text`, the emoji
#'   written out.
#' @seealso [emoji_dfm()], [emoji_sentiment()] and [emoji_frequency()] for what
#'   to do with the result.
#' @examples
#' reactions <- data.frame(
#'   pr = c(101, 101, 102),
#'   reaction = c("+1", "rocket", "-1"),
#'   count = c(3, 1, 2)
#' )
#' txt <- emoji_from_counts(reactions, reaction, count, id = pr)
#' txt
#' emoji_sentiment(txt, text)
#' @concept tallies
#' @export
emoji_from_counts <- function(data, emoji, n, id = NULL) {
  glyph_col <- .emoji_col(data, {{ emoji }}, arg = "emoji")
  counts <- .emoji_col(data, {{ n }}, arg = "n")
  if (!is.numeric(counts)) {
    stop(sprintf("`n` must be a numeric column of counts, not %s.",
                 class(counts)[1L]), call. = FALSE)
  }
  bad <- is.na(counts) | !is.finite(counts) | counts < 0 |
    counts != trunc(counts)
  if (any(bad)) {
    stop(sprintf(
      paste0("`n` must hold whole numbers of at least 0, and %d value%s ",
             "do%s not (%s). A text cannot hold a fraction of an emoji, so ",
             "a weight is refused rather than rounded."),
      sum(bad), if (sum(bad) == 1L) "" else "s",
      if (sum(bad) == 1L) "es" else "",
      paste(format(utils::head(counts[bad], 3L)), collapse = ", ")
    ), call. = FALSE)
  }
  if (any(counts > .Machine$integer.max)) {
    stop("`n` holds a count past integer range.", call. = FALSE)
  }
  glyph_col <- as.character(glyph_col)
  if (any(!is.na(glyph_col) & Encoding(glyph_col) == "bytes")) {
    stop("`emoji` carries \"bytes\" encoding, which R will not read as ",
         "characters. Convert it with iconv() first.", call. = FALSE)
  }
  if (anyNA(glyph_col)) {
    stop(sprintf("`emoji` has %d missing value%s; a count needs an emoji.",
                 sum(is.na(glyph_col)),
                 if (sum(is.na(glyph_col)) == 1L) "" else "s"),
         call. = FALSE)
  }
  map <- .emoji_resolve_tally(glyph_col)
  unresolved <- names(map)[is.na(map)]
  if (length(unresolved)) {
    stop(sprintf(
      paste0("`emoji` has %d value%s that %s not one emoji, a GitHub ",
             "reaction name, a shortcode or a Unicode name: %s."),
      length(unresolved), if (length(unresolved) == 1L) "" else "s",
      if (length(unresolved) == 1L) "is" else "are",
      paste(sprintf("`%s`", utils::head(unresolved, 5L)), collapse = ", ")
    ), call. = FALSE)
  }
  glyphs <- unname(map[glyph_col])
  reps <- as.integer(counts)

  q <- rlang::enquo(id)
  if (rlang::quo_is_null(q)) {
    groups <- list(seq_along(glyphs))
  } else {
    id_name <- .emoji_col_name(data, !!q, arg = "id")
    if (id_name == "text") {
      stop("`id` cannot be a column called `text`: that name is the output's.",
           call. = FALSE)
    }
    ids <- .emoji_col(data, !!q, arg = "id")
    groups <- unname(.emoji_id_split(ids))
  }
  text_out <- vapply(groups, function(i) {
    paste(rep(glyphs[i], reps[i]), collapse = " ")
  }, character(1), USE.NAMES = FALSE)
  if (rlang::quo_is_null(q)) {
    return(tibble::tibble(text = text_out))
  }
  out <- tibble::tibble(id = ids[vapply(groups, `[[`, integer(1), 1L)],
                        text = text_out)
  names(out)[1L] <- id_name
  out
}
