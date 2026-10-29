## Submission summary

Update of `acR` from 0.6.0 (published on CRAN on 2026-10-16) to 0.6.1.

### Why an update so soon after 0.6.0

We know this follows 0.6.0 by only about two weeks and would not submit this
quickly for new features. This is a bug-fix release: all five fixes were found
while using the CRAN version of the package to run a course on text analysis
(15 hours, 160 participants, with real data), and each one makes an exported
function fail or return a wrong number:

* `ac_import()`: spreadsheets (`.xlsx`, `.xls`) and CSV files with more than
  one row failed with "Nenhum documento foi importado com sucesso", because
  the one-record-per-row output of `readtext` was matched by file name. Each
  row now becomes a document.
* `ac_qual_code()`: rate-limit errors (HTTP 429, "tokens per minute") were
  classified as `"estouro_contexto"` (context overflow) because the message
  mentions "tokens", and were never retried. They now have their own status
  (`"limite_taxa"`) and are retried, honouring the provider's "try again in"
  hint (up to 90 s).
* `ac_qual_code(model = <function>)`: the documented chat-factory form of
  `model` failed immediately with "cannot coerce type 'closure' to vector of
  type 'character'".
* `ac_cooccurrence(unit = "window")`: Dice could exceed 1 (observed: 1.88)
  because pair counts were divided by token counts. It is now bounded in
  [0, 1]. PMI is unchanged.
* `ac_export(format = "latex")`: the file contained two nested
  `\begin{table}` environments (it did not compile) and the label came out as
  `tab:tab:name`.

Each fix has a regression test, and `NEWS.md` lists them. No new
dependencies, no change of defaults, no new exported functions.

## Test environments

* Local macOS Sonoma 14.4.1 (aarch64), R 4.3.2: `R CMD check --as-cran`,
  with vignettes built (pandoc available), examples (including
  `--run-donttest`) and the full test suite (585 test blocks, 0 failures).

## R CMD check results

0 errors | 0 warnings | 2 notes

* `installed size is 5.8Mb` (sub-directory `doc` 4.7Mb): the vignettes. No
  change in size policy since 0.6.0.
* `unable to verify current time`: a limitation of the sandbox where the
  check was run (no access to a time server); it does not occur on CRAN.
