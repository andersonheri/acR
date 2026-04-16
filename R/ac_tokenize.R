#' Tokenizar textos de um corpus acR
#'
#' @description
#' `ac_tokenize()` recebe um objeto [`ac_corpus()`] e retorna um
#' `tibble` em formato *tidy*, com um token por linha, no estilo
#' usado em analises de texto no ecossistema tidy.
#'
#' A funcao implementa tokenizacao em palavras (n = 1) ou
#' n-gramas de tamanho arbitrario (n > 1), usando janelas
#' contiguas de tokens dentro de cada documento.
#'
#' @param corpus Objeto de classe [`ac_corpus()`].
#' @param token Tipo de tokenizacao desejada. Atualmente apenas
#'   `"word"` e suportado (padrao), reservado para futura expansao.
#' @param n Tamanho do n-grama. Deve ser um inteiro maior ou igual
#'   a 1. Para `n = 1`, o resultado sao tokens individuais; para
#'   `n = 2`, bigramas (`"A B"`), para `n = 3`, trigramas etc.
#' @param keep_empty Logico. Se `FALSE` (padrao), documentos que
#'   resultarem em texto vazio apos a limpeza nao geram linhas na
#'   saida. Se `TRUE`, cada documento vazio gera uma linha com
#'   `token = NA` quando `n = 1`.
#' @param drop_punct Logico. Se `TRUE`, remove da sequencia tokens
#'   que consistem apenas de pontuacao (por exemplo `"!"`, `"..."`)
#'   antes de construir n-gramas. Tokens que misturam letras e
#'   pontuacao (por exemplo `"ola,"`) sao mantidos.
#' @param ... Ignorado, reservado para argumentos futuros.
#'
#' @return Um [`tibble::tibble()`] com colunas:
#' \itemize{
#'   \item `doc_id`: identificador do documento (herdado de `ac_corpus`);
#'   \item `token_id`: posicao (1, 2, 3, ...) do token ou n-grama no documento;
#'   \item `token`: texto do token ou n-grama.
#' }
#'
#' @examples
#' df <- data.frame(
#'   id    = c("d1", "d2"),
#'   texto = c(
#'     "O deputado do PT falou na CCJ.",
#'     "Votar pra valer, agora!"
#'   )
#' )
#'
#' corp <- ac_corpus(df, text = texto, docid = id)
#'
#' # Tokenizacao simples em palavras
#' tokens <- ac_tokenize(corp)
#' tokens
#'
#' # Removendo tokens que sao apenas pontuacao
#' df2 <- data.frame(
#'   id    = "d1",
#'   texto = "Ola, mundo ! ..."
#' )
#' corp2   <- ac_corpus(df2, text = texto, docid = id)
#' tokens2 <- ac_tokenize(corp2, drop_punct = TRUE)
#' tokens2
#'
#' # Bigramas
#' ac_tokenize(corp, n = 2)
#'
#' @seealso [ac_corpus()], [ac_clean()]
#' @concept corpus
#' @export
ac_tokenize <- function(
    corpus,
    token      = c("word"),
    n          = 1L,
    keep_empty = FALSE,
    drop_punct = FALSE,
    ...
) {
  # --- Validacoes ------------------------------------------------------------
  
  if (!is_ac_corpus(corpus)) {
    cli::cli_abort(c(
      "{.arg corpus} deve ser um objeto {.cls ac_corpus}.",
      "i" = "Crie com {.fun ac_corpus}."
    ))
  }
  
  token <- match.arg(token)
  
  if (!is.numeric(n) || length(n) != 1L || is.na(n) || n < 1 || n != as.integer(n)) {
    cli::cli_abort("{.arg n} deve ser um inteiro maior ou igual a 1.")
  }
  n <- as.integer(n)
  
  if (!is.logical(keep_empty) || length(keep_empty) != 1L) {
    cli::cli_abort("{.arg keep_empty} deve ser TRUE ou FALSE.")
  }
  
  if (!is.logical(drop_punct) || length(drop_punct) != 1L) {
    cli::cli_abort("{.arg drop_punct} deve ser TRUE ou FALSE.")
  }
  
  if (!requireNamespace("stringr", quietly = TRUE)) {
    cli::cli_abort(
      "O pacote {.pkg stringr} e necessario. ",
      "Instale com {.code install.packages(\"stringr\")}."
    )
  }
  
  if (!requireNamespace("tibble", quietly = TRUE)) {
    cli::cli_abort(
      "O pacote {.pkg tibble} e necessario. ",
      "Instale com {.code install.packages(\"tibble\")}."
    )
  }
  
  # Avisar sobre argumentos extras
  dots <- list(...)
  if (length(dots) > 0) {
    cli::cli_warn("Argumento{?s} ignorado{?s}: {.val {names(dots)}}.")
  }
  
  # --- Extracao de texto e doc_id -------------------------------------------
  
  txt    <- corpus$text
  doc_id <- corpus$doc_id
  
  if (!is.character(txt)) {
    txt <- as.character(txt)
  }
  
  # Normalizar espacos
  txt_norm <- stringr::str_squish(txt)
  
  # Identificar documentos vazios
  is_empty <- txt_norm == "" | is.na(txt_norm)
  
  # Split em tokens por espacos
  lista_tokens <- stringr::str_split(txt_norm, "\\s+", simplify = FALSE)
  
  # Tratar vazios conforme keep_empty
  if (!keep_empty) {
    lista_tokens[is_empty] <- list(character(0))
  } else {
    lista_tokens[is_empty] <- list(NA_character_)
  }
  
  # Remover tokens que sao apenas pontuacao, se solicitado
  if (drop_punct) {
    lista_tokens <- lapply(lista_tokens, function(tk) {
      if (length(tk) == 0L) return(tk)
      is_punct <- !is.na(tk) & grepl("^[[:punct:]]+$", tk)
      tk[!is_punct]
    })
  }
  
  # --- Construir tokens ou n-gramas -----------------------------------------
  
  if (n == 1L) {
    # Unigramas: comportamento original
    token_vec <- unlist(lista_tokens, use.names = FALSE)
    
    if (length(token_vec) == 0L) {
      return(
        tibble::tibble(
          doc_id   = character(0),
          token_id = integer(0),
          token    = character(0)
        )
      )
    }
    
    n_tokens_por_doc <- vapply(lista_tokens, length, integer(1))
  } else {
    # Funcao auxiliar para construir n-gramas de um vetor de tokens
    build_ngrams <- function(tk, n) {
      # Remover NAs antes de construir n-gramas
      tk <- tk[!is.na(tk)]
      len <- length(tk)
      if (len < n) return(character(0))
      vapply(
        seq_len(len - n + 1L),
        function(i) paste(tk[i:(i + n - 1L)], collapse = " "),
        character(1)
      )
    }
    
    lista_ngrams <- lapply(lista_tokens, build_ngrams, n = n)
    token_vec    <- unlist(lista_ngrams, use.names = FALSE)
    
    if (length(token_vec) == 0L) {
      return(
        tibble::tibble(
          doc_id   = character(0),
          token_id = integer(0),
          token    = character(0)
        )
      )
    }
    
    n_tokens_por_doc <- vapply(lista_ngrams, length, integer(1))
  }
  
  # Vetores de doc_id e token_id
  doc_id_vec   <- rep(doc_id, times = n_tokens_por_doc)
  token_id_vec <- sequence(n_tokens_por_doc)
  
  tibble::tibble(
    doc_id   = doc_id_vec,
    token_id = token_id_vec,
    token    = token_vec
  )
}
