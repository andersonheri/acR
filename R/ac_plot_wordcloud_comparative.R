#' Nuvem de palavras comparativa entre grupos
#'
#' @description
#' `ac_plot_wordcloud_comparative()` gera uma nuvem de palavras comparativa
#' entre dois grupos de documentos, posicionando termos mais associados a
#' cada grupo em lados opostos. Usa TF-IDF para identificar os termos
#' mais distintivos de cada grupo.
#'
#' @param corpus Objeto `ac_corpus` com coluna de metadado de grupo.
#' @param group Coluna de agrupamento (nome sem aspas ou string).
#' @param max_words Número máximo de palavras por grupo. Padrão: `50`.
#' @param colors Vetor com duas cores (uma por grupo). Padrão: paleta
#'   acessível Okabe-Ito.
#' @param title Título do gráfico. Padrão: `NULL`.
#' @param ... Ignorado.
#'
#' @return Objeto `ggplot`.
#'
#' @examples
#' df <- data.frame(
#'   id     = paste0("d", 1:6),
#'   texto  = c(
#'     "democracia participacao popular voto",
#'     "direitos cidadania liberdade democracia",
#'     "participacao popular igualdade direitos",
#'     "mercado economia privatizacao eficiencia",
#'     "privatizacao mercado livre eficiencia",
#'     "economia crescimento mercado investimento"
#'   ),
#'   grupo = c("A","A","A","B","B","B")
#' )
#' corpus <- ac_corpus(df, text = texto, docid = id)
#' ac_plot_wordcloud_comparative(corpus, group = grupo)
#'
#' @seealso [ac_tf_idf()]
#' @concept visualization
#' @export
ac_plot_wordcloud_comparative <- function(corpus,
                                           group,
                                           max_words = 50L,
                                           colors    = c("#0072B2", "#D55E00"),
                                           title     = NULL,
                                           ...) {

  if (!is_ac_corpus(corpus)) {
    cli::cli_abort("{.arg corpus} deve ser um {.cls ac_corpus}.")
  }

  group_col <- tryCatch(
    rlang::as_name(rlang::enquo(group)),
    error = function(e) as.character(substitute(group))
  )

  if (!group_col %in% names(corpus)) {
    cli::cli_abort(c(
      "Coluna de grupo {.val {group_col}} n\u00e3o existe em {.arg corpus}.",
      "i" = "Colunas dispon\u00edveis: {.val {names(corpus)}}."
    ))
  }

  grupos <- unique(corpus[[group_col]])
  if (length(grupos) != 2L) {
    cli::cli_abort(c(
      "{.fn ac_plot_wordcloud_comparative} requer exatamente 2 grupos.",
      "x" = "Encontrados {length(grupos)} grupos: {.val {grupos}}."
    ))
  }

  # Tokenizar e calcular TF-IDF por grupo
  tokens_tbl <- corpus |>
    ac_clean() |>
    ac_tokenize()

  # Adicionar grupo ao tibble de tokens
  meta <- corpus |>
    tibble::as_tibble() |>
    dplyr::select("doc_id", grp = dplyr::all_of(group_col))

  tokens_grp <- tokens_tbl |>
    dplyr::left_join(meta, by = "doc_id") |>
    dplyr::count(grp, token, name = "n")

  # TF-IDF por grupo (tratando cada grupo como "documento")
  tfidf_grp <- tokens_grp |>
    dplyr::rename(doc_id = grp) |>
    ac_tf_idf() |>
    dplyr::rename(grp = doc_id)

  # Top termos por grupo
  top_grp <- tfidf_grp |>
    dplyr::group_by(grp) |>
    dplyr::slice_max(order_by = tf_idf, n = max_words, with_ties = FALSE) |>
    dplyr::ungroup()

  # Cores por grupo
  color_map <- stats::setNames(colors[seq_along(grupos)], as.character(grupos))
  top_grp$color <- color_map[as.character(top_grp$grp)]

  # Plot com ggplot2 (posicionamento proporcional ao tf_idf)
  top_grp <- top_grp |>
    dplyr::group_by(grp) |>
    dplyr::mutate(
      size_norm = scales::rescale(tf_idf, to = c(3, 10))
    ) |>
    dplyr::ungroup()

  # Posicionar grupo A à esquerda, B à direita
  top_grp$x_jitter <- ifelse(
    top_grp$grp == grupos[1],
    stats::runif(nrow(top_grp), -1, -0.1),
    stats::runif(nrow(top_grp), 0.1, 1)
  )
  top_grp$y_jitter <- stats::runif(nrow(top_grp), -1, 1)

  p <- ggplot2::ggplot(
    top_grp,
    ggplot2::aes(x = x_jitter, y = y_jitter,
                 label = token, size = size_norm, color = grp)
  ) +
    ggplot2::geom_text(alpha = 0.85) +
    ggplot2::scale_color_manual(
      values = color_map,
      name   = group_col
    ) +
    ggplot2::scale_size(range = c(3, 10), guide = "none") +
    ggplot2::geom_vline(xintercept = 0, color = "grey80", linewidth = 0.5) +
    ggplot2::annotate("text", x = -0.55, y = 1.05,
                      label = as.character(grupos[1]),
                      fontface = "bold", color = colors[1], size = 4) +
    ggplot2::annotate("text", x = 0.55, y = 1.05,
                      label = as.character(grupos[2]),
                      fontface = "bold", color = colors[2], size = 4) +
    ggplot2::labs(
      title    = title,
      subtitle = paste0("Termos distintivos por grupo (TF-IDF) \u2022 top ",
                        max_words, " por grupo"),
      caption  = "acR \u2022 ac_plot_wordcloud_comparative()"
    ) +
    ggplot2::theme_void() +
    ggplot2::theme(
      plot.title    = ggplot2::element_text(face = "bold", hjust = 0.5),
      plot.subtitle = ggplot2::element_text(color = "grey40",
                                            hjust = 0.5, size = 9),
      plot.caption  = ggplot2::element_text(color = "grey60", size = 8,
                                            hjust = 1),
      legend.position = "none"
    )

  p
}


#' Gráfico X-ray — dispersão lexical de termos no corpus
#'
#' @description
#' `ac_plot_xray()` exibe a posição de ocorrência de um ou mais termos ao
#' longo do texto de cada documento, como marcações verticais numa linha
#' horizontal. Útil para visualizar padrões de uso ao longo de discursos,
#' capítulos ou documentos longos.
#'
#' @param corpus Objeto `ac_corpus`.
#' @param terms Vetor de termos a rastrear (após limpeza e tokenização).
#' @param ignore_case Se `TRUE` (padrão), ignora diferenças de capitalização.
#' @param colors Vetor de cores para os termos. Se `NULL`, usa paleta padrão.
#' @param title Título do gráfico. Padrão: `NULL`.
#' @param ... Ignorado.
#'
#' @return Objeto `ggplot`.
#'
#' @examples
#' df <- data.frame(
#'   id = c("d1", "d2"),
#'   texto = c(
#'     "democracia liberdade igualdade democracia direitos democracia",
#'     "mercado liberdade privatizacao mercado eficiencia mercado"
#'   )
#' )
#' corpus <- ac_corpus(df, text = texto, docid = id)
#' ac_plot_xray(corpus, terms = c("democracia", "mercado", "liberdade"))
#'
#' @seealso [ac_corpus()]
#' @concept visualization
#' @export
ac_plot_xray <- function(corpus,
                          terms,
                          ignore_case = TRUE,
                          colors      = NULL,
                          title       = NULL,
                          ...) {

  if (!is_ac_corpus(corpus)) {
    cli::cli_abort("{.arg corpus} deve ser um {.cls ac_corpus}.")
  }
  if (!is.character(terms) || length(terms) == 0L) {
    cli::cli_abort("{.arg terms} deve ser um vetor character n\u00e3o vazio.")
  }

  # Tokenizar
  tokens_tbl <- ac_tokenize(corpus)

  if (isTRUE(ignore_case)) {
    tokens_tbl$token <- tolower(tokens_tbl$token)
    terms_lookup     <- tolower(terms)
  } else {
    terms_lookup <- terms
  }

  # Filtrar só tokens que são os termos buscados
  hits <- tokens_tbl |>
    dplyr::filter(token %in% terms_lookup) |>
    dplyr::rename(term = token)

  # Recuperar termo original (para label)
  term_map <- stats::setNames(terms, terms_lookup)
  hits$term_label <- term_map[hits$term]

  if (nrow(hits) == 0L) {
    cli::cli_warn("Nenhum dos termos foi encontrado no corpus ap\u00f3s tokeniza\u00e7\u00e3o.")
    return(ggplot2::ggplot() +
             ggplot2::labs(title = "Nenhum termo encontrado") +
             ggplot2::theme_void())
  }

  # Calcular posição relativa dentro do documento (0 a 1)
  n_tokens_doc <- tokens_tbl |>
    dplyr::group_by(doc_id) |>
    dplyr::summarise(n_total = dplyr::n(), .groups = "drop")

  hits <- hits |>
    dplyr::left_join(n_tokens_doc, by = "doc_id") |>
    dplyr::mutate(pos_rel = (token_id - 1L) / (n_total - 1L))

  # Cores dos termos
  if (is.null(colors)) {
    colors <- c("#0072B2", "#D55E00", "#009E73", "#CC79A7",
                "#F0E442", "#56B4E9", "#E69F00")[seq_along(terms)]
  }
  color_map <- stats::setNames(colors[seq_along(terms)], terms)

  p <- ggplot2::ggplot(
    hits,
    ggplot2::aes(x = pos_rel, y = 0, color = term_label)
  ) +
    ggplot2::geom_segment(
      ggplot2::aes(xend = pos_rel, yend = 0.8),
      alpha = 0.7, linewidth = 0.6
    ) +
    ggplot2::facet_grid(doc_id ~ term_label) +
    ggplot2::scale_x_continuous(
      labels = scales::percent_format(accuracy = 1),
      limits = c(0, 1),
      expand = c(0.01, 0.01)
    ) +
    ggplot2::scale_color_manual(values = color_map, guide = "none") +
    ggplot2::labs(
      title    = title,
      subtitle = paste0("Dispers\u00e3o lexical: ",
                        paste(terms, collapse = ", ")),
      x        = "Posi\u00e7\u00e3o relativa no documento",
      y        = NULL,
      caption  = "acR \u2022 ac_plot_xray()"
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      axis.text.y      = ggplot2::element_blank(),
      axis.ticks.y     = ggplot2::element_blank(),
      panel.grid.major.y = ggplot2::element_blank(),
      panel.grid.minor   = ggplot2::element_blank(),
      strip.text         = ggplot2::element_text(face = "bold", size = 9),
      plot.title         = ggplot2::element_text(face = "bold"),
      plot.subtitle      = ggplot2::element_text(color = "grey40", size = 9),
      plot.caption       = ggplot2::element_text(color = "grey60", size = 8)
    )

  p
}
