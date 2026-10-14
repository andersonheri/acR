# Testes para ac_readability() e ac_plot_readability()

test_that("ac_readability() rejeita corpus invalido", {
  expect_error(ac_readability("nao e corpus"), regexp = "ac_corpus")
})

test_that("ac_readability() conta palavras e frases corretamente", {
  df <- data.frame(
    id = "d1",
    texto = "O gato subiu no muro. Depois ele desceu rapido.",
    stringsAsFactors = FALSE
  )
  corpus <- ac_corpus(df, text = texto, docid = id)
  out <- ac_readability(corpus)

  expect_equal(out$n_frases, 2L)
  expect_equal(out$n_palavras, 10L)
  expect_true(!is.na(out$flesch))
})

test_that("ac_readability() devolve NA para documento vazio sem quebrar", {
  df <- data.frame(id = c("d1", "d2"), texto = c("", "Texto normal aqui."),
                   stringsAsFactors = FALSE)
  corpus <- ac_corpus(df, text = texto, docid = id) |> suppressWarnings()
  out <- ac_readability(corpus)

  expect_true(is.na(out$flesch[out$doc_id == "d1"]))
  expect_false(is.na(out$flesch[out$doc_id == "d2"]))
})

test_that("ac_readability() classifica textos simples como mais faceis que complexos", {
  df <- data.frame(
    id = c("simples", "complexo"),
    texto = c(
      "Eu vi o cao. O cao correu.",
      paste(
        "A implementacao hermeneutica da disposicao normativa",
        "pressupoe exegese sistematica da jurisprudencia consolidada."
      )
    ),
    stringsAsFactors = FALSE
  )
  corpus <- ac_corpus(df, text = texto, docid = id)
  out <- ac_readability(corpus)

  flesch_simples  <- out$flesch[out$doc_id == "simples"]
  flesch_complexo <- out$flesch[out$doc_id == "complexo"]
  expect_true(flesch_simples > flesch_complexo)
})

test_that("ac_readability(by = ...) agrega por grupo", {
  df <- data.frame(
    id = paste0("d", 1:4),
    texto = c("Texto curto aqui.", "Outro texto curto.",
              "Mais um texto breve.", "E o ultimo tambem breve."),
    grupo = c("a", "a", "b", "b"),
    stringsAsFactors = FALSE
  )
  corpus <- ac_corpus(df, text = texto, docid = id, meta = grupo)
  out <- ac_readability(corpus, by = "grupo")

  expect_equal(nrow(out), 2L)
  expect_true(all(c("a", "b") %in% out$grupo))
})

test_that("ac_readability() rejeita by com coluna inexistente", {
  df <- data.frame(id = "d1", texto = "Texto.", stringsAsFactors = FALSE)
  corpus <- ac_corpus(df, text = texto, docid = id)
  expect_error(ac_readability(corpus, by = "inexistente"), regexp = "ausentes")
})

test_that(".ac_count_syllables_pt() conta pelo menos 1 silaba por palavra", {
  expect_equal(acR:::.ac_count_syllables_pt(c("a", "casa", "trabalho")), c(1L, 2L, 3L))
})

test_that("ac_plot_readability() gera um objeto ggplot", {
  skip_if_not_installed("ggplot2")
  df <- data.frame(id = paste0("d", 1:4),
                   texto = c("Texto a.", "Texto b.", "Texto c.", "Texto d."),
                   grupo = c("x", "x", "y", "y"), stringsAsFactors = FALSE)
  corpus <- ac_corpus(df, text = texto, docid = id, meta = grupo)
  leg <- ac_readability(corpus)
  leg$grupo <- corpus$grupo
  p <- ac_plot_readability(leg, group_col = "grupo")
  expect_s3_class(p, "ggplot")
})
