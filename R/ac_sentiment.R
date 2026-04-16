#' Análise de sentimento com OpLexicon
#'
#' @description
#' `ac_sentiment()` calcula a polaridade de sentimento dos documentos de um
#' `ac_corpus` usando o OpLexicon (Souza & Vieira, 2012), retornando
#' pontuações por documento e, opcionalmente, por grupo ou janela temporal.
#'
#' @param corpus Objeto `ac_corpus`.
#' @param by Coluna(s) de agrupamento para agregar o sentimento além do
#'   documento (ex: `"partido"`, `"data"`). Padrão: `NULL` (por documento).
#' @param lexicon Léxico a usar. Atualmente apenas `"oplexicon"` (padrão).
#' @param method Método de agregação por documento:
#'   * `"sum"` (padrão): soma das polaridades.
#'   * `"mean"`: média das polaridades.
#'   * `"ratio"`: razão entre positivos e negativos.
#' @param ... Ignorado.
#'
#' @return Tibble com colunas:
#'   * `doc_id`: identificador do documento;
#'   * Colunas de metadado (se `by` especificado);
#'   * `n_pos`: número de tokens positivos;
#'   * `n_neg`: número de tokens negativos;
#'   * `n_neu`: número de tokens neutros;
#'   * `score`: pontuação de sentimento (método escolhido);
#'   * `sentiment`: classificação (`"positivo"`, `"negativo"`, `"neutro"`).
#'
#' @references
#' Souza, M.; Vieira, R. (2012). Sentiment Analysis on Twitter Data for
#' Portuguese Language. *PROPOR*.
#'
#' Souza, M.; Vieira, R.; Busetti, D.; Chishman, R.; Alves, I. M. (2011).
#' Construction of a Portuguese Opinion Lexicon from multiple resources.
#' *STIL/SBC*.
#'
#' @examples
#' df <- data.frame(
#'   id = c("a", "b", "c"),
#'   texto = c(
#'     "governo excelente otimo resultado positivo",
#'     "pessima gestao corrupta fracasso terrivel",
#'     "aprovada proposta reuniao assembleia"
#'   )
#' )
#' corpus <- ac_corpus(df, text = texto, docid = id)
#' ac_sentiment(corpus)
#'
#' @seealso [ac_plot_sentiment()]
#' @concept quantitative
#' @export
ac_sentiment <- function(corpus,
                          by      = NULL,
                          lexicon = c("oplexicon"),
                          method  = c("sum", "mean", "ratio"),
                          ...) {

  if (!is_ac_corpus(corpus)) {
    cli::cli_abort("{.arg corpus} deve ser um {.cls ac_corpus}.")
  }

  lexicon <- match.arg(lexicon)
  method  <- match.arg(method)

  # Carregar léxico
  lex <- .ac_load_lexicon(lexicon)

  # Tokenizar
  tokens_tbl <- corpus |>
    ac_clean(lower = TRUE, remove_punct = TRUE) |>
    ac_tokenize()

  # Join com léxico
  scored <- tokens_tbl |>
    dplyr::left_join(lex, by = c("token" = "termo")) |>
    dplyr::mutate(
      polaridade = dplyr::coalesce(polaridade, 0L)
    )

  # Agregar por documento
  by_cols <- c("doc_id")
  if (!is.null(by)) {
    meta <- corpus |>
      tibble::as_tibble() |>
      dplyr::select("doc_id", dplyr::all_of(by))

    scored <- scored |>
      dplyr::left_join(meta, by = "doc_id")

    by_cols <- c("doc_id", by)
  }

  result <- scored |>
    dplyr::group_by(dplyr::across(dplyr::all_of(by_cols))) |>
    dplyr::summarise(
      n_pos = sum(polaridade > 0L,  na.rm = TRUE),
      n_neg = sum(polaridade < 0L,  na.rm = TRUE),
      n_neu = sum(polaridade == 0L, na.rm = TRUE),
      score = switch(method,
        "sum"   = sum(polaridade, na.rm = TRUE),
        "mean"  = mean(polaridade, na.rm = TRUE),
        "ratio" = {
          p <- sum(polaridade > 0L,  na.rm = TRUE)
          n <- sum(polaridade < 0L,  na.rm = TRUE)
          if ((p + n) == 0L) 0 else (p - n) / (p + n)
        }
      ),
      .groups = "drop"
    ) |>
    dplyr::mutate(
      sentiment = dplyr::case_when(
        score > 0  ~ "positivo",
        score < 0  ~ "negativo",
        TRUE       ~ "neutro"
      )
    )

  result
}


#' @keywords internal
#' @noRd
.ac_load_lexicon <- function(lexicon = "oplexicon") {
  if (lexicon == "oplexicon") {
    url <- paste0(
      "https://raw.githubusercontent.com/marlovss/OpLexicon/",
      "main/OpLexicon.csv"
    )

    # Tentar cache local primeiro
    cache_dir  <- tools::R_user_dir("acR", "data")
    cache_file <- file.path(cache_dir, "oplexicon.rds")

    if (file.exists(cache_file)) {
      return(readRDS(cache_file))
    }

    cli::cli_inform("Baixando OpLexicon (primeira execu\u00e7\u00e3o \u2014 ser\u00e1 cacheado)...")

    lex <- tryCatch(
      utils::read.csv(
        url,
        header    = FALSE,
        col.names = c("termo", "pos", "polaridade"),
        encoding  = "UTF-8",
        stringsAsFactors = FALSE
      ),
      error = function(e) {
        cli::cli_abort(c(
          "N\u00e3o foi poss\u00edvel baixar o OpLexicon.",
          "i" = "Verifique a conex\u00e3o com a internet.",
          "x" = conditionMessage(e)
        ))
      }
    )

    lex$polaridade <- as.integer(lex$polaridade)

    # Salvar cache
    dir.create(cache_dir, showWarnings = FALSE, recursive = TRUE)
    saveRDS(lex, cache_file)

    return(tibble::as_tibble(lex))
  }

  cli::cli_abort("L\u00e9xico {.val {lexicon}} n\u00e3o suportado.")
}


#' Visualizar sentimento ao longo dos documentos
#'
#' @description
#' `ac_plot_sentiment()` gera visualizações de sentimento: barras por
#' documento, linha temporal, ou distribuição de scores.
#'
#' @param sentiment_tbl Tibble retornado por [ac_sentiment()].
#' @param type Tipo de visualização: `"bar"` (padrão), `"line"`, `"density"`.
#' @param x_col Coluna do eixo X. Padrão: `"doc_id"`. Pode ser
#'   uma coluna de data para `type = "line"`.
#' @param fill_col Coluna para preenchimento/cor. Padrão: `"sentiment"`.
#' @param title Título do gráfico. Padrão: `NULL`.
#' @param ... Ignorado.
#'
#' @return Objeto `ggplot`.
#'
#' @examples
#' df <- data.frame(
#'   id = c("a", "b", "c", "d"),
#'   texto = c(
#'     "excelente otimo positivo bom",
#'     "pessimo terrivel negativo ruim",
#'     "aprovada proposta reuniao",
#'     "bom resultado positivo otimo"
#'   )
#' )
#' corpus <- ac_corpus(df, text = texto, docid = id)
#' sent <- ac_sentiment(corpus)
#' ac_plot_sentiment(sent)
#'
#' @seealso [ac_sentiment()]
#' @concept visualization
#' @export
ac_plot_sentiment <- function(sentiment_tbl,
                               type     = c("bar", "line", "density"),
                               x_col    = "doc_id",
                               fill_col = "sentiment",
                               title    = NULL,
                               ...) {

  type <- match.arg(type)

  cores_sent <- c(
    "positivo" = "#009E73",
    "negativo" = "#D55E00",
    "neutro"   = "grey70"
  )

  if (type == "bar") {
    p <- ggplot2::ggplot(
      sentiment_tbl,
      ggplot2::aes(
        x    = stats::reorder(.data[[x_col]], score),
        y    = score,
        fill = .data[[fill_col]]
      )
    ) +
      ggplot2::geom_col(alpha = 0.85) +
      ggplot2::geom_hline(yintercept = 0, linewidth = 0.4, color = "grey40") +
      ggplot2::coord_flip() +
      ggplot2::scale_fill_manual(
        values = cores_sent,
        name   = "Sentimento"
      ) +
      ggplot2::labs(
        title    = title,
        subtitle = "Pontua\u00e7\u00e3o de sentimento por documento",
        x        = NULL,
        y        = "Score",
        caption  = "acR \u2022 OpLexicon (Souza & Vieira, 2012)"
      )

  } else if (type == "line") {
    p <- ggplot2::ggplot(
      sentiment_tbl,
      ggplot2::aes(x = .data[[x_col]], y = score,
                   color = score > 0, group = 1)
    ) +
      ggplot2::geom_line(linewidth = 0.8) +
      ggplot2::geom_point(
        ggplot2::aes(color = .data[[fill_col]]),
        size = 2.5
      ) +
      ggplot2::geom_hline(yintercept = 0, linewidth = 0.4,
                          linetype = "dashed", color = "grey50") +
      ggplot2::scale_color_manual(
        values = cores_sent,
        name   = "Sentimento"
      ) +
      ggplot2::labs(
        title    = title,
        subtitle = "Evolu\u00e7\u00e3o do sentimento",
        x        = NULL,
        y        = "Score",
        caption  = "acR \u2022 OpLexicon (Souza & Vieira, 2012)"
      )

  } else {  # density
    p <- ggplot2::ggplot(
      sentiment_tbl,
      ggplot2::aes(x = score, fill = .data[[fill_col]])
    ) +
      ggplot2::geom_density(alpha = 0.6) +
      ggplot2::scale_fill_manual(values = cores_sent, name = "Sentimento") +
      ggplot2::geom_vline(xintercept = 0, linewidth = 0.4,
                          linetype = "dashed", color = "grey40") +
      ggplot2::labs(
        title    = title,
        subtitle = "Distribui\u00e7\u00e3o dos scores de sentimento",
        x        = "Score",
        y        = "Densidade",
        caption  = "acR \u2022 OpLexicon (Souza & Vieira, 2012)"
      )
  }

  p +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      plot.title    = ggplot2::element_text(face = "bold"),
      plot.subtitle = ggplot2::element_text(color = "grey40", size = 9),
      plot.caption  = ggplot2::element_text(color = "grey60", size = 8,
                                            hjust = 1),
      panel.grid.minor = ggplot2::element_blank(),
      legend.position  = "bottom"
    )
}
