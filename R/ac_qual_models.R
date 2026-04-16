#' Listar modelos LLM disponíveis para análise de conteúdo
#'
#' @description
#' `ac_qual_list_models()` retorna um tibble com os modelos LLM disponíveis
#' para uso com [ac_qual_code()], incluindo informações de custo, janela de
#' contexto e compatibilidade com análise de conteúdo qualitativa em
#' Ciências Sociais.
#'
#' Dois modos de operação:
#' * **`live = FALSE`** (padrão): usa banco interno curado, funciona offline.
#' * **`live = TRUE`**: consulta a API do provedor via `ellmer::models_*()`
#'   para obter a lista mais atualizada. Requer chave de API configurada.
#'
#' @param provider Provedor(es) a listar. Pode ser `"all"` (padrão) ou um
#'   ou mais de: `"anthropic"`, `"openai"`, `"google"`, `"groq"`,
#'   `"deepseek"`, `"mistral"`, `"ollama"`.
#' @param filter String para filtrar modelos por nome ou ID
#'   (ex: `"claude"`, `"gpt-4"`). Padrão: `NULL` (sem filtro).
#' @param sort_by Como ordenar os resultados: `"cost"` (padrão, menor custo
#'   primeiro), `"name"`, `"context"` (maior janela de contexto primeiro).
#' @param live Lógico. Se `TRUE`, consulta a API do provedor ao vivo via
#'   `ellmer::models_*()`. Requer chave de API. Padrão: `FALSE`.
#' @param ... Ignorado.
#'
#' @return Tibble com colunas:
#'   * `provider`: nome do provedor;
#'   * `model_id`: identificador do modelo para uso em [ac_qual_code()];
#'   * `name`: nome legível;
#'   * `context_k`: janela de contexto em milhares de tokens;
#'   * `cost_input`: custo por 1M tokens de entrada (USD), `NA` se gratuito/local;
#'   * `cost_output`: custo por 1M tokens de saída (USD);
#'   * `tier`: categoria (`"frontier"`, `"balanced"`, `"fast"`, `"free"`, `"local"`);
#'   * `pt_support`: suporte estimado ao português (`"alto"`, `"medio"`, `"baixo"`);
#'   * `acr_string`: string pronta para uso em `model = ...` no `acR`.
#'
#' @examples
#' # Listar todos os modelos do banco interno
#' ac_qual_list_models()
#'
#' # Só modelos Anthropic
#' ac_qual_list_models(provider = "anthropic")
#'
#' # Modelos baratos com suporte a PT
#' ac_qual_list_models(sort_by = "cost") |>
#'   dplyr::filter(pt_support == "alto", cost_input < 1)
#'
#' @seealso [ac_qual_recommend_model()], [ac_qual_code()]
#' @concept qualitative
#' @export
ac_qual_list_models <- function(provider = "all",
                                 filter   = NULL,
                                 sort_by  = c("cost", "name", "context"),
                                 live     = FALSE,
                                 ...) {

  sort_by <- match.arg(sort_by)

  if (isTRUE(live)) {
    return(.ac_list_models_live(provider = provider, filter = filter,
                                sort_by = sort_by))
  }

  # === Banco interno curado ================================================
  tbl <- .ac_models_db()

  # Filtrar por provedor
  if (!identical(provider, "all")) {
    tbl <- tbl[tbl$provider %in% tolower(provider), ]
  }

  # Filtrar por nome/id
  if (!is.null(filter)) {
    pat <- tolower(filter)
    tbl <- tbl[grepl(pat, tolower(tbl$model_id)) |
               grepl(pat, tolower(tbl$name)), ]
  }

  if (nrow(tbl) == 0L) {
    cli::cli_warn("Nenhum modelo encontrado com os filtros aplicados.")
    return(tbl)
  }

  # Ordenar
  if (sort_by == "cost") {
    tbl <- tbl[order(is.na(tbl$cost_input), tbl$cost_input), ]
  } else if (sort_by == "name") {
    tbl <- tbl[order(tbl$provider, tbl$name), ]
  } else {
    tbl <- tbl[order(-tbl$context_k), ]
  }

  tibble::as_tibble(tbl)
}


#' Recomendar modelo LLM para análise de conteúdo qualitativa
#'
#' @description
#' `ac_qual_recommend_model()` sugere o(s) modelo(s) mais adequado(s) para
#' uma tarefa específica de análise de conteúdo qualitativa, considerando
#' custo, desempenho em português e tipo de tarefa.
#'
#' As recomendações são baseadas em benchmarks de classificação de texto
#' em Ciências Sociais (Gilardi et al., 2023; Törnberg, 2023; Alizadeh
#' et al., 2023) e na experiência prática com corpora em português
#' brasileiro.
#'
#' @param task Tipo de tarefa:
#'   * `"coding"` (padrão): classificação de textos com codebook existente;
#'   * `"literature"`: geração de definições e busca de referências;
#'   * `"both"`: ambas as tarefas.
#' @param budget Orçamento disponível:
#'   * `"free"`: apenas modelos gratuitos ou locais;
#'   * `"low"`: até USD 1/1M tokens de entrada;
#'   * `"medium"`: até USD 5/1M tokens (padrão);
#'   * `"high"`: sem restrição de custo.
#' @param lang Idioma predominante do corpus: `"pt"` (padrão) ou `"en"`.
#' @param local Lógico. Se `TRUE`, prioriza modelos locais (Ollama).
#'   Padrão: `FALSE`.
#' @param n Número de recomendações a retornar. Padrão: `3`.
#' @param ... Ignorado.
#'
#' @return Tibble com as colunas de [ac_qual_list_models()] mais:
#'   * `rank`: posição na recomendação;
#'   * `score`: pontuação composta (0-100);
#'   * `justificativa`: texto explicando por que o modelo foi recomendado.
#'
#' @references
#' Gilardi, F.; Alizadeh, M.; Kubli, M. (2023). ChatGPT Outperforms Crowd
#' Workers for Text-Annotation Tasks. *PNAS*, 120(30).
#'
#' Tornberg, P. (2023). ChatGPT-4 Outperforms Experts and Crowd Workers
#' in Annotating Political Twitter Messages with Zero-Shot Learning.
#' *PLOS ONE*, 18(4).
#'
#' Alizadeh, M. et al. (2023). Open-Source LLMs for Text Annotation:
#' A Practical Guide for Model Setting and Fine-Tuning.
#' *arXiv*, 2307.02179.
#'
#' @examples
#' # Recomendação padrão para classificacao em PT com orcamento medio
#' ac_qual_recommend_model()
#'
#' # Opcao gratuita para explorar
#' ac_qual_recommend_model(budget = "free")
#'
#' # Local (Ollama) para dados sigilosos
#' ac_qual_recommend_model(local = TRUE)
#'
#' @seealso [ac_qual_list_models()], [ac_qual_code()]
#' @concept qualitative
#' @export
ac_qual_recommend_model <- function(task   = c("coding", "literature", "both"),
                                     budget = c("medium", "low", "high", "free"),
                                     lang   = "pt",
                                     local  = FALSE,
                                     n      = 3L,
                                     ...) {

  task   <- match.arg(task)
  budget <- match.arg(budget)

  tbl <- .ac_models_db()

  # Filtrar por local
  if (isTRUE(local)) {
    tbl <- tbl[tbl$tier == "local", ]
    if (nrow(tbl) == 0L) {
      cli::cli_abort(c(
        "Nenhum modelo local encontrado.",
        "i" = "Instale o Ollama em {.url https://ollama.com} e baixe um modelo.",
        "i" = "Exemplo: {.code ollama pull llama3.1:8b}"
      ))
    }
  } else {
    # Filtrar por budget
    budget_limit <- switch(budget,
      "free"   = 0,
      "low"    = 1,
      "medium" = 5,
      "high"   = Inf
    )
    tbl <- tbl[is.na(tbl$cost_input) | tbl$cost_input <= budget_limit, ]
  }

  if (nrow(tbl) == 0L) {
    cli::cli_abort(
      "Nenhum modelo encontrado para budget = {.val {budget}}."
    )
  }

  # Calcular score composto (0-100)
  tbl$score <- .ac_score_models(tbl, task = task, lang = lang)

  # Ordenar e pegar top n
  tbl <- tbl[order(-tbl$score), ]
  tbl <- tbl[seq_len(min(n, nrow(tbl))), ]
  tbl$rank <- seq_len(nrow(tbl))

  # Gerar justificativa
  tbl$justificativa <- purrr::map_chr(seq_len(nrow(tbl)), function(i) {
    .ac_model_justification(tbl[i, ], task = task, lang = lang,
                            budget = budget)
  })

  # Reordenar colunas
  cols <- c("rank", "provider", "model_id", "name", "tier",
            "context_k", "cost_input", "cost_output",
            "pt_support", "score", "justificativa", "acr_string")
  cols <- cols[cols %in% names(tbl)]

  cli::cli_h1("Recomendacoes de modelo {.pkg acR}")
  cli::cli_bullets(c(
    "i" = "Tarefa: {.val {task}} | Budget: {.val {budget}} | Idioma: {.val {lang}}",
    "i" = "Baseado em Gilardi et al. (2023, PNAS) e Tornberg (2023, PLOS ONE)."
  ))

  tibble::as_tibble(tbl[, cols])
}


# ============================================================================
# Banco interno de modelos
# ============================================================================

#' @keywords internal
#' @noRd
.ac_models_db <- function() {
  tibble::tribble(
    ~provider,    ~model_id,                           ~name,
    ~context_k,   ~cost_input, ~cost_output,
    ~tier,        ~pt_support,

    # === ANTHROPIC ===========================================================
    "anthropic", "anthropic/claude-opus-4-5",
    "Claude Opus 4.5",
    200, 15.0, 75.0, "frontier", "alto",

    "anthropic", "anthropic/claude-sonnet-4-5",
    "Claude Sonnet 4.5",
    200, 3.0, 15.0, "balanced", "alto",

    "anthropic", "anthropic/claude-haiku-4-5",
    "Claude Haiku 4.5",
    200, 0.8, 4.0, "fast", "alto",

    "anthropic", "anthropic/claude-3-5-sonnet-20241022",
    "Claude 3.5 Sonnet",
    200, 3.0, 15.0, "balanced", "alto",

    "anthropic", "anthropic/claude-3-5-haiku-20241022",
    "Claude 3.5 Haiku",
    200, 0.8, 4.0, "fast", "alto",

    # === OPENAI ==============================================================
    "openai", "openai/gpt-4.1",
    "GPT-4.1",
    128, 2.0, 8.0, "frontier", "alto",

    "openai", "openai/gpt-4.1-mini",
    "GPT-4.1 Mini",
    128, 0.4, 1.6, "fast", "alto",

    "openai", "openai/gpt-4.1-nano",
    "GPT-4.1 Nano",
    128, 0.1, 0.4, "fast", "medio",

    "openai", "openai/o3",
    "o3 (reasoning)",
    200, 10.0, 40.0, "frontier", "alto",

    "openai", "openai/o4-mini",
    "o4-mini (reasoning)",
    200, 1.1, 4.4, "balanced", "alto",

    # === GOOGLE ==============================================================
    "google", "google/gemini-2.0-flash",
    "Gemini 2.0 Flash",
    1000, 0.1, 0.4, "fast", "alto",

    "google", "google/gemini-2.5-pro",
    "Gemini 2.5 Pro",
    1000, 1.25, 10.0, "frontier", "alto",

    "google", "google/gemini-2.0-flash-lite",
    "Gemini 2.0 Flash Lite",
    1000, 0.075, 0.3, "fast", "medio",

    # === GROQ (inferencia rapida, gratuito com limites) ======================
    "groq", "groq/llama-3.3-70b-versatile",
    "Llama 3.3 70B (Groq)",
    128, 0.59, 0.79, "balanced", "medio",

    "groq", "groq/llama-3.1-8b-instant",
    "Llama 3.1 8B Instant (Groq)",
    128, 0.05, 0.08, "fast", "baixo",

    "groq", "groq/gemma2-9b-it",
    "Gemma2 9B (Groq)",
    8, 0.2, 0.2, "fast", "medio",

    # === DEEPSEEK ============================================================
    "deepseek", "deepseek/deepseek-chat",
    "DeepSeek-V3",
    64, 0.27, 1.1, "balanced", "medio",

    "deepseek", "deepseek/deepseek-reasoner",
    "DeepSeek-R1 (reasoning)",
    64, 0.55, 2.19, "balanced", "medio",

    # === MISTRAL =============================================================
    "mistral", "mistral/mistral-large-latest",
    "Mistral Large",
    128, 2.0, 6.0, "balanced", "medio",

    "mistral", "mistral/mistral-small-latest",
    "Mistral Small",
    32, 0.1, 0.3, "fast", "medio",

    # === OLLAMA (local, gratuito) ============================================
    "ollama", "ollama/llama3.3:70b",
    "Llama 3.3 70B (local)",
    128, NA_real_, NA_real_, "local", "medio",

    "ollama", "ollama/llama3.1:8b",
    "Llama 3.1 8B (local)",
    128, NA_real_, NA_real_, "local", "baixo",

    "ollama", "ollama/gemma3:27b",
    "Gemma 3 27B (local)",
    128, NA_real_, NA_real_, "local", "medio",

    "ollama", "ollama/qwen2.5:72b",
    "Qwen 2.5 72B (local, bom PT)",
    128, NA_real_, NA_real_, "local", "alto",

    "ollama", "ollama/mistral:7b",
    "Mistral 7B (local)",
    32, NA_real_, NA_real_, "local", "baixo"
  ) |>
    dplyr::mutate(
      acr_string = dplyr::case_when(
        tier == "local" ~
          paste0(
            'ellmer::chat_ollama(model = "',
            sub("ollama/", "", model_id), '")'
          ),
        TRUE ~ paste0('model = "', model_id, '"')
      )
    )
}


# ============================================================================
# Score composto para recomendação
# ============================================================================

#' @keywords internal
#' @noRd
.ac_score_models <- function(tbl, task, lang) {

  n <- nrow(tbl)
  score <- numeric(n)

  for (i in seq_len(n)) {
    m <- tbl[i, ]

    # 1. Custo (0-30 pts): modelos mais baratos ganham mais pontos
    if (is.na(m$cost_input)) {
      # local = 15 pts (gratuito mas limitado)
      s_cost <- 15
    } else if (m$cost_input == 0) {
      s_cost <- 30
    } else {
      # Escala inversa: USD 0.1 = 28 pts, USD 1 = 22 pts, USD 5 = 15 pts,
      # USD 15+ = 5 pts
      s_cost <- max(5, 30 - log1p(m$cost_input) * 8)
    }

    # 2. Suporte ao portugues (0-25 pts)
    s_pt <- switch(m$pt_support,
      "alto"  = if (lang == "pt") 25 else 15,
      "medio" = if (lang == "pt") 12 else 18,
      "baixo" = if (lang == "pt")  3 else 10,
      10
    )

    # 3. Adequacao a tarefa (0-25 pts)
    s_task <- switch(task,
      "coding" = switch(m$tier,
        "frontier" = 20, "balanced" = 25, "fast" = 18, "local" = 12, 15
      ),
      "literature" = switch(m$tier,
        "frontier" = 25, "balanced" = 20, "fast" = 10, "local" = 8, 12
      ),
      "both" = switch(m$tier,
        "frontier" = 22, "balanced" = 23, "fast" = 14, "local" = 10, 14
      )
    )

    # 4. Janela de contexto (0-10 pts)
    s_ctx <- min(10, m$context_k / 100)

    # 5. Bonus por tier para reasoning tasks
    s_bonus <- 0
    if (task %in% c("literature", "both") &&
        grepl("reasoning|o3|o4|r1", tolower(m$name))) {
      s_bonus <- 8
    }

    score[i] <- round(s_cost + s_pt + s_task + s_ctx + s_bonus, 1)
  }

  score
}


#' @keywords internal
#' @noRd
.ac_model_justification <- function(row, task, lang, budget) {
  parts <- character(0)

  # Custo
  if (is.na(row$cost_input)) {
    parts <- c(parts, "gratuito (local)")
  } else if (row$cost_input < 0.5) {
    parts <- c(parts, paste0("baixo custo (USD ", row$cost_input,
                              "/1M tokens entrada)"))
  } else if (row$cost_input < 3) {
    parts <- c(parts, paste0("custo moderado (USD ", row$cost_input,
                              "/1M tokens)"))
  } else {
    parts <- c(parts, paste0("alto desempenho (USD ", row$cost_input,
                              "/1M tokens)"))
  }

  # PT
  if (lang == "pt") {
    parts <- c(parts, switch(row$pt_support,
      "alto"  = "excelente suporte ao portugues",
      "medio" = "suporte razoavel ao portugues",
      "baixo" = "suporte limitado ao portugues"
    ))
  }

  # Tarefa
  if (task == "coding") {
    if (row$tier == "balanced") {
      parts <- c(parts, "balanco ideal custo x qualidade para classificacao")
    } else if (row$tier == "fast") {
      parts <- c(parts, "rapido para grandes volumes de texto")
    } else if (row$tier == "frontier") {
      parts <- c(parts, "maxima precisao na classificacao")
    }
  } else if (task == "literature") {
    if (row$tier == "frontier") {
      parts <- c(parts, "melhor para geracao de definicoes academicas")
    }
    if (grepl("reasoning|o3|o4|r1", tolower(row$name))) {
      parts <- c(parts, "capacidade de raciocinio avancado para literatura")
    }
  }

  # Contexto
  if (!is.na(row$context_k) && row$context_k >= 200) {
    parts <- c(parts, paste0("janela de contexto ampla (", row$context_k,
                              "k tokens)"))
  }

  # Local
  if (row$tier == "local") {
    parts <- c(parts, "dados nao saem do computador (privacidade)")
  }

  paste(parts, collapse = "; ")
}


# ============================================================================
# Listagem ao vivo via ellmer
# ============================================================================

#' @keywords internal
#' @noRd
.ac_list_models_live <- function(provider, filter, sort_by) {
  if (!requireNamespace("ellmer", quietly = TRUE)) {
    cli::cli_abort("O pacote {.pkg ellmer} e necessario para {.arg live = TRUE}.")
  }

  providers_map <- list(
    anthropic = "ellmer::models_anthropic",
    openai    = "ellmer::models_openai",
    google    = "ellmer::models_google_gemini",
    groq      = "ellmer::models_groq",
    mistral   = "ellmer::models_mistral",
    deepseek  = "ellmer::models_deepseek",
    ollama    = "ellmer::models_ollama"
  )

  if (identical(provider, "all")) {
    providers_use <- names(providers_map)
  } else {
    providers_use <- intersect(tolower(provider), names(providers_map))
    if (length(providers_use) == 0L) {
      cli::cli_abort(c(
        "Provedor {.val {provider}} nao suportado para busca ao vivo.",
        "i" = "Provedores disponiveis: {.val {names(providers_map)}}."
      ))
    }
  }

  results <- purrr::map(providers_use, function(prov) {
    fn_name <- providers_map[[prov]]
    fn      <- tryCatch(
      eval(parse(text = fn_name)),
      error = function(e) NULL
    )
    if (is.null(fn)) return(NULL)

    tbl <- tryCatch(
      fn(),
      error = function(e) {
        cli::cli_warn(c(
          "Nao foi possivel listar modelos de {.val {prov}}.",
          "i" = "Verifique se a chave de API esta configurada.",
          "x" = conditionMessage(e)
        ))
        return(NULL)
      }
    )
    if (is.null(tbl)) return(NULL)

    tbl <- tibble::as_tibble(tbl)
    tbl$provider <- prov

    # Normalizar colunas
    if ("id" %in% names(tbl)) tbl$model_id <- paste0(prov, "/", tbl$id)
    if (!"name" %in% names(tbl) && "id" %in% names(tbl)) tbl$name <- tbl$id
    if (!"input" %in% names(tbl)) tbl$input <- NA_real_
    if (!"output" %in% names(tbl)) tbl$output <- NA_real_

    tbl |>
      dplyr::select(
        provider,
        model_id,
        name,
        cost_input  = input,
        cost_output = output
      ) |>
      dplyr::mutate(
        context_k   = NA_real_,
        tier        = "unknown",
        pt_support  = "unknown",
        acr_string  = paste0('model = "', model_id, '"')
      )
  })

  tbl_all <- dplyr::bind_rows(purrr::compact(results))

  if (!is.null(filter)) {
    pat <- tolower(filter)
    tbl_all <- tbl_all[grepl(pat, tolower(tbl_all$model_id)) |
                       grepl(pat, tolower(tbl_all$name)), ]
  }

  if (sort_by == "cost") {
    tbl_all <- tbl_all[order(is.na(tbl_all$cost_input), tbl_all$cost_input), ]
  } else if (sort_by == "name") {
    tbl_all <- tbl_all[order(tbl_all$provider, tbl_all$name), ]
  }

  cli::cli_inform(c(
    "i" = "{nrow(tbl_all)} modelos encontrados via API ao vivo.",
    "i" = "Para detalhes de contexto e PT, use {.code live = FALSE}."
  ))

  tbl_all
}
