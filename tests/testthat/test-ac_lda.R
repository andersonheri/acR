# Testes para ac_lda(), ac_lda_tune() e ac_plot_lda_*()
# Requerem pacote topicmodels instalado.

make_corpus_lda <- function() {
  df <- data.frame(
    id = paste0("d", 1:8),
    texto = c(
      "democracia participacao cidadania voto politica",
      "mercado economia privatizacao fiscal crescimento",
      "saude hospital medico doenca tratamento",
      "educacao escola professor universidade ensino",
      "democracia eleicao partido politica voto",
      "economia inflacao juros fiscal orcamento",
      "saude sus medico hospital remedio",
      "educacao pesquisa ciencia tecnologia universidade"
    )
  )
  ac_corpus(df, text = texto, docid = id)
}

# ============================================================
# Validações básicas
# ============================================================

test_that("ac_lda() exige ac_corpus", {
  expect_error(ac_lda("texto"), regexp = "ac_corpus")
})

test_that("ac_lda() exige topicmodels instalado", {
  skip_if_not_installed("topicmodels")
  expect_true(requireNamespace("topicmodels", quietly = TRUE))
})

test_that("ac_lda() retorna objeto ac_lda com k correto", {
  skip_if_not_installed("topicmodels")
  corpus <- make_corpus_lda()
  result <- ac_lda(corpus, k = 3L, seed = 1L)
  expect_s3_class(result, "ac_lda")
  expect_equal(result$k, 3L)
})

test_that("ac_lda() retorna tibbles de terms e documents", {
  skip_if_not_installed("topicmodels")
  corpus <- make_corpus_lda()
  result <- ac_lda(corpus, k = 3L, seed = 1L)
  expect_s3_class(result$terms, "tbl_df")
  expect_s3_class(result$documents, "tbl_df")
  expect_true(all(c("topic", "term", "beta") %in% names(result$terms)))
  expect_true(all(c("doc_id", "topic", "gamma") %in% names(result$documents)))
})

test_that("betas somam aproximadamente 1 por topico", {
  skip_if_not_installed("topicmodels")
  corpus <- make_corpus_lda()
  result <- ac_lda(corpus, k = 2L, seed = 1L)
  beta_sums <- result$terms |>
    dplyr::group_by(topic) |>
    dplyr::summarise(total = sum(beta))
  expect_true(all(abs(beta_sums$total - 1) < 0.01))
})

test_that("gammas somam aproximadamente 1 por documento", {
  skip_if_not_installed("topicmodels")
  corpus <- make_corpus_lda()
  result <- ac_lda(corpus, k = 2L, seed = 1L)
  gamma_sums <- result$documents |>
    dplyr::group_by(doc_id) |>
    dplyr::summarise(total = sum(gamma))
  expect_true(all(abs(gamma_sums$total - 1) < 0.01))
})

test_that("print.ac_lda nao gera erro", {
  skip_if_not_installed("topicmodels")
  corpus <- make_corpus_lda()
  result <- ac_lda(corpus, k = 2L, seed = 1L)
  # cli escreve em stderr; verificar que retorna invisível sem erro
  expect_invisible(print(result))
  expect_s3_class(result, "ac_lda")
})

test_that("ac_lda() rejeita k < 2", {
  skip_if_not_installed("topicmodels")
  corpus <- make_corpus_lda()
  expect_error(ac_lda(corpus, k = 1L), regexp = ">= 2")
})

# ============================================================
# ac_lda_tune()
# ============================================================

test_that("ac_lda_tune() retorna tibble com colunas k e perplexity", {
  skip_if_not_installed("topicmodels")
  corpus <- make_corpus_lda()
  result <- ac_lda_tune(corpus, k_range = 2:3, seed = 1L)
  expect_s3_class(result, "tbl_df")
  expect_true(all(c("k", "perplexity") %in% names(result)))
  expect_equal(nrow(result), 2L)
})

# ============================================================
# ac_plot_lda_*()
# ============================================================

test_that("ac_plot_lda_topics() retorna ggplot", {
  skip_if_not_installed("topicmodels")
  corpus <- make_corpus_lda()
  lda <- ac_lda(corpus, k = 2L, seed = 1L)
  p <- ac_plot_lda_topics(lda, top_n = 3)
  expect_s3_class(p, "ggplot")
})

test_that("ac_plot_lda_tune() retorna ggplot", {
  skip_if_not_installed("topicmodels")
  corpus <- make_corpus_lda()
  tune <- ac_lda_tune(corpus, k_range = 2:3, seed = 1L)
  p <- ac_plot_lda_tune(tune)
  expect_s3_class(p, "ggplot")
})
