#' Conectar a um servidor LLM local compatível com OpenAI
#'
#' @description
#' `ac_chat_local()` cria um `Chat` do `ellmer` apontando para um servidor
#' local compatível com a API da OpenAI — LM Studio, llama.cpp
#' (`llama-server`), vLLM, Ollama em modo OpenAI, etc. — sem exigir uma
#' chave de API real.
#'
#' Classificar com um modelo local (via [ac_qual_code()]) elimina o custo
#' por token e mantém os documentos fora de qualquer rede externa, ao
#' preço de gerência própria do servidor: tamanho de contexto, tempo de
#' resposta e throughput passam a depender do hardware local. Use junto
#' com `checkpoint_dir` e `max_retries` em `ac_qual_code()` para rodadas
#' longas, e [ac_estimate_tokens()] para evitar estouro de contexto.
#'
#' @param model Nome/identificador do modelo como o servidor local o
#'   reconhece (ex.: o nome exibido pelo LM Studio, ou o `--model` passado
#'   ao `llama-server`).
#' @param base_url URL base do servidor OpenAI-compatible. Padrão:
#'   `"http://localhost:1234/v1"` (porta padrão do LM Studio).
#' @param api Qual API o servidor expõe: `"chat_completions"` (padrão —
#'   a maioria dos servidores locais: LM Studio, llama.cpp, vLLM) ou
#'   `"responses"` (servidores que implementam a API Responses da
#'   OpenAI).
#' @param temperature Temperatura padrão do chat. `NULL` (padrão): usa o
#'   padrão do servidor.
#' @param system_prompt Prompt de sistema inicial. `NULL` (padrão).
#' @param ... Argumentos adicionais passados a `ellmer::chat_openai()` ou
#'   `ellmer::chat_openai_compatible()`.
#'
#' @return Objeto `Chat` do `ellmer`, pronto para uso em
#'   [ac_qual_code()] (via `chat = ac_chat_local(...)`).
#'
#' @examples
#' \dontrun{
#' # LM Studio rodando localmente, servindo um modelo na porta padrao
#' chat_local <- ac_chat_local(model = "qwen2.5-14b-instruct")
#'
#' cb <- ac_qual_codebook(
#'   name = "tom", instructions = "Classifique o tom.",
#'   categories = list(
#'     positivo = list(definition = "Tom propositivo."),
#'     negativo = list(definition = "Tom critico.")
#'   )
#' )
#' df <- data.frame(id = "d1", texto = "Proponho cooperacao.")
#' corpus <- ac_corpus(df, text = texto, docid = id)
#' coded <- ac_qual_code(corpus, cb, chat = chat_local,
#'                       checkpoint_dir = "checkpoints/")
#' }
#'
#' @concept qualitative
#' @export
ac_chat_local <- function(model,
                           base_url      = "http://localhost:1234/v1",
                           api           = c("chat_completions", "responses"),
                           temperature   = NULL,
                           system_prompt = NULL,
                           ...) {
  if (!requireNamespace("ellmer", quietly = TRUE)) {
    cli::cli_abort("O pacote {.pkg ellmer} \u00e9 necess\u00e1rio.")
  }

  api <- match.arg(api)
  ellmer_exports <- getNamespaceExports("ellmer")
  fn_name <- if (api == "responses") "chat_openai" else "chat_openai_compatible"

  if (!fn_name %in% ellmer_exports) {
    cli::cli_abort(c(
      "{.fn {fn_name}} n\u00e3o dispon\u00edvel nesta vers\u00e3o de {.pkg ellmer}.",
      "i" = "Tente {.code api = \"responses\"} ou atualize o {.pkg ellmer}."
    ))
  }
  fn <- getExportedValue("ellmer", fn_name)

  args <- .ac_chat_local_build_args(
    base_url = base_url, model = model, system_prompt = system_prompt,
    temperature = temperature, dots = list(...),
    formais = names(formals(fn))
  )

  do.call(fn, args)
}


# Monta os argumentos de chat_openai()/chat_openai_compatible() para um
# servidor local. Injeta uma credencial placeholder apenas quando o
# usuario nao forneceu uma via ... E o parametro existir na assinatura
# da funcao de destino -- o nome do parametro de credencial mudou entre
# versoes do ellmer (api_key vs credentials), por isso a checagem usa
# os formais da funcao real em vez de supor um nome fixo.
#' @keywords internal
#' @noRd
.ac_chat_local_build_args <- function(base_url, model, system_prompt,
                                       temperature, dots, formais) {
  args <- c(
    list(base_url = base_url, model = model, system_prompt = system_prompt),
    dots
  )

  if (!is.null(temperature) && is.null(args$params)) {
    args$params <- ellmer::params(temperature = temperature)
  }

  if (is.null(args$api_key) && is.null(args$credentials)) {
    if ("api_key" %in% formais) {
      args$api_key <- "local"
    } else if ("credentials" %in% formais) {
      args$credentials <- function() "local"
    }
  }

  args
}
