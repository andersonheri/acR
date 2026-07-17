#' Calcular tf-idf para termos em documentos ou grupos
#'
#' @description
#' `ac_tf_idf()` calcula a frequencia de termos (`tf`), a frequencia
#' inversa de documentos (`idf`) e o produto `tf_idf` a partir de uma
#' tabela de frequencias de termos (tipicamente o resultado de
#' [`ac_count()`]).
#'
#' A funcao segue a mesma logica de [`tidytext::bind_tf_idf()`], mas
#' adaptada para o fluxo de trabalho do pacote:
#' - sem grupos (`by = NULL`): cada `doc_id` e tratado como um documento;
#' - com grupos (`by = c("partido", ...)`): cada combinacao de
#'   metadados e tratada como um "documento" no calculo de `idf`.
#'
#' @param x Um `data.frame` ou [`tibble::tibble()`] contendo, no minimo,
#'   as colunas `token` e `n`. Em geral, o resultado de [`ac_count()`].
#' @param by Vetor de nomes de colunas em `x` que identificam
#'   documentos ou grupos. Se `NULL` (padrao), usa `doc_id` (que deve
#'   existir em `x`). Se nao for `NULL`, cada combinacao de `by` e
#'   tratada como um documento no calculo de `idf`.
#'
#' @return Um [`tibble::tibble()`] com as colunas originais de `x` mais
#'   tres colunas numeric as:
#'   - `tf`: frequencia do termo no documento/grupo;
#'   - `idf`: frequencia inversa de documentos;
#'   - `tf_idf`: produto `tf * idf`.
#'
#' @details
#' A definicao de `tf`, `idf` e `tf_idf` segue a literatura padrao de
#' tf-idf em mineracao de texto:
#' - `tf` e a frequencia relativa do termo no documento;
#' - `idf` e log(N / df), em que N e o numero de documentos e df e o
#'   numero de documentos que contem o termo;
#' - `tf_idf` e o produto `tf * idf`.
#'
#' A tabela de entrada deve ter exatamente uma linha por combinacao de
#' documento/grupo e termo (isto e, uma linha por termo-em-documento).
#'
#' @examples
#' # Corpus com discursos sobre tres agendas distintas.
#' # TF-IDF vai destacar o vocabulario proprio de cada texto,
#' # nao os termos comuns a todos (que a frequencia bruta mostraria).
#' df <- data.frame(
#'   id    = paste0("d", 1:6),
#'   texto = c(
#'     "reforma tributaria simplifica sistema impostos empresas",
#'     "IVA dual substitui PIS COFINS ICMS federal",
#'     "programa habitacional amplia recursos moradia popular urbana",
#'     "deficit habitacional afeta familias baixa renda cidades",
#'     "educacao basica recebe recursos Fundeb Congresso",
#'     "alfabetizacao idade certa meta Plano Nacional Educacao"
#'   ),
#'   tema  = rep(c("tributario", "habitacao", "educacao"), each = 2),
#'   stringsAsFactors = FALSE
#' )
#'
#' corp <- ac_corpus(df, text = texto, docid = id)
#'
#' # TF-IDF por documento
#' freq  <- ac_count(corp)
#' tfidf <- ac_tf_idf(freq)
#' head(tfidf)
#'
#' # TF-IDF por tema (cada tema tratado como "documento agregado")
#' freq_by  <- ac_count(corp, by = "tema")
#' tfidf_by <- ac_tf_idf(freq_by, by = "tema")
#' head(tfidf_by)
#'
#' @seealso [ac_count()], [ac_top_terms()], `tidytext::bind_tf_idf()`
#' @concept corpus
#' @export
ac_tf_idf <- function(x, by = NULL) {
  if (!is.data.frame(x)) {
    cli::cli_abort("{.arg x} deve ser um data.frame ou tibble.")
  }
  
  if (!all(c("token", "n") %in% names(x))) {
    cli::cli_abort(
      "{.arg x} deve conter, no minimo, as colunas {.field token} e {.field n}."
    )
  }
  
  if (!requireNamespace("dplyr", quietly = TRUE)) {
    cli::cli_abort(c(
      "O pacote {.pkg dplyr} e necessario.",
      "i" = "Instale com {.code install.packages(\"dplyr\")}."
    ))
  }
  
  if (is.null(by)) {
    if (!"doc_id" %in% names(x)) {
      cli::cli_abort(
        c(
          "{.arg by} e NULL, mas {.arg x} nao possui coluna {.field doc_id}.",
          "i" = "Use {.arg by} para indicar as colunas que identificam documentos."
        )
      )
    }
    by <- "doc_id"
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
  }
  
  # total de tokens por documento/grupo
  totals <- x |>
    dplyr::group_by(dplyr::across(dplyr::all_of(by))) |>
    dplyr::summarise(total = sum(n), .groups = "drop")
  
  # numero de documentos/grupos em que cada termo aparece (df)
  df_term <- x |>
    dplyr::group_by(token) |>
    dplyr::summarise(df = dplyr::n_distinct(dplyr::across(dplyr::all_of(by))), .groups = "drop")
  
  # numero total de documentos/grupos (N)
  N <- x |>
    dplyr::distinct(dplyr::across(dplyr::all_of(by))) |>
    nrow()
  
  # juntar totais aos dados
  out <- x |>
    dplyr::left_join(totals, by = by)
  
  # calcular tf, idf, tf-idf
  out <- out |>
    dplyr::left_join(df_term, by = "token") |>
    dplyr::mutate(
      tf    = n / total,
      idf   = log(N / df),
      tf_idf = tf * idf
    ) |>
    dplyr::select(-total, -df)
  
  out
}
