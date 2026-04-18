#' Buscar referencias bibliograficas sobre um conceito via LLM
#'
#' @description
#' `ac_qual_search_literature()` usa um modelo de linguagem via `ellmer` para
#' buscar e sintetizar referencias bibliograficas sobre um conceito teorico,
#' retornando um tibble com autores, ano, trechos originais, definicoes em
#' portugues, revista e link.
#'
#' @param concept String. Conceito ou termo teorico a buscar
#'   (ex: `"democratic backsliding"`, `"state capacity"`).
#' @param chat Objeto `Chat` do pacote `ellmer` (ex: `chat_google_gemini()`,
#'   `chat_openai()`, `chat_ollama()`). Quando fornecido, tem prioridade sobre
#'   `model`. Permite usar qualquer provedor suportado pelo `ellmer`.
#' @param model String no formato `"provedor/modelo"` (ex:
#'   `"anthropic/claude-sonnet-4-5"`). Ignorado quando `chat` e fornecido.
#' @param n_refs Inteiro. Numero de referencias a retornar. Padrao: `5`.
#' @param journals Periódicos a considerar. Opcoes:
#'   * `"default"`: lista curada de periodicos de referencia em CP/CS;
#'   * `"all"`: sem restricao de periodico (NULL interno);
#'   * Vetor de strings: lista customizada (ex: `c("default", "RBCS")`).
#' @param lang Idioma das definicoes retornadas. Padrao: `"pt"` (portugues).
#'   Use `"en"` para ingles.
#' @param ... Argumentos adicionais passados a `ellmer::chat()`.
#'
#' @return Tibble com colunas:
#'   * `conceito`: conceito buscado;
#'   * `autor`: autores da referencia;
#'   * `ano`: ano de publicacao;
#'   * `trecho_original`: trecho relevante em ingles;
#'   * `definicao_pt`: definicao sintetizada em portugues;
#'   * `revista`: nome do periodico;
#'   * `link`: DOI ou URL da referencia.
#'
#' @references
#' Gilardi, F.; Alizadeh, M.; Kubli, M. (2023). ChatGPT Outperforms Crowd
#' Workers for Text-Annotation Tasks. *PNAS*, 120(30).
#'
#' @examples
#' \dontrun{
#' # Usando string de modelo
#' lit <- ac_qual_search_literature(
#'   concept = "democratic backsliding",
#'   n_refs  = 3,
#'   model   = "anthropic/claude-sonnet-4-5"
#' )
#'
#' # Usando objeto Chat do ellmer
#' chat_obj <- ellmer::chat_google_gemini(model = "gemini-2.5-flash", echo = "none")
#' lit <- ac_qual_search_literature(
#'   concept = "state capacity",
#'   n_refs  = 5,
#'   chat    = chat_obj
#' )
#' }
#'
#' @concept qualitative
#' @export
ac_qual_search_literature <- function(concept,
                                       chat     = NULL,
                                       model    = "anthropic/claude-sonnet-4-5",
                                       n_refs   = 5L,
                                       journals = "default",
                                       lang     = "pt",
                                       ...) {

  # === Validacoes =============================================================
  if (!is.character(concept) || length(concept) != 1L || nchar(trimws(concept)) == 0L) {
    cli::cli_abort("{.arg concept} deve ser uma string nao vazia.")
  }
  if (!requireNamespace("ellmer", quietly = TRUE)) {
    cli::cli_abort("O pacote {.pkg ellmer} e necessario.")
  }
  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    cli::cli_abort("O pacote {.pkg jsonlite} e necessario.")
  }
  if (!is.null(chat) && !inherits(chat, "Chat")) {
    cli::cli_abort(
      "{.arg chat} deve ser um objeto {.cls Chat} do pacote {.pkg ellmer}."
    )
  }

  n_refs         <- as.integer(n_refs)
  effective_model <- if (!is.null(chat)) chat else model
  journal_list   <- .ac_get_journals(journals)

  # === Montar system prompt ===================================================
  journal_instruction <- if (is.null(journal_list)) {
    "Nao ha restricao de periodico."
  } else {
    paste0(
      "Priorize referencias publicadas nos seguintes periodicos: ",
      paste(journal_list, collapse = ", "), "."
    )
  }

  lang_instruction <- if (lang == "pt") {
    "O campo 'definicao_pt' deve estar em portugues claro e academico."
  } else {
    "O campo 'definicao_pt' deve estar em ingles academico."
  }

  system_prompt <- paste0(
    "Voce e um assistente especializado em ciencia politica e ciencias sociais. ",
    "Sua tarefa e identificar referencias academicas reais e relevantes sobre ",
    "conceitos teoricos, com foco em trabalhos indexados e citados. ",
    "Retorne APENAS JSON valido, sem markdown, sem texto adicional. ",
    lang_instruction
  )

  user_msg <- paste0(
    "Retorne exatamente ", n_refs, " referencias academicas sobre o conceito: '",
    concept, "'.\n\n",
    journal_instruction, "\n\n",
    "Responda APENAS com um array JSON valido, sem markdown:\n",
    "[\n",
    "  {\n",
    "    \"conceito\": \"", concept, "\",\n",
    "    \"autor\": \"Sobrenome, N.\",\n",
    "    \"ano\": 2020,\n",
    "    \"trecho_original\": \"trecho relevante em ingles\",\n",
    "    \"definicao_pt\": \"definicao sintetizada em portugues\",\n",
    "    \"revista\": \"Nome do Periodico\",\n",
    "    \"link\": \"https://doi.org/...\"\n",
    "  }\n",
    "]"
  )

  # === Inicializar chat =======================================================
  if (inherits(effective_model, "Chat")) {
    chat_obj <- effective_model$clone()
    chat_obj$set_system_prompt(system_prompt)
  } else {
    chat_args <- c(
      list(name = effective_model, system_prompt = system_prompt),
      list(...)
    )
    chat_obj <- tryCatch(
      do.call(ellmer::chat, chat_args),
      error = function(e) {
        cli::cli_abort(c(
          "Erro ao inicializar {.pkg ellmer}.",
          "i" = "Modelo: {.val {effective_model}}",
          "x" = conditionMessage(e)
        ))
      }
    )
  }

  # === Chamar LLM =============================================================
  model_label <- if (!is.null(chat)) class(chat)[1] else model
  cli::cli_inform(c(
    "i" = "Buscando {n_refs} referencia{?s} sobre {.val {concept}} com {.val {model_label}}..."
  ))

  resposta <- tryCatch(
    chat_obj$chat(user_msg),
    error = function(e) {
      cli::cli_abort(c(
        "Erro ao consultar o modelo.",
        "x" = conditionMessage(e)
      ))
    }
  )

  # === Parsear JSON ===========================================================
  # Extrair array JSON da resposta
  json_str <- stringr::str_extract(resposta, "\\[.*\\]")
  if (is.na(json_str)) json_str <- resposta

  parsed <- tryCatch(
    jsonlite::fromJSON(json_str, simplifyDataFrame = TRUE),
    error = function(e) {
      cli::cli_abort(c(
        "Nao foi possivel parsear a resposta do modelo como JSON.",
        "x" = conditionMessage(e)
      ))
    }
  )

  # === Garantir colunas esperadas =============================================
  expected_cols <- c("conceito", "autor", "ano", "trecho_original",
                     "definicao_pt", "revista", "link")

  result <- tibble::as_tibble(parsed)

  # Adicionar colunas ausentes como NA
  for (col in expected_cols) {
    if (!col %in% names(result)) {
      result[[col]] <- NA_character_
    }
  }

  # Garantir que conceito esta preenchido
  result$conceito <- concept

  result[, expected_cols]
}


# ============================================================================
# Funcao auxiliar interna
# ============================================================================

#' @keywords internal
#' @noRd
.ac_get_journals <- function(journals) {
  default_journals <- c(
    # Ciencia Politica - internacional
    "American Political Science Review",
    "American Journal of Political Science",
    "Journal of Politics",
    "Comparative Political Studies",
    "World Politics",
    "Comparative Politics",
    "Party Politics",
    "Political Research Quarterly",
    "Legislative Studies Quarterly",
    "Governance",
    # Administracao Publica
    "Public Administration Review",
    "Journal of Public Administration Research and Theory",
    "Publius",
    # Ciencias Sociais - Brasil
    "DADOS",
    "RBCS",
    "Lua Nova",
    "Opiniao Publica",
    "Revista de Sociologia e Politica",
    "Brazilian Political Science Review",
    "Revista Brasileira de Ciencia Politica"
  )

  if (identical(journals, "all")) {
    return(NULL)
  }

  if (identical(journals, "default")) {
    return(default_journals)
  }

  # Vetor customizado: inclui default se solicitado + extras
  result <- character(0)
  if ("default" %in% journals) {
    result <- c(result, default_journals)
  }
  extras <- setdiff(journals, "default")
  result <- unique(c(result, extras))

  result
}
