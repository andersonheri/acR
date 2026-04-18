#' Criar um codebook para análise de conteúdo qualitativa
#'
#' @description
#' `ac_qual_codebook()` cria um livro de códigos estruturado para classificação
#' de textos via LLM. Suporta três modos:
#'
#' * **`"manual"`** (padrão): o pesquisador fornece definições, exemplos e
#'   referências diretamente.
#' * **`"induced"`**: a LLM induz categorias automaticamente a partir de uma
#'   amostra do corpus, sugerindo nomes, definições e exemplos. Útil quando
#'   o pesquisador ainda não tem categorias pré-definidas.
#' * **`"literature"`**: a LLM busca definições na literatura acadêmica
#'   (periódicos nacionais e internacionais de alto impacto), gerando um banco
#'   estruturado com trecho original, tradução, autor, ano, revista e link.
#'   O pesquisador revisa e aprova interativamente antes de usar.
#'
#' @param name Nome identificador do codebook (string).
#' @param instructions Instrução geral para a LLM (o que ela deve fazer com
#'   o texto). Ex: `"Classifique o discurso quanto ao conteúdo iliberal."`.
#' @param categories Lista nomeada de categorias. Cada elemento pode ser:
#'   * **Modo manual**: lista com `definition`, `examples_pos`, `examples_neg`.
#'   * **Modo literature**: lista com `concept` (string de busca em inglês).
#'   * **Modo induced**: ignorado — as categorias são geradas pela LLM.
#' @param corpus Objeto `ac_corpus`. Obrigatório no modo `"induced"`. A LLM
#'   analisa uma amostra de até 20 documentos para induzir as categorias.
#' @param n_categories Inteiro. Número de categorias a induzir no modo
#'   `"induced"`. Padrão: `5L`. Ignorado nos modos `"manual"` e `"literature"`.
#' @param mode `"manual"` (padrão), `"induced"` ou `"literature"`.
#' @param multilabel Lógico. Se `TRUE`, um documento pode pertencer a mais de
#'   uma categoria. Padrão: `FALSE`.
#' @param lang Idioma do corpus: `"pt"` (padrão) ou `"en"`.
#' @param chat Objeto `Chat` do pacote `ellmer` (ex: `chat_google_gemini()`,
#'   `chat_openai()`, `chat_ollama()`). Quando fornecido, tem prioridade sobre
#'   `model`. Permite usar qualquer provedor suportado pelo `ellmer`.
#' @param model Modelo LLM a usar nos modos `"induced"` e `"literature"`.
#'   Padrão: `"anthropic/claude-sonnet-4-5"`.
#' @param journals Periódicos a incluir na busca de literatura. Pode ser:
#'   * `"default"`: lista padrão de periódicos nacionais e internacionais;
#'   * `"all"`: sem restrição de periódico;
#'   * vetor character: `c("default", "RBCS", "Cadernos Gestão Pública")`.
#' @param n_refs Número de referências a buscar por categoria. Padrão: `5`.
#' @param ... Ignorado.
#'
#' @return Objeto de classe `ac_codebook`.
#'
#' @references
#' Krippendorff, K. (2018). *Content Analysis: An Introduction to Its
#' Methodology* (4th ed.). SAGE.
#'
#' Mayring, P. (2022). *Qualitative Content Analysis: A Step-by-Step Guide*.
#' SAGE.
#'
#' @examples
#' # Modo manual
#' cb <- ac_qual_codebook(
#'   name         = "tom_discurso",
#'   instructions = "Classifique o tom geral do discurso.",
#'   categories   = list(
#'     positivo = list(
#'       definition   = "Discurso com tom propositivo e colaborativo.",
#'       examples_pos = c("Proponho que trabalhemos juntos nesta agenda."),
#'       examples_neg = c("Este governo e um desastre completo.")
#'     ),
#'     negativo = list(
#'       definition   = "Discurso com tom critico, confrontacional ou pessimista.",
#'       examples_pos = c("Esta proposta vai arruinar o pais."),
#'       examples_neg = c("Apresento esta emenda para melhorar o texto.")
#'     )
#'   )
#' )
#' cb
#'
#' \dontrun{
#' # Modo induced — categorias sugeridas automaticamente pela LLM
#' corpus <- ac_corpus(
#'   data.frame(id = c("d1","d2","d3"),
#'              texto = c("Texto A", "Texto B", "Texto C")),
#'   text = texto, docid = id
#' )
#' chat_obj <- ellmer::chat_groq(model = "llama-3.3-70b-versatile", echo = "none")
#' cb_ind <- ac_qual_codebook(
#'   name         = "temas_induzidos",
#'   instructions = "Classifique o tema principal do discurso.",
#'   categories   = list(),
#'   corpus       = corpus,
#'   n_categories = 5L,
#'   mode         = "induced",
#'   chat         = chat_obj
#' )
#' print(cb_ind)
#' }
#'
#' @concept qualitative
#' @export
ac_qual_codebook <- function(name, instructions, categories = list(),
    corpus       = NULL,
    n_categories = 5L,
    mode         = c("manual", "induced", "literature"),
    multilabel   = FALSE,
    lang         = "pt",
    chat         = NULL,
    model        = "anthropic/claude-sonnet-4-5",
    journals     = "default",
    n_refs       = 5L,
    ...) {

  mode <- match.arg(mode)

  # === Validacoes =============================================================
  if (!is.character(name) || length(name) != 1L || nchar(name) == 0L) {
    cli::cli_abort("{.arg name} deve ser uma string n\u00e3o vazia.")
  }
  if (!is.character(instructions) || length(instructions) != 1L) {
    cli::cli_abort("{.arg instructions} deve ser uma string.")
  }
  if (mode != "induced") {
    if (!is.list(categories) || is.null(names(categories))) {
      cli::cli_abort("{.arg categories} deve ser uma lista nomeada.")
    }
    if (length(categories) < 2L) {
      cli::cli_abort("{.arg categories} deve ter pelo menos 2 categorias.")
    }
  }
  if (mode == "induced" && (is.null(corpus) || !is_ac_corpus(corpus))) {
    cli::cli_abort(c(
      "{.arg corpus} e obrigatorio no modo {.val induced}.",
      "i" = "Forneca um objeto {.cls ac_corpus} com os textos a analisar."
    ))
  }

  # Resolver provedor: chat= tem prioridade sobre model=
  if (!is.null(chat)) {
    if (!inherits(chat, "Chat")) {
      cli::cli_abort("{.arg chat} deve ser um objeto {.cls Chat} do {.pkg ellmer}.")
    }
    model <- chat
  }

  # === Modo manual ============================================================
  if (mode == "manual") {
    cats <- purrr::map(names(categories), function(cat_name) {
      cat_def <- categories[[cat_name]]
      if (!is.list(cat_def)) {
        cat_def <- list(definition = as.character(cat_def))
      }
      structure(
        list(
          name         = cat_name,
          definition   = cat_def$definition   %||% "",
          examples_pos = cat_def$examples_pos %||% character(0),
          examples_neg = cat_def$examples_neg %||% character(0),
          references   = cat_def$references   %||% character(0),
          concept      = NULL,
          literature   = NULL
        ),
        class = "ac_category"
      )
    })
    names(cats) <- names(categories)
  }

  # === Modo induced ===========================================================
  if (mode == "induced") {
    if (!requireNamespace("ellmer", quietly = TRUE)) {
      cli::cli_abort(c(
        "O pacote {.pkg ellmer} \u00e9 necess\u00e1rio para o modo {.val induced}.",
        "i" = "Instale com {.code install.packages(\"ellmer\")}."
      ))
    }
    if (!requireNamespace("jsonlite", quietly = TRUE)) {
      cli::cli_abort("O pacote {.pkg jsonlite} \u00e9 necess\u00e1rio.")
    }

    n_categories <- as.integer(n_categories)

    # Amostrar textos (max 20 para nao exceder contexto)
    n_sample <- min(20L, nrow(corpus))
    idx      <- sample(seq_len(nrow(corpus)), n_sample)
    textos   <- corpus$text[idx]

    cli::cli_inform(c(
      "i" = "Induzindo codebook a partir de {n_sample} documento{?s}...",
      "i" = "N\u00famero de categorias: {n_categories}"
    ))

    system_prompt <- paste0(
      "Voc\u00ea \u00e9 um especialista em an\u00e1lise de conte\u00fado qualitativa. ",
      "Sua tarefa \u00e9 induzir categorias anal\u00edticas a partir de um corpus de textos. ",
      "Responda APENAS com JSON v\u00e1lido, sem markdown."
    )

    user_msg <- paste0(
      "Analise os textos abaixo e sugira exatamente ", n_categories,
      " categorias para classificar o tema ou posicionamento de cada texto.\n\n",
      "INSTRUCAO GERAL: ", instructions, "\n\n",
      "TEXTOS:\n",
      paste0(seq_along(textos), ". ", textos, collapse = "\n"),
      "\n\nRetorne APENAS este JSON (sem markdown):\n",
      "{\n",
      "  \"categories\": [\n",
      "    {\n",
      "      \"name\": \"nome_snake_case\",\n",
      "      \"definition\": \"Definicao operacional clara em 1-2 frases.\",\n",
      "      \"examples_pos\": [\"exemplo positivo\"],\n",
      "      \"examples_neg\": [\"exemplo negativo\"]\n",
      "    }\n",
      "  ]\n",
      "}"
    )

    # Inicializar chat
    if (inherits(model, "Chat")) {
      chat_obj <- model$clone()
      chat_obj$set_system_prompt(system_prompt)
    } else {
      chat_obj <- tryCatch(
        ellmer::chat(name = model, system_prompt = system_prompt),
        error = function(e) {
          cli::cli_abort(c(
            "Erro ao inicializar {.pkg ellmer}.",
            "x" = conditionMessage(e)
          ))
        }
      )
    }

    resposta <- tryCatch(
      chat_obj$chat(user_msg),
      error = function(e) {
        cli::cli_abort(c(
          "Erro ao consultar o modelo.",
          "x" = conditionMessage(e)
        ))
      }
    )

    json_str <- stringr::str_extract(resposta, "\\{.*\\}")
    if (is.na(json_str)) {
      cli::cli_abort(
        "O modelo n\u00e3o retornou JSON v\u00e1lido. Tente novamente ou use {.val mode = 'manual'}."
      )
    }

    parsed <- tryCatch(
      jsonlite::fromJSON(json_str, simplifyVector = FALSE),
      error = function(e) {
        cli::cli_abort("Erro ao parsear JSON: {conditionMessage(e)}")
      }
    )

    cats_raw <- parsed$categories %||% list()
    if (length(cats_raw) == 0L) {
      cli::cli_abort("O modelo retornou lista de categorias vazia.")
    }

    cats <- purrr::map(cats_raw, function(cat_def) {
      structure(
        list(
          name         = cat_def$name         %||% "sem_nome",
          definition   = cat_def$definition   %||% "",
          examples_pos = unlist(cat_def$examples_pos %||% list()),
          examples_neg = unlist(cat_def$examples_neg %||% list()),
          references   = character(0),
          concept      = NULL,
          literature   = NULL
        ),
        class = "ac_category"
      )
    })
    names(cats) <- purrr::map_chr(cats, "name")

    cli::cli_inform(c(
      "v" = "{length(cats)} categoria{?s} induzida{?s}: {.val {names(cats)}}",
      "i" = "Revise as defini\u00e7\u00f5es com {.fn print} antes de usar em {.fn ac_qual_code}."
    ))
  }

  # === Modo literatura ========================================================
  if (mode == "literature") {
    if (!requireNamespace("ellmer", quietly = TRUE)) {
      cli::cli_abort(c(
        "O pacote {.pkg ellmer} \u00e9 necess\u00e1rio para o modo {.val literature}.",
        "i" = "Instale com {.code install.packages(\"ellmer\")}."
      ))
    }

    cli::cli_h1("acR \u2022 Modo literatura")
    cli::cli_inform(c(
      "i" = "Buscando defini\u00e7\u00f5es na literatura acad\u00eamica para {length(categories)} categoria(s)...",
      "i" = "Modelo: {.val {model}}"
    ))

    journals_list <- .ac_get_journals(journals)

    cats <- purrr::map(names(categories), function(cat_name) {
      cat_def <- categories[[cat_name]]
      concept  <- cat_def$concept %||% cat_name

      cli::cli_h2("Categoria: {.val {cat_name}}")
      cli::cli_inform("Conceito de busca: {.val {concept}}")

      lit <- .ac_search_literature_llm(
        concept  = concept,
        model    = model,
        journals = journals_list,
        n_refs   = n_refs,
        lang     = lang
      )

      cat_result <- .ac_review_category(
        cat_name = cat_name,
        concept  = concept,
        lit      = lit,
        model    = model,
        lang     = lang
      )

      cat_result
    })
    names(cats) <- names(categories)
  }

  # === Montar objeto ac_codebook ==============================================
  structure(
    list(
      name         = name,
      instructions = instructions,
      categories   = cats,
      multilabel   = multilabel,
      lang         = lang,
      mode         = mode,
      model        = if (mode %in% c("induced", "literature")) model else NULL,
      created_at   = Sys.time(),
      needs_review = FALSE
    ),
    class = "ac_codebook"
  )
}


# ============================================================================
# Metodos S3 para ac_codebook
# ============================================================================

#' @export
print.ac_codebook <- function(x, ...) {
  cli::cli_h1("Codebook {.pkg acR}: {.val {x$name}}")
  cli::cli_bullets(c(
    "*" = "Modo: {.val {x$mode}}",
    "*" = "Categorias ({length(x$categories)}): {.val {names(x$categories)}}",
    "*" = "Multilabel: {.val {x$multilabel}}",
    "*" = "Idioma: {.val {x$lang}}",
    "*" = "Criado em: {format(x$created_at, '%d/%m/%Y %H:%M')}"
  ))
  cli::cli_text("")
  cli::cli_text("{.strong Instru\u00e7\u00e3o geral}:")
  cli::cli_text(x$instructions)
  cli::cli_text("")
  cli::cli_text("{.strong Categorias}:")
  for (cat in x$categories) {
    cli::cli_text("  \u2022 {.val {cat$name}}: {cat$definition}")
  }
  invisible(x)
}

#' @export
summary.ac_codebook <- function(object, ...) {
  cat_summary <- purrr::map_dfr(object$categories, function(cat) {
    tibble::tibble(
      categoria     = cat$name,
      tem_definicao = nchar(cat$definition) > 0,
      n_ex_pos      = length(cat$examples_pos),
      n_ex_neg      = length(cat$examples_neg),
      n_refs        = length(cat$references)
    )
  })
  cli::cli_h1("Resumo do codebook {.val {object$name}}")
  print(cat_summary)
  invisible(object)
}


# ============================================================================
# Salvar e carregar codebook em YAML
# ============================================================================

#' Salvar codebook em arquivo YAML
#'
#' @param codebook Objeto `ac_codebook`.
#' @param path Caminho do arquivo `.yaml`. Se omitido, usa `<name>.yaml`.
#' @param ... Ignorado.
#' @export
#' @concept qualitative
ac_qual_save_codebook <- function(codebook, path = NULL, ...) {
  if (!inherits(codebook, "ac_codebook")) {
    cli::cli_abort("{.arg codebook} deve ser um objeto {.cls ac_codebook}.")
  }
  if (!requireNamespace("yaml", quietly = TRUE)) {
    cli::cli_abort(c(
      "O pacote {.pkg yaml} \u00e9 necess\u00e1rio.",
      "i" = "Instale com {.code install.packages(\"yaml\")}."
    ))
  }

  if (is.null(path)) {
    path <- paste0(gsub("[^a-zA-Z0-9_-]", "_", codebook$name), ".yaml")
  }

  obj <- list(
    name         = codebook$name,
    instructions = codebook$instructions,
    multilabel   = codebook$multilabel,
    lang         = codebook$lang,
    mode         = codebook$mode,
    created_at   = format(codebook$created_at, "%Y-%m-%d %H:%M:%S"),
    categories   = purrr::map(codebook$categories, function(cat) {
      list(
        name         = cat$name,
        definition   = cat$definition,
        examples_pos = cat$examples_pos,
        examples_neg = cat$examples_neg,
        references   = cat$references,
        concept      = cat$concept,
        literature   = if (!is.null(cat$literature)) as.list(cat$literature) else NULL
      )
    })
  )

  yaml::write_yaml(obj, path)
  cli::cli_inform("\u2705 Codebook salvo em {.path {path}}")
  invisible(path)
}


#' Carregar codebook de arquivo YAML
#'
#' @param path Caminho do arquivo `.yaml`.
#' @param ... Ignorado.
#' @export
#' @concept qualitative
ac_qual_load_codebook <- function(path, ...) {
  if (!requireNamespace("yaml", quietly = TRUE)) {
    cli::cli_abort("O pacote {.pkg yaml} \u00e9 necess\u00e1rio.")
  }
  if (!file.exists(path)) {
    cli::cli_abort("Arquivo {.path {path}} n\u00e3o encontrado.")
  }

  obj  <- yaml::read_yaml(path)
  cats <- purrr::map(obj$categories, function(cat) {
    structure(
      list(
        name         = cat$name,
        definition   = cat$definition   %||% "",
        examples_pos = cat$examples_pos %||% character(0),
        examples_neg = cat$examples_neg %||% character(0),
        references   = cat$references   %||% character(0),
        concept      = cat$concept,
        literature   = if (!is.null(cat$literature)) tibble::as_tibble(cat$literature) else NULL
      ),
      class = "ac_category"
    )
  })
  names(cats) <- purrr::map_chr(obj$categories, "name")

  structure(
    list(
      name         = obj$name,
      instructions = obj$instructions,
      categories   = cats,
      multilabel   = obj$multilabel %||% FALSE,
      lang         = obj$lang       %||% "pt",
      mode         = obj$mode       %||% "manual",
      model        = obj$model,
      created_at   = as.POSIXct(obj$created_at),
      needs_review = FALSE
    ),
    class = "ac_codebook"
  )
}


# ============================================================================
# Funcoes auxiliares internas
# ============================================================================

#' @keywords internal
#' @noRd
.ac_get_journals <- function(journals) {
  default_intl <- c(
    "American Political Science Review",
    "Comparative Political Studies",
    "Journal of Democracy",
    "Democratization",
    "Political Research Quarterly",
    "Comparative Politics",
    "World Politics",
    "European Journal of Political Research"
  )
  default_br <- c(
    "DADOS",
    "Opini\u00e3o P\u00fablica",
    "Brazilian Political Science Review",
    "Revista de Sociologia e Pol\u00edtica",
    "Lua Nova",
    "Cadernos CRH",
    "Revista Brasileira de Ci\u00eancias Sociais"
  )
  default_all <- c(default_intl, default_br)

  if (identical(journals, "all"))     return(NULL)
  if (identical(journals, "default")) return(default_all)

  extra <- journals[journals != "default"]
  if ("default" %in% journals) return(unique(c(default_all, extra)))
  unique(extra)
}


#' @keywords internal
#' @noRd
.ac_search_literature_llm <- function(concept, model, journals, n_refs, lang) {

  journals_str <- if (is.null(journals)) {
    "qualquer peri\u00f3dico acad\u00eamico relevante"
  } else {
    paste(journals, collapse = "; ")
  }

  lang_str <- if (lang == "pt") "portugu\u00eas brasileiro" else "English"

  prompt <- paste0(
    "Voc\u00ea \u00e9 um especialista em Ci\u00eancia Pol\u00edtica e Ci\u00eancias Sociais.\n\n",
    "Busque ", n_refs, " refer\u00eancias acad\u00eamicas de alto impacto sobre: '", concept, "'.\n\n",
    "Priorize: ", journals_str, ".\n\n",
    "Retorne APENAS JSON v\u00e1lido:\n",
    "[\n",
    "  {\n",
    "    \"conceito\": \"", concept, "\",\n",
    "    \"autor\": \"Sobrenome, Iniciais.\",\n",
    "    \"ano\": 2020,\n",
    "    \"trecho_original\": \"trecho exato\",\n",
    "    \"definicao_pt\": \"tradu\u00e7\u00e3o em ", lang_str, "\",\n",
    "    \"revista\": \"nome da revista\",\n",
    "    \"link\": \"DOI ou null\"\n",
    "  }\n",
    "]"
  )

  chat     <- ellmer::chat(name = model)
  resposta <- tryCatch(chat$chat(prompt), error = function(e) {
    cli::cli_abort(c("Erro ao consultar a LLM.", "x" = conditionMessage(e)))
  })

  json_str <- stringr::str_extract(resposta, "\\[.*\\]")
  if (is.na(json_str)) {
    cli::cli_warn("LLM n\u00e3o retornou JSON v\u00e1lido.")
    return(.empty_literature_tibble())
  }

  parsed <- tryCatch(
    jsonlite::fromJSON(json_str, simplifyDataFrame = TRUE),
    error = function(e) { cli::cli_warn("Erro ao parsear JSON."); NULL }
  )

  if (is.null(parsed) || nrow(parsed) == 0L) return(.empty_literature_tibble())

  expected_cols <- c("conceito","autor","ano","trecho_original","definicao_pt","revista","link")
  for (col in expected_cols) if (!col %in% names(parsed)) parsed[[col]] <- NA_character_

  cli::cli_warn(c(
    "!" = "Refer\u00eancias geradas por LLM. Verifique antes de citar."
  ))

  tibble::as_tibble(parsed[, expected_cols])
}


#' @keywords internal
#' @noRd
.empty_literature_tibble <- function() {
  tibble::tibble(
    conceito        = character(0),
    autor           = character(0),
    ano             = integer(0),
    trecho_original = character(0),
    definicao_pt    = character(0),
    revista         = character(0),
    link            = character(0)
  )
}


#' @keywords internal
#' @noRd
.ac_review_category <- function(cat_name, concept, lit, model, lang) {

  if (nrow(lit) > 0L) {
    definicao_gerada <- .ac_generate_definition(cat_name, concept, lit, model, lang)
    exemplos         <- .ac_generate_examples(cat_name, definicao_gerada$definition, model, lang)
  } else {
    definicao_gerada <- list(definition = "")
    exemplos         <- list(pos = character(0), neg = character(0))
  }

  if (interactive()) {
    aprovado        <- FALSE
    definicao_atual <- definicao_gerada$definition
    ex_pos_atual    <- exemplos$pos
    ex_neg_atual    <- exemplos$neg

    while (!aprovado) {
      cli::cli_rule()
      cli::cli_h2("CATEGORIA: {.val {cat_name}}")
      cli::cli_text("{.strong Defini\u00e7\u00e3o}: {definicao_atual}")
      opcao <- toupper(trimws(readline("[E]ditar  [R]egerar  [A]provar > ")))

      if (opcao == "A") {
        aprovado <- TRUE
      } else if (opcao == "E") {
        linhas <- character(0)
        repeat {
          linha <- readline("")
          if (nchar(linha) == 0L && length(linhas) > 0L) break
          linhas <- c(linhas, linha)
        }
        definicao_atual <- paste(linhas, collapse = " ")
      } else if (opcao == "R") {
        definicao_gerada <- .ac_generate_definition(cat_name, concept, lit, model, lang)
        exemplos         <- .ac_generate_examples(cat_name, definicao_gerada$definition, model, lang)
        definicao_atual  <- definicao_gerada$definition
        ex_pos_atual     <- exemplos$pos
        ex_neg_atual     <- exemplos$neg
      }
    }
  } else {
    cli::cli_warn("Modo n\u00e3o-interativo: revis\u00e3o da categoria {.val {cat_name}} pulada.")
    definicao_atual <- definicao_gerada$definition
    ex_pos_atual    <- exemplos$pos
    ex_neg_atual    <- exemplos$neg
  }

  structure(
    list(
      name         = cat_name,
      definition   = definicao_atual,
      examples_pos = ex_pos_atual,
      examples_neg = ex_neg_atual,
      references   = if (nrow(lit) > 0L) paste0(lit$autor, " (", lit$ano, "). ", lit$revista, ".") else character(0),
      concept      = concept,
      literature   = lit
    ),
    class = "ac_category"
  )
}


#' @keywords internal
#' @noRd
.ac_generate_definition <- function(cat_name, concept, lit, model, lang) {
  lang_str <- if (lang == "pt") "portugu\u00eas brasileiro" else "English"
  refs_str <- paste(purrr::map_chr(seq_len(nrow(lit)), function(i) {
    paste0(lit$autor[i], " (", lit$ano[i], "): \"", lit$trecho_original[i], "\"")
  }), collapse = "\n")

  prompt <- paste0(
    "Com base nas refer\u00eancias sobre '", concept, "':\n\n", refs_str, "\n\n",
    "Redija em ", lang_str, " uma defini\u00e7\u00e3o operacional de 2-4 frases para '", cat_name, "'. ",
    "Retorne APENAS a defini\u00e7\u00e3o."
  )
  chat       <- ellmer::chat(name = model)
  definition <- tryCatch(chat$chat(prompt), error = function(e) "")
  list(definition = trimws(definition))
}


#' @keywords internal
#' @noRd
.ac_generate_examples <- function(cat_name, definicao, model, lang) {
  lang_str <- if (lang == "pt") "portugu\u00eas brasileiro" else "English"
  prompt   <- paste0(
    "Para a categoria '", cat_name, "': ", definicao, "\n\n",
    "Gere JSON: {\"pos\":[\"ex1\",\"ex2\",\"ex3\"],\"neg\":[\"ex1\",\"ex2\",\"ex3\"]}.\n",
    "Idioma: ", lang_str, ". Retorne APENAS o JSON."
  )
  chat   <- ellmer::chat(name = model)
  resp   <- tryCatch(chat$chat(prompt), error = function(e) "")
  parsed <- tryCatch(jsonlite::fromJSON(resp), error = function(e) list(pos=character(0),neg=character(0)))
  list(pos = parsed$pos %||% character(0), neg = parsed$neg %||% character(0))
}
