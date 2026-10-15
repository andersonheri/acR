#' Calcular diversidade lexical (riqueza de vocabulário)
#'
#' @description
#' `ac_lexical_diversity()` mede quão variado é o vocabulário dos
#' documentos de um `ac_corpus`: uma pergunta recorrente em linguística
#' computacional (textos de falantes nativos vs. aprendizes de uma
#' língua), análise de redações escolares, estudos de estilo autoral, ou
#' comparação de roteiros/transcrições por gênero ou locutor.
#'
#' Calcula três métricas, cada uma respondendo à mesma pergunta de forma
#' diferente: e cada uma com um ponto fraco diferente:
#'
#' * **TTR** (*Type-Token Ratio*): proporção simples `tipos / tokens`.
#'   Fácil de entender, mas extremamente sensível ao tamanho do texto:
#'   textos mais longos quase sempre têm TTR menor, então **não compare
#'   TTR entre documentos de tamanhos muito diferentes**.
#' * **C de Herdan** (Herdan, 1960): `log(tipos) / log(tokens)`. Mais
#'   estável que TTR frente a variação de tamanho, mas ainda não é
#'   totalmente independente do comprimento do texto.
#' * **MTLD** (*Measure of Textual Lexical Diversity*; McCarthy & Jarvis,
#'   2010): percorre o texto token a token acumulando um "fator" sempre
#'   que a TTR local cai abaixo de 0,72, e usa a média de fatores nos
#'   sentidos direto e reverso. É a métrica recomendada quando os
#'   documentos comparados têm tamanhos desiguais.
#'
#' @param corpus Objeto `ac_corpus`.
#' @param by Coluna(s) de agrupamento para agregar a diversidade lexical
#'   além do documento (ex.: `"autor"`, `"genero"`). Padrão: `NULL` (uma
#'   linha por documento).
#' @param case_sensitive Lógico. Se `FALSE` (padrão), trata `"Casa"` e
#'   `"casa"` como o mesmo tipo lexical.
#'
#' @return Tibble com colunas:
#'   * `doc_id` (ou as colunas de `by`, se informado);
#'   * `n_tokens`, `n_types`: contagens de tokens e tipos (palavras
#'     únicas);
#'   * `ttr`, `herdan_c`, `mtld`: as três métricas descritas acima.
#'
#' @references
#' Herdan, G. (1960). *Type-Token Mathematics: A Textbook of Mathematical
#' Linguistics*. Mouton.
#'
#' McCarthy, P. M.; Jarvis, S. (2010). MTLD, vocd-D, and HD-D: A
#' validation study of sophisticated approaches to lexical diversity
#' assessment. *Behavior Research Methods*, 42(2), 381-392.
#'
#' @examples
#' # Transcricoes de dois narradores com estilos de vocabulário distintos
#' df <- data.frame(
#'   id = paste0("t", 1:4),
#'   texto = c(
#'     "o gato subiu no muro e desceu depois correu e subiu de novo",
#'     paste(
#'       "o felino ascendeu ao parapeito, permaneceu imovel por instantes,",
#'       "descendeu com cautela e retornou ao ponto de partida original"
#'     ),
#'     "ela correu muito rápido e muito rápido e muito rápido ainda",
#'     paste(
#'       "a atleta acelerou vertiginosamente, superando marcas anteriores",
#'       "com uma performance notável e consistente ao longo do percurso"
#'     )
#'   ),
#'   narrador = c("simples", "rebuscado", "simples", "rebuscado"),
#'   stringsAsFactors = FALSE
#' )
#' corpus <- ac_corpus(df, text = texto, docid = id, meta = narrador)
#'
#' ac_lexical_diversity(corpus)
#'
#' # Comparar riqueza de vocabulário entre os dois estilos narrativos
#' ac_lexical_diversity(corpus, by = "narrador")
#'
#' @seealso [ac_readability()]
#' @concept quantitative
#' @export
ac_lexical_diversity <- function(corpus, by = NULL, case_sensitive = FALSE) {
  if (!is_ac_corpus(corpus)) {
    cli::cli_abort("{.arg corpus} deve ser um {.cls ac_corpus}.")
  }
  if (!requireNamespace("dplyr", quietly = TRUE)) {
    cli::cli_abort("O pacote {.pkg dplyr} \u00e9 necess\u00e1rio.")
  }

  tokens_tbl <- ac_tokenize(corpus, drop_punct = TRUE)
  if (!case_sensitive) {
    tokens_tbl$token <- tolower(tokens_tbl$token)
  }

  if (is.null(by)) {
    out <- tokens_tbl |>
      dplyr::group_by(doc_id) |>
      dplyr::summarise(
        n_tokens = dplyr::n(),
        n_types  = dplyr::n_distinct(token),
        ttr      = n_types / n_tokens,
        herdan_c = ifelse(n_tokens > 1, log(n_types) / log(n_tokens), NA_real_),
        mtld     = .ac_mtld(token),
        .groups  = "drop"
      )
    # garantir uma linha por documento do corpus, mesmo os sem tokens
    todos <- tibble::tibble(doc_id = corpus$doc_id)
    out <- dplyr::left_join(todos, out, by = "doc_id")
    return(out)
  }

  if (!all(by %in% names(corpus))) {
    cli::cli_abort(c(
      "{.arg by} cont\u00e9m nomes que n\u00e3o existem em {.arg corpus}.",
      "x" = "Nomes ausentes: {.val {setdiff(by, names(corpus))}}"
    ))
  }

  meta <- tibble::as_tibble(corpus)[, c("doc_id", by), drop = FALSE]
  tokens_tbl |>
    dplyr::left_join(meta, by = "doc_id") |>
    dplyr::group_by(dplyr::across(dplyr::all_of(by))) |>
    dplyr::summarise(
      n_tokens = dplyr::n(),
      n_types  = dplyr::n_distinct(token),
      ttr      = n_types / n_tokens,
      herdan_c = ifelse(n_tokens > 1, log(n_types) / log(n_tokens), NA_real_),
      mtld     = .ac_mtld(token),
      .groups  = "drop"
    )
}


#' @keywords internal
#' @noRd
# Uma passada do algoritmo MTLD (McCarthy & Jarvis, 2010): acumula
# "fatores" completos sempre que a TTR local cai para <= threshold,
# e soma um fator parcial com o residuo final.
.ac_mtld_pass <- function(tokens, threshold = 0.72) {
  n <- length(tokens)
  if (n == 0L) return(0)

  factors <- 0
  seen    <- character(0)
  start   <- 1L

  for (i in seq_len(n)) {
    seen <- union(seen, tokens[i])
    ttr  <- length(seen) / (i - start + 1L)
    if (ttr <= threshold) {
      factors <- factors + 1
      seen  <- character(0)
      start <- i + 1L
    }
  }

  resto <- n - start + 1L
  if (resto > 0L) {
    seen_resto <- unique(tokens[start:n])
    ttr_resto  <- length(seen_resto) / resto
    factors <- factors + (1 - ttr_resto) / (1 - threshold)
  }

  if (factors == 0) return(n)
  n / factors
}


#' @keywords internal
#' @noRd
.ac_mtld <- function(tokens) {
  if (length(tokens) < 2L) return(NA_real_)
  fwd <- .ac_mtld_pass(tokens)
  bwd <- .ac_mtld_pass(rev(tokens))
  mean(c(fwd, bwd))
}


#' Visualizar diversidade lexical por grupo
#'
#' @description
#' `ac_plot_lexical_diversity()` compara MTLD (ou outra métrica de
#' [ac_lexical_diversity()]) entre grupos.
#'
#' @param diversity_tbl Tibble retornado por `ac_lexical_diversity(corpus,
#'   by = NULL)` com uma coluna de grupo adicional já presente, ou por
#'   `ac_lexical_diversity(corpus, by = ...)`.
#' @param group_col Nome da coluna de agrupamento no eixo X.
#' @param metric Métrica a visualizar: `"mtld"` (padrão), `"ttr"` ou
#'   `"herdan_c"`.
#' @param type Tipo de gráfico: `"box"` (padrão) ou `"bar"`.
#' @param title Título do gráfico. Padrão: `NULL`.
#'
#' @return Objeto `ggplot`.
#'
#' @examples
#' df <- data.frame(
#'   id = paste0("t", 1:4),
#'   texto = c(
#'     "o gato subiu no muro e desceu depois correu e subiu de novo",
#'     "o felino ascendeu ao parapeito e descendeu com cautela depois",
#'     "ela correu muito rápido e muito rápido e muito rápido ainda",
#'     "a atleta acelerou vertiginosamente superando marcas anteriores"
#'   ),
#'   narrador = c("simples", "rebuscado", "simples", "rebuscado"),
#'   stringsAsFactors = FALSE
#' )
#' corpus <- ac_corpus(df, text = texto, docid = id, meta = narrador)
#' div <- ac_lexical_diversity(corpus)
#' div$narrador <- corpus$narrador
#' ac_plot_lexical_diversity(div, group_col = "narrador")
#'
#' @seealso [ac_lexical_diversity()]
#' @concept visualization
#' @export
ac_plot_lexical_diversity <- function(diversity_tbl,
                                       group_col = NULL,
                                       metric = c("mtld", "ttr", "herdan_c"),
                                       type = c("box", "bar"),
                                       title = NULL) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    cli::cli_abort("O pacote {.pkg ggplot2} \u00e9 necess\u00e1rio.")
  }
  metric <- match.arg(metric)
  type   <- match.arg(type)

  if (is.null(group_col) || !group_col %in% names(diversity_tbl)) {
    cli::cli_abort("{.arg group_col} deve ser uma coluna existente em {.arg diversity_tbl}.")
  }

  rotulo <- c(mtld = "MTLD", ttr = "TTR", herdan_c = "C de Herdan")[[metric]]

  p <- ggplot2::ggplot(
    diversity_tbl,
    ggplot2::aes(x = .data[[group_col]], y = .data[[metric]])
  )

  p <- if (type == "box") {
    p + ggplot2::geom_boxplot(fill = "#2C7FB8", alpha = 0.6, outlier.alpha = 0.4)
  } else {
    p + ggplot2::geom_col(fill = "#2C7FB8")
  }

  p +
    ggplot2::labs(
      title    = title,
      subtitle = paste0("Diversidade lexical (", rotulo, ") por grupo"),
      x        = NULL,
      y        = rotulo,
      caption  = "acR \u2022 Herdan (1960); McCarthy & Jarvis (2010)"
    ) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      plot.title    = ggplot2::element_text(face = "bold"),
      plot.subtitle = ggplot2::element_text(color = "grey40", size = 9),
      plot.caption  = ggplot2::element_text(color = "grey60", size = 8, hjust = 1),
      panel.grid.minor = ggplot2::element_blank()
    )
}
