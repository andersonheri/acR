#' Contar frequencias de tokens ou n-gramas em um corpus
#'
#' @description
#' `ac_count()` calcula frequencias de tokens ou n-gramas a partir de
#' um objeto [`ac_corpus()`], usando internamente [`ac_tokenize()`]
#' seguido de uma agregacao com [`dplyr::count()`].
#'
#' Pode operar em dois niveis:
#' - por documento (`by = NULL`): contagens por `doc_id` e `token`;
#' - por metadados (`by = c("partido", ...)`): contagens por
#'   variaveis de agrupamento e `token` (agregando varios documentos).
#'
#' @param corpus Objeto de classe [`ac_corpus()`].
#' @param n Tamanho do n-grama a ser tokenizado. Encaminhado para
#'   [`ac_tokenize()`]. Veja `?ac_tokenize` para detalhes.
#' @param drop_punct Logico. Se `TRUE`, remove tokens compostos apenas
#'   por pontuacao antes de calcular as frequencias (via
#'   `drop_punct = TRUE` em [`ac_tokenize()`]).
#' @param by Vetor de nomes de colunas de metadados em `corpus` a serem
#'   usados como grupos de agregacao. Se `NULL` (padrao), as contagens
#'   sao feitas por documento (`doc_id`). Se nao for `NULL`, as colunas
#'   indicadas sao usadas como grupos e `doc_id` nao entra no resultado.
#' @param sort Logico. Se `TRUE` (padrao), ordena a saida em ordem
#'   decrescente de frequencia (`n`).
#' @param ... Argumentos adicionais encaminhados para
#'   [`ac_tokenize()`] (por exemplo, `keep_empty`).
#'
#' @return Um [`tibble::tibble()`]:
#' - Se `by = NULL`: colunas `doc_id`, `token`, `n`;
#' - Se `by` nao nulo: colunas `by`, `token`, `n`.
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
#' # Frequencia de palavras (unigramas) por documento
#' ac_count(corp)
#'
#' # Frequencia de palavras por partido
#' ac_count(corp, by = "partido")
#'
#' # Frequencia de bigramas por partido, removendo apenas pontuacao
#' ac_count(corp, n = 2, drop_punct = TRUE, by = "partido")
#'
#' @seealso [ac_corpus()], [ac_clean()], [ac_tokenize()]
#' @concept corpus
#' @export
ac_count <- function(
    corpus,
    n          = 1L,
    drop_punct = FALSE,
    by         = NULL,
    sort       = TRUE,
    ...
) {
  if (!is_ac_corpus(corpus)) {
    cli::cli_abort(c(
      "{.arg corpus} deve ser um objeto {.cls ac_corpus}.",
      "i" = "Crie com {.fun ac_corpus}."
    ))
  }
  
  if (!is.null(by)) {
    if (!is.character(by)) {
      cli::cli_abort("{.arg by} deve ser um vetor de nomes de colunas (character).")
    }
    by <- unique(by)
    
    # colunas disponiveis no corpus (doc_id, text e metadados)
    cols_corpus <- names(corpus)
    missing_by  <- setdiff(by, cols_corpus)
    
    if (length(missing_by) > 0L) {
      cli::cli_abort(c(
        "{.arg by} contem nomes que nao existem em {.cls ac_corpus}.",
        "x" = "Nomes ausentes: {.val {missing_by}}"
      ))
    }
    
    # Nao faz sentido agrupar por text (texto bruto)
    if ("text" %in% by) {
      cli::cli_abort("A coluna {.field text} nao deve ser usada em {.arg by}.")
    }
  }
  
  if (!requireNamespace("dplyr", quietly = TRUE)) {
    cli::cli_abort(c(
      "O pacote {.pkg dplyr} e necessario.",
      "i" = "Instale com {.code install.packages(\"dplyr\")}."
    ))
  }
  
  tokens <- ac_tokenize(
    corpus,
    n          = n,
    drop_punct = drop_punct,
    ...
  )
  
  # Se nao ha tokens, devolver estrutura vazia adequada
  if (nrow(tokens) == 0L) {
    if (is.null(by)) {
      return(
        tibble::tibble(
          doc_id = character(0),
          token  = character(0),
          n      = integer(0)
        )
      )
    } else {
      col_list <- vector("list", length(by) + 2L)
      names(col_list) <- c(by, "token", "n")
      col_list[] <- list(character(0))
      return(tibble::as_tibble(col_list))
    }
  }
  
  if (is.null(by)) {
    # Comportamento original: contagem por documento
    out <- dplyr::count(
      tokens,
      doc_id,
      token,
      name = "n",
      sort = sort
    )
  } else {
    # Tabela de metadados: doc_id + colunas de by
    meta <- tibble::as_tibble(corpus)[, c("doc_id", by), drop = FALSE]
    
    df <- dplyr::left_join(
      tokens,
      meta,
      by   = "doc_id",
      copy = FALSE
    )
    
    # Agrupar por by + token
    out <- df |>
      dplyr::group_by(dplyr::across(dplyr::all_of(by)), token) |>
      dplyr::summarise(n = dplyr::n(), .groups = "drop")
    
    if (sort) {
      out <- dplyr::arrange(out, dplyr::desc(n))
    } else {
      out <- dplyr::arrange(out, dplyr::across(dplyr::all_of(by)), token)
    }
  }
  
  out
}
