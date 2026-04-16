#' Criar nuvem de palavras
#'
#' @description
#' `ac_wordcloud()` cria uma nuvem de palavras a partir de uma tabela de
#' frequencias, tipicamente gerada por [`ac_count()`].
#'
#' A funcao usa o pacote `wordcloud` para desenhar a nuvem e trabalha
#' com as colunas `token` e `n`.
#'
#' @param x Um `data.frame` ou [`tibble::tibble()`] contendo, no minimo,
#'   as colunas `token` e `n`.
#' @param max_words Numero maximo de palavras a desenhar. Padrao: `100`.
#' @param min_n Frequencia minima para incluir um termo. Padrao: `1`.
#' @param scale Vetor numerico de comprimento 2 indicando o intervalo de
#'   tamanhos das palavras. Padrao: `c(4, 0.8)`.
#' @param random_order Logico. Se `TRUE`, plota em ordem aleatoria.
#'   Se `FALSE` (padrao), as palavras mais frequentes tendem a aparecer
#'   mais ao centro.
#' @param colors Vetor de cores usado no grafico. Padrao:
#'   `c("#2C7FB8", "#7FCDBB", "#EDF8B1", "#253494")`.
#' @param ... Argumentos adicionais encaminhados para
#'   [`wordcloud::wordcloud()`].
#'
#' @return Invisivelmente, o `data.frame` filtrado usado para desenhar
#'   a nuvem de palavras.
#'
#' @details
#' Como `wordcloud::wordcloud()` desenha diretamente no dispositivo
#' grafico ativo, esta funcao nao retorna um objeto `ggplot`. Em vez
#' disso, produz o grafico como efeito colateral e retorna
#' invisivelmente a tabela usada no desenho.
#'
#' @examples
#' df <- data.frame(
#'   id    = c("d1", "d2", "d3"),
#'   texto = c("A A B", "B C", "A C"),
#'   stringsAsFactors = FALSE
#' )
#'
#' corp <- ac_corpus(df, text = texto, docid = id)
#' freq <- ac_count(corp)
#'
#' if (requireNamespace("wordcloud", quietly = TRUE)) {
#'   ac_wordcloud(freq, max_words = 20)
#' }
#'
#' @seealso [ac_count()], [ac_top_terms()]
#' @concept corpus
#' @export
ac_wordcloud <- function(
    x,
    max_words = 100,
    min_n = 1,
    scale = c(4, 0.8),
    random_order = FALSE,
    colors = c("#2C7FB8", "#7FCDBB", "#EDF8B1", "#253494"),
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
  
  if (!requireNamespace("wordcloud", quietly = TRUE)) {
    cli::cli_abort(c(
      "O pacote {.pkg wordcloud} e necessario.",
      "i" = "Instale com {.code install.packages(\"wordcloud\")}."
    ))
  }
  
  if (!is.numeric(max_words) || length(max_words) != 1L || is.na(max_words) || max_words < 1L) {
    cli::cli_abort("{.arg max_words} deve ser um inteiro maior ou igual a 1.")
  }
  max_words <- as.integer(max_words)
  
  if (!is.numeric(min_n) || length(min_n) != 1L || is.na(min_n) || min_n < 1L) {
    cli::cli_abort("{.arg min_n} deve ser um inteiro maior ou igual a 1.")
  }
  
  if (!is.numeric(scale) || length(scale) != 2L || any(is.na(scale))) {
    cli::cli_abort("{.arg scale} deve ser um vetor numerico de comprimento 2.")
  }
  
  df_plot <- tibble::as_tibble(x) |>
    dplyr::filter(n >= min_n) |>
    dplyr::arrange(dplyr::desc(n), token)
  
  if (nrow(df_plot) == 0L) {
    cli::cli_abort(
      "Nenhum termo restante apos aplicar o filtro de {.arg min_n}."
    )
  }
  
  if (nrow(df_plot) > max_words) {
    df_plot <- df_plot[seq_len(max_words), , drop = FALSE]
  }
  
  wordcloud::wordcloud(
    words = df_plot$token,
    freq = df_plot$n,
    scale = scale,
    random.order = random_order,
    colors = colors,
    ...
  )
  
  invisible(df_plot)
}
