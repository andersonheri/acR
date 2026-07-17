## Submission summary

This is a patch release of `acR` (0.3.0 -> 0.3.1). The package provides an
integrated pipeline for content analysis in R, combining qualitative coding
assisted by large language models (LLMs) with classical quantitative text
analysis. Special focus on Brazilian corpora and political-institutional
codebooks.

### Changes in 0.3.1

* `ac_plot_wordcloud_comparative()`: reproducible layout via a new `seed`
  argument; default `colors` now come from `ac_palette(2L)`; global RNG is
  saved and restored to avoid side effects on the user's session.
* `ac_plot_xray()`: fixed a divide-by-zero for documents with a single
  token (position defaults to 0.5); warning now identifies which specific
  terms have no occurrences.
* `ac_import()`: document order in the resulting corpus now matches input
  order even when mixing OCR and text parsers; duplicate `doc_id` values
  are disambiguated automatically with a warning; error calls migrated
  from `stop()` to `cli::cli_abort()` for consistency.
* Added test coverage for `ac_export()`, `ac_qual_irr()`, `theme_ac()`,
  `ac_palette()`, and `is_ac_corpus()`.

## Test environments

* Local: macOS 14.4 (Darwin arm64), R 4.3.x — 0 errors, 0 warnings, 1 note.
* R-hub v2 (GitHub Actions): linux, windows, macos, all on R-devel.
* win-builder (R-devel).

## R CMD check results

0 errors | 0 warnings | 1 note

* NOTE: unable to verify current time.
  Environmental (offline check host); not related to the package.

## Vignettes

Six vignettes ship with the tarball. All chunks that call external services
(LLM providers, network APIs) are guarded with `eval = FALSE`, so the
vignettes build offline and without API credentials on CRAN check hosts.

## Suggests

The package uses `ellmer` conditionally (only when the user calls a
qualitative-coding function). `ellmer` is therefore declared under
`Suggests`, guarded by `requireNamespace()` at every call site.

## Downstream dependencies

This is a new submission; there are no downstream dependencies to break.

## Reviewer notes

* `Additional_repositories` field has been removed (previous revisions
  pointed to a GitHub URL, which CRAN does not accept).
* `Language: en-US` declared. Documentation is bilingual (PT-BR user-facing
  content and EN-US package metadata); `inst/WORDLIST` seeds the Portuguese
  vocabulary so `spelling::spell_check_package()` runs clean.
* `tests/spelling.R` is non-blocking (`skip_on_cran = TRUE`).
