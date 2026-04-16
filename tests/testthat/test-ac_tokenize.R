# tests/testthat/test-ac_tokenize.R
# ============================================================================
# Testes unitários para ac_tokenize()
# Cobre: tipo de saída, preservação de doc_id, comportamento com textos
# vazios, keep_empty, e validações básicas de entrada.
# ============================================================================

# Helper: cria ac_corpus rapidamente
make_corpus_token <- function(texts, ids = NULL) {
  if (is.null(ids)) ids <- paste0("d", seq_along(texts))
  ac_corpus(
    data.frame(id = ids, texto = texts, stringsAsFactors = FALSE),
    text  = texto,
    docid = id
  )
}

# =============================================================================
# 1. Tipo de saída e estrutura básica
# =============================================================================

test_that("ac_tokenize retorna tibble com colunas esperadas", {
  corp   <- make_corpus_token(c("Texto um.", "Texto dois."))
  tokens <- ac_tokenize(corp)
  
  expect_s3_class(tokens, "tbl_df")
  expect_true(all(c("doc_id", "token_id", "token") %in% names(tokens)))
})

test_that("ac_tokenize preserva doc_id e ordem dos documentos", {
  corp <- make_corpus_token(
    texts = c("A B", "C D"),
    ids   = c("d1", "d2")
  )
  tokens <- ac_tokenize(corp)
  
  # primeiros tokens de cada documento devem respeitar a ordem dos ids
  expect_equal(tokens$doc_id[1], "d1")
  expect_equal(tokens$doc_id[which(tokens$token == "C")[1]], "d2")
})

# =============================================================================
# 2. Tokenização simples em palavras
# =============================================================================

test_that("ac_tokenize separa tokens por espaco", {
  corp <- make_corpus_token("O deputado do PT falou na CCJ.")
  tokens <- ac_tokenize(corp)
  
  # Deve haver pelo menos estas palavras como tokens
  expect_true(all(c("O", "deputado", "do", "PT", "falou", "na", "CCJ.") %in% tokens$token))
})

test_that("token_id representa a posicao do token no documento", {
  corp <- make_corpus_token("um dois tres")
  tokens <- ac_tokenize(corp)
  
  expect_equal(tokens$token,   c("um", "dois", "tres"))
  expect_equal(tokens$token_id, c(1L,   2L,     3L))
})

# =============================================================================
# 3. keep_empty e textos vazios
# =============================================================================

test_that("docs vazios nao geram linhas quando keep_empty = FALSE", {
  corp <- suppressWarnings(
    make_corpus_token(c("texto", "", NA))
  )
  
  tokens <- ac_tokenize(corp, keep_empty = FALSE)
  
  expect_true(all(tokens$doc_id == "d1"))
  expect_true(all(tokens$token == "texto"))
})

test_that("docs vazios geram uma linha com NA quando keep_empty = TRUE", {
  corp <- suppressWarnings(
    make_corpus_token(c("", " "))
  )
  
  tokens <- ac_tokenize(corp, keep_empty = TRUE)
  
  expect_equal(nrow(tokens), 2L)
  expect_true(all(is.na(tokens$token)))
  expect_equal(tokens$doc_id, c("d1", "d2"))
})

test_that("todos docs vazios com keep_empty = FALSE retorna tibble vazio", {
  corp <- suppressWarnings(
    make_corpus_token(c("", " ", NA))
  )
  
  tokens <- ac_tokenize(corp, keep_empty = FALSE)
  
  expect_s3_class(tokens, "tbl_df")
  expect_equal(nrow(tokens), 0L)
  expect_equal(names(tokens), c("doc_id", "token_id", "token"))
})


# =============================================================================
# 4. Validacao de entrada
# =============================================================================

test_that("erro se corpus nao e ac_corpus", {
  expect_error(
    ac_tokenize(data.frame(texto = "oi")),
    class = "rlang_error"
  )
})

test_that("keep_empty precisa ser logico escalar", {
  corp <- make_corpus_token("texto")
  expect_error(ac_tokenize(corp, keep_empty = "sim"), class = "rlang_error")
  expect_error(ac_tokenize(corp, keep_empty = c(TRUE, FALSE)), class = "rlang_error")
})

# =============================================================================
# 5. Integração simples com ac_clean
# =============================================================================

test_that("ac_tokenize funciona apos ac_clean", {
  corp <- make_corpus_token(c(
    "Vou pra reuniao http://camara.gov.br",
    "vc precisa votar pra valer!"
  ))
  
  tokens <- corp |>
    ac_clean(remove_url = TRUE) |>
    ac_tokenize()
  
  expect_s3_class(tokens, "tbl_df")
  expect_true(nrow(tokens) > 0L)
  expect_false(any(grepl("http", tokens$token, fixed = TRUE)))
})


# =============================================================================
# 6. drop_punct
# =============================================================================

test_that("drop_punct TRUE remove tokens compostos apenas por pontuacao", {
  corp <- make_corpus_token("Ola, mundo ! ...")
  
  tokens_keep <- ac_tokenize(corp, drop_punct = FALSE)
  tokens_drop <- ac_tokenize(corp, drop_punct = TRUE)
  
  # Comportamento baseline: tokens de pontuacao presentes
  expect_true(any(tokens_keep$token %in% c("!", "...")))
  
  # Com drop_punct = TRUE: tokens apenas de pontuacao removidos
  expect_false(any(tokens_drop$token %in% c("!", "...")))
  
  # Tokens com letras + pontuacao sao mantidos
  expect_true(any(tokens_drop$token %in% c("Ola,", "mundo")))
})

test_that("drop_punct reenumerara token_id dentro de cada documento", {
  corp <- make_corpus_token("A , B , C .")
  
  tokens_drop <- ac_tokenize(corp, drop_punct = TRUE)
  
  expect_equal(tokens_drop$token,   c("A", "B", "C"))
  expect_equal(tokens_drop$token_id, c(1L, 2L, 3L))
})


# =============================================================================
# 7. n-gramas
# =============================================================================

test_that("n = 2 gera bigramas sequenciais por documento", {
  corp <- make_corpus_token("A B C")
  tokens <- ac_tokenize(corp, n = 2L)
  
  expect_equal(tokens$token,    c("A B", "B C"))
  expect_equal(tokens$token_id, c(1L,    2L))
})

test_that("n-gramas preservam doc_id por documento", {
  corp <- make_corpus_token(
    texts = c("A B C", "D E F"),
    ids   = c("d1", "d2")
  )
  
  tokens <- ac_tokenize(corp, n = 2L)
  
  expect_equal(tokens$doc_id, c("d1", "d1", "d2", "d2"))
  expect_equal(tokens$token,  c("A B", "B C", "D E", "E F"))
})

test_that("n maior que numero de tokens devolve tibble vazio", {
  corp <- make_corpus_token("A B")
  
  tokens <- ac_tokenize(corp, n = 3L)
  
  expect_s3_class(tokens, "tbl_df")
  expect_equal(nrow(tokens), 0L)
  expect_equal(names(tokens), c("doc_id", "token_id", "token"))
})

test_that("n-gramas respeitam drop_punct", {
  corp <- make_corpus_token("A , B")
  
  tokens <- ac_tokenize(corp, n = 2L, drop_punct = TRUE)
  
  expect_equal(tokens$token,    "A B")
  expect_equal(tokens$token_id, 1L)
})

test_that("n deve ser inteiro maior ou igual a 1", {
  corp <- make_corpus_token("A B C")
  
  expect_error(ac_tokenize(corp, n = 0),     class = "rlang_error")
  expect_error(ac_tokenize(corp, n = -1),    class = "rlang_error")
  expect_error(ac_tokenize(corp, n = 1.5),   class = "rlang_error")
  expect_error(ac_tokenize(corp, n = c(1,2)), class = "rlang_error")
})


