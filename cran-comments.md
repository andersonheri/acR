## Submission summary

Minor release of `acR` (0.3.4 → 0.4.0): a critical silent-fallback bug
fix plus several new parameters/functions in the qualitative pipeline
(`ac_qual_code()`, `ac_qual_reliability()`, `ac_qual_sample()`),
derived from production use classifying 872 normative acts with
`ellmer` against local LM Studio servers. All changes are additive
(new optional parameters with backward-compatible defaults, new
columns in the output tibble, new exported functions) — no existing
call to any exported function changes behavior with its previous
defaults, except the one documented bug fix below.

### Fixes in 0.4.0

* `ac_qual_code(model/chat = <Chat do ellmer>)`: `temperature` era
  descartado em silêncio sempre que a reconstrução do chat via helper
  interno falhava — o que passou a acontecer sistematicamente no
  `ellmer >= 0.5.0` por uma mudança no formato de `class()` do
  provider. Corrigido mutando o objeto `Model` diretamente
  (`set_model()`/`get_model_object()`), com aviso explícito
  (`cli::cli_warn()`) se a mutação falhar — nunca mais em silêncio.
* `ac_qual_code()` multilabel: a confiança por variável
  (`confidence = "by_variable"/"both"`) subestimava categorias
  presentes junto com outras na mesma rodada (comparava a string
  inteira em vez de testar presença). Corrigido com `%in%` após
  separar por `"|"`.

### New in 0.4.0

* `max_retries`, coluna `status` e `n_tentativas`: novas tentativas
  automáticas com espera exponencial; aborta a execução se mais da
  metade dos últimos documentos falhar.
* `checkpoint_dir`: grava cada documento atomicamente, permite
  retomar uma rodada interrompida sem reclassificar.
* Colunas `tokens_entrada`/`tokens_saida`/`segundos`/
  `tokens_por_segundo` e o atributo `run_info` (versões, modelo,
  parâmetros efetivos, hash do codebook).
* `main_temperature`/`reasoning_extras` expostos (antes fixos no
  código); `live = "progress"` (barra enxuta) e `echo = "none"` por
  padrão em chats internos.
* `ac_qual_reliability(by_variable = TRUE, exclude_status = ...)`:
  métricas binárias por categoria do codebook (essencial em
  multilabel), com `NA` em denominadores indefinidos.
* `ac_qual_sample(strategy = "proportional", strata = ..., ...)`:
  amostragem estratificada com alocação proporcional (método do
  maior resto) e coluna `peso_amostral`.
* `ac_chat_local()`: provedor de primeira classe para servidores LLM
  locais compatíveis com OpenAI (LM Studio, llama.cpp, vLLM).
* `ac_estimate_tokens()` / `ac_calibrate_tokens()`: estimativa e
  calibração de consumo de tokens sem depender de uma chamada de rede
  por documento.
* Nova vignette `llm-local-em-escala` cobrindo o fluxo completo de
  classificação local em escala.
* `stats` e `utils` adicionados a `Imports` em `DESCRIPTION` (usados
  via `::` havia tempo, faltava a declaração formal — NOTE latente
  corrigido).

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

* Local: Windows 11, R 4.6.1 (ucrt) — full `devtools::document()`,
  `devtools::test()` (879 passed, 0 failed) and
  `devtools::check(remote = TRUE, manual = TRUE)` run confirmed.
* GitHub Actions matrix on the tip of `main`: Ubuntu R-devel / release
  / oldrel-1, macOS release, Windows release (to be re-confirmed after
  this branch merges; no changes to the workflow files themselves).

## R CMD check results

Local, `--as-cran`, confirmed:

```
0 errors | 0 warnings | 1 NOTE
```

The NOTE is:

1. **Invalid URL** — `README.md` links to
   `https://andersonheri.github.io/acR/articles/llm-local-em-escala.html`
   (the new vignette added in this release), which 404s because the
   pkgdown site has not been rebuilt yet on this branch. The `pkgdown`
   GitHub Action rebuilds the site automatically once this branch
   merges to `main`; the URL will resolve at that point. If it still
   404s when CRAN processes the submission, rebuild and deploy the
   site manually (`pkgdown::build_site()` + push to `gh-pages`) before
   resubmitting, or temporarily drop that one link from `README.md`.

## Pre-submission checklist for this release

1. ~~`devtools::document()`~~ — done; `man/*.Rd` and `NAMESPACE` are in
   sync with the roxygen comments in `R/*.R`.
2. ~~`devtools::test()`~~ — done; `0` failures.
3. ~~`devtools::check(remote = TRUE, manual = TRUE)`~~ — done; see
   above.
4. **Before submitting**: make sure the `llm-local-em-escala` article
   is live at the URL above (merge this branch to `main` and let the
   `pkgdown` Action run, or build+deploy manually) so the NOTE above
   does not reproduce on CRAN's end.
5. `devtools::submit_cran()`, and click the confirmation email — both
   steps require your local machine/inbox.

## Downstream dependencies

None known.

## Reviewer notes

* No changes to DESCRIPTION Fields, License, or reverse dependencies.
* All items from the 0.3.2 review (K. Lauseker, 2026-07-28) remain in
  effect: no `\dontrun{}` beyond truly external-service examples, no
  writes to `.GlobalEnv`, no `<<-`, no `set.seed()` inside functions
  (all seeds are user-controlled parameters scoped via `withr`).
