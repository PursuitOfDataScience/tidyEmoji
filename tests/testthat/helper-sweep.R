# The CRAN time budget (0.7.0): sweeps and their twins.
#
# CRAN's check farm spends most of this package's check time in a few dozen
# exhaustive tests: every catalogue spelling, every verb, hundreds of random
# strings. Those belong in CI, where NOT_CRAN is true and they keep running on
# every push, and not on CRAN's machines, where 0.6.0's suite took 237 s of CPU
# on the x86_64 flavours. So a test that takes more than half a second in CRAN
# mode is a *sweep*: it starts with skip_sweep(), which stands it down on CRAN,
# and names its *twin*, the test that still runs there and asserts the same
# property over a deterministic sample. A sweep that guards nothing a sample
# could catch says so instead, with a twin argument that begins "no twin:".
#
# A test in test-budget.R reads every test file and fails when a sweep names a
# twin that does not exist, so a twin cannot be renamed or deleted without
# the sweep that relies on it noticing.

# Stand a sweep down on CRAN, the way skip_on_cran() does, but carrying the
# name of the test that runs there in its place.
skip_sweep <- function(twin) {
  if (!is.character(twin) || length(twin) != 1L || is.na(twin) ||
      !nzchar(twin)) {
    stop("skip_sweep() needs the twin's test name, or a \"no twin:\" reason.")
  }
  on_cran <- !interactive() &&
    !isTRUE(as.logical(Sys.getenv("NOT_CRAN", "false")))
  if (on_cran) {
    testthat::skip(paste0("a sweep, run off CRAN; on CRAN: ", twin))
  }
  invisible(TRUE)
}

cp <- function(...) intToUtf8(c(...))

# The cases a sample must never leave out, whatever it draws: the spellings
# where detection has gone wrong before, or could. Every twin over glyphs
# includes them.
sweep_hard_cases <- function() {
  c(
    # keycaps: fully qualified, and the bare spelling without its selector
    cp(0x23, 0xFE0F, 0x20E3), cp(0x31, 0xFE0F, 0x20E3), cp(0x31, 0x20E3),
    # two country flags and the three tag-sequence flags
    cp(0x1F1FA, 0x1F1F8), cp(0x1F1EF, 0x1F1F5),
    cp(0x1F3F4, 0xE0067, 0xE0062, 0xE0065, 0xE006E, 0xE0067, 0xE007F),
    cp(0x1F3F4, 0xE0067, 0xE0062, 0xE0073, 0xE0063, 0xE0074, 0xE007F),
    cp(0x1F3F4, 0xE0067, 0xE0062, 0xE0077, 0xE006C, 0xE0073, 0xE007F),
    # the 16 code points newer than the bundled detection regex, which the
    # derived prefix exists for, one of them toned
    cp(0x1F6D8), cp(0x1F6D9), cp(0x1FA8A), cp(0x1FA8B), cp(0x1FA8C),
    cp(0x1FA8D), cp(0x1FA8E), cp(0x1FAC8), cp(0x1FACC), cp(0x1FACD),
    cp(0x1FADD), cp(0x1FAEA), cp(0x1FAEB), cp(0x1FAEF), cp(0x1FAF9),
    cp(0x1FAFA), cp(0x1FAF9, 0x1F3FD),
    # ZWJ families, and toned couples in matching and mixed tones
    cp(0x1F468, 0x200D, 0x1F469, 0x200D, 0x1F467, 0x200D, 0x1F466),
    cp(0x1F9D1, 0x200D, 0x1F9D1, 0x200D, 0x1F9D2),
    cp(0x1F9D1, 0x1F3FB, 0x200D, 0x2764, 0xFE0F, 0x200D, 0x1F9D1, 0x1F3FF),
    cp(0x1F469, 0x1F3FB, 0x200D, 0x1F91D, 0x200D, 0x1F468, 0x1F3FF),
    cp(0x1F9D1, 0x1F3FD, 0x200D, 0x1F91D, 0x200D, 0x1F9D1, 0x1F3FD),
    # a text-default base with and without its emoji selector, and a toned hand
    cp(0x2764), cp(0x2764, 0xFE0F), cp(0x263A, 0xFE0F), cp(0x1F44D, 0x1F3FD)
  )
}

# Indices of a deterministic sample of `glyphs`: every k-th after ordering by
# code point, never by locale, so the sample is the same on every platform,
# with every hard case that `glyphs` holds always included. `n` is roughly how
# many to draw.
sweep_rows <- function(glyphs, n) {
  key <- vapply(glyphs, function(g) {
    cps <- suppressWarnings(utf8ToInt(g))
    if (anyNA(cps)) "" else paste(sprintf("%06X", cps), collapse = " ")
  }, character(1), USE.NAMES = FALSE)
  o <- order(key, method = "radix")
  k <- max(1L, ceiling(length(glyphs) / n))
  pick <- o[seq(1L, length(o), by = k)]
  hard <- which(glyphs %in% sweep_hard_cases())
  sort(unique(c(pick, hard)))
}

# The sample itself, for a sweep over a plain vector of glyphs.
sweep_sample <- function(glyphs, n) glyphs[sweep_rows(glyphs, n)]

# The values of every `.stride`-th of the calls in `...`, evaluated in the
# caller's frame and left unevaluated otherwise, so a twin can run a
# deterministic share of a sweep's list of verb calls rather than all of them.
sweep_calls <- function(..., .stride = 1L) {
  calls <- as.list(substitute(list(...)))[-1L]
  env <- parent.frame()
  keep <- seq(1L, length(calls), by = .stride)
  lapply(calls[keep], eval, envir = env)
}

# The share of `x` a twin's `i`-th iteration reads: all of it when `stride` is
# 1, and otherwise every `stride`-th element, starting one place later on each
# iteration, so that across the iterations every element is still reached.
sweep_rotate <- function(x, i, stride = 1L) {
  if (stride <= 1L || !length(x)) return(x)
  x[seq(1L + (i - 1L) %% min(stride, length(x)), length(x), by = stride)]
}
