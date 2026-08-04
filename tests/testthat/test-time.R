# Tests for the time verbs and the Unicode release table.

grin  <- "\U0001f600"
laugh <- "\U0001f602"
party <- "\U0001f389"

df <- data.frame(
  when = as.Date(c("2024-01-05", "2024-01-20", "2024-02-03")),
  text = c(paste0(grin, " hi"), paste0(grin, laugh), paste0(laugh, " yes"))
)

test_that("emoji_unicode_releases is a unique, ordered lookup", {
  rel <- emoji_unicode_releases()
  expect_named(rel, c("version", "version_num", "series", "release_date"))
  expect_equal(anyDuplicated(rel$version), 0L)
  expect_s3_class(rel$release_date, "Date")
  expect_true(all(rel$series %in% c("emoji", "unicode")))
  expect_false(is.unsorted(rel$version_num))
  expect_equal(rel$release_date[rel$version == "13.0" &
                                  rel$series == "emoji"],
               as.Date("2020-03-10"))
})

test_that("emoji_unicode_version reports a parseable version", {
  v <- emoji_unicode_version()
  expect_length(v, 1L)
  expect_type(v, "character")
  expect_false(is.na(suppressWarnings(as.numeric(v))))
})

test_that("emoji_trend returns a complete period x emoji grid", {
  out <- emoji_trend(df, text, when)
  expect_named(out, c(".period", "emoji", "name", "n", "share"))
  expect_s3_class(out$.period, "Date")
  expect_equal(nrow(out), 4L)                 # 2 periods x 2 emoji
  expect_equal(sort(unique(out$.period)),
               as.Date(c("2024-01-01", "2024-02-01")))
  jan <- out[out$.period == as.Date("2024-01-01"), ]
  expect_equal(jan$n[jan$emoji == grin], 2L)
  expect_equal(jan$share[jan$emoji == grin], 2 / 3)
  feb <- out[out$.period == as.Date("2024-02-01"), ]
  expect_equal(feb$n[feb$emoji == grin], 0L)  # absent periods are kept
  expect_equal(feb$share[feb$emoji == laugh], 1)
})

test_that("emoji_trend honours by, top_n and measure", {
  expect_equal(nrow(emoji_trend(df, text, when, top_n = 1)), 2L)
  expect_equal(emoji_trend(df, text, when, top_n = 1)$emoji, rep(grin, 2))
  yearly <- emoji_trend(df, text, when, by = "year")
  expect_equal(unique(yearly$.period), as.Date("2024-01-01"))
  daily <- emoji_trend(df, text, when, by = "day")
  expect_equal(length(unique(daily$.period)), 3L)
  weekly <- emoji_trend(df, text, when, by = "week")
  expect_equal(as.integer(format(unique(weekly$.period), "%u")),
               rep(1L, length(unique(weekly$.period))))   # Mondays
  expect_error(emoji_trend(df, text, when, by = "fortnight"))
  expect_error(emoji_trend(df, text, when, top_n = -1), "non-negative")
})

test_that("emoji_trend drops rows with unusable times", {
  bad <- data.frame(when = as.Date(c(NA, "2024-01-05")),
                    text = c(grin, laugh))
  out <- emoji_trend(bad, text, when)
  expect_equal(nrow(out), 1L)
  expect_equal(out$emoji, laugh)
  none <- emoji_trend(data.frame(when = as.Date("2024-01-01"), text = "plain"),
                      text, when)
  expect_equal(nrow(none), 0L)
  expect_named(none, c(".period", "emoji", "name", "n", "share"))
})

test_that("emoji_turnover compares consecutive periods", {
  churn <- data.frame(
    when = as.Date(c("2024-01-05", "2024-02-03", "2024-02-20")),
    text = c(paste0(grin, laugh), grin, party)
  )
  out <- emoji_turnover(churn, text, when)
  expect_equal(nrow(out), 1L)
  expect_equal(out$.period, as.Date("2024-02-01"))
  expect_equal(out$.period_prev, as.Date("2024-01-01"))
  expect_equal(out$n_types_prev, 2L)
  expect_equal(out$n_types, 2L)
  expect_equal(out$jaccard, 1 / 3)
  expect_equal(out$n_new, 1L)
  expect_equal(out$n_lost, 1L)
  expect_equal(out$n_core, 1L)
})

test_that("emoji_turnover selects measures and copes with one period", {
  out <- emoji_turnover(df, text, when, measure = "jaccard")
  expect_named(out, c(".period", ".period_prev", "n_types_prev", "n_types",
                      "jaccard"))
  one <- emoji_turnover(df[1, ], text, when)
  expect_equal(nrow(one), 0L)
  expect_s3_class(one$.period, "Date")
})

test_that("emoji_version_profile accounts for every emoji token", {
  out <- emoji_version_profile(df, text)
  expect_named(out, c("version", "version_num", "release_date", "n_types",
                      "n_tokens", "share_types", "share_tokens"))
  expect_equal(sum(out$n_tokens), 4L)          # grin x2, laugh x2
  expect_equal(sum(out$n_types), 2L)
  expect_equal(sum(out$share_tokens), 1)
  expect_false(is.unsorted(out$version_num[!is.na(out$version_num)]))
  expect_equal(nrow(emoji_version_profile(data.frame(text = "plain"), text)),
               0L)
})

test_that("emoji_adoption_lag reports first use against the release date", {
  out <- emoji_adoption_lag(df, text, when)
  expect_named(out, c("emoji", "name", "n", "version", "release_date",
                      "first_seen", "lag_days"))
  expect_setequal(out$emoji, c(grin, laugh))
  expect_equal(out$first_seen[out$emoji == grin], as.Date("2024-01-05"))
  expect_equal(out$first_seen[out$emoji == laugh], as.Date("2024-01-20"))
  expect_equal(out$n[out$emoji == grin], 2L)
  ok <- !is.na(out$lag_days)
  expect_equal(out$lag_days[ok],
               as.integer(out$first_seen[ok] - out$release_date[ok]))
  expect_equal(nrow(emoji_adoption_lag(data.frame(when = as.Date("2024-01-01"),
                                                  text = "plain"),
                                       text, when)), 0L)
})

test_that("emoji_seasonality returns every level of the cycle", {
  season <- data.frame(
    when = as.Date(c("2024-01-05", "2024-01-20", "2024-07-03")),
    text = c(grin, paste0(grin, laugh), "plain")
  )
  out <- emoji_seasonality(season, text, when)
  expect_named(out, c(".period", ".period_label", "n_texts", "n_with_emoji",
                      "n_emoji", "emoji_per_text", "share"))
  expect_equal(nrow(out), 12L)
  expect_equal(out$.period_label, month.abb)
  expect_equal(out$n_texts[1], 2L)
  expect_equal(out$n_with_emoji[1], 2L)
  expect_equal(out$n_emoji[1], 3L)
  expect_equal(out$emoji_per_text[1], 1.5)
  expect_equal(out$share[1], 1)
  expect_equal(out$n_emoji[7], 0L)
  expect_true(is.na(out$emoji_per_text[2]))     # no texts in February
})

test_that("emoji_seasonality supports weekdays and needs POSIXct for hours", {
  wk <- emoji_seasonality(df, text, when, period = "weekday")
  expect_equal(nrow(wk), 7L)
  expect_equal(wk$.period_label[1], "Mon")
  expect_error(emoji_seasonality(df, text, when, period = "hour"), "POSIX")
  hourly <- data.frame(
    when = as.POSIXct(c("2024-01-05 09:30:00", "2024-01-05 09:45:00"),
                      tz = "UTC"),
    text = c(grin, "plain")
  )
  out <- emoji_seasonality(hourly, text, when, period = "hour")
  expect_equal(nrow(out), 24L)
  expect_equal(out$n_texts[out$.period == 9], 2L)
  expect_equal(out$n_emoji[out$.period == 9], 1L)
})

test_that("the time verbs accept character and POSIXct time columns", {
  chr <- data.frame(when = c("2024-01-05", "2024-02-03"),
                    text = c(grin, laugh))
  expect_equal(nrow(emoji_trend(chr, text, when)), 4L)
  pos <- data.frame(when = as.POSIXct(c("2024-01-05 10:00:00",
                                        "2024-02-03 10:00:00"), tz = "UTC"),
                    text = c(grin, laugh))
  expect_equal(nrow(emoji_trend(pos, text, when)), 4L)
  expect_error(emoji_trend(data.frame(when = 1:2, text = c(grin, laugh)),
                           text, when), "Date")
})
