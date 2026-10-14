# Testes para ac_dictionary(), ac_build_dictionary(), save/load/import

make_dict_corpus <- function() {
  df <- data.frame(
    id = paste0("d", 1:3),
    texto = c(
      "a entrega atrasou muito e o rastreio nao funcionava",
      "o produto chegou com defeito e quebrado",
      "entrega rapida e produto perfeito sem defeito"
    ),
    stringsAsFactors = FALSE
  )
  ac_corpus(df, text = texto, docid = id)
}

test_that("ac_build_dictionary() constroi uma lista nomeada valida", {
  dict <- ac_build_dictionary(a = c("x", "y"), b = c("z"))
  expect_type(dict, "list")
  expect_equal(names(dict), c("a", "b"))
})

test_that("ac_build_dictionary() rejeita categorias sem nome ou vazias", {
  expect_error(ac_build_dictionary(c("x", "y")), regexp = "nome")
  expect_error(ac_build_dictionary(a = character(0)), regexp = "sem palavras")
})

test_that("ac_dictionary() rejeita corpus invalido", {
  dict <- ac_build_dictionary(a = "x")
  expect_error(ac_dictionary("nao e corpus", dict), regexp = "ac_corpus")
})

test_that("ac_dictionary() conta palavras por categoria corretamente", {
  corpus <- make_dict_corpus()
  dict <- ac_build_dictionary(
    entrega = c("entrega", "atrasou", "rapida"),
    produto = c("defeito", "perfeito")
  )
  out <- ac_dictionary(corpus, dict)

  expect_equal(out$entrega_n, c(2L, 0L, 2L))
  expect_equal(out$produto_n, c(0L, 1L, 2L))
  expect_true(all(c("entrega_prop", "produto_prop", "total_tokens") %in% names(out)))
})

test_that("ac_dictionary() calcula proporcao corretamente", {
  corpus <- make_dict_corpus()
  dict <- ac_build_dictionary(entrega = c("entrega", "atrasou", "rapida"))
  out <- ac_dictionary(corpus, dict)
  expect_equal(out$entrega_prop, out$entrega_n / out$total_tokens)
})

test_that("ac_dictionary() respeita case_insensitive = FALSE", {
  df <- data.frame(id = "d1", texto = "Entrega entrega", stringsAsFactors = FALSE)
  corpus <- ac_corpus(df, text = texto, docid = id)
  dict <- ac_build_dictionary(cat = "entrega")

  out_ci <- ac_dictionary(corpus, dict, case_insensitive = TRUE)
  expect_equal(out_ci$cat_n, 2L)

  out_cs <- ac_dictionary(corpus, dict, case_insensitive = FALSE)
  expect_equal(out_cs$cat_n, 1L)
})

test_that("ac_dictionary(by = ...) agrega por grupo", {
  corpus <- make_dict_corpus()
  dict <- ac_build_dictionary(entrega = c("entrega", "atrasou", "rapida"))
  by_tbl <- ac_dictionary(corpus, dict, by = NULL)
  expect_equal(nrow(by_tbl), 3L)
})

test_that("ac_dictionary_save()/ac_dictionary_load() fazem round-trip", {
  skip_if_not_installed("yaml")
  dict <- ac_build_dictionary(positivo = c("bom", "otimo"),
                              negativo = c("mau", "pessimo"))
  arquivo <- tempfile(fileext = ".yaml")
  ac_dictionary_save(dict, arquivo)
  dict2 <- ac_dictionary_load(arquivo)
  expect_equal(dict, dict2)
})

test_that("ac_dictionary_import() constroi dicionario a partir de tabela longa", {
  lexico <- data.frame(
    termo     = c("bom", "otimo", "mau", "pessimo"),
    categoria = c("positivo", "positivo", "negativo", "negativo"),
    stringsAsFactors = FALSE
  )
  dict <- ac_dictionary_import(lexico)
  expect_equal(sort(names(dict)), c("negativo", "positivo"))
  expect_equal(sort(dict$positivo), c("bom", "otimo"))
})

test_that("ac_dictionary_import() rejeita colunas ausentes", {
  lexico <- data.frame(x = 1)
  expect_error(ac_dictionary_import(lexico), regexp = "colunas")
})

test_that("ac_dictionary_import() aceita caminho de arquivo CSV", {
  lexico <- data.frame(
    termo = c("bom", "mau"), categoria = c("positivo", "negativo"),
    stringsAsFactors = FALSE
  )
  arquivo <- tempfile(fileext = ".csv")
  utils::write.csv(lexico, arquivo, row.names = FALSE)
  dict <- ac_dictionary_import(arquivo)
  expect_equal(sort(names(dict)), c("negativo", "positivo"))
})
