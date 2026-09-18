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
# so the fold is driven from an explicit table. Only 1:1 pairs are listed --
# an uppercase code point whose lowercase form is a single, different code
# point -- which is what makes the result byte-identical to tolower() in a
# UTF-8 locale rather than a new folding of its own; the C locale merely
# catches up. Verified over all 5042 names, 10701 keywords and 5761 aliases.
# The trailing tolower() still runs, for anything the table does not name.
#
# The table comes in three parts, for no reason but reviewability: A-Z, then
# the cased Latin letters of the Latin-1 Supplement and Latin Extended-A/-B,
# then every other script with a 1:1 simple lowercase mapping.
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

# Every remaining script with a 1:1 simple lowercase mapping.
#
# The two tables above cover what the *catalogue* needs -- its names are ASCII
# and Latin -- and that was the wrong scope, because emoji_collocations() folds
# the *user's* text, which can be in any script. Under LC_ALL=C tolower()
# leaves every letter it does not have an ASCII rule for exactly as it found
# it, so "PRIVET" in Cyrillic and the same word in lowercase were counted as
# two different collocates in a C session and as one in a UTF-8 session. Same
# defect as the Turkish dotless i, one script family further out, and the
# reason to fix it rather than document it is that the package's own promise
# is that no answer moves with the session.
#
# Derived rather than hand-written: every code point whose tolower() in a
# UTF-8 session is a single, different code point, which is 1157 pairs beyond
# the Latin tables and brings the whole table to 1383. Greek and Cyrillic and
# their extensions, Armenian, Georgian, Cherokee, Coptic, Glagolitic, Adlam,
# Osage, Deseret, Warang Citi, Medefaidrin, Latin Extended Additional (which
# is where Vietnamese lives), Latin Extended-C/D/E, the letterlike and circled
# forms, and fullwidth Latin. A test re-derives the properties the fold needs:
# no duplicate source, no character its own image, no lowercase target that is
# also an uppercase source, and -- in a UTF-8 session only, since that is the
# only place tolower() can be a fair reference -- the table reproduces
# tolower() exactly.
#
# Multi-character mappings are deliberately absent. German sharp s and the
# Greek iota-subscript forms lowercase to more than one code point, which
# chartr() cannot express and tolower() does not do either.
.emoji_other_upper <- intToUtf8(c(
  0x0370,0x0372,0x0376,0x037F,0x0386,0x0388,0x0389,0x038A,
  0x038C,0x038E,0x038F,0x0391,0x0392,0x0393,0x0394,0x0395,
  0x0396,0x0397,0x0398,0x0399,0x039A,0x039B,0x039C,0x039D,
  0x039E,0x039F,0x03A0,0x03A1,0x03A3,0x03A4,0x03A5,0x03A6,
  0x03A7,0x03A8,0x03A9,0x03AA,0x03AB,0x03CF,0x03D8,0x03DA,
  0x03DC,0x03DE,0x03E0,0x03E2,0x03E4,0x03E6,0x03E8,0x03EA,
  0x03EC,0x03EE,0x03F4,0x03F7,0x03F9,0x03FA,0x03FD,0x03FE,
  0x03FF,0x0400,0x0401,0x0402,0x0403,0x0404,0x0405,0x0406,
  0x0407,0x0408,0x0409,0x040A,0x040B,0x040C,0x040D,0x040E,
  0x040F,0x0410,0x0411,0x0412,0x0413,0x0414,0x0415,0x0416,
  0x0417,0x0418,0x0419,0x041A,0x041B,0x041C,0x041D,0x041E,
  0x041F,0x0420,0x0421,0x0422,0x0423,0x0424,0x0425,0x0426,
  0x0427,0x0428,0x0429,0x042A,0x042B,0x042C,0x042D,0x042E,
  0x042F,0x0460,0x0462,0x0464,0x0466,0x0468,0x046A,0x046C,
  0x046E,0x0470,0x0472,0x0474,0x0476,0x0478,0x047A,0x047C,
  0x047E,0x0480,0x048A,0x048C,0x048E,0x0490,0x0492,0x0494,
  0x0496,0x0498,0x049A,0x049C,0x049E,0x04A0,0x04A2,0x04A4,
  0x04A6,0x04A8,0x04AA,0x04AC,0x04AE,0x04B0,0x04B2,0x04B4,
  0x04B6,0x04B8,0x04BA,0x04BC,0x04BE,0x04C0,0x04C1,0x04C3,
  0x04C5,0x04C7,0x04C9,0x04CB,0x04CD,0x04D0,0x04D2,0x04D4,
  0x04D6,0x04D8,0x04DA,0x04DC,0x04DE,0x04E0,0x04E2,0x04E4,
  0x04E6,0x04E8,0x04EA,0x04EC,0x04EE,0x04F0,0x04F2,0x04F4,
  0x04F6,0x04F8,0x04FA,0x04FC,0x04FE,0x0500,0x0502,0x0504,
  0x0506,0x0508,0x050A,0x050C,0x050E,0x0510,0x0512,0x0514,
  0x0516,0x0518,0x051A,0x051C,0x051E,0x0520,0x0522,0x0524,
  0x0526,0x0528,0x052A,0x052C,0x052E,0x0531,0x0532,0x0533,
  0x0534,0x0535,0x0536,0x0537,0x0538,0x0539,0x053A,0x053B,
  0x053C,0x053D,0x053E,0x053F,0x0540,0x0541,0x0542,0x0543,
  0x0544,0x0545,0x0546,0x0547,0x0548,0x0549,0x054A,0x054B,
  0x054C,0x054D,0x054E,0x054F,0x0550,0x0551,0x0552,0x0553,
  0x0554,0x0555,0x0556,0x10A0,0x10A1,0x10A2,0x10A3,0x10A4,
  0x10A5,0x10A6,0x10A7,0x10A8,0x10A9,0x10AA,0x10AB,0x10AC,
  0x10AD,0x10AE,0x10AF,0x10B0,0x10B1,0x10B2,0x10B3,0x10B4,
  0x10B5,0x10B6,0x10B7,0x10B8,0x10B9,0x10BA,0x10BB,0x10BC,
  0x10BD,0x10BE,0x10BF,0x10C0,0x10C1,0x10C2,0x10C3,0x10C4,
  0x10C5,0x10C7,0x10CD,0x13A0,0x13A1,0x13A2,0x13A3,0x13A4,
  0x13A5,0x13A6,0x13A7,0x13A8,0x13A9,0x13AA,0x13AB,0x13AC,
  0x13AD,0x13AE,0x13AF,0x13B0,0x13B1,0x13B2,0x13B3,0x13B4,
  0x13B5,0x13B6,0x13B7,0x13B8,0x13B9,0x13BA,0x13BB,0x13BC,
  0x13BD,0x13BE,0x13BF,0x13C0,0x13C1,0x13C2,0x13C3,0x13C4,
  0x13C5,0x13C6,0x13C7,0x13C8,0x13C9,0x13CA,0x13CB,0x13CC,
  0x13CD,0x13CE,0x13CF,0x13D0,0x13D1,0x13D2,0x13D3,0x13D4,
  0x13D5,0x13D6,0x13D7,0x13D8,0x13D9,0x13DA,0x13DB,0x13DC,
  0x13DD,0x13DE,0x13DF,0x13E0,0x13E1,0x13E2,0x13E3,0x13E4,
  0x13E5,0x13E6,0x13E7,0x13E8,0x13E9,0x13EA,0x13EB,0x13EC,
  0x13ED,0x13EE,0x13EF,0x13F0,0x13F1,0x13F2,0x13F3,0x13F4,
  0x13F5,0x1C90,0x1C91,0x1C92,0x1C93,0x1C94,0x1C95,0x1C96,
  0x1C97,0x1C98,0x1C99,0x1C9A,0x1C9B,0x1C9C,0x1C9D,0x1C9E,
  0x1C9F,0x1CA0,0x1CA1,0x1CA2,0x1CA3,0x1CA4,0x1CA5,0x1CA6,
  0x1CA7,0x1CA8,0x1CA9,0x1CAA,0x1CAB,0x1CAC,0x1CAD,0x1CAE,
  0x1CAF,0x1CB0,0x1CB1,0x1CB2,0x1CB3,0x1CB4,0x1CB5,0x1CB6,
  0x1CB7,0x1CB8,0x1CB9,0x1CBA,0x1CBD,0x1CBE,0x1CBF,0x1E00,
  0x1E02,0x1E04,0x1E06,0x1E08,0x1E0A,0x1E0C,0x1E0E,0x1E10,
  0x1E12,0x1E14,0x1E16,0x1E18,0x1E1A,0x1E1C,0x1E1E,0x1E20,
  0x1E22,0x1E24,0x1E26,0x1E28,0x1E2A,0x1E2C,0x1E2E,0x1E30,
  0x1E32,0x1E34,0x1E36,0x1E38,0x1E3A,0x1E3C,0x1E3E,0x1E40,
  0x1E42,0x1E44,0x1E46,0x1E48,0x1E4A,0x1E4C,0x1E4E,0x1E50,
  0x1E52,0x1E54,0x1E56,0x1E58,0x1E5A,0x1E5C,0x1E5E,0x1E60,
  0x1E62,0x1E64,0x1E66,0x1E68,0x1E6A,0x1E6C,0x1E6E,0x1E70,
  0x1E72,0x1E74,0x1E76,0x1E78,0x1E7A,0x1E7C,0x1E7E,0x1E80,
  0x1E82,0x1E84,0x1E86,0x1E88,0x1E8A,0x1E8C,0x1E8E,0x1E90,
  0x1E92,0x1E94,0x1E9E,0x1EA0,0x1EA2,0x1EA4,0x1EA6,0x1EA8,
  0x1EAA,0x1EAC,0x1EAE,0x1EB0,0x1EB2,0x1EB4,0x1EB6,0x1EB8,
  0x1EBA,0x1EBC,0x1EBE,0x1EC0,0x1EC2,0x1EC4,0x1EC6,0x1EC8,
  0x1ECA,0x1ECC,0x1ECE,0x1ED0,0x1ED2,0x1ED4,0x1ED6,0x1ED8,
  0x1EDA,0x1EDC,0x1EDE,0x1EE0,0x1EE2,0x1EE4,0x1EE6,0x1EE8,
  0x1EEA,0x1EEC,0x1EEE,0x1EF0,0x1EF2,0x1EF4,0x1EF6,0x1EF8,
  0x1EFA,0x1EFC,0x1EFE,0x1F08,0x1F09,0x1F0A,0x1F0B,0x1F0C,
  0x1F0D,0x1F0E,0x1F0F,0x1F18,0x1F19,0x1F1A,0x1F1B,0x1F1C,
  0x1F1D,0x1F28,0x1F29,0x1F2A,0x1F2B,0x1F2C,0x1F2D,0x1F2E,
  0x1F2F,0x1F38,0x1F39,0x1F3A,0x1F3B,0x1F3C,0x1F3D,0x1F3E,
  0x1F3F,0x1F48,0x1F49,0x1F4A,0x1F4B,0x1F4C,0x1F4D,0x1F59,
  0x1F5B,0x1F5D,0x1F5F,0x1F68,0x1F69,0x1F6A,0x1F6B,0x1F6C,
  0x1F6D,0x1F6E,0x1F6F,0x1F88,0x1F89,0x1F8A,0x1F8B,0x1F8C,
  0x1F8D,0x1F8E,0x1F8F,0x1F98,0x1F99,0x1F9A,0x1F9B,0x1F9C,
  0x1F9D,0x1F9E,0x1F9F,0x1FA8,0x1FA9,0x1FAA,0x1FAB,0x1FAC,
  0x1FAD,0x1FAE,0x1FAF,0x1FB8,0x1FB9,0x1FBA,0x1FBB,0x1FBC,
  0x1FC8,0x1FC9,0x1FCA,0x1FCB,0x1FCC,0x1FD8,0x1FD9,0x1FDA,
  0x1FDB,0x1FE8,0x1FE9,0x1FEA,0x1FEB,0x1FEC,0x1FF8,0x1FF9,
  0x1FFA,0x1FFB,0x1FFC,0x2126,0x212A,0x212B,0x2132,0x2160,
  0x2161,0x2162,0x2163,0x2164,0x2165,0x2166,0x2167,0x2168,
  0x2169,0x216A,0x216B,0x216C,0x216D,0x216E,0x216F,0x2183,
  0x24B6,0x24B7,0x24B8,0x24B9,0x24BA,0x24BB,0x24BC,0x24BD,
  0x24BE,0x24BF,0x24C0,0x24C1,0x24C2,0x24C3,0x24C4,0x24C5,
  0x24C6,0x24C7,0x24C8,0x24C9,0x24CA,0x24CB,0x24CC,0x24CD,
  0x24CE,0x24CF,0x2C00,0x2C01,0x2C02,0x2C03,0x2C04,0x2C05,
  0x2C06,0x2C07,0x2C08,0x2C09,0x2C0A,0x2C0B,0x2C0C,0x2C0D,
  0x2C0E,0x2C0F,0x2C10,0x2C11,0x2C12,0x2C13,0x2C14,0x2C15,
  0x2C16,0x2C17,0x2C18,0x2C19,0x2C1A,0x2C1B,0x2C1C,0x2C1D,
  0x2C1E,0x2C1F,0x2C20,0x2C21,0x2C22,0x2C23,0x2C24,0x2C25,
  0x2C26,0x2C27,0x2C28,0x2C29,0x2C2A,0x2C2B,0x2C2C,0x2C2D,
  0x2C2E,0x2C60,0x2C62,0x2C63,0x2C64,0x2C67,0x2C69,0x2C6B,
  0x2C6D,0x2C6E,0x2C6F,0x2C70,0x2C72,0x2C75,0x2C7E,0x2C7F,
  0x2C80,0x2C82,0x2C84,0x2C86,0x2C88,0x2C8A,0x2C8C,0x2C8E,
  0x2C90,0x2C92,0x2C94,0x2C96,0x2C98,0x2C9A,0x2C9C,0x2C9E,
  0x2CA0,0x2CA2,0x2CA4,0x2CA6,0x2CA8,0x2CAA,0x2CAC,0x2CAE,
  0x2CB0,0x2CB2,0x2CB4,0x2CB6,0x2CB8,0x2CBA,0x2CBC,0x2CBE,
  0x2CC0,0x2CC2,0x2CC4,0x2CC6,0x2CC8,0x2CCA,0x2CCC,0x2CCE,
  0x2CD0,0x2CD2,0x2CD4,0x2CD6,0x2CD8,0x2CDA,0x2CDC,0x2CDE,
  0x2CE0,0x2CE2,0x2CEB,0x2CED,0x2CF2,0xA640,0xA642,0xA644,
  0xA646,0xA648,0xA64A,0xA64C,0xA64E,0xA650,0xA652,0xA654,
  0xA656,0xA658,0xA65A,0xA65C,0xA65E,0xA660,0xA662,0xA664,
  0xA666,0xA668,0xA66A,0xA66C,0xA680,0xA682,0xA684,0xA686,
  0xA688,0xA68A,0xA68C,0xA68E,0xA690,0xA692,0xA694,0xA696,
  0xA698,0xA69A,0xA722,0xA724,0xA726,0xA728,0xA72A,0xA72C,
  0xA72E,0xA732,0xA734,0xA736,0xA738,0xA73A,0xA73C,0xA73E,
  0xA740,0xA742,0xA744,0xA746,0xA748,0xA74A,0xA74C,0xA74E,
  0xA750,0xA752,0xA754,0xA756,0xA758,0xA75A,0xA75C,0xA75E,
  0xA760,0xA762,0xA764,0xA766,0xA768,0xA76A,0xA76C,0xA76E,
  0xA779,0xA77B,0xA77D,0xA77E,0xA780,0xA782,0xA784,0xA786,
  0xA78B,0xA78D,0xA790,0xA792,0xA796,0xA798,0xA79A,0xA79C,
  0xA79E,0xA7A0,0xA7A2,0xA7A4,0xA7A6,0xA7A8,0xA7AA,0xA7AB,
  0xA7AC,0xA7AD,0xA7AE,0xA7B0,0xA7B1,0xA7B2,0xA7B3,0xA7B4,
  0xA7B6,0xA7B8,0xFF21,0xFF22,0xFF23,0xFF24,0xFF25,0xFF26,
  0xFF27,0xFF28,0xFF29,0xFF2A,0xFF2B,0xFF2C,0xFF2D,0xFF2E,
  0xFF2F,0xFF30,0xFF31,0xFF32,0xFF33,0xFF34,0xFF35,0xFF36,
  0xFF37,0xFF38,0xFF39,0xFF3A,0x10400,0x10401,0x10402,0x10403,
  0x10404,0x10405,0x10406,0x10407,0x10408,0x10409,0x1040A,0x1040B,
  0x1040C,0x1040D,0x1040E,0x1040F,0x10410,0x10411,0x10412,0x10413,
  0x10414,0x10415,0x10416,0x10417,0x10418,0x10419,0x1041A,0x1041B,
  0x1041C,0x1041D,0x1041E,0x1041F,0x10420,0x10421,0x10422,0x10423,
  0x10424,0x10425,0x10426,0x10427,0x104B0,0x104B1,0x104B2,0x104B3,
  0x104B4,0x104B5,0x104B6,0x104B7,0x104B8,0x104B9,0x104BA,0x104BB,
  0x104BC,0x104BD,0x104BE,0x104BF,0x104C0,0x104C1,0x104C2,0x104C3,
  0x104C4,0x104C5,0x104C6,0x104C7,0x104C8,0x104C9,0x104CA,0x104CB,
  0x104CC,0x104CD,0x104CE,0x104CF,0x104D0,0x104D1,0x104D2,0x104D3,
  0x10C80,0x10C81,0x10C82,0x10C83,0x10C84,0x10C85,0x10C86,0x10C87,
  0x10C88,0x10C89,0x10C8A,0x10C8B,0x10C8C,0x10C8D,0x10C8E,0x10C8F,
  0x10C90,0x10C91,0x10C92,0x10C93,0x10C94,0x10C95,0x10C96,0x10C97,
  0x10C98,0x10C99,0x10C9A,0x10C9B,0x10C9C,0x10C9D,0x10C9E,0x10C9F,
  0x10CA0,0x10CA1,0x10CA2,0x10CA3,0x10CA4,0x10CA5,0x10CA6,0x10CA7,
  0x10CA8,0x10CA9,0x10CAA,0x10CAB,0x10CAC,0x10CAD,0x10CAE,0x10CAF,
  0x10CB0,0x10CB1,0x10CB2,0x118A0,0x118A1,0x118A2,0x118A3,0x118A4,
  0x118A5,0x118A6,0x118A7,0x118A8,0x118A9,0x118AA,0x118AB,0x118AC,
  0x118AD,0x118AE,0x118AF,0x118B0,0x118B1,0x118B2,0x118B3,0x118B4,
  0x118B5,0x118B6,0x118B7,0x118B8,0x118B9,0x118BA,0x118BB,0x118BC,
  0x118BD,0x118BE,0x118BF,0x16E40,0x16E41,0x16E42,0x16E43,0x16E44,
  0x16E45,0x16E46,0x16E47,0x16E48,0x16E49,0x16E4A,0x16E4B,0x16E4C,
  0x16E4D,0x16E4E,0x16E4F,0x16E50,0x16E51,0x16E52,0x16E53,0x16E54,
  0x16E55,0x16E56,0x16E57,0x16E58,0x16E59,0x16E5A,0x16E5B,0x16E5C,
  0x16E5D,0x16E5E,0x16E5F,0x1E900,0x1E901,0x1E902,0x1E903,0x1E904,
  0x1E905,0x1E906,0x1E907,0x1E908,0x1E909,0x1E90A,0x1E90B,0x1E90C,
  0x1E90D,0x1E90E,0x1E90F,0x1E910,0x1E911,0x1E912,0x1E913,0x1E914,
  0x1E915,0x1E916,0x1E917,0x1E918,0x1E919,0x1E91A,0x1E91B,0x1E91C,
  0x1E91D,0x1E91E,0x1E91F,0x1E920,0x1E921
))

.emoji_other_lower <- intToUtf8(c(
  0x0371,0x0373,0x0377,0x03F3,0x03AC,0x03AD,0x03AE,0x03AF,
  0x03CC,0x03CD,0x03CE,0x03B1,0x03B2,0x03B3,0x03B4,0x03B5,
  0x03B6,0x03B7,0x03B8,0x03B9,0x03BA,0x03BB,0x03BC,0x03BD,
  0x03BE,0x03BF,0x03C0,0x03C1,0x03C3,0x03C4,0x03C5,0x03C6,
  0x03C7,0x03C8,0x03C9,0x03CA,0x03CB,0x03D7,0x03D9,0x03DB,
  0x03DD,0x03DF,0x03E1,0x03E3,0x03E5,0x03E7,0x03E9,0x03EB,
  0x03ED,0x03EF,0x03B8,0x03F8,0x03F2,0x03FB,0x037B,0x037C,
  0x037D,0x0450,0x0451,0x0452,0x0453,0x0454,0x0455,0x0456,
  0x0457,0x0458,0x0459,0x045A,0x045B,0x045C,0x045D,0x045E,
  0x045F,0x0430,0x0431,0x0432,0x0433,0x0434,0x0435,0x0436,
  0x0437,0x0438,0x0439,0x043A,0x043B,0x043C,0x043D,0x043E,
  0x043F,0x0440,0x0441,0x0442,0x0443,0x0444,0x0445,0x0446,
  0x0447,0x0448,0x0449,0x044A,0x044B,0x044C,0x044D,0x044E,
  0x044F,0x0461,0x0463,0x0465,0x0467,0x0469,0x046B,0x046D,
  0x046F,0x0471,0x0473,0x0475,0x0477,0x0479,0x047B,0x047D,
  0x047F,0x0481,0x048B,0x048D,0x048F,0x0491,0x0493,0x0495,
  0x0497,0x0499,0x049B,0x049D,0x049F,0x04A1,0x04A3,0x04A5,
  0x04A7,0x04A9,0x04AB,0x04AD,0x04AF,0x04B1,0x04B3,0x04B5,
  0x04B7,0x04B9,0x04BB,0x04BD,0x04BF,0x04CF,0x04C2,0x04C4,
  0x04C6,0x04C8,0x04CA,0x04CC,0x04CE,0x04D1,0x04D3,0x04D5,
  0x04D7,0x04D9,0x04DB,0x04DD,0x04DF,0x04E1,0x04E3,0x04E5,
  0x04E7,0x04E9,0x04EB,0x04ED,0x04EF,0x04F1,0x04F3,0x04F5,
  0x04F7,0x04F9,0x04FB,0x04FD,0x04FF,0x0501,0x0503,0x0505,
  0x0507,0x0509,0x050B,0x050D,0x050F,0x0511,0x0513,0x0515,
  0x0517,0x0519,0x051B,0x051D,0x051F,0x0521,0x0523,0x0525,
  0x0527,0x0529,0x052B,0x052D,0x052F,0x0561,0x0562,0x0563,
  0x0564,0x0565,0x0566,0x0567,0x0568,0x0569,0x056A,0x056B,
  0x056C,0x056D,0x056E,0x056F,0x0570,0x0571,0x0572,0x0573,
  0x0574,0x0575,0x0576,0x0577,0x0578,0x0579,0x057A,0x057B,
  0x057C,0x057D,0x057E,0x057F,0x0580,0x0581,0x0582,0x0583,
  0x0584,0x0585,0x0586,0x2D00,0x2D01,0x2D02,0x2D03,0x2D04,
  0x2D05,0x2D06,0x2D07,0x2D08,0x2D09,0x2D0A,0x2D0B,0x2D0C,
  0x2D0D,0x2D0E,0x2D0F,0x2D10,0x2D11,0x2D12,0x2D13,0x2D14,
  0x2D15,0x2D16,0x2D17,0x2D18,0x2D19,0x2D1A,0x2D1B,0x2D1C,
  0x2D1D,0x2D1E,0x2D1F,0x2D20,0x2D21,0x2D22,0x2D23,0x2D24,
  0x2D25,0x2D27,0x2D2D,0xAB70,0xAB71,0xAB72,0xAB73,0xAB74,
  0xAB75,0xAB76,0xAB77,0xAB78,0xAB79,0xAB7A,0xAB7B,0xAB7C,
  0xAB7D,0xAB7E,0xAB7F,0xAB80,0xAB81,0xAB82,0xAB83,0xAB84,
  0xAB85,0xAB86,0xAB87,0xAB88,0xAB89,0xAB8A,0xAB8B,0xAB8C,
  0xAB8D,0xAB8E,0xAB8F,0xAB90,0xAB91,0xAB92,0xAB93,0xAB94,
  0xAB95,0xAB96,0xAB97,0xAB98,0xAB99,0xAB9A,0xAB9B,0xAB9C,
  0xAB9D,0xAB9E,0xAB9F,0xABA0,0xABA1,0xABA2,0xABA3,0xABA4,
  0xABA5,0xABA6,0xABA7,0xABA8,0xABA9,0xABAA,0xABAB,0xABAC,
  0xABAD,0xABAE,0xABAF,0xABB0,0xABB1,0xABB2,0xABB3,0xABB4,
  0xABB5,0xABB6,0xABB7,0xABB8,0xABB9,0xABBA,0xABBB,0xABBC,
  0xABBD,0xABBE,0xABBF,0x13F8,0x13F9,0x13FA,0x13FB,0x13FC,
  0x13FD,0x10D0,0x10D1,0x10D2,0x10D3,0x10D4,0x10D5,0x10D6,
  0x10D7,0x10D8,0x10D9,0x10DA,0x10DB,0x10DC,0x10DD,0x10DE,
  0x10DF,0x10E0,0x10E1,0x10E2,0x10E3,0x10E4,0x10E5,0x10E6,
  0x10E7,0x10E8,0x10E9,0x10EA,0x10EB,0x10EC,0x10ED,0x10EE,
  0x10EF,0x10F0,0x10F1,0x10F2,0x10F3,0x10F4,0x10F5,0x10F6,
  0x10F7,0x10F8,0x10F9,0x10FA,0x10FD,0x10FE,0x10FF,0x1E01,
  0x1E03,0x1E05,0x1E07,0x1E09,0x1E0B,0x1E0D,0x1E0F,0x1E11,
  0x1E13,0x1E15,0x1E17,0x1E19,0x1E1B,0x1E1D,0x1E1F,0x1E21,
  0x1E23,0x1E25,0x1E27,0x1E29,0x1E2B,0x1E2D,0x1E2F,0x1E31,
  0x1E33,0x1E35,0x1E37,0x1E39,0x1E3B,0x1E3D,0x1E3F,0x1E41,
  0x1E43,0x1E45,0x1E47,0x1E49,0x1E4B,0x1E4D,0x1E4F,0x1E51,
  0x1E53,0x1E55,0x1E57,0x1E59,0x1E5B,0x1E5D,0x1E5F,0x1E61,
  0x1E63,0x1E65,0x1E67,0x1E69,0x1E6B,0x1E6D,0x1E6F,0x1E71,
  0x1E73,0x1E75,0x1E77,0x1E79,0x1E7B,0x1E7D,0x1E7F,0x1E81,
  0x1E83,0x1E85,0x1E87,0x1E89,0x1E8B,0x1E8D,0x1E8F,0x1E91,
  0x1E93,0x1E95,0x00DF,0x1EA1,0x1EA3,0x1EA5,0x1EA7,0x1EA9,
  0x1EAB,0x1EAD,0x1EAF,0x1EB1,0x1EB3,0x1EB5,0x1EB7,0x1EB9,
  0x1EBB,0x1EBD,0x1EBF,0x1EC1,0x1EC3,0x1EC5,0x1EC7,0x1EC9,
  0x1ECB,0x1ECD,0x1ECF,0x1ED1,0x1ED3,0x1ED5,0x1ED7,0x1ED9,
  0x1EDB,0x1EDD,0x1EDF,0x1EE1,0x1EE3,0x1EE5,0x1EE7,0x1EE9,
  0x1EEB,0x1EED,0x1EEF,0x1EF1,0x1EF3,0x1EF5,0x1EF7,0x1EF9,
  0x1EFB,0x1EFD,0x1EFF,0x1F00,0x1F01,0x1F02,0x1F03,0x1F04,
  0x1F05,0x1F06,0x1F07,0x1F10,0x1F11,0x1F12,0x1F13,0x1F14,
  0x1F15,0x1F20,0x1F21,0x1F22,0x1F23,0x1F24,0x1F25,0x1F26,
  0x1F27,0x1F30,0x1F31,0x1F32,0x1F33,0x1F34,0x1F35,0x1F36,
  0x1F37,0x1F40,0x1F41,0x1F42,0x1F43,0x1F44,0x1F45,0x1F51,
  0x1F53,0x1F55,0x1F57,0x1F60,0x1F61,0x1F62,0x1F63,0x1F64,
  0x1F65,0x1F66,0x1F67,0x1F80,0x1F81,0x1F82,0x1F83,0x1F84,
  0x1F85,0x1F86,0x1F87,0x1F90,0x1F91,0x1F92,0x1F93,0x1F94,
  0x1F95,0x1F96,0x1F97,0x1FA0,0x1FA1,0x1FA2,0x1FA3,0x1FA4,
  0x1FA5,0x1FA6,0x1FA7,0x1FB0,0x1FB1,0x1F70,0x1F71,0x1FB3,
  0x1F72,0x1F73,0x1F74,0x1F75,0x1FC3,0x1FD0,0x1FD1,0x1F76,
  0x1F77,0x1FE0,0x1FE1,0x1F7A,0x1F7B,0x1FE5,0x1F78,0x1F79,
  0x1F7C,0x1F7D,0x1FF3,0x03C9,0x006B,0x00E5,0x214E,0x2170,
  0x2171,0x2172,0x2173,0x2174,0x2175,0x2176,0x2177,0x2178,
  0x2179,0x217A,0x217B,0x217C,0x217D,0x217E,0x217F,0x2184,
  0x24D0,0x24D1,0x24D2,0x24D3,0x24D4,0x24D5,0x24D6,0x24D7,
  0x24D8,0x24D9,0x24DA,0x24DB,0x24DC,0x24DD,0x24DE,0x24DF,
  0x24E0,0x24E1,0x24E2,0x24E3,0x24E4,0x24E5,0x24E6,0x24E7,
  0x24E8,0x24E9,0x2C30,0x2C31,0x2C32,0x2C33,0x2C34,0x2C35,
  0x2C36,0x2C37,0x2C38,0x2C39,0x2C3A,0x2C3B,0x2C3C,0x2C3D,
  0x2C3E,0x2C3F,0x2C40,0x2C41,0x2C42,0x2C43,0x2C44,0x2C45,
  0x2C46,0x2C47,0x2C48,0x2C49,0x2C4A,0x2C4B,0x2C4C,0x2C4D,
  0x2C4E,0x2C4F,0x2C50,0x2C51,0x2C52,0x2C53,0x2C54,0x2C55,
  0x2C56,0x2C57,0x2C58,0x2C59,0x2C5A,0x2C5B,0x2C5C,0x2C5D,
  0x2C5E,0x2C61,0x026B,0x1D7D,0x027D,0x2C68,0x2C6A,0x2C6C,
  0x0251,0x0271,0x0250,0x0252,0x2C73,0x2C76,0x023F,0x0240,
  0x2C81,0x2C83,0x2C85,0x2C87,0x2C89,0x2C8B,0x2C8D,0x2C8F,
  0x2C91,0x2C93,0x2C95,0x2C97,0x2C99,0x2C9B,0x2C9D,0x2C9F,
  0x2CA1,0x2CA3,0x2CA5,0x2CA7,0x2CA9,0x2CAB,0x2CAD,0x2CAF,
  0x2CB1,0x2CB3,0x2CB5,0x2CB7,0x2CB9,0x2CBB,0x2CBD,0x2CBF,
  0x2CC1,0x2CC3,0x2CC5,0x2CC7,0x2CC9,0x2CCB,0x2CCD,0x2CCF,
  0x2CD1,0x2CD3,0x2CD5,0x2CD7,0x2CD9,0x2CDB,0x2CDD,0x2CDF,
  0x2CE1,0x2CE3,0x2CEC,0x2CEE,0x2CF3,0xA641,0xA643,0xA645,
  0xA647,0xA649,0xA64B,0xA64D,0xA64F,0xA651,0xA653,0xA655,
  0xA657,0xA659,0xA65B,0xA65D,0xA65F,0xA661,0xA663,0xA665,
  0xA667,0xA669,0xA66B,0xA66D,0xA681,0xA683,0xA685,0xA687,
  0xA689,0xA68B,0xA68D,0xA68F,0xA691,0xA693,0xA695,0xA697,
  0xA699,0xA69B,0xA723,0xA725,0xA727,0xA729,0xA72B,0xA72D,
  0xA72F,0xA733,0xA735,0xA737,0xA739,0xA73B,0xA73D,0xA73F,
  0xA741,0xA743,0xA745,0xA747,0xA749,0xA74B,0xA74D,0xA74F,
  0xA751,0xA753,0xA755,0xA757,0xA759,0xA75B,0xA75D,0xA75F,
  0xA761,0xA763,0xA765,0xA767,0xA769,0xA76B,0xA76D,0xA76F,
  0xA77A,0xA77C,0x1D79,0xA77F,0xA781,0xA783,0xA785,0xA787,
  0xA78C,0x0265,0xA791,0xA793,0xA797,0xA799,0xA79B,0xA79D,
  0xA79F,0xA7A1,0xA7A3,0xA7A5,0xA7A7,0xA7A9,0x0266,0x025C,
  0x0261,0x026C,0x026A,0x029E,0x0287,0x029D,0xAB53,0xA7B5,
  0xA7B7,0xA7B9,0xFF41,0xFF42,0xFF43,0xFF44,0xFF45,0xFF46,
  0xFF47,0xFF48,0xFF49,0xFF4A,0xFF4B,0xFF4C,0xFF4D,0xFF4E,
  0xFF4F,0xFF50,0xFF51,0xFF52,0xFF53,0xFF54,0xFF55,0xFF56,
  0xFF57,0xFF58,0xFF59,0xFF5A,0x10428,0x10429,0x1042A,0x1042B,
  0x1042C,0x1042D,0x1042E,0x1042F,0x10430,0x10431,0x10432,0x10433,
  0x10434,0x10435,0x10436,0x10437,0x10438,0x10439,0x1043A,0x1043B,
  0x1043C,0x1043D,0x1043E,0x1043F,0x10440,0x10441,0x10442,0x10443,
  0x10444,0x10445,0x10446,0x10447,0x10448,0x10449,0x1044A,0x1044B,
  0x1044C,0x1044D,0x1044E,0x1044F,0x104D8,0x104D9,0x104DA,0x104DB,
  0x104DC,0x104DD,0x104DE,0x104DF,0x104E0,0x104E1,0x104E2,0x104E3,
  0x104E4,0x104E5,0x104E6,0x104E7,0x104E8,0x104E9,0x104EA,0x104EB,
  0x104EC,0x104ED,0x104EE,0x104EF,0x104F0,0x104F1,0x104F2,0x104F3,
  0x104F4,0x104F5,0x104F6,0x104F7,0x104F8,0x104F9,0x104FA,0x104FB,
  0x10CC0,0x10CC1,0x10CC2,0x10CC3,0x10CC4,0x10CC5,0x10CC6,0x10CC7,
  0x10CC8,0x10CC9,0x10CCA,0x10CCB,0x10CCC,0x10CCD,0x10CCE,0x10CCF,
  0x10CD0,0x10CD1,0x10CD2,0x10CD3,0x10CD4,0x10CD5,0x10CD6,0x10CD7,
  0x10CD8,0x10CD9,0x10CDA,0x10CDB,0x10CDC,0x10CDD,0x10CDE,0x10CDF,
  0x10CE0,0x10CE1,0x10CE2,0x10CE3,0x10CE4,0x10CE5,0x10CE6,0x10CE7,
  0x10CE8,0x10CE9,0x10CEA,0x10CEB,0x10CEC,0x10CED,0x10CEE,0x10CEF,
  0x10CF0,0x10CF1,0x10CF2,0x118C0,0x118C1,0x118C2,0x118C3,0x118C4,
  0x118C5,0x118C6,0x118C7,0x118C8,0x118C9,0x118CA,0x118CB,0x118CC,
  0x118CD,0x118CE,0x118CF,0x118D0,0x118D1,0x118D2,0x118D3,0x118D4,
  0x118D5,0x118D6,0x118D7,0x118D8,0x118D9,0x118DA,0x118DB,0x118DC,
  0x118DD,0x118DE,0x118DF,0x16E60,0x16E61,0x16E62,0x16E63,0x16E64,
  0x16E65,0x16E66,0x16E67,0x16E68,0x16E69,0x16E6A,0x16E6B,0x16E6C,
  0x16E6D,0x16E6E,0x16E6F,0x16E70,0x16E71,0x16E72,0x16E73,0x16E74,
  0x16E75,0x16E76,0x16E77,0x16E78,0x16E79,0x16E7A,0x16E7B,0x16E7C,
  0x16E7D,0x16E7E,0x16E7F,0x1E922,0x1E923,0x1E924,0x1E925,0x1E926,
  0x1E927,0x1E928,0x1E929,0x1E92A,0x1E92B,0x1E92C,0x1E92D,0x1E92E,
  0x1E92F,0x1E930,0x1E931,0x1E932,0x1E933,0x1E934,0x1E935,0x1E936,
  0x1E937,0x1E938,0x1E939,0x1E93A,0x1E93B,0x1E93C,0x1E93D,0x1E93E,
  0x1E93F,0x1E940,0x1E941,0x1E942,0x1E943
))

.emoji_fold_upper <- paste0(.emoji_ascii_upper, .emoji_latin_upper,
                            .emoji_other_upper)
.emoji_fold_lower <- paste0(.emoji_ascii_lower, .emoji_latin_lower,
                            .emoji_other_lower)

# chartr() rebuilds its translation table on every call, at a cost in the
# length of `old` and regardless of how much text it is given. That is why the
# table's size is worth paying attention to: growing it from 226 pairs to 1383
# took ?emoji_search's example, which folds all 5042 catalogue names, 10701
# keywords and 5761 aliases one row at a time, from under a second to 9.4s and
# earned a new R CMD check NOTE for exceeding the five-second example limit.
#
# The only ASCII source in the whole table is A-Z, so no pair beyond the first
# 26 can touch a string that is pure ASCII -- which the catalogue almost
# entirely is. So test for a non-ASCII byte first and, when there is none,
# build the 26-pair table instead of the 1383-pair one. Verified byte for byte
# against the unconditional fold over all 21511 catalogue strings plus Greek,
# Cyrillic, mixed-script and accented probes. It is faster than the 226-pair
# table this replaced, not merely as fast: 5042 calls went 0.30s to 0.12s.
#
# The trailing tolower() still runs over everything, as it must: it is what
# catches whatever the table does not name.
# NA needs no special case: grepl() answers FALSE for it rather than NA, so
# the index below never carries one, and NA goes down whichever branch the
# rest of the vector chose and comes back NA from chartr(). A line clearing
# NAs out of `nonascii` was here first and mutation testing showed it was
# unreachable.
.emoji_fold <- function(x) {
  nonascii <- grepl("[^\x01-\x7f]", x, useBytes = TRUE)
  if (!any(nonascii)) {
    return(tolower(chartr(.emoji_ascii_upper, .emoji_ascii_lower, x)))
  }
  out <- x
  out[!nonascii] <- chartr(.emoji_ascii_upper, .emoji_ascii_lower,
                           x[!nonascii])
  out[nonascii] <- chartr(.emoji_fold_upper, .emoji_fold_lower, x[nonascii])
  tolower(out)
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

# Word edges, as Unicode general categories rather than "[[:alnum:]]".
#
# Third instance of the same defect as the fold and the whitespace class
# above, and the one that hid longest: emoji_collocations() trimmed leading
# and trailing punctuation off each context word with "[[:alnum:]]", which
# resolves through the C library. Under LC_ALL=C nothing outside ASCII is
# alphanumeric, so "cafe" spelled with an acute came back as "caf", and a
# Hebrew, Arabic, Thai, Devanagari or CJK word was trimmed away to nothing
# and then dropped for being empty. A corpus in any of those scripts reported
# *no collocations at all* on a checking machine whose locale happened to be
# C, while the same corpus reported them in a UTF-8 session. Nothing caught
# it because the fixtures are ASCII and the multi-script sweep exercised
# emoji_context(), which does not trim.
#
# PCRE's \p{...} classes read Unicode's own tables instead of the locale's,
# so they answer identically in every locale -- verified byte for byte under
# en_US.UTF-8 and under LC_ALL=C. Two patterns rather than one:
#
# * Marks belong to a word (\p{M}), because glibc's alnum already kept the
#   ones that spell a word in Hebrew, Arabic, Thai and Devanagari, and a
#   combining acute on a Latin letter is no different -- glibc dropped that
#   one, inconsistently.
# * A token holding no letter and no digit is not a word. That is what the
#   empty result of the old trim achieved for a stray U+FE0F next to a
#   masked glyph, which the bundled corpus has 15 of, and keeping \p{M}
#   would otherwise promote such a token to a collocate.
#
# The pair is byte-identical to the old code on the bundled corpus in a UTF-8
# locale. The one deliberate difference is a superscript digit, which \p{N}
# keeps where glibc's alnum cut it.
.emoji_word_edge <- "^[^\\p{L}\\p{N}\\p{M}]+|[^\\p{L}\\p{N}\\p{M}]+$"
.emoji_word_core <- "[\\p{L}\\p{N}]"

# Trim edge punctuation from each token, then drop whatever is left holding
# no letter or digit.
.emoji_trim_words <- function(w) {
  w <- gsub(.emoji_word_edge, "", w, perl = TRUE)
  w[grepl(.emoji_word_core, w, perl = TRUE)]
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

# A lexicon's value columns have to be numbers, and a non-finite one is not a
# usable number.
#
# The type guard in .emoji_lexicon_record() below rests on one rule: a value
# mean() cannot use must not be reported as scored. `Inf` slipped past it,
# because it is numeric and it is not `NA`, so `.emoji_n_scored` counted the
# emoji and `.emoji_score` came back `Inf`. `NaN` and `NA` in the same column
# were already counted as unscored, so one column answered two ways for the
# same kind of unusable value. The package had also taken the opposite
# position elsewhere: a non-finite `text_score` warns and is treated as
# missing (see emoji_incongruity()). Same rule here, applied where every
# lexicon passes through, so the sentiment, emotion and registered paths
# cannot disagree.
.emoji_drop_nonfinite <- function(values, arg) {
  if (!is.numeric(values)) return(values)
  bad <- !is.na(values) & !is.finite(values)
  n <- sum(bad)
  if (!n) return(values)
  values[bad] <- NA_real_
  warning(sprintf(
    paste0("%d score%s in `%s` %s not finite, so the emoji carrying %s ",
           "count as unscored rather than as scored with an infinite value. ",
           "Left alone, one of them makes every row it appears in infinite ",
           "while `.emoji_n_scored` still reports the row as scored."),
    n, if (n == 1L) "" else "s", arg,
    if (n == 1L) "is" else "are", if (n == 1L) "it" else "them"
  ), call. = FALSE)
  values
}

# The same type check .emoji_lexicon_record() makes on a single score column,
# for the several columns an emotion lexicon carries. Without it a character
# or factor emotion column reached as.matrix() and failed later with R's own
# "'x' must be numeric", naming neither the argument, the column nor the verb
# -- exactly the failure mode the score-column guard exists to replace.
.emoji_check_value_cols <- function(tbl, cols, arg) {
  ok <- vapply(cols, function(cl) {
    v <- tbl[[cl]]
    is.numeric(v) || is.logical(v)
  }, logical(1))
  if (all(ok)) return(invisible(NULL))
  bad <- cols[!ok]
  stop(sprintf(
    paste0("`%s` has %d emotion column%s that %s not numeric (%s), and a ",
           "score has to be a number. Coercing here would report the emoji ",
           "as scored while every score came back `NA`. Convert them first, ",
           "and check what made them non-numeric -- a stray \"NA\" or a ",
           "decimal comma turns a whole column into text."),
    arg, length(bad), if (length(bad) == 1L) "" else "s",
    if (length(bad) == 1L) "is" else "are",
    paste(sprintf("`%s` is %s", bad,
                  vapply(bad, function(cl) class(tbl[[cl]])[1L], character(1))),
          collapse = ", ")
  ), call. = FALSE)
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
  s <- .emoji_drop_nonfinite(s, arg)
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
