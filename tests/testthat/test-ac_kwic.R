# Testes para ac_kwic()

test_that("ac_kwic() rejeita corpus invalido", {
  expect_error(ac_kwic("nao e corpus", pattern = "x"), regexp = "ac_corpus")
})

test_that("ac_kwic() encontra todas as ocorrencias com contexto correto", {
  df <- data.frame(
    id = "d1",
    texto = "o atendimento foi rapido e o atendimento foi cordial",
    stringsAsFactors = FALSE
  )
  corpus <- ac_corpus(df, text = texto, docid = id)
  out <- ac_kwic(corpus, pattern = "atendimento", window = 2)

  expect_equal(nrow(out), 2L)
  expect_equal(out$keyword, c("atendimento", "atendimento"))
  expect_equal(out$before[1], "o")
  expect_equal(out$after[1], "foi rapido")
  expect_equal(out$before[2], "e o")
  expect_equal(out$after[2], "foi cordial")
})

test_that("ac_kwic() devolve tibble vazio quando nao ha ocorrencias", {
  df <- data.frame(id = "d1", texto = "nada aqui relevante", stringsAsFactors = FALSE)
  corpus <- ac_corpus(df, text = texto, docid = id)
  out <- ac_kwic(corpus, pattern = "inexistente")
  expect_equal(nrow(out), 0L)
})

test_that("ac_kwic() respeita case_insensitive", {
  df <- data.frame(id = "d1", texto = "Atendimento bom", stringsAsFactors = FALSE)
  corpus <- ac_corpus(df, text = texto, docid = id)

  out_ci <- ac_kwic(corpus, pattern = "atendimento", case_insensitive = TRUE)
  expect_equal(nrow(out_ci), 1L)

  out_cs <- ac_kwic(corpus, pattern = "atendimento", case_insensitive = FALSE)
  expect_equal(nrow(out_cs), 0L)
})

test_that("ac_kwic(regex = TRUE) busca por padrao", {
  df <- data.frame(id = "d1", texto = "atender atendimento atendente",
                   stringsAsFactors = FALSE)
  corpus <- ac_corpus(df, text = texto, docid = id)
  out <- ac_kwic(corpus, pattern = "^atend", regex = TRUE)
  expect_equal(nrow(out), 3L)
})

test_that("ac_kwic() limita a janela no inicio/fim do documento", {
  df <- data.frame(id = "d1", texto = "atendimento bom", stringsAsFactors = FALSE)
  corpus <- ac_corpus(df, text = texto, docid = id)
  out <- ac_kwic(corpus, pattern = "atendimento", window = 5)
  expect_equal(out$before, "")
  expect_equal(out$after, "bom")
})
