## Submission summary

Minor release of `acR` (0.4.0 → 0.6.0): twelve new quantitative
content-analysis functions, a documentation URL fix, and a repository
cleanup. All changes are additive (new exported functions, new
vignette section) — no existing exported function changes behavior
with its previous defaults.

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

Documentation: new "Novidades" section (§10–16) in
`vignette("quantitativo")`; cross-reference note in
`vignette("qualitativo-llm")`; README highlights section and function
finder table updated; `_pkgdown.yml` reference index updated.

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

* No code changes. Fixes the package `URL` field in `DESCRIPTION` (and
  the matching references in `_pkgdown.yml`, README, and this file):
  the currently-published 0.4.0 points to `https://ahenriquecp.com/acR/`,
  which is the maintainer's **personal** site, not the package's —
  pkgdown is actually deployed to `https://andersonheri.github.io/acR/`.
  Also removes a stale `docs/` directory that had been committed to
  `main` by mistake years ago (already covered by `.Rbuildignore`; now
  also added to `.gitignore` so it cannot reappear from a local
  `pkgdown::build_site()` run).

## Test environments

* GitHub Actions matrix on the tip of `main` (after merging the branch
  with the 0.5.0 functions): Ubuntu R-devel / release / oldrel-1,
  macOS release, Windows release — all green.
* R CMD check run locally (Ubuntu 24.04, R 4.3.3) with every `Imports`
  installed and most `Suggests` installed from apt/conda-forge mirrors
  (network access to CRAN itself was unavailable in that sandboxed
  environment, so `irr`, `stopwords` were installed from alternative
  mirrors and a handful of `Suggests` — `ellmer`, `ggwordcloud`,
  `ipeaplot`, `quanteda`, `readtext`, `senatebR`, `tesseract`,
  `topicmodels` — could not be installed there; the GitHub Actions run
  above has the full matrix with all `Suggests` available and is
  green).

## R CMD check results

0 errors | 0 warnings | 0–2 NOTEs depending on which `Suggests` are
installed:

1. **Packages suggested but not available for checking** — only
   appears when one of the `Suggests` above is missing locally (as in
   the sandboxed run noted above); not reproducible on an environment
   with all `Suggests` installed, and not expected on CRAN's own
   check machines.
2. **Unknown packages 'quanteda.textstats', 'topicmodels' in Rd xrefs**
   — pre-existing (not introduced by this release): `ac_keyness.Rd`
   and `ac_lda.Rd` link to `quanteda.textstats::textstat_keyness()`
   and `topicmodels::LDA()`, both in `Suggests`; this NOTE only
   appears when `quanteda.textstats` specifically is not installed
   (it is not an `acR` dependency, only `quanteda` is) — not expected
   on CRAN's own check machines, which install all `Suggests`.

## Pre-submission checklist for this release

1. ~~`devtools::document()`~~ — done; `man/*.Rd` and `NAMESPACE` are in
   sync with the roxygen comments in `R/*.R`.
2. ~~`devtools::test()`~~ — done; 926 passed / 0 failed in the
   sandboxed run (4 unrelated failures from `ellmer` not being
   installable there are not present on the GitHub Actions matrix,
   which is green).
3. ~~`devtools::check()`~~ — done; see above.
4. ~~Confirm the `URL` field resolves~~ — `https://andersonheri.github.io/acR/`
   is live (pkgdown "release" build rebuilt from the clean 0.6.0
   version tag).
5. `devtools::submit_cran()`, and click the confirmation email — both
   steps require your local machine/inbox.

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
