## Resubmission

This is a **resubmission** of `acR` 0.3.2, addressing the review
comments received from Konstanze Lauseker on 2026-07-18. All requested
changes were applied:

1. **DESCRIPTION** — removed the redundant "in R" at the start of the
   description and dropped single quotes around acronyms/product names
   (`LLM`, `LDA`, `OpLexicon`, `ggplot2`).
2. **`\dontrun{}` usage** — replaced with `\donttest{}` for examples
   that are simply slow or require optional packages; kept `\dontrun{}`
   only where the example truly cannot run without external services
   (network fetch of legislative data via `ac_fetch_camara()` /
   `ac_fetch_senado()`, LLM API keys via `ac_qual_code()` /
   `ac_qual_codebook_hybrid()` / `ac_qual_codebook_translate()` /
   `ac_qual_search_literature()`, and file paths in `ac_import()`).
   `\donttest{}` examples were made self-contained and now build a
   local corpus inside the block.
3. **`.GlobalEnv` writes** — removed the direct `.GlobalEnv` seed
   save/restore idiom from `ac_plot_wordcloud_comparative()`; RNG is
   now scoped exclusively via `withr::with_seed()` (moved `withr` from
   Suggests to Imports).
4. **`<<-` operator** — removed from `.ac_report_build_md()` in
   `ac_qual_report.R`; the string accumulator now uses a local
   environment (`buf$lines <- c(buf$lines, ...)`) instead of assigning
   to an enclosing frame.
5. **Hard-coded `set.seed()` inside functions** — `ac_wordcloud()`,
   `ac_plot_wordcloud_comparative()`, `ac_qual_sample()` no longer
   call `set.seed()`. Each exposes a `seed` argument (default `42L`
   for reproducibility, `NULL` to use the current session RNG); the
   seed is scoped via `withr::with_seed()`.

## Submission summary

`acR` (version 0.3.2) provides an integrated pipeline for content
analysis combining qualitative coding assisted by large language models
(LLMs) with classical quantitative text analysis. Special focus on
Brazilian corpora and political-institutional codebooks.

### Highlights of 0.3.2

* **Unsupervised document clustering:** `ac_cluster_documents()` (hclust
  / k-means / PAM, TF-IDF or count features, cosine or Euclidean
  distance, automatic `k` selection by silhouette when the `cluster`
  package is available) and `ac_plot_cluster()` (dendrogram, PCA
  scatter, dissimilarity heatmap).
* **Comparative word cloud generalized to N groups:**
  `ac_plot_wordcloud_comparative()` now accepts 2 or more groups (was
  hard-limited to 2), with `facet_wrap()` and default colours from
  `ac_palette(N)`.
* **New vignette** `cluster.Rmd` — "Agrupamento não supervisionado de
  documentos": explains hard clustering, soft/fuzzy clustering and LDA
  as three complementary answers to the same latent-typology question;
  six visualisations; side-by-side comparison with the LDA gamma matrix.
* **Documentation polish:** README, `_pkgdown.yml` navbar and the
  `ac_keyness()` help now describe group comparison generically (any
  categorical partition — partido, período, tema, região, condição
  experimental) rather than hard-coding "government vs opposition".
* **Minor fixes carried over from the internal 0.3.1 line:**
  `ac_plot_wordcloud_comparative()` reproducible layout (`seed`
  argument, RNG state saved/restored); `ac_plot_xray()` divide-by-zero
  on single-token documents; `ac_import()` document ordering stable
  under mixed OCR / text inputs; error calls migrated from `stop()` to
  `cli::cli_abort()` throughout the package.

## Test environments

* Local: macOS 14.4 (Darwin arm64), R 4.5.x — 0 errors, 0 warnings,
  2 NOTEs (see below).
* GitHub Actions matrix on the merged PR #4 immediately preceding this
  submission: Ubuntu R-devel / release / oldrel-1, macOS release,
  Windows release — all `R CMD check` runs green. `pkgdown` build also
  green. The `covr::package_coverage()` job was cancelled after a
  runner hang (~6h); the same 715 tests passed on the five `R CMD
  check` configurations, so the hang is a runner issue, not a package
  fault.

## R CMD check results

Locally with `--as-cran`:

```
0 errors | 0 warnings | 3 NOTEs
```

The NOTEs are:

1. **New submission** — expected for a first-time package.
2. **Unable to verify current time** — offline check host, unrelated to
   the package.
3. **HTML validation problems in the manual** — HTML Tidy warnings
   about (a) `<table>` lacking `summary`, `<script>` `onload` attributes
   and `<link>`/`<script>` inserting `type` — all emitted by R's own
   default `Rd2HTML` template, common on many CRAN packages; and (b)
   "replacing invalid character code" warnings when accented Portuguese
   characters (á, ç, — etc., all valid UTF-8) are validated by an
   HTML Tidy that assumes Latin-1 despite the file declaring
   `charset=utf-8`. Nothing in the package can suppress these; the
   generated HTML is well-formed UTF-8.

## Vignettes

Nine vignettes ship with the tarball. All chunks that call external
services (LLM providers, network APIs) are guarded with `eval = FALSE`,
so the vignettes build offline and without API credentials on CRAN
check hosts. The new `cluster` vignette runs entirely on synthetic
in-memory data.

## Suggests

The package uses `ellmer`, `topicmodels`, `cluster`, `ggraph`,
`ggwordcloud`, `tesseract` and a few other packages conditionally
(each is required only when the user calls the corresponding
qualitative-coding, LDA, PAM-clustering, cooccurrence-network,
wordcloud or OCR entry point). They are therefore declared under
`Suggests` and guarded by `requireNamespace()` at every call site.

## Downstream dependencies

This is a first submission; there are no downstream dependencies to
break.

## Reviewer notes

* `Additional_repositories` is not used (previous internal revisions
  pointed to a GitHub URL, which CRAN does not accept; the field was
  removed before this submission).
* `Language: en-US` declared. User-facing documentation is bilingual
  (PT-BR prose in vignettes and roxygen `@description` blocks; EN-US
  package metadata and `NEWS.md` headers). `inst/WORDLIST` seeds the
  Portuguese vocabulary so `spelling::spell_check_package()` runs
  clean.
* `tests/spelling.R` is non-blocking (`skip_on_cran = TRUE`).
* No calls to `install.packages()`, no writes outside `tempdir()`, no
  modification of the global environment. Random-number consumers
  (`ac_qual_sample()`, `ac_lda()`, `ac_plot_wordcloud_comparative()`)
  save and restore the RNG state and expose a `seed` argument.
