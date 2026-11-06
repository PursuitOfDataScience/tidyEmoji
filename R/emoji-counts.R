# Tally input: data that arrives as counts rather than as text.
#
# Every verb takes a text column and derives counts by extraction. Reaction
# data is not text: GitHub, Slack and Telegram hand over (item, glyph, count),
# and a researcher holding (pr_id, thumbs up, 12) could not call
# emoji_sentiment() at all without building synthetic strings by hand. This
# builds them, once and correctly, so every text verb reads a tally.

# GitHub's eight reaction types, under the names its REST API uses ("+1")
# and those of its GraphQL ReactionContent enum (THUMBS_UP), keyed in lower
# case: a value is folded to ASCII lower case before it is looked up, so the
# enum's capitals match. Built from code points so the function body stays
# ASCII when deparsed.
.emoji_github_reactions <- function() {
  glyphs <- vapply(list(0x1F44D, 0x1F44E, 0x1F604, 0x1F389, 0x1F615,
                        c(0x2764, 0xFE0F), 0x1F680, 0x1F440),
                   intToUtf8, character(1))
  rest <- c("+1", "-1", "laugh", "hooray", "confused", "heart", "rocket",
            "eyes")
  graphql <- c("thumbs_up", "thumbs_down", "laugh", "hooray", "confused",
               "heart", "rocket", "eyes")
  out <- stats::setNames(c(glyphs, glyphs), c(rest, graphql))
  out[!duplicated(names(out))]
}

# ASCII lower case, the same in every locale (tolower() is not).
.emoji_ascii_fold <- function(x) {
  chartr(.emoji_ascii_upper, .emoji_ascii_lower, x)
}

# The catalogue's spelling of `glyph` in Slack's skin tone `tone`, 2 (light)
# to 6 (dark), with every person in it toned alike; NA when the emoji takes no
# tone. Read from the catalogue rather than built by inserting a modifier,
# because where the modifier goes depends on the sequence.
.emoji_toned_spelling <- function(glyph, tone) {
  out <- rep(NA_character_, length(glyph))
  ok <- !is.na(glyph)
  if (!any(ok)) return(out)
  ref <- emoji_reference()
  toned <- ref$emoji[ref$status == "fully-qualified" &
                       grepl("(^| )1F3F[B-F]( |$)", ref$key)]
  cps <- lapply(toned, utf8ToInt)
  bare <- emoji_key(.emoji_strip_tones(toned))
  for (i in which(ok)) {
    mod <- 0x1F3FBL + as.integer(tone[[i]]) - 2L
    alike <- vapply(cps, function(c) {
      t <- c[c %in% .emoji_tone_cps]
      length(t) > 0L && all(t == mod)
    }, logical(1))
    hit <- toned[alike & bare == emoji_key(glyph[[i]])]
    if (length(hit)) out[[i]] <- hit[[1L]]
  }
  out
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
  # GitHub's reaction names, REST or GraphQL, then Unicode names and
  # shortcodes, with or without the colons
  by_name <- function(v) {
    r <- unname(.emoji_github_reactions()[.emoji_ascii_fold(v)])
    miss <- is.na(r)
    if (any(miss)) {
      r[miss] <- as_emoji_canonical(as_emoji(sub("^:(.+):$", "\\1", v[miss])))
    }
    r
  }
  todo <- is.na(out)
  if (any(todo)) out[todo] <- by_name(u[todo])
  # Slack's skin tones: "thumbsup::skin-tone-2", with or without the outer
  # colons, is the base in tone 2 (light) to 6 (dark), refused when the base
  # takes no tone
  todo <- which(is.na(out))
  if (length(todo)) {
    bare <- sub("^:(.+):$", "\\1", u[todo])
    m <- regmatches(bare, regexec("^(.+)::skin-tone-([2-6])$", bare))
    hit <- lengths(m) == 3L
    if (any(hit)) {
      base <- by_name(vapply(m[hit], `[[`, character(1), 2L))
      tone <- vapply(m[hit], `[[`, character(1), 3L)
      out[todo[hit]] <- .emoji_toned_spelling(base, tone)
    }
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
#' `"heart"`, `"rocket"`, `"eyes"`, as its REST API returns them, or
#' `"THUMBS_UP"`, `"THUMBS_DOWN"` and the rest, as its GraphQL API does, in
#' any case), shortcodes with or without their colons, Slack's toned names
#' (`"thumbsup::skin-tone-2"`, tone 2 light to 6 dark), or Unicode names.
#' Every glyph is written in its canonical spelling, so a bare `U+2764` in the
#' tally is read by the default `presentation`. A value that resolves to no
#' emoji is an error naming it, rather than a silent zero, unless
#' `unknown = "drop"`; a Slack tone on an emoji that takes none resolves to
#' no emoji.
#'
#' `n` must be a whole number of at least 0. A fractional count, such as a
#' survey weight or an average, is refused rather than rounded: a text cannot hold
#' 2.5 emoji, and truncating it would change the answer without saying so.
#' An item whose counts are all zero keeps its row, with an empty text, so it
#' still counts as a document wherever the number of documents matters (the
#' inverse document frequency of [emoji_dfm()], for one). So does an item
#' whose every row `unknown = "drop"` removed.
#'
#' One item's text is one R string, which holds at most 2,147,483,647 bytes.
#' A tally that would write more for one item, about 430 million thumbs-up,
#' is refused before anything is built, with the item and the size named. A
#' count that size is a weight over a corpus rather than a tally of one
#' item's reactions, and a text cannot carry a weight; score the glyph once
#' and multiply instead.
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
#' @param unknown What to do with a value of `emoji` that resolves to no
#'   emoji: `"error"` (the default) stops and names it, since a silent drop
#'   changes answers; `"drop"` removes its rows and warns once, naming each
#'   such value with the total count it carried. Real tallies need it: the
#'   OASST2 one bundled as [oasst_reactions] records interface actions
#'   (`"_skip_reply"`) beside the emoji.
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
#'
#' # GraphQL names and Slack's tones resolve too
#' emoji_from_counts(data.frame(r = c("THUMBS_UP", "thumbsup::skin-tone-4"),
#'                              n = 1), r, n)
#'
#' # a real tally, with the interface's skip actions set aside
#' oasst <- emoji_from_counts(oasst_reactions, reaction, n, id = message_id,
#'                            unknown = "drop")
#' emoji_frequency(oasst, text)
#' @concept tallies
#' @export
emoji_from_counts <- function(data, emoji, n, id = NULL,
                              unknown = c("error", "drop")) {
  unknown <- .emoji_match_arg(unknown, c("error", "drop"), "unknown")
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
  if (length(unresolved) && unknown == "error") {
    stop(sprintf(
      paste0("`emoji` has %d value%s that %s not one emoji, a reaction ",
             "name, a shortcode or a Unicode name: %s. `unknown = \"drop\"` ",
             "sets such rows aside instead."),
      length(unresolved), if (length(unresolved) == 1L) "" else "s",
      if (length(unresolved) == 1L) "is" else "are",
      paste(sprintf("`%s`", utils::head(unresolved, 5L)), collapse = ", ")
    ), call. = FALSE)
  }
  glyphs <- unname(map[glyph_col])
  reps <- as.integer(counts)
  if (length(unresolved)) {
    # dropped rows are written zero times, so every item keeps its row
    gone <- is.na(glyphs)
    tot <- vapply(split(reps[gone], factor(glyph_col[gone], levels = unresolved)),
                  function(z) sum(as.numeric(z)), numeric(1))
    o <- order(-tot, unresolved, method = "radix")
    named <- sprintf("`%s` (%s)", unresolved[o],
                     format(tot[o], big.mark = ",", scientific = FALSE,
                            trim = TRUE))
    warning(sprintf(
      paste0("Dropped %d value%s of `emoji` that %s not one emoji, with the ",
             "counts %s carried: %s%s."),
      length(unresolved), if (length(unresolved) == 1L) "" else "s",
      if (length(unresolved) == 1L) "is" else "are",
      if (length(unresolved) == 1L) "it" else "they",
      paste(utils::head(named, 10L), collapse = ", "),
      if (length(named) > 10L) sprintf(" and %d more", length(named) - 10L)
      else ""
    ), call. = FALSE)
    reps[gone] <- 0L
    glyphs[gone] <- ""
  }

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
  # One item is one string, and R's strings stop at 2^31 - 1 bytes: refuse a
  # tally that would pass it before building anything, rather than let
  # paste() fail with a message about memory
  bytes <- (nchar(glyphs, type = "bytes") + 1) * reps
  size <- vapply(groups, function(i) max(sum(bytes[i]) - 1, 0), numeric(1))
  big <- which(size > .Machine$integer.max)
  if (length(big)) {
    b <- big[[1L]]
    item <- if (rlang::quo_is_null(q)) {
      "the whole table (one item, since `id` is not given)"
    } else {
      sprintf("item `%s`", format(ids[groups[[b]][[1L]]]))
    }
    stop(sprintf(
      paste0("`n` would write %s bytes of text for %s, past the %s bytes ",
             "one R string can hold. A count that size is a weight over a ",
             "corpus, not a tally of one item's emoji, and a text cannot ",
             "carry a weight: score the glyph once and multiply instead."),
      format(size[[b]], big.mark = ",", scientific = FALSE), item,
      format(.Machine$integer.max, big.mark = ",")), call. = FALSE)
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
