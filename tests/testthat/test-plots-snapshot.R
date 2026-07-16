skip_if_not_installed("ggplot2")
skip_if_not_installed("vdiffr")

# Corpus base para varios testes
build_test_corpus <- function() {
  df <- data.frame(
    text = c(
      "governo excelente proposta positiva otima",
      "pessima gestao terrivel desastre corrupta",
      "aprovada emenda comissao sessao votacao",
      "positivo bom aprovar excelente sucesso",
      "negativo pessimo rejeitar terrivel fracasso"
    ),
    grupo = c("A","B","C","A","B"),
    stringsAsFactors = FALSE
  )
  ac_corpus(df)
}

# ---- theme_ac ---------------------------------------------------------------

test_that("theme_ac() retorna objeto theme e nao quebra sem args", {
  th <- theme_ac()
  expect_s3_class(th, "theme")
  expect_s3_class(th, "gg")

  # Base_size customizado
  th2 <- theme_ac(base_size = 14)
  expect_s3_class(th2, "theme")
})

test_that("ac_palette() retorna cores validas", {
  pal <- ac_palette()
  expect_length(pal, 8L)
  expect_true(all(grepl("^#[0-9A-Fa-f]{6}$", pal)))

  # subset
  expect_length(ac_palette(3), 3L)
  expect_length(ac_palette(1), 1L)

  # limites
  expect_error(ac_palette(0),  "entre 1 e 8")
  expect_error(ac_palette(9),  "entre 1 e 8")
})

# ---- Snapshot: plots geram objetos ggplot validos ---------------------------
# Nao usamos vdiffr por padrao (adiciona depend pesada); testamos estrutura.

test_that("ac_plot_top_terms() gera ggplot valido", {
  corpus <- build_test_corpus()
  freq   <- ac_count(corpus)
  top    <- ac_top_terms(freq, n = 5)
  p      <- ac_plot_top_terms(top)

  expect_s3_class(p, "ggplot")
  expect_true("labels" %in% names(p))
})

test_that("ac_plot_keyness() gera ggplot valido", {
  corpus  <- build_test_corpus()
  freq_by <- ac_count(corpus, by = "grupo")
  # Precisa de 2+ grupos
  freq_2 <- freq_by[freq_by$grupo %in% c("A", "B"), ]
  kn <- ac_keyness(freq_2, group = "grupo", target = "A")
  p  <- ac_plot_keyness(kn, n = 3)

  expect_s3_class(p, "ggplot")
})

test_that("ac_plot_tf_idf() gera ggplot valido", {
  corpus <- build_test_corpus()
  freq   <- ac_count(corpus)
  tfidf  <- ac_tf_idf(freq)
  p      <- ac_plot_tf_idf(tfidf, n = 5)

  expect_s3_class(p, "ggplot")
})

test_that("ac_plot_sentiment() gera ggplot valido para type = bar/line/density", {
  corpus <- build_test_corpus()
  sent   <- ac_sentiment(corpus)

  for (t in c("bar", "line", "density")) {
    p <- ac_plot_sentiment(sent, type = t)
    expect_s3_class(p, "ggplot")
  }
})

test_that("ac_plot_xray() gera ggplot valido", {
  corpus <- build_test_corpus()
  p <- ac_plot_xray(corpus, terms = c("governo", "aprovada"))

  expect_s3_class(p, "ggplot")
})

test_that("ac_plot_wordcloud_comparative() gera ggplot valido (2 grupos)", {
  # requer exatamente 2 grupos
  df <- data.frame(
    text = c("governo excelente positivo", "pessimo terrivel negativo",
             "aprovar bom otimo", "rejeitar ruim pessimo"),
    grupo = c("A", "B", "A", "B"),
    stringsAsFactors = FALSE
  )
  corpus <- ac_corpus(df)
  p <- ac_plot_wordcloud_comparative(corpus, group = grupo)

  expect_s3_class(p, "ggplot")
})
