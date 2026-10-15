#' Agregar uma métrica por período de tempo
#'
#' @description
#' `ac_temporal()` agrega qualquer métrica por documento (sentimento,
#' frequência de um termo, legibilidade, confiança de classificação...)
#' em janelas de tempo, para análise diacrônica — a pergunta "isso mudou
#' ao longo do tempo?" aparece em quase todo estudo de conteúdo com
#' timestamp: cobertura de imprensa sobre um tema, reclamações de
#' clientes por mês, evolução do tom de comunicados de uma empresa,
#' posts de redes sociais durante uma crise.
#'
#' A função é deliberadamente genérica: não importa se o valor vem de
#' [ac_sentiment()], [ac_readability()], [ac_count()] filtrado para um
#' termo específico, ou da saída de [ac_qual_code()] — qualquer tibble
#' com uma coluna de data e uma coluna numérica serve de entrada.
#'
#' @param data Tibble (ou `data.frame`) com, no mínimo, uma coluna de
#'   data e uma coluna numérica a agregar — tipicamente o resultado de
#'   uma das funções de análise do pacote, unido aos metadados do
#'   corpus (ex.: `dplyr::left_join()` de [ac_sentiment()] com a data de
#'   cada documento).
#' @param date_col Nome da coluna de data em `data`. Convertida com
#'   `as.Date()` se ainda não for `Date`.
#' @param value_col Nome da coluna numérica a agregar por período.
#' @param unit Unidade temporal da agregação: `"day"`, `"week"`,
#'   `"month"` (padrão) ou `"year"`.
#' @param stat Estatística de agregação dentro de cada período:
#'   `"mean"` (padrão), `"sum"` ou `"n"` (contagem de documentos,
#'   ignorando `value_col`).
#'
#' @return Tibble com colunas `period` (`Date`, início do período),
#'   `value` (estatística agregada) e `n_docs` (documentos naquele
#'   período).
#'
#' @references
#' Welbers, K.; Van Atteveldt, W.; Benoit, K. (2017). Text Analysis in
#' R. *Communication Methods and Measures*, 11(4), 245-265.
#'
#' @examples
#' # Reclamacoes de clientes ao longo de alguns meses, com score de
#' # sentimento já calculado por documento (ex.: saida de ac_sentiment())
#' df <- data.frame(
#'   doc_id = paste0("d", 1:6),
#'   data   = as.Date(c("2024-01-05", "2024-01-20", "2024-02-02",
#'                      "2024-02-15", "2024-03-01", "2024-03-10")),
#'   score  = c(-2, -1, 0, 1, 2, 1)
#' )
#'
#' ac_temporal(df, date_col = "data", value_col = "score", unit = "month")
#'
#' @seealso [ac_plot_temporal()], [ac_sentiment()]
#' @concept quantitative
#' @export
ac_temporal <- function(data,
                         date_col,
                         value_col,
                         unit = c("month", "day", "week", "year"),
                         stat = c("mean", "sum", "n")) {
  if (!is.data.frame(data)) {
    cli::cli_abort("{.arg data} deve ser um data.frame ou tibble.")
  }
  if (!date_col %in% names(data)) {
    cli::cli_abort("{.arg date_col} ({.val {date_col}}) n\u00e3o existe em {.arg data}.")
  }
  unit <- match.arg(unit)
  stat <- match.arg(stat)
  if (!value_col %in% names(data) && stat != "n") {
    cli::cli_abort("{.arg value_col} ({.val {value_col}}) n\u00e3o existe em {.arg data}.")
  }

  datas <- as.Date(data[[date_col]])
  if (all(is.na(datas))) {
    cli::cli_abort("{.arg date_col} n\u00e3o p\u00f4de ser convertida para {.cls Date}.")
  }

  periodo <- as.Date(cut(datas, breaks = unit))

  valores <- if (stat == "n") rep(NA_real_, length(datas)) else as.numeric(data[[value_col]])

  tibble::tibble(period = periodo, value = valores) |>
    dplyr::group_by(period) |>
    dplyr::summarise(
      value  = switch(stat,
        "mean" = mean(value, na.rm = TRUE),
        "sum"  = sum(value, na.rm = TRUE),
        "n"    = dplyr::n()
      ),
      n_docs = dplyr::n(),
      .groups = "drop"
    ) |>
    dplyr::arrange(period)
}


#' Visualizar uma série temporal de conteúdo
#'
#' @description
#' `ac_plot_temporal()` traça a evolução de uma métrica agregada por
#' período, saída de [ac_temporal()], com uma linha de tendência
#' suavizada opcional.
#'
#' @param temporal_tbl Tibble retornado por [ac_temporal()].
#' @param smooth Lógico. Se `TRUE` (padrão), adiciona uma curva de
#'   tendência (LOESS) sobre os pontos observados.
#' @param title Título do gráfico. Padrão: `NULL`.
#' @param ylab Rótulo do eixo Y. Padrão: `"Valor"`.
#'
#' @return Objeto `ggplot`.
#'
#' @examples
#' df <- data.frame(
#'   doc_id = paste0("d", 1:6),
#'   data   = as.Date(c("2024-01-05", "2024-01-20", "2024-02-02",
#'                      "2024-02-15", "2024-03-01", "2024-03-10")),
#'   score  = c(-2, -1, 0, 1, 2, 1)
#' )
#' temporal <- ac_temporal(df, date_col = "data", value_col = "score")
#' ac_plot_temporal(temporal, ylab = "Sentimento médio")
#'
#' @seealso [ac_temporal()]
#' @concept visualization
#' @export
ac_plot_temporal <- function(temporal_tbl, smooth = TRUE, title = NULL,
                              ylab = "Valor") {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    cli::cli_abort("O pacote {.pkg ggplot2} \u00e9 necess\u00e1rio.")
  }

  p <- ggplot2::ggplot(temporal_tbl, ggplot2::aes(x = period, y = value)) +
    ggplot2::geom_line(color = "#2C7FB8", linewidth = 0.6) +
    ggplot2::geom_point(color = "#2C7FB8", size = 2)

  if (smooth && nrow(temporal_tbl) >= 4L) {
    p <- p + ggplot2::geom_smooth(method = "loess", se = FALSE,
                                  color = "grey50", linetype = "dashed",
                                  linewidth = 0.5, formula = y ~ x)
  }

  p +
    ggplot2::labs(
      title = title,
      x     = NULL,
      y     = ylab,
      caption = "acR \u2022 Welbers, Van Atteveldt & Benoit (2017)"
    ) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      plot.title    = ggplot2::element_text(face = "bold"),
      plot.caption  = ggplot2::element_text(color = "grey60", size = 8, hjust = 1),
      panel.grid.minor = ggplot2::element_blank()
    )
}
