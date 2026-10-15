#' Validar um dicionário contra codificação humana
#'
#' @description
#' `ac_dictionary_validate()` compara a classificação por dicionário
#' (saída de [ac_dictionary()], [ac_emotion()] ou [ac_sentiment()] com
#' categorias binarizadas) contra uma codificação de referência humana,
#' categoria por categoria — a mesma lógica de validação que
#' [ac_qual_reliability()] aplica à classificação por LLM (com
#' `by_variable = TRUE`), agora para o método de dicionário.
#'
#' Nenhum dicionário deveria ser usado numa análise publicável sem essa
#' etapa (Grimmer & Stewart, 2013): um dicionário construído à mão pode
#' parecer razoável e ainda assim ter baixa precisão ou recall numa
#' categoria específica — só a comparação com uma amostra codificada por
#' humano revela isso.
#'
#' @param scored Tibble retornado por [ac_dictionary()] ou
#'   [ac_emotion()] (com colunas `doc_id` e `<categoria>_n` por
#'   categoria).
#' @param human Tibble com colunas `doc_id` e uma coluna de categoria
#'   (ver `cat_col`) — a codificação humana de referência, no mesmo
#'   formato aceito por [ac_qual_reliability()] (multilabel como string
#'   separada por `"|"`).
#' @param cat_col Nome da coluna de categoria em `human`. Padrão:
#'   `"categoria"`.
#' @param threshold Contagem mínima em `<categoria>_n` para o
#'   dicionário considerar a categoria presente no documento. Padrão:
#'   `0` (qualquer palavra da categoria presente já conta).
#'
#' @return Tibble com uma linha por categoria do dicionário e colunas
#'   `categoria`, `n`, `vp`, `fp`, `fn`, `vn`, `concordância`,
#'   `precisao`, `recall`, `f1`, `gwet_ac1`, `krippendorff_alfa` — as
#'   mesmas colunas de `attr(ac_qual_reliability(...), "by_variable")`.
#'   Denominadores indefinidos (ex.: uma categoria que nenhum dos dois
#'   lados marcou) geram `NA`, nunca `0` ou `1` artificiais.
#'
#' @references
#' Grimmer, J.; Stewart, B. M. (2013). Text as Data: The Promise and
#' Pitfalls of Automatic Content Analysis Methods for Political Texts.
#' *Political Analysis*, 21(3), 267-297.
#'
#' @examples
#' df <- data.frame(
#'   id = paste0("d", 1:4),
#'   texto = c(
#'     "a entrega atrasou muito",
#'     "o produto chegou com defeito",
#'     "cobraram duas vezes no cartao",
#'     "entrega rápida e produto perfeito"
#'   ),
#'   stringsAsFactors = FALSE
#' )
#' corpus <- ac_corpus(df, text = texto, docid = id)
#' dict <- ac_build_dictionary(
#'   entrega = c("entrega", "atrasou", "rápida"),
#'   produto = c("defeito", "perfeito")
#' )
#' scored <- ac_dictionary(corpus, dict)
#'
#' # Codificacao humana de referência (simulada para o exemplo)
#' human <- tibble::tibble(
#'   doc_id    = paste0("d", 1:4),
#'   categoria = c("entrega", "produto", NA, "entrega|produto")
#' )
#'
#' ac_dictionary_validate(scored, human)
#'
#' @seealso [ac_dictionary()], [ac_qual_reliability()]
#' @concept quantitative
#' @export
ac_dictionary_validate <- function(scored, human, cat_col = "categoria", threshold = 0) {
  if (!is.data.frame(scored) || !"doc_id" %in% names(scored)) {
    cli::cli_abort("{.arg scored} deve ser um tibble com coluna {.field doc_id}, sa\u00edda de {.fn ac_dictionary}.")
  }
  if (!is.data.frame(human) || !cat_col %in% names(human)) {
    cli::cli_abort(c(
      "{.arg human} deve ser um tibble com coluna {.val {cat_col}}.",
      "i" = "Use a sa\u00edda de {.fn ac_qual_import_human}."
    ))
  }

  cols_n <- grep("_n$", names(scored), value = TRUE)
  cols_n <- setdiff(cols_n, "total_tokens")
  if (length(cols_n) == 0L) {
    cli::cli_abort("{.arg scored} n\u00e3o tem colunas {.val <categoria>_n} -- use a sa\u00edda de {.fn ac_dictionary}.")
  }
  cat_names <- sub("_n$", "", cols_n)

  joined <- dplyr::inner_join(
    scored[, c("doc_id", cols_n), drop = FALSE],
    human[, c("doc_id", cat_col), drop = FALSE],
    by = "doc_id"
  )
  if (nrow(joined) == 0L) {
    cli::cli_abort("Nenhum documento em comum entre {.arg scored} e {.arg human}.")
  }

  human_vals <- as.character(joined[[cat_col]])
  human_sets <- strsplit(human_vals, "|", fixed = TRUE)

  linhas <- purrr::map(seq_along(cat_names), function(i) {
    cat <- cat_names[i]
    m <- as.integer(joined[[cols_n[i]]] > threshold)
    h <- as.integer(vapply(human_sets, function(s) {
      if (length(s) == 0L || all(is.na(s))) return(NA)
      cat %in% s
    }, logical(1)))

    valid <- !is.na(h)
    dplyr::bind_cols(
      tibble::tibble(categoria = cat),
      .ac_metricas_binarias(h[valid], m[valid])
    )
  })

  dplyr::bind_rows(linhas)
}
