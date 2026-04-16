#' Construir um corpus para análise de conteúdo
#'
#' @description
#' `ac_corpus()` é a porta de entrada do pipeline do pacote `acR`. Constrói
#' um objeto estruturado de corpus a partir de um `data.frame`, um vetor
#' de caracteres, ou um corpus do `quanteda`, validando a entrada e
#' preservando metadados associados aos documentos.
#'
#' @param data Entrada do corpus. Pode ser:
#'   * um `data.frame` ou `tibble` com pelo menos uma coluna de texto;
#'   * um vetor `character` com textos (um documento por elemento);
#'   * um objeto `corpus` do pacote `quanteda`.
#' @param text Nome da coluna de texto, sem aspas (usa *tidyselect* /
#'   *non-standard evaluation*). Apenas relevante quando `data` é um
#'   `data.frame`. Se `NULL` (padrão), a função tenta detectar automaticamente
#'   uma coluna chamada `text`, `texto`, `doc`, `content` ou `conteudo`.
#' @param docid Nome da coluna de identificador único, sem aspas. Se `NULL`
#'   (padrão), gera IDs sequenciais no formato `doc_1`, `doc_2`, ...
#' @param meta Colunas de metadados a preservar, via *tidyselect* (ex:
#'   `c(partido, data, regiao)` ou `tidyselect::starts_with("var_")`).
#'   Se `NULL`, preserva todas as demais colunas do `data.frame`.
#' @param lang Código ISO do idioma do corpus (padrão: `"pt"`). Utilizado
#'   em etapas posteriores (lematização, stopwords, léxicos).
#' @param ... Argumentos reservados para extensão futura. No momento,
#'   são ignorados com aviso se nomeados de forma desconhecida.
#'
#' @return Um objeto de classe `ac_corpus` (que herda de `tbl_df`,
#'   `tbl`, `data.frame`) com as colunas:
#'   * `doc_id` (character): identificador único do documento.
#'   * `text` (character): texto do documento.
#'   * Demais colunas de metadados, preservadas de `data`.
#'   O objeto traz também o atributo `lang` indicando o idioma.
#'
#' @details
#' A função realiza cinco validações obrigatórias e falha cedo em caso
#' de problema:
#'
#' 1. `data` deve ser de um dos tipos suportados;
#' 2. a coluna de texto deve existir (ou ser detectável automaticamente);
#' 3. a coluna de texto não pode ser inteiramente `NA` ou vazia;
#' 4. `doc_id` não pode ter valores duplicados;
#' 5. `doc_id` não pode conter `NA`.
#'
#' Documentos com texto vazio ou `NA` geram aviso (`warning`) mas são
#' mantidos no corpus com texto `""` — o usuário decide se filtra depois.
#'
#' @examples
#' # A partir de um data.frame
#' df <- data.frame(
#'   id = c("a", "b", "c"),
#'   texto = c("Primeiro texto.", "Segundo texto.", "Terceiro."),
#'   partido = c("PT", "PL", "MDB")
#' )
#' corpus <- ac_corpus(df, text = texto, docid = id, meta = partido)
#' corpus
#'
#' # A partir de um vetor character (doc_id gerado automaticamente)
#' ac_corpus(c("Texto um.", "Texto dois."))
#'
#' # Detecção automática da coluna de texto
#' df2 <- data.frame(text = c("A", "B"), autor = c("X", "Y"))
#' ac_corpus(df2)
#'
#' @concept corpus
#' @export
ac_corpus <- function(data, text = NULL, docid = NULL, meta = NULL,
                      lang = "pt", ...) {

  # === 1. Validar tipo de entrada =========================================
  # IMPORTANTE: testar quanteda::corpus ANTES de is.character(),
  # porque corpus herda de character no quanteda 4.x
  if (inherits(data, "corpus")) {
    return(.ac_corpus_from_quanteda(data, lang = lang))
  }
  if (is.character(data) && is.null(dim(data))) {
    return(.ac_corpus_from_character(data, lang = lang))
  }

  if (!is.data.frame(data)) {
    cli::cli_abort(c(
      "{.arg data} deve ser um {.cls data.frame}, vetor {.cls character}, ou {.cls quanteda::corpus}.",
      "x" = "Recebido: {.cls {class(data)[1]}}."
    ))
  }

  # === 2. Detectar/validar coluna de texto ================================
  text_quo <- rlang::enquo(text)
  text_name <- if (rlang::quo_is_null(text_quo)) {
    .ac_detect_text_column(data)
  } else {
    rlang::as_name(text_quo)
  }

  if (!text_name %in% names(data)) {
    cli::cli_abort(c(
      "Coluna de texto {.val {text_name}} n\u00e3o existe em {.arg data}.",
      "i" = "Colunas dispon\u00edveis: {.val {names(data)}}."
    ))
  }

  text_vec <- data[[text_name]]

  if (!is.character(text_vec)) {
    text_vec <- as.character(text_vec)
  }

  # === 3. Validar que texto não é inteiramente NA/vazio ===================
  if (all(is.na(text_vec) | text_vec == "")) {
    cli::cli_abort(
      "Coluna de texto {.val {text_name}} est\u00e1 inteiramente vazia ou {.val NA}."
    )
  }

  # Aviso se alguns textos estão vazios
  n_empty <- sum(is.na(text_vec) | text_vec == "")
  if (n_empty > 0) {
    cli::cli_warn(c(
      "{n_empty} de {length(text_vec)} documento{?s} com texto vazio ou {.val NA}.",
      "i" = "Foram mantidos com texto {.val \"\"}. Use {.fn dplyr::filter} se desejar remover."
    ))
    text_vec[is.na(text_vec)] <- ""
  }

  # === 4. Detectar/gerar/validar doc_id ===================================
  docid_quo <- rlang::enquo(docid)
  if (rlang::quo_is_null(docid_quo)) {
    doc_id_vec <- paste0("doc_", seq_len(nrow(data)))
  } else {
    docid_name <- rlang::as_name(docid_quo)
    if (!docid_name %in% names(data)) {
      cli::cli_abort(c(
        "Coluna de ID {.val {docid_name}} n\u00e3o existe em {.arg data}.",
        "i" = "Colunas dispon\u00edveis: {.val {names(data)}}."
      ))
    }
    doc_id_vec <- as.character(data[[docid_name]])

    if (any(is.na(doc_id_vec))) {
      cli::cli_abort(
        "Coluna {.val {docid_name}} cont\u00e9m valores {.val NA}. IDs devem ser \u00fanicos e n\u00e3o-nulos."
      )
    }

    if (anyDuplicated(doc_id_vec) > 0) {
      dupes <- doc_id_vec[duplicated(doc_id_vec)]
      cli::cli_abort(c(
        "Coluna {.val {docid_name}} cont\u00e9m IDs duplicados.",
        "x" = "Duplicados: {.val {unique(dupes)}}."
      ))
    }
  }

  # === 5. Selecionar metadados ============================================
  meta_quo <- rlang::enquo(meta)
  if (rlang::quo_is_null(meta_quo)) {
    # Preservar todas as colunas exceto text e docid
    cols_to_drop <- text_name
    if (!rlang::quo_is_null(docid_quo)) {
      cols_to_drop <- c(cols_to_drop, rlang::as_name(docid_quo))
    }
    meta_df <- data[, setdiff(names(data), cols_to_drop), drop = FALSE]
  } else {
    # Aplicar tidyselect
    meta_cols <- tidyselect::eval_select(meta_quo, data)
    meta_df <- data[, meta_cols, drop = FALSE]
  }

  # === 6. Montar tibble final =============================================
  result <- tibble::tibble(
    doc_id = doc_id_vec,
    text   = text_vec
  )

  if (ncol(meta_df) > 0) {
    result <- dplyr::bind_cols(result, meta_df)
  }

  # Tratar argumentos extras
  dots <- list(...)
  if (length(dots) > 0) {
    cli::cli_warn(
      "Argumento{?s} ignorado{?s}: {.val {names(dots)}}."
    )
  }

  # === 7. Aplicar classe e atributos ======================================
  class(result) <- c("ac_corpus", class(result))
  attr(result, "lang") <- lang

  result
}


# ============================================================================
# Construtores internos
# ============================================================================

#' @keywords internal
#' @noRd
.ac_corpus_from_character <- function(x, lang = "pt") {
  if (length(x) == 0) {
    cli::cli_abort("Vetor de texto est\u00e1 vazio.")
  }
  result <- tibble::tibble(
    doc_id = paste0("doc_", seq_along(x)),
    text   = x
  )
  class(result) <- c("ac_corpus", class(result))
  attr(result, "lang") <- lang
  result
}

#' @keywords internal
#' @noRd
.ac_corpus_from_quanteda <- function(x, lang = "pt") {
  if (!requireNamespace("quanteda", quietly = TRUE)) {
    cli::cli_abort(c(
      "Para converter um {.cls quanteda::corpus}, o pacote {.pkg quanteda} deve estar instalado.",
      "i" = "Instale com {.code install.packages(\"quanteda\")}."
    ))
  }
  # Extrair docnames via API pública e estável
  doc_ids <- as.character(quanteda::docnames(x))
  # Extrair textos: as.character() genérico (dispatch S3) e limpeza de atributos
  texts_raw <- as.character(x)
  # Remover todos os atributos (classe 'corpus', names, etc.) para obter character puro
  texts_char <- unclass(texts_raw)
  attributes(texts_char) <- NULL
  texts_char <- as.character(texts_char)
  # Extrair docvars
  docvars <- tryCatch(
    quanteda::docvars(x),
    error = function(e) NULL
  )
  # Montar tibble
  result <- tibble::tibble(
    doc_id = doc_ids,
    text   = texts_char
  )
  # Adicionar docvars se existirem
  if (!is.null(docvars) && is.data.frame(docvars) && ncol(docvars) > 0 && nrow(docvars) == nrow(result)) {
    result <- dplyr::bind_cols(result, docvars)
  }
  class(result) <- c("ac_corpus", class(result))
  attr(result, "lang") <- lang
  result
}

#' @keywords internal
#' @noRd
.ac_detect_text_column <- function(data) {
  candidates <- c("text", "texto", "doc", "content", "conteudo", "conte\u00fado")
  found <- intersect(candidates, names(data))
  if (length(found) == 0) {
    cli::cli_abort(c(
      "N\u00e3o foi poss\u00edvel detectar a coluna de texto automaticamente.",
      "i" = "Especifique via {.arg text}. Colunas dispon\u00edveis: {.val {names(data)}}.",
      "i" = "Nomes detect\u00e1veis automaticamente: {.val {candidates}}."
    ))
  }
  found[1]
}


# ============================================================================
# Métodos S3
# ============================================================================

#' @export
#' @concept corpus
print.ac_corpus <- function(x, n = 6, ...) {
  lang <- attr(x, "lang") %||% "?"
  n_docs <- nrow(x)
  n_meta <- ncol(x) - 2

  cli::cli_h1("Corpus {.pkg acR}")
  cli::cli_bullets(c(
    "*" = "Documentos: {.val {n_docs}}",
    "*" = "Metadados: {.val {n_meta}} coluna{?s}",
    "*" = "Idioma: {.val {lang}}"
  ))

  # Remover a classe ac_corpus temporariamente para usar o print do tibble
  cli::cli_text("")
  x_plain <- x
  class(x_plain) <- setdiff(class(x_plain), "ac_corpus")
  print(x_plain, n = n, ...)
  invisible(x)
}

#' @export
#' @concept corpus
summary.ac_corpus <- function(object, ...) {
  lang <- attr(object, "lang") %||% "?"
  n_docs <- nrow(object)
  n_meta <- ncol(object) - 2

  # Estatísticas de tamanho de texto (em caracteres)
  nchars <- nchar(object$text)
  # Estatísticas de número de tokens (aproximação: separar por espaço)
  ntokens <- lengths(strsplit(object$text, "\\s+"))

  result <- list(
    n_documents = n_docs,
    n_metadata  = n_meta,
    lang        = lang,
    chars       = c(
      min    = min(nchars),
      median = stats::median(nchars),
      mean   = mean(nchars),
      max    = max(nchars)
    ),
    tokens = c(
      min    = min(ntokens),
      median = stats::median(ntokens),
      mean   = mean(ntokens),
      max    = max(ntokens)
    ),
    metadata_names = setdiff(names(object), c("doc_id", "text"))
  )
  class(result) <- "summary.ac_corpus"
  result
}

#' @export
#' @noRd
print.summary.ac_corpus <- function(x, ...) {
  cli::cli_h1("Resumo do corpus {.pkg acR}")
  cli::cli_bullets(c(
    "*" = "Documentos: {.val {x$n_documents}}",
    "*" = "Idioma: {.val {x$lang}}",
    "*" = "Metadados ({x$n_metadata}): {.val {x$metadata_names}}"
  ))
  cli::cli_h2("Tamanho dos documentos (caracteres)")
  cli::cli_text(
    "min={.val {x$chars['min']}} | mediana={.val {round(x$chars['median'])}} | m\u00e9dia={.val {round(x$chars['mean'], 1)}} | max={.val {x$chars['max']}}"
  )
  cli::cli_h2("Tamanho dos documentos (tokens aproximados)")
  cli::cli_text(
    "min={.val {x$tokens['min']}} | mediana={.val {round(x$tokens['median'])}} | m\u00e9dia={.val {round(x$tokens['mean'], 1)}} | max={.val {x$tokens['max']}}"
  )
  invisible(x)
}

#' @export
#' @concept corpus
format.ac_corpus <- function(x, ...) {
  lang <- attr(x, "lang") %||% "?"
  sprintf("<ac_corpus: %d docs, lang=%s>", nrow(x), lang)
}

#' @importFrom tibble as_tibble
#' @export
#' @concept corpus
as_tibble.ac_corpus <- function(x, ...) {
  # Remove a classe ac_corpus, mantendo apenas as classes do tibble
  attr(x, "lang") <- NULL
  class(x) <- setdiff(class(x), "ac_corpus")
  x
}


# ============================================================================
# Utilitário interno
# ============================================================================

#' @keywords internal
#' @noRd
`%||%` <- function(x, y) if (is.null(x)) y else x
