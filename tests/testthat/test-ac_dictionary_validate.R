# Testes para ac_dictionary_validate()

test_that("ac_dictionary_validate() rejeita scored sem doc_id", {
  expect_error(
    ac_dictionary_validate(data.frame(x = 1), data.frame(doc_id = "d1", categoria = "a")),
    regexp = "doc_id"
  )
})

test_that("ac_dictionary_validate() rejeita human sem cat_col", {
  scored <- tibble::tibble(doc_id = "d1", a_n = 1L, total_tokens = 5L)
  expect_error(
    ac_dictionary_validate(scored, data.frame(doc_id = "d1")),
    regexp = "categoria"
  )
})

test_that("ac_dictionary_validate() calcula metricas binarias conhecidas", {
  # 4 documentos, categoria "a": dicionario marca presenca (a_n > 0) em d1,d2
  # humano marca presenca em d1,d3 -> vp=1 (d1), fp=1 (d2), fn=1 (d3), vn=1 (d4)
  scored <- tibble::tibble(
    doc_id = paste0("d", 1:4),
    a_n    = c(2L, 1L, 0L, 0L),
    total_tokens = c(5L, 5L, 5L, 5L)
  )
  human <- tibble::tibble(
    doc_id    = paste0("d", 1:4),
    categoria = c("a", "b", "a", "b")
  )

  out <- ac_dictionary_validate(scored, human)
  a_row <- out[out$categoria == "a", ]

  expect_equal(a_row$vp, 1)
  expect_equal(a_row$fp, 1)
  expect_equal(a_row$fn, 1)
  expect_equal(a_row$vn, 1)
  expect_equal(a_row$precisao, 0.5)
  expect_equal(a_row$recall, 0.5)
})

test_that("ac_dictionary_validate() trata multilabel (pipe-separado) em human", {
  scored <- tibble::tibble(
    doc_id = c("d1", "d2"),
    a_n    = c(1L, 0L),
    b_n    = c(0L, 1L),
    total_tokens = c(5L, 5L)
  )
  human <- tibble::tibble(
    doc_id    = c("d1", "d2"),
    categoria = c("a|b", "b")
  )

  out <- ac_dictionary_validate(scored, human)
  a_row <- out[out$categoria == "a", ]
  b_row <- out[out$categoria == "b", ]

  # a: dicionario diz presente so em d1; humano diz presente em d1 (via "a|b") -> vp=1, vn=1
  expect_equal(a_row$vp, 1)
  expect_equal(a_row$vn, 1)
  # b: dicionario diz presente so em d2; humano diz presente em d1 e d2 -> vp=1 (d2), fn=1 (d1)
  expect_equal(b_row$vp, 1)
  expect_equal(b_row$fn, 1)
})

test_that("ac_dictionary_validate() ignora documentos sem codificacao humana (NA)", {
  scored <- tibble::tibble(doc_id = c("d1", "d2"), a_n = c(1L, 0L),
                           total_tokens = c(5L, 5L))
  human <- tibble::tibble(doc_id = c("d1", "d2"), categoria = c("a", NA))

  out <- ac_dictionary_validate(scored, human)
  a_row <- out[out$categoria == "a", ]
  expect_equal(a_row$n, 1L)
})
