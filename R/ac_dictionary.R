#' Classificar conteúdo com um dicionário multi-categoria
#'
#' @description
#' `ac_dictionary()` conta, para cada documento de um `ac_corpus`,
#' quantas palavras caem em cada categoria de um dicionário —
#' generalização do método que [ac_sentiment()] já aplica só para
#' polaridade (positivo/negativo). Um dicionário aqui é qualquer lista
#' nomeada de listas de palavras: temas ("economia", "saúde"),
#' enquadramentos ("ameaça", "oportunidade"), categorias de produto, ou
#' qualquer taxonomia definida a priori pelo pesquisador.
#'
#' Métodos de dicionário são o método mais antigo e mais transparente de
#' análise de conteúdo assistida por computador (Stone et al., 1966,
#' *The General Inquirer*; revisado em Grimmer & Stewart, 2013): toda
#' decisão de classificação é auditável — basta olhar a lista de
#' palavras. O preço é a falta de sensibilidade a contexto: a palavra
#' "não" imediatamente antes de um termo do dicionário não inverte a
#' contagem, e sarcasmo ou negação sofisticada passam batido. Para esses
#' casos, o pipeline de LLM ([ac_qual_code()]) é a alternativa — mais
#' caro, menos transparente, mas sensível a contexto.
#'
#' @param corpus Objeto `ac_corpus`.
#' @param dictionary Lista nomeada de vetores de caracteres — uma
#'   entrada por categoria, cada uma com as palavras daquela categoria
#'   (ver [ac_build_dictionary()]). Palavras são comparadas a tokens
#'   individuais (correspondência exata, não substring).
#' @param by Coluna(s) de agrupamento para agregar além do documento
#'   (ex.: `"categoria_produto"`). Padrão: `NULL` (uma linha por
#'   documento).
#' @param case_insensitive Lógico. Se `TRUE` (padrão), ignora
#'   diferenças de maiúsculas/minúsculas na comparação.
#'
#' @return Tibble com uma linha por documento (ou grupo), contendo
#'   `total_tokens` e, para cada categoria do dicionário, duas colunas:
#'   `<categoria>_n` (contagem de palavras daquela categoria) e
#'   `<categoria>_prop` (proporção sobre `total_tokens`).
#'
#' @references
#' Stone, P. J.; Dunphy, D. C.; Smith, M. S.; Ogilvie, D. M. (1966).
#' *The General Inquirer: A Computer Approach to Content Analysis*. MIT
#' Press.
#'
#' Grimmer, J.; Stewart, B. M. (2013). Text as Data: The Promise and
#' Pitfalls of Automatic Content Analysis Methods for Political Texts.
#' *Political Analysis*, 21(3), 267-297.
#'
#' @examples
#' # Reclamacoes de clientes, categorizadas por tema do problema
#' df <- data.frame(
#'   id = paste0("c", 1:4),
#'   texto = c(
#'     "a entrega atrasou muito e o rastreio não funcionava",
#'     "o produto chegou com defeito e quebrado na caixa",
#'     "cobraram duas vezes no cartao e o reembolso demorou",
#'     "entrega rápida mas o produto tinha um defeito de fabrica"
#'   ),
#'   stringsAsFactors = FALSE
#' )
#' corpus <- ac_corpus(df, text = texto, docid = id)
#'
#' dict <- ac_build_dictionary(
#'   entrega    = c("entrega", "atrasou", "rastreio", "rápida"),
#'   produto    = c("defeito", "quebrado", "fabrica"),
#'   financeiro = c("cobraram", "cartao", "reembolso")
#' )
#'
#' ac_dictionary(corpus, dict)
#'
#' @seealso [ac_build_dictionary()], [ac_sentiment()], [ac_qual_code()]
#' @concept quantitative
#' @export
ac_dictionary <- function(corpus, dictionary, by = NULL, case_insensitive = TRUE) {
  if (!is_ac_corpus(corpus)) {
    cli::cli_abort("{.arg corpus} deve ser um {.cls ac_corpus}.")
  }
  .ac_validate_dictionary(dictionary)
  if (!requireNamespace("dplyr", quietly = TRUE)) {
    cli::cli_abort("O pacote {.pkg dplyr} \u00e9 necess\u00e1rio.")
  }

  tokens_tbl <- ac_tokenize(corpus, drop_punct = TRUE)
  cmp <- if (case_insensitive) tolower(tokens_tbl$token) else tokens_tbl$token

  cat_names <- names(dictionary)
  for (cat in cat_names) {
    termos <- dictionary[[cat]]
    if (case_insensitive) termos <- tolower(termos)
    tokens_tbl[[cat]] <- cmp %in% termos
  }

  if (is.null(by)) {
    group_cols <- "doc_id"
    base_tbl <- tokens_tbl
  } else {
    if (!all(by %in% names(corpus))) {
      cli::cli_abort(c(
        "{.arg by} cont\u00e9m nomes que n\u00e3o existem em {.arg corpus}.",
        "x" = "Nomes ausentes: {.val {setdiff(by, names(corpus))}}"
      ))
    }
    meta <- tibble::as_tibble(corpus)[, c("doc_id", by), drop = FALSE]
    base_tbl <- dplyr::left_join(tokens_tbl, meta, by = "doc_id")
    group_cols <- by
  }

  out <- base_tbl |>
    dplyr::group_by(dplyr::across(dplyr::all_of(group_cols))) |>
    dplyr::summarise(
      total_tokens = dplyr::n(),
      dplyr::across(dplyr::all_of(cat_names), sum, .names = "{.col}_n"),
      .groups = "drop"
    )

  for (cat in cat_names) {
    out[[paste0(cat, "_prop")]] <- out[[paste0(cat, "_n")]] / out$total_tokens
  }

  if (is.null(by)) {
    todos <- tibble::tibble(doc_id = corpus$doc_id)
    out <- dplyr::left_join(todos, out, by = "doc_id")
  }

  out
}


#' @keywords internal
#' @noRd
.ac_validate_dictionary <- function(dictionary) {
  if (!is.list(dictionary) || length(dictionary) == 0L) {
    cli::cli_abort("{.arg dictionary} deve ser uma lista nomeada n\u00e3o vazia.")
  }
  nomes <- names(dictionary)
  if (is.null(nomes) || any(nomes == "") || anyNA(nomes)) {
    cli::cli_abort("Todas as categorias de {.arg dictionary} devem ter nome.")
  }
  if (any(duplicated(nomes))) {
    cli::cli_abort("Nomes de categoria duplicados em {.arg dictionary}: {.val {nomes[duplicated(nomes)]}}")
  }
  vazios <- vapply(dictionary, function(x) length(x) == 0L, logical(1))
  if (any(vazios)) {
    cli::cli_abort("Categoria{?s} sem palavras em {.arg dictionary}: {.val {nomes[vazios]}}")
  }
  invisible(TRUE)
}


#' Construir um dicionário multi-categoria
#'
#' @description
#' `ac_build_dictionary()` monta um dicionário no formato esperado por
#' [ac_dictionary()] a partir de argumentos nomeados — cada argumento é
#' uma categoria, e seu valor é o vetor de palavras daquela categoria.
#'
#' @param ... Argumentos nomeados, cada um um vetor de caracteres.
#'
#' @return Lista nomeada de vetores de caracteres (um dicionário).
#'
#' @examples
#' dict <- ac_build_dictionary(
#'   positivo = c("bom", "ótimo", "excelente"),
#'   negativo = c("mau", "péssimo", "horrivel")
#' )
#' dict
#'
#' @seealso [ac_dictionary()], [ac_dictionary_import()],
#'   [ac_dictionary_save()]
#' @concept quantitative
#' @export
ac_build_dictionary <- function(...) {
  dictionary <- list(...)
  .ac_validate_dictionary(dictionary)
  dictionary <- lapply(dictionary, as.character)
  dictionary
}


#' Salvar ou carregar um dicionário em YAML
#'
#' @description
#' `ac_dictionary_save()` grava um dicionário (ver
#' [ac_build_dictionary()]) em um arquivo YAML legível por humanos, para
#' versionar, compartilhar entre pesquisadores ou editar fora do R.
#' `ac_dictionary_load()` faz o caminho inverso.
#'
#' @param dictionary Lista nomeada de vetores de caracteres.
#' @param path Caminho do arquivo `.yaml`.
#'
#' @return `ac_dictionary_save()`: o caminho do arquivo, de forma
#'   invisível. `ac_dictionary_load()`: o dicionário (lista nomeada de
#'   vetores de caracteres).
#'
#' @examples
#' dict <- ac_build_dictionary(
#'   positivo = c("bom", "ótimo"),
#'   negativo = c("mau", "péssimo")
#' )
#' arquivo <- tempfile(fileext = ".yaml")
#' ac_dictionary_save(dict, arquivo)
#'
#' dict2 <- ac_dictionary_load(arquivo)
#' identical(dict, dict2)
#'
#' @seealso [ac_build_dictionary()], [ac_dictionary_import()]
#' @concept quantitative
#' @export
ac_dictionary_save <- function(dictionary, path) {
  .ac_validate_dictionary(dictionary)
  if (!requireNamespace("yaml", quietly = TRUE)) {
    cli::cli_abort("O pacote {.pkg yaml} \u00e9 necess\u00e1rio.")
  }
  yaml::write_yaml(lapply(dictionary, as.list), path)
  invisible(path)
}


#' @rdname ac_dictionary_save
#' @export
ac_dictionary_load <- function(path) {
  if (!requireNamespace("yaml", quietly = TRUE)) {
    cli::cli_abort("O pacote {.pkg yaml} \u00e9 necess\u00e1rio.")
  }
  if (!file.exists(path)) {
    cli::cli_abort("Arquivo {.path {path}} n\u00e3o encontrado.")
  }
  dictionary <- yaml::read_yaml(path)
  dictionary <- lapply(dictionary, function(x) as.character(unlist(x)))
  .ac_validate_dictionary(dictionary)
  dictionary
}


#' Importar um dicionário de uma tabela em formato longo
#'
#' @description
#' `ac_dictionary_import()` constrói um dicionário (ver
#' [ac_build_dictionary()]) a partir de uma tabela em formato longo —
#' uma linha por par palavra-categoria — o formato em que léxicos
#' costumam ser distribuídos (CSV, planilha). Útil para importar listas
#' de palavras construídas fora do R, ou léxicos de terceiros já
#' traduzidos/adaptados para português (o pacote não distribui nenhum
#' léxico de categorias além do OpLexicon usado em [ac_sentiment()] —
#' veja `vignette("dicionários")` para onde encontrar léxicos de
#' terceiros e como adaptá-los a este formato).
#'
#' @param data Um `data.frame`/tibble em formato longo, ou o caminho de
#'   um arquivo `.csv` nesse formato.
#' @param term_col Nome da coluna com a palavra. Padrão: `"termo"`.
#' @param category_col Nome da coluna com a categoria. Padrão:
#'   `"categoria"`.
#' @param ... Argumentos adicionais passados a [utils::read.csv()]
#'   quando `data` é um caminho de arquivo (ex.: `sep`, `fileEncoding`).
#'
#' @return Lista nomeada de vetores de caracteres (um dicionário), uma
#'   entrada por valor distinto de `category_col`.
#'
#' @examples
#' lexico <- data.frame(
#'   termo     = c("bom", "ótimo", "mau", "péssimo"),
#'   categoria = c("positivo", "positivo", "negativo", "negativo"),
#'   stringsAsFactors = FALSE
#' )
#' ac_dictionary_import(lexico)
#'
#' @seealso [ac_build_dictionary()], [ac_dictionary_save()]
#' @concept quantitative
#' @export
ac_dictionary_import <- function(data,
                                  term_col     = "termo",
                                  category_col = "categoria",
                                  ...) {
  if (is.character(data) && length(data) == 1L) {
    if (!file.exists(data)) {
      cli::cli_abort("Arquivo {.path {data}} n\u00e3o encontrado.")
    }
    data <- utils::read.csv(data, stringsAsFactors = FALSE, ...)
  }
  if (!is.data.frame(data)) {
    cli::cli_abort("{.arg data} deve ser um data.frame/tibble ou caminho de arquivo CSV.")
  }
  if (!all(c(term_col, category_col) %in% names(data))) {
    cli::cli_abort(c(
      "{.arg data} deve conter as colunas {.val {term_col}} e {.val {category_col}}.",
      "i" = "Colunas dispon\u00edveis: {.val {names(data)}}."
    ))
  }

  termos <- as.character(data[[term_col]])
  cats   <- as.character(data[[category_col]])
  valid  <- !is.na(termos) & !is.na(cats) & nzchar(termos) & nzchar(cats)

  dictionary <- split(termos[valid], cats[valid])
  dictionary <- lapply(dictionary, unique)
  .ac_validate_dictionary(dictionary)
  dictionary
}
