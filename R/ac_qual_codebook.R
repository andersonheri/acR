#' Criar um codebook para análise de conteúdo qualitativa
#'
#' @description
#' `ac_qual_codebook()` cria um livro de códigos estruturado para classificação
#' de textos via LLM. Suporta dois modos:
#'
#' * **`"manual"`** (padrão): o pesquisador fornece definições, exemplos e
#'   referências diretamente.
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
#'   * **Modo literatura**: lista com `concept` (string de busca em inglês).
#' @param mode `"manual"` (padrão) ou `"literature"`.
#' @param multilabel Lógico. Se `TRUE`, um documento pode pertencer a mais de
#'   uma categoria. Padrão: `FALSE`.
#' @param lang Idioma do corpus: `"pt"` (padrão) ou `"en"`.
#' @param chat Objeto `Chat` do pacote `ellmer` (ex: `chat_google_gemini()`,
#'   `chat_openai()`, `chat_ollama()`). Quando fornecido, tem prioridade sobre
#'   `model`. Permite usar qualquer provedor suportado pelo `ellmer`.
#' @param model Modelo LLM a usar no modo `"literature"`. Padrão:
#'   `"anthropic/claude-sonnet-4-5"`.
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
#'       examples_neg = c("Este governo é um desastre completo.")
#'     ),
#'     negativo = list(
#'       definition   = "Discurso com tom crítico, confrontacional ou pessimista.",
#'       examples_pos = c("Esta proposta vai arruinar o país."),
#'       examples_neg = c("Apresento esta emenda para melhorar o texto.")
#'     )
#'   )
#' )
#' cb
#'
#' @concept qualitative
#' @export
ac_qual_codebook <- function(name, instructions, categories,
    mode       = c("manual", "literature"),
    multilabel = FALSE,
    lang       = "pt",
    chat       = NULL,
    model      = "anthropic/claude-sonnet-4-5",
    journals   = "default",
    n_refs     = 5L,
    ...) {

  mode <- match.arg(mode)

  # === Validações ============================================================
  if (!is.character(name) || length(name) != 1L || nchar(name) == 0L) {
    cli::cli_abort("{.arg name} deve ser uma string n\u00e3o vazia.")
  }
  if (!is.character(instructions) || length(instructions) != 1L) {
    cli::cli_abort("{.arg instructions} deve ser uma string.")
  }
  if (!is.list(categories) || is.null(names(categories))) {
    cli::cli_abort("{.arg categories} deve ser uma lista nomeada.")
  }
  if (length(categories) < 2L) {
    cli::cli_abort("{.arg categories} deve ter pelo menos 2 categorias.")
  }

  # === Modo manual ===========================================================
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

  # === Modo literatura ========================================================
  # Resolver provedor: chat= tem prioridade sobre model=
  if (!is.null(chat)) {
    if (!inherits(chat, "Chat")) {
      cli::cli_abort("{.arg chat} deve ser um objeto {.cls Chat} do {.pkg ellmer}.")
    }
    model <- chat
  }
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

      # Buscar literatura
      lit <- .ac_search_literature_llm(
        concept  = concept,
        model    = model,
        journals = journals_list,
        n_refs   = n_refs,
        lang     = lang
      )

      # Revisão interativa
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
  result <- structure(
    list(
      name         = name,
      instructions = instructions,
      categories   = cats,
      multilabel   = multilabel,
      lang         = lang,
      mode         = mode,
      model        = if (mode == "literature") model else NULL,
      created_at   = Sys.time(),
      needs_review = FALSE
    ),
    class = "ac_codebook"
  )

  result
}


# ============================================================================
# Métodos S3 para ac_codebook
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
      categoria    = cat$name,
      tem_definicao = nchar(cat$definition) > 0,
      n_ex_pos     = length(cat$examples_pos),
      n_ex_neg     = length(cat$examples_neg),
      n_refs       = length(cat$references)
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

  # Converter para lista simples (YAML-serializável)
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
        literature   = if (!is.null(cat$literature)) {
          as.list(cat$literature)
        } else NULL
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

  obj <- yaml::read_yaml(path)

  cats <- purrr::map(obj$categories, function(cat) {
    structure(
      list(
        name         = cat$name,
        definition   = cat$definition   %||% "",
        examples_pos = cat$examples_pos %||% character(0),
        examples_neg = cat$examples_neg %||% character(0),
        references   = cat$references   %||% character(0),
        concept      = cat$concept,
        literature   = if (!is.null(cat$literature)) {
          tibble::as_tibble(cat$literature)
        } else NULL
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
# Busca de literatura via LLM
# ============================================================================

#' Buscar literatura acadêmica para um conceito
#'
#' @description
#' `ac_qual_search_literature()` usa uma LLM para buscar definições de um
#' conceito na literatura acadêmica, retornando um tibble estruturado com
#' trecho original, tradução, autor, ano, revista e link.
#'
#' @param concept String com o conceito a buscar (preferencialmente em inglês).
#' @param chat Objeto `Chat` do pacote `ellmer` (ex: `chat_google_gemini()`,
#'   `chat_openai()`, `chat_ollama()`). Quando fornecido, tem prioridade sobre
#'   `model`. Permite usar qualquer provedor suportado pelo `ellmer`.
#' @param model Modelo LLM. Padrão: `"anthropic/claude-sonnet-4-5"`.
#' @param journals Periódicos a incluir. Padrão: `"default"`.
#' @param n_refs Número de referências. Padrão: `5`.
#' @param lang Idioma da tradução. Padrão: `"pt"`.
#' @param ... Ignorado.
#'
#' @return Tibble com colunas: `conceito`, `autor`, `ano`, `trecho_original`,
#'   `definicao_pt`, `revista`, `link`.
#'
#' @note
#' ATENCAO: as referencias sao geradas por LLM com base no
#' conhecimento de treinamento. Verifique todas as referencias antes de citar.
#' Use \code{ac_qual_verify_references()} (disponivel em versao futura) para
#' checagem automatica.
#'
#' @concept qualitative
#' @export
ac_qual_search_literature <- function(concept,
                                       model    = "anthropic/claude-sonnet-4-5",
                                       journals = "default",
                                       n_refs   = 5L,
                                       lang     = "pt",
                                       ...) {

  if (!requireNamespace("ellmer", quietly = TRUE)) {
    cli::cli_abort("O pacote {.pkg ellmer} \u00e9 necess\u00e1rio.")
  }

  journals_list <- .ac_get_journals(journals)
  .ac_search_literature_llm(
    concept  = concept,
    model    = model,
    journals = journals_list,
    n_refs   = n_refs,
    lang     = lang
  )
}


# ============================================================================
# Funções auxiliares internas
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

  if (identical(journals, "all")) {
    return(NULL)  # sem restrição
  }
  if (identical(journals, "default")) {
    return(default_all)
  }
  # Vetor customizado: pode incluir "default"
  extra <- journals[journals != "default"]
  if ("default" %in% journals) {
    return(unique(c(default_all, extra)))
  }
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
    "Busque ", n_refs, " refer\u00eancias acad\u00eamicas de alto impacto que definem ou discutem o conceito de: '", concept, "'.\n\n",
    "Priorize artigos publicados nos seguintes peri\u00f3dicos: ", journals_str, ".\n\n",
    "Para cada refer\u00eancia, forne\u00e7a EXATAMENTE no formato JSON abaixo (sem markdown, sem texto extra):\n",
    "[\n",
    "  {\n",
    "    \"conceito\": \"", concept, "\",\n",
    "    \"autor\": \"Sobrenome, Iniciais. & Sobrenome, Iniciais.\",\n",
    "    \"ano\": 2020,\n",
    "    \"trecho_original\": \"Trecho exato em ingl\u00eas ou portugu\u00eas com a defini\u00e7\u00e3o do conceito (m\u00e1x 3 frases)\",\n",
    "    \"definicao_pt\": \"Tradu\u00e7\u00e3o fiel para ", lang_str, " do trecho acima\",\n",
    "    \"revista\": \"Nome exato da revista\",\n",
    "    \"link\": \"DOI ou URL se dispon\u00edvel, ou null\"\n",
    "  }\n",
    "]\n\n",
    "IMPORTANTE: retorne APENAS o JSON v\u00e1lido, sem nenhum texto antes ou depois."
  )

  chat <- ellmer::chat(name = model)
  resposta <- tryCatch(
    chat$chat(prompt),
    error = function(e) {
      cli::cli_abort(c(
        "Erro ao consultar a LLM.",
        "x" = conditionMessage(e)
      ))
    }
  )

  # Extrair JSON da resposta
  json_str <- stringr::str_extract(resposta, "\\[.*\\]")
  if (is.na(json_str)) {
    cli::cli_warn("LLM n\u00e3o retornou JSON v\u00e1lido. Retornando tibble vazio.")
    return(.empty_literature_tibble())
  }

  parsed <- tryCatch(
    jsonlite::fromJSON(json_str, simplifyDataFrame = TRUE),
    error = function(e) {
      cli::cli_warn("Erro ao parsear JSON da LLM: {conditionMessage(e)}")
      return(NULL)
    }
  )

  if (is.null(parsed) || nrow(parsed) == 0L) {
    return(.empty_literature_tibble())
  }

  # Garantir colunas esperadas
  expected_cols <- c("conceito", "autor", "ano", "trecho_original",
                     "definicao_pt", "revista", "link")
  for (col in expected_cols) {
    if (!col %in% names(parsed)) parsed[[col]] <- NA_character_
  }

  result <- tibble::as_tibble(parsed[, expected_cols])

  # Aviso obrigatório
  cli::cli_warn(c(
    "!" = "Refer\u00eancias geradas por LLM com base no conhecimento de treinamento.",
    "i" = "Verifique TODAS as refer\u00eancias antes de citar em publica\u00e7\u00f5es.",
    "i" = "Use {.fn ac_qual_verify_references} (dispon\u00edvel em vers\u00e3o futura) para checagem autom\u00e1tica."
  ))

  result
}


#' @keywords internal
#' @noRd
.empty_literature_tibble <- function() {
  tibble::tibble(
    conceito         = character(0),
    autor            = character(0),
    ano              = integer(0),
    trecho_original  = character(0),
    definicao_pt     = character(0),
    revista          = character(0),
    link             = character(0)
  )
}


#' @keywords internal
#' @noRd
.ac_review_category <- function(cat_name, concept, lit, model, lang) {

  # Gerar definição consolidada a partir da literatura
  if (nrow(lit) > 0L) {
    definicao_gerada <- .ac_generate_definition(
      cat_name = cat_name,
      concept  = concept,
      lit      = lit,
      model    = model,
      lang     = lang
    )
    exemplos <- .ac_generate_examples(
      cat_name  = cat_name,
      definicao = definicao_gerada$definition,
      model     = model,
      lang      = lang
    )
  } else {
    definicao_gerada <- list(definition = "", summary = "")
    exemplos         <- list(pos = character(0), neg = character(0))
  }

  # Revisão interativa (só em modo interativo)
  if (interactive()) {
    aprovado <- FALSE
    definicao_atual <- definicao_gerada$definition
    ex_pos_atual    <- exemplos$pos
    ex_neg_atual    <- exemplos$neg

    while (!aprovado) {
      cli::cli_rule()
      cli::cli_h2("CATEGORIA: {.val {cat_name}}")
      cli::cli_text("")
      cli::cli_text("{.strong Defini\u00e7\u00e3o gerada}:")
      cli::cli_text(definicao_atual)
      cli::cli_text("")
      cli::cli_text("{.strong Exemplos positivos}:")
      for (i in seq_along(ex_pos_atual)) {
        cli::cli_text("  {i}. {ex_pos_atual[i]}")
      }
      cli::cli_text("")
      cli::cli_text("{.strong Exemplos negativos}:")
      for (i in seq_along(ex_neg_atual)) {
        cli::cli_text("  {i}. {ex_neg_atual[i]}")
      }
      cli::cli_text("")
      if (nrow(lit) > 0L) {
        cli::cli_text("{.strong Refer\u00eancias utilizadas}:")
        for (i in seq_len(min(3L, nrow(lit)))) {
          cli::cli_text("  \u2022 {lit$autor[i]} ({lit$ano[i]}). {lit$revista[i]}.")
        }
        cli::cli_text("")
        cli::cli_warn(c(
          "!" = "Refer\u00eancias geradas por LLM. Verifique antes de citar."
        ))
      }
      cli::cli_rule()

      opcao <- readline(
        "[E]ditar defini\u00e7\u00e3o  [R]egerar  [A]provar  > "
      )
      opcao <- toupper(trimws(opcao))

      if (opcao == "A") {
        aprovado <- TRUE

      } else if (opcao == "E") {
        cli::cli_text("Cole a nova defini\u00e7\u00e3o (pressione Enter duas vezes para finalizar):")
        linhas <- character(0)
        repeat {
          linha <- readline("")
          if (nchar(linha) == 0L && length(linhas) > 0L) break
          linhas <- c(linhas, linha)
        }
        definicao_atual <- paste(linhas, collapse = " ")

      } else if (opcao == "R") {
        cli::cli_inform("Regerando...")
        definicao_gerada <- .ac_generate_definition(
          cat_name = cat_name,
          concept  = concept,
          lit      = lit,
          model    = model,
          lang     = lang
        )
        exemplos        <- .ac_generate_examples(
          cat_name  = cat_name,
          definicao = definicao_gerada$definition,
          model     = model,
          lang      = lang
        )
        definicao_atual <- definicao_gerada$definition
        ex_pos_atual    <- exemplos$pos
        ex_neg_atual    <- exemplos$neg
      }
    }
  } else {
    cli::cli_warn(c(
      "!" = "Modo n\u00e3o-interativo: revis\u00e3o da categoria {.val {cat_name}} pulada.",
      "i" = "Use {.fn ac_qual_review} para revisar o codebook ap\u00f3s a cria\u00e7\u00e3o."
    ))
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
      references   = if (nrow(lit) > 0L) {
        paste0(lit$autor, " (", lit$ano, "). ", lit$revista, ".")
      } else character(0),
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

  refs_str <- paste(
    purrr::map_chr(seq_len(nrow(lit)), function(i) {
      paste0(lit$autor[i], " (", lit$ano[i], "): \"", lit$trecho_original[i], "\"")
    }),
    collapse = "\n"
  )

  prompt <- paste0(
    "Com base nas seguintes refer\u00eancias acad\u00eamicas sobre o conceito '", concept, "':\n\n",
    refs_str, "\n\n",
    "Redija em ", lang_str, " uma defini\u00e7\u00e3o operacional clara e precisa ",
    "para a categoria '", cat_name, "' que possa ser usada como crit\u00e9rio de classifica\u00e7\u00e3o ",
    "em an\u00e1lise de conte\u00fado qualitativa de discursos pol\u00edticos.\n\n",
    "A defini\u00e7\u00e3o deve:\n",
    "1. Ter entre 2-4 frases\n",
    "2. Ser operacional (especificar o que deve ser observado no texto)\n",
    "3. Ser distinta das demais categorias\n\n",
    "Retorne APENAS a defini\u00e7\u00e3o, sem t\u00edtulo ou explica\u00e7\u00f5es adicionais."
  )

  chat <- ellmer::chat(name = model)
  definition <- tryCatch(
    chat$chat(prompt),
    error = function(e) ""
  )

  list(definition = trimws(definition))
}


#' @keywords internal
#' @noRd
.ac_generate_examples <- function(cat_name, definicao, model, lang) {
  lang_str <- if (lang == "pt") "portugu\u00eas brasileiro" else "English"

  prompt <- paste0(
    "Para a categoria '", cat_name, "' com a seguinte defini\u00e7\u00e3o:\n\n",
    definicao, "\n\n",
    "Gere em formato JSON:\n",
    "{\n",
    "  \"pos\": [\"exemplo 1\", \"exemplo 2\", \"exemplo 3\"],\n",
    "  \"neg\": [\"exemplo 1\", \"exemplo 2\", \"exemplo 3\"]\n",
    "}\n\n",
    "Onde:\n",
    "- \"pos\": 3 exemplos de trechos de discursos pol\u00edticos que S\u00c3O desta categoria\n",
    "- \"neg\": 3 exemplos de trechos que N\u00c3O S\u00c3O desta categoria\n",
    "Idioma: ", lang_str, ".\n",
    "Retorne APENAS o JSON, sem markdown."
  )

  chat   <- ellmer::chat(name = model)
  resp   <- tryCatch(chat$chat(prompt), error = function(e) "")
  parsed <- tryCatch(
    jsonlite::fromJSON(resp),
    error = function(e) list(pos = character(0), neg = character(0))
  )

  list(
    pos = parsed$pos %||% character(0),
    neg = parsed$neg %||% character(0)
  )
}
