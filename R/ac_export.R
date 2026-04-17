#' Exporta resultados de analise de conteudo em multiplos formatos
#'
#' @description
#' Exporta data.frames de resultados (corpus codificado, tabelas de frequencia,
#' metricas de confiabilidade) para CSV, LaTeX, Excel (.xlsx) ou RDS.
#' Pensada para facilitar a transicao entre o pipeline `acR` e a escrita
#' academica (tabelas em artigos) ou o compartilhamento de dados replicaveis.
#'
#' @param x `data.frame` ou objeto `ac_irr`. Dados a exportar.
#' @param path `character`. Caminho do arquivo de saida, incluindo extensao
#'   (ex.: `"resultados.csv"`, `"tabela1.tex"`, `"dados.xlsx"`). Se `NULL`,
#'   o formato e inferido pelo argumento `format` e o arquivo e salvo no
#'   diretorio de trabalho com nome `"acR_export"`.
#' @param format `character`. Formato de saida: `"csv"`, `"latex"`, `"xlsx"`,
#'   `"rds"`. Se `NULL` (padrao), inferido pela extensao de `path`.
#' @param overwrite `logical`. Se `TRUE` (padrao), sobrescreve arquivo
#'   existente. Se `FALSE`, lanca erro se o arquivo ja existir.
#' @param latex_caption `character` ou `NULL`. Legenda da tabela LaTeX.
#' @param latex_label `character` ou `NULL`. Label para `\\ref{}` no LaTeX.
#'   Ex.: `"tab:resultados"`.
#' @param latex_digits `integer`. Casas decimais para colunas numericas
#'   na saida LaTeX. Padrao: `3`.
#' @param excel_sheet `character`. Nome da aba no arquivo Excel.
#'   Padrao: `"acR"`.
#' @param verbose `logical`. Se `TRUE` (padrao), confirma o caminho salvo.
#'
#' @return Invisivel: o caminho do arquivo salvo (`character`).
#'
#' @details
#' ## CSV
#' Usa [utils::write.csv()] com `row.names = FALSE` e encoding UTF-8.
#' Separador: virgula. Adequado para importacao em Stata, SPSS, Python e R.
#'
#' ## LaTeX
#' Gera codigo LaTeX via [knitr::kable()] com `format = "latex"`, empacotado
#' em ambiente `table` com `\\centering`, `\\caption` e `\\label`. Adicione
#' `\\usepackage{booktabs}` no preambulo do documento para melhor tipografia.
#'
#' ## Excel
#' Usa [writexl::write_xlsx()] — sem dependencia de Java ou LibreOffice.
#' Cria arquivo `.xlsx` compativel com Excel 2007+, Google Sheets e
#' LibreOffice Calc.
#'
#' ## RDS
#' Serializa o objeto R completo via [base::saveRDS()]. Preserva tipos,
#' atributos e classes (incluindo objetos `ac_irr`, corpus etc.).
#' Ideal para replicabilidade interna ao projeto.
#'
#' @examples
#' \dontrun{
#' resultados <- data.frame(
#'   id_discurso  = c("d1", "d2", "d3"),
#'   nome_deputado = c("Dep. A", "Dep. B", "Dep. C"),
#'   categoria    = c("progressista", "conservador", "tecnocratico"),
#'   confianca    = c(0.94, 0.91, 0.87)
#' )
#'
#' # CSV
#' ac_export(resultados, "resultados_discursos.csv")
#'
#' # LaTeX (para incluir em artigo)
#' ac_export(
#'   resultados,
#'   "tabela_resultados.tex",
#'   latex_caption = "Classificacao do tom dos discursos por LLM",
#'   latex_label   = "tab:tom_discursos"
#' )
#'
#' # Excel
#' ac_export(resultados, "resultados.xlsx", excel_sheet = "Classificacao")
#'
#' # RDS (replicabilidade)
#' ac_export(resultados, "resultados.rds")
#'
#' # Objeto ac_irr
#' irr_result <- ac_qual_irr(gold, predicted, verbose = FALSE)
#' ac_export(irr_result, "confiabilidade.csv")
#' }
#'
#' @seealso [ac_qual_irr()], [ac_qual_code()]
#'
#' @export
ac_export <- function(
    x,
    path          = NULL,
    format        = NULL,
    overwrite     = TRUE,
    latex_caption = NULL,
    latex_label   = NULL,
    latex_digits  = 3L,
    excel_sheet   = "acR",
    verbose       = TRUE
) {
  # --- 1. Converter ac_irr para data.frame se necessario ----------------------
  if (inherits(x, "ac_irr")) {
    x <- x$metrics
  }

  if (!is.data.frame(x)) {
    cli::cli_abort(
      "{.arg x} deve ser um data.frame ou objeto {.cls ac_irr}. \\
       Recebido: {.cls {class(x)}}."
    )
  }

  # --- 2. Resolver formato e caminho ------------------------------------------
  format <- .export_resolve_format(path, format)
  path   <- .export_resolve_path(path, format)

  if (!overwrite && file.exists(path)) {
    cli::cli_abort(
      "Arquivo ja existe: {.path {path}}. \\
       Use {.code overwrite = TRUE} para sobrescrever."
    )
  }

  # Garantir que o diretorio existe
  dir.create(dirname(path), showWarnings = FALSE, recursive = TRUE)

  # --- 3. Exportar ------------------------------------------------------------
  switch(
    format,
    csv   = .export_csv(x, path),
    latex = .export_latex(x, path, latex_caption, latex_label, latex_digits),
    xlsx  = .export_xlsx(x, path, excel_sheet),
    rds   = .export_rds(x, path)
  )

  if (verbose) {
    cli::cli_alert_success(
      "Exportado para {.path {path}} ({format})."
    )
  }

  invisible(path)
}


# =============================================================================
# Helpers internos de exportacao
# =============================================================================

#' @noRd
.export_resolve_format <- function(path, format) {
  if (!is.null(format)) {
    return(match.arg(format, c("csv", "latex", "xlsx", "rds")))
  }
  if (!is.null(path)) {
    ext <- tolower(tools::file_ext(path))
    fmt <- switch(ext,
      csv  = "csv",
      tex  = "latex",
      xlsx = "xlsx",
      rds  = "rds",
      NULL
    )
    if (!is.null(fmt)) return(fmt)
  }
  cli::cli_abort(
    "Nao foi possivel inferir o formato. Especifique {.arg format} ou \\
     use uma extensao reconhecida em {.arg path}: .csv, .tex, .xlsx, .rds"
  )
}

#' @noRd
.export_resolve_path <- function(path, format) {
  if (!is.null(path)) return(path)
  ext <- switch(format,
    csv   = "csv",
    latex = "tex",
    xlsx  = "xlsx",
    rds   = "rds"
  )
  file.path(getwd(), paste0("acR_export.", ext))
}

#' @noRd
.export_csv <- function(x, path) {
  utils::write.csv(x, file = path, row.names = FALSE, fileEncoding = 'UTF-8')
}



#' @noRd
.export_latex <- function(x, path, caption, label, digits) {
  .check_pkg("knitr", "ac_export (formato latex)")

  # Arredondar colunas numericas
  num_cols <- sapply(x, is.numeric)
  x[num_cols] <- lapply(x[num_cols], round, digits = digits)

  tbl <- knitr::kable(
    x,
    format    = "latex",
    booktabs  = TRUE,
    caption   = caption,
    label     = label,
    linesep   = ""
  )

  # Empacotar em ambiente table completo
  lines <- c(
    "\\begin{table}[htbp]",
    "  \\centering",
    as.character(tbl),
    "\\end{table}"
  )

  writeLines(lines, path)
}

#' @noRd
.export_xlsx <- function(x, path, sheet) {
  .check_pkg("writexl", "ac_export (formato xlsx)")
  sheets <- stats::setNames(list(x), sheet)
  writexl::write_xlsx(sheets, path = path)
}

#' @noRd
.export_rds <- function(x, path) {
  saveRDS(x, file = path)
}
