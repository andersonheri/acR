test_that("ac_plot_keyness falha se faltam colunas obrigatorias", {
  df <- data.frame(a = 1:3, b = 4:6)
  expect_error(ac_plot_keyness(df), class = "rlang_error")
})

test_that("ac_plot_keyness retorna um objeto ggplot", {
  corp <- make_corpus_count(
    texts = c("A A A B", "A B", "A B B B", "B B C"),
    ids   = c("d1", "d2", "d3", "d4")
  )
  corp$lado <- c("Governo", "Governo", "Oposicao", "Oposicao")
  
  freq <- ac_count(corp, by = "lado")
  key <- ac_keyness(freq, group = "lado", target = "Governo")
  
  p <- ac_plot_keyness(key, n = 2)
  
  expect_s3_class(p, "ggplot")
})

test_that("ac_plot_keyness aceita show_reference = FALSE", {
  corp <- make_corpus_count(
    texts = c("A A A B", "A B", "A B B B", "B B C"),
    ids   = c("d1", "d2", "d3", "d4")
  )
  corp$lado <- c("Governo", "Governo", "Oposicao", "Oposicao")
  
  freq <- ac_count(corp, by = "lado")
  key <- ac_keyness(freq, group = "lado", target = "Governo")
  
  p <- ac_plot_keyness(key, n = 2, show_reference = FALSE)
  
  expect_s3_class(p, "ggplot")
})

test_that("ac_plot_keyness avisa se style = ipea sem ipeaplot", {
  corp <- make_corpus_count(
    texts = c("A A A B", "A B", "A B B B", "B B C"),
    ids   = c("d1", "d2", "d3", "d4")
  )
  corp$lado <- c("Governo", "Governo", "Oposicao", "Oposicao")
  
  freq <- ac_count(corp, by = "lado")
  key <- ac_keyness(freq, group = "lado", target = "Governo")
  
  if (!requireNamespace("ipeaplot", quietly = TRUE)) {
    expect_error(
      ac_plot_keyness(key, style = "ipea"),
      class = "rlang_error"
    )
  } else {
    p <- ac_plot_keyness(key, style = "ipea")
    expect_s3_class(p, "ggplot")
  }
})
