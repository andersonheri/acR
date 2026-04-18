# Testes para ac_plot_wordcloud_comparative() e ac_plot_xray()
# Ambas retornam objetos ggplot — testes verificam estrutura, nao renderizacao.

# ============================================================
# Fixtures
# ============================================================

make_wc_corpus <- function() {
  df <- data.frame(
    id    = paste0("d", 1:6),
    texto = c(
      "democracia participacao popular voto",
      "direitos cidadania liberdade democracia",
      "participacao popular igualdade direitos",
      "mercado economia privatizacao eficiencia",
      "privatizacao mercado livre eficiencia",
      "economia crescimento mercado investimento"
    ),
    grupo = c("A","A","A","B","B","B"),
    stringsAsFactors = FALSE
  )
  ac_corpus(df, text = texto, docid = id)
}

make_xray_corpus <- function() {
  df <- data.frame(
    id    = c("d1","d2"),
    texto = c(
      "democracia liberdade igualdade democracia direitos democracia",
      "mercado liberdade privatizacao mercado eficiencia mercado"
    ),
    stringsAsFactors = FALSE
  )
  ac_corpus(df, text = texto, docid = id)
}


# ============================================================
# ac_plot_wordcloud_comparative() — validacoes
# ============================================================

test_that("ac_plot_wordcloud_comparative() rejeita nao ac_corpus", {
  expect_error(
    ac_plot_wordcloud_comparative(data.frame(x = 1), group = "x"),
    regexp = "ac_corpus"
  )
})

test_that("ac_plot_wordcloud_comparative() rejeita coluna de grupo inexistente", {
  corp <- make_wc_corpus()
  expect_error(
    ac_plot_wordcloud_comparative(corp, group = "coluna_inexistente"),
    regexp = "grupo"
  )
})

test_that("ac_plot_wordcloud_comparative() rejeita mais de 2 grupos", {
  df <- data.frame(
    id    = paste0("d", 1:3),
    texto = c("texto a", "texto b", "texto c"),
    grp   = c("A","B","C"),
    stringsAsFactors = FALSE
  )
  corp <- ac_corpus(df, text = texto, docid = id)
  expect_error(
    ac_plot_wordcloud_comparative(corp, group = grp),
    regexp = "2 grupos"
  )
})


# ============================================================
# ac_plot_wordcloud_comparative() — output
# ============================================================

test_that("ac_plot_wordcloud_comparative() retorna objeto ggplot", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("scales")

  corp <- make_wc_corpus()
  p    <- ac_plot_wordcloud_comparative(corp, group = grupo)
  expect_s3_class(p, "ggplot")
})

test_that("ac_plot_wordcloud_comparative() aceita max_words personalizado", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("scales")

  corp <- make_wc_corpus()
  p    <- ac_plot_wordcloud_comparative(corp, group = grupo, max_words = 5L)
  expect_s3_class(p, "ggplot")
})

test_that("ac_plot_wordcloud_comparative() aceita title", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("scales")

  corp <- make_wc_corpus()
  p    <- ac_plot_wordcloud_comparative(corp, group = grupo,
                                        title = "Comparacao A vs B")
  expect_s3_class(p, "ggplot")
  expect_equal(p$labels$title, "Comparacao A vs B")
})

test_that("ac_plot_wordcloud_comparative() aceita cores customizadas", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("scales")

  corp <- make_wc_corpus()
  p    <- ac_plot_wordcloud_comparative(corp, group = grupo,
                                        colors = c("#FF0000","#0000FF"))
  expect_s3_class(p, "ggplot")
})

test_that("ac_plot_wordcloud_comparative() aceita group como string", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("scales")

  corp <- make_wc_corpus()
  p    <- ac_plot_wordcloud_comparative(corp, group = "grupo")
  expect_s3_class(p, "ggplot")
})


# ============================================================
# ac_plot_xray() — validacoes
# ============================================================

test_that("ac_plot_xray() rejeita nao ac_corpus", {
  expect_error(
    ac_plot_xray(data.frame(x = 1), terms = "a"),
    regexp = "ac_corpus"
  )
})

test_that("ac_plot_xray() rejeita terms vazio", {
  corp <- make_xray_corpus()
  expect_error(
    ac_plot_xray(corp, terms = character(0)),
    regexp = "character"
  )
})

test_that("ac_plot_xray() rejeita terms nao character", {
  corp <- make_xray_corpus()
  expect_error(
    ac_plot_xray(corp, terms = 123),
    regexp = "character"
  )
})


# ============================================================
# ac_plot_xray() — output
# ============================================================

test_that("ac_plot_xray() retorna objeto ggplot com termos presentes", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("scales")

  corp <- make_xray_corpus()
  p    <- ac_plot_xray(corp, terms = c("democracia", "mercado"))
  expect_s3_class(p, "ggplot")
})

test_that("ac_plot_xray() retorna ggplot vazio quando termo nao existe", {
  skip_if_not_installed("ggplot2")

  corp <- make_xray_corpus()
  expect_warning(
    p <- ac_plot_xray(corp, terms = "xyzzy_inexistente"),
    regexp = "encontrado"
  )
  expect_s3_class(p, "ggplot")
})

test_that("ac_plot_xray() aceita ignore_case = FALSE", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("scales")

  corp <- make_xray_corpus()
  # Com ignore_case FALSE, "Democracia" nao aparece (texto esta em minusculo)
  p <- ac_plot_xray(corp, terms = c("democracia"), ignore_case = FALSE)
  expect_s3_class(p, "ggplot")
})

test_that("ac_plot_xray() aceita title", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("scales")

  corp <- make_xray_corpus()
  p    <- ac_plot_xray(corp, terms = "democracia", title = "Dispersao lexical")
  expect_equal(p$labels$title, "Dispersao lexical")
})

test_that("ac_plot_xray() aceita vetor de cores", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("scales")

  corp <- make_xray_corpus()
  p    <- ac_plot_xray(corp, terms = c("democracia","mercado"),
                       colors = c("#AA0000","#0000AA"))
  expect_s3_class(p, "ggplot")
})
