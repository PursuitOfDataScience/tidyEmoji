# Access: how emoji sit in a text, and what a screen reader makes of them
# (0.7.0). Runs are the annotation unit of the emoji-sequence literature, the
# features are the cues a classifier of emoji function reads, and the check
# reports the accessibility taxonomy of Griggio, Gorman and Tigwell (CSCW
# 2024) as facts, never as verdicts.

# Letters and numbers make a word, as everywhere in the package: Unicode's own
# properties, never a locale's class.
.emoji_word_rx <- "[\\p{L}\\p{N}]"

# Every occurrence of every row with its run and the run's position: the one
# segmentation emoji_runs(), emoji_features() and emoji_a11y_check() share.
# Two consecutive occurrences are in one run when nothing stands between
# them, when only white space does (sep = "whitespace"), or when only the
# joiners of a sequence split into its parts (D7) do.
.emoji_run_frame <- function(v, presentation, sep) {
  w <- as.character(v)
  w[is.na(w)] <- ""
  occ <- .emoji_occurrences(w, presentation)
  n <- nrow(occ)
  if (!n) {
    return(list(occ = tibble::tibble(
      row = integer(), index = integer(), emoji = character(),
      start = integer(), end = integer(), run = integer(),
      run_length = integer(), zone = character()),
      runs = tibble::tibble(
        row = integer(), run = integer(), start = integer(), end = integer(),
        length = integer(), n_distinct = integer(), glyphs = character(),
        reduplication = logical(), position = character()), text = w))
  }
  row <- occ$.row_number
  st <- occ$.position
  en <- occ$.end
  same <- c(FALSE, row[-1L] == row[-n])
  gap <- rep("", n)
  i <- which(same)
  gap[i] <- substring(w[row[i]], en[i - 1L] + 1L, st[i] - 1L)
  joined <- !nzchar(gap) |
    stringi::stri_detect_regex(gap, "^\\x{200D}+$")
  if (identical(sep, "whitespace")) {
    joined <- joined | stringi::stri_detect_regex(gap, paste0("^", .emoji_ws,
                                                              "$"))
  }
  joined <- same & joined
  run_id <- cumsum(!joined)
  # per run
  first <- !duplicated(run_id)
  last <- !duplicated(run_id, fromLast = TRUE)
  r_row <- row[first]
  r_start <- st[first]
  r_end <- en[last]
  r_len <- tabulate(run_id)
  r_in_row <- as.integer(stats::ave(r_row, r_row, FUN = seq_along))
  r_n_row <- as.integer(stats::ave(r_row, r_row, FUN = length))
  before <- substring(w[r_row], 1L, r_start - 1L)
  after <- substring(w[r_row], r_end + 1L, nchar(w[r_row]))
  is_begin <- r_in_row == 1L & !stringi::stri_detect_regex(before,
                                                           .emoji_word_rx)
  is_end <- r_in_row == r_n_row & !stringi::stri_detect_regex(after,
                                                             .emoji_word_rx)
  position <- ifelse(is_begin & is_end, "only",
                     ifelse(is_begin, "begin", ifelse(is_end, "end", "mid")))
  keys <- emoji_key(occ$.emoji)
  r_distinct <- vapply(split(keys, run_id), function(k) length(unique(k)),
                       integer(1), USE.NAMES = FALSE)
  r_glyphs <- vapply(split(occ$.emoji, run_id), paste, character(1),
                     collapse = "", USE.NAMES = FALSE)
  runs <- tibble::tibble(
    row = r_row, run = r_in_row, start = as.integer(r_start),
    end = as.integer(r_end), length = r_len, n_distinct = r_distinct,
    glyphs = r_glyphs, reduplication = r_len > 1L & r_distinct == 1L,
    position = as.character(position))
  list(
    occ = tibble::tibble(
      row = row,
      index = as.integer(stats::ave(row, row, FUN = seq_along)),
      emoji = occ$.emoji, start = st, end = en,
      run = r_in_row[run_id], run_length = r_len[run_id],
      zone = as.character(position)[run_id]),
    runs = runs, text = w)
}


#' Runs of emoji: the sequences writers build
#'
#' `emoji_runs()` returns one row per run of emoji: a maximal stretch of
#' emoji with nothing but white space between them, or nothing at all with
#' `sep = "adjacent"`. Runs are the unit the literature on emoji sequences
#' annotates. Reduplication, one emoji repeated for emphasis, is the dominant
#' multi-emoji pattern (Cohn, Engelen and Schilperoord 2019), and repetitive
#' sequences are one of the few emoji features that tell people's text from a
#' language model's.
#'
#' @details
#' **What separates two runs.** With `sep = "whitespace"`, the default and
#' what the annotators of the sequence literature did, white space may sit
#' inside a run, so "x x x" spaced out is one run; with `"adjacent"` only
#' emoji written directly together are. White space is Unicode's
#' `White_Space`, as everywhere in the package. The choice matters: the
#' bundled sample holds 1,038 runs under the default and 1,148 under
#' `"adjacent"`, and how far apart the two are depends on how the text was
#' written. Under the default 37.5% of its 1,454 emoji sit in a run of two or
#' more, and 19 of its 129 such runs are reduplications. A zero-width-joiner
#' sequence that counts as its parts (see the *Detection* section of
#' [tidyEmoji]) is one run of those parts.
#'
#' **Position.** A run is at the `"begin"` of its text when only white space
#' and punctuation come before it, at the `"end"` when only they come after
#' it, `"only"` when both are true, and `"mid"` otherwise.
#'
#' Runs are not n-grams: [emoji_ngrams()] slides a window of fixed length
#' over the emoji of a text, where a run is a maximal span of any length.
#'
#' @inheritParams emoji_summary
#' @param sep What may stand between two emoji of one run: `"whitespace"`
#'   (the default) or `"adjacent"` (nothing).
#' @return A tibble with one row per run, carrying the columns of `data`
#'   (rows without emoji contribute none), and `.row_number`, `.emoji_run`
#'   (the number of the run within its row), `.emoji_run_start` and
#'   `.emoji_run_end` (code-point offsets), `.emoji_run_length` (emoji in
#'   it), `.emoji_run_n_distinct`, `.emoji_run_glyphs` (its emoji, written
#'   together), `.emoji_run_is_reduplication` (more than one emoji, all the
#'   same) and `.emoji_run_position` (`"begin"`, `"mid"`, `"end"` or
#'   `"only"`). A grouped input stays grouped.
#' @references
#' Cohn, N., Engelen, J. and Schilperoord, J. (2019). The grammar of emoji?
#' Constraints on communicative pictorial sequencing. *Cognitive Research:
#' Principles and Implications* 4, 33. \doi{10.1186/s41235-019-0177-0}
#' @seealso [emoji_features()] for one row per emoji, with its run;
#'   [emoji_a11y_check()]; [emoji_ngrams()].
#' @examples
#' d <- data.frame(text = c("wow \U0001f600\U0001f600\U0001f600",
#'                          "\U0001f600 ok \U0001f389",
#'                          "\U0001f600\U0001f389"))
#' emoji_runs(d, text)
#' @concept sequences
#' @concept accessibility
#' @export
emoji_runs <- function(data, text, sep = c("whitespace", "adjacent"),
                       presentation = "emoji") {
  sep <- .emoji_match_arg(sep, c("whitespace", "adjacent"), "sep")
  presentation <- .emoji_check_presentation(presentation)
  v <- .emoji_text_col(data, {{ text }})
  fr <- .emoji_run_frame(v, presentation, sep)
  r <- fr$runs
  out <- .emoji_as_tibble(data)[r$row, , drop = FALSE]
  out$.row_number <- r$row
  out$.emoji_run <- r$run
  out$.emoji_run_start <- r$start
  out$.emoji_run_end <- r$end
  out$.emoji_run_length <- r$length
  out$.emoji_run_n_distinct <- r$n_distinct
  out$.emoji_run_glyphs <- r$glyphs
  out$.emoji_run_is_reduplication <- r$reduplication
  out$.emoji_run_position <- r$position
  out
}


# What is next to an occurrence, on one side: the nearest thing that is not
# white space, as "word", "emoji", "punct" or "none", and whether white space
# stands between.
.emoji_neighbour <- function(w, row, start, end, all_spans, side) {
  n <- length(row)
  kind <- character(n)
  space <- logical(n)
  for (j in seq_len(n)) {
    s <- w[[row[[j]]]]
    if (side == "prev") {
      i <- start[[j]] - 1L
      if (i < 1L) { kind[[j]] <- "none"; next }
      ch <- substr(s, i, i)
    } else {
      i <- end[[j]] + 1L
      if (i > nchar(s)) { kind[[j]] <- "none"; next }
      ch <- substr(s, i, i)
    }
    space[[j]] <- stringi::stri_detect_regex(ch, .emoji_ws1)
    # walk over white space to the nearest other character
    if (space[[j]]) {
      step <- if (side == "prev") -1L else 1L
      while (i >= 1L && i <= nchar(s) &&
             stringi::stri_detect_regex(substr(s, i, i), .emoji_ws1)) {
        i <- i + step
      }
      if (i < 1L || i > nchar(s)) { kind[[j]] <- "none"; next }
      ch <- substr(s, i, i)
    }
    m <- all_spans[[row[[j]]]]
    in_span <- nrow(m) > 0L && any(m[, "start"] <= i & m[, "end"] >= i)
    kind[[j]] <- if (in_span) "emoji" else
      if (stringi::stri_detect_regex(ch, .emoji_word_rx)) "word" else "punct"
  }
  list(kind = kind, space = space)
}


#' One row per emoji, with the cues that tell what it is doing
#'
#' `emoji_features()` returns one row per emoji occurrence with the cues a
#' classifier of emoji function reads: where the emoji sits, what is on
#' either side of it, the run it belongs to, and what kind of emoji it is.
#' It reports cues and withholds labels. The best published classifier of
#' what an emoji does in a sentence reached an F1 of 0.62 on content and its
#' annotators a Fleiss kappa of 0.50 on subtype (Na'aman, Provenza and
#' Montoya 2017), and a shipped label at that accuracy is worse than none.
#' The Unicode group, the cue that helped that classifier most, is a column.
#'
#' @details
#' A "word" is Unicode letters and numbers, and punctuation is anything else
#' that is not white space or an emoji, so nothing here depends on the
#' session's locale. `.emoji_intraword` marks an emoji with a letter or number
#' directly on both sides, `h` emoji `ow`: in ordinary text a strong cue that
#' the emoji stands for a word or a syllable, and the signature of the "Emoji
#' Attack" on language-model judges (Wei et al. 2025), which splits words
#' with emoji to throw off their tokenisation.
#'
#' @inheritParams emoji_summary
#' @return A tibble with one row per emoji occurrence, carrying the columns of
#'   `data`, and `.row_number`, `.emoji_index` (its number within the row),
#'   `.emoji`, `.emoji_start` and `.emoji_end` (code-point offsets),
#'   `.emoji_rel_position` (as [emoji_position()] defines it, for this
#'   occurrence), `.emoji_zone` (the position of its run, as [emoji_runs()]
#'   reports it), `.emoji_prev` and `.emoji_next` (`"word"`, `"emoji"`,
#'   `"punct"` or `"none"`, the nearest thing on that side past any white
#'   space), `.emoji_prev_space` and `.emoji_next_space` (white space
#'   directly on that side), `.emoji_intraword`, `.emoji_run` and
#'   `.emoji_run_length`, and `.emoji_group`, `.emoji_subgroup` and
#'   `.emoji_n_codepoints` from the catalogue. A grouped input stays
#'   grouped.
#' @references
#' Na'aman, N., Provenza, H. and Montoya, O. (2017). Varying linguistic
#' purposes of emoji in (Twitter) context. *Proceedings of ACL 2017, Student
#' Research Workshop*, 136-141. \doi{10.18653/v1/P17-3022}
#'
#' Wei, Z. et al. (2025). Emoji attack: enhancing jailbreak attacks against
#' judge LLM detection. *Proceedings of ICML 2025*, PMLR 267, 66103-66117.
#' @seealso [emoji_runs()]; [emoji_position()] for the row-level position.
#' @examples
#' d <- data.frame(text = "h\U0001f600ow are you \U0001f600")
#' emoji_features(d, text)
#' @concept sequences
#' @concept position and intensity
#' @export
emoji_features <- function(data, text, presentation = "emoji") {
  presentation <- .emoji_check_presentation(presentation)
  v <- .emoji_text_col(data, {{ text }})
  fr <- .emoji_run_frame(v, presentation, "whitespace")
  o <- fr$occ
  w <- fr$text
  all_spans <- .emoji_all_spans(w, presentation)
  prev <- .emoji_neighbour(w, o$row, o$start, o$end, all_spans, "prev")
  nxt <- .emoji_neighbour(w, o$row, o$start, o$end, all_spans, "next")
  # each occurrence's relative position, counting every emoji as one
  # position, exactly as emoji_position() does for the row's mean
  locs <- .emoji_locations(w, presentation)
  rel <- unlist(lapply(seq_along(locs), function(i) {
    m <- locs[[i]]
    if (!nrow(m)) return(numeric(0))
    extra <- m[, "end"] - m[, "start"]
    L <- nchar(w[[i]]) - sum(extra)
    if (L <= 1L) return(rep(0, nrow(m)))
    pos <- m[, "start"] - c(0L, cumsum(extra)[-length(extra)])
    (pos - 1) / (L - 1)
  }), use.names = FALSE)
  ref <- emoji_reference()
  ri <- match(emoji_key(o$emoji), ref$key)
  out <- .emoji_as_tibble(data)[o$row, , drop = FALSE]
  out$.row_number <- o$row
  out$.emoji_index <- o$index
  out$.emoji <- o$emoji
  out$.emoji_start <- o$start
  out$.emoji_end <- o$end
  out$.emoji_rel_position <- as.numeric(rel)
  out$.emoji_zone <- o$zone
  out$.emoji_prev <- prev$kind
  out$.emoji_next <- nxt$kind
  out$.emoji_prev_space <- prev$space
  out$.emoji_next_space <- nxt$space
  out$.emoji_intraword <- prev$kind == "word" & !prev$space &
    nxt$kind == "word" & !nxt$space
  out$.emoji_run <- o$run
  out$.emoji_run_length <- o$run_length
  out$.emoji_group <- ref$group[ri]
  out$.emoji_subgroup <- ref$subgroup[ri]
  out$.emoji_n_codepoints <- as.integer(nchar(o$emoji))
  out
}


#' Accessibility facts about the emoji in a text column
#'
#' `emoji_a11y_check()` reports, per row, the facts the accessibility
#' taxonomy of Griggio, Gorman and Tigwell (CSCW 2024) is built from: how
#' often an emoji or a sequence repeats, where emoji sit, which are
#' ambiguous or carry long modified names, and how many characters a screen
#' reader would say for them. It reports facts and gives no verdicts:
#' whether a message is too much is the writer's call, which is the paper's
#' own finding.
#'
#' @details
#' The columns follow the taxonomy. **Number of emoji:** `.emoji_max_repeat`
#' (1a, one emoji repeated), `.emoji_n_repeated_seqs` (1b, the same pair of
#' different emoji written together more than once; a run of one emoji is 1a,
#' not 1b) and `.emoji_longest_run` (1c, a run of emoji of any kind, as
#' [emoji_runs()] segments it). **Placement:** `.emoji_n_mid` (2a, inside the
#' text) and `.emoji_n_begin` (2b, opening it). The package does no sentence
#' segmentation, so these are relative to the row; split your text into
#' sentences first and they are exactly the paper's. **Purpose:**
#' `.emoji_n_ambiguous` (3a, emoji in the top tenth of [emoji_ambiguity()]'s
#' polarisation, which reads the bundled lexicon and so is 0 for the emoji
#' it cannot score; [emoji_coverage()] says how many those are) and
#' `.emoji_n_modifier_names` (3b, emoji whose name a skin tone or a gender
#' extends, as in "woman facepalming: light skin tone").
#'
#' The paper's Alert fired on one emoji three times, two emoji twice each,
#' and three different emoji in a row. Those are thresholds to apply to these
#' columns if you want them; the verb applies none. The design its
#' participants preferred, a Preview of what a screen reader will say, is
#' [emoji_to_text()] with `format = "name"`.
#'
#' **Spoken length is a proxy.** `.emoji_spoken_chars` adds up the CLDR
#' names, which is what NVDA's symbol dictionaries are built from; VoiceOver,
#' the Windows readers and TalkBack each announce their own strings, and Remy
#' Sharp's emoji accessibility reference tabulates them. Some readers shorten
#' a repeat ("three face with tears of joy"), which the column does not
#' model. On the bundled sample, naming every emoji takes the emoji-bearing
#' rows from 147,742 characters to 171,606, 16.2% more, and 50 of its 750
#' emoji-bearing rows hold a run of three or more.
#'
#' `max_name` is the one threshold, because a long name is a property of the
#' catalogue rather than of the text: four catalogue names in five are 40
#' characters or shorter (the median is 26), so the default flags 18.7% of
#' the catalogue, but only 1 of the sample's 1,454 occurrences, because the
#' emoji people use most have short names.
#'
#' @inheritParams emoji_summary
#' @param max_name A name longer than this many characters counts in
#'   `.emoji_n_long_names`. Default `40`.
#' @return `data`, as a tibble, with added columns `.emoji_max_repeat`,
#'   `.emoji_n_repeated_seqs`, `.emoji_longest_run`, `.emoji_n_mid`,
#'   `.emoji_n_begin`, `.emoji_n_ambiguous`, `.emoji_n_modifier_names` (see
#'   Details), `.emoji_spoken_chars` (the characters of the row's emoji
#'   names), `.emoji_n_char` (the text's own length, the denominator; `NA`
#'   for `NA` text), `.emoji_n_long_names` (names longer than `max_name`),
#'   `.emoji_n_ri_letters` (regional indicators that spell no flag, which a
#'   screen reader reads out one letter at a time) and `.emoji_n_hidden`
#'   (hidden code points, as [emoji_hidden()] counts them). A grouped input
#'   stays grouped.
#' @references
#' Griggio, C. F., Gorman, B. M. and Tigwell, G. W. (2024). "Party Face
#' Congratulations!" Exploring design ideas to help sighted users with emoji
#' accessibility when messaging with screen reader users. *Proceedings of
#' the ACM on Human-Computer Interaction* 8 (CSCW1), article 175.
#' \doi{10.1145/3641014}
#' @seealso [emoji_to_text()] for the Preview; [emoji_runs()];
#'   [emoji_ambiguity()].
#' @examples
#' d <- data.frame(text = c(
#'   "lol \U0001f602\U0001f602\U0001f602\U0001f602",
#'   "\U0001f389\u2764\ufe0f yes \U0001f389\u2764\ufe0f",
#'   "so \U0001f389 much fun"))
#' emoji_a11y_check(d, text)
#' @concept accessibility
#' @export
emoji_a11y_check <- function(data, text, max_name = 40L,
                             presentation = "emoji") {
  if (!.emoji_is_count(max_name, finite = TRUE)) {
    stop("`max_name` must be a single non-negative whole number.",
         call. = FALSE)
  }
  presentation <- .emoji_check_presentation(presentation)
  v <- .emoji_text_col(data, {{ text }})
  n <- length(v)
  fr <- .emoji_run_frame(v, presentation, "whitespace")
  o <- fr$occ
  row <- o$row
  key <- emoji_key(o$emoji)
  tally <- function(keep) tabulate(row[keep], nbins = n)
  per_row <- function(f, empty) {
    out <- rep(empty, n)
    if (!nrow(o)) return(out)
    s <- split(seq_len(nrow(o)), factor(row, levels = seq_len(n)))
    got <- lengths(s) > 0L
    out[got] <- vapply(s[got], f, integer(1))
    out
  }
  max_repeat <- per_row(function(i) max(tabulate(match(key[i], key[i]))), 0L)
  # pairs of different emoji written together, within one run
  same_run <- c(FALSE, row[-1L] == row[-length(row)] &
                  o$run[-1L] == o$run[-length(row)])
  pair <- ifelse(same_run, paste(c("", key[-length(key)]), key), NA_character_)
  pair[same_run & c(FALSE, key[-1L] == key[-length(key)])] <- NA_character_
  repeated <- per_row(function(i) {
    p <- pair[i]
    p <- p[!is.na(p)]
    if (!length(p)) return(0L)
    sum(table(p) > 1L)
  }, 0L)
  longest <- per_row(function(i) max(o$run_length[i]), 0L)
  # the top tenth of the bundled lexicon's polarisation
  amb <- emoji_ambiguity(measure = "polarisation")
  cut <- stats::quantile(amb$ambiguity, 0.9, na.rm = TRUE, names = FALSE)
  top <- amb$key[!is.na(amb$ambiguity) & amb$ambiguity >= cut]
  w <- .emoji_identity_lookup(o$emoji)
  modified <- (w$modifiable %in% TRUE & w$tone %in% c(.emoji_tone_levels,
                                                       "mixed")) |
    (w$gender %in% c("female", "male", "mixed") & !is.na(w$neutral) &
       w$neutral != w$base)
  name <- as_emoji_name(o$emoji)
  name_len <- ifelse(is.na(name), 0L, nchar(name))
  spoken <- tabulate(rep(row, name_len), nbins = n)
  # regional indicators standing alone or in a pair that spells no flag (D2)
  sp <- .emoji_spans(fr$text, presentation)
  ri <- vapply(seq_len(n), function(i) {
    k <- sp$kinds[[i]]
    if (is.null(k) || !any(k == .emoji_kind_flag)) return(0L)
    g <- .emoji_slice(sp$locs[[i]][k == .emoji_kind_flag, , drop = FALSE],
                      fr$text[[i]])
    sum(nchar(g))
  }, integer(1))
  n_char <- nchar(v)
  out <- .emoji_as_tibble(data)
  out$.emoji_max_repeat <- as.integer(max_repeat)
  out$.emoji_n_repeated_seqs <- as.integer(repeated)
  out$.emoji_longest_run <- as.integer(longest)
  out$.emoji_n_mid <- tally(o$zone == "mid")
  out$.emoji_n_begin <- tally(o$zone == "begin")
  out$.emoji_n_ambiguous <- tally(key %in% top)
  out$.emoji_n_modifier_names <- tally(modified)
  out$.emoji_spoken_chars <- as.integer(spoken)
  out$.emoji_n_char <- as.integer(n_char)
  out$.emoji_n_long_names <- tally(name_len > max_name)
  out$.emoji_n_ri_letters <- as.integer(ri)
  out$.emoji_n_hidden <- lengths(.emoji_hidden_scan(v)$pos)
  out
}
