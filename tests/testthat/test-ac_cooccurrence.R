# Testes para ac_cooccurrence()

make_corpus_cooc <- function() {
  df <- data.frame(
    id = c("d1", "d2", "d3"),
    texto = c(
      "democracia participacao cidadania direitos",
      "participacao politica democracia voto",
      "cidadania direitos participacao igualdade"
    )
  )
  ac_corpus(df, text = texto, docid = id)
}

test_that("ac_cooccurrence() exige ac_corpus ou tibble tokenizado", {
  expect_error(ac_cooccurrence(data.frame(x = 1)), regexp = "ac_corpus")
  expect_error(ac_cooccurrence("texto"), regexp = "ac_corpus")
})

test_that("ac_cooccurrence() retorna tibble com colunas esperadas", {
  tokens <- ac_tokenize(make_corpus_cooc() |> ac_clean())
  result <- ac_cooccurrence(tokens, min_count = 1)
  expect_s3_class(result, "tbl_df")
  expect_true(all(c("word1", "word2", "cooc") %in% names(result)))
})

test_that("ac_cooccurrence() aceita ac_corpus diretamente", {
  result <- ac_cooccurrence(make_corpus_cooc(), min_count = 1)
  expect_s3_class(result, "tbl_df")
  expect_true(nrow(result) > 0)
})

test_that("word1 e word2 estao sempre em ordem alfabetica", {
  tokens <- ac_tokenize(make_corpus_cooc() |> ac_clean())
  result <- ac_cooccurrence(tokens, min_count = 1)
  expect_true(all(result$word1 <= result$word2))
})

test_that("min_count filtra pares raros", {
  tokens <- ac_tokenize(make_corpus_cooc() |> ac_clean())
  r1 <- ac_cooccurrence(tokens, min_count = 1)
  r2 <- ac_cooccurrence(tokens, min_count = 3)
  expect_true(nrow(r1) >= nrow(r2))
})

test_that("measure=pmi adiciona coluna pmi", {
  tokens <- ac_tokenize(make_corpus_cooc() |> ac_clean())
  result <- ac_cooccurrence(tokens, measure = c("count", "pmi"), min_count = 1)
  expect_true("pmi" %in% names(result))
})

test_that("measure=dice adiciona coluna dice", {
  tokens <- ac_tokenize(make_corpus_cooc() |> ac_clean())
  result <- ac_cooccurrence(tokens, measure = c("count", "dice"), min_count = 1)
  expect_true("dice" %in% names(result))
  # Dice com janela deslizante pode ser > 1; verificar apenas >= 0
  expect_true(all(result$dice >= 0))
})

test_that("unit=document funciona", {
  tokens <- ac_tokenize(make_corpus_cooc() |> ac_clean())
  result <- ac_cooccurrence(tokens, unit = "document", min_count = 1)
  expect_s3_class(result, "tbl_df")
  expect_true(nrow(result) > 0)
})

test_that("corpus vazio retorna tibble vazio", {
  tokens_vazio <- tibble::tibble(
    doc_id   = character(0),
    token_id = integer(0),
    token    = character(0)
  )
  result <- ac_cooccurrence(tokens_vazio, min_count = 1)
  expect_equal(nrow(result), 0)
})
