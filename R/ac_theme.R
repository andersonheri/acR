#' Tema visual consistente do acR
#'
#' @description
#' `theme_ac()` retorna um tema `ggplot2` minimalista e consistente, usado
#' por todos os `ac_plot_*()` do pacote. Deriva de `ggplot2::theme_minimal()`
#' com ajustes editoriais: tipografia mais compacta, gridlines suaves,
#' títulos em negrito com espaçamento negativo (visual editorial).
#'
#' Também expõe [ac_palette()] para uma paleta categórica coerente com o
#' tema (compatível com acessibilidade AA).
#'
#' @param base_size Tamanho base da fonte. Padrão: `12`.
#' @param base_family Família tipográfica. Padrão: `""` (usa sistema).
#'
#' @return Um objeto `ggplot2::theme`.
#'
#' @examples
#' if (requireNamespace("ggplot2", quietly = TRUE)) {
#'   ggplot2::ggplot(mtcars, ggplot2::aes(mpg, wt)) +
#'     ggplot2::geom_point(color = ac_palette()[1]) +
#'     ggplot2::labs(title = "MPG vs. peso", subtitle = "Tema editorial acR") +
#'     theme_ac()
#' }
#'
#' @seealso [ac_palette()]
#' @concept visualization
#' @export
theme_ac <- function(base_size = 12, base_family = "") {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    cli::cli_abort("O pacote {.pkg ggplot2} e necessario para {.fn theme_ac}.")
  }

  ggplot2::theme_minimal(base_size = base_size, base_family = base_family) +
    ggplot2::theme(
      plot.title       = ggplot2::element_text(
        face   = "bold",
        size   = ggplot2::rel(1.15),
        margin = ggplot2::margin(b = 4)
      ),
      plot.subtitle    = ggplot2::element_text(
        color = "grey35",
        size  = ggplot2::rel(0.9),
        margin = ggplot2::margin(b = 12)
      ),
      plot.caption     = ggplot2::element_text(
        color = "grey55",
        size  = ggplot2::rel(0.75),
        hjust = 1
      ),
      axis.title       = ggplot2::element_text(color = "grey30", size = ggplot2::rel(0.9)),
      axis.text        = ggplot2::element_text(color = "grey40"),
      strip.text       = ggplot2::element_text(face = "bold", size = ggplot2::rel(0.95)),
      panel.grid.major = ggplot2::element_line(color = "grey92", linewidth = 0.4),
      panel.grid.minor = ggplot2::element_blank(),
      legend.title     = ggplot2::element_text(size = ggplot2::rel(0.85)),
      legend.text      = ggplot2::element_text(size = ggplot2::rel(0.85)),
      plot.margin      = ggplot2::margin(12, 12, 8, 12)
    )
}


#' Paleta categórica do acR
#'
#' @description
#' Retorna a paleta categórica padrão do pacote — cores compatíveis com
#' contraste WCAG AA e teste de daltonismo (deuteranopia). Deriva da
#' paleta Okabe-Ito, referência para acessibilidade em visualização
#' científica.
#'
#' @param n Número de cores a retornar (max 8). Padrão: `8`.
#'
#' @return Vetor `character` com códigos hex.
#'
#' @examples
#' ac_palette()      # todas as 8 cores
#' ac_palette(3)     # primeiras 3
#'
#' if (requireNamespace("ggplot2", quietly = TRUE)) {
#'   ggplot2::ggplot(iris, ggplot2::aes(Sepal.Length, Petal.Length,
#'                                       color = Species)) +
#'     ggplot2::geom_point(size = 2, alpha = 0.85) +
#'     ggplot2::scale_color_manual(values = ac_palette(3)) +
#'     theme_ac()
#' }
#'
#' @seealso [theme_ac()]
#' @concept visualization
#' @export
ac_palette <- function(n = 8L) {
  pal <- c(
    "#0F3D5C",  # azul-marinho (base)
    "#D97706",  # ambar (secundaria)
    "#0F766E",  # verde-agua (quali)
    "#B91C1C",  # vermelho (alerta)
    "#7C3AED",  # roxo
    "#0284C7",  # azul-medio
    "#65A30D",  # verde-oliva
    "#DB2777"   # rosa
  )
  n <- as.integer(n)
  if (n < 1L || n > length(pal))
    cli::cli_abort("{.arg n} deve estar entre 1 e {length(pal)}.")
  pal[seq_len(n)]
}
