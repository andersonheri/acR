# Testes para ac_collocations()

make_colloc_corpus <- function() {
  df <- data.frame(
    id = paste0("d", 1:3),
    texto = c("a b", "a b", "a c"),
    stringsAsFactors = FALSE
  )
  ac_corpus(df, text = texto, docid = id)
}

test_that("ac_collocations() rejeita corpus invalido", {
  expect_error(ac_collocations("nao e corpus"), regexp = "ac_corpus")
})

test_that("ac_collocations() rejeita n diferente de 2 ou 3", {
  corpus <- make_colloc_corpus()
  expect_error(ac_collocations(corpus, n = 4L), regexp = "2.*3|bigramas")
})

test_that("ac_collocations() calcula PMI corretamente em exemplo controlado", {
  # N = 6 tokens totais; freq(a) = 3, freq(b) = 2, freq(c) = 1;
  # bigrama "a b" ocorre 2x -> PMI = log2(2*6 / (3*2)) = log2(2) = 1
  corpus <- make_colloc_corpus()
  out <- ac_collocations(corpus, measure = "pmi", min_count = 1L)

  ab <- out[out$collocation == "a b", ]
  expect_equal(ab$count, 2L)
  expect_equal(ab$association, 1, tolerance = 1e-8)
})

test_that("ac_collocations() respeita min_count", {
  corpus <- make_colloc_corpus()
  out <- ac_collocations(corpus, measure = "pmi", min_count = 3L)
  expect_equal(nrow(out), 0L)
})

test_that("ac_collocations() funciona com measure = 'll' e 'chi2'", {
  corpus <- make_colloc_corpus()
  out_ll   <- ac_collocations(corpus, measure = "ll",   min_count = 1L)
  out_chi2 <- ac_collocations(corpus, measure = "chi2", min_count = 1L)

  expect_true(all(is.finite(out_ll$association)))
  expect_true(all(is.finite(out_chi2$association)))
})

test_that("ac_collocations() ordena por associacao decrescente", {
  corpus <- make_colloc_corpus()
  out <- ac_collocations(corpus, measure = "pmi", min_count = 1L)
  expect_true(all(diff(out$association) <= 0))
})

test_that("ac_collocations() devolve tibble vazio quando nenhum n-grama atinge min_count", {
  df <- data.frame(id = "d1", texto = "a b c", stringsAsFactors = FALSE)
  corpus <- ac_corpus(df, text = texto, docid = id)
  out <- ac_collocations(corpus, min_count = 10L)
  expect_equal(nrow(out), 0L)
  expect_true(all(c("collocation", "count", "association") %in% names(out)))
})

test_that("trigramas usam a tabela primeira palavra x bigrama restante", {
  df <- data.frame(id = c("a", "b", "c"),
                   t = c("atendimento ao cliente bom", "atendimento ao cliente ruim",
                         "cliente feliz ao final"),
                   stringsAsFactors = FALSE)
  corp <- ac_corpus(df, text = t, docid = id)
  r <- ac_collocations(corp, n = 3, measure = "pmi", min_count = 2)
  # f(trigrama)=2, f(atendimento)=2, f("ao cliente")=2, N=12 unigramas
  expect_equal(r$association[r$collocation == "atendimento ao cliente"],
               log2(2 * 12 / (2 * 2)))
})
