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
#' @param model String no formato `"provedor/modelo"`. Ignorado quando `chat`
#'   e fornecido.
#' @param n_refs Inteiro. Numero de referencias a retornar. Padrao: `5`.
#' @param journals Periodicos a considerar. Opcoes:
#'   * `"default"`: lista curada de periodicos de referencia em CP/CS/AP;
#'   * `"all"`: sem restricao de periodico;
#'   * Vetor de strings: lista customizada (ex: `c("default", "RBCS")`).
#' @param lang Idioma das definicoes sintetizadas. Padrao: `"pt"`.
#' @param min_citations Inteiro. Numero minimo de citacoes. Padrao: `0`.
#' @param ... Argumentos adicionais passados a `ellmer::chat()`.
#'
#' @return Tibble com colunas: `conceito`, `autor`, `ano`, `revista`,
#'   `n_citacoes`, `trecho_original`, `definicao_pt`, `abstract_original`,
#'   `link`.
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
#' chat_obj <- ellmer::chat_groq(model = "llama-3.3-70b-versatile", echo = "none")
#'
#' lit <- ac_qual_search_literature(
#'   concept       = "democratic backsliding",
#'   n_refs        = 5,
#'   min_citations = 50,
#'   chat          = chat_obj
#' )
#' print(lit[, c("autor", "ano", "revista", "n_citacoes", "definicao_pt")])
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

  if (!is.character(concept) || length(concept) != 1L ||
      nchar(trimws(concept)) == 0L) {
    cli::cli_abort("{.arg concept} deve ser uma string nao vazia.")
  }
  if (!requireNamespace("httr2",    quietly = TRUE)) cli::cli_abort("O pacote {.pkg httr2} e necessario.")
  if (!requireNamespace("ellmer",   quietly = TRUE)) cli::cli_abort("O pacote {.pkg ellmer} e necessario.")
  if (!requireNamespace("jsonlite", quietly = TRUE)) cli::cli_abort("O pacote {.pkg jsonlite} e necessario.")
  if (!is.null(chat) && !inherits(chat, "Chat")) {
    cli::cli_abort("{.arg chat} deve ser um objeto {.cls Chat} do pacote {.pkg ellmer}.")
  }

  n_refs        <- as.integer(n_refs)
  min_citations <- as.integer(min_citations)
  journal_list  <- .ac_get_journals(journals)

  # === Etapa 1: resolver IDs de venue no OpenAlex ===========================
  venue_ids <- NULL
  if (!is.null(journal_list) && length(journal_list) > 0L) {
    cli::cli_inform(c("i" = "Resolvendo IDs de periodicos no OpenAlex..."))
    venue_ids <- .ac_resolve_venue_ids(journal_list)
    if (length(venue_ids) == 0L) venue_ids <- NULL
  }

  # === Etapa 2: buscar no OpenAlex ==========================================
  cli::cli_inform(c("i" = "Buscando no OpenAlex: {.val {concept}}..."))

  raw_results <- .ac_openalex_search(
    concept       = concept,
    n_refs        = n_refs * 3L,
    venue_ids     = venue_ids,
    min_citations = min_citations
  )

  # Fallback: sem resultados com filtro de venue -> tenta sem restricao de periodico
  if (nrow(raw_results) == 0L && !is.null(venue_ids)) {
    cli::cli_inform(c(
      "!" = "Sem resultados nos periodicos selecionados. Expandindo busca para todos os periodicos..."
    ))
    raw_results <- .ac_openalex_search(
      concept       = concept,
      n_refs        = n_refs * 3L,
      venue_ids     = NULL,
      min_citations = min_citations
    )
  }

  if (nrow(raw_results) == 0L) {
    cli::cli_warn(c(
      "Nenhum resultado encontrado no OpenAlex para {.val {concept}}.",
      "i" = "Tente reduzir {.arg min_citations}."
    ))
    return(.ac_empty_lit_tibble())
  }

  raw_results <- utils::head(raw_results, n_refs)

  # === Etapa 3: sintetizar com LLM ==========================================
  effective_model <- if (!is.null(chat)) chat else model
  model_label     <- if (!is.null(chat)) class(chat)[1] else model

  cli::cli_inform(c(
    "i" = "Sintetizando {nrow(raw_results)} abstract{?s} com {.val {model_label}}..."
  ))

  lang_instruction <- if (lang == "pt") "em portugues claro e academico" else "in clear academic English"

  system_prompt <- paste0(
    "Voce e um assistente especializado em ciencia politica e ciencias sociais. ",
    "Dado um abstract academico, extraia o trecho mais relevante para o conceito ",
    "solicitado e sintetize o argumento principal ", lang_instruction, " em 2-3 frases. ",
    "Responda APENAS com JSON valido, sem markdown."
  )

  if (inherits(effective_model, "Chat")) {
    chat_obj <- effective_model$clone()
    chat_obj$set_system_prompt(system_prompt)
  } else {
    chat_args <- c(list(name = effective_model, system_prompt = system_prompt), list(...))
    chat_obj  <- tryCatch(
      do.call(ellmer::chat, chat_args),
      error = function(e) cli::cli_abort(c("Erro ao inicializar {.pkg ellmer}.", "x" = conditionMessage(e)))
    )
  }

  syntheses <- purrr::map(seq_len(nrow(raw_results)), function(i) {
    abstract <- raw_results$abstract_original[i]
    if (is.na(abstract) || nchar(trimws(abstract)) == 0L) {
      return(list(trecho_original = NA_character_, definicao_pt = NA_character_))
    }

    user_msg <- paste0(
      "Conceito: '", concept, "'\n\nAbstract:\n", abstract, "\n\n",
      "Responda com:\n{\"trecho_original\": \"trecho de 1-2 frases\", \"definicao_pt\": \"sintese ", lang_instruction, "\"}"
    )

    resposta <- tryCatch(chat_obj$chat(user_msg), error = function(e) {
      cli::cli_warn("Erro ao sintetizar referencia {i}: {conditionMessage(e)}")
      NULL
    })

    if (is.null(resposta)) return(list(trecho_original = NA_character_, definicao_pt = NA_character_))

    json_str <- stringr::str_extract(resposta, "\\{[^\\{\\}]*\\}")
    if (is.na(json_str)) json_str <- resposta

    parsed <- tryCatch(jsonlite::fromJSON(json_str), error = function(e) NULL)
    if (is.null(parsed)) return(list(trecho_original = NA_character_, definicao_pt = NA_character_))

    list(
      trecho_original = parsed$trecho_original %||% NA_character_,
      definicao_pt    = parsed$definicao_pt    %||% NA_character_
    )
  })

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

#' Resolver IDs de venue no OpenAlex para uma lista de nomes de periodicos
#' @keywords internal
#' @noRd
.ac_resolve_venue_ids <- function(journal_names) {
  known_ids <- c(
    "American Political Science Review"        = "S176007004",
    "American Journal of Political Science"    = "S4306400194",
    "Journal of Politics"                      = "S97012182",
    "Comparative Political Studies"            = "S105556297",
    "World Politics"                           = "S107750594",
    "Comparative Politics"                     = "S20832085",
    "Party Politics"                           = "S91191231",
    "Political Research Quarterly"             = "S145574959",
    "Legislative Studies Quarterly"            = "S136718778",
    "Governance"                               = "S202326791",
    "Political Behavior"                       = "S68143283",
    "Electoral Studies"                        = "S92879769",
    "European Journal of Political Research"   = "S141830798",
    "West European Politics"                   = "S47764010",
    "Journal of Democracy"                     = "S151119180",
    "Democratization"                          = "S165682519",
    "Latin American Politics and Society"      = "S2764807396",
    "Latin American Research Review"           = "S144985611",
    "Journal of Latin American Studies"        = "S60395866",
    "Public Administration Review"             = "S185592501",
    "Journal of Public Administration Research and Theory" = "S56945143",
    "Publius"                                  = "S95979234",
    "Policy Sciences"                          = "S113017997",
    "Public Management Review"                 = "S134484086",
    "American Sociological Review"             = "S4306400986",
    "American Journal of Sociology"            = "S4306400806",
    "PNAS"                                     = "S4306402512",
    "PLOS ONE"                                 = "S202381698",
    "DADOS"                                    = "S146986746",
    "Brazilian Political Science Review"       = "S4210177801",
    "Opiniao Publica"                          = "S4210183823",
    "Revista de Sociologia e Politica"         = "S4210199732",
    "Revista de Administracao Publica"         = "S4210186268"
  )

  ids <- character(0)
  for (journal in journal_names) {
    journal_norm <- trimws(journal)
    match_idx <- which(tolower(names(known_ids)) == tolower(journal_norm))
    if (length(match_idx) > 0L) {
      ids <- c(ids, known_ids[match_idx[1]])
      next
    }
    resp <- tryCatch({
      r <- httr2::request("https://api.openalex.org/sources") |>
        httr2::req_url_query(search = journal_norm, per_page = 1L) |>
        httr2::req_timeout(10L) |>
        httr2::req_perform()
      httr2::resp_body_json(r, simplifyVector = TRUE)
    }, error = function(e) NULL)

    if (!is.null(resp) && length(resp$results) > 0L && nrow(resp$results) > 0L) {
      raw_id   <- resp$results$id[1]
      id_clean <- sub("https://openalex.org/", "", raw_id)
      ids <- c(ids, id_clean)
    }
  }
  unique(ids)
}


#' @keywords internal
#' @noRd
.ac_openalex_search <- function(concept, n_refs, venue_ids, min_citations) {

  base_url <- "https://api.openalex.org/works"

  filters <- "type:article"
  if (min_citations > 0L) {
    filters <- paste0(filters, ",cited_by_count:>", min_citations)
  }
  if (!is.null(venue_ids) && length(venue_ids) > 0L) {
    venue_filter <- paste0(
      "primary_location.source.id:",
      paste(venue_ids, collapse = "|")
    )
    filters <- paste0(filters, ",", venue_filter)
  }

  req <- httr2::request(base_url) |>
    httr2::req_url_query(
      search     = concept,
      `per-page` = min(n_refs, 50L),
      sort       = "cited_by_count:desc",
      filter     = filters,
      select     = paste(
        "id", "title", "authorships", "publication_year",
        "primary_location", "cited_by_count", "abstract_inverted_index", "doi",
        sep = ","
      ),
      mailto     = "acR-package@r-pkg"
    ) |>
    httr2::req_headers(
      "User-Agent" = "acR R package (https://github.com/andersonheri/acR)"
    ) |>
    httr2::req_retry(max_tries = 3L, backoff = ~ 2) |>
    httr2::req_timeout(30L)

  resp <- tryCatch(
    httr2::req_perform(req),
    error = function(e) {
      cli::cli_warn(c("Erro ao acessar a API do OpenAlex.", "x" = conditionMessage(e)))
      NULL
    }
  )

  if (is.null(resp)) return(.ac_empty_lit_tibble())

  body <- tryCatch(
    httr2::resp_body_json(resp, simplifyVector = FALSE),
    error = function(e) NULL
  )

  if (is.null(body) || length(body$results) == 0L) return(.ac_empty_lit_tibble())

  rows <- purrr::map(body$results, function(work) {
    autores <- purrr::map_chr(
      work$authorships %||% list(),
      function(a) a$author$display_name %||% NA_character_
    )
    autor_str <- if (length(autores) == 0L)      NA_character_
    else if (length(autores) <= 3L) paste(autores, collapse = "; ")
    else paste0(autores[1], " et al.")

    revista  <- work$primary_location$source$display_name %||% NA_character_
    abstract <- .ac_reconstruct_abstract(work$abstract_inverted_index)
    titulo   <- work$title %||% ""
    doi      <- work$doi %||% NA_character_
    link     <- if (!is.na(doi)) doi else paste0("https://openalex.org/", work$id)

    tibble::tibble(
      titulo            = titulo,
      autor             = autor_str,
      ano               = work$publication_year %||% NA_integer_,
      revista           = revista,
      n_citacoes        = work$cited_by_count %||% 0L,
      abstract_original = abstract,
      link              = link
    )
  })

  df_results <- dplyr::bind_rows(rows)

  if (nrow(df_results) > 0L) {
    conceito_regex <- paste(strsplit(concept, "\\s+")[[1]], collapse = "|")
    relevante <- grepl(
      conceito_regex,
      paste(df_results$titulo, df_results$abstract_original),
      ignore.case = TRUE
    )
    df_results <- df_results[relevante, , drop = FALSE]
  }

  if ("titulo" %in% names(df_results)) df_results$titulo <- NULL

  df_results
}


#' @keywords internal
#' @noRd
.ac_reconstruct_abstract <- function(inverted_index) {
  if (is.null(inverted_index) || length(inverted_index) == 0L) {
    return(NA_character_)
  }
  pos_word <- purrr::imap(inverted_index, function(pos_list, word) {
    posicoes <- as.integer(unlist(pos_list))
    data.frame(pos = posicoes, word = word, stringsAsFactors = FALSE)
  })

  df <- do.call(rbind, pos_word)
  if (is.null(df) || nrow(df) == 0L) return(NA_character_)

  df <- df[order(df$pos), ]
  paste(df$word, collapse = " ")
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
    "Public Administration Review",
    "Journal of Public Administration Research and Theory",
    "Publius",
    "Policy Sciences",
    "Journal of Policy Analysis and Management",
    "Public Management Review",
    "Journal of European Public Policy",
    "American Sociological Review",
    "American Journal of Sociology",
    "Annual Review of Sociology",
    "Science",
    "Nature Human Behaviour",
    "PNAS",
    "PLOS ONE",
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

  if (identical(journals, "all"))     return(NULL)
  if (identical(journals, "default")) return(default_journals)

  result <- character(0)
  if ("default" %in% journals) result <- c(result, default_journals)
  extras <- setdiff(journals, "default")
  unique(c(result, extras))
}
