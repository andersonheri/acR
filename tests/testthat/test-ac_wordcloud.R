test_that("ac_wordcloud falha se faltam token ou n", {
  df <- data.frame(a = 1:3, b = 4:6)
  expect_error(ac_wordcloud(df), class = "rlang_error")
})

test_that("ac_wordcloud retorna invisivelmente a tabela usada", {
  corp <- make_corpus_count(
    texts = c("A A B", "B C"),
    ids   = c("d1", "d2")
  )
  
  freq <- ac_count(corp)
  
  if (requireNamespace("wordcloud", quietly = TRUE)) {
    res <- pdf(NULL)
    on.exit(dev.off(), add = TRUE)
    
    out <- ac_wordcloud(freq, max_words = 10)
    
    expect_true(is.data.frame(out))
    expect_true(all(c("token", "n") %in% names(out)))
  }
})

test_that("ac_wordcloud respeita min_n", {
  corp <- make_corpus_count(
    texts = c("A A B", "B C"),
    ids   = c("d1", "d2")
  )
  
  freq <- ac_count(corp)
  
  if (requireNamespace("wordcloud", quietly = TRUE)) {
    pdf(NULL)
    on.exit(dev.off(), add = TRUE)
    
    out <- ac_wordcloud(freq, min_n = 2)
    
    expect_true(all(out$n >= 2))
  }
})

test_that("ac_wordcloud valida max_words", {
  corp <- make_corpus_count("A A B")
  freq <- ac_count(corp)
  
  expect_error(
    ac_wordcloud(freq, max_words = 0),
    class = "rlang_error"
  )
})

test_that("ac_wordcloud valida scale", {
  corp <- make_corpus_count("A A B")
  freq <- ac_count(corp)
  
  expect_error(
    ac_wordcloud(freq, scale = 1),
    class = "rlang_error"
  )
})
