# Testes para ac_lexical_diversity() e ac_plot_lexical_diversity()

test_that("ac_lexical_diversity() rejeita corpus invalido", {
  expect_error(ac_lexical_diversity("nao e corpus"), regexp = "ac_corpus")
})

test_that("ac_lexical_diversity() calcula TTR corretamente para vocabulario repetitivo", {
  df <- data.frame(id = "d1", texto = "sol sol sol sol", stringsAsFactors = FALSE)
  corpus <- ac_corpus(df, text = texto, docid = id)
  out <- ac_lexical_diversity(corpus)

  expect_equal(out$n_tokens, 4L)
  expect_equal(out$n_types, 1L)
  expect_equal(out$ttr, 0.25)
})

test_that("ac_lexical_diversity() identifica texto com vocabulario mais variado", {
  df <- data.frame(
    id = c("repetitivo", "variado"),
    texto = c(
      "corre corre corre corre corre corre",
      "sol lua estrela ceu nuvem vento"
    ),
    stringsAsFactors = FALSE
  )
  corpus <- ac_corpus(df, text = texto, docid = id)
  out <- ac_lexical_diversity(corpus)

  ttr_rep <- out$ttr[out$doc_id == "repetitivo"]
  ttr_var <- out$ttr[out$doc_id == "variado"]
  expect_true(ttr_var > ttr_rep)
  expect_equal(ttr_var, 1)
})

test_that("ac_lexical_diversity() nao diferencia maiusculas/minusculas por padrao", {
  df <- data.frame(id = "d1", texto = "Casa casa CASA", stringsAsFactors = FALSE)
  corpus <- ac_corpus(df, text = texto, docid = id)
  out <- ac_lexical_diversity(corpus)
  expect_equal(out$n_types, 1L)
})

test_that("ac_lexical_diversity(case_sensitive = TRUE) diferencia caixa", {
  df <- data.frame(id = "d1", texto = "Casa casa CASA", stringsAsFactors = FALSE)
  corpus <- ac_corpus(df, text = texto, docid = id)
  out <- ac_lexical_diversity(corpus, case_sensitive = TRUE)
  expect_equal(out$n_types, 3L)
})

test_that("ac_lexical_diversity(by = ...) agrega por grupo", {
  df <- data.frame(
    id = paste0("d", 1:4),
    texto = c("sol lua", "estrela ceu", "sol sol", "lua lua"),
    grupo = c("a", "a", "b", "b"),
    stringsAsFactors = FALSE
  )
  corpus <- ac_corpus(df, text = texto, docid = id, meta = grupo)
  out <- ac_lexical_diversity(corpus, by = "grupo")
  expect_equal(nrow(out), 2L)
})

test_that(".ac_mtld() devolve NA para menos de 2 tokens", {
  expect_true(is.na(acR:::.ac_mtld(character(0))))
  expect_true(is.na(acR:::.ac_mtld("unico")))
})

test_that(".ac_mtld() devolve o numero de tokens quando a TTR nunca cai abaixo do limiar", {
  tokens <- c("a", "b", "c", "d", "e")
  expect_equal(acR:::.ac_mtld(tokens), length(tokens))
})

test_that("ac_plot_lexical_diversity() gera um objeto ggplot", {
  skip_if_not_installed("ggplot2")
  df <- data.frame(id = paste0("d", 1:4),
                   texto = c("sol lua", "estrela ceu", "sol sol", "lua lua"),
                   grupo = c("a", "a", "b", "b"), stringsAsFactors = FALSE)
  corpus <- ac_corpus(df, text = texto, docid = id, meta = grupo)
  div <- ac_lexical_diversity(corpus, by = "grupo")
  p <- ac_plot_lexical_diversity(div, group_col = "grupo")
  expect_s3_class(p, "ggplot")
})
