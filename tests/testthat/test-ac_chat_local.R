# Testes para ac_chat_local() (item 12 da revisao de producao: provedor
# local de primeira classe para LM Studio / llama.cpp / vLLM).

test_that("ac_chat_local() rejeita api invalida", {
  skip_if_not_installed("ellmer")
  expect_error(
    ac_chat_local(model = "x", api = "bla"),
    regexp = "should be one of|'arg' should be"
  )
})

test_that(".ac_chat_local_build_args() injeta api_key quando o parametro existe e nao foi fornecido", {
  args <- acR:::.ac_chat_local_build_args(
    base_url = "http://localhost:1234/v1", model = "m", system_prompt = NULL,
    temperature = NULL, dots = list(),
    formais = c("base_url", "model", "system_prompt", "api_key", "params")
  )
  expect_equal(args$api_key, "local")
  expect_null(args$credentials)
})

test_that(".ac_chat_local_build_args() injeta credentials quando api_key nao existe na assinatura", {
  args <- acR:::.ac_chat_local_build_args(
    base_url = "http://localhost:1234/v1", model = "m", system_prompt = NULL,
    temperature = NULL, dots = list(),
    formais = c("base_url", "model", "system_prompt", "credentials", "params")
  )
  expect_null(args$api_key)
  expect_true(is.function(args$credentials))
  expect_equal(args$credentials(), "local")
})

test_that(".ac_chat_local_build_args() nao sobrescreve credencial explicita do usuario", {
  args <- acR:::.ac_chat_local_build_args(
    base_url = "http://localhost:1234/v1", model = "m", system_prompt = NULL,
    temperature = NULL, dots = list(api_key = "minha-chave"),
    formais = c("base_url", "model", "system_prompt", "api_key")
  )
  expect_equal(args$api_key, "minha-chave")
})

test_that(".ac_chat_local_build_args() injeta ellmer::params(temperature) quando ausente", {
  skip_if_not_installed("ellmer")
  args <- acR:::.ac_chat_local_build_args(
    base_url = "http://localhost:1234/v1", model = "m", system_prompt = "sys",
    temperature = 0.4, dots = list(),
    formais = c("base_url", "model", "system_prompt", "api_key", "params")
  )
  expect_false(is.null(args$params))
  expect_equal(args$system_prompt, "sys")
})

test_that("ac_chat_local() aborta com mensagem clara se chat_openai_compatible nao existe no ellmer instalado", {
  skip_if_not_installed("ellmer")
  skip_if(
    "chat_openai_compatible" %in% getNamespaceExports("ellmer"),
    "Esta versao do ellmer ja expoe chat_openai_compatible; nada a testar aqui."
  )
  expect_error(
    ac_chat_local(model = "m", api = "chat_completions"),
    regexp = "chat_openai_compatible"
  )
})
