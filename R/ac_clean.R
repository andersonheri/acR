#' Limpar e normalizar texto de um corpus
#'
#' @description
#' `ac_clean()` aplica um conjunto configurável de transformações ao texto de
#' um objeto `ac_corpus`, retornando um novo corpus com o texto modificado.
#' As transformações são aplicadas em ordem lógica e registradas como atributo
#' para auditoria.
#'
#' @param corpus Objeto de classe `ac_corpus`, criado por [ac_corpus()].
#' @param lower Se `TRUE` (padrão), converte texto para minúsculas.
#' @param remove_punct Se `TRUE` (padrão), remove pontuação.
#' @param remove_numbers Se `TRUE`, remove dígitos. Padrão: `FALSE`.
#' @param remove_url Se `TRUE` (padrão), remove URLs (http, https, www).
#' @param remove_email Se `TRUE` (padrão), remove endereços de e-mail.
#' @param remove_symbols Se `TRUE`, remove símbolos e emojis (@, #, \*, etc.).
#'   Padrão: `FALSE`. Cuidado: hashtags e menções podem ser informativas.
#' @param remove_hashtags Se `TRUE`, remove hashtags (#termo). Padrão: `FALSE`.
#' @param remove_mentions Se `TRUE`, remove menções (\@usuario). Padrão: `FALSE`.
#' @param remove_stopwords Pode ser:
#'   * `NULL` (padrão): não remove stopwords;
#'   * uma string com nome de preset (`"pt"`, `"pt-br-extended"`,
#'     `"pt-legislativo"`, `"en"`);
#'   * um vetor `character` com stopwords customizadas.
#' @param remove_accents Se `TRUE`, remove acentos (ex: "ação" vira "acao").
#'   Padrão: `FALSE`.
#' @param normalize_pt Se `TRUE`, aplica normalizações ortográficas do português
#'   brasileiro coloquial: `"pra"` → `"para"`, `"tá"` → `"está"`, etc.
#'   Padrão: `FALSE`.
#' @param protect Vetor `character` com termos a preservar exatamente como
#'   estão. Útil para siglas (`c("PT", "PSDB", "CCJ")`). Padrão: `NULL`.
#' @param extra_stopwords Vetor `character` com stopwords adicionais a remover
#'   antes de qualquer análise, combinado ao preset de `remove_stopwords`.
#'   Use [ac_clean_stopwords()] para inspecionar e editar o objeto padrão.
#'   Padrão: `NULL`.
#' @param min_char Inteiro. Descarta tokens com menos de `min_char` caracteres
#'   após a limpeza. Padrão: `NULL` (sem filtro).
#' @param custom_replacements Lista nomeada de substituições livres aplicadas
#'   antes das demais transformações. Ex: `list("pres\\." = "presidente",
#'   "dep\\." = "deputado")`. Padrão: `NULL`.
#' @param handle_na Como tratar valores `NA` no texto:
#'   * `"preserve"` (padrão): mantém `NA` como `NA`;
#'   * `"empty"`: converte `NA` para `""`;
#'   * `"remove"`: remove documentos com `NA` do corpus.
#' @param strip_whitespace Se `TRUE` (padrão), colapsa espaços consecutivos.
#' @param verbose Se `TRUE`, exibe resumo das operações e estatísticas de
#'   remoção por etapa. Padrão: `FALSE`.
#' @param ... Ignorado com aviso se houver argumentos não reconhecidos.
#'
#' @return Um novo objeto `ac_corpus` com a coluna `text` transformada e o
#'   atributo `cleaning_steps` registrando as operações aplicadas em ordem.
#'   Quando `verbose = TRUE`, também imprime um resumo com tokens removidos
#'   por etapa e documentos que ficaram vazios após limpeza.
#'
#' @details
#' **Ordem de aplicação** das transformações:
#'
#' 1. `handle_na`: tratamento de NAs
#' 2. `custom_replacements`: substituições livres
#' 3. `protect`: proteção de termos com placeholders
#' 4. `remove_url` e `remove_email`
#' 5. `remove_hashtags` e `remove_mentions`
#' 6. `remove_symbols`
#' 7. `lower`
#' 8. `remove_accents`
#' 9. `normalize_pt`
#' 10. `remove_numbers`
#' 11. `remove_punct`
#' 12. `remove_stopwords` + `extra_stopwords`
#' 13. `min_char`: remoção de tokens curtos
#' 14. Restauração dos termos protegidos
#' 15. `strip_whitespace` (sempre)
#'
#' @examples
#' df <- data.frame(
#'   id = c("a", "b", "c"),
#'   texto = c(
#'     "O deputado do PT disse: 'Defendo a CCJ!' Veja em https://exemplo.org",
#'     "Sra. presidente, o Sr. senador apresentou o requerimento n\u00ba 123.",
#'     "T\u00e1 na hora de votar, pra acabar com isso."
#'   )
#' )
#' corpus <- ac_corpus(df, text = texto, docid = id)
#'
#' # Limpeza básica
#' ac_clean(corpus)
#'
#' # Limpeza completa com todas as opções
#' ac_clean(
#'   corpus,
#'   remove_stopwords  = "pt-legislativo",
#'   extra_stopwords   = c("isso", "aquilo", "coisa"),
#'   protect           = c("PT", "CCJ"),
#'   normalize_pt      = TRUE,
#'   custom_replacements = list("pres\\." = "presidente"),
#'   min_char          = 3L,
#'   verbose           = TRUE
#' )
#'
#' @seealso [ac_corpus()], [ac_clean_stopwords()]
#' @concept corpus
#' @export
ac_clean <- function(corpus,
                     lower               = TRUE,
                     remove_punct        = TRUE,
                     remove_numbers      = FALSE,
                     remove_url          = TRUE,
                     remove_email        = TRUE,
                     remove_symbols      = FALSE,
                     remove_hashtags     = FALSE,
                     remove_mentions     = FALSE,
                     remove_stopwords    = NULL,
                     remove_accents      = FALSE,
                     normalize_pt        = FALSE,
                     protect             = NULL,
                     extra_stopwords     = NULL,
                     min_char            = NULL,
                     custom_replacements = NULL,
                     handle_na           = c("preserve", "empty", "remove"),
                     strip_whitespace    = TRUE,
                     verbose             = FALSE,
                     ...) {

  # === Validações ===========================================================
  if (!is_ac_corpus(corpus)) {
    cli::cli_abort(c(
      "{.arg corpus} deve ser um objeto {.cls ac_corpus}.",
      "i" = "Crie com {.fn ac_corpus}.",
      "x" = "Recebido: {.cls {class(corpus)[1]}}."
    ))
  }
  if (!requireNamespace("stringr", quietly = TRUE))
    cli::cli_abort("O pacote {.pkg stringr} \u00e9 necess\u00e1rio.")
  if (!requireNamespace("stringi", quietly = TRUE))
    cli::cli_abort("O pacote {.pkg stringi} \u00e9 necess\u00e1rio.")

  handle_na <- match.arg(handle_na)

  dots <- list(...)
  if (length(dots) > 0)
    cli::cli_warn("Argumento{?s} ignorado{?s}: {.val {names(dots)}}.")

  # === Preparar vetor de texto e registro de passos =========================
  txt   <- corpus$text
  steps <- character(0)

  # helper para contar tokens (para verbose)
  .count_tokens <- function(x) sum(lengths(stringr::str_split(x, "\\s+")), na.rm = TRUE)
  if (isTRUE(verbose)) tokens_before <- .count_tokens(txt)

  # === 0. Tratamento de NAs ================================================
  na_idx <- is.na(txt)
  if (any(na_idx)) {
    if (handle_na == "empty") {
      txt[na_idx] <- ""
      steps <- c(steps, "handle_na(empty)")
      cli::cli_inform(c("i" = "{sum(na_idx)} documento{?s} com NA convertido{?s} para string vazia."))
    } else if (handle_na == "remove") {
      corpus <- corpus[!na_idx, ]
      txt    <- txt[!na_idx]
      steps  <- c(steps, paste0("handle_na(remove=", sum(na_idx), ")"))
      cli::cli_inform(c("i" = "{sum(na_idx)} documento{?s} com NA removido{?s} do corpus."))
    }
    # "preserve": não faz nada, NA propaga normalmente
  }

  # === 1. Substituições customizadas ========================================
  if (!is.null(custom_replacements)) {
    if (!is.list(custom_replacements) || is.null(names(custom_replacements)))
      cli::cli_abort("{.arg custom_replacements} deve ser uma lista nomeada.")
    for (nm in names(custom_replacements)) {
      txt <- stringr::str_replace_all(txt, nm, custom_replacements[[nm]])
    }
    steps <- c(steps, paste0("custom_replacements(", length(custom_replacements), ")"))
  }

  # === 2. Proteção de termos ================================================
  protected_map <- NULL
  if (!is.null(protect) && length(protect) > 0) {
    if (!is.character(protect))
      cli::cli_abort("{.arg protect} deve ser um vetor {.cls character}.")
    placeholders  <- sprintf("__ACPROTECT_%03d__", seq_along(protect))
    protected_map <- stats::setNames(protect, placeholders)
    n_matched <- 0L
    for (i in seq_along(protect)) {
      pattern <- paste0("\\b", stringr::str_escape(protect[i]), "\\b")
      before  <- txt
      txt     <- stringr::str_replace_all(txt, pattern, placeholders[i])
      n_matched <- n_matched + sum(txt != before, na.rm = TRUE)
    }
    if (n_matched == 0L)
      cli::cli_warn("Nenhum termo em {.arg protect} foi encontrado no corpus.")
    steps <- c(steps, paste0("protect(", length(protect), " termos)"))
  }

  # === 3. URLs e emails =====================================================
  if (isTRUE(remove_url)) {
    txt   <- stringr::str_replace_all(txt, "\\b(?:https?://|www\\.)\\S+", " ")
    steps <- c(steps, "remove_url")
  }
  if (isTRUE(remove_email)) {
    txt   <- stringr::str_replace_all(txt, "\\b[[:alnum:]._%+-]+@[[:alnum:].-]+\\.[[:alpha:]]{2,}\\b", " ")
    steps <- c(steps, "remove_email")
  }

  # === 4. Hashtags e menções ================================================
  if (isTRUE(remove_hashtags)) {
    txt   <- stringr::str_replace_all(txt, "#\\S+", " ")
    steps <- c(steps, "remove_hashtags")
  }
  if (isTRUE(remove_mentions)) {
    txt   <- stringr::str_replace_all(txt, "@\\S+", " ")
    steps <- c(steps, "remove_mentions")
  }

  # === 5. Símbolos ==========================================================
  if (isTRUE(remove_symbols)) {
    txt   <- stringi::stri_replace_all_regex(txt, "[\\p{So}\\p{Sk}\\p{Sm}]", " ")
    steps <- c(steps, "remove_symbols")
  }

  # === 6. Lowercase =========================================================
  if (isTRUE(lower)) {
    txt <- stringr::str_to_lower(txt, locale = "pt")
    # Restaurar case dos placeholders que foram lowercased
    if (!is.null(protected_map)) {
      for (ph in names(protected_map)) {
        txt <- stringr::str_replace_all(txt, tolower(ph), ph)
      }
    }
    steps <- c(steps, "lower")
  }

  # === 7. Acentos ===========================================================
  if (isTRUE(remove_accents)) {
    txt   <- stringi::stri_trans_general(txt, "Latin-ASCII")
    steps <- c(steps, "remove_accents")
  }

  # === 8. Normalização PT-BR ================================================
  if (isTRUE(normalize_pt)) {
    txt   <- .ac_normalize_pt(txt)
    steps <- c(steps, "normalize_pt")
  }

  # === 9. Números ===========================================================
  if (isTRUE(remove_numbers)) {
    txt   <- stringr::str_replace_all(txt, "\\d+", " ")
    steps <- c(steps, "remove_numbers")
  }

  # === 10. Pontuação ========================================================
  if (isTRUE(remove_punct)) {
    txt   <- stringi::stri_replace_all_regex(txt, "[\\p{P}&&[^_]]", " ")
    steps <- c(steps, "remove_punct")
  }

  # === 11. Stopwords ========================================================
  stopword_vec <- character(0)

  if (!is.null(remove_stopwords)) {
    if (is.character(remove_stopwords) && length(remove_stopwords) == 1 &&
        remove_stopwords %in% c("pt", "pt-br-extended", "pt-legislativo", "en")) {
      stopword_vec <- .ac_get_stopwords(remove_stopwords)
      steps <- c(steps, paste0("remove_stopwords(preset=", remove_stopwords, ")"))
    } else if (is.character(remove_stopwords)) {
      stopword_vec <- remove_stopwords
      steps <- c(steps, paste0("remove_stopwords(custom=", length(stopword_vec), ")"))
    } else {
      cli::cli_abort(
        "{.arg remove_stopwords} deve ser {.code NULL}, string de preset, ou vetor {.cls character}."
      )
    }
  }

  # Adicionar extra_stopwords
  if (!is.null(extra_stopwords)) {
    if (!is.character(extra_stopwords))
      cli::cli_abort("{.arg extra_stopwords} deve ser um vetor {.cls character}.")
    stopword_vec <- unique(c(stopword_vec, extra_stopwords))
    steps <- c(steps, paste0("extra_stopwords(", length(extra_stopwords), ")"))
  }

  if (length(stopword_vec) > 0) {
    escaped <- stringr::str_escape(stopword_vec)
    pattern <- paste0("\\b(?:", paste(escaped, collapse = "|"), ")\\b")
    txt     <- stringr::str_replace_all(txt, pattern, " ")
  }

  # === 12. Tokens curtos ====================================================
  if (!is.null(min_char)) {
    min_char <- as.integer(min_char)
    # Remover tokens com menos de min_char caracteres
    pattern_short <- paste0("\\b\\w{1,", min_char - 1L, "}\\b")
    txt   <- stringr::str_replace_all(txt, pattern_short, " ")
    steps <- c(steps, paste0("min_char(", min_char, ")"))
  }

  # === 13. Restaurar termos protegidos ======================================
  if (!is.null(protected_map)) {
    for (ph in names(protected_map)) {
      txt <- stringr::str_replace_all(txt, ph, protected_map[[ph]])
    }
  }

  # === 14. Whitespace (sempre) ==============================================
  txt   <- stringr::str_squish(txt)
  steps <- c(steps, "strip_whitespace")

  # === Verbose: resumo ======================================================
  if (isTRUE(verbose)) {
    tokens_after  <- .count_tokens(txt)
    docs_vazios   <- sum(nchar(trimws(txt)) == 0L, na.rm = TRUE)
    cli::cli_inform(c(
      "v" = "Limpeza conclu\u00edda.",
      "i" = "Tokens antes: {tokens_before} | ap\u00f3s: {tokens_after} ({tokens_before - tokens_after} removidos).",
      "i" = "Documentos vazios ap\u00f3s limpeza: {docs_vazios}.",
      "i" = "Etapas aplicadas: {.val {steps}}."
    ))
  }

  # === Montar resultado =====================================================
  result       <- corpus
  result$text  <- txt
  attr(result, "cleaning_steps") <- steps
  if (!inherits(result, "ac_corpus"))
    class(result) <- c("ac_corpus", class(result))
  result
}


# ============================================================================
# Objeto editável de stopwords extras — para o pesquisador customizar
# ============================================================================

#' Inspecionar e editar stopwords extras do acR
#'
#' @description
#' `ac_clean_stopwords()` retorna (e opcionalmente modifica) o vetor de
#' stopwords adicionais que o pesquisador pode passar a [ac_clean()] via
#' `extra_stopwords`. Funciona como um ponto de partida editável: o
#' pesquisador inspeciona o vetor, adiciona ou remove termos conforme o
#' corpus, e passa o resultado para `extra_stopwords`.
#'
#' @param add Vetor `character` com termos a adicionar ao vetor padrão.
#' @param remove Vetor `character` com termos a remover do vetor padrão.
#' @param preset String indicando o ponto de partida:
#'   `"empty"` (padrão), `"pt"`, `"pt-br-extended"` ou `"pt-legislativo"`.
#'
#' @return Vetor `character` de stopwords pronto para passar a
#'   `ac_clean(..., extra_stopwords = ...)`.
#'
#' @examples
#' # Ver o vetor padrão vazio e adicionar termos
#' sw <- ac_clean_stopwords(add = c("nobre", "ilustre", "respeitavel"))
#' print(sw)
#'
#' # Partir do preset legislativo e remover termos que interessam ao corpus
#' sw <- ac_clean_stopwords(
#'   preset = "pt-legislativo",
#'   remove = c("lei", "projeto")   # manter: são relevantes para a análise
#' )
#'
#' # Usar na limpeza
#' # ac_clean(corpus, remove_stopwords = "pt", extra_stopwords = sw)
#'
#' @seealso [ac_clean()]
#' @export
ac_clean_stopwords <- function(add    = NULL,
                                remove = NULL,
                                preset = c("empty", "pt", "pt-br-extended",
                                           "pt-legislativo")) {
  preset <- match.arg(preset)

  base <- if (preset == "empty") {
    character(0)
  } else {
    .ac_get_stopwords(preset)
  }

  if (!is.null(add)) {
    if (!is.character(add))
      cli::cli_abort("{.arg add} deve ser um vetor {.cls character}.")
    base <- unique(c(base, add))
  }

  if (!is.null(remove)) {
    if (!is.character(remove))
      cli::cli_abort("{.arg remove} deve ser um vetor {.cls character}.")
    base <- base[!base %in% remove]
  }

  base
}


# ============================================================================
# Normalização ortográfica PT-BR
# ============================================================================

#' @keywords internal
#' @noRd
.ac_normalize_pt <- function(txt) {
  subs <- list(
    c("\\bpra\\b",      "para"),
    c("\\bpras\\b",     "para as"),
    c("\\bpro\\b",      "para o"),
    c("\\bpros\\b",     "para os"),
    c("\\bta\\b",       "esta"),
    c("\\bt\u00e1\\b",  "est\u00e1"),
    c("\\btao\\b",      "estao"),
    c("\\bt\u00e3o\\b", "est\u00e3o"),
    c("\\bvc\\b",       "voce"),
    c("\\bvcs\\b",      "voces"),
    c("\\btb\\b",       "tambem"),
    c("\\btbm\\b",      "tambem"),
    c("\\bneh\\b",      "ne"),
    c("\\bn\u00e9\\b",  "nao e")
  )
  for (s in subs) {
    txt <- stringr::str_replace_all(txt, s[1], s[2])
  }
  txt
}
