# Testes para ac_wordscores()

make_wordscores_corpus <- function() {
  df <- data.frame(
    id = c("r1", "r2", "r3", "v1"),
    texto = c(
      "bom bom otimo",
      "bom razoavel",
      "ruim ruim pessimo",
      "bom bom bom"
    ),
    stringsAsFactors = FALSE
  )
  ac_corpus(df, text = texto, docid = id)
}

test_that("ac_wordscores() rejeita corpus invalido", {
  expect_error(ac_wordscores("nao e corpus", c(a = 1, b = 2)), regexp = "ac_corpus")
})

test_that("ac_wordscores() rejeita scores nao-nomeado", {
  corpus <- make_wordscores_corpus()
  expect_error(ac_wordscores(corpus, c(1, 2, 3)), regexp = "nomeado")
})

test_that("ac_wordscores() rejeita menos de 2 referencias validas", {
  corpus <- make_wordscores_corpus()
  expect_error(ac_wordscores(corpus, c(r1 = 5)), regexp = "2 documentos")
})

test_that("ac_wordscores() avisa sobre doc_id de referencia ausente do corpus", {
  corpus <- make_wordscores_corpus()
  expect_warning(
    ac_wordscores(corpus, c(r1 = 5, r2 = 3, inexistente = 9)),
    regexp = "ausentes"
  )
})

test_that("ac_wordscores() calcula escores brutos corretamente (verificado a mao)", {
  corpus <- make_wordscores_corpus()
  notas <- c(r1 = 5, r2 = 3, r3 = 1)

  out <- ac_wordscores(corpus, notas, rescale = "none")

  expect_equal(out$is_reference, c(TRUE, TRUE, TRUE, FALSE))
  expect_equal(out$score[out$doc_id == "r1"], 4.428571428571429, tolerance = 1e-8)
  expect_equal(out$score[out$doc_id == "r2"], 3.571428571428571, tolerance = 1e-8)
  expect_equal(out$score[out$doc_id == "r3"], 1, tolerance = 1e-8)
  expect_equal(out$score[out$doc_id == "v1"], 4.142857142857143, tolerance = 1e-8)
  expect_equal(out$score, out$score_raw)
})

test_that("ac_wordscores() rescale = 'lbg' segue Laver, Benoit & Garry (2003, p. 316)", {
  df <- data.frame(
    id = c("r1", "r2", "r3", "v1", "v2"),
    texto = c("bom bom otimo", "bom razoavel", "ruim ruim pessimo",
              "bom bom bom", "ruim razoavel"),
    stringsAsFactors = FALSE
  )
  corpus <- ac_corpus(df, text = texto, docid = id)
  notas  <- c(r1 = 5, r2 = 3, r3 = 1)

  bruto <- ac_wordscores(corpus, notas, rescale = "none")
  sv    <- bruto$score_raw[!bruto$is_reference]
  # S* = (S - media_virgens) * (DP_referencias_conhecidas / DP_virgens) + media_virgens
  esperado <- (sv - mean(sv)) * (stats::sd(c(5, 3, 1)) / stats::sd(sv)) + mean(sv)

  out <- suppressWarnings(ac_wordscores(corpus, notas, rescale = "lbg"))
  expect_equal(out$score[!out$is_reference], esperado, tolerance = 1e-10)
  # os virgens passam a ter a dispersao das referencias
  expect_equal(stats::sd(out$score[!out$is_reference]), stats::sd(c(5, 3, 1)))
  # com poucos virgens, avisa da instabilidade
  expect_warning(ac_wordscores(corpus, notas, rescale = "lbg"), "inst")
})

test_that("ac_wordscores() rescale = 'lbg' exige pelo menos 2 virgens", {
  corpus <- make_wordscores_corpus()
  expect_error(ac_wordscores(corpus, c(r1 = 5, r2 = 3, r3 = 1), rescale = "lbg"),
               "2 documentos virgens")
})

test_that("ac_wordscores() reescalona com rescale = 'mv' (verificado a mao)", {
  corpus <- make_wordscores_corpus()
  notas <- c(r1 = 5, r2 = 3, r3 = 1)

  out <- ac_wordscores(corpus, notas, rescale = "mv")

  expect_equal(out$score[out$doc_id == "v1"], 4.666666666666667, tolerance = 1e-6)
})

test_that("ac_wordscores() aceita scores como tibble", {
  corpus <- make_wordscores_corpus()
  notas <- tibble::tibble(doc_id = c("r1", "r2", "r3"), score = c(5, 3, 1))

  out <- ac_wordscores(corpus, notas, rescale = "none")
  expect_equal(out$score[out$doc_id == "v1"], 4.142857142857143, tolerance = 1e-8)
})

test_that("ac_wordscores() rescale = 'mv' recupera exatamente as referencias extremas", {
  corpus <- make_wordscores_corpus()
  out <- ac_wordscores(corpus, c(r1 = 5, r2 = 3, r3 = 1), rescale = "mv")
  expect_equal(out$score[out$doc_id == "r1"], 5)
  expect_equal(out$score[out$doc_id == "r3"], 1)
})
