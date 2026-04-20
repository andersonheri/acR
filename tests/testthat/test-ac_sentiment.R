# Testes para ac_sentiment() e ac_plot_sentiment()
# ac_sentiment depende de .ac_load_lexicon() que faz download ou usa cache.
# Os testes de unidade usam mock do lexicon para evitar rede.

# ============================================================
# Fixture compartilhada
# ============================================================

make_sent_corpus <- function() {
  df <- data.frame(
    id    = c("pos", "neg", "neu"),
    texto = c(
      "excelente otimo bom resultado positivo",
      "pessimo terrivel ruim fracasso negativo",
      "reuniao proposta aprovada assembleia"
    ),
    stringsAsFactors = FALSE
  )
  ac_corpus(df, text = texto, docid = id)
}

# Lexicon minimo para testes (sem rede)
make_mock_lexicon <- function() {
  tibble::tibble(
    termo      = c("excelente", "otimo", "bom", "positivo",
                   "pessimo",   "terrivel", "ruim", "negativo"),
    pos        = c("adj", "adj", "adj", "adj", "adj", "adj", "adj", "adj"),
    polaridade = c(1L,     1L,    1L,   1L,   -1L,    -1L,   -1L,  -1L)
  )
}


# ============================================================
# Validacoes de entrada
# ============================================================

test_that("ac_sentiment() rejeita objeto nao ac_corpus", {
  expect_error(
    ac_sentiment(data.frame(x = 1)),
    regexp = "ac_corpus"
  )
})

test_that("ac_sentiment() aceita method validos", {
  corp <- make_sent_corpus()
  lex  <- make_mock_lexicon()

  # Mock .ac_load_lexicon para nao fazer download
  local_mocked_bindings(
    .ac_load_lexicon = function(...) lex,
    .package = "acR"
  )

  for (m in c("sum", "mean", "ratio")) {
    result <- ac_sentiment(corp, method = m)
    expect_s3_class(result, "tbl_df")
    expect_true("score" %in% names(result))
  }
})


# ============================================================
# Comportamento com lexicon mockado
# ============================================================

test_that("ac_sentiment() retorna tibble com colunas corretas", {
  corp <- make_sent_corpus()
  lex  <- make_mock_lexicon()

  local_mocked_bindings(
    .ac_load_lexicon = function(...) lex,
    .package = "acR"
  )

  result <- ac_sentiment(corp)

  expect_s3_class(result, "tbl_df")
  expected_cols <- c("doc_id", "n_pos", "n_neg", "n_neu", "score", "sentiment")
  expect_true(all(expected_cols %in% names(result)))
  expect_equal(nrow(result), 3L)
})

test_that("ac_sentiment() classifica documentos corretamente com mock lexicon", {
  corp <- make_sent_corpus()
  lex  <- make_mock_lexicon()

  local_mocked_bindings(
    .ac_load_lexicon = function(...) lex,
    .package = "acR"
  )

  result <- ac_sentiment(corp, method = "sum")
  result <- result[order(result$doc_id), ]

  expect_equal(result$sentiment[result$doc_id == "pos"], "positivo")
  expect_equal(result$sentiment[result$doc_id == "neg"], "negativo")
})

test_that("ac_sentiment() method = 'ratio' retorna score entre -1 e 1", {
  corp <- make_sent_corpus()
  lex  <- make_mock_lexicon()

  local_mocked_bindings(
    .ac_load_lexicon = function(...) lex,
    .package = "acR"
  )

  result <- ac_sentiment(corp, method = "ratio")
  scores_nonzero <- result$score[result$doc_id %in% c("pos", "neg")]
  expect_true(all(abs(scores_nonzero) <= 1))
})

test_that("ac_sentiment() method = 'ratio' retorna 0 para doc sem tokens polarizados", {
  corp <- make_sent_corpus()
  lex  <- make_mock_lexicon()

  local_mocked_bindings(
    .ac_load_lexicon = function(...) lex,
    .package = "acR"
  )

  result <- ac_sentiment(corp, method = "ratio")
  expect_equal(result$score[result$doc_id == "neu"], 0)
})

test_that("ac_sentiment() agrupamento por coluna 'by' funciona", {
  df <- data.frame(
    id     = c("d1", "d2", "d3", "d4"),
    texto  = c("excelente bom", "pessimo ruim", "otimo positivo", "terrivel negativo"),
    grupo  = c("A", "B", "A", "B"),
    stringsAsFactors = FALSE
  )
  corp <- ac_corpus(df, text = texto, docid = id)
  lex  <- make_mock_lexicon()

  local_mocked_bindings(
    .ac_load_lexicon = function(...) lex,
    .package = "acR"
  )

  result <- ac_sentiment(corp, by = "grupo")
  expect_true("grupo" %in% names(result))
  expect_equal(nrow(result), 4L)  # ainda por doc_id + grupo
})

test_that("ac_sentiment() n_pos e n_neg sao inteiros nao negativos", {
  corp <- make_sent_corpus()
  lex  <- make_mock_lexicon()

  local_mocked_bindings(
    .ac_load_lexicon = function(...) lex,
    .package = "acR"
  )

  result <- ac_sentiment(corp)
  expect_true(all(result$n_pos >= 0L))
  expect_true(all(result$n_neg >= 0L))
  expect_true(all(result$n_neu >= 0L))
})


# ============================================================
# ac_plot_sentiment()
# ============================================================

test_that("ac_plot_sentiment() retorna objeto ggplot para type = 'bar'", {
  skip_if_not_installed("ggplot2")

  sent_tbl <- tibble::tibble(
    doc_id    = c("d1", "d2", "d3"),
    score     = c(3, -2, 0),
    sentiment = c("positivo", "negativo", "neutro"),
    n_pos     = c(3L, 0L, 0L),
    n_neg     = c(0L, 2L, 0L),
    n_neu     = c(1L, 1L, 3L)
  )

  p <- ac_plot_sentiment(sent_tbl, type = "bar")
  expect_s3_class(p, "ggplot")
})

test_that("ac_plot_sentiment() retorna ggplot para type = 'density'", {
  skip_if_not_installed("ggplot2")

  sent_tbl <- tibble::tibble(
    doc_id    = paste0("d", 1:6),
    score     = c(3, -2, 0, 1, -1, 2),
    sentiment = c("positivo", "negativo", "neutro",
                  "positivo", "negativo", "positivo"),
    n_pos = c(3L, 0L, 0L, 1L, 0L, 2L),
    n_neg = c(0L, 2L, 0L, 0L, 1L, 0L),
    n_neu = c(0L, 0L, 3L, 0L, 0L, 0L)
  )

  p <- ac_plot_sentiment(sent_tbl, type = "density")
  expect_s3_class(p, "ggplot")
})

test_that("ac_plot_sentiment() aceita title", {
  skip_if_not_installed("ggplot2")

  sent_tbl <- tibble::tibble(
    doc_id    = c("d1"),
    score     = c(1),
    sentiment = c("positivo"),
    n_pos = 1L, n_neg = 0L, n_neu = 0L
  )

  p <- ac_plot_sentiment(sent_tbl, title = "Meu titulo")
  expect_s3_class(p, "ggplot")
  expect_equal(p$labels$title, "Meu titulo")
})

test_that("ac_plot_sentiment() retorna ggplot para type = 'line'", {
  skip_if_not_installed("ggplot2")

  sent_tbl <- tibble::tibble(
    doc_id    = paste0("d", 1:5),
    score     = c(3, -2, 0, 1, -1),
    sentiment = c("positivo", "negativo", "neutro", "positivo", "negativo"),
    n_pos     = c(3L, 0L, 0L, 1L, 0L),
    n_neg     = c(0L, 2L, 0L, 0L, 1L),
    n_neu     = c(0L, 0L, 3L, 0L, 0L)
  )

  p <- ac_plot_sentiment(sent_tbl, type = "line")
  expect_s3_class(p, "ggplot")
})

test_that("ac_plot_sentiment() rejeita type invalido", {
  sent_tbl <- tibble::tibble(
    doc_id    = "d1",
    score     = 1,
    sentiment = "positivo",
    n_pos = 1L, n_neg = 0L, n_neu = 0L
  )
  expect_error(
    ac_plot_sentiment(sent_tbl, type = "invalido"),
    regexp = "invalido|arg"
  )
})

test_that(".ac_load_lexicon() retorna erro para lexicon nao suportado", {
  expect_error(
    acR:::.ac_load_lexicon("lexicon_inexistente"),
    regexp = "suportado"
  )
})
