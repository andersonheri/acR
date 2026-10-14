# Testes para ac_ca() e ac_plot_ca()

make_ca_corpus <- function() {
  df <- data.frame(
    id = paste0("d", 1:6),
    texto = c(
      "entrega atrasada rastreio sumiu",
      "pedido atrasou rastreio sumiu",
      "produto defeito quebrado chegou",
      "veio quebrado produto pessimo",
      "atendimento excelente resolveram rapido",
      "suporte educado resolveu rapido"
    ),
    categoria = c("entrega", "entrega", "produto", "produto",
                  "atendimento", "atendimento"),
    stringsAsFactors = FALSE
  )
  ac_corpus(df, text = texto, docid = id, meta = categoria)
}

test_that("ac_ca() rejeita corpus invalido", {
  expect_error(ac_ca("nao e corpus"), regexp = "ac_corpus")
})

test_that("ac_ca() rejeita by com mais de uma coluna", {
  corpus <- make_ca_corpus()
  expect_error(ac_ca(corpus, by = c("categoria", "categoria")), regexp = "unica coluna")
})

test_that("ac_ca() rejeita filtros que deixam menos de 2 termos", {
  corpus <- make_ca_corpus()
  expect_error(ac_ca(corpus, min_count = 1000), regexp = "Menos de 2 termos")
})

test_that("ac_ca() roda por grupo (by) sem erro e devolve estrutura esperada", {
  corpus <- make_ca_corpus()
  ca <- ac_ca(corpus, by = "categoria", min_count = 1)

  expect_s3_class(ca, "ac_ca")
  expect_true(all(c("row_coords", "col_coords", "eigenvalues", "variance_explained") %in% names(ca)))
  expect_equal(nrow(ca$row_coords), 3L)
  expect_true(all(c("unit", "dim1", "dim2", "mass") %in% names(ca$row_coords)))
  expect_true(all(c("term", "dim1", "dim2", "mass") %in% names(ca$col_coords)))
  expect_equal(sum(ca$variance_explained), 1, tolerance = 1e-8)
})

test_that(".ac_ca_svd() reproduz uma analise de correspondencia verificada numericamente (toy 3x3)", {
  mat <- matrix(
    c(10, 5, 1,
      2, 5, 10,
      6, 6, 6),
    nrow = 3, byrow = TRUE,
    dimnames = list(c("A", "B", "C"), c("t1", "t2", "t3"))
  )

  out <- acR:::.ac_ca_svd(mat, n_dim = 2)

  expect_equal(out$eigenvalues, c(0.2523116, 0.00100593), tolerance = 1e-5)
  expect_equal(out$variance_explained, c(0.99602896, 0.00397104), tolerance = 1e-5)

  rc <- out$row_coords
  rc <- rc[match(c("A", "B", "C"), rc$unit), ]
  expect_equal(rc$dim1, c(0.65519454, -0.59363827, -0.02173678), tolerance = 1e-5)
  expect_equal(rc$dim2, c(-0.02211326, -0.0246347, 0.04292234), tolerance = 1e-5)
  expect_equal(rc$mass, c(0.31372549, 0.33333333, 0.35294118), tolerance = 1e-5)

  cc <- out$col_coords
  cc <- cc[match(c("t1", "t2", "t3"), cc$term), ]
  expect_equal(cc$dim1, c(0.57891286, 0.02206829, -0.63373671), tolerance = 1e-5)
  expect_equal(cc$dim2, c(-0.02253999, 0.04688856, -0.02026454), tolerance = 1e-5)
  expect_equal(cc$mass, c(0.35294118, 0.31372549, 0.33333333), tolerance = 1e-5)
})

test_that("ac_plot_ca() gera um objeto ggplot", {
  skip_if_not_installed("ggplot2")
  corpus <- make_ca_corpus()
  ca <- ac_ca(corpus, by = "categoria", min_count = 1)
  p <- ac_plot_ca(ca)
  expect_s3_class(p, "ggplot")
})

test_that("ac_plot_ca() rejeita objeto que nao seja ac_ca", {
  skip_if_not_installed("ggplot2")
  expect_error(ac_plot_ca(list(a = 1)), regexp = "ac_ca")
})
