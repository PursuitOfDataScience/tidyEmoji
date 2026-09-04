# Time: adoption, turnover, drift.
#
# Every substantive emoji study is longitudinal or comparative, and until now
# the package had no time verb at all. Two of these are almost free: the
# reference table already carries the Unicode version that introduced each
# glyph, which is a ready-made time axis once it is paired with the release
# dates.

# Coerce a user-supplied time column to Date, refusing anything ambiguous
# rather than guessing.
.emoji_as_date <- function(x, arg = "time") {
  if (inherits(x, "Date")) return(x)
  if (inherits(x, "POSIXt")) {
    # as.Date() on a POSIXct converts in UTC whatever the object's `tzone`
    # says, so a timestamp at 23:30 in a western zone landed on the *next*
    # calendar day -- and for an evening-heavy corpus, systematically so. It
    # also disagreed with emoji_seasonality(period = "hour"), which reads
    # format(x, "%H") and so had always used the timestamp's own zone: the
    # same row could be hour 23 and the following day at once. Take the day
    # the timestamp displays as, which is the day it was posted.
    return(as.Date(format(x, "%Y-%m-%d")))
  }
  if (is.factor(x)) x <- as.character(x)
  if (is.character(x)) {
    d <- suppressWarnings(as.Date(x, format = "%Y-%m-%d"))
    if (anyNA(d) && !all(is.na(x))) {
      d2 <- suppressWarnings(as.Date(x, format = "%Y/%m/%d"))
      d[is.na(d)] <- d2[is.na(d)]
    }
    if (all(is.na(d)) && !all(is.na(x))) {
      stop(sprintf(
        "`%s` must be a Date, a POSIXct, or a character column of dates in %s.",
        arg, "\"YYYY-MM-DD\" form"
      ), call. = FALSE)
    }
    # A value that was present but did not parse becomes NA, and every time
    # verb then drops the row -- indistinguishable, in the result, from a row
    # whose date was genuinely missing. Say how many, since a handful of
    # "2020-13-01" or "Jan 5 2020" in a column silently shrinks the corpus the
    # trend is computed over.
    unparsed <- sum(is.na(d) & !is.na(x))
    if (unparsed > 0L) {
      warning(sprintf(
        paste0("%d value%s in `%s` could not be read as a date and will be ",
               "dropped. Expected \"YYYY-MM-DD\" or \"YYYY/MM/DD\"; first ",
               "unreadable value: %s."),
        unparsed, if (unparsed == 1L) "" else "s", arg,
        encodeString(x[is.na(d) & !is.na(x)][1L], quote = "\"")
      ), call. = FALSE)
    }
    return(d)
  }
  stop(sprintf("`%s` must be a Date, a POSIXct or a date-like character column.",
               arg), call. = FALSE)
}

# Period start for each date. All buckets return a Date so the result sorts and
# plots as a time axis rather than as a string.
.emoji_time_buckets <- function() {
  c("day", "week", "month", "quarter", "year")
}

.emoji_time_bucket <- function(d, by) {
  switch(
    by,
    day = d,
    # back up to the Monday of the same ISO week
    week = d - (as.integer(format(d, "%u")) - 1L),
    month = as.Date(format(d, "%Y-%m-01")),
    quarter = {
      y <- as.integer(format(d, "%Y"))
      m <- (as.integer(format(d, "%m")) - 1L) %/% 3L * 3L + 1L
      out <- rep(as.Date(NA), length(d))
      ok <- !is.na(y) & !is.na(m)
      out[ok] <- as.Date(sprintf("%04d-%02d-01", y[ok], m[ok]))
      out
    },
    year = as.Date(format(d, "%Y-01-01"))
  )
}

# "E15.1" / "15.1" / "" -> "15.1" / "15.1" / NA
.emoji_version_label <- function(v) {
  v <- trimws(as.character(v))
  v <- sub("^[Ee]", "", v)
  v[is.na(v) | !nzchar(v)] <- NA_character_
  v
}

# The same, parsed as a number so versions order sensibly (2.0 before 13.0).
.emoji_version_num <- function(v) {
  suppressWarnings(as.numeric(.emoji_version_label(v)))
}

# Named Date vector: normalised version label -> release date.
.emoji_release_map <- function() {
  rel <- emoji_unicode_releases()
  stats::setNames(rel$release_date, rel$version)
}


#' Unicode and Unicode Emoji release dates
#'
#' `emoji_unicode_releases()` returns the publication date of each Unicode
#' Emoji (UTS #51) data-file release, plus the earlier Unicode versions that
#' introduced emoji before the emoji series was numbered separately. It is the
#' lookup that turns the `version` carried by the emoji reference table into a
#' date, and hence into a time axis.
#'
#' @details
#' Two numbering series exist and both turn up in emoji reference data. The
#' Unicode Emoji series (`series = "emoji"`) runs 1.0, 2.0, ... 5.0 and then
#' jumps to 11.0 to line up with the Unicode version; the Unicode series
#' (`series = "unicode"`) covers the 6.0-10.0 releases that added emoji before
#' the alignment. The two do not collide, so `version` is a unique key.
#'
#' The table is kept in code rather than as a bundled `.rda`: it is a few dozen
#' rows, it changes only when Unicode ships, and keeping it beside the verbs
#' that use it means it can never drift out of sync with them.
#'
#' @return A tibble with columns `version` (character, the normalised label with
#'   any leading `E` removed), `version_num` (the same parsed as a number, for
#'   ordering), `series` (`"emoji"` or `"unicode"`) and `release_date` (a
#'   `Date`).
#' @seealso [emoji_version_profile()] and [emoji_adoption_lag()], which join to
#'   this table; [emoji_unicode_version()] for the version this build reflects.
#' @examples
#' emoji_unicode_releases()
#' @export
emoji_unicode_releases <- function() {
  version <- c(
    "0.6", "0.7", "1.0", "2.0", "3.0", "4.0", "5.0",
    "11.0", "12.0", "12.1", "13.0", "13.1", "14.0", "15.0", "15.1",
    "16.0", "17.0",
    "6.0", "6.1", "7.0", "8.0", "9.0", "10.0"
  )
  series <- c(rep("emoji", 17L), rep("unicode", 6L))
  release_date <- as.Date(c(
    "2010-10-11", "2014-06-16", "2015-06-09", "2015-11-12", "2016-06-21",
    "2016-11-22", "2017-06-20",
    "2018-06-05", "2019-03-05", "2019-10-21", "2020-03-10", "2020-09-15",
    "2021-09-14", "2022-09-13", "2023-09-12", "2024-09-10", "2025-09-09",
    "2010-10-11", "2012-01-31", "2014-06-16", "2015-06-17", "2016-06-21",
    "2017-06-20"
  ))
  out <- tibble::tibble(
    version = version,
    version_num = as.numeric(version),
    series = series,
    release_date = release_date
  )
  out[order(out$version_num, out$series, method = "radix"), , drop = FALSE]
}


#' Which Unicode emoji version does this build reflect?
#'
#' `emoji_unicode_version()` reports the highest emoji version present in the
#' reference table tidyEmoji detects against, i.e. how current your installed
#' \pkg{emoji} package is. Anything newer than this simply will not be
#' recognised as an emoji.
#'
#' @return A single string such as `"15.1"`, or `NA` if the reference table
#'   carries no usable version information.
#' @seealso [emoji_provenance()] for the full provenance row;
#'   [emoji_unicode_releases()] for release dates.
#' @examples
#' emoji_unicode_version()
#' @export
emoji_unicode_version <- function() {
  v <- .emoji_version_num(emoji_reference()$version)
  if (all(is.na(v))) return(NA_character_)
  .emoji_version_label(emoji_reference()$version[which.max(v)])
}


#' Emoji frequency over time
#'
#' `emoji_trend()` counts emoji per time period and returns the long, complete
#' table that plots directly: one row per (period, emoji), including the
#' periods in which an emoji is absent, so a trend line does not silently skip
#' its zeros.
#'
#' @details
#' `share` is the emoji's count divided by all emoji tokens in the same period,
#' which is what makes periods with different volumes comparable. `top_n`
#' selects the emoji to follow, ranked over the whole corpus by `measure`, and
#' the selected set is the same in every period.
#'
#' Rows whose time is missing or unparseable contribute nothing. Glyphs are
#' canonicalised through the package's codepoint key, so qualified and
#' unqualified forms share one series.
#'
#' @inheritParams emoji_summary
#' @param time Unquoted column of dates or date-times (`Date`, `POSIXct`, or
#'   character in `"YYYY-MM-DD"` form). A date-time is bucketed by the calendar
#'   day it *displays* as in its own timezone, not by its UTC day: an emoji
#'   posted at 23:30 New York time belongs to that day, not to the next one.
#'   Character values that cannot be read as a date warn and are dropped.
#' @param by Period length: `"day"`, `"week"` (starting Monday), `"month"`
#'   (default), `"quarter"` or `"year"`.
#' @param top_n Number of emoji to follow, ranked by `measure` over the whole
#'   corpus. `NULL` keeps every emoji. Default `20`.
#' @param measure Statistic used to rank emoji for `top_n` and to order the rows
#'   within a period: `"n"` (default) or `"share"`.
#' @return A tibble with columns `.period` (a `Date`, the start of the period),
#'   `emoji`, `name`, `n` and `share`.
#' @seealso [emoji_turnover()] for vocabulary churn, [emoji_seasonality()] for
#'   cyclical patterns.
#' @examples
#' df <- data.frame(
#'   when = as.Date(c("2024-01-05", "2024-01-20", "2024-02-03")),
#'   text = c("\U0001f600 hi", "\U0001f600\U0001f602", "\U0001f602 yes")
#' )
#' emoji_trend(df, text, when)
#' @export
emoji_trend <- function(data, text, time, by = "month", top_n = 20,
                        measure = c("n", "share")) {
  measure <- match.arg(measure)
  by <- match.arg(by, .emoji_time_buckets())
  if (!is.null(top_n) && !.emoji_is_count(top_n, finite = FALSE)) {
    stop("`top_n` must be a single non-negative whole number, ",
         "or NULL for all.", call. = FALSE)
  }
  .emoji_warn_grouped(data, "emoji_trend", "0.4.0")
  empty <- tibble::tibble(.period = as.Date(character()), emoji = character(),
                          name = character(), n = integer(),
                          share = numeric())

  period <- .emoji_time_bucket(
    .emoji_as_date(.emoji_col(data, {{ time }}, arg = "time")), by
  )
  lst <- lapply(emoji_glyph_list(.emoji_text_col(data, {{ text }})),
                emoji_canonical)
  n_per_row <- lengths(lst)
  glyphs <- unlist(lst, use.names = FALSE)
  when <- rep(period, n_per_row)
  keep <- !is.na(when)
  if (!any(keep)) return(empty)

  counts <- dplyr::count(
    tibble::tibble(.period = when[keep], emoji = glyphs[keep]),
    .period, emoji, name = "n"
  )
  pkey <- as.character(counts$.period)
  period_total <- vapply(split(counts$n, pkey), sum, numeric(1))
  counts$share <- counts$n / period_total[pkey]

  periods <- sort(unique(counts$.period))
  if (measure == "n") {
    rank_stat <- vapply(split(counts$n, counts$emoji), sum, numeric(1))
  } else {
    rank_stat <- vapply(split(counts$share, counts$emoji), sum, numeric(1)) /
      length(periods)
  }
  glyph_order <- names(rank_stat)[
    order(-rank_stat, names(rank_stat), method = "radix")
  ]
  if (!is.null(top_n) && is.finite(top_n)) {
    glyph_order <- utils::head(glyph_order, top_n)
  }
  if (!length(glyph_order)) return(empty)

  out <- tibble::tibble(
    .period = rep(periods, times = length(glyph_order)),
    emoji = rep(glyph_order, each = length(periods))
  )
  idx <- match(
    paste(as.character(out$.period), out$emoji, sep = "\r"),
    paste(pkey, counts$emoji, sep = "\r")
  )
  out$n <- ifelse(is.na(idx), 0L, counts$n[idx])
  out$share <- ifelse(is.na(idx), 0, counts$share[idx])
  ref <- emoji_reference()
  out$name <- ref$name[match(emoji_key(out$emoji), ref$key)]
  out <- out[c(".period", "emoji", "name", "n", "share")]
  if (measure == "n") {
    dplyr::arrange(out, .period, dplyr::desc(n), emoji)
  } else {
    dplyr::arrange(out, .period, dplyr::desc(share), emoji)
  }
}


#' Emoji vocabulary churn between consecutive periods
#'
#' `emoji_turnover()` compares the set of distinct emoji used in each period
#' with the set used in the one before: how much of the vocabulary is shared,
#' how much is new, how much was dropped.
#'
#' @details
#' A period's vocabulary is its set of distinct canonicalised glyphs, so an
#' emoji used a thousand times and one used once count the same -- turnover is
#' about repertoire, not volume. `jaccard` is the size of the intersection over
#' the size of the union, and is `NA` when both periods are empty.
#'
#' @inheritParams emoji_trend
#' @param measure Which statistics to return: any of `"jaccard"`, `"new"`,
#'   `"lost"` and `"core"`. All four by default.
#' @return A tibble with one row per consecutive pair of periods: `.period`,
#'   `.period_prev`, `n_types_prev`, `n_types`, and then the requested
#'   `jaccard`, `n_new`, `n_lost` and `n_core` columns. Fewer than two periods
#'   yields no rows.
#' @seealso [emoji_trend()], [emoji_version_profile()].
#' @examples
#' df <- data.frame(
#'   when = as.Date(c("2024-01-05", "2024-02-03", "2024-02-20")),
#'   text = c("\U0001f600\U0001f602", "\U0001f600", "\U0001f389")
#' )
#' emoji_turnover(df, text, when)
#' @export
emoji_turnover <- function(data, text, time, by = "month",
                           measure = c("jaccard", "new", "lost", "core")) {
  measure <- match.arg(measure, several.ok = TRUE)
  by <- match.arg(by, .emoji_time_buckets())
  .emoji_warn_grouped(data, "emoji_turnover", "0.4.0")

  period <- .emoji_time_bucket(
    .emoji_as_date(.emoji_col(data, {{ time }}, arg = "time")), by
  )
  lst <- lapply(emoji_glyph_list(.emoji_text_col(data, {{ text }})),
                emoji_canonical)
  periods <- sort(unique(period[!is.na(period)]))
  # iterate over indices, not over the Date vector: lapply() strips the class
  # from a Date and would hand the callback a bare number
  vocab <- lapply(seq_along(periods), function(k) {
    sel <- which(!is.na(period) & period == periods[k])
    unique(unlist(lst[sel], use.names = FALSE))
  })

  n <- length(periods)
  out <- tibble::tibble(
    .period = if (n > 1L) periods[-1L] else periods[0L],
    .period_prev = if (n > 1L) periods[-n] else periods[0L],
    n_types_prev = if (n > 1L) {
      as.integer(lengths(vocab[-n]))
    } else {
      integer()
    },
    n_types = if (n > 1L) as.integer(lengths(vocab[-1L])) else integer()
  )
  pair <- function(f) {
    if (n < 2L) return(numeric())
    vapply(seq_len(n - 1L), function(k) f(vocab[[k]], vocab[[k + 1L]]),
           numeric(1))
  }
  if ("jaccard" %in% measure) {
    out$jaccard <- pair(function(a, b) {
      u <- length(union(a, b))
      if (!u) NA_real_ else length(intersect(a, b)) / u
    })
  }
  if ("new" %in% measure) {
    out$n_new <- as.integer(pair(function(a, b) length(setdiff(b, a))))
  }
  if ("lost" %in% measure) {
    out$n_lost <- as.integer(pair(function(a, b) length(setdiff(a, b))))
  }
  if ("core" %in% measure) {
    out$n_core <- as.integer(pair(function(a, b) length(intersect(a, b))))
  }
  out
}


#' How new is this corpus's emoji repertoire?
#'
#' `emoji_version_profile()` breaks a corpus down by the Unicode emoji version
#' that introduced each glyph. A corpus written entirely in emoji from 2015 and
#' one full of 2023 additions look identical to a frequency table and quite
#' different here.
#'
#' @details
#' The version comes from the reference table tidyEmoji detects against, so it
#' is capped by your installed \pkg{emoji} package (see
#' [emoji_unicode_version()]). Glyphs whose version is unknown -- including any
#' the reference table does not carry -- are reported in a row with
#' `version = NA` rather than dropped.
#'
#' The corpus's average vintage is a weighted mean over this table, for example
#' `with(profile, weighted.mean(version_num, n_tokens, na.rm = TRUE))`.
#'
#' @inheritParams emoji_summary
#' @return A tibble with one row per version, oldest first: `version`,
#'   `version_num`, `release_date`, `n_types` (distinct emoji), `n_tokens`
#'   (occurrences), `share_types` and `share_tokens`.
#' @seealso [emoji_adoption_lag()] for how quickly new emoji were picked up;
#'   [emoji_unicode_releases()] for the date lookup.
#' @examples
#' df <- data.frame(text = c("\U0001f600 hello", "\U0001f97a nice"))
#' emoji_version_profile(df, text)
#' @export
emoji_version_profile <- function(data, text) {
  .emoji_warn_grouped(data, "emoji_version_profile", "0.4.0")
  lst <- lapply(emoji_glyph_list(.emoji_text_col(data, {{ text }})),
                emoji_canonical)
  glyphs <- unlist(lst, use.names = FALSE)
  if (!length(glyphs)) {
    return(tibble::tibble(version = character(), version_num = numeric(),
                          release_date = as.Date(character()),
                          n_types = integer(), n_tokens = integer(),
                          share_types = numeric(), share_tokens = numeric()))
  }
  ref <- emoji_reference()
  ver <- .emoji_version_label(ref$version[match(emoji_key(glyphs), ref$key)])

  uv <- unique(ver)
  num <- .emoji_version_num(uv)
  uv <- uv[order(num, uv, na.last = TRUE, method = "radix")]
  sel_of <- function(u) if (is.na(u)) is.na(ver) else !is.na(ver) & ver == u
  n_tokens <- vapply(uv, function(u) sum(sel_of(u)), integer(1),
                     USE.NAMES = FALSE)
  n_types <- vapply(uv, function(u) length(unique(glyphs[sel_of(u)])),
                    integer(1), USE.NAMES = FALSE)
  rel <- .emoji_release_map()
  tibble::tibble(
    version = uv,
    version_num = .emoji_version_num(uv),
    release_date = unname(rel[uv]),
    n_types = n_types,
    n_tokens = n_tokens,
    share_types = n_types / length(unique(glyphs)),
    share_tokens = n_tokens / length(glyphs)
  )
}


#' How long did this population take to adopt each emoji?
#'
#' `emoji_adoption_lag()` compares the date an emoji was first used in your
#' corpus with the date Unicode released it, giving a per-glyph adoption lag in
#' days.
#'
#' @details
#' A lag is only as good as the corpus window: an emoji released before your
#' data begins will look adopted on day one, so read the lag together with `n`
#' and the span of your data. Negative lags mean the corpus contains a glyph
#' before its official release date -- usually a vendor shipping early, or a
#' timestamp problem worth investigating.
#'
#' Occurrences whose time is missing or unparseable are dropped.
#'
#' @inheritParams emoji_trend
#' @return A tibble with one row per emoji, most frequent first: `emoji`,
#'   `name`, `n`, `version`, `release_date`, `first_seen` and `lag_days`.
#'   `lag_days` is `NA` when the release date of the version is unknown.
#' @seealso [emoji_version_profile()], [emoji_unicode_releases()].
#' @examples
#' df <- data.frame(
#'   when = as.Date(c("2021-01-01", "2022-06-01")),
#'   text = c("\U0001f600", "\U0001f97a")
#' )
#' emoji_adoption_lag(df, text, when)
#' @export
emoji_adoption_lag <- function(data, text, time) {
  .emoji_warn_grouped(data, "emoji_adoption_lag", "0.4.0")
  d <- .emoji_as_date(.emoji_col(data, {{ time }}, arg = "time"))
  lst <- lapply(emoji_glyph_list(.emoji_text_col(data, {{ text }})),
                emoji_canonical)
  glyphs <- unlist(lst, use.names = FALSE)
  when <- rep(d, lengths(lst))
  keep <- !is.na(when)
  glyphs <- glyphs[keep]
  when <- when[keep]
  if (!length(glyphs)) {
    return(tibble::tibble(emoji = character(), name = character(),
                          n = integer(), version = character(),
                          release_date = as.Date(character()),
                          first_seen = as.Date(character()),
                          lag_days = integer()))
  }
  first_num <- vapply(split(as.numeric(when), glyphs), min, numeric(1))
  g <- names(first_num)
  first_seen <- as.Date(unname(first_num), origin = "1970-01-01")
  ref <- emoji_reference()
  idx <- match(emoji_key(g), ref$key)
  version <- .emoji_version_label(ref$version[idx])
  release_date <- unname(.emoji_release_map()[version])
  out <- tibble::tibble(
    emoji = g,
    name = ref$name[idx],
    n = vapply(split(glyphs, glyphs), length, integer(1), USE.NAMES = FALSE),
    version = version,
    release_date = release_date,
    first_seen = first_seen,
    lag_days = as.integer(first_seen - release_date)
  )
  dplyr::arrange(out, dplyr::desc(n), emoji)
}


#' Cyclical patterns in emoji use
#'
#' `emoji_seasonality()` aggregates emoji use by month of year, day of week or
#' hour of day. Emoji use is strongly seasonal and strongly diurnal, and both
#' are confounders worth seeing before any trend is interpreted.
#'
#' @details
#' Every level of the cycle is returned, including the empty ones, so a bar
#' chart has no invisible gaps. Labels are fixed English abbreviations rather
#' than locale-dependent ones, so the output of a script does not change with
#' the machine that runs it. Weeks start on Monday.
#'
#' @inheritParams emoji_trend
#' @param period `"month"` (default), `"weekday"` or `"hour"`. `"hour"` needs a
#'   `POSIXct`/`POSIXlt` time column.
#' @return A tibble with one row per level of the cycle: `.period` (integer:
#'   1-12, 1-7 with Monday first, or 0-23), `.period_label`, `n_texts`,
#'   `n_with_emoji`, `n_emoji`, `emoji_per_text` and `share` (this level's share
#'   of all emoji tokens).
#' @seealso [emoji_trend()] for the calendar-time view.
#' @examples
#' df <- data.frame(
#'   when = as.Date(c("2024-01-05", "2024-01-20", "2024-07-03")),
#'   text = c("\U0001f600", "\U0001f600\U0001f602", "plain")
#' )
#' emoji_seasonality(df, text, when)
#' @export
emoji_seasonality <- function(data, text, time,
                              period = c("month", "weekday", "hour")) {
  period <- match.arg(period)
  .emoji_warn_grouped(data, "emoji_seasonality", "0.4.0")
  tv <- .emoji_col(data, {{ time }}, arg = "time")
  if (period == "hour") {
    if (!inherits(tv, "POSIXt")) {
      stop("`period = \"hour\"` needs a POSIXct or POSIXlt `time` column.",
           call. = FALSE)
    }
    idx <- as.integer(format(tv, "%H"))
    levels_i <- 0:23
    labels <- sprintf("%02d", 0:23)
  } else if (period == "month") {
    idx <- as.integer(format(.emoji_as_date(tv), "%m"))
    levels_i <- 1:12
    labels <- month.abb
  } else {
    idx <- as.integer(format(.emoji_as_date(tv), "%u"))
    levels_i <- 1:7
    labels <- c("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun")
  }

  n_per_row <- lengths(emoji_glyph_list(.emoji_text_col(data, {{ text }})))
  total <- sum(n_per_row[!is.na(idx)])
  n_texts <- vapply(levels_i, function(k) sum(!is.na(idx) & idx == k),
                    integer(1))
  n_with <- vapply(levels_i,
                   function(k) sum(!is.na(idx) & idx == k & n_per_row > 0L),
                   integer(1))
  n_emoji <- vapply(levels_i,
                    function(k) sum(n_per_row[!is.na(idx) & idx == k]),
                    integer(1))
  tibble::tibble(
    .period = levels_i,
    .period_label = labels,
    n_texts = n_texts,
    n_with_emoji = n_with,
    n_emoji = n_emoji,
    emoji_per_text = ifelse(n_texts == 0L, NA_real_, n_emoji / n_texts),
    share = if (total == 0L) rep(NA_real_, length(levels_i)) else
      n_emoji / total
  )
}
