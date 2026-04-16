#' Limpar e normalizar texto de um corpus
#'
#' @description
#' `ac_clean()` aplica um conjunto configurável de transformações ao texto de
#' um objeto `ac_corpus`, retornando um novo corpus com o texto modificado.
#' As transformações são aplicadas em ordem lógica (URLs e emails antes de
#' pontuação, etc.) e registradas como atributo para auditoria.
#'
#' @param corpus Objeto de classe `ac_corpus`, tipicamente criado por
#'   [ac_corpus()].
#' @param lower Se `TRUE` (padrão), converte texto para minúsculas.
#' @param remove_punct Se `TRUE` (padrão), remove pontuação.
#' @param remove_numbers Se `TRUE`, remove dígitos. Padrão: `FALSE`.
#' @param remove_url Se `TRUE` (padrão), remove URLs (http, https, www).
#' @param remove_email Se `TRUE` (padrão), remove endereços de e-mail.
#' @param remove_symbols Se `TRUE`, remove símbolos e emojis (@, #, \*, etc.).
#'   Padrão: `FALSE`. Cuidado: hashtags e menções podem ser informativas.
#' @param remove_stopwords Pode ser:
#'   * `NULL` (padrão): não remove stopwords;
#'   * uma string com nome de preset (`"pt"`, `"pt-br-extended"`,
#'     `"pt-legislativo"`);
#'   * um vetor `character` com stopwords customizadas.
#' @param remove_accents Se `TRUE`, remove acentos (ex: "ação" vira "acao").
#'   Padrão: `FALSE`. Útil para certas análises quantitativas, mas descaracteriza
#'   o texto para análise qualitativa.
#' @param normalize_pt Se `TRUE`, aplica normalizações ortográficas do português
#'   brasileiro coloquial: `"pra"` → `"para"`, `"pro"` → `"para o"`,
#'   `"tá"` → `"está"`, etc. Padrão: `FALSE`.
#' @param protect Vetor `character` com termos a preservar exatamente como estão
#'   (ignora `lower`, `remove_punct`, `remove_stopwords` para esses termos).
#'   Útil para siglas políticas (`c("PT", "PSDB", "CCJ")`). Padrão: `NULL`.
#' @param strip_whitespace Se `TRUE` (padrão e sempre aplicado ao final),
#'   colapsa espaços consecutivos e remove espaços no início/fim.
#' @param ... Ignorado com aviso se houver argumentos não reconhecidos.
#'
#' @return Um novo objeto `ac_corpus` com a coluna `text` transformada e o
#'   atributo `cleaning_steps` registrando as operações aplicadas em ordem.
#'
#' @details
#' **Ordem de aplicação** das transformações:
#'
#' 1. Proteção de termos (`protect`): substitui termos por placeholders
#' 2. Remoção de URLs e emails
#' 3. Remoção de símbolos (se ativado)
#' 4. `lower` (minúsculas)
#' 5. `remove_accents`
#' 6. `normalize_pt`
#' 7. `remove_numbers`
#' 8. `remove_punct`
#' 9. `remove_stopwords`
#' 10. Restauração dos termos protegidos
#' 11. `strip_whitespace` (sempre)
#'
#' **Sobre stopwords**: a remoção é feita por *palavras inteiras* (delimitadas
#' por fronteiras), não por substring. Isso evita que remover `"em"` corte
#' `"embora"`.
#'
#' **Sobre termos protegidos**: durante a limpeza, termos em `protect` são
#' substituídos por placeholders internos inacessíveis às demais transformações
#' e restaurados ao final com case original.
#'
#' @examples
#' df <- data.frame(
#'   id = c("a", "b", "c"),
#'   texto = c(
#'     "O deputado do PT disse: 'Defendo a CCJ!' Veja em https://exemplo.org",
#'     "Sra. presidente, o Sr. senador apresentou o requerimento n\u00ba 123.",
#'     "Tá na hora de votar, pra acabar com isso."
#'   )
#' )
#' corpus <- ac_corpus(df, text = texto, docid = id)
#'
#' # Limpeza básica
#' ac_clean(corpus)
#'
#' # Limpeza agressiva com stopwords legislativas e proteção de siglas
#' ac_clean(
#'   corpus,
#'   remove_stopwords = "pt-legislativo",
#'   protect = c("PT", "CCJ"),
#'   normalize_pt = TRUE
#' )
#'
#' @seealso [ac_corpus()] para construir o corpus de entrada.
#' @concept corpus
#' @export
ac_clean <- function(corpus,
                     lower            = TRUE,
                     remove_punct     = TRUE,
                     remove_numbers   = FALSE,
                     remove_url       = TRUE,
                     remove_email     = TRUE,
                     remove_symbols   = FALSE,
                     remove_stopwords = NULL,
                     remove_accents   = FALSE,
                     normalize_pt     = FALSE,
                     protect          = NULL,
                     strip_whitespace = TRUE,
                     ...) {

  # === Validações =========================================================
  if (!is_ac_corpus(corpus)) {
    cli::cli_abort(c(
      "{.arg corpus} deve ser um objeto {.cls ac_corpus}.",
      "i" = "Crie com {.fn ac_corpus}.",
      "x" = "Recebido: {.cls {class(corpus)[1]}}."
    ))
  }

  if (!requireNamespace("stringr", quietly = TRUE)) {
    cli::cli_abort("O pacote {.pkg stringr} \u00e9 necess\u00e1rio. Instale com {.code install.packages(\"stringr\")}.")
  }
  if (!requireNamespace("stringi", quietly = TRUE)) {
    cli::cli_abort("O pacote {.pkg stringi} \u00e9 necess\u00e1rio. Instale com {.code install.packages(\"stringi\")}.")
  }

  # Avisar sobre argumentos extras
  dots <- list(...)
  if (length(dots) > 0) {
    cli::cli_warn("Argumento{?s} ignorado{?s}: {.val {names(dots)}}.")
  }

  # === Preparar vetor de texto e registro de passos =======================
  txt <- corpus$text
  steps <- character(0)

  # === 1. Proteção de termos =============================================
  protected_map <- NULL
  if (!is.null(protect) && length(protect) > 0) {
    if (!is.character(protect)) {
      cli::cli_abort("{.arg protect} deve ser um vetor {.cls character}.")
    }
    # Gerar placeholders únicos: __ACPROTECT_001__, __ACPROTECT_002__, ...
    placeholders <- sprintf("__ACPROTECT_%03d__", seq_along(protect))
    protected_map <- stats::setNames(protect, placeholders)
    # Substituir no texto (case-sensitive, palavra inteira quando possível)
    for (i in seq_along(protect)) {
      pattern <- paste0("\\b", stringr::str_escape(protect[i]), "\\b")
      txt <- stringr::str_replace_all(txt, pattern, placeholders[i])
    }
    steps <- c(steps, paste0("protect(", length(protect), " termos)"))
  }

  # === 2. URLs =============================================================
  if (isTRUE(remove_url)) {
    # Padrão robusto: http(s)://, www., e domínios com path
    url_pattern <- "\\b(?:https?://|www\\.)\\S+"
    txt <- stringr::str_replace_all(txt, url_pattern, " ")
    steps <- c(steps, "remove_url")
  }

  # === 3. Emails ===========================================================
  if (isTRUE(remove_email)) {
    email_pattern <- "\\b[[:alnum:]._%+-]+@[[:alnum:].-]+\\.[[:alpha:]]{2,}\\b"
    txt <- stringr::str_replace_all(txt, email_pattern, " ")
    steps <- c(steps, "remove_email")
  }

  # === 4. Símbolos =========================================================
  if (isTRUE(remove_symbols)) {
    # Remove emojis e símbolos não-ASCII, mas preserva letras acentuadas
    # Range de emojis (plano suplementar Unicode) + símbolos comuns
    txt <- stringi::stri_replace_all_regex(txt, "[\\p{So}\\p{Sk}\\p{Sm}]", " ")
    steps <- c(steps, "remove_symbols")
  }

  # === 5. Lowercase ========================================================
  if (isTRUE(lower)) {
    txt <- stringr::str_to_lower(txt, locale = "pt")
    # Restaurar case dos placeholders (lowercase os quebrou)
    if (!is.null(protected_map)) {
      for (ph in names(protected_map)) {
        txt <- stringr::str_replace_all(txt, tolower(ph), ph)
      }
    }
    steps <- c(steps, "lower")
  }

  # === 6. Acentos ==========================================================
  if (isTRUE(remove_accents)) {
    txt <- stringi::stri_trans_general(txt, "Latin-ASCII")
    steps <- c(steps, "remove_accents")
  }

  # === 7. Normalização PT-BR ==============================================
  if (isTRUE(normalize_pt)) {
    txt <- .ac_normalize_pt(txt)
    steps <- c(steps, "normalize_pt")
  }

  # === 8. Números ==========================================================
  if (isTRUE(remove_numbers)) {
    txt <- stringr::str_replace_all(txt, "\\d+", " ")
    steps <- c(steps, "remove_numbers")
  }

  # === 9. Pontuação =======================================================
  if (isTRUE(remove_punct)) {
    # Preservar placeholders (que contêm __): substituir só pontuação "real"
    # Usa regex Unicode para pontuação
    txt <- stringi::stri_replace_all_regex(txt, "[\\p{P}&&[^_]]", " ")
    steps <- c(steps, "remove_punct")
  }

  # === 10. Stopwords ======================================================
  if (!is.null(remove_stopwords)) {
    if (is.character(remove_stopwords) && length(remove_stopwords) == 1 &&
        remove_stopwords %in% c("pt", "pt-br-extended", "pt-legislativo")) {
      # É um preset
      stopword_vec <- .ac_get_stopwords(remove_stopwords)
      steps <- c(steps, paste0("remove_stopwords(preset=", remove_stopwords, ")"))
    } else if (is.character(remove_stopwords)) {
      # É um vetor customizado
      stopword_vec <- remove_stopwords
      steps <- c(steps, paste0("remove_stopwords(custom=", length(stopword_vec), ")"))
    } else {
      cli::cli_abort(
        "{.arg remove_stopwords} deve ser {.code NULL}, string de preset, ou vetor {.cls character}."
      )
    }

    if (length(stopword_vec) > 0) {
      # Remover por palavra inteira (fronteira \\b)
      # Escapar metacaracteres nas stopwords
      escaped <- stringr::str_escape(stopword_vec)
      pattern <- paste0("\\b(?:", paste(escaped, collapse = "|"), ")\\b")
      txt <- stringr::str_replace_all(txt, pattern, " ")
    }
  }

  # === 11. Restaurar termos protegidos ===================================
  if (!is.null(protected_map)) {
    for (ph in names(protected_map)) {
      txt <- stringr::str_replace_all(txt, ph, protected_map[[ph]])
    }
  }

  # === 12. Whitespace (sempre) ===========================================
  if (isTRUE(strip_whitespace)) {
    txt <- stringr::str_squish(txt)
    # str_squish já faz trim + colapso, sem duplicar registro
    if (!"strip_whitespace" %in% steps) {
      steps <- c(steps, "strip_whitespace")
    }
  }

  # === Montar resultado ===================================================
  result <- corpus
  result$text <- txt
  attr(result, "cleaning_steps") <- steps
  # Preservar classe e demais atributos
  if (!inherits(result, "ac_corpus")) {
    class(result) <- c("ac_corpus", class(result))
  }
  result
}


# ============================================================================
# Normalização ortográfica PT-BR (função auxiliar)
# ============================================================================

#' @keywords internal
#' @noRd
.ac_normalize_pt <- function(txt) {
  # Pares (regex, substituição) aplicados por palavra inteira
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
