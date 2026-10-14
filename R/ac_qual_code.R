#' Classificar textos com LLM usando um codebook
#'
#' @description
#' `ac_qual_code()` classifica os textos de um `ac_corpus` de acordo com um
#' `ac_codebook`, usando um modelo de linguagem via `ellmer`. Retorna um tibble
#' com a classificação, grau de certeza (via self-consistency) e raciocínio
#' da LLM para cada documento.
#'
#' É o **motor de classificação** do pipeline qualitativo do `acR`. Assume
#' que o codebook já foi construído com [ac_qual_codebook()] e (idealmente)
#' testado numa amostra piloto. A saída é sempre validada com
#' [ac_qual_reliability()] contra uma amostra codificada por humano —
#' nenhuma análise categorial publicável dispensa essa etapa.
#'
#' Três parâmetros determinam qualidade e custo:
#'
#' * `k_consistency`: número de rodadas de *self-consistency* (Wang et al.,
#'   2023). O mesmo texto é classificado k vezes com pequena variação de
#'   temperatura, e a categoria final é a moda. O `confidence_score` sai
#'   dessa concordância — 1,0 significa que todas as k rodadas concordaram.
#'   Padrão `k = 3` custa 3x mais tokens que uma rodada única, e é a
#'   configuração mínima para reportar confiança de forma defensável.
#' * `reasoning`: pede raciocínio estruturado. Melhora a qualidade em casos
#'   ambíguos mas praticamente dobra o custo por documento. Use `"short"`
#'   como padrão e `"detailed"` só quando planeja auditar decisões
#'   individuais.
#' * `live`: tira a classificação do modo "caixa-preta" mostrando cada
#'   documento em tempo real. Numa rodada de 500 discursos, você percebe
#'   nos primeiros 10 se o codebook está funcionando — antes de gastar
#'   todo o orçamento de tokens.
#'
#' @param corpus Objeto `ac_corpus`.
#' @param codebook Objeto `ac_codebook`, saída de [ac_qual_codebook()].
#' @param model Modelo LLM a usar. Aceita string no formato
#'   `"provedor/modelo"` (ex: `"anthropic/claude-sonnet-4-5"`,
#'   `"openai/gpt-4.1"`), objeto `Chat` do pacote `ellmer`
#'   pré-configurado, ou função fábrica
#'   `function(temperature, system_prompt) Chat` para controle total
#'   sobre a construção do chat a cada rodada. Quando `chat` é fornecido,
#'   `model` é ignorado.
#' @param chat Objeto `Chat` do pacote `ellmer` (ex: `chat_google_gemini()`,
#'   `chat_openai()`, `chat_ollama()`). Quando fornecido, tem prioridade sobre
#'   `model`. Permite usar qualquer provedor suportado pelo `ellmer`.
#' @param confidence Como calcular certeza:
#'   * `"total"` (padrão): uma coluna `confidence_score` com a proporção
#'     de rodadas de self-consistency que concordaram com a categoria
#'     vencedora (moda);
#'   * `"by_variable"`: uma coluna `<categoria>_confidence` por
#'     categoria do codebook, com a proporção de rodadas que escolheram
#'     *aquela* categoria especificamente (não só a vencedora) — útil
#'     para montar uma matriz de confiança por tema/categoria;
#'   * `"both"`: as colunas por categoria + `confidence_score` (a da
#'     vencedora);
#'   * `"none"`: não calcula certeza (mais rápido, menor custo).
#' @param k_consistency Número de rodadas para self-consistency. Padrão: `3`.
#'   Ignorado se `confidence = "none"`.
#' @param temperature Temperatura das rodadas de consistency. Padrão: `0.3`.
#' @param reasoning Lógico. Se `TRUE` (padrão), inclui coluna `raciocinio`
#'   com justificativa da classificação.
#' @param reasoning_length Tamanho do raciocínio: `"short"` (1 frase, padrão),
#'   `"medium"` (3 frases), `"detailed"` (parágrafo).
#' @param main_temperature Temperatura da rodada principal (a que gera
#'   `categoria`, `categoria_label` e `raciocinio` no resultado final).
#'   Padrão `0` (determinística). Separado de `temperature` (usado só nas
#'   rodadas extras de self-consistency) porque os dois cumprem papéis
#'   diferentes: a rodada principal deve ser reprodutível, as extras devem
#'   variar para medir concordância.
#' @param reasoning_extras Lógico. Se `TRUE`, pede raciocínio também nas
#'   rodadas extras de self-consistency (mais caro, não usado no resultado
#'   final). Padrão `FALSE`.
#' @param live Visualização em tempo real da classificação:
#'   * `"off"` (padrão): sem live view;
#'   * `"terminal"`: barra de progresso com doc atual, categoria, confiança e
#'     início do raciocínio a cada iteração;
#'   * `"progress"`: barra de progresso enxuta (doc atual e status), sem
#'     ecoar categoria/raciocínio — útil para rodadas grandes onde o
#'     terminal ficaria poluído;
#'   * `"shiny"`: abre janela Shiny em background com tabela atualizando
#'     conforme documentos são classificados (requer `shiny` e `callr`).
#' @param max_retries Número máximo de novas tentativas por rodada quando a
#'   chamada ao LLM falha (erro de rede, timeout, resposta inválida).
#'   Padrão `2`. Espera exponencial entre tentativas (até 30s). Quando o
#'   erro é classificado como `"estouro_contexto"`, não há nova tentativa
#'   (repetir não resolve). Se mais da metade dos últimos 5+ documentos
#'   falhar, a execução é abortada com sugestão de usar `checkpoint_dir`.
#' @param checkpoint_dir Diretório para salvar o resultado de cada documento
#'   assim que classificado. Se já existir um checkpoint válido para um
#'   `doc_id` (mesmos `codebook`, `model`, `k_consistency` e `temperature`),
#'   o documento é pulado e o resultado salvo é reutilizado — permite
#'   retomar uma rodada interrompida sem reclassificar tudo. `NULL`
#'   (padrão): sem checkpoint.
#' @param ... Argumentos adicionais passados a `ellmer::chat()`.
#'   Permite uso de APIs OpenAI-compatible self-hosted via `base_url`.
#'
#' @return Tibble com colunas:
#'   * `doc_id`: identificador do documento;
#'   * Metadados originais do corpus;
#'   * `categoria`: slug interno da categoria (chave da lista
#'     `categories` no codebook). Em `multilabel = TRUE`, string
#'     pipe-separada sem espaço (`"tecnica|politica"`).
#'   * `categoria_label`: rótulo humano correspondente, vindo do campo
#'     `label` de cada categoria (se ausente, repete o slug). Em
#'     multilabel, unidos por `" | "` (espaço dos dois lados).
#'   * `confidence_score`: grau de certeza da categoria vencedora (0-1).
#'     Presente quando `confidence` é `"total"` ou `"both"`.
#'   * `confidence_level`: `"alta"`, `"media"`, `"baixa"` — interpretação
#'     de `confidence_score` (Landis & Koch, 1977). Acompanha
#'     `confidence_score`.
#'   * `<categoria>_confidence`: uma coluna por categoria do codebook
#'     (ex.: `positivo_confidence`, `negativo_confidence`), com a
#'     proporção de rodadas de self-consistency que escolheram aquela
#'     categoria. Presentes quando `confidence` é `"by_variable"` ou
#'     `"both"`.
#'   * `raciocinio`: justificativa da classificação (se `reasoning = TRUE`).
#'   * `status`: resultado da rodada principal: `"ok"`, `"resposta_invalida"`
#'     (JSON não parseável), `"estouro_contexto"`, `"timeout"` ou
#'     `"erro_servidor"`.
#'   * `n_tentativas`: número de tentativas até obter `status = "ok"` (ou
#'     até esgotar `max_retries`).
#'   * `tokens_entrada`, `tokens_saida`: tokens de entrada/saída da rodada
#'     principal, via `chat$get_tokens()` (`NA` se o provedor não expõe).
#'   * `segundos`: tempo total da rodada principal, incluindo novas
#'     tentativas.
#'   * `tokens_por_segundo`: `tokens_saida / segundos`.
#'
#'   O resultado carrega também um atributo `run_info` (ver
#'   [attributes()]) com metadados da execução: versões de `acR` e
#'   `ellmer`, modelo, `base_url`, parâmetros efetivos aplicados ao
#'   provedor, temperaturas pedidas, `k_consistency`, hash do codebook e
#'   timestamps de início/fim.
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
#' chat_groq <- ellmer::chat_groq(model = "openai/gpt-oss-120b", echo = "none")
#' coded <- ac_qual_code(corpus, cb, chat = chat_groq)
#'
#' # Ollama (modelos locais, sem envio de dados externos)
#' chat_local <- ellmer::chat_ollama(model = "llama3.2", echo = "none")
#' coded <- ac_qual_code(corpus, cb, chat = chat_local)
#'
#' # confidence = "both": alem de confidence_score (categoria vencedora),
#' # ganha uma coluna <categoria>_confidence por categoria do codebook --
#' # util para montar uma matriz de confianca por tema entre documentos
#' # ou comparar modelos na mesma tarefa.
#' coded_both <- ac_qual_code(corpus, cb, model = "anthropic/claude-sonnet-4-5",
#'                             confidence = "both")
#' coded_both[, c("doc_id", "categoria", "confidence_score",
#'                "positivo_confidence", "negativo_confidence")]
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
                          main_temperature   = 0,
                          reasoning_extras   = FALSE,
                          live               = c("off", "terminal", "progress",
                                                 "shiny"),
                          max_retries        = 2L,
                          checkpoint_dir     = NULL,
                          ...) {

  # === Validacoes =============================================================
  if (!is_ac_corpus(corpus)) {
    cli::cli_abort("{.arg corpus} deve ser um {.cls ac_corpus}.")
  }
  if (!inherits(codebook, "ac_codebook")) {
    cli::cli_abort("{.arg codebook} deve ser um {.cls ac_codebook}.")
  }
  if (!requireNamespace("ellmer", quietly = TRUE)) {
    cli::cli_abort("O pacote {.pkg ellmer} \u00e9 necess\u00e1rio.")
  }
  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    cli::cli_abort("O pacote {.pkg jsonlite} \u00e9 necess\u00e1rio.")
  }
  if (!is.null(chat) && !inherits(chat, "Chat")) {
    cli::cli_abort(
      "{.arg chat} deve ser um objeto {.cls Chat} do pacote {.pkg ellmer}."
    )
  }

  confidence       <- match.arg(confidence)
  reasoning_length <- match.arg(reasoning_length)
  live             <- match.arg(live)
  k_consistency    <- as.integer(k_consistency)
  max_retries      <- as.integer(max_retries)
  do_confidence    <- confidence != "none"

  if (live == "shiny" && !requireNamespace("shiny", quietly = TRUE)) {
    cli::cli_warn(c(
      "Pacote {.pkg shiny} nao encontrado; caindo para {.val terminal}.",
      "i" = "Instale com {.code install.packages(\"shiny\")}."
    ))
    live <- "terminal"
  }

  if (!is.null(checkpoint_dir)) {
    if (!dir.exists(checkpoint_dir)) dir.create(checkpoint_dir, recursive = TRUE)
  }
  ck_hash <- if (!is.null(checkpoint_dir)) {
    rlang::hash(list(codebook = codebook, model = model, k_consistency = k_consistency,
                     temperature = temperature, main_temperature = main_temperature))
  } else NULL
  if (!is.null(checkpoint_dir)) .ac_ck_check_meta(checkpoint_dir, ck_hash)

  # chat tem prioridade sobre model
  effective_model <- if (!is.null(chat)) chat else model

  cat_names <- names(codebook$categories)

  # === Construir system prompt ================================================
  system_prompt <- .ac_build_system_prompt_with_weight(codebook, reasoning, reasoning_length)

  # === Classificar cada documento =============================================
  n_docs      <- nrow(corpus)
  model_label <- if (!is.null(chat)) class(chat)[1] else model

  cli::cli_inform(c(
    "i" = "Classificando {n_docs} documento{?s} com {.val {model_label}}...",
    "i" = "Categorias: {.val {cat_names}}",
    if (do_confidence) "i" = "Self-consistency: k = {k_consistency} rodadas"
  ))

  results      <- vector("list", n_docs)
  status_hist  <- character(0)
  start_time   <- Sys.time()

  live_ctx <- .ac_live_start(live, n_docs)
  on.exit(.ac_live_finish(live_ctx), add = TRUE)

  for (i in seq_len(n_docs)) {
    texto  <- corpus$text[i]
    doc_id <- corpus$doc_id[i]

    ck_path <- if (!is.null(checkpoint_dir)) .ac_ck_path(checkpoint_dir, doc_id) else NULL
    if (!is.null(ck_path) && file.exists(ck_path)) {
      results[[i]] <- readRDS(ck_path)
      status_hist  <- c(status_hist, results[[i]]$status %||% "ok")
      .ac_live_update(live_ctx, i, n_docs, doc_id, results[[i]]$main, results[[i]]$conf_scores,
                      doc_status = results[[i]]$status)
      next
    }

    main_attempt <- .ac_classify_with_retry(
      text          = texto,
      codebook      = codebook,
      model         = effective_model,
      system_prompt = system_prompt,
      temperature   = main_temperature,
      reasoning     = reasoning,
      max_retries   = max_retries,
      ...
    )
    main_result <- main_attempt$parsed

    if (do_confidence && k_consistency > 1L && main_attempt$status == "ok") {
      consistency_attempts <- purrr::map(
        seq_len(k_consistency - 1L),
        function(k) {
          .ac_classify_with_retry(
            text          = texto,
            codebook      = codebook,
            model         = effective_model,
            system_prompt = system_prompt,
            temperature   = temperature,
            reasoning     = reasoning_extras,
            max_retries   = max_retries,
            ...
          )
        }
      )
      all_results <- c(list(main_result), purrr::map(consistency_attempts, "parsed"))
      conf_scores <- .ac_compute_confidence(
        results    = all_results,
        cat_names  = cat_names,
        confidence = confidence
      )
    } else {
      conf_scores <- NULL
    }

    status_hist <- c(status_hist, main_attempt$status)
    if (length(status_hist) >= 5L) {
      janela <- utils::tail(status_hist, max(5L, length(status_hist)))
      taxa_falha <- mean(janela != "ok")
      if (taxa_falha > 0.5) {
        pct_falha <- round(taxa_falha * 100)
        cli::cli_abort(c(
          "Mais da metade dos últimos {length(janela)} documentos falhou ({pct_falha}%).",
          "i" = "Interrompendo para evitar desperdiçar cota de tokens em um provedor/servidor instavel.",
          "i" = if (is.null(checkpoint_dir)) {
            "Use {.arg checkpoint_dir} para salvar o progresso e poder retomar depois de investigar."
          } else {
            "O progresso ate aqui foi salvo em {.path {checkpoint_dir}}; corrija o problema e rode novamente."
          }
        ))
      }
    }

    results[[i]] <- list(
      doc_id        = doc_id,
      main          = main_result,
      conf_scores   = conf_scores,
      status        = main_attempt$status,
      n_tentativas  = main_attempt$n_tentativas,
      tokens_entrada = main_attempt$tokens$input,
      tokens_saida   = main_attempt$tokens$output,
      segundos       = main_attempt$segundos
    )

    if (!is.null(ck_path)) {
      tmp <- paste0(ck_path, ".tmp")
      saveRDS(results[[i]], tmp)
      file.rename(tmp, ck_path)
    }

    .ac_live_update(live_ctx, i, n_docs, doc_id, main_result, conf_scores,
                    doc_status = main_attempt$status)
  }

  # === Montar tibble final ====================================================
  resultado <- .ac_build_result_tibble(
    results    = results,
    corpus     = corpus,
    cat_names  = cat_names,
    codebook   = codebook,
    confidence = confidence,
    reasoning  = reasoning
  )

  attr(resultado, "run_info") <- .ac_build_run_info(
    effective_model = effective_model, model = model, chat = chat,
    temperature = temperature, main_temperature = main_temperature,
    k_consistency = k_consistency, codebook = codebook,
    n_docs = n_docs, start_time = start_time
  )

  resultado
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
      detailed = "um par\u00e1grafo detalhado"
    )
    paste0(
      '\n  "raciocinio": "', len_map[reasoning_length],
      ' explicando por que o texto foi classificado nesta categoria",'
    )
  } else ""

  multilabel_instruction <- if (codebook$multilabel) {
    paste(
      "Um texto pode pertencer a MAIS DE UMA categoria simultaneamente.",
      "Se mais de uma categoria se aplicar, responda com uma UNICA STRING",
      "contendo os nomes das categorias escolhidas separados por \"|\"",
      "(exemplo: \"tecnica|politica\"). NUNCA responda com um array JSON",
      "(ex.: [\"tecnica\", \"politica\"]) -- o campo \"categoria\" deve ser",
      "SEMPRE uma string, mesmo quando multiplas categorias se aplicam."
    )
  } else {
    "Cada texto deve ser classificado em EXATAMENTE UMA categoria."
  }

  cat_names <- names(codebook$categories)

  paste0(
    "Voc\u00ea \u00e9 um assistente especializado em an\u00e1lise de conte\u00fado qualitativa.\n\n",
    codebook$instructions, "\n\n",
    multilabel_instruction, "\n\n",
    "CATEGORIAS:\n",
    paste(cat_descriptions, collapse = "\n\n"),
    "\n\n",
    "Responda SEMPRE em formato JSON v\u00e1lido (sem markdown), seguindo exatamente:\n",
    "{\n",
    "  \"categoria\": \"", paste(cat_names, collapse = "|"), "\"",
    reasoning_instruction,
    "\n}"
  )
}


#' @keywords internal
#' @noRd
#'
#' Aplica `temperature` a um `Chat` ja construido, mutando o objeto
#' `Model` associado via `set_model()`/`get_model_object()` (API estavel
#' desde o ellmer 0.5.0). Se a API nao existir ou a mutacao falhar, avisa
#' explicitamente -- nunca degrada em silencio para a temperatura padrao
#' do provedor, que e o bug original (self-consistency rodando as k
#' rodadas na mesma temperatura, inflando `confidence_score`).
.ac_chat_with_temperature <- function(chat, system_prompt, temperature) {
  out <- chat$clone()
  out$set_system_prompt(system_prompt)

  if (is.null(temperature)) return(out)

  applied <- tryCatch({
    mod <- out$get_model_object()
    mod@params <- ellmer::params(temperature = temperature)
    out$set_model(mod)
    TRUE
  }, error = function(e) FALSE)

  if (!applied) {
    cli::cli_warn(c(
      "Nao foi possivel aplicar {.arg temperature} = {temperature} ao objeto {.cls Chat} fornecido.",
      "i" = "A rodada usara a temperatura padrao do provedor; self-consistency pode ficar inflado.",
      "i" = "Verifique a versao de {.pkg ellmer} instalada ({.code packageVersion(\"ellmer\")})."
    ))
  }

  out
}


#' @keywords internal
#' @noRd
#'
#' Constroi (ou reutiliza) o `Chat` usado para uma unica rodada de
#' classificacao, garantindo que `temperature` e `system_prompt` sejam
#' de fato aplicados -- seja `model` uma string `"provedor/modelo"`, um
#' objeto `Chat` pre-configurado, ou uma funcao-fabrica
#' `function(temperature, system_prompt) Chat`.
.ac_make_chat <- function(model, system_prompt, temperature, dots) {
  if (is.function(model)) {
    return(model(temperature = temperature, system_prompt = system_prompt))
  }

  if (inherits(model, "Chat")) {
    return(.ac_chat_with_temperature(model, system_prompt, temperature))
  }

  if (!is.null(temperature) && is.null(dots$params)) {
    dots$params <- ellmer::params(temperature = temperature)
  }
  # Saida enxuta por padrao: chats construidos internamente pelo acR nao
  # devem ecoar tokens no console a cada rodada de self-consistency --
  # com k = 3+ por documento isso polui o terminal sem acrescentar nada
  # que `live` ja nao mostre de forma resumida. Usuario pode sobrescrever
  # passando `echo` explicitamente em `...`.
  if (is.null(dots$echo)) dots$echo <- "none"

  chat_args <- c(list(name = model, system_prompt = system_prompt), dots)
  tryCatch(
    do.call(.ac_ellmer_chat, chat_args),
    error = function(e) {
      cli::cli_abort(c(
        "Erro ao inicializar {.pkg ellmer}. Verifique o modelo e as credenciais.",
        "i" = "Modelo: {.val {model}}",
        "x" = conditionMessage(e)
      ))
    }
  )
}


#' @keywords internal
#' @noRd
#'
#' Classifica categorias de erro de rede/servidor em um rotulo estavel
#' para a coluna `status`, usado para decidir se vale a pena tentar de
#' novo (estouro de contexto nao se resolve com retry) e para o relatorio
#' de qualidade de execucao.
.ac_status_do_erro <- function(msg) {
  msg <- tolower(msg %||% "")
  if (grepl("context|token|too long|maximum|context_length", msg)) {
    "estouro_contexto"
  } else if (grepl("timeout|timed out", msg)) {
    "timeout"
  } else {
    "erro_servidor"
  }
}


#' @keywords internal
#' @noRd
#'
#' Executa uma rodada de classificacao e devolve status/tokens/tempo
#' junto com o JSON parseado (ou NULL). Nao tenta de novo sozinha -- isso
#' e responsabilidade de `.ac_classify_with_retry()`.
.ac_classify_one <- function(text, codebook, model, system_prompt,
                              temperature, reasoning, ...) {
  dots <- list(...)

  chat <- .ac_make_chat(model, system_prompt, temperature, dots)

  user_msg <- paste0(
    "Classifique o seguinte texto:\n\n---\n", text, "\n---"
  )

  erro_msg <- NULL
  resposta <- tryCatch(
    chat$chat(user_msg),
    error = function(e) {
      erro_msg <<- conditionMessage(e)
      NULL
    }
  )

  tokens <- tryCatch({
    tk <- chat$get_tokens()
    list(input = utils::tail(tk$input, 1L), output = utils::tail(tk$output, 1L))
  }, error = function(e) list(input = NA_real_, output = NA_real_))

  if (is.null(resposta)) {
    return(list(parsed = NULL, status = .ac_status_do_erro(erro_msg), tokens = tokens))
  }

  json_str <- stringr::str_extract(resposta, "\\{[^\\{\\}]*\\}")
  if (is.na(json_str)) json_str <- resposta

  parsed <- tryCatch(
    jsonlite::fromJSON(json_str),
    error = function(e) NULL
  )

  status <- if (is.null(parsed)) "resposta_invalida" else "ok"
  list(parsed = parsed, status = status, tokens = tokens)
}


#' @keywords internal
#' @noRd
#'
#' Envolve `.ac_classify_one()` com novas tentativas e espera
#' exponencial. Nao tenta de novo quando o erro e `"estouro_contexto"`
#' (repetir a mesma chamada nao resolve). Devolve `n_tentativas` e
#' `segundos` (tempo total gasto, incluindo as tentativas) junto com o
#' resultado da ultima tentativa.
.ac_classify_with_retry <- function(text, codebook, model, system_prompt,
                                     temperature, reasoning, max_retries, ...) {
  inicio    <- Sys.time()
  tentativa <- 0L
  repeat {
    res <- .ac_classify_one(text, codebook, model, system_prompt,
                            temperature, reasoning, ...)
    tentativa <- tentativa + 1L
    if (res$status == "ok" || res$status == "estouro_contexto") break
    if (tentativa > max_retries) break
    Sys.sleep(min(2^tentativa, 30))
  }
  res$n_tentativas <- tentativa
  res$segundos     <- as.numeric(difftime(Sys.time(), inicio, units = "secs"))
  res
}


#' @keywords internal
#' @noRd
.ac_ck_path <- function(dir, doc_id) {
  file.path(dir, paste0(gsub("[^A-Za-z0-9._-]+", "_", doc_id), ".rds"))
}


#' @keywords internal
#' @noRd
#'
#' Invalida checkpoints de uma rodada anterior com parametros diferentes
#' (codebook, model, k_consistency ou temperature mudaram) -- sem isso,
#' retomar uma pasta de checkpoint com um codebook revisado silenciosamente
#' reaproveitaria classificacoes do codebook antigo.
.ac_ck_check_meta <- function(dir, hash) {
  meta_path <- file.path(dir, "_meta.rds")
  if (!file.exists(meta_path)) {
    saveRDS(list(hash = hash), meta_path)
    return(invisible())
  }
  meta_antigo <- readRDS(meta_path)
  if (!identical(meta_antigo$hash, hash)) {
    cli::cli_warn(c(
      "Parametros mudaram desde o ultimo checkpoint em {.path {dir}}.",
      "i" = "Checkpoints antigos (codebook/model/k_consistency/temperature diferentes) serao ignorados e sobrescritos."
    ))
    old_rds <- list.files(dir, pattern = "\\.rds$", full.names = TRUE)
    old_rds <- setdiff(old_rds, meta_path)
    unlink(old_rds)
    saveRDS(list(hash = hash), meta_path)
  }
  invisible()
}


#' @keywords internal
#' @noRd
.ac_build_run_info <- function(effective_model, model, chat, temperature,
                                main_temperature, k_consistency, codebook,
                                n_docs, start_time) {
  params_efetivos <- NULL
  base_url <- NULL
  model_name <- if (!is.null(chat)) tryCatch(chat$get_model(), error = function(e) NULL) else model

  if (inherits(effective_model, "Chat")) {
    params_efetivos <- tryCatch(as.list(effective_model$get_model_object()@params),
                                error = function(e) NULL)
    base_url <- tryCatch(effective_model$get_provider()@base_url, error = function(e) NULL)
  }

  if (inherits(effective_model, "Chat") && !is.null(temperature) &&
      is.null(params_efetivos$temperature)) {
    cli::cli_warn(c(
      "!" = "Nao foi possivel confirmar que {.arg temperature} foi aplicada ao provedor.",
      "i" = "Verifique {.code attr(resultado, \"run_info\")$params_efetivos} antes de reportar confidence_score."
    ))
  }

  list(
    acR_version      = as.character(utils::packageVersion("acR")),
    ellmer_version    = tryCatch(as.character(utils::packageVersion("ellmer")), error = function(e) NA_character_),
    model             = model_name,
    base_url          = base_url,
    params_efetivos   = params_efetivos,
    temperatura_pedida = list(principal = main_temperature, extras = temperature),
    k_consistency     = k_consistency,
    codebook_hash     = rlang::hash(codebook),
    n_docs            = n_docs,
    inicio            = start_time,
    fim               = Sys.time(),
    r_version         = R.version.string,
    plataforma        = R.version$platform
  )
}


#' @keywords internal
#' @noRd
.ac_compute_confidence <- function(results, cat_names, confidence) {
  valid_results <- results[!purrr::map_lgl(results, is.null)]
  if (length(valid_results) == 0L) return(NULL)

  cats <- purrr::map_chr(valid_results, function(r) {
    if (is.null(r$categoria)) {
      NA_character_
    } else {
      # Colapsa para string unica antes do map_chr(): alguns modelos
      # devolvem um array JSON (ex.: ["tema_a", "tema_b"]) apesar do
      # prompt instruir string unica separada por "|". Mesma logica de
      # .ac_build_result_tibble() (abaixo), aplicada aqui tambem porque
      # o calculo de confianca roda antes e quebrava com
      # "Result must be length 1, not 2".
      paste(as.character(r$categoria), collapse = "|")
    }
  })

  mode_cat <- names(sort(table(cats), decreasing = TRUE))[1]
  agree    <- mean(cats == mode_cat, na.rm = TRUE)

  # Proporcao de rodadas de self-consistency que escolheram CADA
  # categoria do codebook (nao so a vencedora) -- isso e o que de fato
  # varia "por variavel". Calculado para "by_variable" e "both" (o if
  # anterior testava confidence %in% c("total", "both") primeiro, entao
  # "both" nunca alcancava o ramo que populava by_var).
  #
  # Usa %in% apos strsplit("|") em vez de igualdade de string inteira:
  # em multilabel, `cats` pode ser "tecnica|politica", e `cats == "tecnica"`
  # nunca seria TRUE mesmo quando a rodada de fato escolheu "tecnica" --
  # subestimando a confianca por variavel sempre que mais de uma categoria
  # e escolhida na mesma rodada. Para single-label (sem "|"), o resultado
  # e identico ao de igualdade de string.
  by_var <- if (confidence %in% c("by_variable", "both")) {
    stats::setNames(
      as.list(vapply(cat_names, function(cn) {
        mean(vapply(cats, function(c_) {
          if (is.na(c_)) return(NA)
          cn %in% strsplit(c_, "|", fixed = TRUE)[[1]]
        }, logical(1)), na.rm = TRUE)
      }, numeric(1))),
      cat_names
    )
  } else {
    NULL
  }

  total <- if (confidence %in% c("total", "both")) agree else NULL

  list(total = total, by_var = by_var, dominant = mode_cat)
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
.ac_build_result_tibble <- function(results, corpus, cat_names, codebook,
                                     confidence, reasoning) {
  # Mapeamento slug -> label para categoria_label. Se nenhuma categoria
  # tiver `label` definido, categoria_label repete o slug (sem quebrar
  # nada). Bug 5: garante coluna legivel na saida sem exigir dicionario
  # externo do usuario.
  label_map <- stats::setNames(
    vapply(cat_names, function(k) {
      cat <- codebook$categories[[k]]
      if (!is.null(cat$label) && nzchar(cat$label)) cat$label else k
    }, character(1)),
    cat_names
  )

  rows <- purrr::map(results, function(r) {
    main <- r$main
    conf <- r$conf_scores

    # Modelos podem devolver `categoria` como string ("a"), string
    # pipe-separada ("a|b") ou array JSON (["a","b"]) apesar do prompt.
    # Sempre colapsamos para uma unica string, mantendo o tibble com uma
    # linha por documento -- essa e a garantia esperada pelo restante do
    # pipeline (ac_qual_reliability, ac_qual_report, etc.).
    cat_val <- if (!is.null(main) && !is.null(main$categoria)) {
      paste(as.character(main$categoria), collapse = "|")
    } else NA_character_

    # Traduz slug(s) -> label(s), unindo multilabel com " | " (espaco
    # dos dois lados) para leitura humana. Slugs desconhecidos passam
    # inalterados.
    cat_label <- if (!is.na(cat_val)) {
      slugs <- strsplit(cat_val, "|", fixed = TRUE)[[1]]
      labels <- vapply(slugs, function(s) {
        if (s %in% names(label_map)) label_map[[s]] else s
      }, character(1))
      paste(labels, collapse = " | ")
    } else NA_character_

    # Mesmo cuidado para raciocinio: alguns modelos devolvem lista/array
    rac_val <- if (reasoning && !is.null(main) && !is.null(main$raciocinio)) {
      paste(as.character(main$raciocinio), collapse = " ")
    } else NA_character_

    conf_score <- if (!is.null(conf)) conf$total %||% NA_real_ else NA_real_
    conf_level <- if (!is.na(conf_score)) {
      .ac_confidence_level(conf_score)
    } else NA_character_

    tokens_in  <- r$tokens_entrada %||% NA_real_
    tokens_out <- r$tokens_saida %||% NA_real_
    segundos   <- r$segundos %||% NA_real_
    tok_por_s  <- if (!is.na(tokens_out) && !is.na(segundos) && segundos > 0) {
      tokens_out / segundos
    } else NA_real_

    row <- tibble::tibble(
      doc_id           = r$doc_id,
      categoria        = cat_val,
      categoria_label  = cat_label,
      confidence_score = conf_score,
      confidence_level = conf_level,
      status           = r$status %||% NA_character_,
      n_tentativas     = r$n_tentativas %||% NA_integer_,
      tokens_entrada   = tokens_in,
      tokens_saida     = tokens_out,
      segundos         = segundos,
      tokens_por_segundo = tok_por_s
    )

    # Adiciona uma coluna `<categoria>_confidence` por categoria do
    # codebook quando by_var foi calculado (confidence = "by_variable"
    # ou "both"). Implementa o comportamento ja documentado em @return
    # que nunca tinha sido de fato ligado ao tibble de saida.
    if (!is.null(conf) && !is.null(conf$by_var)) {
      by_var_cols <- stats::setNames(
        as.list(vapply(cat_names, function(cn) {
          conf$by_var[[cn]] %||% NA_real_
        }, numeric(1))),
        paste0(cat_names, "_confidence")
      )
      row <- dplyr::bind_cols(row, tibble::as_tibble(by_var_cols))
    }

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
    "i" = "Interpreta\u00e7\u00e3o: >= 0.80 = alta | 0.61-0.79 = m\u00e9dia | < 0.61 = baixa (Landis & Koch, 1977)."
  ))

  result
}
