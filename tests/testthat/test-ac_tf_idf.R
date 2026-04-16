test_that("ac_tf_idf falha se faltam token ou n", {
  df <- data.frame(a = 1:3, b = 4:6)
  expect_error(ac_tf_idf(df), class = "rlang_error")
})

test_that("ac_tf_idf usa doc_id como documento por padrao", {
  corp <- make_corpus_count(
    texts = c("A A B", "B C"),
    ids   = c("d1", "d2")
  )
  
  freq <- ac_count(corp)
  
  tfidf <- ac_tf_idf(freq)
  
  expect_true(all(c("tf", "idf", "tf_idf") %in% names(tfidf)))
  expect_true(all(tfidf$tf >= 0))
  expect_true(all(tfidf$tf <= 1))
})

test_that("ac_tf_idf aceita agrupamento por metadados", {
  corp <- make_corpus_count(
    texts = c("A A B", "B B C", "C C A"),
    ids   = c("d1", "d2", "d3")
  )
  corp$grupo <- c("g1", "g1", "g2")
  
  freq_by <- ac_count(corp, by = "grupo")
  
  tfidf_by <- ac_tf_idf(freq_by, by = "grupo")
  
  expect_true(all(c("grupo", "token", "n", "tf", "idf", "tf_idf") %in% names(tfidf_by)))
  expect_true(any(tfidf_by$tf_idf > 0))
})

test_that("ac_tf_idf valida colunas inexistentes em by", {
  corp <- make_corpus_count("A B C")
  freq <- ac_count(corp)
  
  expect_error(
    ac_tf_idf(freq, by = "partido_inexistente"),
    class = "rlang_error"
  )
})
