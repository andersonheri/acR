# Testes para ac_emotion()

test_that("ac_emotion() rejeita lexicon sem as colunas esperadas", {
  df <- data.frame(id = "d1", texto = "feliz", stringsAsFactors = FALSE)
  corpus <- ac_corpus(df, text = texto, docid = id)
  expect_error(ac_emotion(corpus, lexicon = data.frame(x = 1)), regexp = "colunas")
})

test_that("ac_emotion() conta palavras por emocao corretamente", {
  lexico <- data.frame(
    termo  = c("feliz", "alegria", "medo", "assustado"),
    emocao = c("alegria", "alegria", "medo", "medo"),
    stringsAsFactors = FALSE
  )
  df <- data.frame(
    id = c("d1", "d2"),
    texto = c("fiquei muito feliz com a alegria", "fiquei assustado com tanto medo"),
    stringsAsFactors = FALSE
  )
  corpus <- ac_corpus(df, text = texto, docid = id)
  out <- ac_emotion(corpus, lexicon = lexico)

  expect_equal(out$alegria_n, c(2L, 0L))
  expect_equal(out$medo_n, c(0L, 2L))
})
