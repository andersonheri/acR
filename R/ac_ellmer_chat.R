#' @keywords internal
#' @noRd
.ac_ellmer_chat <- function(name, ...) {
  if (!requireNamespace("ellmer", quietly = TRUE))
    cli::cli_abort("Pacote {.pkg ellmer} necessario.")

  ellmer_exports <- getNamespaceExports("ellmer")

  if ("chat" %in% ellmer_exports) {
    return(do.call(getExportedValue("ellmer", "chat"),
                   c(list(name = name), list(...))))
  }

  parts <- strsplit(name, "/", fixed = TRUE)[[1]]
  if (length(parts) < 2L) {
    cli::cli_abort(c(
      "Modelo deve estar no formato {.val 'provider/model'}.",
      "i" = "Ex: {.val 'anthropic/claude-sonnet-4-5'} ou {.val 'groq/llama-3.3-70b-versatile'}.",
      "x" = "Recebido: {.val {name}}."
    ))
  }
  provider <- parts[1]
  model_id <- paste(parts[-1], collapse = "/")

  fn_name <- switch(provider,
    "anthropic"  = "chat_anthropic",
    "claude"     = "chat_claude",
    "groq"       = "chat_groq",
    "openai"     = "chat_openai",
    "google"     = "chat_google_gemini",
    "gemini"     = "chat_google_gemini",
    "mistral"    = "chat_mistral",
    "ollama"     = "chat_ollama",
    "openrouter" = "chat_openrouter",
    "deepseek"   = "chat_deepseek",
    "azure"      = "chat_azure",
    "bedrock"    = "chat_bedrock",
    "databricks" = "chat_databricks",
    "github"     = "chat_github",
    "perplexity" = "chat_perplexity",
    "portkey"    = "chat_portkey",
    "snowflake"  = "chat_snowflake",
    "vllm"       = "chat_vllm",
    "huggingface"= "chat_huggingface",
    NULL
  )

  if (is.null(fn_name) || !fn_name %in% ellmer_exports) {
    cli::cli_abort(c(
      "Provider {.val {provider}} nao suportado por esta versao de {.pkg ellmer}.",
      "i" = "Providers disponiveis: {.val {grep('^chat_', ellmer_exports, value = TRUE)}}."
    ))
  }

  fn <- getExportedValue("ellmer", fn_name)
  do.call(fn, c(list(model = model_id), list(...)))
}
