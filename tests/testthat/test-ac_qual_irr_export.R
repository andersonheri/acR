# =============================================================================
# Testes: ac_qual_irr()
# =============================================================================

# Dados de exemplo reutilizaveis
.irr_gold <- data.frame(
  id_discurso = paste0("d", 1:10),
  categoria   = c("progressista", "conservador", "tecnocratico",
                  "progressista", "conservador", "progressista",
                  "tecnocratico", "conservador", "progressista",
                  "tecnocratico"),
  stringsAsFactors = FALSE
)

.irr_pred <- data.frame(
  id_discurso = paste0("d", 1:10),
  categoria   = c("progressista", "conservador", "progressista",
                  "progressista", "conservador", "progressista",
                  "tecnocratico", "progressista", "progressista",
                  "tecnocratico"),
  stringsAsFactors = FALSE
)

.irr_perfeito <- data.frame(
  id_discurso = paste0("d", 1:5),
  categoria   = c("progressista", "conservador", "tecnocratico",
                  "progressista", "conservador"),
  stringsAsFactors = FALSE
)

test_that("ac_qual_irr() retorna objeto ac_irr com estrutura correta", {
  skip_if_not_installed("irr")
  result <- ac_qual_irr(.irr_gold, .irr_pred, verbose = FALSE)
  expect_s3_class(result, "ac_irr")
  expect_true(all(c("metrics", "confusion", "n_docs",
                    "n_annotators", "categories", "method") %in% names(result)))
})

test_that("ac_qual_irr() metrics tem colunas corretas", {
  skip_if_not_installed("irr")
  result <- ac_qual_irr(.irr_gold, .irr_pred, verbose = FALSE)
  expect_true(all(c("metric", "estimate", "ci_lower",
                    "ci_upper", "interpretation") %in% names(result$metrics)))
})

test_that("ac_qual_irr() calcula todas as metricas com method = 'all'", {
  skip_if_not_installed("irr")
  result <- ac_qual_irr(.irr_gold, .irr_pred,
                        method = "all", verbose = FALSE)
  expect_equal(nrow(result$metrics), 4)
  expect_true(all(c("Percent Agreement", "Cohen's Kappa (unweighted)",
                    "Fleiss' Kappa", "Krippendorff's Alpha (nominal)") %in%
                    result$metrics$metric))
})

test_that("ac_qual_irr() calcula apenas Cohen's Kappa quando solicitado", {
  skip_if_not_installed("irr")
  result <- ac_qual_irr(.irr_gold, .irr_pred,
                        method = "cohen_kappa", verbose = FALSE)
  expect_equal(nrow(result$metrics), 1)
  expect_true(grepl("Cohen", result$metrics$metric))
})

test_that("ac_qual_irr() kappa = 1 para concordancia perfeita", {
  skip_if_not_installed("irr")
  result <- ac_qual_irr(.irr_perfeito, .irr_perfeito,
                        method = "cohen_kappa", verbose = FALSE)
  expect_equal(result$metrics$estimate, 1.0, tolerance = 1e-6)
  expect_equal(result$metrics$interpretation, "Quase perfeita")
})

test_that("ac_qual_irr() n_docs esta correto", {
  skip_if_not_installed("irr")
  result <- ac_qual_irr(.irr_gold, .irr_pred, verbose = FALSE)
  expect_equal(result$n_docs, 10L)
})

test_that("ac_qual_irr() confusion e uma tabela com dimensoes corretas", {
  skip_if_not_installed("irr")
  result <- ac_qual_irr(.irr_gold, .irr_pred, verbose = FALSE)
  expect_s3_class(result$confusion, "table")
  expect_equal(length(dimnames(result$confusion)), 2)
})

test_that("ac_qual_irr() lanca erro se id_col ausente", {
  skip_if_not_installed("irr")
  bad <- data.frame(id = 1:3, categoria = c("a", "b", "c"))
  expect_error(
    ac_qual_irr(bad, .irr_pred[1:3, ], verbose = FALSE),
    "id_discurso"
  )
})

test_that("ac_qual_irr() lanca erro se nenhum ID em comum", {
  skip_if_not_installed("irr")
  gold2 <- .irr_gold
  gold2$id_discurso <- paste0("x", 1:10)
  expect_error(
    ac_qual_irr(gold2, .irr_pred, verbose = FALSE),
    "comum"
  )
})

test_that("ac_qual_irr() avisa sobre documentos sem par", {
  skip_if_not_installed("irr")
  gold_extra <- rbind(
    .irr_gold,
    data.frame(id_discurso = "d99", categoria = "progressista")
  )
  expect_warning(
    ac_qual_irr(gold_extra, .irr_pred, verbose = FALSE)
  )
})

test_that(".irr_interpret_kappa() retorna interpretacoes corretas", {
  expect_equal(.irr_interpret_kappa(-0.1), "Pobre")
  expect_equal(.irr_interpret_kappa(0.10), "Leve")
  expect_equal(.irr_interpret_kappa(0.30), "Razoavel")
  expect_equal(.irr_interpret_kappa(0.50), "Moderada")
  expect_equal(.irr_interpret_kappa(0.70), "Substancial")
  expect_equal(.irr_interpret_kappa(0.90), "Quase perfeita")
  expect_equal(.irr_interpret_kappa(NA),   "N/A")
})

test_that(".irr_interpret_pa() retorna interpretacoes corretas", {
  expect_equal(.irr_interpret_pa(0.50), "Insuficiente")
  expect_equal(.irr_interpret_pa(0.65), "Aceitavel")
  expect_equal(.irr_interpret_pa(0.75), "Bom")
  expect_equal(.irr_interpret_pa(0.85), "Muito bom")
  expect_equal(.irr_interpret_pa(0.95), "Excelente")
})

test_that("print.ac_irr() nao lanca erro", {
  skip_if_not_installed("irr")
  result <- ac_qual_irr(.irr_gold, .irr_pred, verbose = FALSE)
  expect_no_error(print(result))
})


# =============================================================================
# Testes: ac_export()
# =============================================================================

.export_df <- data.frame(
  id          = c("d1", "d2", "d3"),
  categoria   = c("progressista", "conservador", "tecnocratico"),
  confianca   = c(0.94, 0.91, 0.87),
  stringsAsFactors = FALSE
)

test_that("ac_export() exporta CSV corretamente", {
  path <- tempfile(fileext = ".csv")
  ac_export(.export_df, path, verbose = FALSE)
  expect_true(file.exists(path))
  df_lido <- utils::read.csv(path)
  expect_equal(nrow(df_lido), 3)
  expect_equal(ncol(df_lido), 3)
  unlink(path)
})

test_that("ac_export() infere formato pelo path", {
  path <- tempfile(fileext = ".csv")
  expect_no_error(ac_export(.export_df, path, verbose = FALSE))
  unlink(path)
})

test_that("ac_export() exporta RDS corretamente", {
  path <- tempfile(fileext = ".rds")
  ac_export(.export_df, path, verbose = FALSE)
  expect_true(file.exists(path))
  obj <- readRDS(path)
  expect_equal(obj, .export_df)
  unlink(path)
})

test_that("ac_export() exporta LaTeX corretamente", {
  skip_if_not_installed("knitr")
  path <- tempfile(fileext = ".tex")
  ac_export(
    .export_df, path,
    latex_caption = "Teste",
    latex_label   = "tab:teste",
    verbose       = FALSE
  )
  expect_true(file.exists(path))
  lines <- readLines(path)
  expect_true(any(grepl("\\\\begin\\{table\\}", lines)))
  expect_true(any(grepl("\\\\end\\{table\\}", lines)))
  expect_true(any(grepl("Teste", lines)))
  unlink(path)
})

test_that("ac_export() exporta Excel corretamente", {
  skip_if_not_installed("writexl")
  path <- tempfile(fileext = ".xlsx")
  ac_export(.export_df, path, verbose = FALSE)
  expect_true(file.exists(path))
  expect_gt(file.size(path), 0)
  unlink(path)
})

test_that("ac_export() respeita overwrite = FALSE", {
  path <- tempfile(fileext = ".csv")
  ac_export(.export_df, path, verbose = FALSE)
  expect_error(
    ac_export(.export_df, path, overwrite = FALSE, verbose = FALSE),
    "ja existe"
  )
  unlink(path)
})

test_that("ac_export() aceita objeto ac_irr", {
  skip_if_not_installed("irr")
  path <- tempfile(fileext = ".csv")
  irr_obj <- ac_qual_irr(.irr_gold, .irr_pred, verbose = FALSE)
  expect_no_error(ac_export(irr_obj, path, verbose = FALSE))
  df_lido <- utils::read.csv(path)
  expect_true("metric" %in% names(df_lido))
  unlink(path)
})

test_that("ac_export() lanca erro para formato nao reconhecido", {
  expect_error(
    ac_export(.export_df, "arquivo.xyz", verbose = FALSE),
    "formato"
  )
})

test_that("ac_export() retorna path invisivelmente", {
  path <- tempfile(fileext = ".csv")
  result <- ac_export(.export_df, path, verbose = FALSE)
  expect_equal(result, path)
  unlink(path)
})

test_that(".export_resolve_format() infere formato por extensao", {
  expect_equal(.export_resolve_format("x.csv",  NULL), "csv")
  expect_equal(.export_resolve_format("x.tex",  NULL), "latex")
  expect_equal(.export_resolve_format("x.xlsx", NULL), "xlsx")
  expect_equal(.export_resolve_format("x.rds",  NULL), "rds")
})

test_that(".export_resolve_format() prefere argumento format sobre extensao", {
  expect_equal(.export_resolve_format("x.csv", "rds"), "rds")
})
