## Submission summary

Update of `acR` from 0.4.0 (published on CRAN on 2026-10-14) to 0.6.0.

### Why an update so soon after 0.4.0

We are aware that this follows 0.4.0 by only a few days, and we would not
submit this quickly for new features alone. After 0.4.0 was published, a
line-by-line methodological audit found bugs in functions **already on
CRAN** that silently return wrong numbers. Users of 0.4.0 can get incorrect
results today, so we would rather not wait 1-2 months to ship the fixes:

* `ac_cooccurrence()`: in window mode every co-occurrence was counted
  twice, doubling `cooc` and adding exactly 1 bit to the PMI; in document
  mode, Dice and PMI mixed document counts with token counts.
* `ac_tokenize(drop_punct = TRUE)`: punctuation attached to a word was not
  removed (`"excellent,"` and `"excellent"` became different types),
  affecting every frequency-based function downstream.
* `ac_sentiment()`: 28 terms that appear more than once in the OpLexicon
  (one entry per part of speech) were counted twice; `by` did not
  aggregate by group as documented.
* `ac_qual_irr()`: the confidence interval for kappa used the standard
  error under the null hypothesis, giving limits outside [-1, 1]; it is now
  a percentile bootstrap. `weight = "linear"` was documented but errored.
* `ac_cluster_documents()`: Ward's method received `1 - cosine`, which is
  not a Euclidean distance; it now uses the chord distance.
* `ac_lda_tune()`: perplexity was computed on the training documents
  (always favouring the largest k) and `method = "Gibbs"` errored; it is
  now held-out perplexity by cross-validation.
* `ac_top_terms()`, `ac_plot_keyness()`, `ac_plot_tf_idf()`: ranking did
  not sum terms across documents and kept all ties, so a requested "top 15"
  could return the whole vocabulary.
* `ac_plot_xray()` missed terms followed by punctuation;
  `ac_plot_lda_topics()` showed internal labels (`"term___Topic 1"`) on
  the axis.
* `ac_qual_reliability()` / `ac_qual_irr()`: Krippendorff's alpha and macro
  F1 were labelled with the Landis & Koch (1977) bands, which were proposed
  for kappa; each metric now uses its own reference.

Each fix has a regression test, and `NEWS.md` lists all of them.

### Intentional behaviour changes (documented in NEWS.md)

These are corrections, not new behaviour for its own sake, but they do
change results or defaults of exported functions:

* `ac_qual_sample()`: default `strategy` changed from `"uncertainty"` to
  `"random"`. A sample used to estimate reliability must be representative
  (Krippendorff, 2018, ch. 12); `"uncertainty"` remains available for
  error diagnosis.
* `ac_sentiment(by = )` now returns one row per group, as documented.
* `ac_lda_tune()` returns the extra columns `perplexity_sd` and
  `perplexity_train`, and gains a `folds` argument (default 5).
* `ac_qual_irr()` gains a `bootstrap` argument (default 1000).
* The `interpretation` column of the reliability functions uses
  metric-specific wording.

### New in this release (not on CRAN before)

Twelve quantitative functions, all grounded in the methodological
literature via `@references`: `ac_readability()`,
`ac_lexical_diversity()`, `ac_plot_zipf()`, `ac_kwic()`,
`ac_collocations()`, `ac_temporal()`, `ac_wordscores()` (with the
Laver, Benoit & Garry, 2003, and Martin & Vanberg, 2008, rescalings),
`ac_ca()`, `ac_dictionary()` and helpers, `ac_emotion()` and
`ac_dictionary_validate()`. No new hard dependencies: correspondence
analysis is computed with `base::svd()`.

### Internet resources

`ac_sentiment()` downloads the OpLexicon (a public sentiment lexicon for
Portuguese) from GitHub on first use and caches it in
`tools::R_user_dir("acR", "data")`; it never writes to the user's home
directory otherwise. If the download fails it stops with an informative
message. To make sure no check depends on the network:

* the examples of `ac_sentiment()` and `ac_plot_sentiment()` use
  `@examplesIf interactive()`;
* the three vignettes that use it (`sentimento`, `introducao-acR`,
  `quickstart`) first try to load the lexicon inside `tryCatch()` and,
  if it is not available, skip only the chunks that need it and show a
  short notice instead of failing;
* all tests mock the lexicon and never touch the network.

All other examples that need the internet (Câmara/Senado APIs, OpenAlex,
LLM providers) were already in `\dontrun{}`, since they also require API
access or credentials.

## Test environments

* GitHub Actions on the tip of `main` (commit 463a7a2), building
  vignettes: ubuntu-latest (R-devel, release, oldrel-1), macOS-latest
  (release), windows-latest (release). All green, as are
  `test-coverage.yaml` and `pkgdown.yaml`.
* Local Windows 11, R 4.6.1, with all `Suggests` installed except
  `covr`, `ggraph`, `igraph`, `ipeaplot`, `senatebR`, `spelling` and
  `wordcloud`: `R CMD check --no-manual --ignore-vignettes` (pandoc is not
  installed locally; the vignettes were run with `knitr::knit()` and are
  built by the GitHub Actions matrix above). The three vignettes that use
  the lexicon were also run twice with an empty `R_USER_DATA_DIR`: once
  with the network blocked (they build and show the notice) and once with
  the network available (the lexicon is downloaded and every chunk runs).

## R CMD check results

0 errors | 0 warnings | 0 notes

## Downstream dependencies

None.

## Reviewer notes

* No change to `License`; `Imports` and `Suggests` are unchanged.
* All items from the 0.3.2 review (K. Lauseker, 2026-07-28) remain in
  effect: no `\dontrun{}` beyond examples that need external services or
  credentials, no writes to `.GlobalEnv`, no `<<-`, no `set.seed()` inside
  functions (seeds are user-controlled arguments scoped with `withr`).
