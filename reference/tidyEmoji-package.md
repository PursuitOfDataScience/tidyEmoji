# tidyEmoji: Discover, Count, Categorise, Score and Translate Emoji in Text

A tidy toolkit for working with the emoji in any text column, such as
social-media posts, product reviews, chat logs or survey responses.
Unicode is awkward to handle and not every code point is an emoji, which
makes emoji statistics fiddly to obtain. 'tidyEmoji' extracts, counts,
categorises, sentiment-scores and emotion-scores emoji, converts them to
and from text (for accessibility and NLP preprocessing), and searches
the emoji catalogue, with grapheme-aware detection (so skin-tone and
multi-person sequences stay intact), returning tidy data frames that
slot straight into a 'tidyverse' workflow. The bundled emoji sentiment
lexicon is from the Emoji Sentiment Ranking of Kralj Novak et al. (2015)
[doi:10.1371/journal.pone.0144296](https://doi.org/10.1371/journal.pone.0144296)
, released under CC BY-SA 4.0; the emotion lexicon is from EmoTag1200 of
Shoeb & de Melo (2020) <https://aclanthology.org/2020.emnlp-main.720/>,
released under the MIT licence.

## See also

Useful links:

- <https://pursuitofdatascience.github.io/tidyEmoji/>

- Report bugs at
  <https://github.com/PursuitOfDataScience/tidyEmoji/issues>

## Author

**Maintainer**: Youzhi Yu <yuyouzhi666@icloud.com>
