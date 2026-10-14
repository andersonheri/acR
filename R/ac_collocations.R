#' Identificar colocações com medidas de associação estatística
#'
#' @description
#' `ac_collocations()` identifica pares (ou trincas) de palavras que
#' aparecem juntas com mais frequência do que o esperado pelo acaso —
#' colocações como "reforma tributária", "não recomendo" ou "atendimento
#' ao cliente" — usando medidas de associação estatística em vez de
#' frequência bruta de bigramas/trigramas.
#'
#' A diferença importa: bigramas puramente frequentes tendem a ser
#' dominados por combinações de palavras funcionais comuns ("de o",
#' "que a"), que são frequentes mas não informativas. As medidas de
#' associação penalizam esse efeito, destacando combinações que ocorrem
#' juntas mais do que a frequência individual de cada palavra sugeriria
#' — o uso típico é alimentar um dicionário customizado (ver
#' [ac_build_dictionary()]) ou simplesmente explorar expressões
#' compostas específicas de um domínio (jurídico, médico, técnico) antes
#' de uma análise de frequência ou nuvem de palavras.
#'
#' @param corpus Objeto `ac_corpus`.
#' @param n Tamanho do n-grama: `2` (padrão, bigramas) ou `3`
#'   (trigramas).
#' @param measure Medida de associação:
#'   * `"pmi"` (padrão): *Pointwise Mutual Information* (Church & Hanks,
#'     1990) — quanto mais alto, mais a coocorrência surpreende em
#'     relação ao esperado pelo acaso. Tende a favorecer pares raros.
#'   * `"ll"`: log-likelihood ratio (Dunning, 1993) — mais robusta que
#'     PMI para colocações de baixa frequência; é a medida padrão do
#'     `quanteda.textstats::textstat_collocations()`.
#'   * `"chi2"`: qui-quadrado de associação, mesma lógica de
#'     [ac_keyness()] aplicada a pares de palavras adjacentes em vez de
#'     grupos de documentos.
#' @param min_count Frequência mínima do n-grama para ser considerado.
#'   Padrão: `5`. Medidas de associação são instáveis para n-gramas
#'   muito raros.
#' @param drop_punct Lógico. Se `TRUE` (padrão), ignora n-gramas que
#'   incluem tokens de pontuação pura.
#'
#' @return Tibble ordenado por associação decrescente, com colunas:
#'   * `collocation`: o n-grama (palavras separadas por espaço);
#'   * `count`: frequência absoluta do n-grama no corpus;
#'   * `association`: valor da medida escolhida em `measure`.
#'
#' @references
#' Church, K. W.; Hanks, P. (1990). Word association norms, mutual
#' information, and lexicography. *Computational Linguistics*, 16(1),
#' 22-29.
#'
#' Dunning, T. (1993). Accurate methods for the statistics of surprise
#' and coincidence. *Computational Linguistics*, 19(1), 61-74.
#'
#' @examples
#' # Reviews de um restaurante com expressoes compostas recorrentes
#' df <- data.frame(
#'   id = paste0("r", 1:6),
#'   texto = c(
#'     "atendimento ao cliente impecavel, super recomendo o lugar",
#'     "o atendimento ao cliente deixou a desejar dessa vez",
#'     "comida boa mas atendimento ao cliente lento",
#'     "nao recomendo, atendimento ao cliente horrivel",
#'     "ambiente agradavel e atendimento ao cliente rapido",
#'     "preco justo, atendimento ao cliente cordial sempre"
#'   ),
#'   stringsAsFactors = FALSE
#' )
#' corpus <- ac_corpus(df, text = texto, docid = id)
#'
#' ac_collocations(corpus, min_count = 2)
#'
#' @seealso [ac_keyness()], [ac_count()]
#' @concept quantitative
#' @export
ac_collocations <- function(corpus,
                             n = 2L,
                             measure = c("pmi", "ll", "chi2"),
                             min_count = 5L,
                             drop_punct = TRUE) {
  if (!is_ac_corpus(corpus)) {
    cli::cli_abort("{.arg corpus} deve ser um {.cls ac_corpus}.")
  }
  measure <- match.arg(measure)
  if (!n %in% c(2L, 3L)) {
    cli::cli_abort("{.arg n} deve ser 2 (bigramas) ou 3 (trigramas).")
  }
  if (!requireNamespace("dplyr", quietly = TRUE)) {
    cli::cli_abort("O pacote {.pkg dplyr} \u00e9 necess\u00e1rio.")
  }

  unigramas <- ac_tokenize(corpus, n = 1L, drop_punct = drop_punct)
  ngramas   <- ac_tokenize(corpus, n = n,  drop_punct = drop_punct)

  if (nrow(ngramas) == 0L) {
    return(tibble::tibble(collocation = character(0), count = integer(0),
                          association = numeric(0)))
  }

  n_total <- nrow(unigramas)
  freq_unigrama <- table(unigramas$token)

  freq_ngrama <- ngramas |>
    dplyr::count(token, name = "count") |>
    dplyr::filter(count >= min_count)

  if (nrow(freq_ngrama) == 0L) {
    return(tibble::tibble(collocation = character(0), count = integer(0),
                          association = numeric(0)))
  }

  partes <- strsplit(freq_ngrama$token, " ", fixed = TRUE)
  freq_w1 <- vapply(partes, function(p) as.numeric(freq_unigrama[p[1]] %||% 0), numeric(1))
  freq_w2 <- vapply(partes, function(p) as.numeric(freq_unigrama[p[length(p)]] %||% 0), numeric(1))

  a <- freq_ngrama$count
  b <- pmax(freq_w1 - a, 0)
  c <- pmax(freq_w2 - a, 0)
  d <- pmax(n_total - freq_w1 - freq_w2 + a, 0)

  association <- switch(measure,
    "pmi" = {
      log2((a * n_total) / (freq_w1 * freq_w2))
    },
    "chi2" = {
      num <- (a * d - b * c)^2 * n_total
      den <- (a + b) * (c + d) * (a + c) * (b + d)
      ifelse(den > 0, num / den, NA_real_)
    },
    "ll" = {
      N  <- n_total
      e1 <- (a + b) * (a + c) / N
      e2 <- (a + b) * (b + d) / N
      e3 <- (a + c) * (c + d) / N
      e4 <- (b + d) * (c + d) / N
      t1 <- ifelse(a > 0 & e1 > 0, a * log(a / e1), 0)
      t2 <- ifelse(b > 0 & e2 > 0, b * log(b / e2), 0)
      t3 <- ifelse(c > 0 & e3 > 0, c * log(c / e3), 0)
      t4 <- ifelse(d > 0 & e4 > 0, d * log(d / e4), 0)
      2 * (t1 + t2 + t3 + t4)
    }
  )

  tibble::tibble(
    collocation = freq_ngrama$token,
    count       = freq_ngrama$count,
    association = association
  ) |>
    dplyr::filter(!is.na(association)) |>
    dplyr::arrange(dplyr::desc(association))
}
