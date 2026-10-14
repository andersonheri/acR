#' Visualizar a Lei de Zipf (frequência × posto)
#'
#' @description
#' `ac_plot_zipf()` produz o gráfico diagnóstico clássico de Zipf (1949):
#' frequência de cada palavra contra sua posição no ranking de
#' frequência (1º, 2º, 3º... termo mais comum), em escala log-log. Em
#' praticamente qualquer corpus de linguagem natural — avaliações de
#' produto, letras de música, posts de redes sociais, discursos — essa
#' relação é aproximadamente linear com inclinação próxima de -1: a
#' palavra mais frequente aparece cerca de duas vezes mais que a
#' segunda, três vezes mais que a terceira, e assim por diante.
#'
#' É útil como **diagnóstico de qualidade do corpus** antes de qualquer
#' análise mais sofisticada: desvios fortes da reta esperada podem
#' indicar problemas de tokenização (pontuação não removida dominando o
#' ranking), um corpus pequeno demais, ou texto fortemente repetitivo
#' (boilerplate, templates).
#'
#' @param freq_tbl Tibble com colunas `token` e `n`, tipicamente a saída
#'   de [ac_count()]. Se vier com uma coluna de grupo (de
#'   `ac_count(corp, by = ...)`), use `by` para facetar.
#' @param by Nome da coluna de grupo em `freq_tbl` para facetar o
#'   gráfico (um painel por grupo). Padrão: `NULL` (corpus inteiro).
#' @param title Título do gráfico. Padrão: `NULL`.
#'
#' @return Objeto `ggplot`.
#'
#' @references
#' Zipf, G. K. (1949). *Human Behavior and the Principle of Least
#' Effort*. Addison-Wesley.
#'
#' @examples
#' # Avaliacoes de produtos de duas categorias
#' df <- data.frame(
#'   id = paste0("r", 1:6),
#'   texto = c(
#'     "bom produto bom preco bom atendimento",
#'     "produto bom mas entrega lenta",
#'     "preco justo produto funcional",
#'     "pessimo atendimento produto com defeito",
#'     "excelente produto rapido e eficiente",
#'     "produto ok nada de especial"
#'   ),
#'   categoria = rep(c("eletronico", "casa"), 3),
#'   stringsAsFactors = FALSE
#' )
#' corpus <- ac_corpus(df, text = texto, docid = id)
#' freq <- ac_count(corpus, drop_punct = TRUE, by = NULL)
#'
#' ac_plot_zipf(freq)
#'
#' @seealso [ac_count()], [ac_top_terms()]
#' @concept visualization
#' @export
ac_plot_zipf <- function(freq_tbl, by = NULL, title = NULL) {
  if (!is.data.frame(freq_tbl)) {
    cli::cli_abort("{.arg freq_tbl} deve ser um data.frame ou tibble.")
  }
  if (!all(c("token", "n") %in% names(freq_tbl))) {
    cli::cli_abort(
      "{.arg freq_tbl} deve conter, no m\u00ednimo, as colunas {.field token} e {.field n}."
    )
  }
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    cli::cli_abort("O pacote {.pkg ggplot2} \u00e9 necess\u00e1rio.")
  }
  if (!requireNamespace("dplyr", quietly = TRUE)) {
    cli::cli_abort("O pacote {.pkg dplyr} \u00e9 necess\u00e1rio.")
  }

  if (is.null(by)) {
    ranked <- freq_tbl |>
      dplyr::group_by(token) |>
      dplyr::summarise(n = sum(n), .groups = "drop") |>
      dplyr::filter(n > 0) |>
      dplyr::arrange(dplyr::desc(n)) |>
      dplyr::mutate(rank = dplyr::row_number(), ideal = n[1] / rank)
  } else {
    if (!by %in% names(freq_tbl)) {
      cli::cli_abort("{.arg by} deve ser uma coluna existente em {.arg freq_tbl}.")
    }
    ranked <- freq_tbl |>
      dplyr::group_by(.data[[by]], token) |>
      dplyr::summarise(n = sum(n), .groups = "drop") |>
      dplyr::filter(n > 0) |>
      dplyr::group_by(.data[[by]]) |>
      dplyr::arrange(dplyr::desc(n), .by_group = TRUE) |>
      dplyr::mutate(rank = dplyr::row_number(), ideal = n[1] / rank) |>
      dplyr::ungroup()
  }

  p <- ggplot2::ggplot(ranked, ggplot2::aes(x = rank, y = n)) +
    ggplot2::geom_point(alpha = 0.4, color = "#2C7FB8") +
    ggplot2::geom_line(ggplot2::aes(y = ideal), color = "grey40",
                       linetype = "dashed", linewidth = 0.5) +
    ggplot2::scale_x_log10() +
    ggplot2::scale_y_log10() +
    ggplot2::labs(
      title    = title,
      subtitle = "Linha tracejada = Lei de Zipf ideal (inclina\u00e7\u00e3o -1)",
      x        = "Posto (rank) em escala log",
      y        = "Frequ\u00eancia em escala log",
      caption  = "acR \u2022 Zipf (1949)"
    ) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      plot.title    = ggplot2::element_text(face = "bold"),
      plot.subtitle = ggplot2::element_text(color = "grey40", size = 9),
      plot.caption  = ggplot2::element_text(color = "grey60", size = 8, hjust = 1),
      panel.grid.minor = ggplot2::element_blank()
    )

  if (!is.null(by)) {
    p <- p + ggplot2::facet_wrap(ggplot2::vars(.data[[by]]))
  }

  p
}
