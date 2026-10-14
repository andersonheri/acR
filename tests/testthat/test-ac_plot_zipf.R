# Testes para ac_plot_zipf()

test_that("ac_plot_zipf() rejeita entrada sem colunas token/n", {
  expect_error(ac_plot_zipf(data.frame(x = 1)), regexp = "token")
})

test_that("ac_plot_zipf() gera um objeto ggplot a partir de ac_count()", {
  skip_if_not_installed("ggplot2")
  df <- data.frame(
    id = paste0("d", 1:3),
    texto = c("bom produto bom preco", "produto bom entrega lenta",
              "preco justo produto"),
    stringsAsFactors = FALSE
  )
  corpus <- ac_corpus(df, text = texto, docid = id)
  freq <- ac_count(corpus, drop_punct = TRUE)
  p <- ac_plot_zipf(freq)
  expect_s3_class(p, "ggplot")
})

test_that("ac_plot_zipf(by = ...) faceta por grupo", {
  skip_if_not_installed("ggplot2")
  df <- data.frame(
    id = paste0("d", 1:4),
    texto = c("bom produto", "produto bom", "casa boa", "boa casa"),
    categoria = c("a", "a", "b", "b"),
    stringsAsFactors = FALSE
  )
  corpus <- ac_corpus(df, text = texto, docid = id)
  freq <- ac_count(corpus, by = "categoria")
  p <- ac_plot_zipf(freq, by = "categoria")
  expect_s3_class(p, "ggplot")
})

test_that("ac_plot_zipf() rejeita by com coluna inexistente", {
  skip_if_not_installed("ggplot2")
  df <- data.frame(id = "d1", texto = "a b c", stringsAsFactors = FALSE)
  corpus <- ac_corpus(df, text = texto, docid = id)
  freq <- ac_count(corpus)
  expect_error(ac_plot_zipf(freq, by = "inexistente"), regexp = "coluna existente")
})
