# Flags: regional-indicator pairs to ISO 3166-1 codes, tag sequences to
# ISO 3166-2 codes, and back.
#
# The arithmetic is one constant (a regional indicator is its ASCII capital
# plus 127397: U+1F1E6 is 127462, "A" is 65), and it is necessary but not
# sufficient: U+1F1FD U+1F1FD is well formed and spells "XX", which is no
# country. The catalogue's 259 country flags are the valid set, and they are
# bundled anyway, because detection needs them to tell a flag from a stray
# pair (see .emoji_spans()). So the codes come from the arithmetic and the
# validity from the catalogue.

.emoji_ri_offset <- 127397L

# The ten catalogue flags whose code is not an assigned ISO 3166-1 alpha-2
# code: the European Union and the United Nations; seven codes ISO reserves
# for territories it does not list as countries (Ascension Island,
# Clipperton Island, Sark, Diego Garcia, Ceuta and Melilla, the Canary
# Islands, Tristan da Cunha); and Kosovo's XK, a user-assigned code. A test
# derives the same ten from the ISOcodes package, so the list cannot rot.
.emoji_non_iso_flags <- c("AC", "CP", "CQ", "DG", "EA", "EU", "IC", "TA",
                          "UN", "XK")

# The catalogue's country and subdivision flags, cached: glyph, code and
# region name.
.emoji_flag_table <- function() {
  if (is.null(.tidyEmoji_cache$flags)) {
    ref <- emoji_reference()
    country <- ref[ref$subgroup == "country-flag" &
                     ref$status == "fully-qualified", , drop = FALSE]
    sub <- ref[ref$subgroup == "subdivision-flag" &
                 ref$status == "fully-qualified", , drop = FALSE]
    .tidyEmoji_cache$flags <- list(
      country = tibble::tibble(
        emoji = country$emoji,
        code = vapply(country$emoji, .emoji_ri_letters, character(1),
                      USE.NAMES = FALSE),
        name = sub("^flag: ", "", country$name)
      ),
      subdivision = tibble::tibble(
        emoji = sub$emoji,
        code = vapply(sub$emoji, .emoji_tag_code, character(1),
                      USE.NAMES = FALSE),
        name = sub("^flag: ", "", sub$name)
      )
    )
  }
  .tidyEmoji_cache$flags
}

# "US" for U+1F1FA U+1F1F8; NA unless the glyph is exactly two indicators.
.emoji_ri_letters <- function(g) {
  if (is.na(g)) return(NA_character_)
  cp <- suppressWarnings(utf8ToInt(g))
  if (length(cp) != 2L || anyNA(cp) || any(cp < 0x1F1E6 | cp > 0x1F1FF)) {
    return(NA_character_)
  }
  intToUtf8(cp - .emoji_ri_offset)
}

# "GB-SCT" for the black flag, the tags g b s c t, and the cancel tag; NA
# unless the glyph is one well-formed subdivision tag sequence.
.emoji_tag_rx <- paste0("^\\x{1F3F4}([\\x{E0061}-\\x{E007A}]{2})",
                        "([\\x{E0030}-\\x{E0039}\\x{E0061}-\\x{E007A}]{1,4})",
                        "\\x{E007F}$")

.emoji_tag_code <- function(g) {
  if (is.na(g) || !stringi::stri_detect_regex(g, .emoji_tag_rx)) {
    return(NA_character_)
  }
  cp <- utf8ToInt(g)
  tags <- cp[cp >= 0xE0020 & cp <= 0xE007E] - 0xE0000L
  s <- chartr(.emoji_ascii_lower, .emoji_ascii_upper, intToUtf8(tags))
  paste0(substr(s, 1L, 2L), "-", substr(s, 3L, nchar(s)))
}

# One row per span of `text` matched by `keep`, in reading order, carrying the
# columns of `data`: the long shape emoji_tokens() returns.
.emoji_long_spans <- function(data, text, spans) {
  v <- .emoji_text_col(data, {{ text }})
  v[is.na(v)] <- ""
  glyphs <- mapply(.emoji_slice, spans, v, SIMPLIFY = FALSE,
                   USE.NAMES = FALSE)
  out <- .emoji_as_tibble(data)
  out$.emoji <- glyphs
  out <- tidyr::unnest(out, ".emoji")
  out$.emoji <- as.character(out$.emoji)
  out
}


#' Country flags in a text column, as ISO 3166-1 codes
#'
#' `emoji_country()` returns one row per country flag in the text, with the
#' two-letter region code the flag spells and the region's name. A pair of
#' regional indicators that spells no valid flag (`U+1F1FD U+1F1FD` is "XX")
#' is returned too, with its glyph preserved and `NA` for the code, so a
#' stray pair is visible rather than silently dropped.
#'
#' @details
#' A flag emoji is two *regional indicator* symbols, one per letter of a
#' region code, so the code is plain arithmetic on the code points. The
#' arithmetic accepts any pair, though, and only 259 pairs are flags in the
#' catalogue; anything else is reported with `.emoji_iso2 = NA`. That
#' includes a lone indicator, and it includes pairs that a bigger alphabet
#' soup happened to produce: indicators pair up from the start of a run, so
#' `XUS` reads as `XU` and a lone `S`, not as `X` and the United States,
#' which is also how a phone displays it.
#'
#' The code is the join key, not the name, because the code is what other
#' packages take. Hand `.emoji_iso2` to `countrycode::countrycode(x,
#' "iso2c", "country.name")`, or join it to a map's ISO column, and a corpus
#' of flags is a choropleth. Two things to know before you do:
#'
#' * Not every valid flag is a country, and `.emoji_iso3166` says which are
#'   not, so you can filter before a country-level join rather than lose ten
#'   rows in it. Ten of the 259 flags have no assigned ISO 3166-1 code: `EU`
#'   (European Union) and `UN` (United Nations); `AC` (Ascension Island),
#'   `CP` (Clipperton Island), `CQ` (Sark), `DG` (Diego Garcia), `EA` (Ceuta
#'   and Melilla), `IC` (Canary Islands) and `TA` (Tristan da Cunha), codes
#'   ISO reserves for territories it does not list as countries; and `XK`
#'   (Kosovo), a user-assigned code that ISO does not define. A country-level
#'   tool will not map them.
#' * `.emoji_country_name` is the Unicode (CLDR) English name, kept for
#'   reading the output, and it changes between Unicode versions: three
#'   names did between Emoji 16.0 and 18.0. Join on the code.
#'
#' Subdivision flags such as Scotland's are tag sequences rather than
#' indicator pairs; see [emoji_subdivision()].
#'
#' @inheritParams emoji_summary
#' @return A tibble with the columns of `data` plus `.emoji` (the flag as it
#'   appears in the text), `.emoji_iso2` (the two-letter code, `NA` for a
#'   pair that spells no flag), `.emoji_country_name` and `.emoji_iso3166`
#'   (`TRUE` where the code is an assigned ISO 3166-1 alpha-2 code, `FALSE`
#'   for the ten above, `NA` for a pair that spells no flag). One row per flag,
#'   in reading order; rows without one are dropped. A grouped input stays
#'   grouped, as it does through [emoji_tokens()].
#' @seealso [emoji_flag()] to convert between codes and flags,
#'   [emoji_subdivision()] for England, Scotland and Wales.
#' @examples
#' df <- data.frame(id = 1:3,
#'                  text = c("go \U0001f1fa\U0001f1f8 and \U0001f1ef\U0001f1f5",
#'                           "no flags here",
#'                           "stray \U0001f1fd\U0001f1fd pair"))
#' emoji_country(df, text)
#' @concept flags
#' @export
emoji_country <- function(data, text) {
  v <- .emoji_text_col(data, {{ text }})
  sp <- .emoji_spans(v)
  ri_only <- "^[\\x{1F1E6}-\\x{1F1FF}]+$"
  keep <- lapply(seq_along(v), function(i) {
    m <- sp$locs[[i]]
    if (!nrow(m)) return(m)
    k <- sp$kinds[[i]]
    if (!is.null(k)) {
      # The flags every counting verb counts, read the way they read them: a
      # ZWJ sequence Unicode does not recommend counts as its parts, so two
      # flags a joiner stands between are two flags. Read as one span they
      # matched no flag shape and dropped out of this verb altogether while
      # emoji_frequency() counted both. The stray indicators the counting
      # verbs set aside are kept, as before, to be reported with an NA code.
      m <- rbind(.emoji_counted(sp, i)$m,
                 m[k == .emoji_kind_flag, , drop = FALSE])
      m <- m[order(m[, "start"], method = "radix"), , drop = FALSE]
    }
    g <- .emoji_slice(m, if (is.na(v[[i]])) "" else v[[i]])
    m[stringi::stri_detect_regex(g, ri_only), , drop = FALSE]
  })
  out <- .emoji_long_spans(data, {{ text }}, keep)
  ft <- .emoji_flag_table()$country
  idx <- match(out$.emoji, ft$emoji)
  out$.emoji_iso2 <- ft$code[idx]
  out$.emoji_country_name <- ft$name[idx]
  out$.emoji_iso3166 <- !out$.emoji_iso2 %in% .emoji_non_iso_flags
  out$.emoji_iso3166[is.na(out$.emoji_iso2)] <- NA
  out
}


#' Subdivision flags in a text column, as ISO 3166-2 codes
#'
#' `emoji_subdivision()` returns one row per subdivision flag in the text
#' (the flags of England, Scotland and Wales, and any other tag sequence of
#' the same shape), with the code its tag characters spell (`"GB-SCT"`) and,
#' for the three Unicode recommends, the name.
#'
#' @details
#' A subdivision flag is not a regional-indicator pair. It is a black flag
#' (`U+1F3F4`) followed by invisible tag characters spelling a subdivision
#' code in lower case, and a cancel tag (`U+E007F`): Scotland is the black
#' flag, then `g b s c t`, then the cancel tag. The code is therefore read
#' straight off the tags, for any well-formed sequence.
#'
#' Only three such sequences are in the catalogue, `GB-ENG`, `GB-SCT` and
#' `GB-WLS`, and only those three are emoji the other verbs count. Any other
#' (`US-TX` spelled the same way, say) is valid Unicode that no major
#' platform draws as a flag, so it is reported here with its code and
#' `NA` for the name, while [emoji_frequency()] and the rest see only the
#' black flag at its start. That is the honest answer to a question the text
#' does not settle: the sender typed a Texas flag and the reader most likely
#' saw a black one.
#'
#' @inheritParams emoji_summary
#' @return A tibble with the columns of `data` plus `.emoji` (the whole tag
#'   sequence), `.emoji_subdivision` (the ISO 3166-2 code its tags spell) and
#'   `.emoji_subdivision_name` (the Unicode name for the three in the
#'   catalogue, `NA` otherwise). One row per sequence, in reading order; rows
#'   without one are dropped.
#' @seealso [emoji_country()] for country flags; [emoji_flag()] to convert.
#' @examples
#' scotland <- intToUtf8(c(0x1F3F4, 0xE0067, 0xE0062, 0xE0073, 0xE0063,
#'                         0xE0074, 0xE007F))
#' df <- data.frame(text = c(paste("go", scotland), "none"))
#' emoji_subdivision(df, text)
#' @concept flags
#' @export
emoji_subdivision <- function(data, text) {
  v <- .emoji_text_col(data, {{ text }})
  w <- v
  w[is.na(w)] <- ""
  rx <- paste0("\\x{1F3F4}[\\x{E0061}-\\x{E007A}]{2}",
               "[\\x{E0030}-\\x{E0039}\\x{E0061}-\\x{E007A}]{1,4}\\x{E007F}")
  spans <- stringi::stri_locate_all_regex(w, rx, omit_no_match = TRUE)
  out <- .emoji_long_spans(data, {{ text }}, spans)
  out$.emoji_subdivision <- vapply(out$.emoji, .emoji_tag_code, character(1),
                                   USE.NAMES = FALSE)
  ft <- .emoji_flag_table()$subdivision
  out$.emoji_subdivision_name <- ft$name[match(out$.emoji, ft$emoji)]
  out
}


#' Convert between flag emoji and region codes
#'
#' `emoji_flag()` turns a region code into its flag and a flag into its code,
#' element by element: `"JP"` becomes the Japanese flag, the Japanese flag
#' becomes `"JP"`, and `"GB-SCT"` and Scotland's flag convert the same way.
#' Codes are matched without regard to case.
#'
#' @details
#' Each element is converted in its own direction, so one call can carry
#' both. A code or a flag outside the catalogue's valid set, such as `"XX"`,
#' `"UK"` (the code is `GB`) or a stray indicator pair, gives `NA` rather than a
#' made-up flag. The valid set is the 259 country flags and three subdivision
#' flags of the catalogue [emoji_unicode_version()] reports; see
#' [emoji_country()] for which of the 259 are not countries.
#'
#' @param x A character vector of two-letter region codes, ISO 3166-2
#'   subdivision codes (`"GB-ENG"`, `"GB-SCT"`, `"GB-WLS"`), or flag emoji.
#' @return A character vector the same length as `x`: flags where `x` held
#'   codes, codes where it held flags, and `NA` for anything that is neither.
#' @seealso [emoji_country()], [emoji_subdivision()].
#' @examples
#' emoji_flag(c("JP", "fr", "GB-SCT", "XX"))
#' emoji_flag(emoji_flag(c("JP", "fr")))
#' @concept flags
#' @export
emoji_flag <- function(x) {
  # its main input is codes, so the message names both (N6)
  x <- .emoji_check_glyphs(
    x, what = "region codes (\"US\", \"GB-SCT\") or flag emoji")
  ft <- .emoji_flag_table()
  glyphs <- c(ft$country$emoji, ft$subdivision$emoji)
  codes <- c(ft$country$code, ft$subdivision$code)
  out <- codes[match(x, glyphs)]
  todo <- is.na(out) & !is.na(x)
  # chartr() rather than toupper(): codes are ASCII, and toupper() is the
  # locale-dependent fold the package refuses everywhere else
  up <- chartr(.emoji_ascii_lower, .emoji_ascii_upper, trimws(x[todo]))
  out[todo] <- glyphs[match(up, codes)]
  out
}
