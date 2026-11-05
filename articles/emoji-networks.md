# Emoji networks: edges worth drawing

Which emoji are used together is a network question, and
[`emoji_pairs()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_pairs.md)
returns exactly the edge list a network package wants. The trap is that
the edge list it returns by default is mostly noise, and a layout draws
noise as confidently as it draws structure. This article builds an emoji
network that is worth drawing: weighted by an association measure,
thresholded on frequency, and checked against what the emoji-network
literature says such networks look like.

``` r

library(tidyEmoji)
library(dplyr)

posts <- read.csv(system.file("extdata", "ata_tweets.csv",
                              package = "tidyEmoji"),
                  stringsAsFactors = FALSE, encoding = "UTF-8")
```

## Counts first, and why they are not enough

One row per pair of distinct emoji that appear in the same post, with
the number of posts in which they do:

``` r

edges <- posts %>% emoji_pairs(full_text)
edges
#> # A tibble: 213 × 3
#>    item1 item2     n
#>    <chr> <chr> <int>
#>  1 😂    😭       10
#>  2 😂    😩        4
#>  3 😂    🙄        3
#>  4 😭    🙄        3
#>  5 💕    🥰        2
#>  6 💞    🥺        2
#>  7 💯    🤷🏽‍♂️        2
#>  8 😂    🤔        2
#>  9 😂    🤣        2
#> 10 😂    🤷🏼‍♀️        2
#> # ℹ 203 more rows

edges %>% count(n, name = "pairs")
#> # A tibble: 5 × 2
#>       n pairs
#>   <int> <int>
#> 1     1   200
#> 2     2     9
#> 3     3     2
#> 4     4     1
#> 5    10     1
```

200 of the 213 edges (93.9%) are a single post. A graph drawn from all
of them is one post’s worth of evidence per line, and the few heavy
edges belong to the emoji that are common everywhere, which pair with
everything because they are common, not because they are related.

## Weight by association, then threshold on frequency

Two changes fix this, and they do different jobs.

- **An association measure** scores each pair against what its two
  emoji’s own frequencies predict, so a common emoji no longer wins
  every edge. `measure = "dice"` is `2 * n / (n1 + n2)`, with `n1` and
  `n2` the posts holding each emoji: 1 for a pair never seen apart, near
  0 for a pair that is mostly apart. `"ppmi"` and `"log_odds"` are the
  alternatives; see
  [`?emoji_pairs`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_pairs.md).
- **A frequency threshold** removes the edges seen too rarely to mean
  anything. An association measure cannot do this on its own: a pair
  seen in one post, whose two emoji appear nowhere else, scores the
  maximum Dice of 1.

``` r

weighted <- posts %>%
  emoji_pairs(full_text, measure = "dice") %>%
  filter(n >= 2)

weighted
#> # A tibble: 13 × 4
#>    item1 item2     n   dice
#>    <chr> <chr> <int>  <dbl>
#>  1 💞    🥺        2 0.222 
#>  2 💕    🥰        2 0.182 
#>  3 💯    🤷🏽‍♂️        2 0.182 
#>  4 😂    😭       10 0.121 
#>  5 😭    🙄        3 0.0659
#>  6 😂    😩        4 0.064 
#>  7 😂    🙄        3 0.0526
#>  8 😭    🥰        2 0.0460
#>  9 😭    🥴        2 0.0440
#> 10 😂    🤷🏼‍♀️        2 0.0417
#> 11 😂    🤔        2 0.0396
#> 12 😂    🥰        2 0.0364
#> 13 😂    🤣        2 0.0339
```

That is the honest network for this corpus: 13 edges. Two thousand posts
holding 900 emoji are too few for a network of more than a handful of
emoji, and it is better to know that than to draw the 213-edge version.
A corpus of hundreds of thousands of posts, or one pooled by user or by
conversation with `doc_id`, gives a graph with real structure.

## Into a network package

The edge list feeds `igraph` (or `tidygraph`) directly, with the
association measure as the edge weight:

``` r

g <- igraph::graph_from_data_frame(
  weighted[, c("item1", "item2", "dice", "n")], directed = FALSE)

igraph::vcount(g)
#> [1] 14
igraph::ecount(g)
#> [1] 13
igraph::components(g)$no
#> [1] 3
```

Community detection then groups emoji that are used together more than
chance; Louvain with the Dice weight is a reasonable default:

``` r

set.seed(2026)   # Louvain breaks ties at random; fix them for a stable answer
communities <- igraph::cluster_louvain(g, weights = igraph::E(g)$dice)
split(igraph::V(g)$name, igraph::membership(communities))
#> $`1`
#> [1] "💞" "🥺"
#> 
#> $`2`
#> [1] "💕" "🥰"
#> 
#> $`3`
#> [1] "💯"    "🤷🏽‍♂️"
#> 
#> $`4`
#> [1] "😂"    "😭"    "🙄"    "😩"    "🥴"    "🤷🏼‍♀️" "🤔"    "🤣"
```

Drawing it is a job for a graph-plotting package. With `ggraph`
installed, and `ragg` as the graphics device so the glyphs render in
colour:

``` r

library(ggraph)
ggraph(g, layout = "fr") +
  geom_edge_link(aes(width = dice), alpha = 0.4) +
  geom_node_text(aes(label = name), size = 6) +
  scale_edge_width(range = c(0.3, 2)) +
  theme_void()
```

## Sanity checks for a bigger corpus

Studies of emoji co-occurrence networks on large Twitter samples (Fede
et al., 2018; Alsaif et al., 2021) report two properties, and both make
good checks that a network is measuring structure rather than sampling
noise:

- the **degree distribution is heavy-tailed**: a few emoji connect to
  very many, most connect to a few;
- most emoji fall into **a handful of communities**.

Both are one line once the graph exists. On a network of a dozen nodes
they say little; on a real one, a degree table with no tail or a
community count close to the node count is a sign that the threshold was
set too low:

``` r

table(igraph::degree(g))
#> 
#>  1  2  3  4  7 
#> 10  1  1  1  1
length(communities)
#> [1] 4
```

## Directed sequences

`emoji_pairs(directed = TRUE)` orders each pair by first appearance in
the post, so the edge from one emoji to another counts the posts where
the first came first. The same measures apply to that ordered event, and
[`emoji_ngrams()`](https://pursuitofdatascience.github.io/tidyEmoji/reference/emoji_ngrams.md)
gives the strictly consecutive version for Markov-style models of emoji
sequences.

## References

Alsaif H, Roesch P, Othman S (2021). Analyzing Co-occurrence Networks of
Emojis on Twitter. In *Intelligent Computing*, Springer.
<https://doi.org/10.1007/978-3-030-80126-7_7>

Fede H, Herrera I, Mahdi Seyednezhad SM, Menezes R (2018). Representing
Emoji Usage Using Directed Networks: A Twitter Case Study. In *Complex
Networks & Their Applications VI*.
<https://doi.org/10.1007/978-3-319-72150-7_67>
