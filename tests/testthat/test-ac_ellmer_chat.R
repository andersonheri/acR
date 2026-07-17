# Testes de .ac_ellmer_chat() -- helper interno de dispatch para provedores
# de ellmer. Nao chamamos rede: verificamos validacoes e routing.

test_that(".ac_ellmer_chat rejeita formato invalido de model", {
  skip_if_not_installed("ellmer")

  expect_error(
    acR:::.ac_ellmer_chat(name = "sem_barra"),
    "provider/model"
  )
})

test_that(".ac_ellmer_chat rejeita provider desconhecido", {
  skip_if_not_installed("ellmer")

  expect_error(
    acR:::.ac_ellmer_chat(name = "provedorxyz/algum-modelo"),
    "nao suportado"
  )
})

test_that(".ac_ellmer_chat aceita todos os providers documentados", {
  skip_if_not_installed("ellmer")

  # Providers listados no switch (nao precisamos chamar a rede;
  # apenas checar que o dispatch nao aborta ANTES de tentar iniciar o chat).
  providers <- c("anthropic", "groq", "openai", "google", "gemini",
                 "mistral", "ollama", "openrouter", "deepseek", "azure",
                 "bedrock", "databricks", "github", "perplexity",
                 "portkey", "snowflake", "vllm", "huggingface", "claude")

  for (prov in providers) {
    # Chamamos com um model bogus; esperamos que a funcao NAO aborte com
    # "provider nao suportado" antes de chegar na criacao do chat.
    # A criacao pode falhar por API key ausente -- isso e OK.
    err <- tryCatch(
      acR:::.ac_ellmer_chat(name = paste0(prov, "/test-model")),
      error = function(e) conditionMessage(e)
    )
    expect_false(
      grepl("nao suportado", err %||% ""),
      info = paste0("provider ", prov, " deveria ser reconhecido")
    )
  }
})
