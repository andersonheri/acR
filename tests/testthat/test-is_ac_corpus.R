# Testes para is_ac_corpus()

test_that("is_ac_corpus() TRUE para saida de ac_corpus()", {
  corp <- ac_corpus(c("texto um", "texto dois"))
  expect_true(is_ac_corpus(corp))
})

test_that("is_ac_corpus() FALSE para tipos comuns", {
  expect_false(is_ac_corpus(data.frame(x = 1)))
  expect_false(is_ac_corpus("string"))
  expect_false(is_ac_corpus(NULL))
  expect_false(is_ac_corpus(list()))
  expect_false(is_ac_corpus(1:3))
})
