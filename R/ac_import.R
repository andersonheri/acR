#' Importar arquivos para um corpus acR
#'
#' @description
#' Importa arquivos de texto em diferentes formatos (PDF, Word, Excel, CSV,
#' TXT, JSON, imagens com OCR) e retorna diretamente um objeto `ac_corpus`.
#' Suporta caminhos individuais, vetores de arquivos e globs (`dados/*.pdf`).
#'
#' É a **via de entrada principal** do pipeline quando você trabalha com
#' arquivos em disco (relatórios, transcrições, PDFs escaneados). Faz o
#' que `ac_corpus()` faria a partir de um `data.frame`, mas cobrindo o
#' passo anterior: extração de texto de formatos heterogêneos com detecção
#' automática pelo sufixo do arquivo. Para PDFs escaneados e imagens,
#' aciona OCR via `tesseract` com português como padrão.
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
#' A ordem dos documentos no corpus resultante segue a ordem de entrada em
#' `path` (ou a ordem alfabetica retornada por `Sys.glob()`), independente
#' de o parser ser OCR ou readtext. IDs duplicados (dois arquivos com o
#' mesmo `basename`) sao desambiguados automaticamente com um sufixo `_2`,
#' `_3`, ... e um aviso e emitido.
#'
#' **Dependencias opcionais**: `readtext` e `tesseract` nao sao importados
#' automaticamente -- o `ac_import()` verifica se estao instalados e
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
#' # Excel -- indicar a coluna de texto
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

  # -- verificar dependencias -----------------------------------------------
  .check_pkg <- function(pkg) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
      cli::cli_abort(c(
        "Pacote {.pkg {pkg}} necessario mas nao instalado.",
        "i" = "Instale com {.code install.packages(\"{pkg}\")}."
      ))
    }
  }

  # -- expandir globs preservando a ordem de entrada ------------------------
  arquivos <- unlist(lapply(path, function(p) {
    m <- Sys.glob(p)
    if (length(m) == 0L) p else m
  }), use.names = FALSE)

  exts <- tolower(tools::file_ext(arquivos))

  formatos_ocr    <- c('png', 'jpg', 'jpeg', 'tiff', 'bmp', 'gif')
  formatos_texto  <- c('pdf', 'doc', 'docx', 'xlsx', 'xls',
                       'csv', 'txt', 'json', 'odt', 'rtf')

  is_ocr   <- exts %in% formatos_ocr
  is_texto <- exts %in% formatos_texto

  if (!any(is_ocr | is_texto)) {
    cli::cli_abort(c(
      "Nenhum arquivo compativel encontrado em: {.path {path}}.",
      "i" = paste0(
        "Formatos suportados: ",
        paste(c(formatos_texto, formatos_ocr), collapse = ', '), "."
      )
    ))
  }

  # -- processar cada arquivo mantendo a ordem original ---------------------
  # (OCR item-a-item; texto em lote com readtext, depois reordenado)
  textos <- character(length(arquivos))
  ids    <- character(length(arquivos))

  if (any(is_ocr)) {
    .check_pkg('tesseract')
    engine <- tesseract::tesseract(lang_ocr)
    idx_ocr <- which(is_ocr)
    cli::cli_progress_bar(
      "Executando OCR",
      total = length(idx_ocr),
      clear = TRUE
    )
    for (i in idx_ocr) {
      textos[i] <- paste(tesseract::ocr(arquivos[i], engine = engine),
                         collapse = ' ')
      ids[i]    <- tools::file_path_sans_ext(basename(arquivos[i]))
      cli::cli_progress_update()
    }
    cli::cli_progress_done()
  }

  if (any(is_texto)) {
    .check_pkg('readtext')
    arq_txt <- arquivos[is_texto]

    args <- list(file = arq_txt, ...)
    if (!is.null(text_field)) args$text_field <- text_field

    rt <- do.call(readtext::readtext, args)

    # readtext pode reordenar; realinhar pela chave basename
    key_rt   <- tools::file_path_sans_ext(basename(rt$doc_id))
    key_want <- tools::file_path_sans_ext(basename(arq_txt))
    ord <- match(key_want, key_rt)
    if (anyNA(ord)) {
      cli::cli_warn(
        "Alguns arquivos foram descartados por {.pkg readtext} (formato invalido?)."
      )
      ord <- ord[!is.na(ord)]
    }

    idx_texto <- which(is_texto)[seq_along(ord)]
    textos[idx_texto] <- rt$text[ord]
    ids[idx_texto]    <- key_rt[ord]
  }

  # -- filtrar posicoes descartadas -----------------------------------------
  keep <- nzchar(ids)
  textos <- textos[keep]
  ids    <- ids[keep]

  if (length(textos) == 0L) {
    cli::cli_abort("Nenhum documento foi importado com sucesso.")
  }

  # -- gerar IDs finais -----------------------------------------------------
  ids_finais <- if (is.character(id_from) && length(id_from) != 1L) {
    if (length(id_from) != length(textos)) {
      cli::cli_abort(
        "{.arg id_from} deve ter o mesmo comprimento que o numero de arquivos importados ({length(textos)})."
      )
    }
    id_from
  } else if (identical(id_from, 'rownum')) {
    paste0('doc_', seq_along(textos))
  } else {
    ids
  }

  # -- desambiguar IDs duplicados -------------------------------------------
  if (anyDuplicated(ids_finais)) {
    dup <- ids_finais[duplicated(ids_finais)]
    cli::cli_warn(c(
      "IDs duplicados detectados; adicionando sufixos {.val _2}, {.val _3}, ...",
      "i" = "IDs afetados: {.val {unique(dup)}}."
    ))
    ids_finais <- make.unique(ids_finais, sep = '_')
  }

  # -- retornar ac_corpus ----------------------------------------------------
  ac_corpus(
    data.frame(doc_id = ids_finais, text = textos, stringsAsFactors = FALSE),
    text  = text,
    docid = doc_id
  )

}
