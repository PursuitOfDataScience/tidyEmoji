# Hidden payloads (0.7.0, D8): bytes riding invisibly on an emoji.
#
# Unicode has 256 variation selectors, U+FE00..U+FE0F and U+E0100..U+E01EF,
# and a run of them after an emoji is invisible in every renderer, survives
# copy and paste, and reaches a language model's tokenizer intact, so each
# one can carry a byte of a message (Butler 2025). The tag block
# U+E0000..U+E007F mirrors ASCII and renders as nothing too ("ASCII
# smuggling"). Both are the best-documented way of slipping instructions past
# a guardrail, and until 0.7.0 every rewriting verb here passed them through,
# because they sit outside every emoji span and the verbs only act on spans.
#
# The scanner below calls a code point *hidden* by two exact rules, read from
# Unicode's own data rather than guessed at:
#
# 1. A variation selector is hidden when it cannot be part of any sequence
#    Unicode defines:
#    (a) it follows another variation selector, since no defined sequence has
#        two;
#    (b) it is an ideographic selector (U+E0100..U+E01EF) not directly after
#        a Unified_Ideograph, which is the only thing those follow (it is how
#        Japanese names are spelled); or
#    (c) it is one of U+FE00..U+FE0D and the pair is not a standardized
#        variation sequence (StandardizedVariants.txt, bundled from the UCD
#        by data-raw/crosswalks.R as .emoji_std_variants).
#    A single U+FE0E or U+FE0F is never hidden, wherever it stands: redundant
#    presentation selectors are common in ordinary text, and one carries at
#    most one byte.
# 2. A tag character is hidden unless it is inside a well-formed emoji tag
#    sequence: U+1F3F4, tags spelling a subdivision identifier, U+E007F. The
#    England, Scotland and Wales flags pass, as does a well-formed subdivision
#    the catalogue does not list (emoji_subdivision() reports it with an NA
#    name). U+E0001, the deprecated language tag, is always hidden.
#
# Out of scope on purpose: zero-width spaces, joiners and non-joiners and the
# other format characters. They are not emoji mechanisms, and several scripts
# need them (the non-joiner in Persian, the joiner in Indic scripts, the
# zero-width space in Thai and Khmer word breaking). This package inspects the
# two mechanisms that ride on emoji, and leaves the rest to a general
# Unicode-security tool.

# A row can hold a hidden code point only if it holds a tag, an ideographic
# selector, one of U+FE00..U+FE0D, or a presentation selector followed by
# another selector. Nearly every row holds none of them, and pays for this one
# scan and nothing else.
.emoji_hidden_prefilter <- paste0(
  "[\\x{E0000}-\\x{E007F}\\x{E0100}-\\x{E01EF}\\x{FE00}-\\x{FE0D}]|",
  "[\\x{FE0E}\\x{FE0F}][\\x{FE00}-\\x{FE0F}\\x{E0100}-\\x{E01EF}]"
)

# The emoji tag sequences whose tags are legitimate: the same well-formed
# subdivision shape emoji_subdivision() reads.
.emoji_flag_tag_rx <- paste0(
  "\\x{1F3F4}[\\x{E0061}-\\x{E007A}]{2}",
  "[\\x{E0030}-\\x{E0039}\\x{E0061}-\\x{E007A}]{1,4}\\x{E007F}"
)

.emoji_is_vs <- function(cp) {
  (cp >= 0xFE00L & cp <= 0xFE0FL) | (cp >= 0xE0100L & cp <= 0xE01EFL)
}

.emoji_is_tag <- function(cp) cp >= 0xE0000L & cp <= 0xE007FL

# TRUE where a code point is a Unified_Ideograph, by ICU's property tables
# through stringi, which do not depend on the session's locale. NA is not.
.emoji_is_unified_ideograph <- function(cp) {
  out <- logical(length(cp))
  ok <- !is.na(cp)
  if (any(ok)) {
    out[ok] <- stringi::stri_detect_regex(
      intToUtf8(cp[ok], multiple = TRUE), "^\\p{Unified_Ideograph}$")
  }
  out
}

# The indices of the hidden code points in `cps`, the code points of one
# string, whose UTF-8 form is `s`.
.emoji_hidden_positions <- function(cps, s) {
  n <- length(cps)
  is_vs <- .emoji_is_vs(cps)
  prev_vs <- c(FALSE, is_vs[-n])
  prev <- c(NA_integer_, cps[-n])
  # (a) a selector after a selector
  hidden <- is_vs & prev_vs
  first <- is_vs & !prev_vs
  # (b) an ideographic selector that does not follow an ideograph
  ivs <- first & cps >= 0xE0100L
  if (any(ivs)) hidden[ivs] <- !.emoji_is_unified_ideograph(prev[ivs])
  # (c) U+FE00..U+FE0D outside a standardized variation sequence
  svs <- first & cps <= 0xFE0DL
  if (any(svs)) {
    pair <- paste(sprintf("%X", prev[svs]), sprintf("%X", cps[svs]))
    hidden[svs] <- !pair %in% .emoji_std_variants
  }
  # 2: a tag outside a well-formed flag sequence
  is_tag <- .emoji_is_tag(cps)
  if (any(is_tag)) {
    legit <- logical(n)
    m <- stringi::stri_locate_all_regex(s, .emoji_flag_tag_rx,
                                        omit_no_match = TRUE)[[1L]]
    for (r in seq_len(nrow(m))) legit[m[r, "start"]:m[r, "end"]] <- TRUE
    hidden[is_tag & !legit] <- TRUE
  }
  which(hidden)
}

# For each element of `x`, the code-point indices of its hidden code points
# (integer(0) for an element with none, NA included), and the element's code
# points where it has any, which the callers that decode or remove need.
.emoji_hidden_scan <- function(x) {
  x <- as.character(x)
  pos <- rep(list(integer(0)), length(x))
  cps <- vector("list", length(x))
  cand <- which(!is.na(x) &
                  stringi::stri_detect_regex(x, .emoji_hidden_prefilter))
  for (i in cand) {
    # a string that is not valid UTF-8 cannot hold any of these code points
    cp <- suppressWarnings(utf8ToInt(x[[i]]))
    if (anyNA(cp)) next
    p <- .emoji_hidden_positions(cp, x[[i]])
    if (length(p)) {
      pos[[i]] <- p
      cps[[i]] <- cp
    }
  }
  list(pos = pos, cps = cps)
}

# `x` with every hidden code point deleted. Elements with none come back as
# they went in, byte for byte and with their encoding mark, so the default of
# the rewriting verbs changes nothing on text that carries no payload.
#
# Deleting is repeated until nothing hidden is left. One pass was not enough,
# because a deletion can make two selectors adjacent, and rule (a) then hides
# the second: U+1F600 U+FE0F <tag> U+FE0F kept a hidden U+FE0F, and selectors
# interleaved with tags carried a whole run of U+FE0E and U+FE0F through, a
# binary channel. Each pass deletes at least one code point from every
# element it rescans, so the loop ends.
.emoji_hidden_remove <- function(x) {
  sc <- .emoji_hidden_scan(x)
  hit <- which(lengths(sc$pos) > 0L)
  if (!length(hit)) return(x)
  x <- as.character(x)
  pos <- sc$pos[hit]
  cps <- sc$cps[hit]
  repeat {
    for (j in seq_along(hit)) x[[hit[[j]]]] <- intToUtf8(cps[[j]][-pos[[j]]])
    sc <- .emoji_hidden_scan(x[hit])
    again <- lengths(sc$pos) > 0L
    if (!any(again)) break
    hit <- hit[again]
    pos <- sc$pos[again]
    cps <- sc$cps[again]
  }
  x
}

# The same, for a column that may be a factor: a factor keeps being a factor,
# with its levels cleaned (two levels that differed only by a payload merge,
# which is the point). Anything else is handed to .emoji_hidden_remove().
.emoji_hidden_remove_col <- function(v) {
  if (is.factor(v)) {
    lv <- levels(v)
    clean <- .emoji_hidden_remove(lv)
    if (!identical(clean, lv)) levels(v) <- clean
    return(v)
  }
  if (!is.character(v)) return(v)
  .emoji_hidden_remove(v)
}

# Validate a `hidden` argument.
.emoji_check_hidden <- function(hidden) {
  .emoji_match_arg(hidden, c("remove", "keep"), "hidden")
}

# Make attacker text safe to print: every C0 and C1 control and every
# bidirectional control becomes a visible <U+XXXX> marker, so a decoded
# payload cannot recolour or rewrite a terminal, or reorder what a reader
# sees in a knitted report (the "Trojan Source" trick).
.emoji_escape_controls <- function(s) {
  cp <- utf8ToInt(s)
  bidi <- c(0x061CL, 0x200EL, 0x200FL, 0x202AL:0x202EL, 0x2066L:0x2069L)
  bad <- cp <= 0x1FL | (cp >= 0x7FL & cp <= 0x9FL) | cp %in% bidi
  if (!any(bad)) return(s)
  parts <- character(length(cp))
  parts[bad] <- sprintf("<U+%04X>", cp[bad])
  parts[!bad] <- intToUtf8(cp[!bad], multiple = TRUE)
  paste(parts, collapse = "")
}

# The text one contiguous run of hidden code points encodes, or NA when it is
# in neither published encoding: variation selectors as bytes (U+FE00..U+FE0F
# as 0 to 15, U+E0100..U+E01EF as 16 to 255, Butler 2025), accepted only if
# the bytes are valid UTF-8, and tag characters U+E0020..U+E007E as ASCII.
.emoji_hidden_decode <- function(seg) {
  if (all(.emoji_is_vs(seg))) {
    bytes <- ifelse(seg <= 0xFE0FL, seg - 0xFE00L, seg - 0xE0100L + 16L)
    # NUL cannot live in an R string, so decode around it; it is a control
    # character, shown as a marker like the others
    pieces <- split(bytes, cumsum(bytes == 0L))
    txt <- vapply(pieces, function(b) {
      lead_nul <- length(b) && b[1L] == 0L
      b <- b[b != 0L]
      s <- if (length(b)) rawToChar(as.raw(b)) else ""
      if (!validUTF8(s)) return(NA_character_)
      Encoding(s) <- "UTF-8"
      paste0(if (lead_nul) "<U+0000>" else "", .emoji_escape_controls(s))
    }, character(1))
    if (anyNA(txt)) return(NA_character_)
    return(paste(txt, collapse = ""))
  }
  if (all(seg >= 0xE0020L & seg <= 0xE007EL)) {
    return(.emoji_escape_controls(intToUtf8(seg - 0xE0000L)))
  }
  NA_character_
}


#' Find, measure and decode what is hidden in a text
#'
#' `emoji_hidden()` reports, per row, the code points riding invisibly in a
#' text column that Unicode gives no visible meaning to: runs of variation
#' selectors after an emoji, and tag characters outside a flag. These are the
#' two published ways of smuggling a message through an emoji, invisibly and
#' past copy and paste, into whatever reads the text next, a language model
#' included. The verb counts them, says how many bytes they cost a tokenizer,
#' and decodes the payload when it is in one of the two published encodings.
#'
#' @details
#' **What counts as hidden** is decided by two exact rules from Unicode's own
#' data, not by a guess:
#'
#' * **A variation selector is hidden when it cannot be part of any sequence
#'   Unicode defines**: when it follows another selector (no defined sequence
#'   has two), when it is an ideographic selector (`U+E0100` to `U+E01EF`)
#'   that does not follow a CJK ideograph, or when it is one of `U+FE00` to
#'   `U+FE0D` and the pair is not a standardized variation sequence. A single
#'   `U+FE0E` or `U+FE0F` is never hidden, wherever it stands, because
#'   redundant presentation selectors are common in ordinary text and one
#'   carries at most one byte.
#' * **A tag character is hidden unless it is inside a well-formed flag tag
#'   sequence**: `U+1F3F4`, tag letters spelling a subdivision code, then
#'   `U+E007F`. The England, Scotland and Wales flags are untouched, and so is
#'   a well-formed subdivision flag the catalogue does not list.
#'
#' So Japanese text spelled with ideographic variation selectors, the
#' mathematical and Mongolian variants Unicode standardizes, every keycap,
#' every catalogue spelling and every flag report nothing. Zero-width spaces,
#' joiners and non-joiners are deliberately not inspected: they are not emoji
#' mechanisms, and Persian, the Indic scripts, Thai and Khmer need them. Use a
#' general Unicode-security tool for those.
#'
#' **Decoding** covers the two published encodings only: variation selectors
#' as bytes (`U+FE00` to `U+FE0F` as 0 to 15, `U+E0100` to `U+E01EF` as 16 to
#' 255, the scheme of Butler, 2025), accepted only when the bytes are valid
#' UTF-8; and tag characters `U+E0020` to `U+E007E` as ASCII. Each contiguous
#' run of hidden code points is decoded on its own and the runs are joined by
#' `" | "`. A row with any run in neither encoding gets an `NA` payload and
#' `.emoji_hidden_decoded = FALSE`; it is still counted.
#'
#' **The payload is attacker text, returned as data.** Do not paste it into a
#' model. Every C0 and C1 control character and every bidirectional control
#' in it is replaced by a visible `<U+XXXX>` marker, so printing the result in
#' a console or a knitted report cannot recolour or rewrite the terminal or
#' reorder what a reader sees.
#'
#' There is no `presentation` argument, because neither rule depends on it: a
#' `U+FE0F` after a text-default glyph is valid whatever the caller counts as
#' an emoji. [emoji_sanitize()] and [emoji_to_text()] remove these code points
#' by default, under every policy, and [emoji_summary()] and
#' [emoji_token_cost()] count them.
#'
#' @references Butler P (2025). Smuggling arbitrary data through an emoji.
#'   <https://paulbutler.org/2025/smuggling-arbitrary-data-through-an-emoji/>
#'
#'   Hackett W, Birch L, Trawicki S, Suri N, Garraghan P (2025). Bypassing LLM
#'   Guardrails: An Empirical Analysis of Evasion Attacks against Prompt
#'   Injection and Jailbreak Detection Systems. arXiv:2504.11168.
#'
#' @inheritParams emoji_summary
#' @return `data`, as a tibble, with six columns added:
#'   \describe{
#'     \item{`.emoji_n_hidden`}{the number of hidden code points.}
#'     \item{`.emoji_hidden_bytes`}{their size in UTF-8 bytes, which is what
#'       a byte-level tokenizer pays for.}
#'     \item{`.emoji_hidden_kind`}{`"none"`, `"variation_selectors"`,
#'       `"tags"` or `"both"`.}
#'     \item{`.emoji_hidden_segments`}{the number of contiguous runs of
#'       hidden code points.}
#'     \item{`.emoji_hidden_payload`}{the decoded text, runs joined by
#'       `" | "`, with every control character shown as `<U+XXXX>`; `NA` when
#'       nothing is hidden or a run is in neither published encoding.}
#'     \item{`.emoji_hidden_decoded`}{`TRUE` when every run decoded, `FALSE`
#'       otherwise, including when nothing is hidden.}
#'   }
#'   A grouped input stays grouped. `NA` text has nothing hidden.
#' @seealso [emoji_sanitize()], whose default `hidden = "remove"` deletes what
#'   this reports; [emoji_token_cost()] for what the rest of the emoji cost.
#' @examples
#' # "hi" hidden after a grinning face, one variation selector per byte
#' hide <- function(s) {
#'   b <- as.integer(charToRaw(s))
#'   intToUtf8(ifelse(b < 16L, 0xFE00L + b, 0xE0100L + b - 16L))
#' }
#' df <- data.frame(text = c(paste0("hello \U0001F600", hide("hi")),
#'                           "plain \U0001F600"))
#' emoji_hidden(df, text)
#'
#' # the rewriting verbs remove it by default
#' nchar(emoji_sanitize(df, text)$text)
#' nchar(emoji_sanitize(df, text, hidden = "keep")$text)
#' @concept security
#' @concept language-model preprocessing
#' @export
emoji_hidden <- function(data, text) {
  v <- .emoji_text_col(data, {{ text }})
  sc <- .emoji_hidden_scan(v)
  n <- length(v)
  n_hidden <- lengths(sc$pos)
  bytes <- integer(n)
  kind <- rep("none", n)
  segments <- integer(n)
  payload <- rep(NA_character_, n)
  decoded <- logical(n)
  for (i in which(n_hidden > 0L)) {
    h <- sc$cps[[i]][sc$pos[[i]]]
    bytes[i] <- sum(ifelse(h > 0xFFFFL, 4L, 3L))
    vs <- any(.emoji_is_vs(h))
    tg <- any(.emoji_is_tag(h))
    kind[i] <- if (vs && tg) "both" else if (vs) "variation_selectors" else
      "tags"
    runs <- split(h, cumsum(c(TRUE, diff(sc$pos[[i]]) != 1L)))
    segments[i] <- length(runs)
    txt <- vapply(runs, .emoji_hidden_decode, character(1), USE.NAMES = FALSE)
    if (!anyNA(txt)) {
      payload[i] <- paste(txt, collapse = " | ")
      decoded[i] <- TRUE
    }
  }
  out <- .emoji_as_tibble(data)
  out$.emoji_n_hidden <- as.integer(n_hidden)
  out$.emoji_hidden_bytes <- as.integer(bytes)
  out$.emoji_hidden_kind <- kind
  out$.emoji_hidden_segments <- as.integer(segments)
  out$.emoji_hidden_payload <- payload
  out$.emoji_hidden_decoded <- decoded
  out
}
