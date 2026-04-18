# Testes para ac_plot_cooccurrence()
# Requer ggraph e igraph (Suggests). Todos os testes usam skip_if_not_installed.

# ============================================================
# Fixture
# ============================================================

make_cooc_tbl <- function() {
  tibble::tibble(
    word1 = c("democracia", "participacao", "cidadania",
              "democracia",  "participacao"),
    word2 = c("participacao", "cidadania", "direitos",
              "cidadania",   "direitos"),
    cooc  = c(5L, 4L, 3L, 2L, 2L)
  )
}

make_cooc_tbl_pmi <- function() {
  tbl <- make_cooc_tbl()
  tbl$pmi  <- c(2.1, 1.8, 1.5, 1.2, 1.0)
  tbl$dice <- c(0.8, 0.6, 0.5, 0.4, 0.3)
  tbl
}


# ============================================================
# Validacoes de entrada
# ============================================================

test_that("ac_plot_cooccurrence() rejeita weight ausente do tibble", {
  skip_if_not_installed("ggraph")
  skip_if_not_installed("igraph")

  cooc <- make_cooc_tbl()   # sem coluna 'pmi'
  expect_error(
    ac_plot_cooccurrence(cooc, weight = "pmi"),
    regexp = "pmi"
  )
})

test_that("ac_plot_cooccurrence() rejeita weight ausente (dice)", {
  skip_if_not_installed("ggraph")
  skip_if_not_installed("igraph")

  cooc <- make_cooc_tbl()   # sem coluna 'dice'
  expect_error(
    ac_plot_cooccurrence(cooc, weight = "dice"),
    regexp = "dice"
  )
})


# ============================================================
# Output correto
# ============================================================

test_that("ac_plot_cooccurrence() retorna objeto ggplot com weight = 'cooc'", {
  skip_if_not_installed("ggraph")
  skip_if_not_installed("igraph")
  skip_if_not_installed("ggplot2")

  cooc <- make_cooc_tbl()
  p    <- ac_plot_cooccurrence(cooc, weight = "cooc")
  expect_s3_class(p, "ggplot")
})

test_that("ac_plot_cooccurrence() retorna ggplot com weight = 'pmi'", {
  skip_if_not_installed("ggraph")
  skip_if_not_installed("igraph")
  skip_if_not_installed("ggplot2")

  cooc <- make_cooc_tbl_pmi()
  p    <- ac_plot_cooccurrence(cooc, weight = "pmi")
  expect_s3_class(p, "ggplot")
})

test_that("ac_plot_cooccurrence() retorna ggplot com weight = 'dice'", {
  skip_if_not_installed("ggraph")
  skip_if_not_installed("igraph")
  skip_if_not_installed("ggplot2")

  cooc <- make_cooc_tbl_pmi()
  p    <- ac_plot_cooccurrence(cooc, weight = "dice")
  expect_s3_class(p, "ggplot")
})

test_that("ac_plot_cooccurrence() aceita top_n personalizado", {
  skip_if_not_installed("ggraph")
  skip_if_not_installed("igraph")
  skip_if_not_installed("ggplot2")

  cooc <- make_cooc_tbl()
  p    <- ac_plot_cooccurrence(cooc, top_n = 3L)
  expect_s3_class(p, "ggplot")
})

test_that("ac_plot_cooccurrence() aceita title", {
  skip_if_not_installed("ggraph")
  skip_if_not_installed("igraph")
  skip_if_not_installed("ggplot2")

  cooc <- make_cooc_tbl()
  p    <- ac_plot_cooccurrence(cooc, title = "Rede de co-ocorrencia")
  expect_s3_class(p, "ggplot")
  expect_equal(p$labels$title, "Rede de co-ocorrencia")
})

test_that("ac_plot_cooccurrence() aceita node_color e edge_color customizados", {
  skip_if_not_installed("ggraph")
  skip_if_not_installed("igraph")
  skip_if_not_installed("ggplot2")

  cooc <- make_cooc_tbl()
  p    <- ac_plot_cooccurrence(cooc, node_color = "#FF0000", edge_color = "#0000FF")
  expect_s3_class(p, "ggplot")
})

test_that("ac_plot_cooccurrence() aceita layout diferente do padrao", {
  skip_if_not_installed("ggraph")
  skip_if_not_installed("igraph")
  skip_if_not_installed("ggplot2")

  cooc <- make_cooc_tbl()
  p    <- ac_plot_cooccurrence(cooc, layout = "kk")
  expect_s3_class(p, "ggplot")
})

test_that("ac_plot_cooccurrence() funciona com corpus tokenizado de ponta a ponta", {
  skip_if_not_installed("ggraph")
  skip_if_not_installed("igraph")
  skip_if_not_installed("ggplot2")

  df <- data.frame(
    id    = c("d1", "d2", "d3"),
    texto = c(
      "democracia participacao cidadania",
      "participacao politica democracia",
      "cidadania direitos participacao"
    ),
    stringsAsFactors = FALSE
  )
  corp <- ac_corpus(df, text = texto, docid = id) |> ac_clean()
  cooc <- ac_cooccurrence(ac_tokenize(corp), min_count = 1L)
  p    <- ac_plot_cooccurrence(cooc)
  expect_s3_class(p, "ggplot")
})
