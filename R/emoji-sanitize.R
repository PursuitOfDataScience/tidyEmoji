# LLM-era plumbing: what do emoji cost, and what should a pipeline do with
# them?
#
# Emoji are now a preprocessing decision in every LLM pipeline, and the
# decision matters: they inflate token counts several-fold and models
# disambiguate them poorly. tidyEmoji already owns the detection and
# translation primitives, so this is mostly packaging what exists behind one
# verb whose argument shows up in a script diff and in a methods section.

.emoji_sanitize_policies <- function() {
  c("keep", "strip", "name", "shortcode", "placeholder")
}


#' Apply an explicit emoji policy to a text column
#'
#' `emoji_sanitize()` rewrites a text column under one named policy: keep the
#' emoji, delete them, spell them out as names or shortcodes, or replace them
#' with a placeholder token. The value is not new capability -- most of it
#' exists across [emoji_to_text()] and the extraction verbs -- but a single
#' argument that says which choice was made, so that "we replaced emoji with
#' their Unicode names" becomes a reproducibility statement rather than a
#' forgotten line of `gsub()`.
#'
#' @details
#' The policies:
#'
#' * `"keep"` returns the text untouched. It is the honest baseline for an A/B
#'   comparison, and it means the policy argument can stay in the script even
#'   when the answer is "do nothing".
#' * `"strip"` deletes the emoji. Because deleting a glyph can leave two spaces
#'   where there was one, `strip` also collapses runs of spaces and tabs and
#'   trims the ends -- the only policy that touches anything but the emoji.
#' * `"name"` and `"shortcode"` substitute the Unicode name
#'   ("grinning face") or the GitHub-style alias (":grinning:"), exactly as
#'   [emoji_to_text()] does. `name` is also the accessibility answer: it is
#'   what a screen reader announces.
#' * `"placeholder"` substitutes a fixed token, which keeps the *position* of
#'   an emoji as a feature while removing its identity.
#'
#' Replacements go exactly where the glyph was, with no padding, so a grinning
#' face glued to the end of a word yields `"wordgrinning face"`. If your
#' tokeniser needs whitespace around them, use `"placeholder"` with a padded
#' placeholder such as `" [emoji] "`.
#'
#' @section Which policies can be undone:
#' The five policies are not five parallel options: they are a ladder of
#' information loss, and how far down it you step is invisible until you try to
#' put the emoji back after the model call.
#'
#' | `policy` | `"great <U+1F600> work"` becomes | Restorable with [text_to_emoji()]? | What is lost |
#' |---|---|---|---|
#' | `"keep"` | `great <U+1F600> work` | yes | nothing |
#' | `"shortcode"` | `great :grinning: work` | **yes** | nothing |
#' | `"name"` | `great grinning face work` | no | the delimiters; the name is now ordinary words |
#' | `"placeholder"` | `great [emoji] work` | no | *which* emoji -- the position survives |
#' | `"strip"` | `great work` | no | that there was an emoji at all |
#'
#' So if the pipeline has to restore emoji downstream, `"shortcode"` is the
#' only policy that permits it, and it holds up on the awkward cases:
#' skin-tone modifiers, flags, ZWJ sequences and keycaps all come back.
#' Measured against the whole reference table of \pkg{emoji} 16.0.0: for all
#' 3790 emoji in their canonical (fully qualified) spelling -- the spelling a
#' keyboard emits and text normally holds -- **the round trip returns the
#' original text byte for byte, 100% of the time**.
#'
#' Unicode also lists shorter spellings of the same emoji, with the `U+FE0F`
#' presentation selectors omitted. Feed one of those in and the round trip
#' returns the *canonical* spelling instead: `U+270C` comes back as
#' `U+270C U+FE0F`. Across all 4853 catalogued spellings that is 79.5%
#' byte-identical, and the remaining 20.5% differ by `U+FE0F` alone -- never
#' by more. The emoji is always the same emoji, and every tidyEmoji lookup
#' treats the two spellings as one, so this matters only if you are diffing raw
#' bytes on text that had its selectors stripped upstream.
#'
#' `"placeholder"` keeps *where* but not *which*, which is enough to use "an
#' emoji was here" as a model feature and not enough to reconstruct the text.
#' `"name"` is the accessibility answer rather than the reversible one -- it
#' is what a screen reader announces.
#'
#' @inheritParams emoji_summary
#' @param policy One of `"keep"` (default), `"strip"`, `"name"`,
#'   `"shortcode"` or `"placeholder"`.
#' @param placeholder Replacement token for `policy = "placeholder"`. Default
#'   `"[emoji]"`.
#' @param wrap Template for `policy = "shortcode"`, with `{x}` standing for the
#'   shortcode. Default `":{x}:"`.
#' @return `data`, as a tibble, with the text column rewritten in place (same
#'   column name). `NA` entries stay `NA`.
#' @seealso [emoji_token_cost()] for what the emoji are costing you;
#'   [emoji_to_text()] for the name/shortcode rewrite on its own.
#' @examples
#' df <- data.frame(text = c("ship it \U0001f680", "no emoji"))
#' emoji_sanitize(df, text, policy = "strip")
#' emoji_sanitize(df, text, policy = "name")
#' emoji_sanitize(df, text, policy = "placeholder")
#' @export
emoji_sanitize <- function(data, text, policy = "keep",
                           placeholder = "[emoji]", wrap = ":{x}:") {
  policy <- match.arg(policy, .emoji_sanitize_policies())
  # resolve the column even for "keep", so a typo is an error under every
  # policy rather than only under the ones that rewrite
  col_name <- .emoji_col_name(data, {{ text }})
  if (policy == "keep") {
    return(.emoji_as_tibble(data))
  }
  if (policy %in% c("name", "shortcode")) {
    return(emoji_to_text(data, {{ text }}, format = policy, wrap = wrap))
  }
  if (policy == "placeholder") .emoji_check_string(placeholder, "placeholder")

  v <- .emoji_text_col(data, {{ text }})
  was_na <- is.na(v)
  v[was_na] <- ""
  locs <- .emoji_locations(v)
  rewritten <- vapply(seq_along(v), function(i) {
    m <- locs[[i]]
    if (is.null(m) || nrow(m) == 0L) return(v[[i]])
    g <- .emoji_slice(m, v[[i]])
    rpl <- if (policy == "strip") rep("", length(g)) else
      rep(placeholder, length(g))
    .emoji_replace_in_order(v[[i]], m, g, rpl)
  }, character(1))
  if (policy == "strip") {
    # only tidy the rows a glyph was actually removed from
    had <- vapply(locs, function(m) !is.null(m) && nrow(m) > 0L, logical(1))
    rewritten[had] <- trimws(gsub("[ \t]{2,}", " ", rewritten[had]))
  }
  rewritten[was_na] <- NA_character_

  out <- .emoji_as_tibble(data)
  out[[col_name]] <- rewritten
  .emoji_regroup(out, col_name)
}


#' What are the emoji in this text costing a tokeniser?
#'
#' `emoji_token_cost()` measures the size of the emoji in each row: bytes, code
#' points, grapheme clusters, and an estimate of the tokens they will cost a
#' byte-level tokeniser. Emoji are several times more expensive than their
#' visual weight suggests -- a single ZWJ family emoji can run to well over a
#' dozen tokens -- which makes them a real line item in a prompt budget.
#'
#' @details
#' Bytes, code points and graphemes are exact and tidyEmoji can be
#' authoritative about them. The token count cannot be: it depends on the
#' tokeniser. Without `tokenizer`, `.emoji_token_estimate` is a deliberately
#' crude heuristic of roughly two UTF-8 bytes per token, which is in the right
#' range for byte-level BPE vocabularies but is an estimate and should never be
#' quoted as a bill. Pass your real tokeniser through `tokenizer` when the
#' number matters.
#'
#' `.emoji_graphemes` is the number of emoji occurrences, since the package's
#' detection is grapheme-aware: a skin-toned family emoji is one grapheme and
#' many code points, which is precisely the gap that makes emoji expensive.
#'
#' @inheritParams emoji_summary
#' @param tokenizer Optional function taking a character vector and returning
#'   either token counts (a numeric vector of the same length) or a list of
#'   token vectors. It is called on the row's emoji, concatenated. `NULL`
#'   (default) uses the byte heuristic.
#' @return `data`, as a tibble, with added columns `.emoji_n`, `.emoji_bytes`,
#'   `.emoji_codepoints`, `.emoji_graphemes` and `.emoji_token_estimate`.
#' @seealso [emoji_sanitize()] for acting on the answer; [emoji_ratio()] for
#'   the share of the text that is emoji.
#' @examples
#' family <- paste0("\U0001F468\u200d\U0001F469\u200d",
#'                   "\U0001F467\u200d\U0001F466")
#' df <- data.frame(text = c("hi \U0001f600", family, "plain"))
#' emoji_token_cost(df, text)
#' @export
emoji_token_cost <- function(data, text, tokenizer = NULL) {
  if (!is.null(tokenizer) && !is.function(tokenizer)) {
    stop("`tokenizer` must be a function or NULL.", call. = FALSE)
  }
  v <- .emoji_text_col(data, {{ text }})
  v[is.na(v)] <- ""
  lst <- emoji_glyph_list(v)
  joined <- vapply(lst, paste, character(1), collapse = "")
  n_bytes <- as.integer(nchar(joined, type = "bytes"))
  n_chars <- as.integer(nchar(joined, type = "chars"))

  if (is.null(tokenizer)) {
    est <- as.integer(ceiling(n_bytes / 2))
  } else {
    tk <- tokenizer(joined)
    if (is.list(tk)) tk <- lengths(tk)
    if (!is.numeric(tk) || length(tk) != length(joined)) {
      stop("`tokenizer` must return one token count, or one token vector, ",
           "per element of its input.", call. = FALSE)
    }
    est <- as.integer(tk)
    est[!nzchar(joined)] <- 0L
  }

  out <- .emoji_as_tibble(data)
  out$.emoji_n <- as.integer(lengths(lst))
  out$.emoji_bytes <- n_bytes
  out$.emoji_codepoints <- n_chars
  out$.emoji_graphemes <- as.integer(lengths(lst))
  out$.emoji_token_estimate <- est
  out
}
