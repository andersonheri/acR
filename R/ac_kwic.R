#' Concordância (keyword-in-context, KWIC)
#'
#' @description
#' `ac_kwic()` localiza todas as ocorrências de um termo (ou padrão) nos
#' documentos de um `ac_corpus` e devolve cada ocorrência com uma janela
#' de palavras antes e depois — a técnica de concordância usada desde os
#' primórdios da linguística de corpus (Sinclair, 1991) para entender
#' *como* uma palavra é usada, não só *com que frequência*.
#'
#' É o complemento natural de uma análise de frequência ou keyness: saber
#' que "liberdade" é um termo-chave de um grupo não diz nada sobre como o
#' termo é empregado — a concordância mostra se aparece ao lado de
#' "econômica", "de expressão" ou "individual", revelando o enquadramento
#' (framing) real do termo em cada contexto. Funciona em qualquer corpus
#' com linguagem natural: reviews de produto, letras de música, transcrições
#' de atendimento, posts em redes sociais.
#'
#' @param corpus Objeto `ac_corpus`.
#' @param pattern Termo ou expressão regular a localizar (string única).
#' @param window Número de palavras de contexto a mostrar antes e depois
#'   de cada ocorrência. Padrão: `5`.
#' @param regex Lógico. Se `FALSE` (padrão), `pattern` é tratado como uma
#'   palavra exata (comparação literal, após normalização de caixa). Se
#'   `TRUE`, `pattern` é tratado como expressão regular (POSIX) aplicada
#'   a cada token.
#' @param case_insensitive Lógico. Se `TRUE` (padrão), ignora
#'   diferenças de maiúsculas/minúsculas na busca.
#'
#' @return Tibble com uma linha por ocorrência, colunas:
#'   * `doc_id`: documento onde a ocorrência foi encontrada;
#'   * `position`: posição do token correspondente no documento;
#'   * `before`: até `window` palavras imediatamente antes;
#'   * `keyword`: o token que casou com `pattern`, como aparece no texto;
#'   * `after`: até `window` palavras imediatamente depois.
#'
#' @references
#' Sinclair, J. (1991). *Corpus, Concordance, Collocation*. Oxford
#' University Press.
#'
#' @examples
#' # Avaliacoes de atendimento ao cliente
#' df <- data.frame(
#'   id = paste0("a", 1:4),
#'   texto = c(
#'     "o atendimento foi rapido e a atendente foi muito educada comigo",
#'     "fiquei esperando muito tempo e o atendimento foi frio e distante",
#'     "atendimento excelente, resolveram meu problema na hora",
#'     "o atendimento automatico nao entendeu minha solicitacao"
#'   ),
#'   stringsAsFactors = FALSE
#' )
#' corpus <- ac_corpus(df, text = texto, docid = id)
#'
#' ac_kwic(corpus, pattern = "atendimento", window = 3)
#'
#' @seealso [ac_plot_xray()], [ac_count()]
#' @concept quantitative
#' @export
ac_kwic <- function(corpus,
                     pattern,
                     window = 5L,
                     regex = FALSE,
                     case_insensitive = TRUE) {
  if (!is_ac_corpus(corpus)) {
    cli::cli_abort("{.arg corpus} deve ser um {.cls ac_corpus}.")
  }
  if (!is.character(pattern) || length(pattern) != 1L || is.na(pattern)) {
    cli::cli_abort("{.arg pattern} deve ser uma unica string.")
  }
  if (!is.numeric(window) || length(window) != 1L || window < 0L) {
    cli::cli_abort("{.arg window} deve ser um inteiro n\u00e3o negativo.")
  }
  window <- as.integer(window)

  tokens_tbl <- ac_tokenize(corpus)
  if (nrow(tokens_tbl) == 0L) {
    return(tibble::tibble(
      doc_id = character(0), position = integer(0),
      before = character(0), keyword = character(0), after = character(0)
    ))
  }

  cmp <- if (case_insensitive) tolower(tokens_tbl$token) else tokens_tbl$token
  pat <- if (case_insensitive) tolower(pattern) else pattern

  matches <- if (regex) {
    grepl(pat, cmp, perl = TRUE)
  } else {
    cmp == pat
  }

  if (!any(matches)) {
    return(tibble::tibble(
      doc_id = character(0), position = integer(0),
      before = character(0), keyword = character(0), after = character(0)
    ))
  }

  idx <- which(matches)
  result <- lapply(idx, function(i) {
    doc    <- tokens_tbl$doc_id[i]
    mesmo_doc <- tokens_tbl$doc_id == doc
    pos_doc   <- which(mesmo_doc)
    pos_i     <- which(pos_doc == i)

    ini_before <- max(1L, pos_i - window)
    fim_after  <- min(length(pos_doc), pos_i + window)

    before <- if (pos_i > 1L) {
      paste(tokens_tbl$token[pos_doc[ini_before:(pos_i - 1L)]], collapse = " ")
    } else ""
    after <- if (pos_i < length(pos_doc)) {
      paste(tokens_tbl$token[pos_doc[(pos_i + 1L):fim_after]], collapse = " ")
    } else ""

    tibble::tibble(
      doc_id   = doc,
      position = tokens_tbl$token_id[i],
      before   = before,
      keyword  = tokens_tbl$token[i],
      after    = after
    )
  })

  dplyr::bind_rows(result)
}
