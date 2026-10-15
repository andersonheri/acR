#' Selecionar os termos mais frequentes
#'
#' @description
#' `ac_top_terms()` seleciona os `n` termos mais frequentes a partir de uma
#' tabela de frequências (tipicamente o resultado de [`ac_count()`]).
#'
#' Pode operar em dois modos:
#' - sem grupos (`by = NULL`): retorna os `n` termos mais frequentes no geral;
#' - com grupos (`by = c("partido", ...)`): retorna os `n` termos mais
#'   frequentes em cada combinacao de metadados.
#'
#' @param x Um `data.frame` ou [`tibble::tibble()`] contendo, no mínimo,
#'   as colunas `token` e `n`. Em geral, o resultado de [`ac_count()`].
#' @param n Número de termos a selecionar. Valor inteiro >= 1.
#' @param by Vetor de nomes de colunas em `x` a serem usados como grupos
#'   de agregacao. Se `NULL` (padrao), a selecao e feita no conjunto total.
#'   Se não for `NULL`, os `n` termos mais frequentes sao selecionados
#'   dentro de cada combinacao de `by`.
#' @param sort Lógico. Se `TRUE` (padrão), ordena a saída em ordem
#'   decrescente de frequência (`n`). Se `FALSE`, ordena os termos
#'   selecionados alfabeticamente (dentro de cada grupo, quando houver).
#'
#' @return Um [`tibble::tibble()`] com as colunas `token` e `n` (mais as
#'   colunas de `by`, se houver), com exatamente `n` termos (ou menos, se
#'   o vocabulário for menor) no geral ou por grupo. A frequência de cada
#'   termo é **somada** sobre os documentos (ou dentro de cada grupo), de
#'   modo que uma tabela por documento, saída padrão de [`ac_count()`],
#'   dá o total do corpus. Empates na última posição são desfeitos em
#'   ordem alfabética.
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
  
  # Soma cada termo no conjunto (ou dentro de cada grupo) antes de
  # ranquear. Sem isso, uma tabela por documento (saida padrao de
  # ac_count()) era ranqueada linha a linha: um termo presente em 3
  # documentos aparecia 3 vezes com n = 1, e nunca com n = 3.
  # Empates na ultima posicao sao desfeitos em ordem alfabetica, para
  # devolver exatamente `n` termos (com empates mantidos, um corpus
  # pequeno em que quase tudo vale 1 devolvia o vocabulario inteiro).
  n_top <- n
  if (is.null(by)) {
    out <- x |>
      dplyr::group_by(token) |>
      dplyr::summarise(n = sum(n), .groups = "drop") |>
      dplyr::arrange(dplyr::desc(n), token) |>
      utils::head(n_top)
    if (!sort) {
      out <- dplyr::arrange(out, token)
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
      dplyr::group_by(dplyr::across(dplyr::all_of(c(by, "token")))) |>
      dplyr::summarise(n = sum(n), .groups = "drop") |>
      dplyr::group_by(dplyr::across(dplyr::all_of(by))) |>
      dplyr::arrange(dplyr::desc(n), token, .by_group = TRUE) |>
      dplyr::slice_head(n = n_top) |>
      dplyr::ungroup()
    
    if (sort) {
      out <- dplyr::arrange(
        out,
        dplyr::across(dplyr::all_of(by)),
        dplyr::desc(n),
        token
      )
    } else {
      out <- dplyr::arrange(out, dplyr::across(dplyr::all_of(by)), token)
    }
  }
  
  out
}
