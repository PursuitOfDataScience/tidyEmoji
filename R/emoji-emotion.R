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
#'   in place of the eight columns **and of the two counts** -- the long form
#'   returns neither `.emoji_n` nor `.emoji_n_scored`. Rows without emoji, or
#'   whose emoji are absent from the lexicon, receive `NA` scores.
#'
#'   `.emoji_n_scored` is what tells those two apart, as in
#'   [emoji_sentiment()]: `0` means the row had emoji the lexicon could not
#'   score, `NA` that it had no emoji to score. Since the long form omits it,
#'   read the counts from a `long = FALSE` call on the same data (the rows are
#'   in the same order) when the distinction matters -- on a 150-glyph lexicon
#'   it usually does.
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
  .emoji_emotion_impl(data, {{ text }}, lexicon = lexicon, long = long)$out
}

# The body of emoji_emotion(), handing back the dimensions it scored as well
# as the result. emoji_emotion_label() has to know exactly which
# `.emoji_<emotion>` columns *this call* wrote: it used to pick them out of the
# result by name, which also caught any that `data` still carried from an
# earlier call, so a custom lexicon scoring only `joy` was labelled "fear" from
# a stale `.emoji_fear` it never computed.
.emoji_emotion_impl <- function(data, text, lexicon, long) {
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
    .emoji_check_value_cols(lex, dims_avail, "lexicon")
    emap <- .emoji_drop_nonfinite(as.matrix(lex[, dims_avail, drop = FALSE]),
                                  "lexicon")
    # a registered table through the column it was registered with, as in
    # emoji_score(); a plain data frame through `emoji`, falling back to `key`
    keys <- .emoji_lexicon_keys(lex, by = .emoji_registered_by(lex),
                                arg = "lexicon")
    # The same duplicate-key refusal emoji_score()/emoji_sentiment() make via
    # .emoji_lexicon_record(). Duplicate rownames are legal, and the lookup
    # below silently takes the *first* match, so a lexicon listing both
    # U+2764 and U+2764 U+FE0F with different scores gave an answer that
    # changed when the caller reordered their own table. One table, one
    # answer, whichever verb reads it.
    .emoji_check_dup_keys(keys, emap, arg = "lexicon")
    # A row whose glyph yields no key can never be matched, so it goes; then
    # one row per key, taking each dimension's non-NA value, so the answer
    # does not depend on which of two agreeing rows comes first.
    ok <- !is.na(keys) & nzchar(keys)
    emap <- emap[ok, , drop = FALSE]
    rownames(emap) <- keys[ok]
    emap <- .emoji_collapse_keys(emap)
  } else if (identical(lex$type, "emotion")) {
    emap <- emoji_emotion_map()
  } else if (identical(lex$type, "sentiment")) {
    # The mirror of emoji_sentiment()'s emotion case: say which shape was
    # passed and name the verb that takes it, rather than only listing what
    # this one wants.
    stop(sprintf(
      paste0("`lexicon = \"%s\"` is a sentiment lexicon -- one score per ",
             "emoji -- and emoji_emotion() needs the eight emotion ",
             "dimensions. Use emoji_sentiment() for a sentiment lexicon, or ",
             "'emotag1200' here."),
      lexicon), call. = FALSE)
  } else {
    # Unreachable for the same reason as emoji_sentiment()'s fall-through: the
    # custom case is unwrapped to a data frame above, so the three branches
    # cover everything .emoji_lexicon_lookup() can answer with. Kept as a net
    # for a fourth type, and worded for whoever adds one.
    stop(sprintf(
      "Internal: `lexicon` resolved to an unhandled type, \"%s\".",
      as.character(lex$type)[1L]), call. = FALSE)
  }
  dims <- colnames(emap)
  # The keys an emoji can actually be scored on. A lexicon row with no usable
  # value in any dimension (all NA, or a value that was infinite and has just
  # been dropped) is in the table but scores nothing, so an emoji matching it
  # is not scored: the rule the sentiment path already followed, and the one
  # .emoji_drop_nonfinite()'s warning states. It used to count towards
  # `.emoji_n_scored` here while every score in the row stayed NA.
  scorable <- rownames(emap)[rowSums(!is.na(emap)) > 0L]

  lst <- emoji_glyph_list(.emoji_text_col(data, {{ text }}))
  all_glyphs <- unique(unlist(lst, use.names = FALSE))
  key_lookup <- stats::setNames(emoji_key(all_glyphs), all_glyphs)

  # Per-row mean over each emotion, over the emoji the lexicon can score.
  row_means <- vapply(lst, function(g) {
    if (!length(g)) return(rep(NA_real_, length(dims)))
    keys <- key_lookup[g]
    keys <- keys[!is.na(keys) & keys %in% scorable]
    if (!length(keys)) return(rep(NA_real_, length(dims)))
    sub <- emap[keys, , drop = FALSE]
    m <- colMeans(sub, na.rm = TRUE)
    # colMeans(na.rm = TRUE) over a dimension that is missing for every emoji
    # in the row is 0/0, so it returns NaN. Every other verb reports an
    # unknown value as NA, and emoji_sentiment() returns NA_real_ for exactly
    # this case, so a custom lexicon with a gap in one dimension should not be
    # the one place a NaN reaches the user. (The bundled emotion lexicon has
    # no missing cells, so this is reachable only through `lexicon = `.)
    m[is.nan(m)] <- NA_real_
    m
  }, numeric(length(dims)))
  # vapply returns a plain vector when there is a single emotion column
  row_means <- if (length(dims) == 1L) matrix(row_means, ncol = 1L) else t(row_means)
  colnames(row_means) <- dims

  n_total <- as.integer(lengths(lst))
  n_scored <- vapply(lst, function(g) {
    if (!length(g)) return(NA_integer_)
    sum(key_lookup[g] %in% scorable)
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
    # unname(): on a one-row input `row_means[, em]` drops a 1 x k matrix to
    # length one, and R then keeps the column's dimname, so every emotion
    # column of a single-row result came back as a vector named "joy",
    # "fear", ... where every other row count gave a plain one
    for (em in dims) {
      out[[paste0(".emoji_", em)]] <- unname(row_means[, em])
    }
    out$.emoji_n <- n_total
    out$.emoji_n_scored <- n_scored
  }
  list(out = out, dims = dims)
}


#' The dominant emoji emotion per row
#'
#' `emoji_emotion_label()` adds `.emoji_emotion`, the emotion with the highest
#' mean score among the row's emoji (using [emoji_emotion()]). Ties are broken
#' in Plutchik order; a row with nothing scorable, or with no emotion ahead of
#' the others, receives `NA`.
#'
#' @inheritParams emoji_summary
#' @param lexicon Passed to [emoji_emotion()].
#' @details
#' Ties are broken in Plutchik order -- the order the eight emotions are listed
#' in throughout the package (anger, anticipation, disgust, fear, joy, sadness,
#' surprise, trust) -- so the winner is deterministic and does not depend on
#' the row's position in the data. It happens: **3 of the bundled lexicon's
#' 150 glyphs tie for their top emotion**, and because Plutchik order is
#' alphabetical the tie-break quietly favours the early names. `U+1F3A4`
#' scores anticipation and joy at 0.39 and is labelled anticipation; `U+1F619`
#' scores joy and trust at 0.83 and is labelled joy. So read
#' `.emoji_n_scored` alongside the label, and reach for [emoji_emotion()]
#' when a near-tie would change your reading: a single winning name cannot
#' show one.
#'
#' A row whose scored emotions are *all* equal is the one case with no winner
#' to break a tie between, and it gets `NA` rather than the first name in the
#' order. An emoji scored zero on all eight is the obvious example. That
#' needs a custom lexicon to reach, the bundled one having no such glyph, and
#' `.emoji_n_scored` still separates it from a row with nothing to score.
#'
#' @return `data`, as a tibble, with `.emoji_emotion` (the winning emotion, or
#'   `NA` when nothing was scorable) added, alongside the `.emoji_n` and
#'   `.emoji_n_scored` counts it inherits from [emoji_emotion()]. The eight
#'   per-emotion columns are *not* returned -- the label is the point -- unless
#'   they were already in `data`, which is what
#'   `emoji_emotion() |> emoji_emotion_label()` gives you: the profile and the
#'   label side by side.
#' @seealso [emoji_emotion()] for the eight scores this collapses, and the
#'   coverage caveat that applies to both; [emoji_emotion_lexicon] for the
#'   underlying data; [emoji_sentiment()] for valence instead of emotion.
#' @examples
#' df <- data.frame(text = c("love it \U0001f60d", "scary \U0001f628", "meh"))
#' emoji_emotion_label(df, text)
#' @export
emoji_emotion_label <- function(data, text, lexicon = "emotag1200") {
  res <- .emoji_emotion_impl(data, {{ text }}, lexicon = lexicon, long = FALSE)
  em <- res$out
  # The dimensions this call scored, in Plutchik order; a custom lexicon may
  # supply only a subset of the eight. Taken from the scoring itself rather
  # than from the names of `em`, which also holds any `.emoji_*` emotion
  # column `data` arrived with.
  dims <- res$dims
  cols <- paste0(".emoji_", dims)
  mat <- as.matrix(em[, cols, drop = FALSE])
  # break ties in Plutchik order (first max wins via ties.method="first").
  # max.col() answers NA_integer_ for any row holding an NA -- ?max.col states
  # its documented equivalence only "if m has no missing values" -- so a row
  # that scored on seven emotions and was NA on the eighth came back unlabelled
  # even though its maximum was unambiguous. Reachable from a custom lexicon
  # with an NA in one column, and from colMeans(na.rm = TRUE) returning NaN
  # when a column is NA for every glyph in the row. -Inf cannot win a maximum
  # against any real score, and has_score below still gates the rows that are
  # genuinely all-NA.
  fin <- mat
  fin[is.na(fin)] <- -Inf
  idx <- max.col(fin, ties.method = "first")
  has_score <- rowSums(!is.na(mat)) > 0
  label <- dims[idx]
  label[!has_score] <- NA_character_
  # A row whose scored dimensions are all *equal* has no dominant emotion,
  # and max.col() cannot say so -- it returns the first column, so a custom
  # lexicon scoring an emoji the same across the board (zero across the
  # board, most obviously) came back labelled "anger", which is a claim the
  # data does not make. NA is the honest answer, and it is unambiguous here
  # because `.emoji_n_scored` stays at its count rather than becoming NA, so
  # "scored, nothing won" is still distinguishable from "nothing to score".
  # Two or more scored dimensions are needed for that to mean anything: a row
  # that scored on exactly one *is* that one, with nothing to tie against.
  # The bundled lexicon has no such glyph, so nothing changes for
  # `lexicon = "emotag1200"`; this is reachable only through `lexicon = `.
  flat <- if (nrow(mat)) {
    vapply(seq_len(nrow(mat)), function(i) {
      r <- mat[i, ]
      r <- r[!is.na(r)]
      length(r) > 1L && all(r == r[1L])
    }, logical(1))
  } else {
    logical(0)
  }
  label[flat] <- NA_character_
  em$.emoji_emotion <- label
  # Drop only the per-emotion columns *this call* introduced. `data` may
  # already carry them -- emoji_emotion() then emoji_emotion_label() is the
  # obvious way to get the profile and the label together -- and dropping
  # those discarded the caller's own columns, contradicting a @return that
  # says the label is *added*. For input without them, `introduced` is the
  # whole set and the result is exactly what it always was.
  introduced <- setdiff(cols, names(data))
  em <- em[, setdiff(names(em), introduced), drop = FALSE]
  em
}
