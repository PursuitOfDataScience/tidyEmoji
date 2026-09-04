# Internal engine -------------------------------------------------------------
# Shared, cached helpers that power the user-facing verbs. Detection is
# delegated to {emoji}'s regex, which is fast and grapheme-aware (skin-tone
# modifiers and ZWJ sequences such as family emoji stay intact), with a
# post-pass here that re-joins ZWJ sequences the upstream regex does not yet
# know about (see .emoji_merge_zwj()). Every verb goes through
# .emoji_locations() / emoji_glyph_list(), so they all agree on what an emoji
# is. None of the helpers below are exported.

.tidyEmoji_cache <- new.env(parent = emptyenv())

# One row per emoji glyph, derived from the installed emoji::emojis table.
# `shortcode` is the first GitHub-style alias (e.g. "grinning" for the glyph
# that emoji::emojis names "grinning face"). `key` is the codepoint-normalised
# join key (U+FE0F removed). Cached for the session.
emoji_reference <- function() {
  if (is.null(.tidyEmoji_cache$reference)) {
    e <- emoji::emojis
    shortcode <- vapply(
      e$aliases,
      function(a) if (length(a)) a[[1L]] else NA_character_,
      character(1)
    )
    ref <- tibble::tibble(
      emoji     = e$emoji,
      name      = e$name,
      shortcode = shortcode,
      group     = e$group,
      subgroup  = e$subgroup,
      version   = e$version
    )
    ref$key <- emoji_key(ref$emoji)
    .tidyEmoji_cache$reference <- ref
  }
  .tidyEmoji_cache$reference
}

# Codepoint key used to join emoji robustly across qualified / unqualified
# forms: the emoji variation selector U+FE0F is dropped so that, for example,
# the qualified heart (U+2764 U+FE0F) matches the lexicon's unqualified
# U+2764.
emoji_key <- function(glyphs) {
  vapply(glyphs, function(g) {
    if (is.na(g) || !nzchar(g)) return(NA_character_)
    cp <- utf8ToInt(g)
    cp <- cp[cp != 0xFE0F]
    # A string that was nothing but variation selectors leaves no code points,
    # and used to key on "" -- a second "there is no key here" value alongside
    # NA, which every consumer then had to remember to filter separately. One
    # sentinel is enough.
    if (!length(cp)) return(NA_character_)
    paste(sprintf("%X", cp), collapse = " ")
  }, character(1), USE.NAMES = FALSE)
}

# Named vector mapping emoji_key() -> sentiment score, cached for the session.
emoji_sentiment_map <- function() {
  if (is.null(.tidyEmoji_cache$sentiment)) {
    lex <- emoji_sentiment_lexicon
    keys <- emoji_key(lex$emoji)
    score <- lex$sentiment_score
    names(score) <- keys
    .tidyEmoji_cache$sentiment <- score[!duplicated(keys)]
  }
  .tidyEmoji_cache$sentiment
}

# Grapheme-cluster repair ------------------------------------------------
# The upstream emoji regex only knows the ZWJ sequences that were current when
# it was built, so newer ones (face exhaling, heart on fire, people holding
# hands, the skin-toned handshakes, ...) come back as their component emoji.
# Two rules put them back together, and both are needed.
#
# 1. UAX #29 rule GB11 is unconditional: a zero-width joiner between two
#    emoji always binds them into one grapheme cluster. So whenever two matches
#    are separated by exactly one ZWJ, merge them. This is the rule that
#    handles sequences *newer than the installed reference table*, which is the
#    whole reason this repair exists.
#
# 2. GB11 alone was not enough, because it requires the gap to be exactly one
#    ZWJ -- and in a sequence whose middle component is a text-presentation
#    code point, that component is not matched either, so the gap is
#    `ZWJ + component + ZWJ` and the rule declined. Measured against the
#    reference table: 232 of its 2501 ZWJ sequences came back split, and the
#    damage was not a missing count but a *wrong* one. The 2023 additions with
#    a bare gender sign are the clearest case:
#
#      U+1F6B6 U+200D U+2640 U+200D U+27A1 U+FE0F   "woman walking facing right"
#
#    U+2640 is undetected, so this arrived as two emoji, "person walking" and
#    "right arrow" -- an emoji the text does not contain, counted twice.
#
#    So: also merge when the gap contains a ZWJ and the *union* of the two
#    spans is itself a catalogued emoji. That check is exact -- it can only
#    join code points that really do spell one emoji -- and it leaves rule 1
#    to cover everything the catalogue has not heard of. The pass repeats
#    because a three-part sequence may only become catalogued once two of its
#    parts have merged; it terminates because each pass strictly reduces the
#    row count.
.emoji_zwj <- "\u200d"

# The distinct codepoint keys of the reference table, cached: the set rule 2
# above tests membership in.
.emoji_ref_keys <- function() {
  if (is.null(.tidyEmoji_cache$ref_keys)) {
    .tidyEmoji_cache$ref_keys <- unique(emoji_reference()$key)
  }
  .tidyEmoji_cache$ref_keys
}

# Merge ZWJ-adjacent rows of one start/end matrix. `s` is the string the
# positions refer to.
.emoji_merge_zwj <- function(m, s) {
  if (nrow(m) < 2L) return(m)
  keys <- .emoji_ref_keys()
  repeat {
    n <- nrow(m)
    if (n < 2L) break
    gap_start <- m[-n, "end"] + 1L
    gap_end   <- m[-1L, "start"] - 1L
    gap <- substring(s, gap_start, gap_end)
    # rule 1: exactly one ZWJ between the two matches
    join_gb11 <- gap_end == gap_start & gap == .emoji_zwj
    # rule 2: a longer gap that holds a ZWJ, where the union is a real emoji
    wider <- gap_end > gap_start & grepl(.emoji_zwj, gap, fixed = TRUE)
    join_cat <- wider
    if (any(wider)) {
      span <- substring(s, m[-n, "start"][wider], m[-1L, "end"][wider])
      join_cat[wider] <- emoji_key(span) %in% keys
    }
    joined <- join_gb11 | join_cat
    if (!any(joined)) break
    grp <- cumsum(c(TRUE, !joined))
    m <- cbind(start = as.integer(tapply(m[, "start"], grp, min)),
               end   = as.integer(tapply(m[, "end"], grp, max)))
  }
  m
}

# 3. The two merge rules above both need *two* matches to work with. A
#    sequence whose only detectable component is one of its parts yields a
#    single match, so there is no pair to merge and the sequence arrives as
#    that part: `U+2764 U+200D U+1F525` ("heart on fire") with its selectors
#    omitted came back as `U+1F525` ("fire"). Counting glyphs cannot see this
#    -- one match is still one glyph -- which is why the test for it looks for
#    a joiner left *outside* every span.
#
#    So a lone match adjacent to such a joiner is grown outwards while the
#    span stays a catalogued emoji, longest win. Bounded by the longest
#    catalogued emoji (10 code points), never crossing a neighbouring match,
#    and gated on the string actually having an orphaned joiner -- so
#    well-formed text pays for one scan and nothing else. Over the reference
#    table this takes orphaned joiners from 793 to 2 (the two spellings with
#    no detectable component at all, which have nothing to grow from).
.emoji_max_cp <- 10L

# Grow lone matches over the joiners that rule 1 and rule 2 could not reach.
.emoji_extend_zwj <- function(m, s) {
  n <- nrow(m)
  if (!n) return(m)
  nc <- nchar(s)
  cps <- strsplit(s, "")[[1]]
  inside <- rep(FALSE, nc)
  for (k in seq_len(n)) inside[m[k, "start"]:m[k, "end"]] <- TRUE
  # nothing broken here: leave well-formed text alone
  if (!any(cps == .emoji_zwj & !inside)) return(m)
  keys <- .emoji_ref_keys()
  st <- m[, "start"]
  en <- m[, "end"]
  for (k in seq_len(n)) {
    lo <- if (k == 1L) 1L else en[k - 1L] + 1L
    hi <- if (k == n) nc else st[k + 1L] - 1L
    a <- st[k]
    b <- en[k]
    if (b < hi && cps[b + 1L] == .emoji_zwj) {
      best <- b
      for (e in (b + 1L):min(hi, a + .emoji_max_cp - 1L)) {
        if (emoji_key(substring(s, a, e)) %in% keys) best <- e
      }
      b <- best
    }
    if (a > lo && cps[a - 1L] == .emoji_zwj) {
      best <- a
      for (p in (a - 1L):max(lo, b - .emoji_max_cp + 1L)) {
        if (emoji_key(substring(s, p, b)) %in% keys) best <- p
      }
      a <- best
    }
    st[k] <- a
    en[k] <- b
  }
  cbind(start = as.integer(st), end = as.integer(en))
}

# Emoji locations per element, as a list of start/end matrices (possibly
# 0-row). Positions are in characters, matching substr(). This is the single
# source of truth: emoji_glyph_list() slices the same spans, so extraction and
# location can never disagree.
.emoji_locations <- function(x) {
  x <- as.character(x)
  x[is.na(x)] <- ""
  locs <- emoji::emoji_locate_all(x)
  z <- grepl(.emoji_zwj, x, fixed = TRUE)
  if (any(z)) {
    locs[z] <- mapply(.emoji_repair_zwj, locs[z], x[z], SIMPLIFY = FALSE)
  }
  locs
}

# The three rules in order. The second merge pass matters because an extension
# can bring two matches into rule 1's reach.
.emoji_repair_zwj <- function(m, s) {
  out <- .emoji_extend_zwj(.emoji_merge_zwj(m, s), s)
  if (nrow(out) > 1L) out <- .emoji_merge_zwj(out, s)
  out
}

# Slice the glyphs of one string out of its start/end matrix.
.emoji_slice <- function(m, s) {
  if (!nrow(m)) character(0) else substring(s, m[, "start"], m[, "end"])
}

# A list, one element per element of `x`, of the emoji glyphs it contains.
emoji_glyph_list <- function(x) {
  x <- as.character(x)
  x[is.na(x)] <- ""
  mapply(.emoji_slice, .emoji_locations(x), x,
         SIMPLIFY = FALSE, USE.NAMES = FALSE)
}

# Unified detection: TRUE where text contains at least one emoji.
# All verbs should use this so they agree on "what counts as having an emoji."
emoji_has <- function(x) {
  lengths(emoji_glyph_list(x)) > 0L
}

# One row per emoji occurrence, in reading order, with the character span it
# occupies. The long-form counterpart of emoji_glyph_list(): every verb that
# needs occurrence-level detail (context windows, per-glyph profiles) builds on
# this so occurrence identity is defined in exactly one place.
.emoji_occurrences <- function(v) {
  v <- as.character(v)
  v[is.na(v)] <- ""
  locs <- .emoji_locations(v)
  n <- vapply(locs, nrow, integer(1))
  if (!sum(n)) {
    return(tibble::tibble(.row_number = integer(), .position = integer(),
                          .end = integer(), .emoji = character()))
  }
  tibble::tibble(
    .row_number = rep(seq_along(v), n),
    .position = as.integer(unlist(lapply(locs, function(m) m[, "start"]),
                                  use.names = FALSE)),
    .end = as.integer(unlist(lapply(locs, function(m) m[, "end"]),
                             use.names = FALSE)),
    .emoji = as.character(unlist(
      mapply(.emoji_slice, locs, v, SIMPLIFY = FALSE, USE.NAMES = FALSE),
      use.names = FALSE
    ))
  )
}

# Split row indices into documents, in *first-appearance* order of the id.
# factor() would order the levels by sort(), which for character ids depends on
# the session's collation -- the same trap emoji_pairs()/emoji_dfm() avoid when
# ordering glyphs. Rows whose id is NA form one document.
.emoji_id_split <- function(ids) {
  lvls <- unique(ids)
  f <- factor(match(ids, lvls), levels = seq_along(lvls))
  split(seq_along(ids), f)
}

# Canonical glyph identity for the relational verbs (pairs / co-occurrence /
# n-grams / dfm): map each extracted glyph to the reference glyph that shares
# its codepoint key, so the qualified (U+2764 U+FE0F) and unqualified (U+2764)
# forms of the same emoji count as one item / node / feature. Glyphs unknown to
# the reference pass through unchanged.
emoji_canonical <- function(glyphs) {
  if (!length(glyphs)) return(character(0))
  ref <- emoji_reference()
  idx <- match(emoji_key(glyphs), ref$key)
  out <- ref$emoji[idx]
  out[is.na(idx)] <- glyphs[is.na(idx)]
  out
}

# Emotion map -------------------------------------------------------------
# Named matrix of emotion scores, rows indexed by emoji_key() so emoji carrying
# U+FE0F resolve exactly like sentiment. Cached for the session.
emoji_emotion_map <- function() {
  if (is.null(.tidyEmoji_cache$emotion)) {
    lex <- emoji_emotion_lexicon
    m <- as.matrix(lex[, c("anger", "anticipation", "disgust", "fear",
                            "joy", "sadness", "surprise", "trust")])
    rownames(m) <- lex$key
    .tidyEmoji_cache$emotion <- m
  }
  .tidyEmoji_cache$emotion
}

# Lexicon registry ------------------------------------------------------
# A tiny, documented registry so sentiment, emotion and user-supplied lexicons
# share one mechanism.
#   key -> score table is returned keyed by emoji_key() so user lexicons keyed
#   on unqualified glyphs still match qualified text.
emoji_emotion_dims <- function() {
  c("anger", "anticipation", "disgust", "fear",
    "joy", "sadness", "surprise", "trust")
}

# Build the (key -> score) record from a lexicon data frame or named score
# column, normalised through emoji_key().
.emoji_lexicon_record <- function(tbl, by = "emoji", score = NULL) {
  if (!is.data.frame(tbl)) {
    stop("`tbl` must be a data frame.", call. = FALSE)
  }
  keys <- .emoji_lexicon_keys(tbl, by)
  if (is.null(score)) {
    # heuristic: prefer 'sentiment_score', then 'score'
    score <- intersect(c("sentiment_score", "score"), names(tbl))[1L]
    if (is.na(score)) {
      stop("No score column found in `tbl`; supply `score`.",
           call. = FALSE)
    }
  }
  if (!score %in% names(tbl)) {
    stop(sprintf("Lexicon has no score column `%s`.", score), call. = FALSE)
  }
  s <- tbl[[score]]
  out <- stats::setNames(s, keys)
  out[!is.na(keys) & keys != ""]
}

# Normalised join keys for a lexicon table: prefer the glyph column `by`, and
# fall back to a pre-computed `key` column (as stored by
# register_emoji_lexicon()) so registered lexicons resolve regardless of what
# their glyph column was called.
.emoji_lexicon_keys <- function(tbl, by = "emoji") {
  if (by %in% names(tbl)) {
    emoji_key(tbl[[by]])
  } else if ("key" %in% names(tbl)) {
    as.character(tbl[["key"]])
  } else {
    stop(sprintf("Lexicon has no column `%s` to map glyphs from.", by),
         call. = FALSE)
  }
}

# Name --> tidy key index. Resolve a requested lexicon to a record or table.
# `lexicon` may be a string naming a bundled lexicon ("novak2015",
# "emotag1200"), a data frame, or a registry name registered via
# register_emoji_lexicon().
# The names the bundled lexicons answer to. The lookup below resolves these
# before it looks in the registry, so register_emoji_lexicon() has to refuse
# them: a registration under a bundled name used to succeed, appear in
# emoji_lexicons() as a second row with the same `name`, and then never be
# reachable, because every `lexicon =` naming it got the bundled table.
.emoji_reserved_lexicons <- function() {
  c("novak2015", "emoji_sentiment_lexicon", "sentiment",
    "emotag1200", "emoji_emotion_lexicon", "emotion")
}

.emoji_lexicon_lookup <- function(lexicon) {
  if (is.data.frame(lexicon)) return(lexicon)
  reg <- .tidyEmoji_cache$lexicons %||% list()
  if (!is.character(lexicon)) {
    stop("`lexicon` must be a name (string), a data frame, or NULL for the default.",
         call. = FALSE)
  }
  if (lexicon %in% c("novak2015", "emoji_sentiment_lexicon", "sentiment")) {
    ans <- list(type = "sentiment")
  } else if (lexicon %in% c("emotag1200", "emoji_emotion_lexicon", "emotion")) {
    ans <- list(type = "emotion")
  } else {
    # registered lexicon?
    if (!lexicon %in% names(reg)) {
      stop(sprintf("Unknown lexicon `%s`. See emoji_lexicons() for the bundled ones.",
                   lexicon), call. = FALSE)
    }
    ans <- list(type = "custom", tbl = reg[[lexicon]])
  }
  ans
}

# Convenience for `%||%` operator without importing rlang.
`%||%` <- function(a, b) if (is.null(a)) b else a

# Column resolution ------------------------------------------------------
# Every verb takes its column as an unquoted name (`verb(data, text)`), and
# each one used to resolve it with dplyr::pull(), which reports all three ways
# of getting the argument wrong in terms of `var` -- its own formal, and a name
# that appears in no tidyEmoji signature:
#
#   verb(df)                 ->  "`var` is absent but must be supplied."
#   verb(df, c(a, b))        ->  "`!!enquo(var)` must select exactly one column."
#   verb(df, mispelled)      ->  "object 'mispelled' not found"
#
# So the user is told to fix an argument they never wrote, and the misspelling
# -- by far the most common mistake -- is reported as if their own code had a
# free variable in it. These helpers name the real argument instead, and hand
# the not-found case to dplyr::select(), whose message says which column is
# missing.
#
# The ungroup() is load-bearing: select() on a grouped data frame silently
# re-adds the grouping columns ("Adding missing grouping variables: `g`"), so a
# grouped input made the selection return two names and the caller rejected it.
# Grouping cannot change which column a name refers to, so it is dropped for
# the lookup only -- the caller still sees the original `data`.
.emoji_col_name <- function(data, col, arg = "text") {
  if (rlang::quo_is_missing(rlang::enquo(col))) {
    stop(sprintf(
      "`%s` is required: give the unquoted name of the column to use.", arg
    ), call. = FALSE)
  }
  if (!is.data.frame(data)) {
    stop("`data` must be a data frame.", call. = FALSE)
  }
  nm <- names(dplyr::select(dplyr::ungroup(data), {{ col }}))
  if (length(nm) != 1L) {
    stop(sprintf("`%s` must select exactly one column, not %d.",
                 arg, length(nm)), call. = FALSE)
  }
  nm
}

# The column itself, with its type intact (the time verbs need Date / POSIXct
# to survive). `[[` rather than dplyr::pull() so grouped input needs no special
# case.
.emoji_col <- function(data, col, arg = "text") {
  data[[.emoji_col_name(data, {{ col }}, arg = arg)]]
}

# The text column as a character vector -- the form nearly every verb wants.
.emoji_text_col <- function(data, text, arg = "text") {
  as.character(.emoji_col(data, {{ text }}, arg = arg))
}

# Output shape for the row-preserving verbs -------------------------------
# tibble::as_tibble() strips the grouped_df class, so `df |> group_by(author)
# |> emoji_sentiment(text) |> summarise(mean(.emoji_sentiment))` silently
# collapsed to one corpus-wide row instead of one row per author -- the groups
# were gone by the time summarise() saw the data. dplyr's own mutate() and
# filter() carry groups through, and these verbs are the package's mutate() and
# filter(), so they must too. A grouped_df already *is* a tibble, so passing it
# straight back both preserves the grouping and skips a copy; anything else is
# converted as before. The cross-row aggregators do not use this -- they build
# a fresh tibble and warn that groups are ignored.
.emoji_as_tibble <- function(data) {
  if (inherits(data, "tbl_df")) data else tibble::as_tibble(data)
}

# Re-derive the group indices after a verb has rewritten column `changed`.
# The three verbs that rewrite the text column in place (emoji_to_text(),
# text_to_emoji(), emoji_sanitize()) would otherwise leave a grouped_df holding
# indices computed from the pre-rewrite values, if the user happened to group
# by the text column itself.
.emoji_regroup <- function(data, changed) {
  gv <- dplyr::group_vars(data)
  if (length(gv) && changed %in% gv) {
    return(dplyr::grouped_df(dplyr::ungroup(data), gv))
  }
  data
}

# Grouped-input guard for the cross-row aggregators -----------------------
# These verbs pool every row into one corpus-wide answer, so silently ignoring
# a grouping turns a per-group question into a global one. The guard used to be
# copy-pasted into each verb, which is exactly why seven aggregators went
# without one: it was written where the problem was noticed and never grepped
# across the package. Defining it once means a new aggregator has one obvious
# line to add.
#
# `what` carries the verb's own name so lifecycle deduplicates per verb rather
# than per call site: a session that calls several aggregators must hear from
# each of them, not just the first.
#
# `env` / `user_env` have to be passed explicitly and computed *before* the
# call. lifecycle defaults them to caller_env(1) and caller_env(2), which from
# inside this helper are the verb and the verb's own body -- both inside
# tidyEmoji -- so lifecycle concluded the package was deprecating against
# itself and appended "The deprecated feature was likely used in the tidyEmoji
# package. Please report the issue", telling the user to file a bug for their
# own grouped data frame.
.emoji_warn_grouped <- function(data, verb, when, details = NULL) {
  if (!dplyr::is_grouped_df(data)) return(invisible(FALSE))
  if (is.null(details)) {
    details <- sprintf(
      paste0("%s() pools every row into one result and ignores the grouping. ",
             "Ungroup the data, or expect a single corpus-wide answer."),
      verb
    )
  }
  verb_env <- parent.frame()
  caller_env <- if (sys.nframe() > 1L) parent.frame(2L) else globalenv()
  lifecycle::deprecate_warn(
    when,
    sprintf("%s(data = \"must be ungrouped data\")", verb),
    details = details,
    env = verb_env,
    user_env = caller_env
  )
  invisible(TRUE)
}

# TRUE when `x` is a single whole number of at least `min`.
#
# Count-like arguments (`n`, `top_n`, `window`, `min_n`) are all consumed by
# something that silently truncates a fractional value: head(n = 2.5) returns
# two rows, as.integer(window = 2.7) is a window of two, seq_len() of 2.9 stops
# at two. So the number the user wrote is not the number that was used --
# the same failure mode as the head(n = -1) the 0.4.0 audit caught, in the
# other direction. Reject it instead.
#
# Inf passes unless `finite = TRUE`: `n = Inf` is a useful "all of them" for
# the verbs whose consumer is head(), and meaningless for a window width.
.emoji_is_count <- function(x, min = 0, finite = TRUE) {
  if (!is.numeric(x) || length(x) != 1L || is.na(x) || x < min) return(FALSE)
  if (is.infinite(x)) return(!finite)
  x == trunc(x)
}

# Validate a single-string argument (a separator, a placeholder, a name).
.emoji_check_string <- function(x, arg) {
  if (!is.character(x) || length(x) != 1L || is.na(x)) {
    stop(sprintf("`%s` must be a single string.", arg), call. = FALSE)
  }
  invisible(x)
}

# Validate a TRUE/FALSE argument. isTRUE() quietly treats every non-TRUE value
# as FALSE, so an unchecked flag turns a typo into a different, silently wrong
# answer instead of an error -- the same failure mode as an unvalidated `n` or
# a `wrap` template with no placeholder.
.emoji_check_flag <- function(x, arg) {
  if (!is.logical(x) || length(x) != 1L || is.na(x)) {
    stop(sprintf("`%s` must be TRUE or FALSE.", arg), call. = FALSE)
  }
  invisible(x)
}
