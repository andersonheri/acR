## Submission summary

This is the initial CRAN submission of `acR` (version 0.3.0). The package
provides an integrated pipeline for content analysis in R, combining
qualitative coding assisted by large language models (LLMs) with classical
quantitative text analysis. Special focus on Brazilian corpora and
political-institutional codebooks.

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
