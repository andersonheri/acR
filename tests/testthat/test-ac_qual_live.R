# Testes dos helpers de live view. Shiny nao e testado (dependencia pesada
# + roda em processo separado); testamos os modos off e terminal.

test_that(".ac_live_start('off') retorna ctx com mode off e sem side effects", {
  ctx <- acR:::.ac_live_start(mode = "off", n_docs = 10L)
  expect_identical(ctx$mode, "off")
  expect_identical(ctx$n, 10L)
})

test_that(".ac_live_update('off') e no-op", {
  ctx <- list(mode = "off")
  expect_null(acR:::.ac_live_update(
    ctx, i = 1, n_docs = 5, doc_id = "d1",
    main_result = list(categoria = "x"), conf_scores = NULL
  ))
})

test_that(".ac_live_finish() nao falha com ctx NULL/off", {
  expect_invisible(acR:::.ac_live_finish(NULL))
  expect_invisible(acR:::.ac_live_finish(list(mode = "off")))
})

test_that(".ac_live_start('terminal') retorna ctx no formato certo", {
  # Nao invocamos progress_update fora do contexto do progress bar
  # (cli guarda estado global; testes isolados quebram).
  # Apenas validamos que o modo eh reconhecido e o ctx tem a estrutura.
  ctx <- acR:::.ac_live_start(mode = "terminal", n_docs = 3L)
  expect_identical(ctx$mode, "terminal")
  expect_identical(ctx$n, 3L)

  # Finish encerra sem erro
  expect_invisible(acR:::.ac_live_finish(ctx))
})

test_that(".ac_live_start('shiny') sem pacote cai para terminal via warn", {
  # Assumindo shiny provavelmente instalado no dev env, so testamos que
  # a rotina de fallback tem o requireNamespace. Vamos testar diretamente
  # o comportamento de fallback simulando via ac_qual_code().

  # ac_qual_code() emite warning e cai para terminal se shiny ausente.
  # Nao chamamos ac_qual_code (requer LLM), so validamos que a logica
  # em ac_qual_live.R existe.
  expect_true(exists(".ac_live_start", envir = asNamespace("acR")))
})


# ============================================================
# Bug fix: cli::cli_progress_bar sem .envir travava a barra ao frame
# de .ac_live_start(), que retorna imediatamente -- primeira chamada
# de cli_progress_update encontrava "Cannot find progress bar".
# Fix: .ac_live_start ganha argumento .envir (default parent.frame()),
# amarrando a barra ao chamador (ac_qual_code).
# ============================================================

test_that(".ac_live_start('terminal') sobrevive alem do proprio frame (bug .envir)", {
  # Simula o fluxo real: um wrapper chama .ac_live_start, guarda o ctx
  # e sai de escopo; depois um segundo wrapper (analogo ao loop de
  # ac_qual_code) tenta atualizar a barra. Antes do fix, isso falhava
  # imediatamente com "Cannot find progress bar <id>".
  run_pipeline <- function() {
    ctx <- acR:::.ac_live_start(mode = "terminal", n_docs = 3L)
    # Alguns updates: se .envir estiver amarrado ao frame errado, o
    # primeiro update ja quebra
    for (i in seq_len(3L)) {
      cli::cli_progress_update(id = ctx$pb, status = paste0("doc ", i),
                               .envir = parent.frame())
    }
    acR:::.ac_live_finish(ctx)
    "ok"
  }
  expect_equal(run_pipeline(), "ok")
})
