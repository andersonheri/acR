# Testes para ac_qual_list_models() e ac_qual_recommend_model()

# ============================================================
# ac_qual_list_models()
# ============================================================

test_that("ac_qual_list_models() retorna tibble com colunas esperadas", {
  result <- ac_qual_list_models()
  expect_s3_class(result, "tbl_df")
  expected_cols <- c("provider", "model_id", "name", "context_k",
                     "cost_input", "cost_output", "tier",
                     "pt_support", "acr_string")
  expect_true(all(expected_cols %in% names(result)))
  expect_true(nrow(result) > 0)
})

test_that("ac_qual_list_models() filtra por provedor", {
  result <- ac_qual_list_models(provider = "anthropic")
  expect_true(all(result$provider == "anthropic"))
  expect_true(nrow(result) > 0)
})

test_that("ac_qual_list_models() filtra por nome", {
  result <- ac_qual_list_models(filter = "claude")
  expect_true(all(grepl("claude", tolower(result$model_id))))
})

test_that("ac_qual_list_models() aceita multiplos provedores", {
  result <- ac_qual_list_models(provider = c("anthropic", "openai"))
  expect_true(all(result$provider %in% c("anthropic", "openai")))
})

test_that("ac_qual_list_models() ordena por custo", {
  result <- ac_qual_list_models(sort_by = "cost")
  # Modelos com NA no custo ficam por ultimo
  non_na <- result[!is.na(result$cost_input), ]
  if (nrow(non_na) > 1) {
    expect_true(all(diff(non_na$cost_input) >= 0))
  }
})

test_that("ac_qual_list_models() ordena por contexto", {
  result <- ac_qual_list_models(sort_by = "context")
  expect_true(all(diff(result$context_k) <= 0))
})

test_that("ac_qual_list_models() retorna aviso se nenhum modelo encontrado", {
  expect_warning(
    ac_qual_list_models(filter = "modelo_que_nao_existe_xyz"),
    regexp = "Nenhum modelo"
  )
})

test_that("modelos locais tem tier='local' e cost NA", {
  result <- ac_qual_list_models(provider = "ollama")
  expect_true(all(result$tier == "local"))
  expect_true(all(is.na(result$cost_input)))
})

test_that("acr_string esta preenchido para todos os modelos", {
  result <- ac_qual_list_models()
  expect_true(all(nchar(result$acr_string) > 0))
})

# ============================================================
# ac_qual_recommend_model()
# ============================================================

test_that("ac_qual_recommend_model() retorna tibble com colunas esperadas", {
  result <- ac_qual_recommend_model()
  expect_s3_class(result, "tbl_df")
  expect_true(all(c("rank", "provider", "model_id", "score",
                    "justificativa") %in% names(result)))
})

test_that("ac_qual_recommend_model() retorna n recomendacoes", {
  r3 <- ac_qual_recommend_model(n = 3)
  r1 <- ac_qual_recommend_model(n = 1)
  expect_equal(nrow(r3), 3L)
  expect_equal(nrow(r1), 1L)
})

test_that("ac_qual_recommend_model() rank esta em ordem crescente", {
  result <- ac_qual_recommend_model(n = 3)
  expect_equal(result$rank, 1:3)
})

test_that("ac_qual_recommend_model() score esta entre 0 e 100", {
  result <- ac_qual_recommend_model()
  expect_true(all(result$score >= 0 & result$score <= 100))
})

test_that("budget='free' retorna so modelos locais ou gratuitos", {
  result <- ac_qual_recommend_model(budget = "free")
  custo_ok <- is.na(result$cost_input) | result$cost_input == 0
  expect_true(all(custo_ok))
})

test_that("budget='low' respeita limite de USD 1", {
  result <- ac_qual_recommend_model(budget = "low")
  custo_ok <- is.na(result$cost_input) | result$cost_input <= 1
  expect_true(all(custo_ok))
})

test_that("local=TRUE retorna so modelos ollama", {
  result <- ac_qual_recommend_model(local = TRUE)
  expect_true(all(result$provider == "ollama"))
})

test_that("task='literature' prioriza modelos frontier", {
  r_lit  <- ac_qual_recommend_model(task = "literature", budget = "high", n = 1)
  expect_equal(r_lit$tier[1], "frontier")
})

test_that("justificativa e uma string nao vazia", {
  result <- ac_qual_recommend_model(n = 3)
  expect_true(all(nchar(result$justificativa) > 0))
})
