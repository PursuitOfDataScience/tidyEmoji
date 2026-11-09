# The catalogue surface: what a glyph is, which spelling is canonical, whether
# two glyphs are the same emoji, and the keyword vocabulary.
#
# Every verb in the package detects and joins against the bundled catalogue,
# and until 0.6.0 none of them let a user ask it anything. These do. They are
# vector verbs, like as_emoji_name(): they take glyphs, not a data frame.

# The catalogue keyed by code-point key, with what the vector verbs need per
# emoji rather than per spelling, cached: the canonical (fully-qualified or
# component) spelling, and whether the emoji can carry a skin-tone modifier.
.emoji_tone_cps <- 0x1F3FB:0x1F3FF

.emoji_strip_tones <- function(glyphs) {
  vapply(glyphs, function(g) {
    if (is.na(g)) return(NA_character_)
    cp <- suppressWarnings(utf8ToInt(g))
    if (anyNA(cp)) return(NA_character_)
    intToUtf8(cp[!cp %in% .emoji_tone_cps])
  }, character(1), USE.NAMES = FALSE)
}

.emoji_by_key <- function() {
  if (is.null(.tidyEmoji_cache$by_key)) {
    ref <- emoji_reference()
    first <- !duplicated(ref$key)
    keys <- ref$key[first]
    # an emoji is modifiable when the catalogue spells it with a tone: strip
    # the tones from every spelling that has one, and the keys left are the
    # emoji that take them
    has_tone <- grepl("(^| )1F3F[B-F]( |$)", ref$key)
    toneless <- unique(emoji_key(.emoji_strip_tones(ref$emoji[has_tone])))
    .tidyEmoji_cache$by_key <- list(
      key = keys,
      canonical = ref$emoji[first],
      modifiable = keys %in% toneless
    )
  }
  .tidyEmoji_cache$by_key
}

# "U+1F600 U+FE0F" for each glyph; NA for NA or undecodable input.
.emoji_codepoint_label <- function(glyphs) {
  vapply(glyphs, function(g) {
    if (is.na(g)) return(NA_character_)
    cp <- suppressWarnings(utf8ToInt(g))
    if (anyNA(cp) || !length(cp)) return(NA_character_)
    paste(sprintf("U+%04X", cp), collapse = " ")
  }, character(1), USE.NAMES = FALSE)
}

# `what` is what the vector should hold, in the words of the message, so a
# verb that takes more than glyphs can say so.
.emoji_check_glyphs <- function(x, arg = "x", what = "emoji glyphs") {
  if (is.factor(x)) x <- as.character(x)
  if (!is.character(x) && !(is.logical(x) && all(is.na(x)))) {
    stop(sprintf("`%s` must be a character vector of %s, not %s.",
                 arg, what, class(x)[1L]), call. = FALSE)
  }
  x <- as.character(x)
  bad <- !is.na(x) & Encoding(x) == "bytes"
  if (any(bad)) {
    stop(sprintf(
      paste0("`%s` carries \"bytes\" encoding, which R will not read as ",
             "characters. Convert it with iconv() from whatever encoding ",
             "those bytes really are."), arg), call. = FALSE)
  }
  x
}


#' What the catalogue knows about a glyph
#'
#' `emoji_properties()` reports, for each glyph, everything the bundled emoji
#' catalogue records about it: its code points, its qualification status, its
#' Unicode name, group and subgroup, the emoji version that introduced it, and
#' whether it can carry a skin-tone modifier. With no argument it returns the
#' whole catalogue, one row per spelling.
#'
#' @details
#' The catalogue is Unicode's `emoji-test.txt` for the version
#' [emoji_unicode_version()] reports. It lists every spelling of every emoji,
#' and `status` is what the file calls the spelling:
#'
#' * `"fully-qualified"`: the spelling a keyboard emits, carrying every
#'   `U+FE0F` the emoji needs. Exactly one per emoji.
#' * `"minimally-qualified"`: a shorter spelling of a joined sequence, with
#'   some selectors left out but the first one kept.
#' * `"unqualified"`: a spelling with the first selector left out too, such
#'   as the bare heart `U+2764`. These are detected only under
#'   `presentation = "any"`; see [emoji_summary()].
#' * `"component"`: the five skin-tone swatches and four hair components,
#'   which are parts of emoji rather than emoji. Standing alone they are not
#'   counted by any verb.
#'
#' `status` describes the exact spelling you passed, so it is `NA` for one the
#' catalogue does not list: a correct emoji with a stray extra `U+FE0F`, a
#' sequence too new for this catalogue, or a string that is not an emoji at
#' all. The other catalogue columns describe the *emoji*, and are looked up
#' through the code-point key every verb uses, which ignores `U+FE0F`: the
#' bare and the qualified heart share a name, a group and a version. The
#' `codepoints`, `n_codepoints` and `has_fe0f` columns describe the string
#' itself and are filled in for anything, emoji or not.
#'
#' `modifiable` is `TRUE` when the catalogue spells the emoji with a skin
#' tone, so it is a statement about the emoji with any tone it carries
#' removed: `U+1F44D` and `U+1F44D U+1F3FD` are both modifiable. It is `NA`
#' where the emoji is not in the catalogue.
#'
#' @param x A character vector of glyphs. The default, `NULL`, returns every
#'   spelling in the catalogue, in the catalogue's own order.
#' @return A tibble with one row per element of `x` (or per catalogue
#'   spelling), in the same order, and columns `emoji`, `codepoints` (as
#'   `"U+1F600 U+FE0F"`), `n_codepoints`, `key` (the code-point key, with
#'   `U+FE0F` removed), `name`, `status`, `group`, `subgroup`, `version`
#'   (the emoji version that introduced it, such as `"15.0"`), `modifiable`
#'   and `has_fe0f`.
#' @seealso [as_emoji_canonical()] for the fully-qualified spelling,
#'   [emoji_identical()] to compare two glyphs, [emoji_unicode_releases()]
#'   to turn `version` into a date, and [emoji_keywords()] for the vocabulary.
#' @examples
#' emoji_properties(c("\u2764", "\u2764\ufe0f", "\U0001f44d\U0001f3fd"))
#'
#' # the whole catalogue, one row per spelling
#' cat <- emoji_properties()
#' table(cat$status)
#' @concept catalogue
#' @export
emoji_properties <- function(x = NULL) {
  ref <- emoji_reference()
  if (is.null(x)) {
    # The whole catalogue is the same table every time it is asked for, and
    # building it costs a quarter of a second, so it is built once per
    # session. Derived from the reference, so .emoji_derived_cache_slots()
    # names it and a rebuilt reference drops it.
    if (is.null(.tidyEmoji_cache$properties)) {
      .tidyEmoji_cache$properties <- .emoji_properties_of(ref$emoji, ref)
    }
    return(.tidyEmoji_cache$properties)
  }
  .emoji_properties_of(.emoji_check_glyphs(x), ref)
}

.emoji_properties_of <- function(x, ref) {
  keys <- emoji_key(x)
  bk <- .emoji_by_key()
  kidx <- match(keys, ref$key)
  status <- ref$status[match(x, ref$emoji)]
  cps <- lapply(x, function(g) {
    if (is.na(g)) return(NA_integer_)
    suppressWarnings(utf8ToInt(g))
  })
  n_cp <- vapply(cps, function(c) if (anyNA(c)) NA_integer_ else length(c),
                 integer(1))
  # Judged on the emoji with its tones removed, so a toned glyph answers for
  # its base. A swatch on its own strips to nothing: it is in the catalogue
  # and takes no tone, so FALSE rather than NA.
  modifiable <- bk$modifiable[match(emoji_key(.emoji_strip_tones(x)), bk$key)]
  # A catalogue spelling with a tone in it is, by the definition above, an
  # emoji the catalogue spells with a tone. Stripping the tones misses 280
  # of them: a handshake, a kiss, a couple with heart, people holding hands,
  # wrestlers and bunny ears in mixed tones are joined sequences whose
  # untoned form is a different, single code point (U+1F91D for the
  # handshake), so the stripped key is in no catalogue and they fell through
  # to FALSE below, where emoji_decompose() said TRUE.
  toned <- !is.na(kidx) & ref$status[kidx] != "component" &
    grepl("(^| )1F3F[B-F]( |$)", keys)
  modifiable[is.na(modifiable) & toned] <- TRUE
  modifiable[is.na(modifiable) & !is.na(kidx)] <- FALSE
  tibble::tibble(
    emoji = x,
    codepoints = .emoji_codepoint_label(x),
    n_codepoints = n_cp,
    key = keys,
    name = ref$name[kidx],
    status = status,
    group = ref$group[kidx],
    subgroup = ref$subgroup[kidx],
    version = ref$version[kidx],
    modifiable = modifiable,
    has_fe0f = vapply(cps, function(c) {
      if (anyNA(c)) NA else any(c == 0xFE0F)
    }, logical(1))
  )
}


#' The canonical spelling of an emoji
#'
#' `as_emoji_canonical()` maps each glyph to the one spelling the catalogue
#' marks fully-qualified, so that the bare heart `U+2764` and the qualified
#' heart `U+2764 U+FE0F` become the same string. It is the normalisation every
#' verb in the package applies before a join, exported so a join of your own
#' can apply it too.
#'
#' @details
#' Two spellings of one emoji differ only in the variation selector `U+FE0F`
#' (or `U+FE0E`, which asks for the text form), and a plain
#' `dplyr::left_join()` on the glyph treats them as different
#' keys, which silently drops every row whose text holds the other spelling.
#' Canonicalising both sides first is the fix. A glyph the catalogue does not
#' know comes back unchanged, so the function is safe to apply to a whole
#' column, and `NA` stays `NA`.
#'
#' The canonical spelling is a choice of bytes, not of meaning: a skin tone, a
#' gender sign and a ZWJ component are part of the emoji and are kept. Use
#' [emoji_identical()] to ask whether two glyphs are the same emoji, and how
#' they differ when they are not.
#'
#' @param x A character vector of glyphs.
#' @return A character vector the same length as `x`.
#' @seealso [emoji_identical()], [emoji_properties()].
#' @examples
#' as_emoji_canonical(c("\u2764", "\u2764\ufe0f", "\u263a", "not an emoji"))
#' @concept catalogue
#' @export
as_emoji_canonical <- function(x) {
  x <- .emoji_check_glyphs(x)
  bk <- .emoji_by_key()
  out <- bk$canonical[match(emoji_key(x), bk$key)]
  miss <- is.na(out)
  out[miss] <- x[miss]
  out
}


#' Are two glyphs the same emoji?
#'
#' `emoji_identical()` compares glyphs element by element and says whether each
#' pair is the same emoji, which means the same code points once the variation
#' selectors `U+FE0F` and `U+FE0E` are set aside. With `details = TRUE` it also
#' says how two glyphs differ: not at all, only in a selector, only in skin
#' tone, or in the emoji itself.
#'
#' The comparison is by code points and nothing else, so it answers for any
#' two strings: two that are not emoji are `identical` when their code points
#' are. `difference` says so. When either side, in its canonical spelling, is
#' not a catalogue spelling, it is `"not one emoji"`, whatever else is true:
#' a grinning face followed by a skin tone (`U+1F600 U+1F3FB`) is a face and
#' a swatch the face cannot take, never a toned variant of the face.
#'
#' @section What this can and cannot tell you:
#' This is the comparison a forensic or legal question needs, and it has a
#' hard limit that belongs here rather than in a footnote. **tidyEmoji can say
#' which code points a message contains and which Unicode version defines
#' them. It cannot say what the sender or the recipient saw.** Rendering is
#' decided by the font and the platform: the same code points draw differently
#' on two phones, an emoji newer than a device's font draws as an empty box or
#' as its separate parts, and a skin-tone sequence can draw as a base emoji
#' beside a colour swatch. No dataset of vendor renderings is available to the
#' package (all eight `vendor_*` columns of the \pkg{emoji} package's table
#' are empty), so nothing here reports one.
#'
#' Two glyphs that are `identical` here can therefore look different to
#' people, and two that are not can look alike. Treat a `TRUE` as "the same
#' characters were sent", never as "the same picture was seen".
#'
#' @param x,y Character vectors of glyphs, the same length or one of them of
#'   length one.
#' @param details If `FALSE` (default), return a logical vector. If `TRUE`,
#'   return a tibble describing each comparison.
#' @return With `details = FALSE`, a logical vector: `TRUE` where the two
#'   glyphs are the same emoji, `NA` where either is `NA`. With
#'   `details = TRUE`, a tibble with columns `x`, `y`, `identical` (the same
#'   vector), `exact` (the code points are identical, selector included),
#'   `difference` (`"none"`, `"variation selector"`, `"skin tone"`,
#'   `"different"` or `"not one emoji"`), and `x_codepoints` and
#'   `y_codepoints`, the two code-point
#'   sequences written out (`"U+2764 U+FE0F"`) for the record.
#' @seealso [as_emoji_canonical()], [emoji_properties()].
#' @examples
#' emoji_identical("\u2764", "\u2764\ufe0f")
#' emoji_identical("\U0001f600", "\U0001f602")
#'
#' emoji_identical(c("\u2764", "\U0001f44d", "\U0001f600"),
#'                 c("\u2764\ufe0f", "\U0001f44d\U0001f3fd", "\U0001f602"),
#'                 details = TRUE)
#' @concept catalogue
#' @export
emoji_identical <- function(x, y, details = FALSE) {
  x <- .emoji_check_glyphs(x, "x")
  y <- .emoji_check_glyphs(y, "y")
  .emoji_check_flag(details, "details")
  nx <- length(x)
  ny <- length(y)
  if (nx != ny && nx != 1L && ny != 1L) {
    stop(sprintf(
      paste0("`x` and `y` must be the same length, or one of them length ",
             "one; they are %d and %d."), nx, ny), call. = FALSE)
  }
  n <- if (nx && ny) max(nx, ny) else 0L
  x <- rep_len(x, n)
  y <- rep_len(y, n)
  kx <- emoji_key(x)
  ky <- emoji_key(y)
  na <- is.na(x) | is.na(y)
  exact <- !na & x == y
  same <- exact | (!is.na(kx) & !is.na(ky) & kx == ky)
  same[na] <- NA
  exact[na] <- NA
  if (!details) return(same)
  tone_x <- emoji_key(.emoji_strip_tones(x))
  tone_y <- emoji_key(.emoji_strip_tones(y))
  difference <- ifelse(
    exact, "none",
    ifelse(same, "variation selector",
           ifelse(!is.na(tone_x) & !is.na(tone_y) & tone_x == tone_y,
                  "skin tone", "different")))
  # Two strings that are not both emoji have no emoji difference to report:
  # 0.6.0 called a grinning face and the same face with a swatch after it a
  # "skin tone" variant, which a face that takes no tone cannot have (N8)
  spellings <- emoji_reference()$emoji
  one <- as_emoji_canonical(x) %in% spellings &
    as_emoji_canonical(y) %in% spellings
  difference[!one] <- "not one emoji"
  difference[na] <- NA_character_
  tibble::tibble(
    x = x,
    y = y,
    identical = same,
    exact = exact,
    difference = difference,
    x_codepoints = .emoji_codepoint_label(x),
    y_codepoints = .emoji_codepoint_label(y)
  )
}


# Keywords per code-point key, cached: {emoji}'s, the union over every
# spelling of the emoji in {emoji}'s order, so the bare and the qualified
# heart carry the same set, then CLDR 49's that {emoji} lacks (0.7.0).
# `source` says which each keyword came from, "github" for {emoji}'s and
# "cldr" for CLDR's, and `folded` holds the sets case-folded, for
# emoji_find().
.emoji_keyword_sets <- function() {
  if (is.null(.tidyEmoji_cache$vocabulary)) {
    ref <- emoji_reference()
    kw <- .emoji_vocabulary_column(ref$emoji, "keywords")
    keys <- unique(ref$key)
    up <- lapply(split(kw, factor(ref$key, levels = keys)), function(l) {
      k <- unique(unlist(l, use.names = FALSE))
      k[!is.na(k) & nzchar(k)]
    })
    cl <- .emoji_vocab$cldr_keywords[keys]
    sets <- Map(function(a, b) {
      b <- b[!is.na(b) & nzchar(b) & !b %in% a]
      c(a, b)
    }, up, cl)
    names(sets) <- keys
    source <- Map(function(a, s) {
      rep(c("github", "cldr"), c(length(a), length(s) - length(a)))
    }, up, sets)
    flat <- unlist(sets, use.names = FALSE)
    folded <- split(.emoji_fold(flat),
                    factor(rep(names(sets), lengths(sets)),
                           levels = names(sets)))
    .tidyEmoji_cache$vocabulary <- list(raw = sets, source = source,
                                        folded = folded)
  }
  .tidyEmoji_cache$vocabulary
}


#' The keywords of each emoji, one row per keyword
#'
#' `emoji_keywords()` returns the CLDR keywords attached to each glyph in long
#' form, one row per (glyph, keyword) pair, which is the shape a join, a count
#' or a word cloud wants. [emoji_search()] reads the same keywords and returns
#' them collapsed into one string per match.
#'
#' @details
#' **These are the English keyword sets**, and nothing in them says anything
#' about how an emoji is read in another language or culture. Multilingual
#' keywords are not bundled.
#'
#' Since 0.7.0 each emoji's set is the union of two sources, and `source` says
#' which a keyword came from: `"github"`, the GitHub-style set the \pkg{emoji}
#' package carried, which every earlier release used and which comes first,
#' unchanged; and `"cldr"`, the keywords of Unicode's CLDR 49 annotations that
#' set lacks. The union only adds: every emoji in the catalogue has keywords
#' now, the 182 of Emoji 17.0 and 18.0 included, which had none, and no
#' keyword an earlier release returned is gone. A string that is not an emoji
#' gets **one row with `keyword = NA`**, never a row with an empty string, so
#' `is.na(keyword)` is the test for "no vocabulary".
#'
#' Keywords belong to the emoji, not to one spelling of it, so the bare and
#' the qualified heart return the same set.
#'
#' @param x A character vector of glyphs. The default, `NULL`, returns every
#'   emoji in the catalogue, each under its canonical spelling.
#' @return A tibble with columns `emoji`, `name`, `keyword` and `source`
#'   (`"github"` or `"cldr"`, `NA` with a `NA` keyword), one row per keyword,
#'   in the order of `x` and then of the keyword set.
#' @seealso [emoji_find()] to go the other way, from keywords to emoji;
#'   [emoji_search()] for a substring search over keywords, names and
#'   shortcodes.
#' @examples
#' emoji_keywords(c("\U0001f389", "\u2764"))
#' @concept vocabulary
#' @export
emoji_keywords <- function(x = NULL) {
  if (is.null(x)) {
    x <- .emoji_by_key()$canonical
  } else {
    x <- .emoji_check_glyphs(x)
  }
  vs <- .emoji_keyword_sets()
  keys <- emoji_key(x)
  pick <- function(sets) lapply(keys, function(k) {
    if (is.na(k)) return(character(0))
    s <- sets[[k]]
    if (is.null(s)) character(0) else s
  })
  kw <- pick(vs$raw)
  src <- pick(vs$source)
  n <- pmax(lengths(kw), 1L)
  flat <- function(l) {
    unlist(lapply(l, function(k) if (length(k)) k else NA_character_),
           use.names = FALSE)
  }
  tibble::tibble(
    emoji = rep(x, n),
    name = rep(as_emoji_name(x), n),
    keyword = as.character(flat(kw)),
    source = as.character(flat(src))
  )
}


#' Which emoji carry these keywords?
#'
#' `emoji_find()` returns the emoji whose CLDR keyword set contains any (or
#' all) of the given terms: "which emoji mean celebration?" in one call. It is
#' the inverse of [emoji_keywords()], and the way to assemble a stimulus set by
#' semantic field.
#'
#' @details
#' A term matches a keyword exactly, ignoring case, so `"celebration"` finds
#' the party popper and `"celebrat"` finds nothing; [emoji_search()] is the
#' substring search, over names and shortcodes as well as keywords. The fold
#' to lower case does not depend on the session's locale.
#'
#' **English only.** The keyword sets are English ones, the \pkg{emoji}
#' package's and CLDR 49's together (see [emoji_keywords()]), so a term in
#' another language matches nothing and an English term says nothing about how
#' the emoji is read elsewhere. Every emoji in the catalogue has keywords, the
#' newest included.
#'
#' @param terms A character vector of keywords to look for. Terms that differ
#'   only in case are one term, reported in the spelling given first. An empty
#'   vector finds nothing; `NA` and `""` are errors.
#' @param match `"any"` (default) to return emoji carrying at least one of the
#'   terms, `"all"` for emoji carrying every one of them.
#' @return A tibble with one row per emoji found, under its canonical
#'   spelling: `emoji`, `name`, `group`, `matched` (the terms it carries,
#'   joined with `", "`, in the order given) and `n_matched`. Rows are sorted
#'   by descending `n_matched`, then in catalogue order. No match gives a typed
#'   zero-row tibble.
#' @seealso [emoji_keywords()], [emoji_search()].
#' @examples
#' emoji_find("celebration")
#' emoji_find(c("cat", "face"), match = "all")
#' @concept vocabulary
#' @export
emoji_find <- function(terms, match = c("any", "all")) {
  match <- .emoji_match_arg(match, c("any", "all"), "match")
  if (!is.character(terms) || anyNA(terms) || !all(nzchar(terms))) {
    stop("`terms` must be a character vector of non-empty keywords.",
         call. = FALSE)
  }
  if (any(Encoding(terms) == "bytes")) {
    stop("`terms` carries \"bytes\" encoding, which R will not read as ",
         "characters. Convert it with iconv() from whatever encoding those ",
         "bytes really are.", call. = FALSE)
  }
  none <- tibble::tibble(emoji = character(), name = character(),
                         group = character(), matched = character(),
                         n_matched = integer())
  # no terms find nothing, as a query that matches nothing does
  if (!length(terms)) return(none)
  # one term per keyword: "cat" and "CAT" are folded first and kept once, in
  # the spelling given first, or one keyword would count twice towards
  # n_matched and satisfy match = "all" on its own
  folded <- .emoji_fold(terms)
  first <- !duplicated(folded)
  terms <- terms[first]
  folded <- folded[first]
  sets <- .emoji_keyword_sets()$folded
  bk <- .emoji_by_key()
  hits <- lapply(bk$key, function(k) {
    s <- sets[[k]]
    if (!length(s)) return(integer(0))
    which(folded %in% s)
  })
  n_hit <- lengths(hits)
  keep <- if (match == "any") n_hit > 0L else n_hit == length(terms)
  if (!any(keep)) return(none)
  idx <- which(keep)
  glyph <- bk$canonical[idx]
  ref <- emoji_reference()
  ri <- match(bk$key[idx], ref$key)
  out <- tibble::tibble(
    emoji = glyph,
    name = ref$name[ri],
    group = ref$group[ri],
    matched = vapply(hits[idx], function(h) paste(terms[h], collapse = ", "),
                     character(1)),
    n_matched = as.integer(n_hit[idx])
  )
  out[order(-out$n_matched, seq_len(nrow(out)), method = "radix"), ,
      drop = FALSE]
}
