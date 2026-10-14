#' Estimar número de tokens de um texto
#'
#' @description
#' `ac_estimate_tokens()` estima o número de tokens de entrada que um texto
#' vai consumir, usando uma heurística de caracteres por token. Útil para
#' prever o custo de uma rodada de [ac_qual_code()] ou para detectar, antes
#' de enviar ao LLM, documentos que provavelmente excederão a janela de
#' contexto do modelo.
#'
#' É uma estimativa deliberadamente barata: não faz nenhuma chamada de rede
#' nem depende do tokenizador exato de um modelo específico (que varia por
#' provedor e às vezes nem é público). Para calibrar a heurística contra um
#' modelo real, use [ac_calibrate_tokens()] com uma amostra pequena de
#' textos.
#'
#' @param text Vetor de caracteres com os textos.
#' @param chat Ignorado nesta versão (reservado para uma futura estimativa
#'   específica de provedor via `chat$token_count()`). Receber o argumento
#'   já na assinatura evita quebrar código que o passar.
#' @param chars_per_token Caracteres por token, usado para a estimativa.
#'   Padrão `3.2` (razoável para português via BPE; varia por tokenizador
#'   e idioma). Calibre com [ac_calibrate_tokens()] se precisar de
#'   precisão maior para um modelo específico.
#'
#' @return Vetor inteiro com a estimativa de tokens por texto.
#'
#' @examples
#' ac_estimate_tokens("Este e um texto de exemplo para estimar tokens.")
#' ac_estimate_tokens(c("texto curto", "um texto um pouco mais longo que o anterior"))
#'
#' @concept qualitative
#' @export
ac_estimate_tokens <- function(text, chat = NULL, chars_per_token = 3.2) {
  as.integer(ceiling(nchar(text) / chars_per_token))
}


#' Calibrar a razão caracteres/token contra um modelo real
#'
#' @description
#' `ac_calibrate_tokens()` mede, contra um `Chat` real, quantos tokens de
#' entrada um conjunto de textos de amostra realmente consome, e devolve a
#' razão caracteres/token observada — para usar como `chars_per_token` em
#' [ac_estimate_tokens()] (ou como `chars_per_token` em `ac_qual_code()` /
#' futuras funções que dependam da estimativa).
#'
#' Faz uma chamada real ao modelo por texto de amostra (com uma mensagem
#' mínima, para medir só o consumo de tokens de entrada), então usa poucos
#' textos — o suficiente para calibrar, não uma amostra representativa de
#' todo o corpus.
#'
#' @param chat_factory Função `function(temperature, system_prompt) Chat`
#'   que constrói o chat a usar (o mesmo padrão aceito por `model` em
#'   [ac_qual_code()]). Permite calibrar contra o provedor/modelo exato que
#'   será usado na rodada real.
#' @param textos Vetor de caracteres com textos de amostra (poucos bastam;
#'   ideal variar o tamanho).
#'
#' @return Número: a mediana de caracteres por token observada na amostra.
#'
#' @examples
#' \dontrun{
#' chat_factory <- function(temperature, system_prompt) {
#'   ellmer::chat_openai(model = "gpt-4.1-mini", temperature = temperature,
#'                       system_prompt = system_prompt, echo = "none")
#' }
#' razao <- ac_calibrate_tokens(chat_factory, c("texto curto de teste.",
#'                                              "um texto um pouco mais longo de teste."))
#' coded <- ac_qual_code(corpus, cb, model = chat_factory)
#' }
#'
#' @concept qualitative
#' @export
ac_calibrate_tokens <- function(chat_factory, textos) {
  if (!is.function(chat_factory)) {
    cli::cli_abort("{.arg chat_factory} deve ser uma função {.code function(temperature, system_prompt) Chat}.")
  }

  uso <- vapply(textos, function(tx) {
    tx_cortado <- substr(tx, 1L, 20000L)
    ch <- chat_factory(temperature = 0, system_prompt = "Responda OK")
    ch$chat(tx_cortado)
    tk <- ch$get_tokens()
    as.numeric(utils::tail(tk$input, 1L))
  }, numeric(1))

  stats::median(nchar(substr(textos, 1L, 20000L)) / uso, na.rm = TRUE)
}
