test_that("ac_plot_tf_idf falha se faltam token ou tf_idf", {
  df <- data.frame(a = 1:3, b = 4:6)
  expect_error(ac_plot_tf_idf(df), class = "rlang_error")
})

test_that("ac_plot_tf_idf retorna um objeto ggplot", {
  corp <- make_corpus_count(
    texts = c("A A B", "B C"),
    ids   = c("d1", "d2")
  )
  
  freq <- ac_count(corp)
  tfidf <- ac_tf_idf(freq)
  
  p <- ac_plot_tf_idf(tfidf, n = 3)
  
  expect_s3_class(p, "ggplot")
})

test_that("ac_plot_tf_idf aceita agrupamento por metadados", {
  corp <- make_corpus_count(
    texts = c("A A B", "B B C", "C C A"),
    ids   = c("d1", "d2", "d3")
  )
  corp$grupo <- c("g1", "g1", "g2")
  
  freq_by <- ac_count(corp, by = "grupo")
  tfidf_by <- ac_tf_idf(freq_by, by = "grupo")
  
  p <- ac_plot_tf_idf(tfidf_by, by = "grupo", n = 2)
  
  expect_s3_class(p, "ggplot")
})

test_that("ac_plot_tf_idf valida colunas inexistentes em by", {
  corp <- make_corpus_count("A B C")
  freq <- ac_count(corp)
  tfidf <- ac_tf_idf(freq)
  
  expect_error(
    ac_plot_tf_idf(tfidf, by = "partido_inexistente"),
    class = "rlang_error"
  )
})

test_that("ac_plot_tf_idf avisa se style = ipea sem ipeaplot", {
  corp <- make_corpus_count("A A B")
  freq <- ac_count(corp)
  tfidf <- ac_tf_idf(freq)
  
  if (!requireNamespace("ipeaplot", quietly = TRUE)) {
    expect_error(
      ac_plot_tf_idf(tfidf, style = "ipea"),
      class = "rlang_error"
    )
  } else {
    p <- ac_plot_tf_idf(tfidf, style = "ipea")
    expect_s3_class(p, "ggplot")
  }
})
