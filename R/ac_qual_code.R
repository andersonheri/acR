#' Classificar textos com LLM usando um codebook
#'
#' @description
#' `ac_qual_code()` classifica os textos de um `ac_corpus` de acordo com um
#' `ac_codebook`, usando um modelo de linguagem via `ellmer`. Retorna um tibble
#' com a classificação, grau de certeza (via self-consistency) e raciocínio
#' da LLM para cada documento.
#'
#' @param corpus Objeto `ac_corpus`.
#' @param codebook Objeto `ac_codebook`, saída de [ac_qual_codebook()].
#' @param model Modelo LLM a usar. Aceita string no formato
#'   `"provedor/modelo"` (ex: `"anthropic/claude-sonnet-4-5"`,
#'   `"openai/gpt-4.1"`) ou objeto `Chat` do pacote `ellmer`
#'   pré-configurado. Quando `chat` é fornecido, `model` é ignorado.
#' @param chat Objeto `Chat` do pacote `ellmer` (ex: `chat_google_gemini()`,
#'   `chat_openai()`, `chat_ollama()`). Quando fornecido, tem prioridade sobre
#'   `model`. Permite usar qualquer provedor suportado pelo `ellmer`.
#' @param confidence Como calcular certeza:
#'   * `"total"` (padrão): uma coluna `confidence_score` com média de todas
#'     as variáveis;
#'   * `"by_variable"`: uma coluna `<variavel>_confidence` por categoria;
#'   * `"both"`: colunas por variável + coluna `confidence_score` (média);
#'   * `"none"`: não calcula certeza (mais rápido, menor custo).
#' @param k_consistency Número de rodadas para self-consistency. Padrão: `3`.
#'   Ignorado se `confidence = "none"`.
#' @param temperature Temperatura das rodadas de consistency. Padrão: `0.3`.
#' @param reasoning Lógico. Se `TRUE` (padrão), inclui coluna `raciocinio`
#'   com justificativa da classificação.
#' @param reasoning_length Tamanho do raciocínio: `"short"` (1 frase, padrão),
#'   `"medium"` (3 frases), `"detailed"` (parágrafo).
#' @param ... Argumentos adicionais passados a `ellmer::chat()`.
#'   Permite uso de APIs OpenAI-compatible self-hosted via `base_url`.
#'
#' @return Tibble com colunas:
#'   * `doc_id`: identificador do documento;
#'   * Metadados originais do corpus;
#'   * Uma coluna por categoria com a classificação;
#'   * `confidence_score`: grau de certeza (0-1);
#'   * `confidence_level`: `"alta"`, `"media"`, `"baixa"`;
#'   * `raciocinio`: justificativa da classificação (se `reasoning = TRUE`).
#'
#' @references
#' Wang, X. et al. (2023). Self-Consistency Improves Chain of Thought Reasoning
#' in Language Models. *EMNLP*.
#'
#' Landis, J. R.; Koch, G. G. (1977). The Measurement of Observer Agreement
#' for Categorical Data. *Biometrics*, 33(1), 159-174.
#'
#' Gilardi, F.; Alizadeh, M.; Kubli, M. (2023). ChatGPT Outperforms Crowd
#' Workers for Text-Annotation Tasks. *PNAS*, 120(30).
#'
#' @examples
#' \dontrun{
#' cb <- ac_qual_codebook(
#'   name         = "tom",
#'   instructions = "Classifique o tom do discurso.",
#'   categories   = list(
#'     positivo = list(definition = "Tom propositivo e colaborativo."),
#'     negativo = list(definition = "Tom critico e confrontacional.")
#'   )
#' )
#'
#' df <- data.frame(
#'   id    = c("d1", "d2"),
#'   texto = c("Proponho cooperacao.", "Este governo e um fracasso.")
#' )
#' corpus <- ac_corpus(df, text = texto, docid = id)
#'
#' # Usando string de modelo (comportamento padrao)
#' coded <- ac_qual_code(corpus, cb, model = "anthropic/claude-sonnet-4-5")
#'
#' # Usando objeto Chat do ellmer (recomendado para controle fino)
#' chat_obj <- ellmer::chat_google_gemini(model = "gemini-2.5-flash", echo = "none")
#' coded <- ac_qual_code(corpus, cb, chat = chat_obj)
#'
#' # Groq (inferencia rapida, plano gratuito)
#' chat_groq <- ellmer::chat_groq(model = "llama-3.3-70b-versatile", echo = "none")
#' coded <- ac_qual_code(corpus, cb, chat = chat_groq)
#'
#' # Ollama (modelos locais, sem envio de dados externos)
#' chat_local <- ellmer::chat_ollama(model = "llama3.2", echo = "none")
#' coded <- ac_qual_code(corpus, cb, chat = chat_local)
#' }
#'
#' @concept qualitative
#' @export
ac_qual_code <- function(corpus,
                          codebook,
                          model              = "anthropic/claude-sonnet-4-5",
                          chat               = NULL,
                          confidence         = c("total", "by_variable",
                                                 "both", "none"),
                          k_consistency      = 3L,
                          temperature        = 0.3,
                          reasoning          = TRUE,
                          reasoning_length   = c("short", "medium", "detailed"),
                          ...) {

  # === Validacoes =============================================================
  if (!is_ac_corpus(corpus)) {
    cli::cli_abort("{.arg corpus} deve ser um {.cls ac_corpus}.")
  }
  if (!inherits(codebook, "ac_codebook")) {
    cli::cli_abort("{.arg codebook} deve ser um {.cls ac_codebook}.")
  }
  if (!requireNamespace("ellmer", quietly = TRUE)) {
    cli::cli_abort("O pacote {.pkg ellmer} é necessário.")
  }
  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    cli::cli_abort("O pacote {.pkg jsonlite} é necessário.")
  }
  if (!is.null(chat) && !inherits(chat, "Chat")) {
    cli::cli_abort(
      "{.arg chat} deve ser um objeto {.cls Chat} do pacote {.pkg ellmer}."
    )
  }

  confidence       <- match.arg(confidence)
  reasoning_length <- match.arg(reasoning_length)
  k_consistency    <- as.integer(k_consistency)
  do_confidence    <- confidence != "none"

  # chat tem prioridade sobre model
  effective_model <- if (!is.null(chat)) chat else model

  cat_names <- names(codebook$categories)

  # === Construir system prompt ================================================
  system_prompt <- .ac_build_system_prompt(codebook, reasoning, reasoning_length)

  # === Classificar cada documento =============================================
  n_docs      <- nrow(corpus)
  model_label <- if (!is.null(chat)) class(chat)[1] else model

  cli::cli_inform(c(
    "i" = "Classificando {n_docs} documento{?s} com {.val {model_label}}...",
    "i" = "Categorias: {.val {cat_names}}",
    if (do_confidence) "i" = "Self-consistency: k = {k_consistency} rodadas"
  ))

  results <- vector("list", n_docs)

  for (i in seq_len(n_docs)) {
    texto  <- corpus$text[i]
    doc_id <- corpus$doc_id[i]

    main_result <- .ac_classify_one(
      text          = texto,
      codebook      = codebook,
      model         = effective_model,
      system_prompt = system_prompt,
      temperature   = 0,
      reasoning     = reasoning,
      ...
    )

    if (do_confidence && k_consistency > 1L) {
      consistency_results <- purrr::map(
        seq_len(k_consistency - 1L),
        function(k) {
          .ac_classify_one(
            text          = texto,
            codebook      = codebook,
            model         = effective_model,
            system_prompt = system_prompt,
            temperature   = temperature,
            reasoning     = FALSE,
            ...
          )
        }
      )
      all_results <- c(list(main_result), consistency_results)
      conf_scores <- .ac_compute_confidence(
        results    = all_results,
        cat_names  = cat_names,
        confidence = confidence
      )
    } else {
      conf_scores <- NULL
    }

    results[[i]] <- list(
      doc_id      = doc_id,
      main        = main_result,
      conf_scores = conf_scores
    )
  }

  # === Montar tibble final ====================================================
  .ac_build_result_tibble(
    results    = results,
    corpus     = corpus,
    cat_names  = cat_names,
    confidence = confidence,
    reasoning  = reasoning
  )
}


# ============================================================================
# Funcoes auxiliares internas
# ============================================================================

#' @keywords internal
#' @noRd
.ac_build_system_prompt <- function(codebook, reasoning, reasoning_length) {
  cat_descriptions <- purrr::map_chr(codebook$categories, function(cat) {
    ex_pos <- if (length(cat$examples_pos) > 0L) {
      paste0("\n  Exemplos positivos:\n",
             paste0("    - ", cat$examples_pos, collapse = "\n"))
    } else ""
    ex_neg <- if (length(cat$examples_neg) > 0L) {
      paste0("\n  Exemplos negativos:\n",
             paste0("    - ", cat$examples_neg, collapse = "\n"))
    } else ""
    paste0("- ", cat$name, ": ", cat$definition, ex_pos, ex_neg)
  })

  reasoning_instruction <- if (reasoning) {
    len_map <- c(
      short    = "1 frase curta e objetiva",
      medium   = "2-3 frases",
      detailed = "um parágrafo detalhado"
    )
    paste0(
      '\n  "raciocinio": "', len_map[reasoning_length],
      ' explicando por que o texto foi classificado nesta categoria",'
    )
  } else ""

  multilabel_instruction <- if (codebook$multilabel) {
    "Um texto pode pertencer a MAIS DE UMA categoria simultaneamente."
  } else {
    "Cada texto deve ser classificado em EXATAMENTE UMA categoria."
  }

  cat_names <- names(codebook$categories)

  paste0(
    "Você é um assistente especializado em análise de conteúdo qualitativa.\n\n",
    codebook$instructions, "\n\n",
    multilabel_instruction, "\n\n",
    "CATEGORIAS:\n",
    paste(cat_descriptions, collapse = "\n\n"),
    "\n\n",
    "Responda SEMPRE em formato JSON válido (sem markdown), seguindo exatamente:\n",
    "{\n",
    "  \"categoria\": \"", paste(cat_names, collapse = "|"), "\"",
    reasoning_instruction,
    "\n}"
  )
}


#' @keywords internal
#' @noRd
.ac_classify_one <- function(text, codebook, model, system_prompt,
                              temperature, reasoning, ...) {
  dots <- list(...)

  if (inherits(model, "Chat")) {
    chat <- model$clone()
    chat$set_system_prompt(system_prompt)
  } else {
    chat_args <- c(
      list(name = model, system_prompt = system_prompt),
      dots
    )
    chat <- tryCatch(
      do.call(ellmer::chat, chat_args),
      error = function(e) {
        cli::cli_abort(c(
          "Erro ao inicializar {.pkg ellmer}. Verifique o modelo e as credenciais.",
          "i" = "Modelo: {.val {model}}",
          "x" = conditionMessage(e)
        ))
      }
    )
  }

  user_msg <- paste0(
    "Classifique o seguinte texto:\n\n---\n", text, "\n---"
  )

  resposta <- tryCatch(
    chat$chat(user_msg),
    error = function(e) {
      cli::cli_warn("Erro ao classificar documento: {conditionMessage(e)}")
      return(NULL)
    }
  )

  if (is.null(resposta)) return(NULL)

  json_str <- stringr::str_extract(resposta, "\\{[^\\{\\}]*\\}")
  if (is.na(json_str)) json_str <- resposta

  parsed <- tryCatch(
    jsonlite::fromJSON(json_str),
    error = function(e) NULL
  )

  parsed
}


#' @keywords internal
#' @noRd
.ac_compute_confidence <- function(results, cat_names, confidence) {
  valid_results <- results[!purrr::map_lgl(results, is.null)]
  if (length(valid_results) == 0L) return(NULL)

  cats <- purrr::map_chr(valid_results, function(r) {
    r$categoria %||% NA_character_
  })

  mode_cat <- names(sort(table(cats), decreasing = TRUE))[1]
  agree    <- mean(cats == mode_cat, na.rm = TRUE)

  if (confidence %in% c("total", "both")) {
    list(total = agree, by_var = NULL, dominant = mode_cat)
  } else {
    list(total = NULL,
         by_var = stats::setNames(list(agree), mode_cat),
         dominant = mode_cat)
  }
}


#' @keywords internal
#' @noRd
.ac_confidence_level <- function(score) {
  dplyr::case_when(
    score >= 0.80 ~ "alta",
    score >= 0.61 ~ "media",
    TRUE          ~ "baixa"
  )
}


#' @keywords internal
#' @noRd
.ac_build_result_tibble <- function(results, corpus, cat_names,
                                     confidence, reasoning) {
  rows <- purrr::map(results, function(r) {
    main <- r$main
    conf <- r$conf_scores

    cat_val <- if (!is.null(main) && !is.null(main$categoria)) {
      as.character(main$categoria)
    } else NA_character_

    rac_val <- if (reasoning && !is.null(main) && !is.null(main$raciocinio)) {
      as.character(main$raciocinio)
    } else NA_character_

    conf_score <- if (!is.null(conf)) conf$total %||% NA_real_ else NA_real_
    conf_level <- if (!is.na(conf_score)) {
      .ac_confidence_level(conf_score)
    } else NA_character_

    row <- tibble::tibble(
      doc_id           = r$doc_id,
      categoria        = cat_val,
      confidence_score = conf_score,
      confidence_level = conf_level
    )

    if (reasoning) row$raciocinio <- rac_val

    row
  })

  result <- dplyr::bind_rows(rows)

  meta_cols <- setdiff(names(corpus), c("doc_id", "text"))
  if (length(meta_cols) > 0L) {
    meta <- corpus |>
      tibble::as_tibble() |>
      dplyr::select("doc_id", dplyr::all_of(meta_cols))
    result <- result |>
      dplyr::left_join(meta, by = "doc_id") |>
      dplyr::relocate(dplyr::all_of(meta_cols), .after = "doc_id")
  }

  cli::cli_inform(c(
    "i" = "Certeza calculada via self-consistency (Wang et al., 2023, EMNLP).",
    "i" = "Interpretação: >= 0.80 = alta | 0.61-0.79 = média | < 0.61 = baixa (Landis & Koch, 1977)."
  ))

  result
}
