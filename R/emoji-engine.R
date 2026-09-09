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
    # emoji::emojis records the introducing version on the *unqualified* member
    # of a variation pair and leaves it NA on the fully-qualified one, so 1252
    # of 5042 rows -- including everyday glyphs like U+2764 U+FE0F -- arrived
    # with no version at all and emoji_version_profile() filed them as unknown.
    # The version belongs to the emoji, not to one spelling of it, so fill it
    # within each codepoint key. min() is the first version any spelling became
    # available, which is what "introduced in" means; no key currently holds two
    # different versions, so this only ever fills gaps.
    ref$version <- .emoji_fill_by_key(ref$version, ref$key)
    .tidyEmoji_cache$reference <- ref
    # Whatever is derived from the reference is now stale by construction, so
    # drop it here rather than leaving each consumer to notice. `ref_keys` is
    # the one that matters: the ZWJ repair tests membership in it, so a stale
    # copy changes *detection*, not just metadata. Owning the invalidation in
    # the one function that writes `reference` is what keeps the three slots
    # from drifting apart as more derived caches are added.
    .emoji_drop_derived_caches()
  }
  .tidyEmoji_cache$reference
}

# The cache slots computed *from* `reference`, in one place. Anything added
# later that derives from the reference table belongs in this vector.
.emoji_derived_cache_slots <- function() c("ref_keys", "type")

.emoji_drop_derived_caches <- function() {
  for (slot in .emoji_derived_cache_slots()) {
    .tidyEmoji_cache[[slot]] <- NULL
  }
  invisible(NULL)
}

# Fill NA entries of a per-glyph attribute from other rows sharing the same
# codepoint key. Used for `version`, which the upstream table attaches to only
# one spelling of a variation pair.
.emoji_fill_by_key <- function(x, key) {
  # .emoji_version_num(), not as.numeric(): every consumer strips a leading
  # "E" first, because "E17.0" is the spelling Unicode's own emoji-data.txt
  # uses. With a bare as.numeric() an upstream release carrying that spelling
  # would make every entry NA, so `first` would be all-NA, `take` all-FALSE,
  # and this fill would silently no-op -- putting back the 1252 rows with no
  # version that it exists to remove.
  num <- .emoji_version_num(x)
  if (!anyNA(num)) return(x)
  first <- vapply(
    split(num, key),
    function(v) if (all(is.na(v))) NA_real_ else min(v, na.rm = TRUE),
    numeric(1)
  )
  filled <- first[key]
  out <- x
  take <- is.na(out) & !is.na(filled)
  # write back in the column's own representation, matching an existing row so
  # "12.1" stays "12.1" rather than becoming "12.100000"
  lookup <- x[!is.na(num)]
  lookup_num <- num[!is.na(num)]
  out[take] <- lookup[match(filled[take], lookup_num)]
  out
}

# Locale-independent lower-casing for matching.
#
# `tolower()` honours LC_CTYPE, and under a Turkish or Azerbaijani locale it
# maps "I" to a dotless i (U+0131) rather than "i". Every case-insensitive
# comparison in the package folds a query and an ASCII target, so that rule made
# emoji_search("FIRE") return 0 rows instead of 27, and let emoji_collocations()
# count "BIG" and "big" as different words -- results that changed with the
# session locale rather than the data.
#
# chartr() settles A-Z deterministically before tolower() can apply any locale
# rule. tolower() alone is locale-dependent twice over, though, and the second
# way was missed until 0.4.0: besides the Turkish dotless i, tolower() leaves
# every non-ASCII letter untouched in a non-UTF-8 locale. The catalogue carries
# 24 names with an uppercase accented letter -- "flag: Aland Islands", "flag:
# Curacao", "flag: Cote d'Ivoire" and the rest, spelled with the accents -- so
# emoji_search() matched a lowercase query against them in a UTF-8 session and
# returned nothing at all under LC_ALL=C.
#
# chartr() is a plain code-point substitution and is subject to neither rule,
# so the fold is driven from an explicit table: A-Z, then the cased Latin
# letters of the Latin-1 Supplement and Latin Extended-A/-B. Only 1:1 pairs are
# listed -- an uppercase code point whose lowercase form is a single, different
# code point -- which is what makes the result byte-identical to tolower() in a
# UTF-8 locale rather than a new folding of its own; the C locale merely catches
# up. Verified over all 5042 names, 10701 keywords and 5761 aliases. The
# trailing tolower() still runs, for anything the table does not name.
.emoji_ascii_upper <- "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
.emoji_ascii_lower <- "abcdefghijklmnopqrstuvwxyz"

# Written as code points so this file stays pure ASCII, as CRAN prefers.
.emoji_latin_upper <- intToUtf8(c(
  0x00C0,0x00C1,0x00C2,0x00C3,0x00C4,0x00C5,0x00C6,0x00C7,0x00C8,0x00C9,
  0x00CA,0x00CB,0x00CC,0x00CD,0x00CE,0x00CF,0x00D0,0x00D1,0x00D2,0x00D3,
  0x00D4,0x00D5,0x00D6,0x00D8,0x00D9,0x00DA,0x00DB,0x00DC,0x00DD,0x00DE,
  0x0100,0x0102,0x0104,0x0106,0x0108,0x010A,0x010C,0x010E,0x0110,0x0112,
  0x0114,0x0116,0x0118,0x011A,0x011C,0x011E,0x0120,0x0122,0x0124,0x0126,
  0x0128,0x012A,0x012C,0x012E,0x0130,0x0132,0x0134,0x0136,0x0139,0x013B,
  0x013D,0x013F,0x0141,0x0143,0x0145,0x0147,0x014A,0x014C,0x014E,0x0150,
  0x0152,0x0154,0x0156,0x0158,0x015A,0x015C,0x015E,0x0160,0x0162,0x0164,
  0x0166,0x0168,0x016A,0x016C,0x016E,0x0170,0x0172,0x0174,0x0176,0x0178,
  0x0179,0x017B,0x017D,0x0181,0x0182,0x0184,0x0186,0x0187,0x0189,0x018A,
  0x018B,0x018E,0x018F,0x0190,0x0191,0x0193,0x0194,0x0196,0x0197,0x0198,
  0x019C,0x019D,0x019F,0x01A0,0x01A2,0x01A4,0x01A6,0x01A7,0x01A9,0x01AC,
  0x01AE,0x01AF,0x01B1,0x01B2,0x01B3,0x01B5,0x01B7,0x01B8,0x01BC,0x01C4,
  0x01C5,0x01C7,0x01C8,0x01CA,0x01CB,0x01CD,0x01CF,0x01D1,0x01D3,0x01D5,
  0x01D7,0x01D9,0x01DB,0x01DE,0x01E0,0x01E2,0x01E4,0x01E6,0x01E8,0x01EA,
  0x01EC,0x01EE,0x01F1,0x01F2,0x01F4,0x01F6,0x01F7,0x01F8,0x01FA,0x01FC,
  0x01FE,0x0200,0x0202,0x0204,0x0206,0x0208,0x020A,0x020C,0x020E,0x0210,
  0x0212,0x0214,0x0216,0x0218,0x021A,0x021C,0x021E,0x0220,0x0222,0x0224,
  0x0226,0x0228,0x022A,0x022C,0x022E,0x0230,0x0232,0x023A,0x023B,0x023D,
  0x023E,0x0241,0x0243,0x0244,0x0245,0x0246,0x0248,0x024A,0x024C,0x024E
))
.emoji_latin_lower <- intToUtf8(c(
  0x00E0,0x00E1,0x00E2,0x00E3,0x00E4,0x00E5,0x00E6,0x00E7,0x00E8,0x00E9,
  0x00EA,0x00EB,0x00EC,0x00ED,0x00EE,0x00EF,0x00F0,0x00F1,0x00F2,0x00F3,
  0x00F4,0x00F5,0x00F6,0x00F8,0x00F9,0x00FA,0x00FB,0x00FC,0x00FD,0x00FE,
  0x0101,0x0103,0x0105,0x0107,0x0109,0x010B,0x010D,0x010F,0x0111,0x0113,
  0x0115,0x0117,0x0119,0x011B,0x011D,0x011F,0x0121,0x0123,0x0125,0x0127,
  0x0129,0x012B,0x012D,0x012F,0x0069,0x0133,0x0135,0x0137,0x013A,0x013C,
  0x013E,0x0140,0x0142,0x0144,0x0146,0x0148,0x014B,0x014D,0x014F,0x0151,
  0x0153,0x0155,0x0157,0x0159,0x015B,0x015D,0x015F,0x0161,0x0163,0x0165,
  0x0167,0x0169,0x016B,0x016D,0x016F,0x0171,0x0173,0x0175,0x0177,0x00FF,
  0x017A,0x017C,0x017E,0x0253,0x0183,0x0185,0x0254,0x0188,0x0256,0x0257,
  0x018C,0x01DD,0x0259,0x025B,0x0192,0x0260,0x0263,0x0269,0x0268,0x0199,
  0x026F,0x0272,0x0275,0x01A1,0x01A3,0x01A5,0x0280,0x01A8,0x0283,0x01AD,
  0x0288,0x01B0,0x028A,0x028B,0x01B4,0x01B6,0x0292,0x01B9,0x01BD,0x01C6,
  0x01C6,0x01C9,0x01C9,0x01CC,0x01CC,0x01CE,0x01D0,0x01D2,0x01D4,0x01D6,
  0x01D8,0x01DA,0x01DC,0x01DF,0x01E1,0x01E3,0x01E5,0x01E7,0x01E9,0x01EB,
  0x01ED,0x01EF,0x01F3,0x01F3,0x01F5,0x0195,0x01BF,0x01F9,0x01FB,0x01FD,
  0x01FF,0x0201,0x0203,0x0205,0x0207,0x0209,0x020B,0x020D,0x020F,0x0211,
  0x0213,0x0215,0x0217,0x0219,0x021B,0x021D,0x021F,0x019E,0x0223,0x0225,
  0x0227,0x0229,0x022B,0x022D,0x022F,0x0231,0x0233,0x2C65,0x023C,0x019A,
  0x2C66,0x0242,0x0180,0x0289,0x028C,0x0247,0x0249,0x024B,0x024D,0x024F
))

.emoji_fold_upper <- paste0(.emoji_ascii_upper, .emoji_latin_upper)
.emoji_fold_lower <- paste0(.emoji_ascii_lower, .emoji_latin_lower)

.emoji_fold <- function(x) {
  tolower(chartr(.emoji_fold_upper, .emoji_fold_lower, x))
}

# Whitespace, as an explicit set rather than "\\s" or "[[:space:]]".
#
# Both of those resolve through the C library's iswspace(), which depends on
# the locale and on the platform's character tables. Under LC_ALL=C they match
# nothing but ASCII, so emoji_ratio()'s `.emoji_only` -- documented as "the
# text contains emoji and nothing else but whitespace" -- answered TRUE for an
# emoji followed by an ideographic space in a UTF-8 session and FALSE for the
# same string in a C one. That is the same defect as the fold above: a
# documented, user-visible answer that changes with the session rather than
# with the data, and CRAN checks on flavours whose iswspace() need not agree
# with glibc's.
#
# The set below is Unicode's White_Space property, written out. It also
# settles a second inconsistency glibc had left: U+00A0 and U+202F, the two
# no-break spaces, were the only White_Space characters iswspace() rejected,
# so U+3000 counted as whitespace and U+00A0 did not. Both count now. U+200B
# (zero-width space) is deliberately absent -- despite the name, Unicode does
# not give it White_Space.
.emoji_ws_cps <- c(0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x20, 0x85, 0xA0, 0x1680,
                   0x2000:0x200A, 0x2028, 0x2029, 0x202F, 0x205F, 0x3000)
.emoji_ws_class <- paste0(
  "[", paste(intToUtf8(.emoji_ws_cps, multiple = TRUE), collapse = ""), "]")
.emoji_ws1 <- .emoji_ws_class                       # exactly one
.emoji_ws  <- paste0(.emoji_ws_class, "+")          # a run

# trimws() is already deterministic -- it defaults to an explicit ASCII class,
# not to iswspace() -- but it therefore trims less than the package now counts
# as whitespace, so give it the same set.
.emoji_trimws <- function(x, which = "both") {
  trimws(x, which = which, whitespace = .emoji_ws)
}

# Codepoint key used to join emoji robustly across qualified / unqualified
# forms: the emoji variation selector U+FE0F is dropped so that, for example,
# the qualified heart (U+2764 U+FE0F) matches the lexicon's unqualified
# U+2764.
emoji_key <- function(glyphs) {
  # as.character() first, like as_emoji_name() and emoji_ambiguity() already
  # do. Without it a factor glyph column reached nzchar() -- "'nzchar()'
  # requires a character vector" -- and a numeric one reached utf8ToInt(),
  # neither message naming the argument, the column or the verb. Both are
  # reachable from a user lexicon through `by =`.
  glyphs <- as.character(glyphs)
  vapply(glyphs, function(g) {
    if (is.na(g) || !nzchar(g)) return(NA_character_)
    # utf8ToInt() answers NA_integer_ for a string that is not valid UTF-8,
    # and NA != 0xFE0F is NA, so the filter below kept it and sprintf("%X", NA)
    # turned it into the literal key "NA" -- a real key that every undecodable
    # value collided on, and that consumers read as present rather than
    # missing.
    cp <- suppressWarnings(utf8ToInt(g))
    if (anyNA(cp)) return(NA_character_)
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
    # Both loops must only ever *grow* the span. `a:b` in R counts downwards
    # when b < a, and rule 1 above merges arbitrarily long ZWJ chains, so a
    # match longer than .emoji_max_cp is reachable: the forward sequence then
    # ran backwards over spans strictly inside the current match and, because
    # `best <- e` fires on every hit while descending, the shortest match won
    # and `b` moved *left*. A 12-code-point kiss-sequence chain lost its
    # trailing ZWJ + grinning face that way. The backward loop mirrored it.
    # Compute the bound first and skip the loop when it does not extend.
    if (b < hi && cps[b + 1L] == .emoji_zwj) {
      hi_e <- min(hi, a + .emoji_max_cp - 1L)
      if (hi_e >= b + 1L) {
        best <- b
        for (e in (b + 1L):hi_e) {
          if (emoji_key(substring(s, a, e)) %in% keys) best <- e
        }
        b <- best
      }
    }
    if (a > lo && cps[a - 1L] == .emoji_zwj) {
      lo_p <- max(lo, b - .emoji_max_cp + 1L)
      if (lo_p <= a - 1L) {
        best <- a
        for (p in (a - 1L):lo_p) {
          if (emoji_key(substring(s, p, b)) %in% keys) best <- p
        }
        a <- best
      }
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

# Above this many spans in one string, index code points instead of taking
# character substrings. `substring()` and `substr()` rescan a multi-byte string
# from its first byte to reach a character offset, so slicing m spans out of a
# length-L string costs O(m * L) -- quadratic, and this runs in nearly every
# verb. Converting to code points once is linear but carries a fixed cost, so
# below the threshold the substring path is still the faster of the two
# (measured crossover is a few hundred spans on a 45k-character row).
.emoji_cp_threshold <- 512L

# Slice the glyphs of one string out of its start/end matrix.
#
# Ordinary rows hold a handful of glyphs and stay on `substring()`, byte for
# byte the behaviour every other verb was built against. Emoji-dense rows take
# the code-point path; `anyNA()` sends anything `utf8ToInt()` cannot represent
# (a latin1- or bytes-marked string) back to `substring()`, so the two paths
# cannot disagree.
.emoji_slice <- function(m, s) {
  if (!nrow(m)) return(character(0))
  if (nrow(m) >= .emoji_cp_threshold) {
    cp <- tryCatch(utf8ToInt(s), error = function(e) NA_integer_)
    if (!anyNA(cp)) {
      st <- m[, "start"]
      en <- m[, "end"]
      return(vapply(seq_along(st),
                    function(i) intToUtf8(cp[st[i]:en[i]]), character(1)))
    }
  }
  substring(s, m[, "start"], m[, "end"])
}

# The nrow(m) + 1 stretches of `s` lying *outside* the emoji spans in `m`, in
# order: before the first glyph, between each adjacent pair, and after the
# last. Three verbs need the non-emoji text and each used to cut it out with
# its own substr() loop -- the translation verbs splice replacements between
# these stretches, emoji_ratio() concatenates them to test whether anything but
# emoji remains, and emoji_incongruity() walks back over the trailing ones
# looking for whitespace. Cutting the string happens here instead, once.
#
# `gaps[i]` for i >= 2 is the text between glyph i - 1 and glyph i, so a
# consumer indexing glyph pairs and one indexing the tail agree by
# construction. Same threshold reasoning as .emoji_slice(): m one-at-a-time
# substr() calls cost O(m * L), so past .emoji_cp_threshold convert once and
# slice code points, and fall back whenever utf8ToInt() cannot represent the
# string.
.emoji_gaps <- function(s, m) {
  n <- nrow(m)
  if (!n) return(s)
  starts <- c(1L, m[, "end"] + 1L)
  ends <- c(m[, "start"] - 1L, NA_integer_)
  cp <- if (n >= .emoji_cp_threshold) {
    tryCatch(utf8ToInt(s), error = function(e) NA_integer_)
  } else {
    NA_integer_
  }
  if (anyNA(cp)) {
    ends[n + 1L] <- nchar(s)
    return(substring(s, starts, ends))
  }
  ends[n + 1L] <- length(cp)
  vapply(seq_len(n + 1L),
         function(i) if (starts[i] > ends[i]) "" else {
           intToUtf8(cp[starts[i]:ends[i]])
         },
         character(1))
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
# `arg` is the name the *user* typed. This helper serves two callers with
# different argument names -- register_emoji_lexicon(tbl = ) and
# emoji_score() / emoji_sentiment() / emoji_emotion()'s `lexicon = ` -- and it
# used to say "`tbl`" to both, so a user who passed a data frame as `lexicon`
# was told to fix an argument that function does not have. Same failure mode
# the column resolver's `arg` was added for.
# Two rows can legitimately share a code-point key -- a lexicon listing both
# the unqualified and the U+FE0F-qualified spelling of one emoji canonicalises
# to one key -- but only if they agree. When they disagree the lookup silently
# takes whichever came first, so swapping two rows of the caller's own table
# changes the answer. `values` is the score vector (the sentiment path) or the
# matrix of emotion columns (the emotion path); both are checked the same way,
# row against row, ignoring NA. Neither bundled lexicon has a duplicated key.
.emoji_check_dup_keys <- function(keys, values, arg) {
  keep <- !is.na(keys) & nzchar(keys)
  kk <- keys[keep]
  dk <- unique(kk[duplicated(kk)])
  if (!length(dk)) return(invisible(NULL))
  vv <- if (is.matrix(values)) values[keep, , drop = FALSE] else values[keep]
  disagrees <- function(k) {
    if (is.matrix(vv)) {
      rows <- vv[kk == k, , drop = FALSE]
      any(vapply(seq_len(ncol(rows)), function(j) {
        v <- rows[, j]
        length(unique(v[!is.na(v)])) > 1L
      }, logical(1)))
    } else {
      v <- vv[kk == k]
      length(unique(v[!is.na(v)])) > 1L
    }
  }
  bad <- dk[vapply(dk, disagrees, logical(1))]
  if (length(bad)) {
    stop(sprintf(
      paste0("`%s` gives %d emoji more than one score: %s. Spellings that ",
             "differ only by a variation selector share one code-point key, ",
             "so two such rows must agree. Reading either one is a choice ",
             "the row order would be making, not you -- collapse them ",
             "first (one row per emoji_key())."),
      arg, length(bad),
      paste(sprintf("`%s`", utils::head(bad, 3L)), collapse = ", ")
    ), call. = FALSE)
  }
  invisible(NULL)
}

.emoji_lexicon_record <- function(tbl, by = "emoji", score = NULL,
                                  arg = "tbl") {
  if (!is.data.frame(tbl)) {
    stop(sprintf("`%s` must be a data frame.", arg), call. = FALSE)
  }
  keys <- .emoji_lexicon_keys(tbl, by, arg = arg)
  if (is.null(score)) {
    # heuristic: prefer 'sentiment_score', then 'score'
    score <- intersect(c("sentiment_score", "score"), names(tbl))[1L]
    if (is.na(score)) {
      # An emotion-shaped table is the one case where "supply `score`" is a
      # dead end: `score` names a single column, and a user with eight
      # emotion columns wants their mean -- which emoji_score() computes only
      # for the bundled "emotag1200". Say where to go instead.
      emo <- intersect(emoji_emotion_dims(), names(tbl))
      if (length(emo)) {
        stop(sprintf(paste0(
          "`%s` has no score column, but it does carry emotion columns ",
          "(%s). emoji_score() averages emotion dimensions only for the ",
          "bundled \"emotag1200\"; use emoji_emotion() for the per-emotion ",
          "profile of a lexicon like this, or `score = \"%s\"` to score on ",
          "one dimension."),
          arg, paste(emo, collapse = ", "), emo[1L]), call. = FALSE)
      }
      stop(sprintf("`%s` has no score column; supply `score`.", arg),
           call. = FALSE)
    }
  }
  if (!score %in% names(tbl)) {
    stop(sprintf("`%s` has no column `%s` to take the score from.",
                 arg, score), call. = FALSE)
  }
  s <- tbl[[score]]
  # The presence of a score column was checked above; its *type* was not, and
  # the two failures that let through are both silent. A character or factor
  # column reaches mean() untouched, which returns NA with R's own "argument
  # is not numeric or logical" warning -- while `.emoji_n_scored` still counts
  # the emoji as scored, so the row claims a score it does not have. A
  # genuinely NA numeric score is counted as unscored, which is the contract
  # this restores.
  if (!is.numeric(s) && !is.logical(s)) {
    stop(sprintf(
      paste0("`%s`'s score column `%s` is %s, and a score has to be a ",
             "number. Coercing it here would report the emoji as scored ",
             "while every score came back `NA`. Convert the column first, ",
             "and check what made it non-numeric -- a stray \"NA\" or a ",
             "decimal comma turns a whole column into text."),
      arg, score, class(s)[1L]
    ), call. = FALSE)
  }
  keep <- !is.na(keys) & keys != ""
  .emoji_check_dup_keys(keys, s, arg)
  out <- stats::setNames(s, keys)
  out[keep]
}

# Normalised join keys for a lexicon table: prefer the glyph column `by`, and
# fall back to a pre-computed `key` column (as stored by
# register_emoji_lexicon()) so registered lexicons resolve regardless of what
# their glyph column was called.
.emoji_lexicon_keys <- function(tbl, by = "emoji", arg = "tbl") {
  # `by` reaches `%in%` below, so a vector turned the guard into a length-2
  # condition and R reported "the condition has length > 1" -- its message,
  # naming neither this argument nor the verb the user called.
  .emoji_check_string(by, "by")
  if (by %in% names(tbl)) {
    emoji_key(tbl[[by]])
  } else if ("key" %in% names(tbl)) {
    as.character(tbl[["key"]])
  } else {
    stop(sprintf("`%s` has no column `%s` to map glyphs from.", arg, by),
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
  if (!is.character(lexicon) || length(lexicon) != 1L || is.na(lexicon)) {
    # The message used to offer "or NULL for the default", which this very
    # guard rejects -- is.character(NULL) is FALSE -- and which no verb
    # accepts or documents. Describe what is actually taken, and name what
    # was passed, since a lexicon argument is easy to fill from a variable
    # that turned out empty.
    stop(sprintf(
      paste0("`lexicon` must be a single lexicon name or a data frame, not ",
             "%s. See emoji_lexicons() for the names."),
      if (is.null(lexicon)) "NULL" else
        sprintf("%s of length %d", class(lexicon)[1L], length(lexicon))
    ), call. = FALSE)
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
# The tail of the missing-column message: "exist. Available: `a`, `b`." --
# truncated, because the list is the caller's data and can be long. A
# 500-column frame gave a 5074-character error, and even a 40-column survey
# export gave 665, burying the one thing that matters (the name that is
# wrong) behind a wall of names that are not. A frame with no columns at all
# used to end "Available: ." on its own.
.emoji_available_cols <- function(nms, max_show = 5L) {
  if (!length(nms)) {
    return("exist -- `data` has no columns.")
  }
  shown <- paste(sprintf("`%s`", utils::head(nms, max_show)), collapse = ", ")
  extra <- length(nms) - min(length(nms), max_show)
  sprintf("exist. Available: %s%s.", shown,
          if (extra > 0L) sprintf(", and %d more", extra) else "")
}

.emoji_col_name <- function(data, col, arg = "text") {
  if (rlang::quo_is_missing(rlang::enquo(col))) {
    stop(sprintf(
      "`%s` is required: give the unquoted name of the column to use.", arg
    ), call. = FALSE)
  }
  if (!is.data.frame(data)) {
    stop("`data` must be a data frame.", call. = FALSE)
  }
  # A bare column name is resolved against names(data) directly, without
  # dplyr::select(). Two reasons, and the first is a correctness one.
  #
  # tidyselect falls back to an *external vector* of the same name when the
  # column is absent, and `text` is a common variable name. So
  # `emoji_sentiment(df, text)` on a data frame whose column had been renamed,
  # in a session where `text` also happened to be a character vector, reported
  # "Can't select columns that don't exist. Columns `global value` and ..." --
  # naming the contents of the caller's variable as though they were column
  # names -- and added a tidyselect deprecation warning advising `all_of()`,
  # which is not what the caller meant at all. That is the same failure mode as
  # the `var` message this helper was written to replace.
  #
  # The second is that this is the hot path: nearly every call names a bare
  # column, and dplyr::select() costs about a millisecond.
  #
  # Anything that is not a bare symbol -- a string, a position, `all_of()`,
  # `starts_with()` -- still goes to select(), so every tidyselect form works
  # and a selection of two columns is still reported as one.
  q <- rlang::enquo(col)
  expr <- rlang::quo_get_expr(q)
  if (rlang::is_symbol(expr)) {
    # (.emoji_available_cols() builds the tail of the message; see below)
    nm <- rlang::as_name(expr)
    hits <- which(names(data) == nm)
    if (!length(hits)) {
      stop(sprintf("`%s` must name a column of `data`, and `%s` does not %s",
                   arg, nm, .emoji_available_cols(names(data))),
           call. = FALSE)
    }
    # `nm %in% names(data)` is not enough: a base data frame built with
    # check.names = FALSE can carry the same name twice -- a spreadsheet with
    # repeated headers read by read.csv() does exactly that -- and `[[`
    # silently returns the first. dplyr::select(), which this path replaced,
    # rejected the ambiguity, and without this check emoji_summary() and
    # emoji_frequency() answered from whichever column came first while the
    # verbs that convert `data` to a tibble failed with tibble's own message.
    if (length(hits) > 1L) {
      stop(sprintf(
        paste0("`%s` matches %d columns named `%s`, so which one to read is ",
               "ambiguous. Give the columns distinct names -- read.csv() ",
               "does that for you without `check.names = FALSE`."),
        arg, length(hits), nm
      ), call. = FALSE)
    }
    return(nm)
  }
  nm <- names(dplyr::select(dplyr::ungroup(data), !!q))
  if (length(nm) != 1L) {
    stop(sprintf("`%s` must select exactly one column, not %d.",
                 arg, length(nm)), call. = FALSE)
  }
  nm
}

# The column itself, with its type intact (the time verbs need Date / POSIXct
# to survive). `[[` rather than dplyr::pull() so grouped input needs no special
# case.
#
# One value per row, checked here so every column argument gets it -- `text`,
# `time`, `doc_id` and `text_score` all come through this helper. A matrix
# column holds one element per *cell*, and nothing downstream noticed: a 2x2
# character `time` gave `emoji_trend()` and `emoji_adoption_lag()`
# "invalid 'times' argument", `emoji_seasonality()` "missing value where
# TRUE/FALSE needed", and `emoji_turnover()` a *result*, computed over periods
# that were not in the data. A 2x2 `doc_id` made `emoji_dfm()` report four
# documents for two rows. A 2x2 `text_score` passed the `is.numeric()` guard --
# a matrix is numeric -- and reached tibble as
# "Assigned data `gap` must be compatible with existing data".
#
# length() is right for every type the package accepts, POSIXlt included: R
# gives it a length method that counts times, not list components.
.emoji_col <- function(data, col, arg = "text") {
  nm <- .emoji_col_name(data, {{ col }}, arg = arg)
  v <- data[[nm]]
  # The same deparse hazard .emoji_text_col() guards, for the other three
  # column arguments. `time` and `text_score` fall through to their own type
  # checks, but `doc_id` had none: .emoji_id_split() calls match(), which
  # coerces a list column with as.character() -- so documents were grouped by
  # their deparsed R source and two different ids that deparse alike merged.
  # POSIXlt is a list and a legitimate `time` column, so exempt it; length()
  # on a POSIXlt counts times, which is what the row check below needs.
  if (!is.atomic(v) && !inherits(v, "POSIXlt")) {
    stop(sprintf(
      paste0("`%s` must be an atomic column, but `%s` is a %s column. ",
             "Coercing one to character would deparse it rather than read ",
             "it, so the values used would be R source, not your data."),
      arg, nm, class(v)[1L]
    ), call. = FALSE)
  }
  .emoji_check_len(v, nm, nrow(data), arg)
}

# The one-value-per-row check, taking an already-resolved name so a caller
# that has one does not pay for resolving it again. .emoji_col_name() runs
# dplyr::select(), which costs about a millisecond -- invisible next to
# detection on a real corpus, but the whole cost of a verb called once per
# group in a loop over a split data frame.
.emoji_check_len <- function(v, nm, n_row, arg) {
  if (length(v) != n_row) {
    stop(sprintf(
      paste0("`%s` must have one value per row, but `%s` has %d for %d ",
             "row%s -- a matrix column holds one element per cell."),
      arg, nm, length(v), n_row, if (n_row == 1L) "" else "s"
    ), call. = FALSE)
  }
  v
}

# The text column as a character vector -- the form nearly every verb wants.
#
# as.character() is what lets a factor column work, and it is harmless on a
# numeric, Date or logical one (no emoji, so every answer is NA). On a *list*
# column it is not harmless: it deparses, so a column holding
# `list(c("a", "<U+1F600>"))` was read as the source text `c("a",
# "<U+1F600>")`, the emoji inside that was counted, and the row came back with
# a real-looking sentiment the user's data never contained. A data-frame column
# deparses the same way.
#
# The length check catches the other shape: a matrix column has one element per
# cell, not per row, so a two-column matrix gave `emoji_sentiment()` and
# `emoji_tokens()` an internal tibble error naming a variable from this
# package's own source, while `emoji_frequency()` silently counted every cell.
# Refuse a "bytes"-encoded character vector -------------------------------
# A string declared with Encoding() == "bytes" is a bag of bytes R will not
# interpret as characters: nchar(type = "chars"), gsub(), tolower() and
# substr() all stop with "bytes encoding is not supported by this function".
# Emoji detection is built out of exactly those, so nine of ten verbs already
# failed on such a column -- but they failed with R's own message, which names
# no argument, no column and no remedy, and emoji_sanitize(policy = "keep")
# did not fail at all. Catching it in the resolver makes one clear message
# serve every verb.
#
# Refusing rather than coercing is the point: a string is usually marked
# "bytes" precisely because it is *not* valid UTF-8, so enc2utf8() cannot
# repair it and would quietly substitute replacement characters. Only the
# caller knows what encoding the bytes really are.
.emoji_check_encoding <- function(v, nm, arg) {
  if (!is.character(v)) return(invisible(v))
  bad <- Encoding(v) == "bytes"
  if (any(bad)) {
    stop(sprintf(
      paste0("`%s` reads column `%s`, whose strings carry \"bytes\" encoding ",
             "(%d of %d). Finding emoji means reading characters, and R will ",
             "not read a \"bytes\" string as characters at all. Convert it ",
             "with iconv() from whatever encoding those bytes really are -- ",
             "enc2utf8() cannot, because it does not know."),
      arg, nm, sum(bad), length(v)
    ), call. = FALSE)
  }
  invisible(v)
}

.emoji_text_col <- function(data, text, arg = "text") {
  nm <- .emoji_col_name(data, {{ text }}, arg = arg)
  # Before .emoji_col()'s length check, because a data-frame column's length()
  # is its column count -- so the length message would fire first and say
  # nothing about the real problem.
  v <- data[[nm]]
  if (!is.atomic(v)) {
    stop(sprintf(
      paste0("`%s` must be a column of text, but `%s` is a %s column. ",
             "Coercing one to character would deparse it rather than read ",
             "it, so the emoji found would be in the code, not in your data."),
      arg, nm, class(v)[1L]
    ), call. = FALSE)
  }
  v <- as.character(.emoji_check_len(v, nm, nrow(data), arg))
  .emoji_check_encoding(v, nm, arg)
  v
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
  # same reason as .emoji_check_encoding(): every string argument ends up
  # inside gsub() or paste()d next to text that does, and a "bytes" string
  # poisons both with R's own message rather than one naming this argument
  if (Encoding(x) == "bytes") {
    stop(sprintf(
      paste0("`%s` carries \"bytes\" encoding, which R will not read as ",
             "characters. Convert it with iconv() from whatever encoding ",
             "those bytes really are."),
      arg
    ), call. = FALSE)
  }
  invisible(x)
}

# Validate a TRUE/FALSE argument. isTRUE() quietly treats every non-TRUE value
# as FALSE, so an unchecked flag turns a typo into a different, silently wrong
# answer instead of an error -- the same failure mode as an unvalidated `n` or
# a `wrap` template with no placeholder.
# match.arg() that names the argument -------------------------------------
# match.arg() reports its own formal, so every one of the package's enum
# arguments answered a typo with "'arg' should be one of ..." or "'arg' must
# be of length 1" -- naming a variable the caller never wrote and cannot see.
# emoji_turnover() was given a hand-rolled check for exactly this reason, and
# the fix was never grepped across the other fifteen call sites; this is that
# check, once, so a new enum argument has one obvious line to use.
#
# Behaviour is match.arg()'s: a value identical to the whole choice vector
# means "no value supplied" and takes the first, exact matches win, and
# unambiguous prefixes still resolve (pmatch()), so `by = "mon"` keeps
# working. Only the message changes.
.emoji_match_arg <- function(x, choices, arg) {
  if (identical(x, choices)) {
    return(choices[[1L]])
  }
  quoted <- paste(sprintf('"%s"', choices), collapse = ", ")
  if (!is.character(x) || length(x) != 1L || is.na(x)) {
    stop(sprintf(
      "`%s` must be a single string, one of %s.%s", arg, quoted,
      if (is.character(x) && length(x) > 1L)
        sprintf(" You gave %d.", length(x)) else ""
    ), call. = FALSE)
  }
  i <- pmatch(x, choices)
  if (is.na(i)) {
    stop(sprintf("`%s` has no option \"%s\". Choose from %s.",
                 arg, x, quoted), call. = FALSE)
  }
  choices[[i]]
}

.emoji_check_flag <- function(x, arg) {
  if (!is.logical(x) || length(x) != 1L || is.na(x)) {
    stop(sprintf("`%s` must be TRUE or FALSE.", arg), call. = FALSE)
  }
  invisible(x)
}
