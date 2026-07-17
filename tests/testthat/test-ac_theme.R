# Testes para theme_ac() e ac_palette()

test_that("theme_ac() retorna objeto ggplot2::theme", {
  skip_if_not_installed("ggplot2")
  t <- theme_ac()
  expect_s3_class(t, "theme")
})

test_that("theme_ac() aceita base_size customizado", {
  skip_if_not_installed("ggplot2")
  expect_s3_class(theme_ac(base_size = 14), "theme")
})

test_that("ac_palette() retorna 8 cores hex por padrao", {
  pal <- ac_palette()
  expect_length(pal, 8L)
  expect_true(all(grepl("^#[0-9A-Fa-f]{6}$", pal)))
})

test_that("ac_palette() aceita n < 8 e devolve prefixo", {
  full <- ac_palette()
  expect_equal(ac_palette(3), full[1:3])
})

test_that("ac_palette() rejeita n fora do intervalo", {
  expect_error(ac_palette(0), regexp = "entre")
  expect_error(ac_palette(9), regexp = "entre")
})
