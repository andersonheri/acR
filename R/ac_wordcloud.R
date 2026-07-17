#' Criar nuvem de palavras
#'
#' @description
#' `ac_wordcloud()` cria uma nuvem de palavras a partir de uma tabela de
#' frequências, tipicamente gerada por [`ac_count()`].
#'
#' Por padrão prefere `ggwordcloud` (retorna `ggplot`, layout mais
#' agradável, tipografia melhor); cai para `wordcloud` clássico se
#' o primeiro não estiver instalado.
#'
#' @param x Um `data.frame` ou tibble contendo, no mínimo, as colunas
#'   `token` e `n`.
#' @param max_words Número máximo de palavras a desenhar. Padrão: `100`.
#' @param min_n Frequência mínima para incluir um termo. Padrão: `1`.
#' @param colors Vetor de cores usado no gráfico. Padrão: paleta
#'   [ac_palette()].
#' @param backend Motor a usar: `"auto"` (padrão, prefere
#'   `ggwordcloud`), `"ggwordcloud"` ou `"wordcloud"`.
#' @param title Título opcional (apenas em modo `ggwordcloud`).
#' @param ... Argumentos adicionais encaminhados para o motor escolhido
#'   (`ggwordcloud::geom_text_wordcloud` ou `wordcloud::wordcloud`).
#'
#' @return Um objeto `ggplot` (backend `ggwordcloud`) ou, invisivelmente,
#'   o `data.frame` filtrado (backend `wordcloud`).
#'
#' @examples
#' # Corpus pequeno para demonstrar
#' df <- data.frame(
#'   id    = paste0("d", 1:8),
#'   texto = c(
#'     "reforma tributaria simplifica sistema empresas",
#'     "reforma reduz distorcoes fiscais brasileiras",
#'     "sistema tributario complexo prejudica empresas",
#'     "reforma modernizacao arrecadacao federal",
#'     "IVA substitui impostos indiretos federais",
#'     "reforma tributaria arrecadacao IVA aliquotas",
#'     "simplificacao impostos aliquotas empresas",
#'     "reforma federal moderniza sistema tributario"
#'   ),
#'   stringsAsFactors = FALSE
#' )
#' corp <- ac_corpus(df, text = texto, docid = id) |>
#'   ac_clean(remove_stopwords = "pt")
#' freq <- ac_count(corp)
#'
#' # Motor ggplot moderno (recomendado)
#' if (requireNamespace("ggwordcloud", quietly = TRUE)) {
#'   ac_wordcloud(freq, max_words = 30, title = "Termos frequentes")
#' }
#'
#' # Motor classico (fallback)
#' if (requireNamespace("wordcloud", quietly = TRUE)) {
#'   ac_wordcloud(freq, max_words = 30, backend = "wordcloud")
#' }
#'
#' @seealso [ac_count()], [ac_top_terms()], [ac_palette()]
#' @concept visualization
#' @export
ac_wordcloud <- function(
    x,
    max_words = 100,
    min_n     = 1,
    colors    = NULL,
    backend   = c("auto", "ggwordcloud", "wordcloud"),
    title     = NULL,
    ...
) {
  if (!is.data.frame(x)) {
    cli::cli_abort("{.arg x} deve ser um data.frame ou tibble.")
  }
  if (!all(c("token", "n") %in% names(x))) {
    cli::cli_abort(
      "{.arg x} deve conter, no minimo, as colunas {.field token} e {.field n}."
    )
  }

  backend <- match.arg(backend)
  if (is.null(colors)) colors <- ac_palette()

  if (!is.numeric(max_words) || length(max_words) != 1L ||
      is.na(max_words) || max_words < 1L) {
    cli::cli_abort("{.arg max_words} deve ser um inteiro >= 1.")
  }
  if (!is.numeric(min_n) || length(min_n) != 1L ||
      is.na(min_n) || min_n < 1L) {
    cli::cli_abort("{.arg min_n} deve ser um inteiro >= 1.")
  }
  max_words <- as.integer(max_words)

  df_plot <- tibble::as_tibble(x) |>
    dplyr::filter(n >= min_n) |>
    dplyr::arrange(dplyr::desc(n), token)

  if (nrow(df_plot) == 0L)
    cli::cli_abort("Nenhum termo restante apos aplicar {.arg min_n}.")
  if (nrow(df_plot) > max_words)
    df_plot <- df_plot[seq_len(max_words), , drop = FALSE]

  # Resolver backend
  use_ggwordcloud <- switch(backend,
    "ggwordcloud" = TRUE,
    "wordcloud"   = FALSE,
    "auto"        = requireNamespace("ggwordcloud", quietly = TRUE)
  )

  if (use_ggwordcloud) {
    if (!requireNamespace("ggwordcloud", quietly = TRUE)) {
      cli::cli_abort(c(
        "Pacote {.pkg ggwordcloud} necessario para backend {.val ggwordcloud}.",
        "i" = "Instale com {.code install.packages(\"ggwordcloud\")}."
      ))
    }
    if (!requireNamespace("ggplot2", quietly = TRUE)) {
      cli::cli_abort("Pacote {.pkg ggplot2} necessario.")
    }

    df_plot$color_id <- (seq_len(nrow(df_plot)) - 1L) %% length(colors) + 1L
    set.seed(42L)  # layout reproduzivel

    p <- ggplot2::ggplot(
      df_plot,
      ggplot2::aes(label = .data$token, size = .data$n,
                   color = factor(.data$color_id))
    ) +
      ggwordcloud::geom_text_wordcloud(
        rm_outside = TRUE,
        eccentricity = 0.9,
        shape = "circle",
        family = "sans",
        ...
      ) +
      ggplot2::scale_size_area(max_size = 24) +
      ggplot2::scale_color_manual(values = colors, guide = "none") +
      theme_ac() +
      ggplot2::theme(
        panel.grid = ggplot2::element_blank(),
        axis.text  = ggplot2::element_blank(),
        axis.title = ggplot2::element_blank(),
        axis.ticks = ggplot2::element_blank()
      )
    if (!is.null(title)) {
      p <- p + ggplot2::labs(title = title)
    }
    return(p)
  }

  # Fallback: wordcloud classico
  if (!requireNamespace("wordcloud", quietly = TRUE)) {
    cli::cli_abort(c(
      "Nenhum backend disponivel.",
      "i" = "Instale {.pkg ggwordcloud} (recomendado) ou {.pkg wordcloud}."
    ))
  }
  wordcloud::wordcloud(
    words        = df_plot$token,
    freq         = df_plot$n,
    scale        = c(4, 0.8),
    random.order = FALSE,
    colors       = colors,
    ...
  )
  invisible(df_plot)
}
