test_that("ac_fetch_senado() retorna data.frame (integracao)", {
  skip_on_cran()
  skip_on_ci()
  skip_if_not_installed("senatebR")
  skip_if_offline("legis.senate.leg.br")
  try(closeAllConnections(), silent = TRUE)
  result <- suppressWarnings(
    ac_fetch_senado(
      data_inicio = "2024-03-01",
      data_fim    = "2024-03-15",
      partido     = "PT",
      n_max       = 5,
      verbose     = FALSE
    )
  )
  try(closeAllConnections(), silent = TRUE)
  expect_true(inherits(result, "data.frame"))
})

test_that("ac_fetch_senado() e ac_fetch_camara() sao compativeis (integracao)", {
  skip_on_cran()
  skip_on_ci()
  skip_if_not_installed("senatebR")
  skip_if_offline("legis.senate.leg.br")
  try(closeAllConnections(), silent = TRUE)
  result <- suppressWarnings(
    ac_fetch_senado(
      data_inicio = "2024-03-01",
      data_fim    = "2024-03-07",
      n_max       = 3,
      verbose     = FALSE
    )
  )
  try(closeAllConnections(), silent = TRUE)
  expect_true(inherits(result, "data.frame"))
  if (nrow(result) > 0) {
    expect_true("casa" %in% names(result))
    expect_equal(unique(result$casa), "senado")
  }
})
