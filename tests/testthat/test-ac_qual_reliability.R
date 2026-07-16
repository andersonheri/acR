# Testes para ac_qual_reliability(), ac_qual_sample(), e auxiliares internos
# Todas as funcoes sao puro R: sem rede, sem LLM, sem arquivos externos.

# ============================================================
# Fixtures
# ============================================================

make_llm_df <- function() {
  tibble::tibble(
    doc_id    = paste0("d", 1:10),
    categoria = c("pos","pos","neg","neg","neu","pos","neg","pos","neu","neg"),
    confidence_score = c(1, 0.67, 1, 0.33, 1, 0.67, 0.33, 1, 0.67, 1)
  )
}

make_human_df <- function() {
  tibble::tibble(
    doc_id    = paste0("d", 1:10),
    categoria = c("pos","pos","neg","pos","neu","pos","neg","neg","neu","neg")
  )
}


# ============================================================
# ac_qual_reliability() — validacoes de entrada
# ============================================================

test_that("ac_qual_reliability() rejeita llm sem coluna categoria", {
  expect_error(
    ac_qual_reliability(
      llm   = tibble::tibble(doc_id = "d1", outra = "x"),
      human = make_human_df()
    ),
    regexp = "categoria"
  )
})

test_that("ac_qual_reliability() rejeita human sem coluna categoria", {
  expect_error(
    ac_qual_reliability(
      llm   = make_llm_df(),
      human = tibble::tibble(doc_id = "d1", outra = "x")
    ),
    regexp = "categoria"
  )
})

test_that("ac_qual_reliability() rejeita quando nao ha doc_id em comum", {
  llm   <- tibble::tibble(doc_id = "d1",  categoria = "pos")
  human <- tibble::tibble(doc_id = "d99", categoria = "neg")
  expect_error(
    ac_qual_reliability(llm = llm, human = human),
    regexp = "comum"
  )
})


# ============================================================
# ac_qual_reliability() — resultados
# ============================================================

test_that("ac_qual_reliability() retorna tibble com colunas corretas", {
  result <- suppressWarnings(ac_qual_reliability(
    llm       = make_llm_df(),
    human     = make_human_df(),
    bootstrap = 50L
  ))

  expect_s3_class(result, "tbl_df")
  expect_true(all(c("metric", "estimate", "ci_lower", "ci_upper",
                    "interpretation") %in% names(result)))
})

test_that("ac_qual_reliability() retorna 4 metricas por padrao", {
  result <- suppressWarnings(ac_qual_reliability(
    llm       = make_llm_df(),
    human     = make_human_df(),
    bootstrap = 50L
  ))
  expect_equal(nrow(result), 4L)
})

test_that("ac_qual_reliability() retorna subset correto de metricas", {
  result <- ac_qual_reliability(
    llm       = make_llm_df(),
    human     = make_human_df(),
    metrics   = c("percent_agreement", "gwet_ac1"),
    bootstrap = 50L
  )
  expect_equal(nrow(result), 2L)
  expect_true("percent_agreement" %in% result$metric)
  expect_true("gwet_ac1"          %in% result$metric)
})

test_that("ac_qual_reliability() estimate de percent_agreement esta entre 0 e 1", {
  result <- ac_qual_reliability(
    llm       = make_llm_df(),
    human     = make_human_df(),
    metrics   = "percent_agreement",
    bootstrap = 50L
  )
  est <- result$estimate[result$metric == "percent_agreement"]
  expect_true(est >= 0 && est <= 1)
})

test_that("ac_qual_reliability() concordancia perfeita retorna percent_agreement = 1", {
  df <- tibble::tibble(
    doc_id    = paste0("d", 1:5),
    categoria = c("pos","neg","neu","pos","neg")
  )
  result <- ac_qual_reliability(
    llm       = df,
    human     = df,
    metrics   = "percent_agreement",
    bootstrap = 50L
  )
  expect_equal(result$estimate, 1)
})

test_that("ac_qual_reliability() usa cat_col customizado", {
  llm   <- tibble::tibble(doc_id = paste0("d",1:5), label = c("a","b","a","b","a"))
  human <- tibble::tibble(doc_id = paste0("d",1:5), label = c("a","b","a","a","a"))

  result <- ac_qual_reliability(
    llm       = llm,
    human     = human,
    cat_col   = "label",
    metrics   = "percent_agreement",
    bootstrap = 50L
  )
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 1L)
})


# ============================================================
# Auxiliares internos
# ============================================================

test_that(".ac_gwet_ac1() retorna 1 para concordancia perfeita", {
  r <- c("a","b","c","a","b")
  expect_equal(acR:::.ac_gwet_ac1(r, r), 1)
})

test_that(".ac_gwet_ac1() retorna NA com menos de 2 observacoes", {
  expect_true(is.na(acR:::.ac_gwet_ac1("a", "b")))
})

test_that(".ac_gwet_ac1() retorna NA com apenas 1 categoria", {
  r <- c("a","a","a")
  expect_true(is.na(acR:::.ac_gwet_ac1(r, r)))
})

test_that(".ac_gwet_ac1() retorna valor entre -1 e 1 para dados reais", {
  llm   <- make_llm_df()$categoria
  human <- make_human_df()$categoria
  val   <- acR:::.ac_gwet_ac1(llm, human)
  expect_true(val >= -1 && val <= 1)
})

test_that(".ac_compute_f1_macro() retorna 1 para concordancia perfeita", {
  r <- c("a","b","c")
  expect_equal(acR:::.ac_compute_f1_macro(r, r), 1)
})

test_that(".ac_compute_f1_macro() retorna valor entre 0 e 1", {
  pred <- c("a","b","a","c","b")
  true <- c("a","b","b","c","a")
  val  <- acR:::.ac_compute_f1_macro(pred, true)
  expect_true(val >= 0 && val <= 1)
})

test_that(".ac_interpret_agreement() retorna string nao vazia", {
  expect_type(acR:::.ac_interpret_agreement(0.9, "kappa"),   "character")
  expect_type(acR:::.ac_interpret_agreement(0.5, "percent"), "character")
  expect_type(acR:::.ac_interpret_agreement(NA,  "kappa"),   "character")
})

test_that(".ac_bootstrap_metric() retorna vetor de comprimento 2", {
  v1 <- c("a","b","a","b","a")
  v2 <- c("a","a","a","b","b")
  ci <- acR:::.ac_bootstrap_metric(v1, v2, B = 100L, ci_level = 0.95,
                                   fn = function(l, h) mean(l == h))
  expect_length(ci, 2L)
  expect_true(ci[1] <= ci[2])
})


# ============================================================
# ac_qual_sample()
# ============================================================

test_that("ac_qual_sample() rejeita objeto nao data.frame", {
  expect_error(ac_qual_sample("nao_df"), regexp = "tibble")
})

test_that("ac_qual_sample() strategy = 'random' retorna n linhas", {
  coded  <- make_llm_df()
  result <- ac_qual_sample(coded, n = 5L, strategy = "random", seed = 42L)
  expect_equal(nrow(result), 5L)
  expect_true("sample_reason" %in% names(result))
})

test_that("ac_qual_sample() strategy = 'uncertainty' ordena por confidence", {
  coded  <- make_llm_df()
  result <- ac_qual_sample(coded, n = 3L, strategy = "uncertainty", seed = 1L)
  expect_equal(nrow(result), 3L)
  # Os 3 com menor confidence_score devem ser selecionados
  expect_true(all(result$confidence_score <= sort(coded$confidence_score)[3]))
})

test_that("ac_qual_sample() strategy = 'stratified' inclui multiplas categorias", {
  coded  <- make_llm_df()
  result <- ac_qual_sample(coded, n = 6L, strategy = "stratified", seed = 1L)
  expect_true(length(unique(result$categoria)) > 1L)
})

test_that("ac_qual_sample() strategy = 'disagreement' seleciona confidence < 1", {
  coded  <- make_llm_df()
  result <- ac_qual_sample(coded, n = 4L, strategy = "disagreement", seed = 1L)
  expect_true(all(result$confidence_score < 1.0))
})

test_that("ac_qual_sample() nao retorna mais linhas do que o input", {
  coded  <- make_llm_df()  # 10 linhas
  result <- ac_qual_sample(coded, n = 999L, strategy = "random")
  expect_equal(nrow(result), nrow(coded))
})

test_that("ac_qual_sample() sem confidence_score cai para random em 'uncertainty'", {
  coded <- tibble::tibble(
    doc_id    = paste0("d", 1:5),
    categoria = c("a","b","a","b","a")
  )
  expect_warning(
    result <- ac_qual_sample(coded, n = 3L, strategy = "uncertainty"),
    regexp = "confidence_score"
  )
  expect_equal(nrow(result), 3L)
})


# ============================================================
# ac_qual_export_for_review() e ac_qual_import_human()
# I/O Excel: usa tempfile(); requer openxlsx
# ============================================================

test_that("ac_qual_export_for_review() cria arquivo e retorna o path", {
  skip_if_not_installed("openxlsx")
  amostra <- ac_qual_sample(make_llm_df(), n = 5L, strategy = "random", seed = 1L)
  path <- tempfile(fileext = ".xlsx"); on.exit(unlink(path), add = TRUE)
  ret <- suppressMessages(ac_qual_export_for_review(amostra, path = path))
  expect_true(file.exists(path))
  expect_identical(ret, path)
})

test_that("ac_qual_export_for_review() adiciona colunas de preenchimento humano", {
  skip_if_not_installed("openxlsx")
  amostra <- ac_qual_sample(make_llm_df(), n = 4L, strategy = "random", seed = 2L)
  path <- tempfile(fileext = ".xlsx"); on.exit(unlink(path), add = TRUE)
  suppressMessages(ac_qual_export_for_review(amostra, path = path))
  df <- openxlsx::read.xlsx(path)
  expect_true(all(c("categoria_humano", "notas_humano") %in% names(df)))
})

test_that("ac_qual_export_for_review() inclui texto quando corpus e fornecido", {
  skip_if_not_installed("openxlsx")
  amostra <- ac_qual_sample(make_llm_df(), n = 3L, strategy = "random", seed = 3L)
  corpus  <- ac_corpus(
    data.frame(id = paste0("d", 1:10), texto = paste("Documento", 1:10)),
    text = texto, docid = id
  )
  path <- tempfile(fileext = ".xlsx"); on.exit(unlink(path), add = TRUE)
  suppressMessages(ac_qual_export_for_review(amostra, path = path, corpus = corpus))
  df <- openxlsx::read.xlsx(path)
  expect_true("text" %in% names(df))
})

test_that("roundtrip export -> preenchimento -> import recupera classificacoes", {
  skip_if_not_installed("openxlsx")
  amostra <- ac_qual_sample(make_llm_df(), n = 5L, strategy = "random", seed = 7L)
  path <- tempfile(fileext = ".xlsx"); on.exit(unlink(path), add = TRUE)
  suppressMessages(ac_qual_export_for_review(amostra, path = path))
  df <- openxlsx::read.xlsx(path)
  df$categoria_humano <- df$categoria            # humano concorda com a LLM
  openxlsx::write.xlsx(df, path, overwrite = TRUE)
  human <- suppressMessages(ac_qual_import_human(path))
  expect_s3_class(human, "tbl_df")
  expect_true(all(c("doc_id", "categoria") %in% names(human)))
  expect_equal(nrow(human), 5L)
})

test_that("ac_qual_import_human() aborta se arquivo nao existe", {
  skip_if_not_installed("openxlsx")
  expect_error(ac_qual_import_human(tempfile(fileext = ".xlsx")), regexp = "encontrado")
})

test_that("ac_qual_import_human() aborta se falta id_col", {
  skip_if_not_installed("openxlsx")
  path <- tempfile(fileext = ".xlsx"); on.exit(unlink(path), add = TRUE)
  openxlsx::write.xlsx(data.frame(categoria_humano = "pos"), path)
  expect_error(suppressMessages(ac_qual_import_human(path)), regexp = "doc_id")
})

test_that("ac_qual_import_human() aborta se falta cat_col", {
  skip_if_not_installed("openxlsx")
  path <- tempfile(fileext = ".xlsx"); on.exit(unlink(path), add = TRUE)
  openxlsx::write.xlsx(data.frame(doc_id = "d1"), path)
  expect_error(suppressMessages(ac_qual_import_human(path)), regexp = "categoria_humano")
})

test_that("ac_qual_import_human() avisa e remove linhas sem classificacao", {
  skip_if_not_installed("openxlsx")
  path <- tempfile(fileext = ".xlsx"); on.exit(unlink(path), add = TRUE)
  openxlsx::write.xlsx(
    data.frame(doc_id = c("d1","d2","d3"),
               categoria_humano = c("pos", "", NA)),
    path
  )
  expect_warning(human <- suppressMessages(ac_qual_import_human(path)),
                 regexp = "sem classifica")
  expect_equal(nrow(human), 1L)
})
