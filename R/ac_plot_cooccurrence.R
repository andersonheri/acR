#' Visualizar rede de co-ocorrência de termos
#'
#' @description
#' `ac_plot_cooccurrence()` gera um gráfico de rede a partir de um tibble de
#' co-ocorrências (saída de [ac_cooccurrence()]), usando `ggplot2` e `ggraph`.
#'
#' @param cooc Tibble com co-ocorrências, saída de [ac_cooccurrence()].
#' @param top_n Número de pares mais frequentes a exibir. Padrão: `50`.
#' @param weight Coluna a usar como peso das arestas:
#'   `"cooc"` (padrão), `"pmi"` ou `"dice"`.
#' @param layout Layout do grafo. Qualquer layout suportado por
#'   `ggraph::ggraph()`: `"fr"` (Fruchterman-Reingold, padrão),
#'   `"kk"`, `"circle"`, etc.
#' @param node_color Cor dos nós. Padrão: `"#0072B2"`.
#' @param edge_color Cor das arestas. Padrão: `"grey70"`.
#' @param title Título do gráfico. Padrão: `NULL`.
#' @param ... Ignorado.
#'
#' @return Objeto `ggplot`.
#'
#' @examples
#' df <- data.frame(
#'   id = c("d1", "d2", "d3"),
#'   texto = c(
#'     "democracia participacao cidadania",
#'     "participacao politica democracia",
#'     "cidadania direitos participacao"
#'   )
#' )
#' corpus <- ac_corpus(df, text = texto, docid = id) |> ac_clean()
#' cooc <- ac_cooccurrence(ac_tokenize(corpus), min_count = 1)
#' if (requireNamespace("ggraph", quietly = TRUE)) {
#'   ac_plot_cooccurrence(cooc)
#' }
#'
#' @seealso [ac_cooccurrence()]
#' @concept visualization
#' @export
ac_plot_cooccurrence <- function(cooc,
                                  top_n      = 50L,
                                  weight     = c("cooc", "pmi", "dice"),
                                  layout     = "fr",
                                  node_color = "#0072B2",
                                  edge_color = "grey70",
                                  title      = NULL,
                                  ...) {

  if (!requireNamespace("ggraph", quietly = TRUE)) {
    cli::cli_abort(c(
      "O pacote {.pkg ggraph} \u00e9 necess\u00e1rio para {.fn ac_plot_cooccurrence}.",
      "i" = "Instale com {.code install.packages(\"ggraph\")}."
    ))
  }
  if (!requireNamespace("igraph", quietly = TRUE)) {
    cli::cli_abort(c(
      "O pacote {.pkg igraph} \u00e9 necess\u00e1rio para {.fn ac_plot_cooccurrence}.",
      "i" = "Instale com {.code install.packages(\"igraph\")}."
    ))
  }

  weight <- match.arg(weight)

  if (!weight %in% names(cooc)) {
    cli::cli_abort(c(
      "Coluna {.val {weight}} n\u00e3o existe em {.arg cooc}.",
      "i" = "Colunas dispon\u00edveis: {.val {names(cooc)}}."
    ))
  }

  # Filtrar top_n pares
  df_plot <- cooc |>
    dplyr::slice_max(order_by = .data[[weight]], n = top_n, with_ties = FALSE)

  # Construir grafo
  grafo <- igraph::graph_from_data_frame(
    d        = df_plot |>
      dplyr::select("word1", "word2", w = dplyr::all_of(weight)),
    directed = FALSE
  )

  # Grau dos nós para tamanho
  igraph::V(grafo)$degree <- igraph::degree(grafo)

  # Plot
  p <- ggraph::ggraph(grafo, layout = layout) +
    ggraph::geom_edge_link(
      ggplot2::aes(width = w, alpha = w),
      color = edge_color,
      show.legend = FALSE
    ) +
    ggraph::scale_edge_width(range = c(0.3, 2)) +
    ggraph::scale_edge_alpha(range = c(0.3, 0.9)) +
    ggraph::geom_node_point(
      ggplot2::aes(size = degree),
      color = node_color,
      alpha = 0.8
    ) +
    ggraph::geom_node_text(
      ggplot2::aes(label = name),
      repel = TRUE,
      size  = 3,
      color = "grey20"
    ) +
    ggplot2::scale_size(range = c(2, 8)) +
    ggplot2::labs(
      title    = title,
      subtitle = paste0("Top ", top_n, " pares \u2022 peso: ", weight),
      caption  = "acR \u2022 ac_plot_cooccurrence()"
    ) +
    ggraph::theme_graph(base_family = "") +
    ggplot2::theme(
      plot.title    = ggplot2::element_text(face = "bold"),
      plot.subtitle = ggplot2::element_text(color = "grey40", size = 9),
      plot.caption  = ggplot2::element_text(color = "grey60", size = 8)
    )

  p
}
