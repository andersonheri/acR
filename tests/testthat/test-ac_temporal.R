# Testes para ac_temporal() e ac_plot_temporal()

test_that("ac_temporal() rejeita data.frame invalido", {
  expect_error(ac_temporal("nao e df", date_col = "x", value_col = "y"),
              regexp = "data.frame")
})

test_that("ac_temporal() rejeita colunas inexistentes", {
  df <- data.frame(data = as.Date("2024-01-01"), score = 1)
  expect_error(ac_temporal(df, date_col = "inexistente", value_col = "score"),
              regexp = "inexistente")
  expect_error(ac_temporal(df, date_col = "data", value_col = "inexistente"),
              regexp = "inexistente")
})

test_that("ac_temporal() agrega por mes com media", {
  df <- data.frame(
    data  = as.Date(c("2024-01-05", "2024-01-20", "2024-02-02")),
    score = c(1, 3, 10)
  )
  out <- ac_temporal(df, date_col = "data", value_col = "score", unit = "month")

  expect_equal(nrow(out), 2L)
  jan <- out[out$period == as.Date("2024-01-01"), ]
  expect_equal(jan$value, 2)
  expect_equal(jan$n_docs, 2L)
})

test_that("ac_temporal() agrega com soma quando stat = 'sum'", {
  df <- data.frame(
    data  = as.Date(c("2024-01-05", "2024-01-20")),
    score = c(1, 3)
  )
  out <- ac_temporal(df, date_col = "data", value_col = "score",
                     unit = "month", stat = "sum")
  expect_equal(out$value, 4)
})

test_that("ac_temporal() agrega com contagem quando stat = 'n'", {
  df <- data.frame(
    data  = as.Date(c("2024-01-05", "2024-01-20", "2024-02-01")),
    score = c(1, 3, 5)
  )
  out <- ac_temporal(df, date_col = "data", value_col = "score",
                     unit = "month", stat = "n")
  expect_equal(out$value, c(2, 1))
})

test_that("ac_temporal() ordena por periodo", {
  df <- data.frame(
    data  = as.Date(c("2024-03-01", "2024-01-01", "2024-02-01")),
    score = c(1, 2, 3)
  )
  out <- ac_temporal(df, date_col = "data", value_col = "score", unit = "month")
  expect_equal(out$period, sort(out$period))
})

test_that("ac_plot_temporal() gera um objeto ggplot", {
  skip_if_not_installed("ggplot2")
  df <- data.frame(
    data  = as.Date(c("2024-01-05", "2024-02-20", "2024-03-02", "2024-04-15")),
    score = c(1, 3, 2, 4)
  )
  temporal <- ac_temporal(df, date_col = "data", value_col = "score")
  p <- ac_plot_temporal(temporal, smooth = FALSE)
  expect_s3_class(p, "ggplot")
})
