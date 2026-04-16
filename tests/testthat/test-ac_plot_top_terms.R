test_that("ac_plot_top_terms falha se faltam token ou n", {
  df <- data.frame(a = 1:3, b = 4:6)
  expect_error(ac_plot_top_terms(df), class = "rlang_error")
})

test_that("ac_plot_top_terms retorna um objeto ggplot", {
  corp <- make_corpus_count(
    texts = c("A A B", "B C"),
    ids   = c("d1", "d2")
  )
  
  freq <- ac_count(corp)
  
  p <- ac_plot_top_terms(freq, n = 3)
  
  expect_s3_class(p, "ggplot")
})

test_that("ac_plot_top_terms aceita agrupamento por metadados", {
  corp <- make_corpus_count(
    texts = c("A A B", "B B C", "C C A"),
    ids   = c("d1", "d2", "d3")
  )
  corp$grupo <- c("g1", "g1", "g2")
  
  freq_by <- ac_count(corp, by = "grupo")
  
  p <- ac_plot_top_terms(freq_by, by = "grupo", n = 2)
  
  expect_s3_class(p, "ggplot")
})

test_that("ac_plot_top_terms valida colunas inexistentes em by", {
  corp <- make_corpus_count("A B C")
  freq <- ac_count(corp)
  
  expect_error(
    ac_plot_top_terms(freq, by = "partido_inexistente"),
    class = "rlang_error"
  )
})

test_that("ac_plot_top_terms avisa se style = ipea sem ipeaplot", {
  corp <- make_corpus_count("A A B")
  freq <- ac_count(corp)
  
  if (!requireNamespace("ipeaplot", quietly = TRUE)) {
    expect_error(
      ac_plot_top_terms(freq, style = "ipea"),
      class = "rlang_error"
    )
  } else {
    p <- ac_plot_top_terms(freq, style = "ipea")
    expect_s3_class(p, "ggplot")
  }
})
