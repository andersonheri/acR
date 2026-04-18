#' Plotar termos mais caracteristicos por tf-idf
#'
#' @description
#' `ac_plot_tf_idf()` cria um grafico de barras com os termos mais
#' caracteristicos a partir de uma tabela com a coluna `tf_idf`, tipicamente
#' gerada por [`ac_tf_idf()`].
#'
#' A funcao usa [ggplot2][ggplot2::ggplot2] como base e pode, opcionalmente, aplicar o
#' estilo editorial do pacote `ipeaplot`.
#'
#' @param x Um `data.frame` ou [`tibble::tibble()`] contendo, no minimo,
#'   as colunas `token` e `tf_idf`.
#' @param by Vetor de nomes de colunas em `x` a serem usados como grupos
#'   de facetas. Se `NULL` (padrao), produz um unico grafico. Se nao for
#'   `NULL`, cria facetas por combinacao das colunas informadas.
#' @param n Numero de termos a exibir. Se `NULL` (padrao), usa todas as
#'   linhas de `x`. Se informado, seleciona os top `n` termos por `tf_idf`
#'   no geral ou em cada grupo definido por `by`.
#' @param style Estilo grafico. Pode ser `"default"` (padrao) ou `"ipea"`.
#'   Quando `"ipea"`, a funcao tenta aplicar `ipeaplot::theme_ipea()`.
#' @param flip Logico. Se `TRUE` (padrao), usa barras horizontais com
#'   [`ggplot2::coord_flip()`].
#'
#' @return Um objeto `ggplot`.
#'
#' @examples
#' df <- data.frame(
#'   id      = c("d1", "d2", "d3"),
#'   texto   = c(
#'     "O deputado do PT falou na CCJ.",
#'     "O deputado do PL falou novamente.",
#'     "O senador do PT falou na CCJ."
#'   ),
#'   partido = c("PT", "PL", "PT"),
#'   stringsAsFactors = FALSE
#' )
#'
#' corp <- ac_corpus(df, text = texto, docid = id, meta = partido)
#'
#' freq <- ac_count(corp)
#' tfidf <- ac_tf_idf(freq)
#' ac_plot_tf_idf(tfidf, n = 10)
#'
#' freq_by <- ac_count(corp, by = "partido")
#' tfidf_by <- ac_tf_idf(freq_by, by = "partido")
#' ac_plot_tf_idf(tfidf_by, by = "partido", n = 5)
#'
#' @seealso [ac_count()], [ac_tf_idf()], [ac_top_terms()]
#' @concept corpus
#' @export
ac_plot_tf_idf <- function(
    x,
    by = NULL,
    n = NULL,
    style = c("default", "ipea"),
    flip = TRUE
) {
  if (!is.data.frame(x)) {
    cli::cli_abort("{.arg x} deve ser um data.frame ou tibble.")
  }
  
  if (!all(c("token", "tf_idf") %in% names(x))) {
    cli::cli_abort(
      "{.arg x} deve conter, no minimo, as colunas {.field token} e {.field tf_idf}."
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
  
  if (!is.null(by)) {
    if (!is.character(by)) {
      cli::cli_abort("{.arg by} deve ser um vetor de nomes de colunas (character).")
    }
    by <- unique(by)
    
    missing_by <- setdiff(by, names(x))
    if (length(missing_by) > 0L) {
      cli::cli_abort(c(
        "{.arg by} contem nomes que nao existem em {.arg x}.",
        "x" = "Nomes ausentes: {.val {missing_by}}"
      ))
    }
  }
  
  if (!is.null(n)) {
    if (!is.numeric(n) || length(n) != 1L || is.na(n) || n < 1L) {
      cli::cli_abort("{.arg n} deve ser um inteiro maior ou igual a 1.")
    }
    n <- as.integer(n)
    
    if (is.null(by)) {
      x <- dplyr::slice_max(x, order_by = tf_idf, n = n, with_ties = TRUE)
    } else {
      x <- x |>
        dplyr::group_by(dplyr::across(dplyr::all_of(by))) |>
        dplyr::slice_max(order_by = tf_idf, n = n, with_ties = TRUE) |>
        dplyr::ungroup()
    }
  }
  
  df_plot <- tibble::as_tibble(x)
  
  if (is.null(by)) {
    df_plot <- df_plot |>
      dplyr::arrange(dplyr::desc(tf_idf), token) |>
      dplyr::mutate(token = factor(token, levels = unique(token)))
  } else {
    facet_col <- "__facet_group__"
    df_plot[[facet_col]] <- do.call(paste, c(df_plot[by], sep = " | "))
    
    df_plot <- df_plot |>
      dplyr::group_by(.data[[facet_col]]) |>
      dplyr::arrange(dplyr::desc(tf_idf), token, .by_group = TRUE) |>
      dplyr::mutate(token = factor(token, levels = unique(token))) |>
      dplyr::ungroup()
  }
  
  p <- ggplot2::ggplot(
    df_plot,
    ggplot2::aes(x = token, y = tf_idf)
  ) +
    ggplot2::geom_col(fill = "#2C7FB8") +
    ggplot2::labs(
      x = NULL,
      y = "tf-idf"
    )
  
  if (!is.null(by)) {
    p <- p + ggplot2::facet_wrap(ggplot2::vars(.data[[facet_col]]), scales = "free_y")
  }
  
  if (flip) {
    p <- p + ggplot2::coord_flip()
  }
  
  if (style == "default") {
    p <- p +
      ggplot2::theme_minimal(base_size = 12) +
      ggplot2::theme(
        panel.grid.minor = ggplot2::element_blank(),
        axis.text.y = ggplot2::element_text(size = 10),
        strip.text = ggplot2::element_text(face = "bold")
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
