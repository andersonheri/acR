# Testes para ac_cluster_documents() + ac_plot_cluster()

make_cluster_corpus <- function() {
  df <- data.frame(
    id = paste0("d", 1:8),
    texto = c(
      "democracia participacao voto liberdade",
      "cidadania direitos participacao democracia",
      "voto direitos liberdade cidadania",
      "democracia voto participacao popular",
      "mercado economia eficiencia privatizacao",
      "privatizacao mercado livre eficiencia",
      "economia crescimento investimento mercado",
      "eficiencia mercado economia livre"
    ),
    stringsAsFactors = FALSE
  )
  ac_corpus(df, text = texto, docid = id)
}


# ============================================================
# ac_cluster_documents() -- validacoes
# ============================================================

test_that("ac_cluster_documents() rejeita nao ac_corpus", {
  expect_error(
    ac_cluster_documents(data.frame(x = 1)),
    regexp = "ac_corpus"
  )
})

test_that("ac_cluster_documents() emite warning para corpus pequeno", {
  corp <- make_cluster_corpus()
  expect_warning(
    ac_cluster_documents(corp, k = 2, min_docs = 100L),
    regexp = "pequeno"
  )
})


# ============================================================
# ac_cluster_documents() -- output basico
# ============================================================

test_that("ac_cluster_documents() retorna ac_cluster com k = 2", {
  corp <- make_cluster_corpus()
  cl <- suppressWarnings(ac_cluster_documents(corp, k = 2, min_docs = 1L))
  expect_s3_class(cl, "ac_cluster")
  expect_equal(cl$k, 2L)
  expect_equal(nrow(cl$assignments), 8L)
  expect_setequal(unique(cl$assignments$cluster), c(1L, 2L))
})

test_that("ac_cluster_documents() recupera 2 blocos tematicos com hclust", {
  corp <- make_cluster_corpus()
  cl <- suppressWarnings(ac_cluster_documents(corp, k = 2, min_docs = 1L))
  # Docs 1-4 (democracia) devem ficar no mesmo cluster; 5-8 (mercado) noutro
  cl_map <- setNames(cl$assignments$cluster, cl$assignments$doc_id)
  democracia <- unique(cl_map[c("d1","d2","d3","d4")])
  mercado    <- unique(cl_map[c("d5","d6","d7","d8")])
  expect_length(democracia, 1L)
  expect_length(mercado, 1L)
  expect_false(democracia == mercado)
})

test_that("ac_cluster_documents() aceita method = 'kmeans'", {
  corp <- make_cluster_corpus()
  cl <- suppressWarnings(ac_cluster_documents(corp, method = "kmeans",
                                              k = 2, min_docs = 1L))
  expect_s3_class(cl, "ac_cluster")
  expect_equal(cl$method, "kmeans")
})

test_that("ac_cluster_documents() aceita features = 'count'", {
  corp <- make_cluster_corpus()
  cl <- suppressWarnings(ac_cluster_documents(corp, features = "count",
                                              k = 2, min_docs = 1L))
  expect_equal(cl$features, "count")
})

test_that("ac_cluster_documents() aceita distance = 'euclidean'", {
  corp <- make_cluster_corpus()
  cl <- suppressWarnings(ac_cluster_documents(corp, distance = "euclidean",
                                              k = 2, min_docs = 1L))
  expect_equal(cl$distance, "euclidean")
})

test_that("ac_cluster_documents() rejeita k invalido", {
  corp <- make_cluster_corpus()
  expect_error(
    suppressWarnings(ac_cluster_documents(corp, k = 1, min_docs = 1L)),
    regexp = "entre 2"
  )
  expect_error(
    suppressWarnings(ac_cluster_documents(corp, k = 20, min_docs = 1L)),
    regexp = "entre 2"
  )
})


# ============================================================
# ac_plot_cluster()
# ============================================================

test_that("ac_plot_cluster() retorna ggplot para dendrograma", {
  skip_if_not_installed("ggplot2")
  corp <- make_cluster_corpus()
  cl <- suppressWarnings(ac_cluster_documents(corp, k = 2, min_docs = 1L))
  p <- ac_plot_cluster(cl, kind = "dendrogram")
  expect_s3_class(p, "ggplot")
})

test_that("ac_plot_cluster() retorna ggplot para scatter (PCA)", {
  skip_if_not_installed("ggplot2")
  corp <- make_cluster_corpus()
  cl <- suppressWarnings(ac_cluster_documents(corp, method = "kmeans",
                                              k = 2, min_docs = 1L))
  p <- ac_plot_cluster(cl, kind = "scatter")
  expect_s3_class(p, "ggplot")
})

test_that("ac_plot_cluster() retorna ggplot para heatmap", {
  skip_if_not_installed("ggplot2")
  corp <- make_cluster_corpus()
  cl <- suppressWarnings(ac_cluster_documents(corp, k = 2, min_docs = 1L))
  p <- ac_plot_cluster(cl, kind = "heatmap")
  expect_s3_class(p, "ggplot")
})

test_that("ac_plot_cluster() 'auto' escolhe dendrograma para hclust", {
  skip_if_not_installed("ggplot2")
  corp <- make_cluster_corpus()
  cl <- suppressWarnings(ac_cluster_documents(corp, k = 2, min_docs = 1L))
  p_auto <- ac_plot_cluster(cl, kind = "auto")
  p_dend <- ac_plot_cluster(cl, kind = "dendrogram")
  expect_equal(p_auto$labels$title, p_dend$labels$title)
})

test_that("ac_plot_cluster() rejeita input errado", {
  expect_error(ac_plot_cluster(list(x = 1)), regexp = "ac_cluster")
})


# ============================================================
# Cobertura adicional -- pam, k automatico, print, edge cases
# ============================================================

test_that("ac_cluster_documents() aceita method = 'pam' quando cluster disponivel", {
  skip_if_not_installed("cluster")
  corp <- make_cluster_corpus()
  cl <- suppressWarnings(ac_cluster_documents(corp, method = "pam",
                                              k = 2, min_docs = 1L))
  expect_s3_class(cl, "ac_cluster")
  expect_equal(cl$method, "pam")
  expect_setequal(unique(cl$assignments$cluster), c(1L, 2L))
})

test_that("ac_cluster_documents() escolhe k automaticamente por silhueta", {
  skip_if_not_installed("cluster")
  corp <- make_cluster_corpus()
  cl <- suppressWarnings(ac_cluster_documents(corp, k = NULL, min_docs = 1L))
  expect_s3_class(cl, "ac_cluster")
  expect_true(cl$k >= 2L && cl$k <= 7L)  # limite superior = n_docs - 1
  expect_false(is.na(cl$silhouette))
})

test_that("ac_cluster_documents() aborta para corpus com < 2 documentos", {
  df <- data.frame(id = "d1", texto = "unico documento",
                   stringsAsFactors = FALSE)
  corp <- ac_corpus(df, text = texto, docid = id)
  expect_error(
    suppressWarnings(ac_cluster_documents(corp, k = 2, min_docs = 1L)),
    regexp = "clustering exige"
  )
})

test_that("print.ac_cluster() imprime resumo e retorna x invisivelmente", {
  corp <- make_cluster_corpus()
  cl <- suppressWarnings(ac_cluster_documents(corp, k = 2, min_docs = 1L))
  out <- capture.output(res <- print(cl))
  expect_identical(res, cl)
  # cli::cli_* escreve em stderr; a tabela final vai a stdout via cat()
  expect_true(any(grepl("Documentos por cluster", out)))
})

test_that("ac_plot_cluster(kind='dendrogram') sobre kmeans avisa e usa scatter", {
  skip_if_not_installed("ggplot2")
  corp <- make_cluster_corpus()
  cl <- suppressWarnings(ac_cluster_documents(corp, method = "kmeans",
                                              k = 2, min_docs = 1L))
  expect_warning(
    p <- ac_plot_cluster(cl, kind = "dendrogram"),
    regexp = "dendrogram"
  )
  expect_s3_class(p, "ggplot")
})

test_that("ac_plot_cluster(kind='heatmap') funciona para kmeans", {
  skip_if_not_installed("ggplot2")
  corp <- make_cluster_corpus()
  cl <- suppressWarnings(ac_cluster_documents(corp, method = "kmeans",
                                              k = 2, min_docs = 1L))
  p <- ac_plot_cluster(cl, kind = "heatmap")
  expect_s3_class(p, "ggplot")
})
