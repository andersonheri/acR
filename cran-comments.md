## Submission summary

Patch release of `acR` (0.3.3 → 0.3.4) fixing two crashes/bugs in the
qualitative pipeline found in production use, on top of the fixes and
addition already shipped in 0.3.3.

### Fixes in 0.3.4

* `ac_qual_code(confidence = "by_variable" | "both")` never computed
  or surfaced per-category confidence, despite being documented in
  `@return`. Two bugs in the same function: (1) `.ac_compute_confidence()`
  tested `confidence %in% c("total", "both")` in its first `if`, so
  `"both"` always took that branch and never reached the per-variable
  calculation; (2) even when computed (pure `"by_variable"` mode), the
  value stored was only the winning category's proportion, not a
  proportion per codebook category -- and `.ac_build_result_tibble()`
  never read that value to add columns to the output tibble. Fixed in
  both functions: `by_var` now has one entry per category in
  `cat_names` with the proportion of self-consistency rounds that
  picked it, computed whenever `confidence` includes `"by_variable"`,
  and the output tibble gains the corresponding
  `<category>_confidence` columns.

* `ac_qual_code()` no longer crashes with "Result must be length 1,
  not N" inside `.ac_compute_confidence()` (the self-consistency
  confidence calculation) when one of the `k_consistency` rounds
  returns `categoria` as a JSON array instead of a single string --
  even though the system prompt explicitly instructs otherwise. The
  sibling function `.ac_build_result_tibble()` already collapsed this
  case defensively (`paste(collapse = "|")`, added in 0.3.3 for the
  `multilabel = TRUE` bug), but the crash happened earlier, in the
  confidence calculation, which lacked the same guard. Same collapsing
  logic now applied in both places.

### Fixes in 0.3.3

* `live = "terminal"` in `ac_qual_code()` no longer aborts on the first
  document with "Cannot find progress bar". The `cli::cli_progress_bar()`
  was created inside a helper that returned immediately, so `cli` tore
  the bar down before the caller's loop could update it. Fixed by
  passing `.envir = parent.frame()` from the helper, tying the bar's
  lifecycle to the caller (typically `ac_qual_code()`).
* `temperature` argument of `ac_qual_code()` is now actually applied.
  Previously it was accepted as a formal parameter but never propagated
  to the `ellmer::Chat`, which meant the `k_consistency` rounds of
  self-consistency (Wang et al., 2023) all used the provider's default
  temperature and `confidence_score` was inflated. Fixed by injecting
  `ellmer::params(temperature = ...)` into the chat args when the user
  did not pass an explicit `params` via `...`.
* `multilabel = TRUE` no longer breaks with "Result must be length 1,
  not N" when the model returns a JSON array (`["a","b"]`) instead of a
  pipe-separated string. Two-part fix: (a) the system prompt now
  explicitly instructs multilabel responses to be a single string with
  categories separated by `"|"` and forbids JSON arrays; (b) the parser
  in `.ac_build_result_tibble()` always collapses with
  `paste(collapse = "|")`, absorbing arrays defensively.
* `ac_qual_report(path = <relative>)` no longer fails with "The
  directory 'X' does not exist" when `rmarkdown::render()` changes the
  working directory during the knit. Fixed by resolving the path to
  absolute before calling `render()` and creating the destination
  directory if it does not exist.

### New in 0.3.3

* Each codebook category now accepts an optional `label` field (human
  display name) alongside `definition`, `examples_pos`, etc. When
  present, `ac_qual_code()` returns an extra column `categoria_label`
  with the translated label; multilabel labels are joined with `" | "`
  (with spaces) while the slug column `categoria` keeps `"|"` (no
  spaces) as the stable key. Preserved by save/load YAML.
* `ac_qual_report_full()`: consolidated multi-variable report. Accepts
  a named list of `(coded, codebook, reliability)` triples and emits a
  single Markdown or HTML document with one section per variable and a
  summary table at the top. Removes the need for ad-hoc consolidators
  in projects that code several content variables.

## Test environments

* Local: Windows 11, R 4.6.x — reproduced and fixed the crash reported
  from production use.
* Local: macOS 14.4 (Darwin arm64), R 4.5.x — 0 errors, 0 warnings,
  2 NOTEs (see below), confirmed against 0.3.3's own submission.
* GitHub Actions matrix on the tip of `main`: Ubuntu R-devel / release
  / oldrel-1, macOS release, Windows release.

## R CMD check results

Locally with `--as-cran`:

```
0 errors | 0 warnings | 2 NOTEs
```

The NOTEs are:

1. **Unable to verify current time** — offline/VM check host clock
   skew, unrelated to the package.
2. **HTML version of manual** — validation warnings (`<link> inserting
   "type" attribute`, `<table> lacks "summary" attribute`, etc.) from
   an outdated local `tidy` bundled with macOS; a well-known false
   positive on macOS local checks that does not reproduce on CRAN's
   Linux build machines with a current `tidy`.

## Downstream dependencies

None known.

## Reviewer notes

* No changes to DESCRIPTION Fields, License, or reverse dependencies.
* All items from the 0.3.2 review (K. Lauseker, 2026-07-28) remain in
  effect: no `\dontrun{}` beyond truly external-service examples, no
  writes to `.GlobalEnv`, no `<<-`, no `set.seed()` inside functions
  (all seeds are user-controlled parameters scoped via `withr`).
