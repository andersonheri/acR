#' Criar um codebook para análise de conteúdo qualitativa
#'
#' @description
#' `ac_qual_codebook()` cria um livro de códigos estruturado para classificação
#' de textos via LLM. Suporta três modos:
#'
#' * **`"manual"`** (padrão): o pesquisador fornece definições, exemplos e
#'   referências diretamente.
#' * **`"induced"`**: a LLM induz categorias automaticamente a partir de uma
#'   amostra do corpus, sugerindo nomes, definições e exemplos.
#' * **`"literature"`**: a LLM busca definições na literatura acadêmica,
#'   gerando um banco estruturado com trecho original, tradução, autor, ano,
#'   revista e link. O pesquisador revisa e aprova interativamente.
#'
#' @param name Nome identificador do codebook (string).
#' @param instructions Instrução geral para a LLM.
#' @param categories Lista nomeada de categorias. Cada elemento pode conter:
#'   * `definition`: definição operacional da categoria (obrigatório).
#'   * `examples_pos`: vetor de exemplos positivos (recomendado).
#'   * `examples_neg`: vetor de exemplos negativos (recomendado).
#'   * `references`: vetor de referências bibliográficas (opcional).
#'   * `weight`: número entre 0 e 1 indicando a importância relativa da
#'     categoria para a LLM (padrão: `1`). Categorias raras ou difíceis
#'     podem receber peso maior para instrução extra.
#' @param corpus Objeto `ac_corpus`. Obrigatório no modo `"induced"`.
#' @param n_categories Inteiro. Número de categorias a induzir. Padrão: `5L`.
#' @param mode `"manual"` (padrão), `"induced"` ou `"literature"`.
#' @param multilabel Lógico. Se `TRUE`, um documento pode pertencer a mais de
#'   uma categoria. Padrão: `FALSE`.
#' @param lang Idioma do corpus: `"pt"` (padrão) ou `"en"`.
#' @param chat Objeto `Chat` do pacote `ellmer`. Tem prioridade sobre `model`.
#' @param model Modelo LLM. Padrão: `"anthropic/claude-sonnet-4-5"`.
#' @param journals Periódicos para busca de literatura.
#' @param n_refs Número de referências por categoria. Padrão: `5`.
#' @param check_overlap Se `TRUE`, verifica sobreposição semântica entre
#'   definições e avisa o pesquisador. Requer `chat` ou `model`. Padrão: `FALSE`.
#' @param ... Ignorado.
#'
#' @return Objeto de classe `ac_codebook`.
#'
#' @references
#' Krippendorff, K. (2018). *Content Analysis: An Introduction to Its
#' Methodology* (4th ed.). SAGE.
#'
#' Sampaio, R. C., & Lycarião, D. (2021). *Análise de conteúdo categorial:
#' manual de aplicação*. Brasília: ENAP.
#'
#' @examples
#' cb <- ac_qual_codebook(
#'   name         = "tom_discurso",
#'   instructions = "Classifique o tom geral do discurso.",
#'   categories   = list(
#'     positivo = list(
#'       definition   = "Discurso com tom propositivo e colaborativo.",
#'       examples_pos = c("Proponho que trabalhemos juntos nesta agenda."),
#'       examples_neg = c("Este governo e um desastre completo."),
#'       weight       = 1
#'     ),
#'     negativo = list(
#'       definition   = "Discurso com tom critico ou confrontacional.",
#'       examples_pos = c("Esta proposta vai arruinar o pais."),
#'       examples_neg = c("Apresento esta emenda para melhorar o texto."),
#'       weight       = 1
#'     )
#'   )
#' )
#' cb
#'
#' @concept qualitative
#' @export
ac_qual_codebook <- function(name,
                              instructions,
                              categories   = list(),
                              corpus       = NULL,
                              n_categories = 5L,
                              mode         = c("manual", "induced", "literature"),
                              multilabel   = FALSE,
                              lang         = "pt",
                              chat         = NULL,
                              model        = "anthropic/claude-sonnet-4-5",
                              journals     = "default",
                              n_refs       = 5L,
                              check_overlap = FALSE,
                              ...) {

  mode <- match.arg(mode)

  # === Valida\u00e7\u00f5es gerais =====================================================
  if (!is.character(name) || length(name) != 1L || nchar(trimws(name)) == 0L)
    cli::cli_abort("{.arg name} deve ser uma string n\u00e3o vazia.")
  if (!is.character(instructions) || length(instructions) != 1L)
    cli::cli_abort("{.arg instructions} deve ser uma string.")
  if (mode != "induced") {
    if (!is.list(categories) || is.null(names(categories)))
      cli::cli_abort("{.arg categories} deve ser uma lista nomeada.")
    if (length(categories) < 2L)
      cli::cli_abort("{.arg categories} deve ter pelo menos 2 categorias.")
  }
  if (mode == "induced" && (is.null(corpus) || !is_ac_corpus(corpus)))
    cli::cli_abort(c(
      "{.arg corpus} \u00e9 obrigat\u00f3rio no modo {.val induced}.",
      "i" = "Forne\u00e7a um objeto {.cls ac_corpus}."
    ))
  if (!is.null(chat) && !inherits(chat, "Chat"))
    cli::cli_abort("{.arg chat} deve ser um objeto {.cls Chat} do {.pkg ellmer}.")

  effective_model <- if (!is.null(chat)) chat else model

  # === Modo manual ============================================================
  if (mode == "manual") {
    cats <- .ac_parse_categories_manual(categories)
  }

  # === Modo induced ===========================================================
  if (mode == "induced") {
    if (!requireNamespace("ellmer",   quietly = TRUE)) cli::cli_abort("O pacote {.pkg ellmer} \u00e9 necess\u00e1rio.")
    if (!requireNamespace("jsonlite", quietly = TRUE)) cli::cli_abort("O pacote {.pkg jsonlite} \u00e9 necess\u00e1rio.")
    cats <- .ac_induce_categories(
      corpus       = corpus,
      instructions = instructions,
      n_categories = as.integer(n_categories),
      model        = effective_model
    )
  }

  # === Modo literature ========================================================
  if (mode == "literature") {
    if (!requireNamespace("ellmer", quietly = TRUE)) cli::cli_abort("O pacote {.pkg ellmer} \u00e9 necess\u00e1rio.")
    journals_list <- .ac_get_journals(journals)
    cats <- .ac_literature_categories(
      categories = categories,
      model      = effective_model,
      journals   = journals_list,
      n_refs     = n_refs,
      lang       = lang
    )
  }

  # === Verifica\u00e7\u00e3o de sobreposi\u00e7\u00e3o ============================================
  if (isTRUE(check_overlap) && length(cats) >= 2L) {
    .ac_check_overlap(cats, effective_model)
  }

  # === Montar objeto ==========================================================
  structure(
    list(
      name         = name,
      instructions = instructions,
      categories   = cats,
      multilabel   = multilabel,
      lang         = lang,
      mode         = mode,
      model        = if (mode %in% c("induced", "literature")) effective_model else NULL,
      created_at   = Sys.time(),
      history      = list(),
      needs_review = FALSE
    ),
    class = "ac_codebook"
  )
}


# ============================================================================
# Adicionar e remover categorias
# ============================================================================

#' Adicionar categoria a um codebook existente
#'
#' @description
#' `ac_qual_codebook_add()` adiciona uma ou mais categorias a um `ac_codebook`
#' já criado, sem precisar recriar o objeto do zero. Útil para refinamento
#' iterativo do codebook durante a análise.
#'
#' @param codebook Objeto `ac_codebook`.
#' @param ... Categorias a adicionar, nomeadas. Cada elemento deve ser uma
#'   lista com `definition` e, opcionalmente, `examples_pos`, `examples_neg`,
#'   `weight` e `references`.
#'
#' @return Objeto `ac_codebook` atualizado.
#'
#' @examples
#' cb <- ac_qual_codebook(
#'   name         = "tom",
#'   instructions = "Classifique o tom.",
#'   categories   = list(
#'     positivo = list(definition = "Tom propositivo."),
#'     negativo = list(definition = "Tom critico.")
#'   )
#' )
#'
#' cb <- ac_qual_codebook_add(cb,
#'   neutro = list(
#'     definition   = "Tom neutro, sem posicionamento claro.",
#'     examples_pos = c("O projeto foi apresentado na sessao de hoje.")
#'   )
#' )
#' names(cb$categories)
#'
#' @seealso [ac_qual_codebook()], [ac_qual_codebook_remove()]
#' @concept qualitative
#' @export
ac_qual_codebook_add <- function(codebook, ...) {
  if (!inherits(codebook, "ac_codebook"))
    cli::cli_abort("{.arg codebook} deve ser um objeto {.cls ac_codebook}.")

  novas <- list(...)
  if (length(novas) == 0L || is.null(names(novas)))
    cli::cli_abort("Forne\u00e7a categorias nomeadas para adicionar.")

  # Verificar duplicatas
  duplicatas <- intersect(names(novas), names(codebook$categories))
  if (length(duplicatas) > 0L)
    cli::cli_abort(c(
      "Categoria{?s} j\u00e1 {?existe/existem} no codebook: {.val {duplicatas}}.",
      "i" = "Use {.fn ac_qual_codebook_remove} primeiro se quiser substituir."
    ))

  # Registrar no hist\u00f3rico antes de modificar
  codebook <- .ac_history_push(codebook, "add", paste(names(novas), collapse = ", "))

  novas_cats <- .ac_parse_categories_manual(novas)
  codebook$categories <- c(codebook$categories, novas_cats)

  cli::cli_inform(c(
    "v" = "{length(novas)} categoria{?s} adicionada{?s}: {.val {names(novas)}}.",
    "i" = "Codebook agora tem {length(codebook$categories)} categorias."
  ))
  codebook
}


#' Remover categoria de um codebook existente
#'
#' @description
#' `ac_qual_codebook_remove()` remove uma ou mais categorias de um
#' `ac_codebook` existente.
#'
#' @param codebook Objeto `ac_codebook`.
#' @param categories Vetor `character` com os nomes das categorias a remover.
#'
#' @return Objeto `ac_codebook` atualizado.
#'
#' @examples
#' cb <- ac_qual_codebook(
#'   name         = "tom",
#'   instructions = "Classifique o tom.",
#'   categories   = list(
#'     positivo = list(definition = "Tom propositivo."),
#'     negativo = list(definition = "Tom critico."),
#'     neutro   = list(definition = "Tom neutro.")
#'   )
#' )
#' cb <- ac_qual_codebook_remove(cb, "neutro")
#' names(cb$categories)
#'
#' @seealso [ac_qual_codebook()], [ac_qual_codebook_add()]
#' @concept qualitative
#' @export
ac_qual_codebook_remove <- function(codebook, categories) {
  if (!inherits(codebook, "ac_codebook"))
    cli::cli_abort("{.arg codebook} deve ser um objeto {.cls ac_codebook}.")
  if (!is.character(categories) || length(categories) == 0L)
    cli::cli_abort("{.arg categories} deve ser um vetor character n\u00e3o vazio.")

  nao_encontradas <- setdiff(categories, names(codebook$categories))
  if (length(nao_encontradas) > 0L)
    cli::cli_abort(c(
      "Categoria{?s} n\u00e3o encontrada{?s}: {.val {nao_encontradas}}.",
      "i" = "Categorias dispon\u00edveis: {.val {names(codebook$categories)}}."
    ))

  restantes <- length(codebook$categories) - length(categories)
  if (restantes < 2L)
    cli::cli_abort(c(
      "O codebook precisa de pelo menos 2 categorias.",
      "x" = "Remover {.val {categories}} deixaria apenas {restantes} categoria{?s}."
    ))

  codebook <- .ac_history_push(codebook, "remove", paste(categories, collapse = ", "))
  codebook$categories <- codebook$categories[!names(codebook$categories) %in% categories]

  cli::cli_inform(c(
    "v" = "{length(categories)} categoria{?s} removida{?s}: {.val {categories}}.",
    "i" = "Codebook agora tem {length(codebook$categories)} categorias."
  ))
  codebook
}


# ============================================================================
# M\u00e9todos S3
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
    weight_str <- if (!is.null(cat$weight) && cat$weight != 1)
      paste0(" [peso: ", cat$weight, "]") else ""
    cli::cli_text("  \u2022 {.val {cat$name}}{weight_str}: {cat$definition}")
    if (length(cat$examples_pos) > 0L)
      cli::cli_text("    Ex+: {cat$examples_pos[1]}")
  }
  if (length(x$history) > 0L) {
    cli::cli_text("")
    cli::cli_text("{.strong Hist\u00f3rico}: {length(x$history)} modifica\u00e7\u00e3o(\u00f5es)")
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
      n_refs        = length(cat$references),
      weight        = cat$weight %||% 1
    )
  })
  cli::cli_h1("Resumo do codebook {.val {object$name}}")
  print(cat_summary)
  invisible(object)
}


# ============================================================================
# Salvar e carregar
# ============================================================================

#' Salvar codebook em arquivo YAML
#' @param codebook Objeto `ac_codebook`.
#' @param path Caminho do arquivo `.yaml`.
#' @param ... Ignorado.
#' @export
#' @concept qualitative
ac_qual_save_codebook <- function(codebook, path = NULL, ...) {
  if (!inherits(codebook, "ac_codebook"))
    cli::cli_abort("{.arg codebook} deve ser um objeto {.cls ac_codebook}.")
  if (!requireNamespace("yaml", quietly = TRUE))
    cli::cli_abort("O pacote {.pkg yaml} \u00e9 necess\u00e1rio.")

  if (is.null(path))
    path <- paste0(gsub("[^a-zA-Z0-9_-]", "_", codebook$name), ".yaml")

  obj <- list(
    name         = codebook$name,
    instructions = codebook$instructions,
    multilabel   = codebook$multilabel,
    lang         = codebook$lang,
    mode         = codebook$mode,
    created_at   = format(codebook$created_at, "%Y-%m-%d %H:%M:%S"),
    history      = codebook$history,
    categories   = purrr::map(codebook$categories, function(cat) {
      list(
        name         = cat$name,
        definition   = cat$definition,
        examples_pos = cat$examples_pos,
        examples_neg = cat$examples_neg,
        references   = cat$references,
        weight       = cat$weight %||% 1,
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
#' @param path Caminho do arquivo `.yaml`.
#' @param ... Ignorado.
#' @export
#' @concept qualitative
ac_qual_load_codebook <- function(path, ...) {
  if (!requireNamespace("yaml", quietly = TRUE))
    cli::cli_abort("O pacote {.pkg yaml} \u00e9 necess\u00e1rio.")
  if (!file.exists(path))
    cli::cli_abort("Arquivo {.path {path}} n\u00e3o encontrado.")

  obj  <- yaml::read_yaml(path)
  cats <- purrr::map(obj$categories, function(cat) {
    structure(
      list(
        name         = cat$name,
        definition   = cat$definition   %||% "",
        examples_pos = unlist(cat$examples_pos %||% list()),
        examples_neg = unlist(cat$examples_neg %||% list()),
        references   = unlist(cat$references   %||% list()),
        weight       = cat$weight %||% 1,
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
      history      = obj$history    %||% list(),
      needs_review = FALSE
    ),
    class = "ac_codebook"
  )
}


# ============================================================================
# Auxiliares internos
# ============================================================================

#' Parsear e validar categorias no modo manual
#' @keywords internal
#' @noRd
.ac_parse_categories_manual <- function(categories) {
  purrr::imap(categories, function(cat_def, cat_name) {

    # Aceitar string simples como definition
    if (is.character(cat_def) && length(cat_def) == 1L) {
      cat_def <- list(definition = cat_def)
    }
    if (!is.list(cat_def)) {
      cli::cli_abort(c(
        "Categoria {.val {cat_name}}: formato inv\u00e1lido.",
        "i" = "Cada categoria deve ser uma lista com pelo menos {.field definition}."
      ))
    }

    # Validar definition
    if (is.null(cat_def$definition) || nchar(trimws(cat_def$definition)) == 0L) {
      cli::cli_abort(c(
        "Categoria {.val {cat_name}}: {.field definition} est\u00e1 ausente ou vazia.",
        "i" = "Forne\u00e7a uma defini\u00e7\u00e3o operacional clara em 1-3 frases."
      ))
    }

    # Avisar sobre exemplos ausentes
    if (length(cat_def$examples_pos %||% character(0)) == 0L) {
      cli::cli_inform(c(
        "!" = "Categoria {.val {cat_name}}: sem exemplos positivos ({.field examples_pos}).",
        "i" = "Exemplos melhoram a precis\u00e3o da classifica\u00e7\u00e3o (Sampaio & Lycari\u00e3o, 2021)."
      ))
    }
    if (length(cat_def$examples_neg %||% character(0)) == 0L) {
      cli::cli_inform(c(
        "!" = "Categoria {.val {cat_name}}: sem exemplos negativos ({.field examples_neg}).",
        "i" = "Exemplos negativos reduzem confus\u00e3o entre categorias similares."
      ))
    }

    # Validar weight
    w <- cat_def$weight %||% 1
    if (!is.numeric(w) || length(w) != 1L || w < 0 || w > 2) {
      cli::cli_abort(c(
        "Categoria {.val {cat_name}}: {.field weight} deve ser num\u00e9rico entre 0 e 2.",
        "i" = "Use 1 (padr\u00e3o) para peso normal, > 1 para categorias raras/dif\u00edceis."
      ))
    }

    structure(
      list(
        name         = cat_name,
        definition   = trimws(cat_def$definition),
        examples_pos = cat_def$examples_pos %||% character(0),
        examples_neg = cat_def$examples_neg %||% character(0),
        references   = cat_def$references   %||% character(0),
        weight       = w,
        concept      = NULL,
        literature   = NULL
      ),
      class = "ac_category"
    )
  })
}


#' Induzir categorias via LLM
#' @keywords internal
#' @noRd
.ac_induce_categories <- function(corpus, instructions, n_categories, model) {
  n_sample <- min(20L, nrow(corpus))
  idx      <- sample(seq_len(nrow(corpus)), n_sample)
  textos   <- corpus$text[idx]

  cli::cli_inform(c(
    "i" = "Induzindo codebook a partir de {n_sample} documento(s)...",
    "i" = "N\u00famero de categorias: {n_categories}"
  ))

  system_prompt <- paste0(
    "Voc\u00ea \u00e9 um especialista em an\u00e1lise de conte\u00fado qualitativa. ",
    "Sua tarefa \u00e9 induzir categorias anal\u00edticas a partir de um corpus de textos. ",
    "Responda APENAS com JSON v\u00e1lido, sem markdown."
  )

  user_msg <- paste0(
    "Analise os textos abaixo e sugira exatamente ", n_categories,
    " categorias.\n\nINSTRU\u00c7\u00c3O: ", instructions, "\n\nTEXTOS:\n",
    paste0(seq_along(textos), ". ", textos, collapse = "\n"),
    "\n\nRetorne APENAS este JSON:\n",
    "{\"categories\":[{\"name\":\"nome_snake_case\",",
    "\"definition\":\"definicao em 1-2 frases\",",
    "\"examples_pos\":[\"ex1\"],\"examples_neg\":[\"ex1\"]}]}"
  )

  if (inherits(model, "Chat")) {
    chat_obj <- model$clone()
    chat_obj$set_system_prompt(system_prompt)
  } else {
    chat_obj <- tryCatch(
      ellmer::chat(name = model, system_prompt = system_prompt),
      error = function(e) cli::cli_abort(c("Erro ao inicializar ellmer.", "x" = conditionMessage(e)))
    )
  }

  resposta <- tryCatch(
    chat_obj$chat(user_msg),
    error = function(e) cli::cli_abort(c("Erro ao consultar o modelo.", "x" = conditionMessage(e)))
  )

  json_str <- stringr::str_extract(resposta, "\\{.*\\}")
  if (is.na(json_str))
    cli::cli_abort("O modelo n\u00e3o retornou JSON v\u00e1lido.")

  parsed   <- tryCatch(
    jsonlite::fromJSON(json_str, simplifyVector = FALSE),
    error = function(e) cli::cli_abort("Erro ao parsear JSON: {conditionMessage(e)}")
  )

  cats_raw <- parsed$categories %||% list()
  if (length(cats_raw) == 0L)
    cli::cli_abort("O modelo retornou lista de categorias vazia.")

  cats <- purrr::map(cats_raw, function(cat_def) {
    structure(
      list(
        name         = cat_def$name         %||% "sem_nome",
        definition   = cat_def$definition   %||% "",
        examples_pos = unlist(cat_def$examples_pos %||% list()),
        examples_neg = unlist(cat_def$examples_neg %||% list()),
        references   = character(0),
        weight       = 1,
        concept      = NULL,
        literature   = NULL
      ),
      class = "ac_category"
    )
  })
  names(cats) <- purrr::map_chr(cats, "name")

  cli::cli_inform(c(
    "v" = "{length(cats)} categoria(s) induzida(s): {.val {names(cats)}}",
    "i" = "Revise as defini\u00e7\u00f5es com {.fn print} antes de usar em {.fn ac_qual_code}."
  ))
  cats
}


#' Construir categorias via literatura
#' @keywords internal
#' @noRd
.ac_literature_categories <- function(categories, model, journals, n_refs, lang) {
  cli::cli_h1("acR \u2022 Modo literatura")
  cli::cli_inform(c(
    "i" = "Buscando defini\u00e7\u00f5es para {length(categories)} categoria(s)...",
    "i" = "Modelo: {.val {if (inherits(model, 'Chat')) class(model)[1] else model}}"
  ))

  cats <- purrr::map(names(categories), function(cat_name) {
    cat_def <- categories[[cat_name]]
    concept <- cat_def$concept %||% cat_name
    cli::cli_h2("Categoria: {.val {cat_name}}")
    lit <- .ac_search_literature_llm(
      concept  = concept,
      model    = model,
      journals = journals,
      n_refs   = n_refs,
      lang     = lang
    )
    .ac_review_category(cat_name = cat_name, concept = concept,
                        lit = lit, model = model, lang = lang)
  })
  names(cats) <- names(categories)
  cats
}


#' Verificar sobreposição semântica entre definições
#' @keywords internal
#' @noRd
.ac_check_overlap <- function(cats, model) {
  cli::cli_inform(c("i" = "Verificando sobreposi\u00e7\u00e3o entre defini\u00e7\u00f5es..."))

  defs <- purrr::map_chr(cats, "definition")
  nomes <- names(defs)
  pares <- utils::combn(length(defs), 2L, simplify = FALSE)

  avisos <- character(0)
  for (par in pares) {
    i <- par[1]; j <- par[2]
    sim <- .ac_string_similarity(defs[i], defs[j])
    if (sim > 0.45) {
      avisos <- c(avisos, paste0(nomes[i], " \u00d7 ", nomes[j],
                                 " (similaridade: ", round(sim, 2), ")"))
    }
  }

  if (length(avisos) > 0L) {
    cli::cli_warn(c(
      "!" = "Poss\u00edvel sobreposi\u00e7\u00e3o entre categorias:",
      purrr::set_names(avisos, rep("*", length(avisos))),
      "i" = "Defini\u00e7\u00f5es sobrepostas aumentam ambiguidade na classifica\u00e7\u00e3o.",
      "i" = "Revise ou adicione exemplos negativos cruzados entre as categorias."
    ))
  } else {
    cli::cli_inform(c("v" = "Nenhuma sobreposi\u00e7\u00e3o detectada entre as defini\u00e7\u00f5es."))
  }

  invisible(NULL)
}


#' Similaridade simples entre duas strings (Jaccard sobre bigramas)
#' @keywords internal
#' @noRd
.ac_string_similarity <- function(a, b) {
  .bigrams <- function(s) {
    s  <- tolower(trimws(s))
    ch <- strsplit(s, "")[[1]]
    if (length(ch) < 2L) return(character(0))
    paste0(ch[-length(ch)], ch[-1L])
  }
  bg_a <- unique(.bigrams(a))
  bg_b <- unique(.bigrams(b))
  if (length(bg_a) == 0L || length(bg_b) == 0L) return(0)
  length(intersect(bg_a, bg_b)) / length(union(bg_a, bg_b))
}


#' Registrar modificação no histórico do codebook
#' @keywords internal
#' @noRd
.ac_history_push <- function(codebook, action, detail = "") {
  entry <- list(
    timestamp = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
    action    = action,
    detail    = detail
  )
  codebook$history <- c(codebook$history, list(entry))
  codebook
}


# ============================================================================
# Fun\u00e7\u00f5es auxiliares de literatura (mantidas do original)
# ============================================================================

#' @keywords internal
#' @noRd
.ac_get_journals <- function(journals) {
  default_intl <- c(
    "American Political Science Review", "Comparative Political Studies",
    "Journal of Democracy", "Democratization", "Political Research Quarterly",
    "Comparative Politics", "World Politics", "European Journal of Political Research"
  )
  default_br <- c(
    "DADOS", "Opini\u00e3o P\u00fablica", "Brazilian Political Science Review",
    "Revista de Sociologia e Pol\u00edtica", "Lua Nova", "Cadernos CRH",
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
  journals_str <- if (is.null(journals)) "qualquer peri\u00f3dico acad\u00eamico relevante" else
    paste(journals, collapse = "; ")
  lang_str <- if (lang == "pt") "portugu\u00eas brasileiro" else "English"

  prompt <- paste0(
    "Voc\u00ea \u00e9 especialista em Ci\u00eancia Pol\u00edtica e Ci\u00eancias Sociais.\n\n",
    "Busque ", n_refs, " refer\u00eancias sobre: '", concept, "'.\n",
    "Priorize: ", journals_str, ".\n\n",
    "Retorne APENAS JSON:\n",
    "[{\"conceito\":\"", concept, "\",\"autor\":\"Sobrenome, I.\",",
    "\"ano\":2020,\"trecho_original\":\"trecho\",",
    "\"definicao_pt\":\"tradu\u00e7\u00e3o em ", lang_str, "\",",
    "\"revista\":\"nome\",\"link\":\"DOI ou null\"}]"
  )

  if (inherits(model, "Chat")) {
    chat <- model$clone()
  } else {
    chat <- ellmer::chat(name = model)
  }

  resposta <- tryCatch(chat$chat(prompt),
    error = function(e) cli::cli_abort(c("Erro ao consultar a LLM.", "x" = conditionMessage(e))))

  json_str <- stringr::str_extract(resposta, "\\[.*\\]")
  if (is.na(json_str)) {
    cli::cli_warn("LLM n\u00e3o retornou JSON v\u00e1lido.")
    return(.empty_literature_tibble())
  }

  parsed <- tryCatch(jsonlite::fromJSON(json_str, simplifyDataFrame = TRUE),
    error = function(e) { cli::cli_warn("Erro ao parsear JSON."); NULL })

  if (is.null(parsed) || nrow(parsed) == 0L) return(.empty_literature_tibble())

  expected_cols <- c("conceito","autor","ano","trecho_original","definicao_pt","revista","link")
  for (col in expected_cols) if (!col %in% names(parsed)) parsed[[col]] <- NA_character_

  cli::cli_warn(c("!" = "Refer\u00eancias geradas por LLM. Verifique antes de citar."))
  tibble::as_tibble(parsed[, expected_cols])
}


#' @keywords internal
#' @noRd
.empty_literature_tibble <- function() {
  tibble::tibble(
    conceito = character(0), autor = character(0), ano = integer(0),
    trecho_original = character(0), definicao_pt = character(0),
    revista = character(0), link = character(0)
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
    cli::cli_warn("Modo n\u00e3o-interativo: revis\u00e3o de {.val {cat_name}} pulada.")
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
      references   = if (nrow(lit) > 0L)
        paste0(lit$autor, " (", lit$ano, "). ", lit$revista, ".")
        else character(0),
      weight       = 1,
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
  refs_str <- paste(purrr::map_chr(seq_len(nrow(lit)), function(i)
    paste0(lit$autor[i], " (", lit$ano[i], "): \"", lit$trecho_original[i], "\"")),
    collapse = "\n")

  prompt <- paste0(
    "Com base nas refer\u00eancias sobre '", concept, "':\n\n", refs_str, "\n\n",
    "Redija em ", lang_str, " uma defini\u00e7\u00e3o operacional de 2-4 frases para '",
    cat_name, "'. Retorne APENAS a defini\u00e7\u00e3o."
  )

  if (inherits(model, "Chat")) {
    chat <- model$clone()
  } else {
    chat <- ellmer::chat(name = model)
  }
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
  if (inherits(model, "Chat")) {
    chat <- model$clone()
  } else {
    chat <- ellmer::chat(name = model)
  }
  resp   <- tryCatch(chat$chat(prompt), error = function(e) "")
  parsed <- tryCatch(jsonlite::fromJSON(resp),
    error = function(e) list(pos = character(0), neg = character(0)))
  list(pos = parsed$pos %||% character(0), neg = parsed$neg %||% character(0))
}
#' Enriquecer codebook com literatura via LLM (modo híbrido)
#'
#' @description
#' `ac_qual_codebook_hybrid()` re-ancora as definições de um `ac_codebook`
#' existente em referências bibliográficas buscadas via LLM, combinando
#' definições manuais com fundamento teórico induzido da literatura.
#'
#' @param codebook Objeto `ac_codebook`.
#' @param chat Objeto `Chat` do pacote `ellmer`. Tem prioridade sobre `model`.
#' @param model Modelo LLM. Padrão: `"anthropic/claude-sonnet-4-5"`.
#' @param concepts Lista nomeada com conceitos por categoria (opcional).
#' @param journals Periódicos para busca. Padrão: `"default"`.
#' @param n_refs Número de referências por categoria. Padrão: `3L`.
#' @param lang Idioma: `"pt"` (padrão) ou `"en"`.
#'
#' @return Objeto `ac_codebook` com definições atualizadas e literatura anexada.
#'
#' @concept qualitative
#' @export
ac_qual_codebook_hybrid <- function(codebook, chat=NULL, model='anthropic/claude-sonnet-4-5', concepts=NULL, journals='default', n_refs=3L, lang='pt') {
  if (!inherits(codebook, 'ac_codebook')) cli::cli_abort('{.arg codebook} deve ser ac_codebook.')
  effective_model <- if (!is.null(chat)) chat else model
  journals_list <- .ac_get_journals(journals)
  cats <- purrr::imap(codebook$categories, function(cat, cat_name) {
    concept <- if (!is.null(concepts) && !is.null(concepts[[cat_name]])) concepts[[cat_name]] else gsub('_',' ',cat_name)
    lit <- tryCatch(.ac_search_literature_llm(concept,effective_model,journals_list,as.integer(n_refs),lang), error=function(e){cli::cli_warn(conditionMessage(e));.empty_literature_tibble()})
    nova_def <- if(nrow(lit)>0L) .ac_generate_definition(cat_name,concept,lit,effective_model,lang)$definition else cat$definition
    refs_novas <- if(nrow(lit)>0L) paste0(lit$autor,' (',lit$ano,'). ',lit$revista,'.') else character(0)
    structure(list(name=cat_name,definition=nova_def,examples_pos=cat$examples_pos,examples_neg=cat$examples_neg,references=unique(c(cat$references,refs_novas)),weight=if(is.null(cat$weight))1 else cat$weight,concept=concept,literature=lit),class='ac_category')
  })
  codebook <- .ac_history_push(codebook,'hybrid',paste(names(cats),collapse=', '))
  codebook$categories <- cats; codebook$mode <- 'hybrid'
  cli::cli_inform(c('v'='Codebook h\u00edbrido pronto.'))
  codebook
}

#' Exibir histórico de modificações de um codebook
#'
#' @description
#' `ac_qual_codebook_history()` retorna e imprime o histórico de ações
#' registradas em um `ac_codebook` (adições, remoções, merges, traduções etc.).
#'
#' @param codebook Objeto `ac_codebook`.
#' @param n Número máximo de entradas a exibir. Padrão: `Inf` (todas).
#'
#' @return Tibble com colunas `timestamp`, `action` e `detail` (invisível).
#'
#' @concept qualitative
#' @export
ac_qual_codebook_history <- function(codebook, n=Inf) {
  if (!inherits(codebook,'ac_codebook')) cli::cli_abort('{.arg codebook} deve ser ac_codebook.')
  hist <- codebook$history
  if (length(hist)==0L) { cli::cli_inform('Nenhuma modifica\u00e7\u00e3o.'); return(invisible(tibble::tibble(timestamp=character(0),action=character(0),detail=character(0)))) }
  tbl <- tibble::tibble(timestamp=purrr::map_chr(hist,'timestamp'),action=purrr::map_chr(hist,'action'),detail=purrr::map_chr(hist,'detail'))
  if (is.finite(n)) tbl <- utils::head(tbl,as.integer(n))
  cli::cli_h1('Hist\u00f3rico: {.val {codebook$name}}')
  print(tbl); invisible(tbl)
}

#' Converter codebook em system prompt para LLM
#'
#' @description
#' `as_prompt()` é um genérico S3 que converte um objeto em system prompt
#' formatado para uso com LLMs. O método `as_prompt.ac_codebook()` gera
#' o prompt a partir de um `ac_codebook`, incluindo instruções, categorias,
#' exemplos, pesos e, opcionalmente, raciocínio estruturado.
#'
#' @param x Objeto a converter (para `as_prompt.ac_codebook`: um `ac_codebook`).
#' @param ... Argumentos adicionais passados ao método.
#'
#' @return String com o system prompt (invisível).
#'
#' @concept qualitative
#' @export
as_prompt <- function(x, ...) UseMethod('as_prompt')

#' @rdname as_prompt
#' @param reasoning Lógico. Se `TRUE`, inclui campo de raciocínio no JSON de saída. Padrão: `TRUE`.
#' @param reasoning_length Extensão do raciocínio: `"short"`, `"medium"` ou `"detailed"`.
#' @export
as_prompt.ac_codebook <- function(x, reasoning=TRUE, reasoning_length=c('short','medium','detailed'), ...) {
  reasoning_length <- match.arg(reasoning_length)
  prompt <- .ac_build_system_prompt_with_weight(x, reasoning, reasoning_length)
  cli::cli_h1('System prompt: {.val {x$name}}')
  cli::cli_text('({nchar(prompt)} caracteres)')
  cli::cli_rule(); cat(prompt, '\n'); cli::cli_rule()
  invisible(prompt)
}

#' Fundir dois codebooks em um
#'
#' @description
#' `ac_qual_codebook_merge()` combina as categorias de dois objetos `ac_codebook`
#' em um único codebook, com controle de conflitos de nomes.
#'
#' @param cb1 Objeto `ac_codebook` (base).
#' @param cb2 Objeto `ac_codebook` (a fundir).
#' @param name Nome do codebook resultante. Padrão: `"cb1_cb2"`.
#' @param on_conflict Estratégia em caso de categorias com o mesmo nome:
#'   `"error"` (padrão), `"keep_first"`, `"keep_second"` ou `"rename_second"`.
#' @param instructions Instrução geral do novo codebook. Se `NULL`, usa a de `cb1`.
#'
#' @return Objeto `ac_codebook` fundido.
#'
#' @concept qualitative
#' @export
ac_qual_codebook_merge <- function(cb1, cb2, name=NULL, on_conflict=c('error','keep_first','keep_second','rename_second'), instructions=NULL) {
  if (!inherits(cb1,'ac_codebook')) cli::cli_abort('{.arg cb1} deve ser ac_codebook.')
  if (!inherits(cb2,'ac_codebook')) cli::cli_abort('{.arg cb2} deve ser ac_codebook.')
  on_conflict <- match.arg(on_conflict)
  conflitos <- intersect(names(cb1$categories),names(cb2$categories))
  if (length(conflitos)>0L) {
    if (on_conflict=='error') cli::cli_abort(c('Conflito: {.val {conflitos}}.','i'='Use on_conflict para resolver.'))
    else if (on_conflict=='keep_first') cb2$categories <- cb2$categories[!names(cb2$categories)%in%conflitos]
    else if (on_conflict=='keep_second') cb1$categories <- cb1$categories[!names(cb1$categories)%in%conflitos]
    else if (on_conflict=='rename_second') { idx <- names(cb2$categories)%in%conflitos; names(cb2$categories)[idx] <- paste0(names(cb2$categories)[idx],'_2') }
  }
  cats <- c(cb1$categories,cb2$categories)
  result <- structure(list(name=if(is.null(name))paste0(cb1$name,'_',cb2$name)else name,instructions=if(is.null(instructions))cb1$instructions else instructions,categories=cats,multilabel=cb1$multilabel,lang=cb1$lang,mode='manual',model=NULL,created_at=Sys.time(),history=list(list(timestamp=format(Sys.time(),'%Y-%m-%d %H:%M:%S'),action='merge',detail=paste0(cb1$name,' + ',cb2$name))),needs_review=FALSE),class='ac_codebook')
  cli::cli_inform(c('v'='Fundidos: {length(cats)} categorias.')); result
}

#' Traduzir codebook para outro idioma via LLM
#'
#' @description
#' `ac_qual_codebook_translate()` traduz as instruções, definições e exemplos
#' de um `ac_codebook` para o idioma alvo usando uma LLM, preservando a
#' estrutura e os metadados do objeto.
#'
#' @param codebook Objeto `ac_codebook`.
#' @param to Idioma alvo: `"en"` (padrão) ou `"pt"`.
#' @param chat Objeto `Chat` do pacote `ellmer`. Tem prioridade sobre `model`.
#' @param model Modelo LLM. Padrão: `"anthropic/claude-sonnet-4-5"`.
#' @param translate_examples Se `TRUE` (padrão), traduz também os exemplos.
#'
#' @return Objeto `ac_codebook` traduzido.
#'
#' @concept qualitative
#' @export
ac_qual_codebook_translate <- function(codebook, to=c('en','pt'), chat=NULL, model='anthropic/claude-sonnet-4-5', translate_examples=TRUE) {
  if (!inherits(codebook,'ac_codebook')) cli::cli_abort('{.arg codebook} deve ser ac_codebook.')
  if (!requireNamespace('ellmer',quietly=TRUE)) cli::cli_abort('ellmer necessario.')
  if (!requireNamespace('jsonlite',quietly=TRUE)) cli::cli_abort('jsonlite necessario.')
  to <- match.arg(to)
  if (codebook$lang==to) { cli::cli_inform('J\u00e1 em {.val {to}}.'); return(codebook) }
  effective_model <- if (!is.null(chat)) chat else model
  lang_names <- c(pt='portugu\u00eas brasileiro',en='English')
  payload <- list(instructions=codebook$instructions,categories=purrr::imap(codebook$categories,function(cat,nm){entry<-list(name=nm,definition=cat$definition);if(isTRUE(translate_examples)){entry$examples_pos<-cat$examples_pos;entry$examples_neg<-cat$examples_neg};entry}))
  sys_p <- paste0('Translate JSON from ',lang_names[codebook$lang],' to ',lang_names[to],'. Keep keys. Translate values only. Return ONLY valid JSON.')
  user_msg <- paste0('Translate:\n\n',jsonlite::toJSON(payload,auto_unbox=TRUE,pretty=TRUE))
  if (inherits(effective_model,'Chat')) { chat_obj<-effective_model$clone(); chat_obj$set_system_prompt(sys_p) } else { chat_obj<-tryCatch(ellmer::chat(name=effective_model,system_prompt=sys_p),error=function(e)cli::cli_abort(conditionMessage(e))) }
  resp <- tryCatch(chat_obj$chat(user_msg),error=function(e)cli::cli_abort(conditionMessage(e)))
  json_str <- stringr::str_extract(resp,'\\{[\\s\\S]*\\}')
  if (is.na(json_str)) cli::cli_abort('JSON inv\u00e1lido.')
  parsed <- tryCatch(jsonlite::fromJSON(json_str,simplifyVector=FALSE),error=function(e)cli::cli_abort(conditionMessage(e)))
  result <- codebook; result$lang <- to
  result$instructions <- if(is.null(parsed$instructions)) codebook$instructions else parsed$instructions
  result$categories <- purrr::imap(codebook$categories,function(cat,nm){cat_tr<-purrr::detect(parsed$categories,function(c)c$name==nm);structure(list(name=nm,definition=if(is.null(cat_tr$definition))cat$definition else cat_tr$definition,examples_pos=if(isTRUE(translate_examples))unlist(if(is.null(cat_tr$examples_pos))list() else cat_tr$examples_pos)else cat$examples_pos,examples_neg=if(isTRUE(translate_examples))unlist(if(is.null(cat_tr$examples_neg))list() else cat_tr$examples_neg)else cat$examples_neg,references=cat$references,weight=if(is.null(cat$weight))1 else cat$weight,concept=cat$concept,literature=cat$literature),class='ac_category')})
  result <- .ac_history_push(result,'translate',paste0(codebook$lang,' -> ',to))
  cli::cli_inform(c('v'='Traduzido para {.val {to}}.')); result
}

#' @keywords internal
#' @noRd
.ac_build_system_prompt_with_weight <- function(codebook, reasoning, reasoning_length) {
  len_map <- c(short='1 frase curta',medium='2-3 frases',detailed='um par\u00e1grafo')
  cat_descriptions <- purrr::map_chr(codebook$categories, function(cat) {
    w <- if(is.null(cat$weight)) 1 else cat$weight
    weight_note <- if(w>1) paste0('\n  [ATEN\u00c7\u00c3O: categoria rara/dif\u00edcil, peso=',w,']') else ''
    ex_pos <- if(length(cat$examples_pos)>0L) paste0('\n  Exemplos positivos:\n',paste0('    - ',cat$examples_pos,collapse='\n')) else ''
    ex_neg <- if(length(cat$examples_neg)>0L) paste0('\n  Exemplos negativos:\n',paste0('    - ',cat$examples_neg,collapse='\n')) else ''
    paste0('- ',cat$name,': ',cat$definition,weight_note,ex_pos,ex_neg)
  })
  ri <- if(reasoning) paste0('\n  "raciocinio": "',len_map[reasoning_length],'",') else ''
  mi <- if(codebook$multilabel) 'Um texto pode pertencer a MAIS DE UMA categoria.' else 'Cada texto deve ser classificado em EXATAMENTE UMA categoria.'
  paste0('Voc\u00ea \u00e9 assistente de an\u00e1lise de conte\u00fado qualitativa.\n\n',codebook$instructions,'\n\n',mi,'\n\nCATEGORIAS:\n',paste(cat_descriptions,collapse='\n\n'),'\n\nResponda SEMPRE em JSON v\u00e1lido:\n{\n  "categoria": "',paste(names(codebook$categories),collapse='|'),'"',ri,'\n}')
}
