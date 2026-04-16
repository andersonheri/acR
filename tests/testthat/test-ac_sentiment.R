# Testes para ac_sentiment() e ac_plot_sentiment()
# Nota: ac_sentiment() requer download do OpLexicon na primeira execução.
# Testes de integração usam skip_if_offline().

make_corpus_sent <- function() {
  df <- data.frame(
    id = c("pos", "neg", "neu"),
    texto = c(
      "excelente otimo bom positivo alegre feliz",
      "pessimo terrivel ruim negativo triste",
      "aprovada proposta reuniao assembleia texto"
    )
  )
  ac_corpus(df, text = texto, docid = id)
}

# ============================================================
# Validações básicas (offline)
# ============================================================

test_that("ac_sentiment() exige ac_corpus", {
  expect_error(ac_sentiment("texto"), regexp = "ac_corpus")
  expect_error(ac_sentiment(data.frame(x = 1)), regexp = "ac_corpus")
})

test_that("ac_sentiment() aceita method valido", {
  skip_if_offline()
  corpus <- make_corpus_sent()
  r1 <- ac_sentiment(corpus, method = "sum")
  r2 <- ac_sentiment(corpus, method = "mean")
  r3 <- ac_sentiment(corpus, method = "ratio")
  expect_s3_class(r1, "tbl_df")
  expect_s3_class(r2, "tbl_df")
  expect_s3_class(r3, "tbl_df")
})

test_that("ac_sentiment() retorna colunas esperadas", {
  skip_if_offline()
  corpus <- make_corpus_sent()
  result <- ac_sentiment(corpus)
  expected_cols <- c("doc_id", "n_pos", "n_neg", "n_neu", "score", "sentiment")
  expect_true(all(expected_cols %in% names(result)))
})

test_that("ac_sentiment() classifica sentimento corretamente", {
  skip_if_offline()
  corpus <- make_corpus_sent()
  result <- ac_sentiment(corpus)
  # Documento "pos" deve ter score > 0
  expect_true(result$score[result$doc_id == "pos"] > 0)
  # Documento "neg" deve ter score < 0
  expect_true(result$score[result$doc_id == "neg"] < 0)
})

test_that("ac_sentiment() retorna um resultado por documento", {
  skip_if_offline()
  corpus <- make_corpus_sent()
  result <- ac_sentiment(corpus)
  expect_equal(nrow(result), nrow(corpus))
})

# ============================================================
# ac_plot_sentiment()
# ============================================================

test_that("ac_plot_sentiment() retorna ggplot para type='bar'", {
  skip_if_offline()
  corpus <- make_corpus_sent()
  sent <- ac_sentiment(corpus)
  p <- ac_plot_sentiment(sent, type = "bar")
  expect_s3_class(p, "ggplot")
})

test_that("ac_plot_sentiment() retorna ggplot para type='density'", {
  skip_if_offline()
  corpus <- make_corpus_sent()
  sent <- ac_sentiment(corpus)
  p <- ac_plot_sentiment(sent, type = "density")
  expect_s3_class(p, "ggplot")
})
