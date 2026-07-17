# Testes de ac_qual_report() — geracao de relatorio de replicabilidade.
# Testa em Markdown (nao requer rmarkdown/pandoc); HTML testado condicionalmente.

make_cb <- function() {
  ac_qual_codebook(
    name         = "polaridade",
    instructions = "Classifique a polaridade.",
    categories   = list(
      favor  = list(definition = "Apoio.",     examples_pos = "Sou a favor."),
      contra = list(definition = "Oposicao.")
    )
  )
}

make_coded <- function(n = 6L) {
  tibble::tibble(
    doc_id           = paste0("d", seq_len(n)),
    categoria        = sample(c("favor", "contra"), n, replace = TRUE),
    confidence_score = c(1.00, 0.67, 1.00, 1.00, 0.67, 0.33)[seq_len(n)],
    reasoning        = rep("motivo", n)
  )
}

test_that("ac_qual_report() em markdown gera arquivo com todas as secoes", {
  cb    <- make_cb()
  coded <- make_coded()
  tmp   <- tempfile(fileext = ".md")

  path <- ac_qual_report(coded, cb, path = tmp, author = "Test", format = "md")

  expect_true(file.exists(path))
  txt <- paste(readLines(path), collapse = "\n")

  # Secoes obrigatorias
  expect_match(txt, "## 1\\. Visao geral")
  expect_match(txt, "## 2\\. Codebook")
  expect_match(txt, "## 3\\. Historico")
  expect_match(txt, "## 4\\. Configuracao da LLM")
  expect_match(txt, "## 5\\. Resultados")
  expect_match(txt, "## 6\\. Confiabilidade")
  expect_match(txt, "## 7\\. Referencias")
  expect_match(txt, "## 8\\. Como citar")

  # Autor injetado
  expect_match(txt, "Test")
})

test_that("ac_qual_report() aceita lang = 'en'", {
  cb    <- make_cb()
  coded <- make_coded()
  tmp   <- tempfile(fileext = ".md")

  path <- ac_qual_report(coded, cb, path = tmp, lang = "en")
  txt  <- paste(readLines(path), collapse = "\n")

  expect_match(txt, "## 1\\. Overview")
  expect_match(txt, "## 2\\. Codebook")
  expect_match(txt, "## 8\\. How to cite")
})

test_that("ac_qual_report() inclui secao IRR se reliability fornecido", {
  cb    <- make_cb()
  coded <- make_coded()

  # Mock de reliability: lista com $metrics tibble compativel
  rel <- list(
    metrics = tibble::tibble(
      metric   = c("krippendorff", "gwet_ac1"),
      estimate = c(0.78, 0.81),
      ci_low   = c(0.65, 0.70),
      ci_high  = c(0.88, 0.90)
    )
  )
  class(rel) <- c("ac_reliability", "list")

  tmp  <- tempfile(fileext = ".md")
  path <- ac_qual_report(coded, cb, reliability = rel, path = tmp)
  txt  <- paste(readLines(path), collapse = "\n")

  expect_match(txt, "krippendorff")
  expect_match(txt, "0\\.78")
  expect_false(grepl("Nao foi executada validacao", txt))
})

test_that("ac_qual_report() rejeita coded nao-tibble e codebook errado", {
  cb <- make_cb()
  expect_error(ac_qual_report(coded = "nao_tibble", codebook = cb),
               "deve ser um tibble")
  expect_error(ac_qual_report(coded = make_coded(),
                              codebook = list()),
               "ac_codebook")
})

test_that("ac_qual_report() infere provider/model de string tipo 'provider/id'", {
  cb    <- make_cb()
  coded <- make_coded()
  tmp   <- tempfile(fileext = ".md")

  ac_qual_report(coded, cb, chat = "anthropic/claude-sonnet-4-5",
                 path = tmp)
  txt <- paste(readLines(tmp), collapse = "\n")

  expect_match(txt, "anthropic")
  expect_match(txt, "claude-sonnet-4-5")
})
