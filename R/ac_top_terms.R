#' Selecionar os termos mais frequentes
#'
#' @description
#' `ac_top_terms()` seleciona os `n` termos mais frequentes a partir de uma
#' tabela de frequencias (tipicamente o resultado de [`ac_count()`]).
#'
#' Pode operar em dois modos:
#' - sem grupos (`by = NULL`): retorna os `n` termos mais frequentes no geral;
#' - com grupos (`by = c("partido", ...)`): retorna os `n` termos mais
#'   frequentes em cada combinacao de metadados.
#'
#' @param x Um `data.frame` ou [`tibble::tibble()`] contendo, no minimo,
#'   as colunas `token` e `n`. Em geral, o resultado de [`ac_count()`].
#' @param n Numero de termos a selecionar. Valor inteiro >= 1.
#' @param by Vetor de nomes de colunas em `x` a serem usados como grupos
#'   de agregacao. Se `NULL` (padrao), a selecao e feita no conjunto total.
#'   Se nao for `NULL`, os `n` termos mais frequentes sao selecionados
#'   dentro de cada combinacao de `by`.
#' @param sort Logico. Se `TRUE` (padrao), ordena a saida em ordem
#'   decrescente de frequencia (`n`). Se `FALSE`, preserva a ordem
#'   retornada pela operacao interna de selecao, apenas garantindo que
#'   os grupos (quando houver) venham juntos.
#'
#' @return Um [`tibble::tibble()`] com as mesmas colunas de `x`, mas
#'   restrito aos `n` termos mais frequentes (no geral ou por grupo).
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
#' # Top 10 termos no corpus inteiro
#' freq <- ac_count(corp)
#' ac_top_terms(freq, n = 10)
#'
#' # Top 5 termos por partido
#' freq_by <- ac_count(corp, by = "partido")
#' ac_top_terms(freq_by, n = 5, by = "partido")
#'
#' @seealso [ac_count()], [ac_tokenize()]
#' @concept corpus
#' @export
ac_top_terms <- function(x, n = 20L, by = NULL, sort = TRUE) {
  if (!is.data.frame(x)) {
    cli::cli_abort("{.arg x} deve ser um data.frame ou tibble.")
  }
  
  if (!all(c("token", "n") %in% names(x))) {
    cli::cli_abort(
      "{.arg x} deve conter, no minimo, as colunas {.field token} e {.field n}."
    )
  }
  
  if (!is.numeric(n) || length(n) != 1L || is.na(n) || n < 1L) {
    cli::cli_abort("{.arg n} deve ser um inteiro maior ou igual a 1.")
  }
  n <- as.integer(n)
  
  if (!requireNamespace("dplyr", quietly = TRUE)) {
    cli::cli_abort(c(
      "O pacote {.pkg dplyr} e necessario.",
      "i" = "Instale com {.code install.packages(\"dplyr\")}."
    ))
  }
  
  if (is.null(by)) {
    out <- dplyr::slice_max(x, order_by = n, n = n, with_ties = TRUE)
    if (sort) {
      out <- dplyr::arrange(out, dplyr::desc(n), token)
    }
  } else {
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
    
    out <- x |>
      dplyr::group_by(dplyr::across(dplyr::all_of(by))) |>
      dplyr::slice_max(order_by = n, n = n, with_ties = TRUE) |>
      dplyr::ungroup()
    
    if (sort) {
      out <- dplyr::arrange(
        out,
        dplyr::across(dplyr::all_of(by)),
        dplyr::desc(n),
        token
      )
    } else {
      out <- dplyr::arrange(out, dplyr::across(dplyr::all_of(by)))
    }
  }
  
  out
}
