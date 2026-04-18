#' Plotar estatisticas de keyness
#'
#' @description
#' `ac_plot_keyness()` cria um grafico de barras com as estatisticas de
#' keyness calculadas por [`ac_keyness()`], destacando os termos mais
#' caracteristicos do grupo alvo e do grupo de referencia.
#'
#' A funcao usa [ggplot2][ggplot2::ggplot2] como base e pode, opcionalmente, aplicar o
#' estilo editorial do pacote `ipeaplot`.
#'
#' @param x Um `data.frame` ou [`tibble::tibble()`] contendo, no minimo,
#'   as colunas `token`, `keyness` e `direction`.
#' @param n Numero de termos a exibir por direcao. Se `NULL` (padrao),
#'   usa todas as linhas de `x`. Se informado, seleciona os top `n`
#'   termos com `keyness` positivo e os top `n` com `keyness` negativo.
#' @param style Estilo grafico. Pode ser `"default"` (padrao) ou `"ipea"`.
#'   Quando `"ipea"`, a funcao tenta aplicar `ipeaplot::theme_ipea()`.
#' @param flip Logico. Se `TRUE` (padrao), usa barras horizontais com
#'   [`ggplot2::coord_flip()`].
#' @param show_reference Logico. Se `TRUE` (padrao), mostra termos
#'   caracteristicos do grupo alvo e do grupo de referencia. Se `FALSE`,
#'   mostra apenas os termos com `keyness` positivo.
#'
#' @return Um objeto `ggplot`.
#'
#' @examples
#' df <- data.frame(
#'   id    = c("d1", "d2", "d3", "d4"),
#'   texto = c(
#'     "A A A B",
#'     "A B",
#'     "A B B B",
#'     "B B C"
#'   ),
#'   lado  = c("Governo", "Governo", "Oposicao", "Oposicao"),
#'   stringsAsFactors = FALSE
#' )
#'
#' corp <- ac_corpus(df, text = texto, docid = id, meta = lado)
#' freq <- ac_count(corp, by = "lado")
#' key <- ac_keyness(freq, group = "lado", target = "Governo")
#'
#' ac_plot_keyness(key, n = 5)
#'
#' @seealso [ac_count()], [ac_keyness()]
#' @concept corpus
#' @export
ac_plot_keyness <- function(
    x,
    n = NULL,
    style = c("default", "ipea"),
    flip = TRUE,
    show_reference = TRUE
) {
  if (!is.data.frame(x)) {
    cli::cli_abort("{.arg x} deve ser um data.frame ou tibble.")
  }
  
  if (!all(c("token", "keyness", "direction") %in% names(x))) {
    cli::cli_abort(
      "{.arg x} deve conter, no minimo, as colunas {.field token}, {.field keyness} e {.field direction}."
    )
  }
  
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    cli::cli_abort(c(
      "O pacote {.pkg ggplot2} e necessario.",
      "i" = "Instale com {.code install.packages(\"ggplot2\")}."
    ))
  }
  
  if (!requireNamespace("dplyr", quietly = TRUE)) {
    cli::cli_abort(c(
      "O pacote {.pkg dplyr} e necessario.",
      "i" = "Instale com {.code install.packages(\"dplyr\")}."
    ))
  }
  
  style <- match.arg(style, c("default", "ipea"))
  
  df_plot <- tibble::as_tibble(x)
  
  if (!show_reference) {
    df_plot <- df_plot |>
      dplyr::filter(keyness > 0)
  }
  
  if (!is.null(n)) {
    if (!is.numeric(n) || length(n) != 1L || is.na(n) || n < 1L) {
      cli::cli_abort("{.arg n} deve ser um inteiro maior ou igual a 1.")
    }
    n <- as.integer(n)
    
    if (show_reference) {
      df_pos <- df_plot |>
        dplyr::filter(keyness > 0) |>
        dplyr::slice_max(order_by = keyness, n = n, with_ties = TRUE)
      
      df_neg <- df_plot |>
        dplyr::filter(keyness < 0) |>
        dplyr::slice_min(order_by = keyness, n = n, with_ties = TRUE)
      
      df_plot <- dplyr::bind_rows(df_pos, df_neg)
    } else {
      df_plot <- df_plot |>
        dplyr::slice_max(order_by = keyness, n = n, with_ties = TRUE)
    }
  }
  
  df_plot <- df_plot |>
    dplyr::arrange(keyness, token) |>
    dplyr::mutate(token = factor(token, levels = unique(token)))
  
  p <- ggplot2::ggplot(
    df_plot,
    ggplot2::aes(x = token, y = keyness, fill = direction)
  ) +
    ggplot2::geom_col() +
    ggplot2::labs(
      x = NULL,
      y = "Keyness",
      fill = "Direcao"
    )
  
  if (flip) {
    p <- p + ggplot2::coord_flip()
  }
  
  if (style == "default") {
    p <- p +
      ggplot2::theme_minimal(base_size = 12) +
      ggplot2::theme(
        panel.grid.minor = ggplot2::element_blank(),
        axis.text.y = ggplot2::element_text(size = 10),
        legend.position = "bottom"
      )
  }
  
  if (style == "ipea") {
    if (!requireNamespace("ipeaplot", quietly = TRUE)) {
      cli::cli_abort(c(
        "O estilo {.val ipea} requer o pacote {.pkg ipeaplot}.",
        "i" = "Instale com {.code install.packages(\"ipeaplot\")}."
      ))
    }
    
    p <- p + ipeaplot::theme_ipea()
  }
  
  p
}
