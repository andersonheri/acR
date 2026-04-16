# tests/testthat/test-ac_count.R
# ============================================================================
# Testes unitarios para ac_count()
# ============================================================================

# Helper: reutiliza o helper de ac_tokenize, se estiver no mesmo arquivo
make_corpus_count <- function(texts, ids = NULL) {
  if (is.null(ids)) ids <- paste0("d", seq_along(texts))
  ac_corpus(
    data.frame(id = ids, texto = texts, stringsAsFactors = FALSE),
    text  = texto,
    docid = id
  )
}

# =============================================================================
# 1. Unigramas (n = 1)
# =============================================================================

test_that("ac_count retorna frequencias de palavras por documento", {
  corp <- make_corpus_count(
    texts = c("A B A", "B C"),
    ids   = c("d1", "d2")
  )
  
  freq <- ac_count(corp, n = 1L, drop_punct = FALSE, sort = FALSE)
  
  expect_s3_class(freq, "tbl_df")
  expect_true(all(c("doc_id", "token", "n") %in% names(freq)))
  
  # Filtrar manualmente para inspecionar alguns casos
  f_d1_A <- freq[freq$doc_id == "d1" & freq$token == "A", "n", drop = TRUE]
  f_d1_B <- freq[freq$doc_id == "d1" & freq$token == "B", "n", drop = TRUE]
  f_d2_B <- freq[freq$doc_id == "d2" & freq$token == "B", "n", drop = TRUE]
  
  expect_equal(f_d1_A, 2L)
  expect_equal(f_d1_B, 1L)
  expect_equal(f_d2_B, 1L)
})

# =============================================================================
# 2. Bigramas (n = 2)
# =============================================================================

test_that("ac_count calcula frequencias de bigramas", {
  corp <- make_corpus_count("A B C A B")
  
  freq <- ac_count(corp, n = 2L, drop_punct = FALSE, sort = TRUE)
  
  # Bigramas esperados: "A B", "B C", "C A", "A B"
  # Frequencias: "A B" = 2, demais = 1
  f_AB <- freq[freq$token == "A B", "n", drop = TRUE]
  f_BC <- freq[freq$token == "B C", "n", drop = TRUE]
  
  expect_equal(f_AB, 2L)
  expect_equal(f_BC, 1L)
})

# =============================================================================
# 3. drop_punct interage com contagem
# =============================================================================

test_that("ac_count respeita drop_punct", {
  corp <- make_corpus_count("A , B . B")
  
  freq_sem <- ac_count(corp, n = 1L, drop_punct = FALSE, sort = FALSE)
  freq_com <- ac_count(corp, n = 1L, drop_punct = TRUE,  sort = FALSE)
  
  # Na versao sem filtragem, tokens apenas de pontuacao aparecem
  expect_true(any(freq_sem$token %in% c(",", ".")))
  
  # Na versao com drop_punct = TRUE, nao devem aparecer
  expect_false(any(freq_com$token %in% c(",", ".")))
  
  # Frequencia de B deve ser a mesma
  n_B_sem <- freq_sem[freq_sem$token == "B", "n", drop = TRUE]
  n_B_com <- freq_com[freq_com$token == "B", "n", drop = TRUE]
  expect_equal(n_B_sem, n_B_com)
})

# =============================================================================
# 4. Qualidade de entrada
# =============================================================================

test_that("ac_count falha se entrada nao for ac_corpus", {
  df <- data.frame(texto = "A B C")
  expect_error(ac_count(df), class = "rlang_error")
})

# =============================================================================
# 5. Corpus sem tokens ou so com vazios
# =============================================================================

test_that("ac_count com corpus sem tokens retorna tibble vazio", {
  corp <- suppressWarnings(
    make_corpus_count(c("", " "))
  )
  
  freq <- ac_count(corp, n = 1L, drop_punct = TRUE)
  
  expect_s3_class(freq, "tbl_df")
  expect_equal(nrow(freq), 0L)
  expect_equal(names(freq), c("doc_id", "token", "n"))
})


# =============================================================================
# 6. Agrupacao por metadados (by)
# =============================================================================

test_that("ac_count agrupa por uma coluna de metadados", {
  corp <- make_corpus_count(
    texts = c("A B A", "B C", "A C"),
    ids   = c("d1", "d2", "d3")
  )
  
  # adicionar metadado simples: grupo
  corp$grupo <- c("g1", "g2", "g1")
  
  freq_by <- ac_count(corp, by = "grupo", sort = FALSE)
  
  # Em g1 temos documentos d1 ("A B A") e d3 ("A C")
  # Tokens esperados: A (3x), B (1x), C (1x)
  f_g1_A <- freq_by[freq_by$grupo == "g1" & freq_by$token == "A", "n", drop = TRUE]
  f_g1_B <- freq_by[freq_by$grupo == "g1" & freq_by$token == "B", "n", drop = TRUE]
  f_g1_C <- freq_by[freq_by$grupo == "g1" & freq_by$token == "C", "n", drop = TRUE]
  
  expect_equal(f_g1_A, 3L)
  expect_equal(f_g1_B, 1L)
  expect_equal(f_g1_C, 1L)
  
  # Em g2 temos apenas d2 ("B C")
  f_g2_B <- freq_by[freq_by$grupo == "g2" & freq_by$token == "B", "n", drop = TRUE]
  f_g2_C <- freq_by[freq_by$grupo == "g2" & freq_by$token == "C", "n", drop = TRUE]
  
  expect_equal(f_g2_B, 1L)
  expect_equal(f_g2_C, 1L)
})

test_that("ac_count agrupa por multiplas colunas de metadados", {
  corp <- make_corpus_count(
    texts = c("A B", "A B", "B C"),
    ids   = c("d1", "d2", "d3")
  )
  
  corp$grupo <- c("g1", "g1", "g2")
  corp$ano   <- c(2020, 2021, 2020)
  
  freq_by2 <- ac_count(corp, by = c("grupo", "ano"), sort = FALSE)
  
  # grupo g1, ano 2020: apenas d1 ("A B")
  f_g1_2020_A <- freq_by2[
    freq_by2$grupo == "g1" & freq_by2$ano == 2020 & freq_by2$token == "A",
    "n", drop = TRUE
  ]
  expect_equal(f_g1_2020_A, 1L)
  
  # grupo g1, ano 2021: apenas d2 ("A B")
  f_g1_2021_B <- freq_by2[
    freq_by2$grupo == "g1" & freq_by2$ano == 2021 & freq_by2$token == "B",
    "n", drop = TRUE
  ]
  expect_equal(f_g1_2021_B, 1L)
})

test_that("ac_count valida colunas inexistentes em by", {
  corp <- make_corpus_count("A B C")
  expect_error(
    ac_count(corp, by = "partido_que_nao_existe"),
    class = "rlang_error"
  )
})

test_that("ac_count rejeita uso de text em by", {
  corp <- make_corpus_count("A B C")
  expect_error(
    ac_count(corp, by = "text"),
    class = "rlang_error"
  )
})


