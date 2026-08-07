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


# ============================================================
# Bug fix: ac_qual_report(path = <relativo>) falhava com
# "The directory 'X' does not exist" quando rmarkdown::render()
# mudava de cwd. Fix: .ac_report_absolute_path + dir.create.
# ============================================================

test_that("ac_qual_report() resolve path relativo em absoluto (bug 4)", {
  cb <- ac_qual_codebook(
    name = "t", instructions = "cl.",
    categories = list(
      a = list(definition = "cat a"),
      b = list(definition = "cat b")
    )
  )
  coded <- tibble::tibble(
    doc_id = c("d1", "d2"),
    categoria = c("a", "b"),
    confidence_score = c(1, 0.67)
  )
  # Muda para tempdir e passa path relativo -- antes do fix quebrava
  old_wd <- setwd(tempdir())
  on.exit(setwd(old_wd), add = TRUE)
  rel_path <- file.path("subdir_report", "rel.md")
  # subdir_report nao existe ainda -- fix deve cria-lo
  suppressMessages(out <- ac_qual_report(coded, cb, path = rel_path))
  expect_true(file.exists(out))
  expect_true(grepl("^/", out))  # ja e absoluto
  expect_true(dir.exists(file.path(tempdir(), "subdir_report")))
})


# ============================================================
# ac_qual_report_full (Feature 6) -- relatorio multi-variavel
# ============================================================

test_that("ac_qual_report_full() gera 1 arquivo com N secoes", {
  cb1 <- ac_qual_codebook(
    name = "tom", instructions = "cl.",
    categories = list(
      pos = list(definition = "positivo", label = "Positivo"),
      neg = list(definition = "negativo", label = "Negativo")
    )
  )
  cb2 <- ac_qual_codebook(
    name = "pos", instructions = "cl.",
    categories = list(
      favor  = list(definition = "a favor", label = "A favor"),
      contra = list(definition = "contra",  label = "Contra")
    )
  )
  coded1 <- tibble::tibble(doc_id = c("d1","d2"), categoria = c("pos","neg"),
                           confidence_score = c(1, 1))
  coded2 <- tibble::tibble(doc_id = c("d1","d2"), categoria = c("favor","contra"),
                           confidence_score = c(1, 1))

  path <- tempfile(fileext = ".md")
  suppressMessages(out <- ac_qual_report_full(
    variables = list(
      "Tom do discurso" = list(coded = coded1, codebook = cb1),
      "Posicao politica" = list(coded = coded2, codebook = cb2)
    ),
    path = path
  ))
  expect_true(file.exists(out))
  contents <- readLines(out)
  expect_true(any(grepl("^# Tom do discurso", contents)))
  expect_true(any(grepl("^# Posicao politica", contents)))
  # Tabela sumario deve mencionar ambos os codebooks
  expect_true(any(grepl("Tom do discurso.*2.*2", contents)))
})

test_that("ac_qual_report_full() rejeita input mal formado", {
  # lista sem nomes
  expect_error(
    ac_qual_report_full(variables = list(list(coded = 1, codebook = 1))),
    regexp = "nomeada"
  )
  # falta coded ou codebook
  expect_error(
    ac_qual_report_full(variables = list("x" = list(coded = tibble::tibble()))),
    regexp = "obrigatorios"
  )
})
