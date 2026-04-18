#' Importar arquivos para um corpus acR
#'
#' @description
#' Importa arquivos de texto em diferentes formatos (PDF, Word, Excel, CSV,
#' TXT, JSON, imagens com OCR) e retorna diretamente um objeto `ac_corpus`.
#' Suporta caminhos individuais, vetores de arquivos e globs (`dados/*.pdf`).
#'
#' @param path Caminho para um arquivo, vetor de arquivos ou glob
#'   (ex: `'dados/*.docx'`). Formatos suportados: `.pdf`, `.doc`, `.docx`,
#'   `.xlsx`, `.xls`, `.csv`, `.txt`, `.json`, `.png`, `.jpg`, `.jpeg`,
#'   `.tiff`.
#' @param text_field Nome da coluna que contem o texto, para arquivos
#'   tabulares (`.xlsx`, `.xls`, `.csv`). Obrigatorio nesses formatos.
#' @param lang_ocr Lingua para OCR em imagens e PDFs escaneados.
#'   Padrao: `'por'` (portugues). Use `tesseract::tesseract_info()` para
#'   ver linguas instaladas.
#' @param id_from Como gerar os IDs dos documentos. `'filename'` (padrao)
#'   usa o nome do arquivo sem extensao. `'rownum'` usa numeros sequenciais.
#'   Ou um vetor de strings com os IDs desejados.
#' @param ... Argumentos adicionais passados para `readtext::readtext()`.
#'
#' @return Um objeto `ac_corpus` pronto para uso com todas as funcoes do acR.
#'
#' @details
#' O `ac_import()` detecta automaticamente o formato pelo extension e
#' aciona o parser correto:
#'
#' - **PDF com texto selecionavel**: `readtext` + `pdftools`
#' - **PDF escaneado / imagem**: `tesseract` (OCR)
#' - **Word** (`.doc`, `.docx`): `readtext`
#' - **Excel** (`.xlsx`, `.xls`): `readtext` (requer `text_field`)
#' - **CSV**: `readtext` (requer `text_field`)
#' - **TXT / JSON**: `readtext`
#' - **Pasta inteira / glob**: todos os arquivos compativeis de uma vez
#'
#' **Dependencias opcionais**: `readtext` e `tesseract` nao sao importados
#' automaticamente — o `ac_import()` verifica se estao instalados e
#' orienta a instalacao caso necessario.
#'
#' @examples
#' \dontrun{
#' # PDF com texto selecionavel
#' corpus <- ac_import('relatorio.pdf')
#'
#' # Pasta inteira de Word
#' corpus <- ac_import('proposicoes/*.docx')
#'
#' # Excel — indicar a coluna de texto
#' corpus <- ac_import('respostas.xlsx', text_field = 'resposta')
#'
#' # PDF escaneado (OCR em portugues)
#' corpus <- ac_import('ata_manuscrita.pdf', lang_ocr = 'por')
#'
#' # Imagem (OCR)
#' corpus <- ac_import('captura.png')
#'
#' # Pasta mista (PDF + DOCX + TXT)
#' corpus <- ac_import('dados/*')
#' }
#'
#' @seealso [ac_corpus()], [ac_clean()], [ac_tokenize()]
#'
#' @references
#' Benoit, K., et al. (2018). readtext: Import and Handling for Plain and
#' Formatted Text Files. R package.
#' <https://CRAN.R-project.org/package=readtext>
#'
#' Ooms, J. (2024). tesseract: Open Source OCR Engine. R package.
#' <https://CRAN.R-project.org/package=tesseract>
#'
#' @importFrom tools file_ext file_path_sans_ext
#' @export
ac_import <- function(path,
                      text_field = NULL,
                      lang_ocr   = 'por',
                      id_from    = 'filename',
                      ...) {

  # ── verificar dependencias ──────────────────────────────────────────────
  .check_pkg <- function(pkg) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
      stop(
        'Pacote necessario nao instalado: ', pkg, '\n',
        'Instale com: install.packages("', pkg, '")',
        call. = FALSE
      )
    }
  }

  # ── detectar extensoes dos arquivos ────────────────────────────────────
  arquivos <- Sys.glob(path)
  if (length(arquivos) == 0) arquivos <- path

  exts <- unique(tolower(tools::file_ext(arquivos)))

  formatos_ocr    <- c('png', 'jpg', 'jpeg', 'tiff', 'bmp', 'gif')
  formatos_texto  <- c('pdf', 'doc', 'docx', 'xlsx', 'xls',
                       'csv', 'txt', 'json', 'odt', 'rtf')

  e_ocr   <- any(exts %in% formatos_ocr)
  e_texto <- any(exts %in% formatos_texto)

  textos <- character(0)
  ids    <- character(0)

  # ── branch OCR (imagens e PDFs escaneados) ──────────────────────────────
  if (e_ocr) {
    .check_pkg('tesseract')
    arq_ocr <- arquivos[tolower(tools::file_ext(arquivos)) %in% formatos_ocr]
    engine  <- tesseract::tesseract(lang_ocr)
    for (a in arq_ocr) {
      t <- paste(tesseract::ocr(a, engine = engine), collapse = ' ')
      textos <- c(textos, t)
      ids    <- c(ids, tools::file_path_sans_ext(basename(a)))
    }
  }

  # ── branch readtext (todos os formatos de texto) ────────────────────────
  if (e_texto) {
    .check_pkg('readtext')
    arq_txt <- arquivos[tolower(tools::file_ext(arquivos)) %in% formatos_texto]

    args <- list(file = arq_txt, ...)
    if (!is.null(text_field)) args$text_field <- text_field

    rt      <- do.call(readtext::readtext, args)
    textos  <- c(textos, rt$text)
    ids_rt  <- tools::file_path_sans_ext(basename(rt$doc_id))
    ids     <- c(ids, ids_rt)
  }

  if (length(textos) == 0) {
    stop(
      'Nenhum arquivo compativel encontrado em: ', path, '\n',
      'Formatos suportados: pdf, doc, docx, xlsx, xls, csv, txt, ',
      'json, odt, rtf, png, jpg, jpeg, tiff',
      call. = FALSE
    )
  }

  # ── gerar IDs ───────────────────────────────────────────────────────────
  ids_finais <- if (is.character(id_from) && length(id_from) > 1) {
    if (length(id_from) != length(textos))
      stop('`id_from` deve ter o mesmo comprimento que o numero de arquivos.',
           call. = FALSE)
    id_from
  } else if (id_from == 'rownum') {
    paste0('doc_', seq_along(textos))
  } else {
    ids
  }

  # ── retornar ac_corpus ───────────────────────────────────────────────────
  ac_corpus(textos, id = ids_finais)
}
