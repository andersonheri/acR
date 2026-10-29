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
#'   `"dice"` (coeficiente Dice). Padrão: as três.
#' @param min_count Frequência mínima de co-ocorrência para incluir o par.
#'   Padrão: `2`.
#' @param ... Ignorado.
#'
#' @return Tibble com colunas:
#'   * `word1`, `word2`: par de termos (ordenado alfabeticamente);
#'   * `cooc`: frequência de co-ocorrência. Com `unit = "window"`, é o
#'     número de vezes em que os dois termos aparecem a até `window`
#'     tokens um do outro (cada encontro conta **uma** vez); com
#'     `unit = "document"`, é o número de documentos que contêm os dois;
#'   * `pmi` (se solicitado): pointwise mutual information, em bits;
#'   * `dice` (se solicitado): coeficiente Dice.
#'
#' @details
#' **PMI** (Church & Hanks, 1990) compara a probabilidade conjunta com a
#' esperada sob independência: \eqn{\log_2 [P(x,y) / (P(x)P(y))]}. Zero
#' indica que o par aparece junto tanto quanto o acaso preveria; valores
#' positivos, mais que o acaso. PMI superestima pares raros (Evert, 2005),
#' por isso use `min_count` para descartá-los.
#'
#' **Dice** (Smadja, McKeown & Hatzivassiloglou, 1996) é
#' \eqn{2 f(x,y) / (f(x) + f(y))}, entre 0 e 1.
#'
#' As probabilidades usam a mesma unidade da contagem conjunta: com
#' `unit = "window"`, frequências de token e o total de tokens do corpus
#' (aproximação usual de Church & Hanks); com `unit = "document"`,
#' frequência documental (em quantos documentos o termo aparece) e o
#' número de documentos. Pares de um termo com ele mesmo são ignorados.
#'
#' @references
#' Church, K. W.; Hanks, P. (1990). Word association norms, mutual
#' information, and lexicography. *Computational Linguistics*, 16(1),
#' 22-29.
#'
#' Evert, S. (2005). *The Statistics of Word Cooccurrences: Word Pairs and
#' Collocations*. Tese (Doutorado), Universität Stuttgart.
#'
#' Smadja, F.; McKeown, K. R.; Hatzivassiloglou, V. (1996). Translating
#' collocations for bilingual lexicons: A statistical approach.
#' *Computational Linguistics*, 22(1), 1-38.
#'
#' @examples
#' # Corpus tematico: coocorrência revela associações conceituais
#' # (que palavras "andam juntas" no discurso).
#' df <- data.frame(
#'   id = paste0("d", 1:6),
#'   texto = c(
#'     "democracia participacao voto liberdade cidadania popular",
#'     "cidadania direitos participacao democracia representacao politica",
#'     "voto direitos liberdade cidadania soberania popular",
#'     "mercado economia eficiência privatizacao competicao livre",
#'     "privatizacao mercado livre eficiência produtividade lucro",
#'     "economia crescimento investimento mercado capital juros"
#'   ),
#'   stringsAsFactors = FALSE
#' )
#'
#' corpus <- ac_corpus(df, text = texto, docid = id) |>
#'   ac_clean()
#' tokens <- ac_tokenize(corpus)
#'
#' # Janela de 3 tokens, sem filtro de frequência mínima
#' # (em corpora reais use min_count >= 5 para reduzir ruido)
#' cooc <- ac_cooccurrence(tokens, window = 3L, min_count = 1L)
#' head(cooc)
#'
#' # Coocorrência com PMI (associação normalizada por acaso)
#' cooc_pmi <- ac_cooccurrence(tokens, window = 3L, measure = "pmi",
#'                             min_count = 1L)
#' head(cooc_pmi)
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

  # Marginais em unidade de PAR (so no modo janela): em quantos pares cada palavra
  # entra, contados ANTES do corte por min_count. O Dice precisa deste marginal:
  # com a frequencia de token, uma palavra repetida perto de outra gera mais pares
  # (A,B) do que ocorrencias de A e B, e o Dice passava de 1.
  if (unit == "window" && "dice" %in% measure) {
    pair_freq_tbl <- dplyr::bind_rows(
      tibble::tibble(word = pairs$word1),
      tibble::tibble(word = pairs$word2)
    ) |>
      dplyr::count(word, name = "pair_freq")
  }

  # Contar co-ocorrências
  cooc_tbl <- pairs |>
    dplyr::count(word1, word2, name = "cooc") |>
    dplyr::filter(cooc >= min_count)

  if (nrow(cooc_tbl) == 0L) {
    return(.empty_cooc_tibble(measure))
  }

  # Frequências marginais para PMI e Dice, na MESMA unidade de cooc:
  # janela -> frequência de token e total de tokens; documento ->
  # frequência documental e número de documentos. Misturar as unidades
  # (cooc em documentos, freq em tokens) dava Dice e PMI sem sentido.
  if (any(c("pmi", "dice") %in% measure)) {
    if (unit == "window") {
      freq_tbl <- tokens_tbl |>
        dplyr::count(token, name = "freq") |>
        dplyr::rename(word = token)
      total_tokens <- sum(freq_tbl$freq)
    } else {
      freq_tbl <- tokens_tbl |>
        dplyr::distinct(doc_id, token) |>
        dplyr::count(token, name = "freq") |>
        dplyr::rename(word = token)
      total_tokens <- dplyr::n_distinct(tokens_tbl$doc_id)
    }

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

  # Dice: 2 * cooc / (marginal1 + marginal2). Janela: marginal = numero de pares
  # em que a palavra entra (assim 0 <= Dice <= 1). Documento: frequencia documental.
  if ("dice" %in% measure) {
    if (unit == "window") {
      cooc_tbl <- cooc_tbl |>
        dplyr::left_join(pair_freq_tbl |> dplyr::rename(pf1 = pair_freq),
                         by = c("word1" = "word")) |>
        dplyr::left_join(pair_freq_tbl |> dplyr::rename(pf2 = pair_freq),
                         by = c("word2" = "word")) |>
        dplyr::mutate(dice = (2 * cooc) / (pf1 + pf2))
    } else {
      cooc_tbl <- cooc_tbl |>
        dplyr::mutate(dice = (2 * cooc) / (freq1 + freq2))
    }
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
    for (j in seq_len(n - 1L)) {
      # Olhar so para a FRENTE: o par (j, j+d) e registrado uma unica vez.
      # Olhar para os dois lados contava cada encontro duas vezes (uma a
      # partir de cada palavra), dobrando cooc e somando 1 bit ao PMI.
      hi  <- min(n, j + window)
      ctx <- (j + 1L):hi
      w1 <- toks[j]
      w2 <- toks[ctx]
      w2 <- w2[w2 != w1]
      if (length(w2) == 0L) next
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
