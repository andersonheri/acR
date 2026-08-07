#' Gerar relatório de replicabilidade da análise qualitativa
#'
#' @description
#' `ac_qual_report()` gera um documento estruturado, pronto para artigo ou
#' relatório, com todas as decisões metodológicas da rodada de codificação
#' qualitativa: codebook completo, histórico de modificações, configuração
#' da LLM, distribuição de resultados, métricas de confiabilidade e
#' referências bibliográficas.
#'
#' É a resposta do `acR` a um risco real de comunicação em análises
#' assistidas por LLM: **o revisor ou leitor não consegue reproduzir a
#' rodada** sem saber exatamente qual modelo, qual codebook, quais
#' parâmetros e qual amostra foram usados. Sem esse relatório, o leitor
#' tem que confiar no autor — algo que a tradição de análise de conteúdo
#' (Krippendorff, 2018) sempre rejeitou. O documento gerado é autocontido
#' e pode ser anexado como material suplementar do artigo, publicado como
#' apêndice ou depositado num repositório de dados junto com o codebook em
#' YAML.
#'
#' Suporta saída em Markdown (`.md`) ou HTML autocontido (`.html`),
#' em português ou inglês (para submissões internacionais).
#'
#' @param coded Tibble com resultado de [ac_qual_code()].
#' @param codebook Objeto `ac_codebook` usado na classificacao.
#' @param reliability Opcional. Saida de [ac_qual_reliability()]; se
#'   fornecido, adiciona secao de confiabilidade inter-codificador.
#' @param chat Opcional. Objeto `Chat` do `ellmer` (ou string de modelo);
#'   se fornecido, extrai provedor/modelo/parametros para o relatorio.
#' @param title Titulo do relatorio. Padrao: gerado a partir do nome do codebook.
#' @param author Autor(es) do estudo (opcional).
#' @param method Descricao livre do metodo de coleta do corpus (opcional).
#' @param format Formato de saida: `"md"` (padrao) ou `"html"`.
#' @param path Caminho do arquivo destino. Se `NULL`, usa `tempfile()`.
#' @param lang Idioma: `"pt"` (padrao) ou `"en"`.
#'
#' @return Invisivel: caminho do arquivo gerado.
#'
#' @examples
#' # Simular resultado de ac_qual_code para o exemplo
#' cb <- ac_qual_codebook(
#'   name         = "polaridade",
#'   instructions = "Classifique a polaridade do texto.",
#'   categories   = list(
#'     favor  = list(definition = "Apoio a proposta."),
#'     contra = list(definition = "Oposicao a proposta.")
#'   )
#' )
#'
#' coded <- tibble::tibble(
#'   doc_id           = paste0("d", 1:5),
#'   categoria        = c("favor", "contra", "favor", "contra", "favor"),
#'   confidence_score = c(1.00, 0.67, 1.00, 1.00, 0.67),
#'   reasoning        = rep("...", 5)
#' )
#'
#' # Gerar relatorio em markdown temporario
#' arquivo <- tempfile(fileext = ".md")
#' ac_qual_report(coded, cb, path = arquivo, author = "Fulano de Tal")
#' # readLines(arquivo, n = 20)
#'
#' @concept qualitative
#' @export
ac_qual_report <- function(coded,
                            codebook,
                            reliability = NULL,
                            chat        = NULL,
                            title       = NULL,
                            author      = NULL,
                            method      = NULL,
                            format      = c("md", "html"),
                            path        = NULL,
                            lang        = c("pt", "en")) {

  if (!inherits(codebook, "ac_codebook"))
    cli::cli_abort("{.arg codebook} deve ser um objeto {.cls ac_codebook}.")
  if (!is.data.frame(coded))
    cli::cli_abort("{.arg coded} deve ser um tibble (saida de {.fn ac_qual_code}).")

  format <- match.arg(format)
  lang   <- match.arg(lang)

  L <- .ac_report_labels(lang)

  if (is.null(title))
    title <- sprintf(L$title_fmt, codebook$name)
  if (is.null(path)) {
    path <- tempfile(pattern = paste0("acr-report-",
                                      gsub("[^A-Za-z0-9_-]", "_", codebook$name), "-"),
                     fileext = paste0(".", format))
  }

  # rmarkdown::render() muda o diretorio de trabalho durante o knit;
  # se `path` for relativo, dirname(path) sera resolvido no cwd novo e
  # a checagem "The directory 'X' does not exist" quebra mesmo com a
  # pasta existindo no cwd original. Convertemos SEMPRE para absoluto
  # antes de sair do cwd atual, e criamos a pasta destino se preciso.
  path     <- .ac_report_absolute_path(path)
  dest_dir <- dirname(path)
  if (!dir.exists(dest_dir)) {
    dir.create(dest_dir, recursive = TRUE, showWarnings = FALSE)
    if (!dir.exists(dest_dir)) {
      cli::cli_abort(c(
        "Nao foi possivel criar o diretorio destino do relatorio.",
        "i" = "Diretorio: {.path {dest_dir}}"
      ))
    }
  }

  md <- .ac_report_build_md(
    coded       = coded,
    codebook    = codebook,
    reliability = reliability,
    chat        = chat,
    title       = title,
    author      = author,
    method      = method,
    L           = L
  )

  if (format == "md") {
    writeLines(md, path, useBytes = TRUE)
  } else {
    if (!requireNamespace("rmarkdown", quietly = TRUE))
      cli::cli_abort("Formato {.val html} requer o pacote {.pkg rmarkdown}.")
    md_tmp <- tempfile(fileext = ".md")
    writeLines(md, md_tmp, useBytes = TRUE)
    rmarkdown::render(
      md_tmp,
      output_format = rmarkdown::html_document(
        theme            = "cosmo",
        toc              = TRUE,
        toc_depth        = 2,
        self_contained   = TRUE,
        highlight        = "tango"
      ),
      output_file  = path,   # ja absoluto
      quiet        = TRUE
    )
  }

  cli::cli_inform(c(
    "v" = sprintf(L$done_fmt, path)
  ))
  invisible(path)
}


#' Converte um caminho (possivelmente inexistente) em caminho absoluto
#' @keywords internal
#' @noRd
.ac_report_absolute_path <- function(p) {
  if (length(p) != 1L || !is.character(p)) return(p)
  # Ja absoluto?  Unix: comeca com "/"; Windows: "C:/" ou "\\\\server"
  if (grepl("^(/|[A-Za-z]:[/\\\\]|\\\\\\\\)", p)) return(p)
  # Relativo: resolver contra o cwd ATUAL (antes de render mudar de dir)
  file.path(normalizePath(getwd(), winslash = "/", mustWork = FALSE), p)
}


# ============================================================================
# Internos
# ============================================================================

#' @keywords internal
#' @noRd
.ac_report_labels <- function(lang) {
  if (lang == "pt") {
    list(
      title_fmt        = "Relatorio de replicabilidade -- codebook \"%s\"",
      generated_at     = "Gerado em",
      pkg_version      = "Versao do acR",
      author           = "Autor(es)",
      method           = "Metodo",
      overview         = "1. Visao geral",
      overview_body    = paste(
        "Este relatorio documenta as decisoes metodologicas da rodada de codificacao",
        "qualitativa assistida por LLM, seguindo as recomendacoes de Krippendorff (2018)",
        "sobre replicabilidade em analise de conteudo e as boas praticas de Gilardi et al.",
        "(2023) para uso de LLMs em anotacao de textos."
      ),
      cb_section       = "2. Codebook",
      cb_name          = "Nome",
      cb_lang          = "Idioma",
      cb_mode          = "Modo",
      cb_multilabel    = "Multilabel",
      cb_created       = "Criado em",
      cb_instructions  = "Instrucoes ao codificador",
      cb_categories    = "Categorias",
      cb_category      = "Categoria",
      cb_definition    = "Definicao",
      cb_ex_pos        = "Exemplos positivos",
      cb_ex_neg        = "Exemplos negativos",
      cb_weight        = "Peso",
      cb_refs          = "Referencias",
      history_section  = "3. Historico de modificacoes do codebook",
      history_empty    = "Nenhuma modificacao registrada apos criacao.",
      llm_section      = "4. Configuracao da LLM",
      llm_provider     = "Provedor",
      llm_model        = "Modelo",
      llm_temp         = "Temperatura",
      llm_kcons        = "k self-consistency",
      llm_reasoning    = "Raciocinio estruturado",
      llm_reasoning_len = "Extensao do raciocinio",
      llm_note         = paste(
        "Self-consistency (Wang et al., 2022) reduz variabilidade estocastica reamostrando",
        "cada documento k vezes e tomando a moda das classificacoes. `confidence_score` reporta",
        "a proporcao de rodadas que concordaram (1.00 = todas concordaram)."
      ),
      results_section  = "5. Resultados",
      results_ndocs    = "Documentos classificados",
      results_ncats    = "Categorias no codebook",
      results_dist     = "Distribuicao por categoria",
      results_conf     = "Distribuicao de confidence_score",
      results_lowconf  = "Casos com confianca < 0.80 (candidatos prioritarios para revisao humana)",
      rel_section      = "6. Confiabilidade inter-codificador",
      rel_none         = "Nao foi executada validacao humana nesta rodada.",
      rel_note         = paste(
        "Interpretacao de kappa/alpha segundo Landis & Koch (1977) e Gwet (2014).",
        "Para publicacao, valores acima de 0.67 (Krippendorff) ou 0.61 (Landis-Koch)",
        "sao geralmente considerados aceitaveis."
      ),
      refs_section     = "7. Referencias metodologicas",
      how_to_cite      = "8. Como citar esta analise",
      cite_text        = "Sugestao de citacao (formato ABNT):",
      done_fmt         = "Relatorio salvo em {.path %s}"
    )
  } else {
    list(
      title_fmt        = "Reproducibility report -- codebook \"%s\"",
      generated_at     = "Generated on",
      pkg_version      = "acR version",
      author           = "Author(s)",
      method           = "Method",
      overview         = "1. Overview",
      overview_body    = paste(
        "This report documents the methodological choices of an LLM-assisted qualitative",
        "coding round, following Krippendorff (2018) on replicability in content analysis and",
        "the best-practice recommendations of Gilardi et al. (2023) for LLM-based text annotation."
      ),
      cb_section       = "2. Codebook",
      cb_name          = "Name",
      cb_lang          = "Language",
      cb_mode          = "Mode",
      cb_multilabel    = "Multilabel",
      cb_created       = "Created at",
      cb_instructions  = "Instructions to the coder",
      cb_categories    = "Categories",
      cb_category      = "Category",
      cb_definition    = "Definition",
      cb_ex_pos        = "Positive examples",
      cb_ex_neg        = "Negative examples",
      cb_weight        = "Weight",
      cb_refs          = "References",
      history_section  = "3. Codebook modification history",
      history_empty    = "No modifications recorded after initial creation.",
      llm_section      = "4. LLM configuration",
      llm_provider     = "Provider",
      llm_model        = "Model",
      llm_temp         = "Temperature",
      llm_kcons        = "k (self-consistency)",
      llm_reasoning    = "Structured reasoning",
      llm_reasoning_len = "Reasoning length",
      llm_note         = paste(
        "Self-consistency (Wang et al., 2022) reduces stochastic variability by resampling",
        "each document k times and taking the modal classification. `confidence_score` reports",
        "the proportion of rounds that agreed (1.00 = full agreement)."
      ),
      results_section  = "5. Results",
      results_ndocs    = "Documents classified",
      results_ncats    = "Categories in codebook",
      results_dist     = "Distribution by category",
      results_conf     = "Distribution of confidence_score",
      results_lowconf  = "Cases with confidence < 0.80 (priority for human review)",
      rel_section      = "6. Inter-coder reliability",
      rel_none         = "No human validation was performed for this round.",
      rel_note         = paste(
        "Kappa/alpha interpretation follows Landis & Koch (1977) and Gwet (2014).",
        "For publication, values above 0.67 (Krippendorff) or 0.61 (Landis-Koch) are generally",
        "considered acceptable."
      ),
      refs_section     = "7. Methodological references",
      how_to_cite      = "8. How to cite this analysis",
      cite_text        = "Suggested citation (APA):",
      done_fmt         = "Report saved to {.path %s}"
    )
  }
}


#' @keywords internal
#' @noRd
.ac_report_build_md <- function(coded, codebook, reliability, chat,
                                 title, author, method, L) {
  # Container local mutavel para evitar <<- (CRAN policy):
  # environment() e um objeto R normal, nao escreve fora do escopo.
  buf <- new.env(parent = emptyenv())
  buf$lines <- character(0)
  add <- function(...) buf$lines <- c(buf$lines, ...)

  # ---- Header --------------------------------------------------------------
  add(paste0("# ", title))
  add("")
  add(paste0("- **", L$generated_at, ":** ",
             format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")))
  add(paste0("- **", L$pkg_version, ":** ",
             as.character(utils::packageVersion("acR"))))
  if (!is.null(author))
    add(paste0("- **", L$author, ":** ", author))
  if (!is.null(method))
    add(paste0("- **", L$method, ":** ", method))
  add("")

  # ---- 1. Overview ---------------------------------------------------------
  add(paste0("## ", L$overview))
  add("")
  add(L$overview_body)
  add("")

  # ---- 2. Codebook ---------------------------------------------------------
  add(paste0("## ", L$cb_section))
  add("")
  add(paste0("| ", L$cb_name, " | ", codebook$name, " |"))
  add("|---|---|")
  add(paste0("| ", L$cb_lang, "        | `", codebook$lang %||% "?",       "` |"))
  add(paste0("| ", L$cb_mode, "        | `", codebook$mode %||% "manual",  "` |"))
  add(paste0("| ", L$cb_multilabel, "  | `", isTRUE(codebook$multilabel),  "` |"))
  if (!is.null(codebook$created_at))
    add(paste0("| ", L$cb_created, "     | ",
               format(codebook$created_at, "%Y-%m-%d %H:%M:%S"), " |"))
  add("")
  add(paste0("**", L$cb_instructions, ":**"))
  add("")
  add(paste0("> ", codebook$instructions))
  add("")
  add(paste0("### ", L$cb_categories))
  add("")
  for (cat_name in names(codebook$categories)) {
    cat <- codebook$categories[[cat_name]]
    add(paste0("#### `", cat_name, "`"))
    add("")
    add(paste0("**", L$cb_definition, ":** ", cat$definition %||% "-"))
    add("")
    if (length(cat$examples_pos)) {
      add(paste0("**", L$cb_ex_pos, ":**"))
      add(paste0("- ", cat$examples_pos))
      add("")
    }
    if (length(cat$examples_neg)) {
      add(paste0("**", L$cb_ex_neg, ":**"))
      add(paste0("- ", cat$examples_neg))
      add("")
    }
    if (!is.null(cat$weight) && cat$weight != 1)
      add(paste0("**", L$cb_weight, ":** ", cat$weight))
    if (length(cat$references)) {
      add(paste0("**", L$cb_refs, ":**"))
      add(paste0("- ", cat$references))
      add("")
    }
  }

  # ---- 3. History ----------------------------------------------------------
  add(paste0("## ", L$history_section))
  add("")
  h <- codebook$history
  if (length(h) == 0L) {
    add(paste0("_", L$history_empty, "_"))
  } else {
    add("| timestamp | action | detail |")
    add("|---|---|---|")
    for (entry in h) {
      add(paste0("| ", entry$timestamp,
                 " | `", entry$action, "`",
                 " | ", entry$detail, " |"))
    }
  }
  add("")

  # ---- 4. LLM config -------------------------------------------------------
  add(paste0("## ", L$llm_section))
  add("")
  cfg <- .ac_report_llm_config(coded, chat)
  add("| Item | Valor |")
  add("|---|---|")
  add(paste0("| ", L$llm_provider,      " | ", cfg$provider,  " |"))
  add(paste0("| ", L$llm_model,         " | `", cfg$model,    "` |"))
  add(paste0("| ", L$llm_temp,          " | ", cfg$temperature," |"))
  add(paste0("| ", L$llm_kcons,         " | ", cfg$k,          " |"))
  add(paste0("| ", L$llm_reasoning,     " | ", cfg$reasoning,  " |"))
  add("")
  add(paste0("_", L$llm_note, "_"))
  add("")

  # ---- 5. Results ----------------------------------------------------------
  add(paste0("## ", L$results_section))
  add("")
  add(paste0("- **", L$results_ndocs, ":** ", nrow(coded)))
  add(paste0("- **", L$results_ncats, ":** ", length(codebook$categories)))
  add("")
  add(paste0("**", L$results_dist, ":**"))
  add("")
  cat_tbl <- table(coded$categoria, useNA = "ifany")
  cat_pct <- round(100 * prop.table(cat_tbl), 1)
  add("| Categoria | N | % |")
  add("|---|---:|---:|")
  for (nm in names(cat_tbl)) {
    add(paste0("| ", nm, " | ", cat_tbl[[nm]], " | ", cat_pct[[nm]], "% |"))
  }
  add("")
  if ("confidence_score" %in% names(coded)) {
    q  <- stats::quantile(coded$confidence_score, c(0, .25, .5, .75, 1),
                          na.rm = TRUE)
    add(paste0("**", L$results_conf, ":**"))
    add("")
    add(paste0("- min = ", round(q[[1]], 2),
               " | Q1 = ",  round(q[[2]], 2),
               " | mediana = ", round(q[[3]], 2),
               " | Q3 = ",  round(q[[4]], 2),
               " | max = ", round(q[[5]], 2)))
    n_low <- sum(coded$confidence_score < 0.8, na.rm = TRUE)
    add(paste0("- ", L$results_lowconf, ": **", n_low, "** (",
               round(100 * n_low / nrow(coded), 1), "%)"))
    add("")
  }

  # ---- 6. Reliability ------------------------------------------------------
  add(paste0("## ", L$rel_section))
  add("")
  if (is.null(reliability)) {
    add(paste0("_", L$rel_none, "_"))
  } else {
    add("| Metrica | Estimativa | IC 95% |")
    add("|---|---:|---:|")
    rel <- reliability
    if (inherits(rel, "ac_reliability") || is.list(rel)) {
      m <- if (!is.null(rel$metrics)) rel$metrics else rel
      if (is.data.frame(m)) {
        has_ci <- all(c("ci_low", "ci_high") %in% names(m))
        est_col  <- if ("estimate" %in% names(m)) "estimate" else
                    if ("value"    %in% names(m)) "value"    else NA_character_
        name_col <- if ("metric"   %in% names(m)) "metric"   else
                    if ("name"     %in% names(m)) "name"     else NA_character_
        for (i in seq_len(nrow(m))) {
          ic <- if (has_ci)
            paste0("[", round(m$ci_low[i], 3), ", ", round(m$ci_high[i], 3), "]")
          else "-"
          est <- if (!is.na(est_col)) m[[est_col]][i] else NA_real_
          nm  <- if (!is.na(name_col)) m[[name_col]][i] else paste0("metric_", i)
          add(paste0("| ", nm,
                     " | ", round(est, 3),
                     " | ", ic, " |"))
        }
      }
    }
    add("")
    add(paste0("_", L$rel_note, "_"))
  }
  add("")

  # ---- 7. References -------------------------------------------------------
  add(paste0("## ", L$refs_section))
  add("")
  add("- Gilardi, F.; Alizadeh, M.; Kubli, M. (2023). ChatGPT outperforms crowd workers for text-annotation tasks. *PNAS*, 120(30). <https://doi.org/10.1073/pnas.2305016120>")
  add("- Gwet, K. L. (2014). *Handbook of Inter-Rater Reliability* (4th ed.). Advanced Analytics.")
  add("- Krippendorff, K. (2018). *Content Analysis: An Introduction to Its Methodology* (4th ed.). SAGE.")
  add("- Landis, J. R.; Koch, G. G. (1977). The measurement of observer agreement for categorical data. *Biometrics*, 33(1), 159-174.")
  add("- Sampaio, R. C.; Lycari\u00e3o, D. (2021). *Analise de conteudo categorial: manual de aplicacao*. ENAP.")
  add("- Wang, X. et al. (2022). Self-consistency improves chain-of-thought reasoning in language models. *arXiv:2203.11171*.")
  add("")

  # ---- 8. How to cite ------------------------------------------------------
  add(paste0("## ", L$how_to_cite))
  add("")
  add(paste0("_", L$cite_text, "_"))
  add("")
  add("```")
  add(paste0("HENRIQUE, A. acR: Analise de Conteudo em R. Versao ",
             as.character(utils::packageVersion("acR")),
             ". Sao Paulo: CEM-Cepid/USP, ",
             format(Sys.Date(), "%Y"),
             ". Disponivel em: <https://ahenriquecp.com/acR/>."))
  add("```")
  add("")

  paste(buf$lines, collapse = "\n")
}


#' @keywords internal
#' @noRd
.ac_report_llm_config <- function(coded, chat) {
  provider <- "unknown"
  model    <- "unknown"

  if (!is.null(chat)) {
    if (inherits(chat, "Chat")) {
      cls <- class(chat)
      provider <- sub("^Chat", "", cls[grepl("^Chat[A-Z]", cls)][1] %||% "Chat")
      if (identical(provider, character(0)) || is.na(provider)) provider <- "Chat"
      model <- tryCatch(chat$get_model() %||% "unknown",
                        error = function(e) "unknown")
    } else if (is.character(chat)) {
      parts <- strsplit(chat, "/", fixed = TRUE)[[1]]
      if (length(parts) >= 2L) {
        provider <- parts[1]
        model    <- paste(parts[-1], collapse = "/")
      } else {
        model <- chat
      }
    }
  }

  # k de self-consistency e reasoning: inferimos a partir do que existe no tibble
  k <- if ("confidence_score" %in% names(coded) &&
           any(!is.na(coded$confidence_score))) {
    scores <- coded$confidence_score[!is.na(coded$confidence_score)]
    # se todos os scores forem multiplos de 1/n para algum n pequeno, esse n eh k
    guessed <- .ac_guess_k_from_scores(scores)
    if (is.null(guessed)) "inferido do resultado" else as.character(guessed)
  } else {
    "1 (sem self-consistency)"
  }

  reasoning <- if ("reasoning" %in% names(coded) &&
                    any(nzchar(coded$reasoning %||% ""), na.rm = TRUE)) {
    "ativo"
  } else {
    "desativado"
  }

  list(
    provider    = provider,
    model       = model,
    temperature = "0.3 (self-consistency) / 0 (primeira rodada)",
    k           = k,
    reasoning   = reasoning
  )
}


#' @keywords internal
#' @noRd
.ac_guess_k_from_scores <- function(scores) {
  for (k in 3:7) {
    valid <- vapply(scores, function(s) {
      any(abs(s - (0:k) / k) < 1e-6)
    }, logical(1))
    if (all(valid)) return(k)
  }
  NULL
}


# ============================================================================
# ac_qual_report_full: relatorio consolidado multi-variavel (Feature #6)
# ============================================================================

#' Gerar relatório consolidado de múltiplas variáveis de conteúdo
#'
#' @description
#' `ac_qual_report_full()` gera **um único** documento (Markdown ou HTML)
#' consolidando resultados de N variáveis de codificação qualitativa —
#' cada uma com seu próprio codebook, rodada de [ac_qual_code()] e,
#' opcionalmente, métricas de [ac_qual_reliability()] ou [ac_qual_irr()].
#'
#' É a resposta natural ao caso de uso mais comum de análise de conteúdo
#' categorial (Krippendorff, 2018): um estudo tem várias variáveis de
#' conteúdo (tom, posicionamento, tema, framing…). Antes desta função, o
#' pesquisador precisava chamar [ac_qual_report()] N vezes e emendar os
#' relatórios manualmente, ou escrever um consolidador ad hoc por projeto.
#'
#' Aceita variáveis `multilabel = TRUE` e `multilabel = FALSE` no mesmo
#' relatório — cada seção herda a apresentação apropriada para o tipo.
#'
#' @param variables Lista **nomeada** onde cada elemento é uma lista com:
#'   * `coded`: tibble com resultado de [ac_qual_code()] (obrigatório).
#'   * `codebook`: objeto `ac_codebook` (obrigatório).
#'   * `reliability`: opcional, saída de [ac_qual_reliability()] ou
#'     [ac_qual_irr()].
#'   Os nomes da lista viram os títulos das seções do relatório.
#' @param chat Opcional. Objeto `Chat` do `ellmer` ou string de modelo
#'   `"provider/model"`. Aplica-se a todas as variáveis (assumindo que
#'   todas foram classificadas com o mesmo modelo — se não, deixe `NULL`).
#' @param title Título do relatório consolidado. Padrão: `"Relatório
#'   consolidado de análise de conteúdo"`.
#' @param author Autor(es) do estudo.
#' @param method Descrição do método de coleta do corpus.
#' @param format `"md"` (padrão) ou `"html"`.
#' @param path Caminho do arquivo destino. Se `NULL`, usa `tempfile()`.
#' @param lang `"pt"` (padrão) ou `"en"`.
#'
#' @return Invisível: caminho do arquivo gerado.
#'
#' @examples
#' # Duas variaveis de conteudo, cada uma com seu codebook
#' cb_tom <- ac_qual_codebook(
#'   name = "tom",
#'   instructions = "Classifique o tom.",
#'   categories = list(
#'     pos = list(definition = "Positivo.", label = "Positivo"),
#'     neg = list(definition = "Negativo.", label = "Negativo")
#'   )
#' )
#' cb_pos <- ac_qual_codebook(
#'   name = "posicao",
#'   instructions = "Classifique a posicao.",
#'   categories = list(
#'     favor  = list(definition = "A favor.",  label = "A favor"),
#'     contra = list(definition = "Contra.",   label = "Contra")
#'   )
#' )
#'
#' coded_tom <- tibble::tibble(
#'   doc_id = paste0("d", 1:3),
#'   categoria = c("pos", "neg", "pos"),
#'   confidence_score = c(1, 0.67, 1)
#' )
#' coded_pos <- tibble::tibble(
#'   doc_id = paste0("d", 1:3),
#'   categoria = c("favor", "contra", "favor"),
#'   confidence_score = c(1, 1, 0.67)
#' )
#'
#' arquivo <- tempfile(fileext = ".md")
#' ac_qual_report_full(
#'   variables = list(
#'     "Tom do discurso" = list(coded = coded_tom, codebook = cb_tom),
#'     "Posicao politica" = list(coded = coded_pos, codebook = cb_pos)
#'   ),
#'   path = arquivo,
#'   author = "Fulano de Tal"
#' )
#'
#' @seealso [ac_qual_report()] para relatório de uma única variável.
#'
#' @concept qualitative
#' @export
ac_qual_report_full <- function(variables,
                                 chat   = NULL,
                                 title  = NULL,
                                 author = NULL,
                                 method = NULL,
                                 format = c("md", "html"),
                                 path   = NULL,
                                 lang   = c("pt", "en")) {

  format <- match.arg(format)
  lang   <- match.arg(lang)
  L      <- .ac_report_labels(lang)

  # ---- Validacoes ----------------------------------------------------------
  if (!is.list(variables) || length(variables) == 0L) {
    cli::cli_abort("{.arg variables} deve ser uma lista nao-vazia.")
  }
  if (is.null(names(variables)) || any(!nzchar(names(variables)))) {
    cli::cli_abort(c(
      "{.arg variables} deve ser uma lista {.strong nomeada}.",
      "i" = "Os nomes viram os titulos das secoes do relatorio."
    ))
  }
  for (nm in names(variables)) {
    v <- variables[[nm]]
    if (!is.list(v) || is.null(v$coded) || is.null(v$codebook)) {
      cli::cli_abort(c(
        "variables[['{nm}']]: campos {.field coded} e {.field codebook} sao obrigatorios."
      ))
    }
    if (!inherits(v$codebook, "ac_codebook")) {
      cli::cli_abort("variables[['{nm}']]$codebook deve ser um {.cls ac_codebook}.")
    }
    if (!is.data.frame(v$coded)) {
      cli::cli_abort("variables[['{nm}']]$coded deve ser um tibble (saida de {.fn ac_qual_code}).")
    }
  }

  # ---- Path absoluto + dir cria-se se preciso -----------------------------
  if (is.null(title)) {
    title <- if (lang == "pt") {
      "Relatorio consolidado de analise de conteudo"
    } else {
      "Consolidated content analysis report"
    }
  }
  if (is.null(path)) {
    path <- tempfile(pattern = "acr-report-full-",
                     fileext = paste0(".", format))
  }
  path     <- .ac_report_absolute_path(path)
  dest_dir <- dirname(path)
  if (!dir.exists(dest_dir)) {
    dir.create(dest_dir, recursive = TRUE, showWarnings = FALSE)
    if (!dir.exists(dest_dir)) {
      cli::cli_abort(c(
        "Nao foi possivel criar o diretorio destino do relatorio.",
        "i" = "Diretorio: {.path {dest_dir}}"
      ))
    }
  }

  # ---- Build markdown consolidado -----------------------------------------
  parts <- character(0)
  parts <- c(parts, paste0("# ", title), "")
  parts <- c(parts,
             paste0("- **", L$generated_at, ":** ",
                    format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
             paste0("- **", L$pkg_version, ":** ",
                    as.character(utils::packageVersion("acR"))))
  if (!is.null(author)) parts <- c(parts, paste0("- **", L$author, ":** ", author))
  if (!is.null(method)) parts <- c(parts, paste0("- **", L$method, ":** ", method))
  parts <- c(parts, "")

  # Sumario das variaveis
  parts <- c(parts, if (lang == "pt") "## Variaveis analisadas" else "## Variables analysed", "")
  parts <- c(parts,
             if (lang == "pt")
               "| Variavel | k categorias | n documentos | multilabel |"
             else
               "| Variable | k categories | n documents | multilabel |",
             "|---|---|---|---|")
  for (nm in names(variables)) {
    v <- variables[[nm]]
    parts <- c(parts, sprintf("| %s | %d | %d | %s |",
                              nm,
                              length(v$codebook$categories),
                              nrow(v$coded),
                              if (isTRUE(v$codebook$multilabel)) "sim" else "nao"))
  }
  parts <- c(parts, "")

  # Uma secao por variavel, reusando o gerador de single-variable
  for (nm in names(variables)) {
    v <- variables[[nm]]
    parts <- c(parts, paste0("---"), "",
               paste0("# ", nm), "")
    section_md <- .ac_report_build_md(
      coded       = v$coded,
      codebook    = v$codebook,
      reliability = v$reliability,
      chat        = chat,
      title       = "",  # ja emitimos H1 acima
      author      = NULL,
      method      = NULL,
      L           = L
    )
    # Remove o H1 do gerador (a primeira linha eh "# " com titulo vazio)
    section_lines <- strsplit(section_md, "\n", fixed = TRUE)[[1]]
    if (length(section_lines) >= 2L && startsWith(section_lines[1], "# ")) {
      section_lines <- section_lines[-c(1L, 2L)]
    }
    parts <- c(parts, section_lines)
  }

  md <- paste(parts, collapse = "\n")

  # ---- Escrever ------------------------------------------------------------
  if (format == "md") {
    writeLines(md, path, useBytes = TRUE)
  } else {
    if (!requireNamespace("rmarkdown", quietly = TRUE))
      cli::cli_abort("Formato {.val html} requer o pacote {.pkg rmarkdown}.")
    md_tmp <- tempfile(fileext = ".md")
    writeLines(md, md_tmp, useBytes = TRUE)
    rmarkdown::render(
      md_tmp,
      output_format = rmarkdown::html_document(
        theme          = "cosmo",
        toc            = TRUE,
        toc_depth      = 2,
        self_contained = TRUE,
        highlight      = "tango"
      ),
      output_file = path,
      quiet       = TRUE
    )
  }

  cli::cli_inform(c("v" = sprintf(L$done_fmt, path)))
  invisible(path)
}
