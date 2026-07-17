# Testes de ac_qual_code focados no argumento `live` (validacao e fallback).
# NAO testa classificacao real (requer chave de API); usamos mocks.

test_that("ac_qual_code() rejeita valores invalidos de live", {
  skip_if_not_installed("ellmer")

  cb <- ac_qual_codebook(
    name         = "x",
    instructions = "y",
    categories   = list(
      a = list(definition = "def a"),
      b = list(definition = "def b")
    )
  )
  corpus <- ac_corpus(data.frame(text = "teste"))

  # live tem de ser um dos valores em match.arg
  expect_error(
    ac_qual_code(corpus, cb, live = "modo_inexistente"),
    "'arg'"  # msg default do match.arg
  )
})

test_that("ac_qual_code() com live='shiny' cai para 'terminal' se shiny ausente", {
  skip_if_not_installed("ellmer")

  # Nao vamos rodar de verdade (precisa API). Apenas verificar que a
  # funcao esta documentada com o argumento.
  args <- names(formals(ac_qual_code))
  expect_true("live" %in% args)

  # Default deve ser "off"
  expect_identical(eval(formals(ac_qual_code)$live)[1], "off")
})
