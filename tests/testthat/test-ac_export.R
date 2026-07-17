# Testes para ac_export()

make_df <- function() {
  data.frame(
    id       = c("d1", "d2", "d3"),
    grupo    = c("A", "B", "A"),
    metrica  = c(0.912, 0.845, 0.777),
    stringsAsFactors = FALSE
  )
}

# --- validacoes -------------------------------------------------------------

test_that("ac_export() rejeita entrada que nao e data.frame nem ac_irr", {
  expect_error(
    ac_export(list(a = 1), path = tempfile(fileext = ".csv"), verbose = FALSE),
    regexp = "data\\.frame|ac_irr"
  )
})

test_that("ac_export() erra quando formato nao pode ser inferido", {
  expect_error(
    ac_export(make_df(), path = tempfile(fileext = ".xyz"), verbose = FALSE),
    regexp = "formato"
  )
})

test_that("ac_export() respeita overwrite = FALSE", {
  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp))
  ac_export(make_df(), path = tmp, verbose = FALSE)
  expect_error(
    ac_export(make_df(), path = tmp, overwrite = FALSE, verbose = FALSE),
    regexp = "existe"
  )
})

# --- CSV --------------------------------------------------------------------

test_that("ac_export() para CSV grava arquivo lido de volta identico", {
  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp))
  df <- make_df()
  path <- ac_export(df, path = tmp, verbose = FALSE)
  expect_equal(path, tmp)
  expect_true(file.exists(tmp))

  read_back <- utils::read.csv(tmp, stringsAsFactors = FALSE)
  expect_equal(nrow(read_back), 3L)
  expect_equal(read_back$id, df$id)
  expect_equal(read_back$grupo, df$grupo)
})

# --- RDS --------------------------------------------------------------------

test_that("ac_export() para RDS preserva o objeto", {
  tmp <- tempfile(fileext = ".rds")
  on.exit(unlink(tmp))
  df <- make_df()
  ac_export(df, path = tmp, verbose = FALSE)
  expect_equal(readRDS(tmp), df)
})

# --- format explicito -------------------------------------------------------

test_that("ac_export() aceita format explicito com path sem extensao", {
  tmp <- tempfile()
  on.exit(unlink(tmp))
  path <- ac_export(make_df(), path = tmp, format = "csv", verbose = FALSE)
  expect_true(file.exists(path))
  expect_equal(path, tmp)
})
