#' Visualiza um objeto ac_cluster
#'
#' @description
#' Tres formas complementares de olhar para o mesmo cluster:
#'
#' - `"dendrogram"` (padrao para `method = "hclust"`): arvore de fusoes
#'   com cortes coloridos por grupo.
#' - `"scatter"`: projecao 2D via PCA sobre a matriz documento-termo, com
#'   pontos coloridos por cluster.
#' - `"heatmap"`: mapa de calor da matriz de dissimilaridade, ordenado
#'   pelo dendrograma.
#'
#' @param x Objeto `ac_cluster` (saida de [ac_cluster_documents()]).
#' @param kind Tipo de grafico. `"auto"` (padrao) escolhe conforme o metodo
#'   (dendrograma para `hclust`, scatter para `kmeans`/`pam`).
#' @param title Titulo do grafico.
#' @param palette Vetor de cores para os clusters. Padrao: [ac_palette()].
#'
#' @return Objeto `ggplot`.
#'
#' @examples
#' df <- data.frame(
#'   id = paste0("d", 1:8),
#'   texto = c("democracia participacao voto",
#'             "cidadania direitos participacao",
#'             "voto direitos liberdade",
#'             "democracia voto participacao",
#'             "mercado economia eficiencia",
#'             "privatizacao mercado livre",
#'             "economia crescimento mercado",
#'             "eficiencia mercado livre")
#' )
#' corpus <- ac_corpus(df, text = texto, docid = id)
#' clust  <- ac_cluster_documents(corpus, k = 2)
#' ac_plot_cluster(clust)
#'
#' @seealso [ac_cluster_documents()]
#' @concept visualization
#' @export
ac_plot_cluster <- function(x,
                            kind    = c("auto", "dendrogram", "scatter",
                                        "heatmap"),
                            title   = NULL,
                            palette = NULL) {

  if (!inherits(x, "ac_cluster")) {
    cli::cli_abort("{.arg x} deve ser um objeto {.cls ac_cluster}.")
  }
  kind <- match.arg(kind)
  if (kind == "auto") {
    kind <- if (x$method == "hclust") "dendrogram" else "scatter"
  }
  if (kind == "dendrogram" && x$method != "hclust") {
    cli::cli_warn("{.val dendrogram} so faz sentido para {.arg method = 'hclust'}; usando {.val scatter}.")
    kind <- "scatter"
  }
  if (is.null(palette)) palette <- ac_palette(min(x$k, 8L))

  switch(kind,
    dendrogram = .plot_cluster_dendrogram(x, palette, title),
    scatter    = .plot_cluster_scatter(x, palette, title),
    heatmap    = .plot_cluster_heatmap(x, palette, title)
  )
}


#' @noRd
.plot_cluster_dendrogram <- function(x, palette, title) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    cli::cli_abort("Pacote {.pkg ggplot2} necessario.")
  }
  h  <- x$fit
  cl <- stats::cutree(h, k = x$k)
  ord <- h$order
  labs <- h$labels[ord]
  seg <- .dendro_segments(h)

  # Anotar cor por cluster no eixo x
  leaf_df <- data.frame(
    doc_id  = labs,
    x       = seq_along(labs),
    cluster = factor(cl[labs])
  )

  ggplot2::ggplot() +
    ggplot2::geom_segment(
      data = seg,
      ggplot2::aes(x = x, xend = xend, y = y, yend = yend),
      color = "grey40", linewidth = 0.4
    ) +
    ggplot2::geom_point(
      data = leaf_df,
      ggplot2::aes(x = x, y = 0, color = cluster),
      size = 3
    ) +
    ggplot2::scale_x_continuous(
      breaks = leaf_df$x,
      labels = leaf_df$doc_id,
      expand = c(0.02, 0.02)
    ) +
    ggplot2::scale_color_manual(values = palette, name = "Cluster") +
    ggplot2::labs(
      title    = title %||% "Dendrograma dos documentos",
      subtitle = sprintf("Metodo: hclust (Ward.D2) \u2022 k = %d \u2022 dist: %s",
                         x$k, x$distance),
      x = NULL, y = "Altura de fusao",
      caption = "acR \u2022 ac_plot_cluster(kind = 'dendrogram')"
    ) +
    theme_ac() +
    ggplot2::theme(
      axis.text.x = ggplot2::element_text(angle = 45, hjust = 1)
    )
}


#' @noRd
.plot_cluster_scatter <- function(x, palette, title) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    cli::cli_abort("Pacote {.pkg ggplot2} necessario.")
  }
  pca <- stats::prcomp(x$dtm, scale. = FALSE)
  scores <- as.data.frame(pca$x[, 1:2, drop = FALSE])
  colnames(scores) <- c("PC1", "PC2")
  scores$doc_id  <- rownames(x$dtm)
  scores$cluster <- factor(x$assignments$cluster[
    match(scores$doc_id, x$assignments$doc_id)
  ])

  vexp <- summary(pca)$importance[2, 1:2] * 100

  ggplot2::ggplot(
    scores,
    ggplot2::aes(PC1, PC2, color = cluster, label = doc_id)
  ) +
    ggplot2::geom_point(size = 3, alpha = 0.85) +
    ggplot2::geom_text(vjust = -1.1, size = 3, color = "grey30",
                       show.legend = FALSE) +
    ggplot2::scale_color_manual(values = palette, name = "Cluster") +
    ggplot2::labs(
      title    = title %||% "Projecao 2D dos documentos (PCA)",
      subtitle = sprintf(
        "Metodo: %s \u2022 k = %d \u2022 PC1: %.1f%%, PC2: %.1f%%",
        x$method, x$k, vexp[1], vexp[2]
      ),
      caption = "acR \u2022 ac_plot_cluster(kind = 'scatter')"
    ) +
    theme_ac()
}


#' @noRd
.plot_cluster_heatmap <- function(x, palette, title) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    cli::cli_abort("Pacote {.pkg ggplot2} necessario.")
  }
  d <- as.matrix(.cluster_distance(x$dtm, x$distance))
  # Ordenar por dendrograma para revelar blocos
  ord <- if (x$method == "hclust") x$fit$order else {
    stats::hclust(stats::as.dist(d), method = "ward.D2")$order
  }
  d   <- d[ord, ord]
  df  <- expand.grid(x = rownames(d), y = colnames(d))
  df$dist <- as.vector(d)
  df$x <- factor(df$x, levels = rownames(d))
  df$y <- factor(df$y, levels = rev(colnames(d)))

  ggplot2::ggplot(df, ggplot2::aes(x, y, fill = dist)) +
    ggplot2::geom_tile(color = "white") +
    ggplot2::scale_fill_gradient(low = ac_palette(1), high = "#F1F5F9",
                                 name = "Dissim.") +
    ggplot2::labs(
      title    = title %||% "Matriz de dissimilaridade entre documentos",
      subtitle = sprintf("Distancia: %s \u2022 ordenada por dendrograma",
                         x$distance),
      x = NULL, y = NULL,
      caption = "acR \u2022 ac_plot_cluster(kind = 'heatmap')"
    ) +
    theme_ac() +
    ggplot2::theme(
      axis.text.x = ggplot2::element_text(angle = 45, hjust = 1)
    )
}


#' @noRd
.dendro_segments <- function(h) {
  # Converte hclust em segmentos para geom_segment (evita ggdendro).
  n <- length(h$order)
  x <- integer(n); x[h$order] <- seq_len(n)
  merge <- h$merge; hgt <- h$height
  # posicao horizontal de cada merge
  xm <- numeric(nrow(merge)); ym <- hgt
  for (i in seq_len(nrow(merge))) {
    coords <- vapply(merge[i, ], function(m) {
      if (m < 0) x[-m] else xm[m]
    }, numeric(1))
    xm[i] <- mean(coords)
  }
  # Construir segmentos: 2 verticais + 1 horizontal por merge
  segs <- vector("list", nrow(merge))
  for (i in seq_len(nrow(merge))) {
    left <- if (merge[i, 1] < 0) c(x[-merge[i, 1]], 0)
            else c(xm[merge[i, 1]], hgt[merge[i, 1]])
    right <- if (merge[i, 2] < 0) c(x[-merge[i, 2]], 0)
             else c(xm[merge[i, 2]], hgt[merge[i, 2]])
    segs[[i]] <- data.frame(
      x    = c(left[1], right[1], left[1]),
      xend = c(left[1], right[1], right[1]),
      y    = c(left[2], right[2], hgt[i]),
      yend = c(hgt[i],  hgt[i],   hgt[i])
    )
  }
  do.call(rbind, segs)
}
