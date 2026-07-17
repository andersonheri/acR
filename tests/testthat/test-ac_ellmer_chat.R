# Testes de .ac_ellmer_chat() -- helper interno de dispatch.
# Nao chamamos rede: verificamos comportamento de fronteira.
# Robusto a duas versoes de ellmer (com e sem `chat`).

test_that(".ac_ellmer_chat rejeita formato invalido de model", {
  skip_if_not_installed("ellmer")

  # 'sem_barra' viola o formato provider/model.
  # Em ambos os ambientes (ellmer com ou sem chat) deve abortar.
  expect_error(
    acR:::.ac_ellmer_chat(name = "sem_barra")
  )
})

test_that(".ac_ellmer_chat rejeita provider desconhecido", {
  skip_if_not_installed("ellmer")

  # Provider bogus deve abortar (mensagem varia entre versoes de ellmer).
  expect_error(
    acR:::.ac_ellmer_chat(name = "provedorxyz/algum-modelo")
  )
})

test_that(".ac_ellmer_chat aceita providers conhecidos sem abortar em roteamento", {
  skip_if_not_installed("ellmer")

  # Testamos apenas que a chamada NAO aborta com uma mensagem de
  # "provider desconhecido" para providers documentados. A chamada em
  # si pode falhar por API key ausente, mas isso e OK -- estamos
  # validando o dispatch, nao a conexao.
  providers_conhecidos <- c("anthropic", "groq", "openai", "google",
                            "mistral", "ollama", "deepseek", "openrouter",
                            "gemini", "claude")

  for (prov in providers_conhecidos) {
    err_msg <- tryCatch({
      acR:::.ac_ellmer_chat(name = paste0(prov, "/test-model"))
      ""
    }, error = function(e) conditionMessage(e))

    err_msg <- if (is.character(err_msg)) err_msg else ""

    # Nao pode conter marcadores de "provider desconhecido"
    # (aceita erros por API key, rede, etc.)
    expect_false(
      grepl("desconhecid|nao suportad|Can't find provider|unknown provider",
            err_msg, ignore.case = TRUE),
      label = paste0("provider '", prov, "' rejeitado indevidamente: ", err_msg)
    )
  }
})
