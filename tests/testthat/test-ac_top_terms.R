make_corpus_count <- function(texts, ids = NULL) {
  if (is.null(ids)) {
    ids <- paste0("d", seq_along(texts))
  }
  
  if (length(ids) != length(texts)) {
    stop("length(ids) deve ser igual a length(texts).", call. = FALSE)
  }
  
  df <- data.frame(
    id    = ids,
    texto = texts,
    stringsAsFactors = FALSE
  )
  
  ac_corpus(df, text = texto, docid = id)
}







test_that("ac_top_terms falha se x nao tem token/n", {
  df <- data.frame(a = 1:3, b = 4:6)
  expect_error(ac_top_terms(df), class = "rlang_error")
})

test_that("ac_top_terms retorna top n global", {
  corp <- make_corpus_count(
    texts = c("A A B", "B C"),
    ids   = c("d1", "d2")
  )
  freq <- ac_count(corp)
  
  top2 <- ac_top_terms(freq, n = 2)
  
  # A deve aparecer (termo com n maximo)
  expect_true("A" %in% top2$token)
  
  # maximo global de frequencia
  max_n <- max(freq$n)
  
  # Pelo menos uma linha em top2 deve ter a frequencia maxima de freq
  expect_true(any(top2$n == max_n))
  
  # Nenhum termo em top2 pode ter frequencia maior que o maximo global
  expect_true(all(top2$n <= max_n))
})


test_that("ac_top_terms retorna top n por grupo", {
  corp <- make_corpus_count(
    texts = c("A A B", "B B C", "C C A"),
    ids   = c("d1", "d2", "d3")
  )
  
  corp$grupo <- c("g1", "g1", "g2")
  
  freq_by <- ac_count(corp, by = "grupo")
  
  top1 <- ac_top_terms(freq_by, n = 1, by = "grupo")
  
  # Deve haver uma linha para g1 e uma para g2
  expect_equal(sort(unique(top1$grupo)), c("g1", "g2"))
  expect_equal(nrow(top1), 2L)
  
  # Em g1, o termo mais frequente deve ter n >= 2
  n_g1 <- top1[top1$grupo == "g1", "n", drop = TRUE]
  expect_true(n_g1 >= 2L)
})

test_that("ac_top_terms valida colunas inexistentes em by", {
  corp <- make_corpus_count("A B C")
  freq <- ac_count(corp)
  expect_error(
    ac_top_terms(freq, by = "partido_inexistente"),
    class = "rlang_error"
  )
})
