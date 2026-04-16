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
#' @examples
#' \dontrun{
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
#'     "educacao universidade pesquisa ciencia",
#'     "participacao social cidadania direitos igualdade",
#'     "mercado trabalho emprego salario industria"
#'   )
#' )
#' corpus <- ac_corpus(df, text = texto, docid = id)
#' lda <- ac_lda(corpus, k = 3)
#' lda
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
#' calcula métricas de qualidade para auxiliar na seleção do número
#' ideal de tópicos.
#'
#' @param corpus Objeto `ac_corpus`.
#' @param k_range Vetor de valores de k a testar. Padrão: `5:20`.
#' @param seed Semente. Padrão: `42`.
#' @param method Método de estimação. Padrão: `"VEM"`.
#' @param ... Ignorado.
#'
#' @return Tibble com colunas `k`, `perplexity` e, se disponível,
#'   métricas do pacote `ldatuning`.
#'
#' @examples
#' \dontrun{
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
#'     "educacao pesquisa ciencia tecnologia",
#'     "participacao social democracia cidadania",
#'     "mercado trabalho emprego salario"
#'   )
#' )
#' corpus <- ac_corpus(df, text = texto, docid = id)
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

  cli::cli_inform("Testando k = {min(k_range)} a {max(k_range)}...")

  results <- purrr::map(k_range, function(k) {
    model <- topicmodels::LDA(
      dtm, k = k, method = method,
      control = list(seed = seed)
    )
    tibble::tibble(
      k           = k,
      perplexity  = topicmodels::perplexity(model)
    )
  })

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
#' \dontrun{
#' lda <- ac_lda(corpus, k = 3)
#' ac_plot_lda_topics(lda, top_n = 8)
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
#' \dontrun{
#' tune <- ac_lda_tune(corpus, k_range = 2:10)
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
      subtitle = "Menor perplexidade indica melhor ajuste",
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
