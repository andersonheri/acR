## Submission summary

Minor release of `acR` (0.4.0 → 0.6.0): twelve new quantitative
content-analysis functions, one behavior fix, a documentation
overhaul, and a repository cleanup. All changes to exported functions
are additive or strictly corrective — no existing exported function
changes its documented, intended behavior.

### New in 0.5.0

Twelve new functions covering corpus diagnostics, context/association,
time series, scaling, and custom dictionaries — all documented with
non-parliamentary examples (product reviews, customer service, news)
and grounded in the relevant methodological literature via `@references`:

* `ac_readability()` / `ac_plot_readability()` — readability index
  (Flesch adapted to Portuguese; Martins et al., 1996).
* `ac_lexical_diversity()` / `ac_plot_lexical_diversity()` — lexical
  diversity (TTR, Herdan's C, MTLD; Herdan, 1960; McCarthy & Jarvis,
  2010).
* `ac_plot_zipf()` — rank-frequency log-log plot (Zipf, 1949).
* `ac_kwic()` — keyword-in-context concordance (Sinclair, 1991).
* `ac_collocations()` — statistically associated n-grams via PMI
  (Church & Hanks, 1990), log-likelihood (Dunning, 1993), or chi-square.
* `ac_temporal()` / `ac_plot_temporal()` — diachronic aggregation of
  any metric by day/week/month/year (Welbers, Van Atteveldt & Benoit,
  2017).
* `ac_wordscores()` / `ac_plot_wordscores()` — Wordscores ideological
  scaling (Laver, Benoit & Garry, 2003), with `"lbg"`/`"mv"`
  rescaling (Martin & Vanberg, 2007).
* `ac_ca()` / `ac_plot_ca()` — correspondence analysis biplot computed
  natively via `base::svd()` (Greenacre, 2007); no new hard dependency.
* `ac_dictionary()` / `ac_build_dictionary()` — generic multi-category
  dictionary scoring (Stone et al., 1966; Grimmer & Stewart, 2013).
* `ac_dictionary_save()` / `ac_dictionary_load()` / `ac_dictionary_import()`
  — build/import a custom dictionary from YAML/CSV.
* `ac_emotion()` — emotion-lexicon scoring from a user-supplied lexicon
  (inspired by the NRC Emotion Lexicon; Mohammad & Turney, 2013); the
  package does not bundle any emotion lexicon for licensing reasons.
* `ac_dictionary_validate()` — validates dictionary-based classification
  against human-coded ground truth, the dictionary-method counterpart
  of `ac_qual_reliability()`.

### Fixed in 0.5.0 (found by `devtools::check()` before this submission)

* `ac_temporal()`: `match.arg(stat)` ran after a check that already
  used the unmatched `stat` vector, raising a coercion error instead
  of the intended `cli_abort()`.
* `ac_wordscores()`: output row order depended on `ac_count()`'s
  frequency sort instead of the original document order.
* `ac_dictionary_validate.Rd` / `ac_wordscores.Rd`: two `[...]`
  Markdown links that `roxygen2` could not resolve
  (`checking Rd cross-references ... WARNING`), fixed by linking only
  `ac_qual_reliability()` and wrapping the `[min, max]` interval
  notation in backticks instead of brackets.
* `R/globals.R`: declared the NSE column names used by the new
  `ac_plot_*`/`ac_collocations()`/`ac_lexical_diversity()` functions
  (`checking R code for possible problems ... NOTE`).

### New in 0.6.0

**Behavior fix**

* `ac_qual_codebook_translate()` required the `ellmer` package to be
  installed even when the codebook was already in the target
  language (a case where no LLM call happens at all). The
  already-in-target-language short-circuit now runs before the
  dependency check.

**Documentation overhaul**

* Full spelling pass (missing diacritics) across the README, all ten
  vignettes, and every `roxygen2` comment in `R/*.R`.
* The "which metric answers which question" lookup table in
  `vignette("quantitativo")` was expanded to cover all twelve new
  0.5.0 functions, organized into five methodological families (it
  previously covered only the six pre-0.5.0 functions).
* Added "How to interpret" callouts after essentially every plot and
  result table across all ten vignettes, explaining axis meaning,
  common thresholds, and interpretation pitfalls.
* Added alternative visualizations (as extra `ggplot2` usage examples
  inside the vignettes, not new exported functions) for several
  0.5.0 techniques in `vignette("quantitativo")` and
  `vignette("lda")`.
* Added a "Suggested sequence for reporting results" section (table +
  rationale) to `vignette("quantitativo")` and
  `vignette("qualitativo-llm")`, guiding readers through which
  analyses to run and report, and why, for a publication-ready
  write-up.
* Reduced em-dash usage to zero occurrences across the entire package
  (README, vignettes, `roxygen2` comments), replaced by colons or
  sentence restructuring, per standard Portuguese punctuation
  conventions.
* `man/*.Rd` regenerated via `devtools::document()` to resync with the
  corrected `roxygen2` comments.

**Vignette/test robustness**

* `vignette("cluster")` and `vignette("lda")`: chunks depending on the
  `topicmodels` Suggests package are now guarded with
  `eval = requireNamespace("topicmodels", quietly = TRUE)`, so vignette
  rebuilding no longer errors out on a system without that package
  (it previously did, which would have been fragile for anyone
  reproducing the vignettes locally without every Suggests installed).
* Three tests exercising `ellmer`-dependent code paths gained
  `skip_if_not_installed("ellmer")`, matching the pattern already used
  by the rest of that test file.

**Infrastructure maintenance**

* Fixed references to the maintainer's **personal** domain
  (`ahenriquecp.com`), which had been mistakenly pointed to as the
  package's site in `_pkgdown.yml`, README, `DESCRIPTION`, and this
  file; all now point to the real pkgdown URL
  (`https://andersonheri.github.io/acR/`).
* Removed a stale `docs/` directory that had been committed to `main`
  by mistake years ago (already covered by `.Rbuildignore`; now also
  added to `.gitignore` so it cannot reappear from a local
  `pkgdown::build_site()` run).

## Test environments

* GitHub Actions matrix on the tip of `main`: Ubuntu R-devel /
  release / oldrel-1, macOS release, Windows release — all green
  (`R-CMD-check.yaml`), plus `test-coverage.yaml` green.
* `R CMD check` run locally (Ubuntu 24.04, R 4.3.3) with every
  `Imports` installed; network access to CRAN itself was unavailable
  in that sandboxed environment, so a handful of `Suggests`
  (`ellmer`, `ggwordcloud`, `ipeaplot`, `quanteda`, `readtext`,
  `senatebR`, `tesseract`, `topicmodels`) could not be installed
  there. The GitHub Actions run above has the full matrix with all
  `Suggests` available and is green.

## R CMD check results

0 errors | 0 warnings | 0–2 NOTEs depending on which `Suggests` are
installed:

1. **Packages suggested but not available for checking** — only
   appears when one of the `Suggests` above is missing locally (as in
   the sandboxed run noted above, which also has no network access to
   CRAN); not reproducible on an environment with all `Suggests`
   installed, and not expected on CRAN's own check machines.
2. **Unknown packages 'quanteda.textstats', 'topicmodels' in Rd xrefs**
   — pre-existing (not introduced by this release): `ac_keyness.Rd`
   and `ac_lda.Rd` link to `quanteda.textstats::textstat_keyness()`
   and `topicmodels::LDA()`, both in `Suggests`; this NOTE only
   appears when `quanteda.textstats` specifically is not installed
   (it is not an `acR` dependency, only `quanteda` is) — not expected
   on CRAN's own check machines, which install all `Suggests`.

`devtools::test()` locally: 927 passed / 0 failed / 58 skipped (all
skips are `Suggests` not installed in the sandboxed environment —
`ellmer`, `ggwordcloud`, `quanteda`, `readtext`, `senatebR`,
`topicmodels` — or require network access; none of these are
reproducible on CRAN's check machines or the green GitHub Actions
matrix).

## Pre-submission checklist for this release

1. ~~`devtools::document()`~~ — done; `man/*.Rd` and `NAMESPACE` are in
   sync with the roxygen comments in `R/*.R`.
2. ~~`devtools::test()`~~ — done; see above.
3. ~~`devtools::check()`~~ — done; see above.
4. ~~Confirm the `URL` field resolves~~ — `https://andersonheri.github.io/acR/`
   is live.
5. ~~Full documentation/spelling/didactic review~~ — done; see
   "Documentation overhaul" above.
6. `devtools::submit_cran()`, and click the confirmation email — both
   steps require the maintainer's local machine/inbox.

## Downstream dependencies

None known.

## Reviewer notes

* No changes to `License` or reverse dependencies.
* `Imports`/`Suggests` lists are unchanged by the new functions — all
  twelve use only already-declared dependencies (`dplyr`, `tidyr`,
  `ggplot2`, `cli`, `tibble`, `yaml`, base `stats`/`utils`); the
  correspondence-analysis function (`ac_ca()`) is computed with
  `base::svd()`, with no new hard dependency on an external CA
  package.
* All items from the 0.3.2 review (K. Lauseker, 2026-07-28) remain in
  effect: no `\dontrun{}` beyond truly external-service examples, no
  writes to `.GlobalEnv`, no `<<-`, no `set.seed()` inside functions
  (all seeds are user-controlled parameters scoped via `withr`).
