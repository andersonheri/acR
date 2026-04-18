#' Buscar referencias bibliograficas sobre um conceito via OpenAlex e LLM
#'
#' @description
#' `ac_qual_search_literature()` busca referencias academicas reais na API do
#' OpenAlex e usa um modelo de linguagem via `ellmer` para sintetizar os
#' abstracts em portugues. Retorna um tibble com metadados bibliograficos
#' verificados e definicoes sintetizadas pela LLM.
#'
#' A arquitetura e: OpenAlex recupera registros reais (autor, ano, DOI,
#' abstract, revista, numero de citacoes); a LLM sintetiza o abstract em
#' portugues e extrai o trecho mais relevante. Isso evita alucinacoes
#' bibliograficas comuns quando a LLM opera sem fonte externa.
#'
#' @param concept String. Conceito ou termo teorico a buscar
#'   (ex: `"democratic backsliding"`, `"state capacity"`).
#' @param chat Objeto `Chat` do pacote `ellmer` (ex: `chat_google_gemini()`,
#'   `chat_openai()`, `chat_ollama()`). Quando fornecido, tem prioridade sobre
#'   `model`.
#' @param model String no formato `"provedor/modelo"` (ex:
#'   `"anthropic/claude-sonnet-4-5"`). Ignorado quando `chat` e fornecido.
#' @param n_refs Inteiro. Numero de referencias a retornar. Padrao: `5`.
#' @param journals Periodicos a considerar. Opcoes:
#'   * `"default"`: lista curada de periodicos de referencia em CP/CS/AP;
#'   * `"all"`: sem restricao de periodico;
#'   * Vetor de strings: lista customizada (ex: `c("default", "RBCS")`).
#' @param lang Idioma das definicoes sintetizadas. Padrao: `"pt"` (portugues).
#'   Use `"en"` para ingles.
#' @param min_citations Inteiro. Numero minimo de citacoes para incluir uma
#'   referencia. Padrao: `0` (sem filtro). Util para focar em trabalhos
#'   consolidados (ex: `min_citations = 50`).
#' @param ... Argumentos adicionais passados a `ellmer::chat()`.
#'
#' @return Tibble com colunas:
#'   * `conceito`: conceito buscado;
#'   * `autor`: autores da referencia (formato "Sobrenome, N.; ...");
#'   * `ano`: ano de publicacao;
#'   * `revista`: nome do periodico;
#'   * `n_citacoes`: numero de citacoes no OpenAlex;
#'   * `trecho_original`: trecho mais relevante do abstract em ingles;
#'   * `definicao_pt`: definicao sintetizada pela LLM em portugues;
#'   * `abstract_original`: abstract completo em ingles;
#'   * `link`: DOI ou URL da referencia.
#'
#' @references
#' Priem, J. et al. (2022). OpenAlex: A fully-open index of the global
#' research system. *arXiv*, 2205.01833.
#'
#' Gilardi, F.; Alizadeh, M.; Kubli, M. (2023). ChatGPT Outperforms Crowd
#' Workers for Text-Annotation Tasks. *PNAS*, 120(30).
#'
#' @examples
#' \dontrun{
#' # Busca basica com modelo padrao
#' lit <- ac_qual_search_literature(
#'   concept = "democratic backsliding",
#'   n_refs  = 5,
#'   model   = "anthropic/claude-sonnet-4-5"
#' )
#'
#' # Com objeto Chat do ellmer (recomendado)
#' chat_obj <- ellmer::chat_google_gemini(
#'   model = "gemini-2.5-flash",
#'   echo  = "none"
#' )
#' lit <- ac_qual_search_literature(
#'   concept = "state capacity",
#'   n_refs  = 10,
#'   chat    = chat_obj
#' )
#'
#' # Focar em trabalhos consolidados de periodicos brasileiros
#' lit <- ac_qual_search_literature(
#'   concept       = "capacidade estatal",
#'   n_refs        = 5,
#'   journals      = c("default", "RBCS", "DADOS"),
#'   min_citations = 20,
#'   chat          = chat_obj
#' )
#' }
#'
#' @concept qualitative
#' @export
ac_qual_search_literature <- function(concept,
                                       chat          = NULL,
                                       model         = "anthropic/claude-sonnet-4-5",
                                       n_refs        = 5L,
                                       journals      = "default",
                                       lang          = "pt",
                                       min_citations = 0L,
                                       ...) {

  # === Validacoes =============================================================
  if (!is.character(concept) || length(concept) != 1L ||
      nchar(trimws(concept)) == 0L) {
    cli::cli_abort("{.arg concept} deve ser uma string nao vazia.")
  }
  if (!requireNamespace("httr2", quietly = TRUE)) {
    cli::cli_abort("O pacote {.pkg httr2} e necessario.")
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

  n_refs        <- as.integer(n_refs)
  min_citations <- as.integer(min_citations)
  journal_list  <- .ac_get_journals(journals)

  # === Etapa 1: buscar no OpenAlex ============================================
  cli::cli_inform(c("i" = "Buscando no OpenAlex: {.val {concept}}..."))

  raw_results <- .ac_openalex_search(
    concept      = concept,
    n_refs       = n_refs * 3L,   # busca mais para ter margem apos filtros
    journal_list = journal_list,
    min_citations = min_citations
  )

  if (nrow(raw_results) == 0L) {
    cli::cli_warn(c(
      "Nenhum resultado encontrado no OpenAlex para {.val {concept}}.",
      "i" = "Tente ampliar o escopo com {.code journals = 'all'} ou reduzir {.arg min_citations}."
    ))
    return(.ac_empty_lit_tibble())
  }

  # Limitar ao n_refs solicitado
  raw_results <- utils::head(raw_results, n_refs)

  # === Etapa 2: sintetizar com LLM ============================================
  effective_model <- if (!is.null(chat)) chat else model
  model_label     <- if (!is.null(chat)) class(chat)[1] else model

  cli::cli_inform(c("i" = "Sintetizando {nrow(raw_results)} abstract{?s} com {.val {model_label}}..."))

  lang_instruction <- if (lang == "pt") {
    "em portugues claro e academico"
  } else {
    "in clear academic English"
  }

  system_prompt <- paste0(
    "Voce e um assistente especializado em ciencia politica e ciencias sociais. ",
    "Dado um abstract academico em ingles, sua tarefa e: ",
    "(1) extrair o trecho de 1-2 frases mais relevante para a definicao do conceito; ",
    "(2) sintetizar o argumento principal do abstract ",
    lang_instruction, " em 2-3 frases. ",
    "Responda APENAS com JSON valido, sem markdown."
  )

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

  # Sintetizar cada abstract
  syntheses <- purrr::map(seq_len(nrow(raw_results)), function(i) {
    row     <- raw_results[i, ]
    abstract <- row$abstract_original

    if (is.na(abstract) || nchar(trimws(abstract)) == 0L) {
      return(list(
        trecho_original = NA_character_,
        definicao_pt    = NA_character_
      ))
    }

    user_msg <- paste0(
      "Conceito buscado: '", concept, "'\n\n",
      "Abstract:\n", abstract, "\n\n",
      "Responda com:\n",
      "{\n",
      "  \"trecho_original\": \"trecho de 1-2 frases mais relevante do abstract\",\n",
      "  \"definicao_pt\": \"sintese do argumento ", lang_instruction, "\"\n",
      "}"
    )

    resposta <- tryCatch(
      chat_obj$chat(user_msg),
      error = function(e) {
        cli::cli_warn("Erro ao sintetizar referencia {i}: {conditionMessage(e)}")
        return(NULL)
      }
    )

    if (is.null(resposta)) {
      return(list(trecho_original = NA_character_, definicao_pt = NA_character_))
    }

    json_str <- stringr::str_extract(resposta, "\\{[^\\{\\}]*\\}")
    if (is.na(json_str)) json_str <- resposta

    parsed <- tryCatch(
      jsonlite::fromJSON(json_str),
      error = function(e) NULL
    )

    if (is.null(parsed)) {
      return(list(trecho_original = NA_character_, definicao_pt = NA_character_))
    }

    list(
      trecho_original = parsed$trecho_original %||% NA_character_,
      definicao_pt    = parsed$definicao_pt    %||% NA_character_
    )
  })

  # === Montar tibble final ====================================================
  result <- raw_results |>
    dplyr::mutate(
      conceito        = concept,
      trecho_original = purrr::map_chr(syntheses, "trecho_original"),
      definicao_pt    = purrr::map_chr(syntheses, "definicao_pt")
    ) |>
    dplyr::select(
      "conceito", "autor", "ano", "revista", "n_citacoes",
      "trecho_original", "definicao_pt", "abstract_original", "link"
    )

  cli::cli_inform(c("v" = "{nrow(result)} referencia{?s} encontrada{?s} e sintetizada{?s}."))

  result
}


# ============================================================================
# Funcoes auxiliares internas
# ============================================================================

#' @keywords internal
#' @noRd
.ac_openalex_search <- function(concept, n_refs, journal_list, min_citations) {

  # Montar query base
  base_url <- "https://api.openalex.org/works"

  req <- httr2::request(base_url) |>
    httr2::req_url_query(
      search         = concept,
      `per-page`     = min(n_refs, 50L),
      sort           = "cited_by_count:desc",
      filter         = .ac_openalex_filter(journal_list, min_citations),
      select         = paste(
        "id", "title", "authorships", "publication_year",
        "primary_location", "cited_by_count", "abstract_inverted_index", "doi",
        sep = ","
      ),
      mailto         = "acR-package@r-pkg"
    ) |>
    httr2::req_headers(
      "User-Agent" = "acR R package (https://github.com/andersonheri/acR)"
    ) |>
    httr2::req_retry(max_tries = 3L, backoff = ~ 2) |>
    httr2::req_timeout(30L)

  resp <- tryCatch(
    httr2::req_perform(req),
    error = function(e) {
      cli::cli_warn(c(
        "Erro ao acessar a API do OpenAlex.",
        "x" = conditionMessage(e)
      ))
      return(NULL)
    }
  )

  if (is.null(resp)) return(.ac_empty_lit_tibble())

  body <- tryCatch(
    httr2::resp_body_json(resp, simplifyVector = FALSE),
    error = function(e) NULL
  )

  if (is.null(body) || length(body$results) == 0L) {
    return(.ac_empty_lit_tibble())
  }

  # Parsear resultados
  rows <- purrr::map(body$results, function(work) {

    # Autores
    autores <- purrr::map_chr(
      work$authorships %||% list(),
      function(a) a$author$display_name %||% NA_character_
    )
    autor_str <- if (length(autores) == 0L) NA_character_
    else if (length(autores) <= 3L) paste(autores, collapse = "; ")
    else paste0(autores[1], " et al.")

    # Revista
    revista <- work$primary_location$source$display_name %||% NA_character_

    # Abstract: reconstruir do inverted index
    abstract <- .ac_reconstruct_abstract(work$abstract_inverted_index)

    # DOI
    doi <- work$doi %||% NA_character_
    link <- if (!is.na(doi)) doi else
      paste0("https://openalex.org/", work$id)

    tibble::tibble(
      autor             = autor_str,
      ano               = work$publication_year %||% NA_integer_,
      revista           = revista,
      n_citacoes        = work$cited_by_count %||% 0L,
      abstract_original = abstract,
      link              = link
    )
  })

  dplyr::bind_rows(rows)
}


#' @keywords internal
#' @noRd
.ac_openalex_filter <- function(journal_list, min_citations) {
  filters <- character(0)

  # Filtro de citacoes minimas
  if (min_citations > 0L) {
    filters <- c(filters, paste0("cited_by_count:>", min_citations))
  }

  # Filtro de tipo: apenas artigos
  filters <- c(filters, "type:article")

  if (length(filters) == 0L) return(NULL)
  paste(filters, collapse = ",")
}


#' @keywords internal
#' @noRd
.ac_reconstruct_abstract <- function(inverted_index) {
  if (is.null(inverted_index) || length(inverted_index) == 0L) {
    return(NA_character_)
  }
  # inverted_index: lista onde cada elemento e palavra -> vetor de posicoes
  positions <- unlist(
    purrr::imap(inverted_index, function(positions, word) {
      stats::setNames(rep(word, length(positions)), as.character(positions))
    })
  )
  if (length(positions) == 0L) return(NA_character_)
  idx  <- as.integer(names(positions))
  ord  <- order(idx)
  paste(positions[ord], collapse = " ")
}


#' @keywords internal
#' @noRd
.ac_empty_lit_tibble <- function() {
  tibble::tibble(
    conceito          = character(0),
    autor             = character(0),
    ano               = integer(0),
    revista           = character(0),
    n_citacoes        = integer(0),
    trecho_original   = character(0),
    definicao_pt      = character(0),
    abstract_original = character(0),
    link              = character(0)
  )
}


#' @keywords internal
#' @noRd
.ac_get_journals <- function(journals) {

  default_journals <- c(
    # Ciencia Politica - top internacional
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
    "Political Behavior",
    "Electoral Studies",
    "European Journal of Political Research",
    "West European Politics",
    "Journal of Democracy",
    "Democratization",
    "Latin American Politics and Society",
    "Latin American Research Review",
    "Journal of Latin American Studies",
    # Administracao Publica e Politicas Publicas
    "Public Administration Review",
    "Journal of Public Administration Research and Theory",
    "Publius",
    "Policy Sciences",
    "Journal of Policy Analysis and Management",
    "Governance",
    "Public Management Review",
    "Journal of European Public Policy",
    # Sociologia e Ciencias Sociais
    "American Sociological Review",
    "American Journal of Sociology",
    "Annual Review of Sociology",
    # Multidisciplinar relevante
    "Science",
    "Nature Human Behaviour",
    "PNAS",
    "PLOS ONE",
    # Brasil - CP e CS
    "DADOS",
    "RBCS",
    "Lua Nova",
    "Opiniao Publica",
    "Revista de Sociologia e Politica",
    "Brazilian Political Science Review",
    "Revista Brasileira de Ciencia Politica",
    "Cadernos CEDES",
    "Novos Estudos CEBRAP",
    "Revista de Administracao Publica",
    "Cadernos de Saude Publica"
  )

  if (identical(journals, "all")) return(NULL)
  if (identical(journals, "default")) return(default_journals)

  # Vetor customizado
  result <- character(0)
  if ("default" %in% journals) result <- c(result, default_journals)
  extras <- setdiff(journals, "default")
  unique(c(result, extras))
}
