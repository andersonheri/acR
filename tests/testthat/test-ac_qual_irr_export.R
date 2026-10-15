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
  expect_equal(result$metrics$interpretation, "quase perfeita (Landis & Koch, 1977)")
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

test_that(".ac_landis_koch() usa os limites exatos de Landis & Koch (1977)", {
  expect_equal(.ac_landis_koch(-0.1), "pobre")
  expect_equal(.ac_landis_koch(0.10), "leve")
  expect_equal(.ac_landis_koch(0.20), "leve")
  expect_equal(.ac_landis_koch(0.30), "razoável")
  expect_equal(.ac_landis_koch(0.50), "moderada")
  expect_equal(.ac_landis_koch(0.70), "substancial")
  expect_equal(.ac_landis_koch(0.80), "substancial")   # 0,61-0,80
  expect_equal(.ac_landis_koch(0.81), "quase perfeita")
  expect_true(is.na(.ac_landis_koch(NA)))
})

test_that("alfa de Krippendorff e lido pelas faixas de Krippendorff (2018)", {
  expect_match(.ac_interpret_agreement(0.85, "alpha"), "^confi")
  expect_match(.ac_interpret_agreement(0.70, "alpha"), "provis")
  expect_match(.ac_interpret_agreement(0.60, "alpha"), "^insuficiente")
})

test_that("percentual usa as faixas de Neuendorf (2017) e F1 nao recebe rotulo", {
  expect_match(.ac_interpret_agreement(0.95, "percent"), "^alta")
  expect_match(.ac_interpret_agreement(0.75, "percent"), "explorat")
  expect_match(.ac_interpret_agreement(0.50, "percent"), "^insuficiente")
  expect_match(.ac_interpret_agreement(0.99, "f1"), "sem faixa")
})

test_that("ac_qual_irr() da IC bootstrap dentro de [-1, 1]", {
  skip_if_not_installed("irr")
  g <- data.frame(id_discurso = 1:5, categoria = c("a", "b", "a", "c", "a"))
  p <- data.frame(id_discurso = 1:5, categoria = c("a", "b", "b", "c", "a"))
  r <- withr::with_seed(1, ac_qual_irr(g, p, verbose = FALSE, bootstrap = 200))
  ci <- r$metrics[r$metrics$metric != "Percent Agreement", c("ci_lower", "ci_upper")]
  expect_true(all(ci$ci_lower >= -1 & ci$ci_upper <= 1, na.rm = TRUE))
  expect_false(anyNA(r$metrics$ci_lower[r$metrics$metric != "Percent Agreement"]))
})

test_that("ac_qual_irr() aceita weight = 'linear' (mapeado para 'equal' do irr)", {
  skip_if_not_installed("irr")
  g <- data.frame(id_discurso = 1:6,
                  categoria = factor(c("baixo", "medio", "alto", "medio", "baixo", "alto"),
                                     levels = c("baixo", "medio", "alto")))
  p <- data.frame(id_discurso = 1:6,
                  categoria = c("baixo", "alto", "alto", "medio", "medio", "alto"))
  expect_no_error(
    r <- ac_qual_irr(g, p, method = "cohen_kappa", weight = "linear",
                     verbose = FALSE, bootstrap = 0)
  )
  expect_equal(r$categories, c("baixo", "medio", "alto"))
})

test_that("ac_qual_irr() rejeita id duplicado", {
  skip_if_not_installed("irr")
  g <- data.frame(id_discurso = c(1, 1, 2), categoria = c("a", "b", "a"))
  p <- data.frame(id_discurso = c(1, 2), categoria = c("a", "a"))
  expect_error(ac_qual_irr(g, p, verbose = FALSE), "duplicado")
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
