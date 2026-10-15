#' Ajustar modelo LDA (Latent Dirichlet Allocation)
#'
#' @description
#' `ac_lda()` ajusta um modelo de tópicos LDA sobre um `ac_corpus`,
#' retornando um objeto com os resultados do modelo e tibbles tidy de
#' termos por tópico e prevalência por documento.
#'
#' @param corpus Objeto `ac_corpus`.
#' @param k Número de tópicos. Padrão: `10`.
#' @param seed Semente para reprodutibilidade. Padrão: `42`.
#' @param method Método de estimação: `"VEM"` (padrão) ou `"Gibbs"`.
#' @param ... Argumentos adicionais passados a [topicmodels::LDA()].
#'
#' @return Lista de classe `ac_lda` com:
#'   * `model`: objeto `LDA` do pacote `topicmodels`;
#'   * `terms`: tibble com beta (probabilidade de cada termo por tópico);
#'   * `documents`: tibble com gamma (prevalência de cada tópico por documento);
#'   * `k`: número de tópicos;
#'   * `params`: parâmetros usados.
#'
#' @references
#' Blei, D. M.; Ng, A. Y.; Jordan, M. I. (2003). Latent Dirichlet Allocation.
#' *Journal of Machine Learning Research*, 3, 993-1022.
#'
#' Vignette: `vignette("lda", package = "acR")`: tutorial completo com
#' corpus real e visualizações.
#'
#' @examples
#' \donttest{
#' # 1. Corpus sintético com 3 temas nitidos (democracia, economia, saude, educacao)
#' df <- data.frame(
#'   id = paste0("d", 1:10),
#'   texto = c(
#'     "democracia participacao cidadania direitos politica",
#'     "mercado economia privatizacao crescimento fiscal",
#'     "saude hospital medico doenca tratamento",
#'     "educacao escola professor ensino aprendizagem",
#'     "democracia eleicao voto politica partido",
#'     "economia inflacao juros fiscal orcamento",
#'     "saude sus medico hospital remedio",
#'     "educacao universidade pesquisa ciência",
#'     "participacao social cidadania direitos igualdade",
#'     "mercado trabalho emprego salário industria"
#'   )
#' )
#' corpus <- ac_corpus(df, text = texto, docid = id)
#'
#' # 2. Ajustar LDA com k=3 tópicos (o corpus tem ~4 temas; k=3 for a experimentacao)
#' lda <- ac_lda(corpus, k = 3)
#' lda  # imprime resumo do modelo
#' }
#'
#' @seealso [ac_lda_tune()], [ac_plot_lda_topics()]
#' @concept quantitative
#' @export
ac_lda <- function(corpus,
                    k      = 10L,
                    seed   = 42L,
                    method = c("VEM", "Gibbs"),
                    ...) {

  if (!is_ac_corpus(corpus)) {
    cli::cli_abort("{.arg corpus} deve ser um {.cls ac_corpus}.")
  }

  if (!requireNamespace("topicmodels", quietly = TRUE)) {
    cli::cli_abort(c(
      "O pacote {.pkg topicmodels} \u00e9 necess\u00e1rio.",
      "i" = "Instale com {.code install.packages(\"topicmodels\")}."
    ))
  }

  method <- match.arg(method)
  k      <- as.integer(k)

  if (k < 2L) cli::cli_abort("{.arg k} deve ser >= 2.")

  # Construir Document-Term Matrix via ac_count
  dtm_tbl <- corpus |>
    ac_clean() |>
    ac_count(n = 1L)

  if (nrow(dtm_tbl) == 0L) {
    cli::cli_abort("Corpus resultou em matrix de termos vazia ap\u00f3s limpeza.")
  }

  # Converter para DocumentTermMatrix do tm/topicmodels
  dtm <- .ac_to_dtm(dtm_tbl)

  # Ajustar LDA
  cli::cli_inform("Ajustando LDA com k = {k} t\u00f3picos...")
  model <- topicmodels::LDA(
    dtm,
    k       = k,
    method  = method,
    control = list(seed = seed),
    ...
  )

  # Extrair beta (termos × tópicos)
  beta_tbl <- topicmodels::posterior(model)$terms |>
    tibble::as_tibble(rownames = "topic") |>
    tidyr::pivot_longer(
      cols      = -topic,
      names_to  = "term",
      values_to = "beta"
    ) |>
    dplyr::mutate(topic = as.integer(topic))

  # Extrair gamma (documentos × tópicos)
  gamma_tbl <- topicmodels::posterior(model)$topics |>
    tibble::as_tibble(rownames = "doc_id") |>
    tidyr::pivot_longer(
      cols      = -doc_id,
      names_to  = "topic",
      values_to = "gamma"
    ) |>
    dplyr::mutate(topic = as.integer(topic))

  result <- list(
    model     = model,
    terms     = beta_tbl,
    documents = gamma_tbl,
    k         = k,
    params    = list(method = method, seed = seed)
  )
  class(result) <- "ac_lda"
  result
}

#' @export
#' @noRd
print.ac_lda <- function(x, ...) {
  cli::cli_h1("Modelo LDA {.pkg acR}")
  cli::cli_bullets(c(
    "*" = "T\u00f3picos (k): {.val {x$k}}",
    "*" = "M\u00e9todo: {.val {x$params$method}}",
    "*" = "Semente: {.val {x$params$seed}}",
    "*" = "Termos \u00fanicos: {.val {length(unique(x$terms$term))}}",
    "*" = "Documentos: {.val {length(unique(x$documents$doc_id))}}"
  ))
  invisible(x)
}


#' Ajustar múltiplos modelos LDA para selecionar k
#'
#' @description
#' `ac_lda_tune()` ajusta modelos LDA para diferentes valores de k e
#' calcula a **perplexidade fora da amostra** por validação cruzada, para
#' auxiliar na seleção do número de tópicos.
#'
#' Por que fora da amostra: a perplexidade calculada nos mesmos documentos
#' usados para ajustar o modelo cai quase sempre à medida que k cresce,
#' porque mais tópicos = mais parâmetros para memorizar o corpus. Blei, Ng
#' & Jordan (2003) e Wallach et al. (2009) avaliam a perplexidade em
#' documentos **não vistos** no ajuste; Zhao et al. (2015) usam validação
#' cruzada em 5 partes, como faz esta função por padrão. A versão de
#' treino continua disponível na coluna `perplexity_train`, só para
#' comparação.
#'
#' Perplexidade é um critério de ajuste preditivo, não de qualidade
#' substantiva: Chang et al. (2009) mostram que modelos com melhor
#' perplexidade podem produzir tópicos **menos** interpretáveis para
#' humanos. Use a curva para delimitar uma faixa de k e decida dentro
#' dela lendo os tópicos.
#'
#' @param corpus Objeto `ac_corpus`.
#' @param k_range Vetor de valores de k a testar. Padrão: `5:20`.
#' @param seed Semente (ajuste dos modelos e sorteio das partes da
#'   validação cruzada). Padrão: `42`.
#' @param method Método de estimação. Padrão: `"VEM"`.
#' @param folds Número de partes da validação cruzada. Padrão: `5`
#'   (limitado ao número de documentos). Use `1` para pular a validação
#'   cruzada e calcular só a perplexidade de treino (não recomendado).
#' @param ... Argumentos adicionais passados a [topicmodels::LDA()].
#'
#' @return Tibble com colunas `k`, `perplexity` (média da perplexidade
#'   nas partes de teste da validação cruzada), `perplexity_sd` (desvio
#'   padrão entre as partes) e `perplexity_train` (perplexidade no corpus
#'   inteiro usado no ajuste).
#'
#' @references
#' Blei, D. M.; Ng, A. Y.; Jordan, M. I. (2003). Latent Dirichlet
#' Allocation. *Journal of Machine Learning Research*, 3, 993-1022.
#'
#' Chang, J.; Gerrish, S.; Wang, C.; Boyd-Graber, J.; Blei, D. M. (2009).
#' Reading tea leaves: How humans interpret topic models. *Advances in
#' Neural Information Processing Systems*, 22, 288-296.
#'
#' Wallach, H. M.; Murray, I.; Salakhutdinov, R.; Mimno, D. (2009).
#' Evaluation methods for topic models. *Proceedings of the 26th
#' International Conference on Machine Learning*, 1105-1112.
#'
#' Zhao, W. et al. (2015). A heuristic approach to determine an
#' appropriate number of topics in topic modeling. *BMC Bioinformatics*,
#' 16(Suppl 13), S8.
#'
#' @examples
#' \donttest{
#' # 1. Corpus sintético (mesmos temas de ac_lda(), palavras diferentes)
#' df <- data.frame(
#'   id = paste0("d", 1:10),
#'   texto = c(
#'     "democracia participacao politica voto eleicao",
#'     "mercado economia fiscal privatizacao",
#'     "saude hospital medico doenca sus",
#'     "educacao escola professor universidade",
#'     "democracia cidadania direitos igualdade",
#'     "economia inflacao juros orcamento",
#'     "saude medico remedio tratamento",
#'     "educacao pesquisa ciência tecnologia",
#'     "participacao social democracia cidadania",
#'     "mercado trabalho emprego salário"
#'   )
#' )
#' corpus <- ac_corpus(df, text = texto, docid = id)
#'
#' # 2. Testar k de 2 a 5: perplexidade fora da amostra (validacao cruzada)
#' tune <- ac_lda_tune(corpus, k_range = 2:5)
#' tune
#' }
#'
#' @seealso [ac_lda()], [ac_plot_lda_tune()]
#' @concept quantitative
#' @export
ac_lda_tune <- function(corpus,
                         k_range = 5:20,
                         seed    = 42L,
                         method  = c("VEM", "Gibbs"),
                         folds   = 5L,
                         ...) {

  if (!is_ac_corpus(corpus)) {
    cli::cli_abort("{.arg corpus} deve ser um {.cls ac_corpus}.")
  }
  if (!requireNamespace("topicmodels", quietly = TRUE)) {
    cli::cli_abort("O pacote {.pkg topicmodels} \u00e9 necess\u00e1rio.")
  }

  method <- match.arg(method)

  dtm_tbl <- corpus |> ac_clean() |> ac_count(n = 1L)
  dtm     <- .ac_to_dtm(dtm_tbl)

  n_docs <- nrow(dtm)
  folds  <- max(1L, min(as.integer(folds), n_docs))
  # Particao fixa dos documentos (mesma para todos os k), sorteada com a
  # semente do usuario sem alterar o RNG global.
  fold_id <- withr::with_seed(seed, sample(rep_len(seq_len(folds), n_docs)))

  cli::cli_inform(c(
    "Testando k = {min(k_range)} a {max(k_range)}...",
    "i" = if (folds > 1L) "Perplexidade fora da amostra: validação cruzada em {folds} partes." else
      "folds = 1: só perplexidade de treino (tende a cair sempre com k)."
  ))

  ajustar <- function(m, k) {
    topicmodels::LDA(m, k = k, method = method,
                     control = list(seed = seed), ...)
  }

  results <- purrr::map(
    k_range,
    function(k) {
      # Para Gibbs, o topicmodels so calcula perplexidade com newdata;
      # passar o proprio dtm da a perplexidade de treino nos dois metodos.
      perp_train <- topicmodels::perplexity(ajustar(dtm, k), newdata = dtm)
      perp_test <- if (folds > 1L) {
        vapply(seq_len(folds), function(f) {
          treino <- dtm[fold_id != f, ]
          teste  <- dtm[fold_id == f, ]
          modelo <- ajustar(treino, k)
          topicmodels::perplexity(modelo, newdata = teste)
        }, numeric(1))
      } else {
        perp_train
      }
      tibble::tibble(
        k                = k,
        perplexity       = mean(perp_test),
        perplexity_sd    = if (folds > 1L) stats::sd(perp_test) else NA_real_,
        perplexity_train = perp_train
      )
    },
    .progress = if (interactive()) "Ajustando LDA" else FALSE
  )

  dplyr::bind_rows(results)
}


#' Visualizar top termos por tópico
#'
#' @description
#' `ac_plot_lda_topics()` gera um gráfico de barras com os termos de maior
#' probabilidade (beta) para cada tópico do modelo LDA.
#'
#' @param lda_result Objeto `ac_lda`, saída de [ac_lda()].
#' @param top_n Número de termos por tópico. Padrão: `10`.
#' @param ncol Número de colunas nos facets. Padrão: `NULL` (automático).
#' @param title Título. Padrão: `NULL`.
#' @param ... Ignorado.
#'
#' @return Objeto `ggplot`.
#'
#' @examples
#' \donttest{
#' # Corpus sintético com dois blocos tematicos
#' df <- data.frame(
#'   id = paste0("d", 1:8),
#'   texto = c(
#'     "democracia participacao voto cidadania",
#'     "cidadania direitos participacao democracia",
#'     "voto direitos liberdade cidadania",
#'     "democracia voto participacao popular",
#'     "mercado economia eficiência privatizacao",
#'     "privatizacao mercado livre eficiência",
#'     "economia crescimento investimento mercado",
#'     "eficiência mercado economia livre"
#'   ),
#'   stringsAsFactors = FALSE
#' )
#' corpus <- ac_corpus(df, text = texto, docid = id)
#' lda    <- ac_lda(corpus, k = 2)
#'
#' # Grafico com os 5 termos mais probabilisticos por tópico
#' ac_plot_lda_topics(lda, top_n = 5)
#' }
#'
#' @seealso [ac_lda()]
#' @concept visualization
#' @export
ac_plot_lda_topics <- function(lda_result,
                                top_n = 10L,
                                ncol  = NULL,
                                title = NULL,
                                ...) {

  if (!inherits(lda_result, "ac_lda")) {
    cli::cli_abort("{.arg lda_result} deve ser um objeto {.cls ac_lda}.")
  }

  top_terms <- lda_result$terms |>
    dplyr::group_by(topic) |>
    dplyr::slice_max(order_by = beta, n = top_n, with_ties = FALSE) |>
    dplyr::ungroup() |>
    dplyr::mutate(
      topic = paste0("T\u00f3pico ", topic),
      term  = tidytext_reorder(term, beta, topic)
    )

  ggplot2::ggplot(
    top_terms,
    ggplot2::aes(x = term, y = beta, fill = topic)
  ) +
    ggplot2::geom_col(show.legend = FALSE, alpha = 0.85) +
    ggplot2::coord_flip() +
    # tidytext_reorder() cria niveis "termo___Topico k" para ordenar
    # dentro de cada painel; aqui o sufixo e removido dos rotulos.
    ggplot2::scale_x_discrete(labels = function(x) sub("___.*$", "", x)) +
    ggplot2::facet_wrap(~ topic,
                        scales = "free_y",
                        ncol   = ncol %||% ceiling(sqrt(lda_result$k))) +
    ggplot2::scale_fill_viridis_d(option = "D", begin = 0.2, end = 0.9) +
    ggplot2::labs(
      title    = title %||% paste0("Top ", top_n, " termos por t\u00f3pico"),
      subtitle = paste0("Modelo LDA com k = ", lda_result$k, " t\u00f3picos"),
      x        = NULL,
      y        = "Beta (probabilidade do termo)",
      caption  = "acR \u2022 ac_plot_lda_topics()"
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      plot.title       = ggplot2::element_text(face = "bold"),
      plot.subtitle    = ggplot2::element_text(color = "grey40", size = 9),
      plot.caption     = ggplot2::element_text(color = "grey60", size = 8),
      strip.text       = ggplot2::element_text(face = "bold"),
      panel.grid.major.y = ggplot2::element_blank(),
      panel.grid.minor   = ggplot2::element_blank()
    )
}


#' Visualizar curva de seleção de k (perplexidade)
#'
#' @description
#' `ac_plot_lda_tune()` gera um gráfico de linha da perplexidade (ou outras
#' métricas) em função do número de tópicos k, auxiliando na escolha do k
#' ideal para o modelo LDA.
#'
#' @param tune_result Tibble retornado por [ac_lda_tune()].
#' @param title Título. Padrão: `NULL`.
#' @param ... Ignorado.
#'
#' @return Objeto `ggplot`.
#'
#' @examples
#' \donttest{
#' # Corpus sintético com dois blocos tematicos
#' df <- data.frame(
#'   id = paste0("d", 1:8),
#'   texto = c(
#'     "democracia participacao voto cidadania",
#'     "cidadania direitos participacao democracia",
#'     "voto direitos liberdade cidadania",
#'     "democracia voto participacao popular",
#'     "mercado economia eficiência privatizacao",
#'     "privatizacao mercado livre eficiência",
#'     "economia crescimento investimento mercado",
#'     "eficiência mercado economia livre"
#'   ),
#'   stringsAsFactors = FALSE
#' )
#' corpus <- ac_corpus(df, text = texto, docid = id)
#'
#' # Testar k de 2 a 4 e visualizar a curva de perplexidade
#' # (ponto de inflexao/"cotovelo" sugere um bom k)
#' tune <- ac_lda_tune(corpus, k_range = 2:4)
#' ac_plot_lda_tune(tune)
#' }
#'
#' @seealso [ac_lda_tune()]
#' @concept visualization
#' @export
ac_plot_lda_tune <- function(tune_result, title = NULL, ...) {

  if (!is.data.frame(tune_result) || !"perplexity" %in% names(tune_result)) {
    cli::cli_abort(
      "{.arg tune_result} deve ser um tibble com coluna {.val perplexity}."
    )
  }

  ggplot2::ggplot(
    tune_result,
    ggplot2::aes(x = k, y = perplexity)
  ) +
    ggplot2::geom_line(color = "#0072B2", linewidth = 1) +
    ggplot2::geom_point(color = "#0072B2", size = 3) +
    ggplot2::scale_x_continuous(breaks = tune_result$k) +
    ggplot2::labs(
      title    = title %||% "Sele\u00e7\u00e3o do n\u00famero de t\u00f3picos (k)",
      subtitle = "Perplexidade fora da amostra (menor = melhor previsão de documentos novos)",
      x        = "N\u00famero de t\u00f3picos (k)",
      y        = "Perplexidade",
      caption  = "acR \u2022 ac_plot_lda_tune()"
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      plot.title       = ggplot2::element_text(face = "bold"),
      plot.subtitle    = ggplot2::element_text(color = "grey40", size = 9),
      plot.caption     = ggplot2::element_text(color = "grey60", size = 8),
      panel.grid.minor = ggplot2::element_blank()
    )
}


# ============================================================
# Auxiliares internas
# ============================================================

#' @keywords internal
#' @noRd
.ac_to_dtm <- function(dtm_tbl) {
  if (!requireNamespace("tidytext", quietly = TRUE)) {
    cli::cli_abort(c(
      "O pacote {.pkg tidytext} \u00e9 necess\u00e1rio para o LDA.",
      "i" = "Instale com {.code install.packages(\"tidytext\")}."
    ))
  }
  # Remover tokens vazios
  dtm_tbl <- dtm_tbl[dtm_tbl$n > 0L & nchar(dtm_tbl$token) > 0L, ]
  if (nrow(dtm_tbl) == 0L) {
    cli::cli_abort("Matriz de termos vazia ap\u00f3s limpeza.")
  }
  # cast_dtm usa a API est\u00e1vel do tidytext
  tidytext::cast_dtm(
    data      = dtm_tbl,
    document  = doc_id,
    term      = token,
    value     = n
  )
}

#' @keywords internal
#' @noRd
tidytext_reorder <- function(x, by, within) {
  # Reordena x pelo valor de 'by' dentro de cada grupo 'within'
  stats::reorder(interaction(x, within, sep = "___"), by)
}
