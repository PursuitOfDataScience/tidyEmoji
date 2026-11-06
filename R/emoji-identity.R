# Identity: what a glyph depicts of a person, a skin tone, a gender, a hair
# style, read from its code points and the catalogue (0.7.0).
#
# Every verb in this file describes glyphs and never people. A tone written is
# a keyboard choice and a gender drawn is a design, and neither says who wrote
# the text: the framing the "Glyphs, not people" section of ?tidyEmoji sets
# out, and every help page here links to.

# The five skin tones, in code-point order, U+1F3FB to U+1F3FF.
.emoji_tone_levels <- c("light", "medium_light", "medium", "medium_dark",
                        "dark")

# Gendered person code points and their neutral counterparts, position for
# position: woman and man to person, girl and boy to child, old woman and old
# man to older person.
.emoji_person_female <- c(0x1F469L, 0x1F467L, 0x1F475L)
.emoji_person_male <- c(0x1F468L, 0x1F466L, 0x1F474L)
.emoji_person_neutral <- c(0x1F9D1L, 0x1F9D2L, 0x1F9D3L)

# The four hair components, by the word emoji_decompose() reports.
.emoji_hair_cps <- c(red = 0x1F9B0L, curly = 0x1F9B1L, bald = 0x1F9B2L,
                     white = 0x1F9B3L)

# The catalogue subgroups whose emoji are people, which is what makes a
# component of a sequence a "person" rather than an object.
.emoji_person_subgroups <- c("person", "person-gesture", "person-role",
                             "person-fantasy", "person-activity",
                             "person-sport", "person-resting", "family")

# Single code points whose gender no code-point rule can see, with the neutral
# form Unicode encoded for each where there is one. The first twelve are the
# bases emojibase marks with a gender that lives in one code point (prince,
# princess, Santa Claus, Mrs. Claus, the two dancers, the two pregnant people,
# men and women holding hands, the woman with headscarf, breast-feeding,
# which emojibase calls female where Unicode's name says nothing); the
# thirteenth, the woman and man holding hands, is the package's own "mixed",
# as every multi-person sequence with both genders is.
.emoji_gender_singles <- function() {
  claus <- intToUtf8(c(0x1F9D1, 0x200D, 0x1F384))
  hands <- intToUtf8(c(0x1F9D1, 0x200D, 0x1F91D, 0x200D, 0x1F9D1))
  crown <- intToUtf8(0x1FAC5)
  pregnant <- intToUtf8(0x1FAC4)
  data.frame(
    cp = c(0x1F934L, 0x1F478L, 0x1F385L, 0x1F936L, 0x1F57AL, 0x1F483L,
           0x1FAC3L, 0x1F930L, 0x1F46CL, 0x1F46DL, 0x1F9D5L, 0x1F931L,
           0x1F46BL),
    gender = c("male", "female", "male", "female", "male", "female", "male",
               "female", "male", "female", "female", "female", "mixed"),
    neutral = c(crown, crown, claus, claus, NA, NA, pregnant, pregnant, hands,
                hands, NA, NA, hands),
    stringsAsFactors = FALSE
  )
}

# The catalogue name of a toned spelling with its tones taken out: "kiss:
# person, person, light skin tone, dark skin tone" is the kiss, "handshake:
# light skin tone, dark skin tone" the handshake. Needed only for the
# two-person sequences whose untoned form is a single code point, where
# taking the tones out of the code points gives no catalogue spelling.
.emoji_untoned_name <- function(nm) {
  tone <- "(light|medium-light|medium|medium-dark|dark) skin tone"
  nm <- gsub(paste0(",? *", tone), "", nm)
  nm <- sub(": person, person$", "", nm)
  sub(":? *$", "", nm)
}

# The facts emoji_decompose() reports that a glyph's own code points decide,
# for each of `glyphs`: its base (tones taken out, in the catalogue's
# spelling), the neutral candidate (genders made neutral, where the catalogue
# has that form), the gender the code points and the list say, its tones in
# reading order, hair, and parts. Worked with regular expressions on the
# code-point keys, which are ASCII words, so the whole catalogue costs a few
# vectorised passes. `strip_map` maps the key of a toned spelling with its
# tones taken out to the base, for the sequences where that is not itself a
# catalogue spelling.
.emoji_identity_facts <- function(glyphs, strip_map, keys = emoji_key(glyphs)) {
  bk <- .emoji_by_key()
  singles <- .emoji_gender_singles()
  # a whole token of a key: keys are upper-case hex words separated by
  # spaces, so the edges are explicit rather than a locale's idea of a word
  word <- function(tokens) {
    paste0("(?<![0-9A-F])(", paste(tokens, collapse = "|"), ")(?![0-9A-F])")
  }
  hex <- function(cp) sprintf("%X", cp)
  canon_of <- function(k) {
    out <- bk$canonical[match(k, bk$key)]
    miss <- is.na(out) & !is.na(k)
    out[miss] <- unname(strip_map[k[miss]])
    out
  }
  ok <- !is.na(keys)
  kk <- as.character(keys)
  kk[!ok] <- ""
  # the key with its tones taken out, and the base it names
  sk <- gsub("(^| )1F3F[B-F](?= |$)", "", kk, perl = TRUE)
  sk <- sub("^ ", "", sk)
  sk[!ok | !nzchar(sk)] <- NA_character_
  base <- canon_of(sk)
  # the code-point rule: a sign, or a gendered person; never the sign alone
  f <- grepl(word(c(hex(.emoji_person_female), "2640")), sk, perl = TRUE)
  m <- grepl(word(c(hex(.emoji_person_male), "2642")), sk, perl = TRUE)
  rule <- ifelse(f & m, "mixed", ifelse(f, "female",
                                        ifelse(m, "male", NA_character_)))
  rule <- as.character(rule)
  rule[sk %in% c("2640", "2642")] <- NA_character_
  bkey <- bk$key[match(base, bk$canonical)]
  one <- !is.na(bkey) & !grepl(" ", bkey, fixed = TRUE)
  base_one <- rep(NA_integer_, length(base))
  base_one[one] <- strtoi(bkey[one], 16L)
  si <- match(base_one, singles$cp)
  fill <- is.na(rule) & !is.na(si)
  rule[fill] <- singles$gender[si[fill]]
  # the neutral candidate: the list's, or the base with its signs and their
  # joiners dropped and its people made neutral, if the catalogue spells it
  ck <- gsub(" 200D 264[02](?![0-9A-F])", "", bkey, perl = TRUE)
  for (p in seq_along(.emoji_person_neutral)) {
    ck <- gsub(word(hex(c(.emoji_person_female[[p]], .emoji_person_male[[p]]))),
               hex(.emoji_person_neutral[[p]]), ck, perl = TRUE)
  }
  neutral <- canon_of(ck)
  listed <- !is.na(si)
  neutral[listed] <- singles$neutral[si[listed]]
  hair_m <- regmatches(sk, regexpr(word(hex(.emoji_hair_cps)), sk, perl = TRUE))
  hair <- rep(NA_character_, length(sk))
  has_hair <- grepl(word(hex(.emoji_hair_cps)), sk, perl = TRUE)
  hair[has_hair] <- names(.emoji_hair_cps)[match(hair_m, hex(.emoji_hair_cps))]
  tone_m <- regmatches(kk, gregexpr("(?<![0-9A-F])1F3F[B-F](?![0-9A-F])", kk,
                                    perl = TRUE))
  # parts: the glyph without its tones, split at its joiners, selectors kept.
  # stringi, not gsub(perl = TRUE): PCRE refuses a code point this high in
  # ASCII-only input and under the C locale
  gg <- as.character(glyphs)
  gg[!ok] <- ""
  untoned <- stringi::stri_replace_all_regex(gg, "[\\x{1F3FB}-\\x{1F3FF}]",
                                             "")
  parts <- strsplit(untoned, .emoji_zwj, fixed = TRUE)
  parts <- lapply(parts, function(p) p[nzchar(p)])
  parts[!ok | is.na(sk)] <- list(character(0))
  list(
    base = base,
    rule = rule,
    neutral_candidate = neutral,
    has_neutral_person = grepl(word(hex(.emoji_person_neutral)), sk,
                               perl = TRUE),
    tones = lapply(tone_m, function(t) {
      .emoji_tone_levels[match(t, hex(.emoji_tone_cps))]
    }),
    hair = hair,
    parts = parts,
    ok = ok & !is.na(sk)
  )
}

# The identity of every catalogue key, cached once per session: one row per
# key in the catalogue's canonical spelling, everything emoji_decompose()
# reports, plus `toned`, the catalogue's spelling of each tone-able base in
# each of the five tones with every person in it alike, which emoji_retone()
# and Slack's tone suffix read.
.emoji_identity <- function() {
  if (is.null(.tidyEmoji_cache$identity)) {
    ref <- emoji_reference()
    bk <- .emoji_by_key()
    fq <- ref$status == "fully-qualified"
    toned <- fq & grepl("(^| )1F3F[B-F]( |$)", ref$key)
    tone_tok <- sprintf("%X", .emoji_tone_cps)
    sk <- vapply(strsplit(ref$key[toned], " ", fixed = TRUE), function(t) {
      paste(t[!t %in% tone_tok], collapse = " ")
    }, character(1))
    lost <- !sk %in% bk$key
    named <- ref$emoji[fq][match(.emoji_untoned_name(ref$name[toned][lost]),
                                 ref$name[fq])]
    strip_map <- stats::setNames(named, sk[lost])
    strip_map <- strip_map[!is.na(strip_map) & !duplicated(names(strip_map))]
    f <- .emoji_identity_facts(bk$canonical, strip_map, keys = bk$key)
    # a gender family is every base sharing one neutral candidate; it is
    # gender-variable when it has two or more forms
    fam <- table(f$neutral_candidate[!duplicated(f$base) & !is.na(f$base)])
    families <- stats::setNames(as.integer(fam), names(fam))
    gender <- .emoji_identity_gender(f, families)
    modifiable <- bk$modifiable[match(f$base, bk$canonical)]
    tab <- .emoji_identity_table(f, gender, modifiable, families, NULL)
    tab$key <- bk$key
    tab$name <- ref$name[match(bk$key, ref$key)]
    # each tone-able base in each tone, every person alike: the first such
    # catalogue spelling, in catalogue order
    t1 <- ref$emoji[toned]
    tl <- lapply(t1, function(g) {
      c <- utf8ToInt(g)
      unique(c[c %in% .emoji_tone_cps])
    })
    alike <- lengths(tl) == 1L
    tb <- bk$canonical[match(sk[alike], bk$key)]
    miss <- is.na(tb)
    tb[miss] <- unname(strip_map[sk[alike][miss]])
    tk <- paste(bk$key[match(tb, bk$canonical)],
                .emoji_tone_levels[unlist(tl[alike]) - 0x1F3FAL])
    toned_map <- stats::setNames(t1[alike], tk)
    toned_map <- toned_map[!duplicated(names(toned_map))]
    .tidyEmoji_cache$identity <- list(
      table = tab, strip_map = strip_map, families = families,
      toned = toned_map
    )
  }
  .tidyEmoji_cache$identity
}

# The gender each glyph depicts: what the code points and the list say, else
# "neutral" for the neutral form of a gender family or a sequence built on
# the neutral person, child or older person, else NA.
.emoji_identity_gender <- function(f, families) {
  g <- f$rule
  size <- unname(families[f$neutral_candidate])
  size[is.na(size)] <- 0L
  is_neutral_form <- !is.na(f$base) & !is.na(f$neutral_candidate) &
    f$base == f$neutral_candidate & size >= 2L
  g[is.na(g) & (is_neutral_form | f$has_neutral_person)] <- "neutral"
  g
}

# Assemble emoji_decompose()'s columns from the facts. `known` is the cached
# table, used to read the gender of a neutral candidate the facts did not
# compute (NULL while the cache itself is being built).
.emoji_identity_table <- function(f, gender, modifiable, families, known) {
  tones <- f$tones
  n_tones <- vapply(tones, function(t) length(unique(t)), integer(1))
  first <- vapply(tones, function(t) {
    if (length(t)) t[[1L]] else NA_character_
  }, character(1))
  tone <- as.character(ifelse(n_tones == 0L, "default",
                              ifelse(n_tones == 1L, first, "mixed")))
  tone_str <- vapply(tones, function(t) {
    if (length(t)) paste(t, collapse = "|") else "default"
  }, character(1))
  modifiable[is.na(f$base)] <- NA
  tone[!modifiable %in% TRUE] <- NA_character_
  tone_str[!modifiable %in% TRUE] <- NA_character_
  n_tones[!modifiable %in% TRUE] <- NA_integer_
  # the neutral form is reported where the glyph depicts a gender and the
  # candidate is itself gender-neutral
  cand <- f$neutral_candidate
  cand_gender <- if (is.null(known)) {
    gender[match(cand, f$base)]
  } else {
    known$gender[match(cand, .emoji_by_key()$canonical)]
  }
  neutral <- cand
  neutral[is.na(gender) | !cand_gender %in% "neutral"] <- NA_character_
  family <- unname(families[f$neutral_candidate])
  family[is.na(family)] <- 0L
  tibble::tibble(
    base = f$base,
    neutral = neutral,
    tone = tone,
    tones = tone_str,
    n_tones = n_tones,
    gender = gender,
    hair = f$hair,
    n_parts = as.integer(ifelse(f$ok & lengths(f$parts) > 0L,
                                lengths(f$parts), NA_integer_)),
    parts = vapply(f$parts, function(p) {
      if (length(p)) paste(p, collapse = "|") else NA_character_
    }, character(1)),
    modifiable = modifiable,
    family = as.integer(family)
  )
}

# emoji_decompose()'s wide rows for `x`, catalogue spellings read from the
# cache by key and anything else computed on the fly.
.emoji_identity_lookup <- function(x) {
  id <- .emoji_identity()
  tab <- id$table
  k <- emoji_key(x)
  i <- match(k, tab$key)
  out <- tab[i, , drop = FALSE]
  miss <- which(is.na(i) & !is.na(x))
  if (length(miss)) {
    f <- .emoji_identity_facts(x[miss], id$strip_map, keys = k[miss])
    gender <- .emoji_identity_gender(f, id$families)
    bk <- .emoji_by_key()
    modifiable <- bk$modifiable[match(f$base, bk$canonical)]
    extra <- .emoji_identity_table(f, gender, modifiable, id$families, tab)
    extra$key <- k[miss]
    extra$name <- NA_character_
    out[miss, names(extra)] <- extra
  }
  out
}


# Split each canonical glyph into its components for long = TRUE: a joiner
# separates two, a skin tone is one of its own, and a selector stays with the
# component before it.
.emoji_components <- function(glyph) {
  c <- suppressWarnings(utf8ToInt(glyph))
  if (anyNA(c) || !length(c)) return(character(0))
  out <- character(0)
  cur <- integer(0)
  for (p in c) {
    if (p == 0x200DL || p %in% .emoji_tone_cps) {
      if (length(cur)) out <- c(out, intToUtf8(cur))
      cur <- integer(0)
      if (p != 0x200DL) out <- c(out, intToUtf8(p))
      next
    }
    cur <- c(cur, p)
  }
  if (length(cur)) out <- c(out, intToUtf8(cur))
  out
}

.emoji_decompose_long <- function(x) {
  ref <- emoji_reference()
  canon <- as_emoji_canonical(x)
  comps <- lapply(seq_along(x), function(i) {
    if (is.na(x[[i]])) character(0) else .emoji_components(canon[[i]])
  })
  n <- lengths(comps)
  comp <- as.character(unlist(comps, use.names = FALSE))
  k <- emoji_key(comp)
  ri <- match(k, ref$key)
  cps <- lapply(comp, function(g) utf8ToInt(g)[utf8ToInt(g) != 0xFE0FL])
  one <- vapply(cps, function(c) if (length(c) == 1L) c else NA_integer_,
                integer(1))
  role <- ifelse(one %in% .emoji_tone_cps, "tone",
          ifelse(one %in% .emoji_hair_cps, "hair",
          ifelse(one %in% c(0x2640L, 0x2642L), "gender_sign",
          ifelse(ref$subgroup[ri] %in% .emoji_person_subgroups, "person",
          ifelse(!is.na(ri), "object", "other")))))
  tibble::tibble(
    emoji = rep(x, n),
    position = as.integer(sequence(n)),
    component = comp,
    role = as.character(role),
    component_name = ref$name[ri]
  )
}


#' Take an emoji apart: base, skin tone, gender and hair
#'
#' `emoji_decompose()` reports, for each glyph, what it depicts of a person
#' and how it is built: the emoji with its skin tones taken out, its
#' gender-neutral form, its tones, the gender and hair it shows, and the
#' components it is joined from. It describes glyphs, never the people who
#' write them; see *Glyphs, not people* in [tidyEmoji]. It is what
#' [emoji_skin_tone()], [emoji_gender()] and [emoji_retone()] read.
#'
#' @details
#' Each glyph is canonicalised first, so the bare heart `U+2764` and the
#' qualified `U+2764 U+FE0F` decompose alike, and read from a table the
#' package builds once per session over the catalogue; a glyph the catalogue
#' does not list, such as a face followed by a swatch it cannot take, is
#' worked out on the fly.
#'
#' * **Tone** is `"default"` for a glyph that takes a tone and has none,
#'   `"light"`, `"medium_light"`, `"medium"`, `"medium_dark"` or `"dark"`
#'   for one tone however many people carry it, and `"mixed"` for two or
#'   more, as on a couple with two tones. It is `NA` only where the glyph
#'   cannot take a tone. `tones` lists every tone in reading order.
#' * **Gender** is the one the glyph is drawn with: `"female"` or `"male"`
#'   from the female and male signs `U+2640` and `U+2642` or a gendered
#'   person (woman, man, girl, boy, old woman, old man), and from a list of
#'   twelve emoji whose gender lives in one code point (prince and princess,
#'   Santa and Mrs. Claus, the two dancers, the two pregnant people, men and
#'   women holding hands, the woman with headscarf, and breast-feeding, which
#'   the list follows emojibase in calling female); `"mixed"` for a
#'   multi-person emoji with both, a derivation of this package's own;
#'   `"neutral"` for the gender-neutral form, which platforms draw
#'   differently; `NA` where no gender is depicted.
#' * **Neutral** is the gender-neutral form the catalogue has, so woman
#'   running gives person running and woman technologist gives technologist;
#'   `NA` where there is none.
#' * **Base** is the glyph with every tone taken out, in the catalogue's
#'   spelling. For a two-person emoji written as one code point untoned, a
#'   kiss or a handshake, the toned spellings are joined sequences and the
#'   base is the single code point.
#'
#' @param x A character vector of glyphs.
#' @param long If `TRUE`, return one row per component instead, the way
#'   [emoji_emotion()] does: `emoji`, `position`, `component`, `role`
#'   (`"person"`, `"object"`, `"gender_sign"`, `"hair"`, `"tone"` or
#'   `"other"`) and `component_name`.
#' @return With `long = FALSE`, a tibble with one row per element of `x`:
#'   `emoji` (as given), `name`, `base`, `neutral`, `tone`, `tones`,
#'   `n_tones` (distinct tones), `gender`, `hair` (`"red"`, `"curly"`,
#'   `"white"` or `"bald"`, `NA` otherwise), `n_parts` (the components a
#'   zero-width joiner joins, 1 for a glyph with no joiner), `parts` (those
#'   components without their tones, separated by `"|"`) and `modifiable`
#'   (whether the base takes a tone). `NA` input gives a row of `NA`.
#' @seealso [emoji_skin_tone()], [emoji_gender()] and [emoji_retone()],
#'   which apply it to a text column; [emoji_properties()] for what the
#'   catalogue records.
#' @examples
#' couple <- "\U0001f469\U0001f3fb\u200d\u2764\ufe0f\u200d\U0001f468\U0001f3ff"
#' emoji_decompose(c("\U0001f44d\U0001f3fd", couple, "\U0001f3c3\u200d\u2640\ufe0f"))
#' emoji_decompose(couple, long = TRUE)
#' @concept identity
#' @export
emoji_decompose <- function(x, long = FALSE) {
  x <- .emoji_check_glyphs(x)
  .emoji_check_flag(long, "long")
  if (long) return(.emoji_decompose_long(x))
  w <- .emoji_identity_lookup(x)
  tibble::tibble(
    emoji = x,
    name = w$name,
    base = w$base,
    neutral = w$neutral,
    tone = w$tone,
    tones = w$tones,
    n_tones = w$n_tones,
    gender = w$gender,
    hair = w$hair,
    n_parts = w$n_parts,
    parts = w$parts,
    modifiable = w$modifiable
  )
}

# The occurrences of each row of `v` with their decomposition, and the row
# each belongs to.
.emoji_identity_occurrences <- function(v, presentation) {
  occ <- .emoji_occurrences(v, presentation)
  w <- .emoji_identity_lookup(occ$.emoji)
  w$.row_number <- occ$.row_number
  w$.emoji <- occ$.emoji
  w
}

# One value per row from per-occurrence values: the single one, "mixed" for
# several, NA for none.
.emoji_row_single <- function(value, row, n) {
  out <- rep(NA_character_, n)
  ok <- !is.na(value)
  if (!any(ok)) return(out)
  u <- lapply(split(value[ok], factor(row[ok], levels = seq_len(n))), unique)
  one <- lengths(u) == 1L
  out[one] <- vapply(u[one], `[[`, character(1), 1L)
  out[lengths(u) > 1L] <- "mixed"
  out
}


#' Skin tones in a text column, with their denominator
#'
#' `emoji_skin_tone()` counts, per row, the emoji that can carry a skin tone,
#' how many of them do, and which tones they carry. It describes the glyphs
#' a text uses and never infers anyone's skin colour or identity; see
#' *Glyphs, not people* in [tidyEmoji].
#'
#' @details
#' Both halves of that sentence have evidence behind them. Writers mostly
#' choose a tone close to their own (Robertson, Magdy and Goldwater 2018,
#' 2020), so tones *are* informative about writers in aggregate; and readers
#' infer the writer's identity from a tone, the default yellow included
#' (CSCW 2021), which is exactly why a tool must not. `"default"` means a
#' tone-able emoji written without a tone, which is a keyboard setting on
#' some platforms and an active choice on others.
#'
#' **Report the denominator.** The share of tone-able emoji that carry a tone
#' differs tenfold between corpora: 88.9% of 117 on the tweet sample this
#' package bundled until 0.7.0, 9.2% of 782 in all of OASST2, 8.0% of 1,445
#' in a WildChat shard, and 23.2% of 181 in [oasst_messages], whose half
#' carrying emoji was sampled for them. A bare percentage cannot tell a
#' difference in the writers from a difference in which emoji they chose, so
#' the verb returns the two counts and leaves the ratio to you, which is also
#' what makes it right for any grouping:
#'
#' ```
#' emoji_skin_tone(d, text) |>
#'   dplyr::group_by(author) |>
#'   dplyr::summarise(modified = sum(.emoji_n_modified),
#'                    modifiable = sum(.emoji_n_modifiable),
#'                    share = modified / modifiable)
#' ```
#'
#' A swatch standing alone, as in `U+1F600 U+1F3FB`, where the face cannot
#' take the tone, is no emoji (see the *Detection* section of [tidyEmoji])
#' and so in none of the tone counts; `.emoji_n_orphan_modifiers` accounts
#' for it.
#'
#' @inheritParams emoji_summary
#' @return `data`, as a tibble, with added columns `.emoji_n_modifiable`
#'   (occurrences of an emoji that can take a tone, toned or not),
#'   `.emoji_n_modified` (those that carry one), `.emoji_n_light`,
#'   `.emoji_n_medium_light`, `.emoji_n_medium`, `.emoji_n_medium_dark` and
#'   `.emoji_n_dark` (tone instances, so a couple in two tones adds to two
#'   columns and one in a single tone adds two to one), `.emoji_n_mixed`
#'   (occurrences carrying two or more distinct tones),
#'   `.emoji_n_orphan_modifiers` (swatches standing alone) and `.emoji_tone`
#'   (the row's one tone, `"default"`, `"mixed"` when its tone-able emoji
#'   differ, or `NA` when it has none). A grouped input stays grouped.
#' @references
#' Robertson, A., Magdy, W. and Goldwater, S. (2018). Self-representation on
#' Twitter using emoji skin color modifiers. *ICWSM 2018*, 680-683.
#'
#' Robertson, A., Magdy, W. and Goldwater, S. (2020). Emoji skin tone
#' modifiers: analyzing variation in usage on social media. *ACM Transactions
#' on Social Computing* 3(2). \doi{10.1145/3377479}
#'
#' Black or white but never neutral: how readers perceive identity from
#' yellow or skin-toned emoji (2021). *Proceedings of the ACM on
#' Human-Computer Interaction* 5 (CSCW2). \doi{10.1145/3476091}
#' @seealso [emoji_decompose()] for one glyph at a time; [emoji_retone()] to
#'   rewrite the tones for an experiment.
#' @examples
#' d <- data.frame(text = c("thanks \U0001f44d\U0001f3fd",
#'                          "\U0001f44d and \U0001f44b\U0001f3ff",
#'                          "a \U0001f600\U0001f3fb b"))
#' emoji_skin_tone(d, text)
#' @concept identity
#' @export
emoji_skin_tone <- function(data, text, presentation = "emoji") {
  presentation <- .emoji_check_presentation(presentation)
  v <- .emoji_text_col(data, {{ text }})
  n <- length(v)
  w <- .emoji_identity_occurrences(v, presentation)
  row <- w$.row_number
  mod <- w$modifiable %in% TRUE
  tally <- function(keep) tabulate(row[keep], nbins = n)
  out <- .emoji_as_tibble(data)
  out$.emoji_n_modifiable <- tally(mod)
  out$.emoji_n_modified <- tally(mod & w$tone != "default")
  toned <- w$tones
  toned[!(mod & w$tone %in% c(.emoji_tone_levels, "mixed"))] <- ""
  inst <- strsplit(as.character(toned), "|", fixed = TRUE)
  for (lv in .emoji_tone_levels) {
    k <- vapply(inst, function(t) sum(t == lv), integer(1))
    out[[paste0(".emoji_n_", lv)]] <- as.integer(tabulate(rep(row, k),
                                                          nbins = n))
  }
  out$.emoji_n_mixed <- tally(mod & w$tone == "mixed")
  # swatches standing alone: D1's component spans that are a tone
  sp <- .emoji_spans(v, presentation)
  w0 <- v
  w0[is.na(w0)] <- ""
  out$.emoji_n_orphan_modifiers <- vapply(seq_len(n), function(i) {
    k <- sp$kinds[[i]]
    if (is.null(k) || !any(k == .emoji_kind_component)) return(0L)
    g <- .emoji_slice(sp$locs[[i]][k == .emoji_kind_component, , drop = FALSE],
                      w0[[i]])
    sum(vapply(g, function(s) {
      c <- utf8ToInt(s)
      c <- c[c != 0xFE0FL]
      length(c) == 1L && c %in% .emoji_tone_cps
    }, logical(1)))
  }, integer(1))
  out$.emoji_tone <- .emoji_row_single(ifelse(mod, w$tone, NA_character_),
                                       row, n)
  out
}


#' The gender the emoji in a text column depict
#'
#' `emoji_gender()` counts, per row, the person emoji by the gender they are
#' drawn with. This is the gender a glyph depicts, not the writer's and not
#' the reader's; see *Glyphs, not people* in [tidyEmoji]. Studies of the
#' gender of the *people* sending emoji, such as Lin (2025), ask a different
#' question, which this verb does not answer.
#'
#' @details
#' The classification is [emoji_decompose()]'s: the female and male signs,
#' the gendered people (woman, man, girl, boy, old woman, old man), and a
#' list of twelve emoji whose gender lives in a single code point, such as
#' prince and princess. `"mixed"` is a multi-person emoji showing both, a
#' couple or a family, and is this package's own derivation. `"neutral"` is
#' Unicode's gender-neutral form, which platforms draw differently.
#'
#' **Gender-variable** emoji are the ones whose catalogue family has more
#' than one gender form: person, woman and man running, or the prince, the
#' princess and the person with crown. The families are derived from the
#' catalogue, by grouping every emoji under its gender-neutral form, not
#' listed by hand. `.emoji_n_gender_variable` is the denominator for "how
#' often did writers pick a gendered form": the woman dancing has no other
#' form and so is female without being a choice.
#'
#' @inheritParams emoji_summary
#' @return `data`, as a tibble, with added columns
#'   `.emoji_n_gender_variable` (occurrences of a person emoji whose family
#'   has more than one gender form), `.emoji_n_female`, `.emoji_n_male`,
#'   `.emoji_n_neutral` and `.emoji_n_mixed` (occurrences by the gender they
#'   depict) and `.emoji_gender` (the row's one gender, `"mixed"` when its
#'   emoji differ, or `NA` when none depicts a gender). A grouped input stays
#'   grouped.
#' @references
#' Lin, Z.-X. (2025). Exploring gender differences in emoji usage:
#' implications for human-computer interaction. *Proceedings of the Fourth
#' Workshop on Bridging Human-Computer Interaction and Natural Language
#' Processing (HCI+NLP)*, 274-282.
#' @seealso [emoji_decompose()]; [emoji_skin_tone()] for tones.
#' @examples
#' d <- data.frame(text = c("\U0001f3c3\u200d\u2640\ufe0f and \U0001f3c3",
#'                          "\U0001f483 \U0001f57a",
#'                          "no people \U0001f600"))
#' emoji_gender(d, text)
#' @concept identity
#' @export
emoji_gender <- function(data, text, presentation = "emoji") {
  presentation <- .emoji_check_presentation(presentation)
  v <- .emoji_text_col(data, {{ text }})
  n <- length(v)
  w <- .emoji_identity_occurrences(v, presentation)
  row <- w$.row_number
  tally <- function(keep) tabulate(row[keep], nbins = n)
  out <- .emoji_as_tibble(data)
  out$.emoji_n_gender_variable <- tally(w$family >= 2L & !is.na(w$gender))
  for (g in c("female", "male", "neutral", "mixed")) {
    out[[paste0(".emoji_n_", g)]] <- tally(w$gender %in% g)
  }
  out$.emoji_gender <- .emoji_row_single(w$gender, row, n)
  out
}


#' Rewrite every skin tone in a text column to one tone
#'
#' `emoji_retone()` rewrites the text so that every emoji that can carry a
#' skin tone carries `tone`, every person in a multi-person emoji alike, and
#' `"default"` takes the tones out. It rewrites glyphs for an experiment and
#' describes no person; see *Glyphs, not people* in [tidyEmoji].
#'
#' @details
#' **Why it exists.** The way to measure how a model treats skin tones is to
#' give it the same text in each tone and compare, as "Digital Skin, Digital
#' Bias" (Li et al. 2026) does for language models and emoji embeddings. A
#' regular expression over `U+1F3FB` to `U+1F3FF` gets multi-person emoji and
#' the selector cases wrong; this reads the catalogue instead. A paired
#' design:
#'
#' ```
#' arms <- c("default", "light", "medium", "dark")
#' copies <- lapply(arms, function(t) emoji_retone(d, text, tone = t))
#' # score each copy with your own model, then compare the arms row by row
#' ```
#'
#' **Rules.** The rewritten spelling is always one the catalogue lists. Where
#' there is none, the occurrence is left as it was and counted in
#' `.emoji_n_unretonable`; on the Emoji 18.0 catalogue that never happens. A
#' swatch standing alone is left alone, and so is every emoji that cannot
#' take a tone. The column is rewritten in place, as [emoji_sanitize()] does.
#'
#' @inheritParams emoji_summary
#' @param tone The tone to write: `"default"` (no tone, the default),
#'   `"light"`, `"medium_light"`, `"medium"`, `"medium_dark"` or `"dark"`.
#' @return `data`, as a tibble, with the text column rewritten and two
#'   columns added: `.emoji_n_retoned` (the tone-able occurrences now in
#'   `tone`, the ones already in it included) and `.emoji_n_unretonable`
#'   (those left as they were for want of a catalogue spelling). The two add
#'   up to [emoji_skin_tone()]'s `.emoji_n_modifiable`. A grouped input stays
#'   grouped.
#' @references
#' Li, M. et al. (2026). Digital skin, digital bias: uncovering tone-based
#' biases in LLMs and emoji embeddings. *Proceedings of the ACM Web
#' Conference 2026*. \doi{10.1145/3774904.3792508}
#' @seealso [emoji_skin_tone()] to count the tones first; [emoji_decompose()].
#' @examples
#' d <- data.frame(text = c("thanks \U0001f44d\U0001f3fd",
#'                          "\U0001f9d1\U0001f3fb\u200d\U0001f91d\u200d\U0001f9d1\U0001f3ff"))
#' emoji_retone(d, text, tone = "dark")
#' emoji_retone(d, text)
#' @concept identity
#' @export
emoji_retone <- function(data, text, tone = "default",
                         presentation = "emoji") {
  tone <- .emoji_match_arg(tone, c("default", .emoji_tone_levels), "tone")
  presentation <- .emoji_check_presentation(presentation)
  col_name <- .emoji_col_name(data, {{ text }})
  v <- .emoji_text_col(data, {{ text }})
  was_na <- is.na(v)
  v[was_na] <- ""
  n <- length(v)
  locs <- .emoji_locations(v, presentation)
  id <- .emoji_identity()
  retoned <- unretonable <- integer(n)
  rewritten <- v
  for (i in which(vapply(locs, nrow, integer(1)) > 0L)) {
    m <- locs[[i]]
    g <- .emoji_slice(m, v[[i]])
    w <- .emoji_identity_lookup(g)
    mod <- w$modifiable %in% TRUE
    if (!any(mod)) next
    target <- if (tone == "default") w$base else
      unname(id$toned[paste(.emoji_by_key()$key[
        match(w$base, .emoji_by_key()$canonical)], tone)])
    already <- w$tone %in% tone
    swap <- mod & !already & !is.na(target)
    retoned[[i]] <- sum(mod & (already | !is.na(target)))
    unretonable[[i]] <- sum(mod & !already & is.na(target))
    if (any(swap)) {
      rpl <- ifelse(swap, target, NA_character_)
      rewritten[[i]] <- .emoji_replace_in_order(v[[i]], m, g, rpl)
    }
  }
  rewritten[was_na] <- NA_character_
  out <- .emoji_as_tibble(data)
  out[[col_name]] <- rewritten
  out$.emoji_n_retoned <- retoned
  out$.emoji_n_unretonable <- unretonable
  .emoji_regroup(out, col_name)
}
