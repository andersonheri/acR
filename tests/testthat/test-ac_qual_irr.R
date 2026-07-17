# Testes para ac_qual_irr()
# Requer o pacote irr (Suggests).

make_pair <- function() {
  gold <- data.frame(
    id_discurso = paste0("d", 1:6),
    categoria   = c("A", "B", "A", "C", "B", "A"),
    stringsAsFactors = FALSE
  )
  pred <- data.frame(
    id_discurso = paste0("d", 1:6),
    categoria   = c("A", "B", "B", "C", "B", "A"),
    stringsAsFactors = FALSE
  )
  list(gold = gold, pred = pred)
}

test_that("ac_qual_irr() rejeita entrada nao data.frame", {
  skip_if_not_installed("irr")
  expect_error(
    ac_qual_irr(list(), data.frame(), verbose = FALSE),
    regexp = "data\\.frame"
  )
})

test_that("ac_qual_irr() erra quando falta coluna obrigatoria", {
  skip_if_not_installed("irr")
  gold <- data.frame(id_discurso = "d1", stringsAsFactors = FALSE)
  pred <- data.frame(id_discurso = "d1", categoria = "A",
                     stringsAsFactors = FALSE)
  expect_error(
    ac_qual_irr(gold, pred, verbose = FALSE),
    regexp = "categoria"
  )
})

test_that("ac_qual_irr() erra sem documentos em comum", {
  skip_if_not_installed("irr")
  gold <- data.frame(id_discurso = "d1", categoria = "A",
                     stringsAsFactors = FALSE)
  pred <- data.frame(id_discurso = "d2", categoria = "A",
                     stringsAsFactors = FALSE)
  expect_error(
    ac_qual_irr(gold, pred, verbose = FALSE),
    regexp = "comum"
  )
})

test_that("ac_qual_irr() retorna ac_irr com metrics/confusion/n_docs", {
  skip_if_not_installed("irr")
  p <- make_pair()
  out <- ac_qual_irr(p$gold, p$pred, verbose = FALSE)
  expect_s3_class(out, "ac_irr")
  expect_true(is.data.frame(out$metrics))
  expect_true(is.table(out$confusion))
  expect_equal(out$n_docs, 6L)
  expect_setequal(out$categories, c("A", "B", "C"))
})

test_that("ac_qual_irr() filtra por method = 'cohen_kappa'", {
  skip_if_not_installed("irr")
  p <- make_pair()
  out <- ac_qual_irr(p$gold, p$pred, method = "cohen_kappa", verbose = FALSE)
  expect_true(all(grepl("Cohen", out$metrics$metric)))
})

test_that("ac_qual_irr() avisa quando gold tem docs sem par em predicted", {
  skip_if_not_installed("irr")
  gold <- data.frame(
    id_discurso = c("d1", "d2", "d3"),
    categoria   = c("A", "B", "A"),
    stringsAsFactors = FALSE
  )
  pred <- data.frame(
    id_discurso = c("d1", "d2"),
    categoria   = c("A", "B"),
    stringsAsFactors = FALSE
  )
  expect_warning(
    ac_qual_irr(gold, pred, verbose = FALSE),
    regexp = "sem par"
  )
})
