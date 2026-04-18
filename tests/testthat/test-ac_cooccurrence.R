# Testes para ac_cooccurrence() e funcoes auxiliares internas
# Puro R, sem rede, sem LLM.

# ============================================================
# Fixture
# ============================================================

make_cooc_corpus <- function() {
  df <- data.frame(
    id    = c("d1", "d2", "d3"),
    texto = c(
      "democracia participacao cidadania direitos",
      "participacao politica democracia voto",
      "cidadania direitos participacao igualdade"
    ),
    stringsAsFactors = FALSE
  )
  ac_corpus(df, text = texto, docid = id) |> ac_clean()
}

make_tokens_tbl <- function() {
  tibble::tibble(
    doc_id   = c("d1","d1","d1","d2","d2","d2"),
    token    = c("democracia","participacao","cidadania",
                 "participacao","democracia","voto"),
    token_id = 1:6
  )
}


# ============================================================
# Validacoes de entrada
# ============================================================

test_that("ac_cooccurrence() rejeita input invalido", {
  expect_error(
    ac_cooccurrence(data.frame(x = 1)),
    regexp = "ac_corpus"
  )
})

test_that("ac_cooccurrence() aceita tibble tokenizado como input", {
  toks <- make_tokens_tbl()
  result <- ac_cooccurrence(toks, min_count = 1L)
  expect_s3_class(result, "tbl_df")
})


# ============================================================
# Estrutura do output
# ============================================================

test_that("ac_cooccurrence() retorna tibble com colunas word1, word2, cooc", {
  corp   <- make_cooc_corpus()
  result <- ac_cooccurrence(corp, min_count = 1L)
  expect_s3_class(result, "tbl_df")
  expect_true(all(c("word1", "word2", "cooc") %in% names(result)))
})

test_that("ac_cooccurrence() pares sao ordenados alfabeticamente (word1 <= word2)", {
  corp   <- make_cooc_corpus()
  result <- ac_cooccurrence(corp, min_count = 1L)
  if (nrow(result) > 0L) {
    expect_true(all(result$word1 <= result$word2))
  }
})

test_that("ac_cooccurrence() com measure = 'pmi' inclui coluna pmi", {
  corp   <- make_cooc_corpus()
  result <- ac_cooccurrence(corp, measure = c("count","pmi"), min_count = 1L)
  expect_true("pmi" %in% names(result))
})

test_that("ac_cooccurrence() com measure = 'dice' inclui coluna dice", {
  corp   <- make_cooc_corpus()
  result <- ac_cooccurrence(corp, measure = c("count","dice"), min_count = 1L)
  expect_true("dice" %in% names(result))
  # Dice esta entre 0 e 1
  expect_true(all(result$dice >= 0 & result$dice <= 1))
})

test_that("ac_cooccurrence() sem measure pmi nao inclui coluna pmi", {
  corp   <- make_cooc_corpus()
  result <- ac_cooccurrence(corp, measure = "count", min_count = 1L)
  expect_false("pmi" %in% names(result))
})

test_that("ac_cooccurrence() min_count filtra pares raros", {
  corp <- make_cooc_corpus()
  r1   <- ac_cooccurrence(corp, min_count = 1L)
  r3   <- ac_cooccurrence(corp, min_count = 3L)
  expect_true(nrow(r3) <= nrow(r1))
})

test_that("ac_cooccurrence() resultado ordenado por cooc decrescente", {
  corp   <- make_cooc_corpus()
  result <- ac_cooccurrence(corp, min_count = 1L)
  if (nrow(result) > 1L) {
    expect_true(all(diff(result$cooc) <= 0L))
  }
})


# ============================================================
# unit = "document"
# ============================================================

test_that("ac_cooccurrence() unit = 'document' funciona", {
  corp   <- make_cooc_corpus()
  result <- ac_cooccurrence(corp, unit = "document", min_count = 1L)
  expect_s3_class(result, "tbl_df")
  expect_true("cooc" %in% names(result))
})


# ============================================================
# Casos de borda
# ============================================================

test_that("ac_cooccurrence() corpus vazio retorna tibble vazio", {
  df   <- data.frame(id = character(0), texto = character(0))
  # Criar com tibble direto, pois ac_corpus pode rejeitar vazio
  toks <- tibble::tibble(doc_id = character(0), token = character(0),
                          token_id = integer(0))
  result <- ac_cooccurrence(toks, min_count = 1L)
  expect_equal(nrow(result), 0L)
})

test_that("ac_cooccurrence() min_count alto demais retorna tibble vazio", {
  corp   <- make_cooc_corpus()
  result <- ac_cooccurrence(corp, min_count = 9999L)
  expect_equal(nrow(result), 0L)
})


# ============================================================
# Auxiliares internos
# ============================================================

test_that(".cooc_window() retorna pares para tokens simples", {
  toks <- tibble::tibble(
    doc_id   = c("d1","d1","d1"),
    token    = c("a","b","c"),
    token_id = 1:3
  )
  result <- acR:::.cooc_window(toks, window = 2L)
  expect_s3_class(result, "tbl_df")
  expect_true(nrow(result) > 0L)
  # Pares sempre ordenados
  if (nrow(result) > 0L) {
    expect_true(all(result$word1 <= result$word2))
  }
})

test_that(".cooc_window() doc com 1 token nao gera pares", {
  toks <- tibble::tibble(
    doc_id   = "d1",
    token    = "a",
    token_id = 1L
  )
  result <- acR:::.cooc_window(toks, window = 2L)
  expect_equal(nrow(result), 0L)
})

test_that(".cooc_document() retorna todos os pares combinatorios por documento", {
  toks <- tibble::tibble(
    doc_id   = c("d1","d1","d1"),
    token    = c("a","b","c"),
    token_id = 1:3
  )
  result <- acR:::.cooc_document(toks)
  # C(3,2) = 3 pares
  expect_equal(nrow(result), 3L)
})

test_that(".empty_cooc_tibble() retorna tibble com 0 linhas e colunas corretas", {
  r_count <- acR:::.empty_cooc_tibble("count")
  expect_equal(nrow(r_count), 0L)
  expect_true(all(c("word1","word2","cooc") %in% names(r_count)))

  r_pmi <- acR:::.empty_cooc_tibble(c("count","pmi"))
  expect_true("pmi" %in% names(r_pmi))

  r_dice <- acR:::.empty_cooc_tibble(c("count","dice"))
  expect_true("dice" %in% names(r_dice))
})
