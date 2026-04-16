#' Calcular co-ocorrências de termos
#'
#' @description
#' `ac_cooccurrence()` calcula pares de termos que co-ocorrem dentro de
#' janelas deslizantes ou dentro do mesmo documento, retornando frequências
#' e medidas de associação (PMI, Dice).
#'
#' @param corpus Objeto `ac_corpus` ou tibble com colunas `doc_id` e `token`
#'   (saída de [ac_tokenize()]).
#' @param window Tamanho da janela deslizante (número de tokens de cada lado).
#'   Padrão: `5`. Ignorado se `unit = "document"`.
#' @param unit Unidade de co-ocorrência: `"window"` (padrão) ou `"document"`.
#' @param measure Medidas de associação a calcular. Um ou mais de:
#'   `"count"` (frequência conjunta), `"pmi"` (pointwise mutual information),
#'   `"dice"` (coeficiente Dice). Padrão: `c("count", "pmi")`.
#' @param min_count Frequência mínima de co-ocorrência para incluir o par.
#'   Padrão: `2`.
#' @param ... Ignorado.
#'
#' @return Tibble com colunas:
#'   * `word1`, `word2`: par de termos (ordenado alfabeticamente);
#'   * `cooc`: frequência de co-ocorrência;
#'   * `pmi` (se solicitado): pointwise mutual information;
#'   * `dice` (se solicitado): coeficiente Dice.
#'
#' @examples
#' df <- data.frame(
#'   id = c("d1", "d2", "d3"),
#'   texto = c(
#'     "democracia participacao cidadania",
#'     "participacao politica democracia",
#'     "cidadania direitos participacao"
#'   )
#' )
#' corpus <- ac_corpus(df, text = texto, docid = id) |>
#'   ac_clean()
#' tokens <- ac_tokenize(corpus)
#' ac_cooccurrence(tokens, window = 3, min_count = 1)
#'
#' @seealso [ac_tokenize()], [ac_plot_cooccurrence()]
#' @concept quantitative
#' @export
ac_cooccurrence <- function(corpus,
                             window   = 5L,
                             unit     = c("window", "document"),
                             measure  = c("count", "pmi", "dice"),
                             min_count = 2L,
                             ...) {

  unit    <- match.arg(unit)
  measure <- match.arg(measure, choices = c("count", "pmi", "dice"), several.ok = TRUE)

  # Aceita ac_corpus ou tibble tokenizado
  if (is_ac_corpus(corpus)) {
    tokens_tbl <- ac_tokenize(corpus)
  } else if (is.data.frame(corpus) && all(c("doc_id", "token") %in% names(corpus))) {
    tokens_tbl <- corpus
  } else {
    cli::cli_abort(c(
      "{.arg corpus} deve ser um {.cls ac_corpus} ou tibble com colunas {.val doc_id} e {.val token}.",
      "i" = "Use {.fn ac_tokenize} para tokenizar primeiro."
    ))
  }

  if (nrow(tokens_tbl) == 0L) {
    return(.empty_cooc_tibble(measure))
  }

  # Gerar pares
  if (unit == "window") {
    pairs <- .cooc_window(tokens_tbl, window = as.integer(window))
  } else {
    pairs <- .cooc_document(tokens_tbl)
  }

  if (nrow(pairs) == 0L) {
    return(.empty_cooc_tibble(measure))
  }

  # Contar co-ocorrências
  cooc_tbl <- pairs |>
    dplyr::count(word1, word2, name = "cooc") |>
    dplyr::filter(cooc >= min_count)

  if (nrow(cooc_tbl) == 0L) {
    return(.empty_cooc_tibble(measure))
  }

  # Frequências marginais para PMI e Dice
  if (any(c("pmi", "dice") %in% measure)) {
    freq_tbl <- tokens_tbl |>
      dplyr::count(token, name = "freq") |>
      dplyr::rename(word = token)

    total_tokens <- sum(freq_tbl$freq)

    cooc_tbl <- cooc_tbl |>
      dplyr::left_join(freq_tbl |> dplyr::rename(freq1 = freq),
                       by = c("word1" = "word")) |>
      dplyr::left_join(freq_tbl |> dplyr::rename(freq2 = freq),
                       by = c("word2" = "word"))
  }

  # PMI
  if ("pmi" %in% measure) {
    cooc_tbl <- cooc_tbl |>
      dplyr::mutate(
        pmi = log2(
          (cooc / total_tokens) /
            ((freq1 / total_tokens) * (freq2 / total_tokens))
        )
      )
  }

  # Dice
  if ("dice" %in% measure) {
    cooc_tbl <- cooc_tbl |>
      dplyr::mutate(
        dice = (2 * cooc) / (freq1 + freq2)
      )
  }

  # Limpar colunas auxiliares
  cols_keep <- c("word1", "word2", "cooc",
                 if ("pmi"  %in% measure) "pmi",
                 if ("dice" %in% measure) "dice")

  cooc_tbl |>
    dplyr::select(dplyr::all_of(cols_keep)) |>
    dplyr::arrange(dplyr::desc(cooc))
}


# ============================================================
# Funções auxiliares internas
# ============================================================

#' @keywords internal
#' @noRd
.cooc_window <- function(tokens_tbl, window = 5L) {
  docs  <- unique(tokens_tbl$doc_id)
  pairs <- vector("list", length(docs))

  for (i in seq_along(docs)) {
    toks <- tokens_tbl$token[tokens_tbl$doc_id == docs[i]]
    n    <- length(toks)
    if (n < 2L) next

    rows <- vector("list", n)
    for (j in seq_len(n)) {
      lo  <- max(1L, j - window)
      hi  <- min(n,  j + window)
      ctx <- setdiff(lo:hi, j)
      if (length(ctx) == 0L) next
      w1 <- toks[j]
      w2 <- toks[ctx]
      # Ordenar par alfabeticamente para evitar (A,B) e (B,A) duplicados
      pair_min <- pmin(w1, w2)
      pair_max <- pmax(w1, w2)
      rows[[j]] <- tibble::tibble(word1 = pair_min, word2 = pair_max)
    }
    pairs[[i]] <- dplyr::bind_rows(rows)
  }

  dplyr::bind_rows(pairs)
}

#' @keywords internal
#' @noRd
.cooc_document <- function(tokens_tbl) {
  docs  <- unique(tokens_tbl$doc_id)
  pairs <- vector("list", length(docs))

  for (i in seq_along(docs)) {
    toks <- unique(tokens_tbl$token[tokens_tbl$doc_id == docs[i]])
    if (length(toks) < 2L) next
    combos <- utils::combn(sort(toks), 2L)
    pairs[[i]] <- tibble::tibble(
      word1 = combos[1L, ],
      word2 = combos[2L, ]
    )
  }

  dplyr::bind_rows(pairs)
}

#' @keywords internal
#' @noRd
.empty_cooc_tibble <- function(measure) {
  base <- tibble::tibble(word1 = character(), word2 = character(),
                         cooc  = integer())
  if ("pmi"  %in% measure) base$pmi  <- numeric()
  if ("dice" %in% measure) base$dice <- numeric()
  base
}
