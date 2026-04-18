# Importar arquivos para um corpus acR

Importa arquivos de texto em diferentes formatos (PDF, Word, Excel, CSV,
TXT, JSON, imagens com OCR) e retorna diretamente um objeto `ac_corpus`.
Suporta caminhos individuais, vetores de arquivos e globs
(`dados/*.pdf`).

## Usage

``` r
ac_import(path, text_field = NULL, lang_ocr = "por", id_from = "filename", ...)
```

## Arguments

- path:

  Caminho para um arquivo, vetor de arquivos ou glob (ex:
  `'dados/*.docx'`). Formatos suportados: `.pdf`, `.doc`, `.docx`,
  `.xlsx`, `.xls`, `.csv`, `.txt`, `.json`, `.png`, `.jpg`, `.jpeg`,
  `.tiff`.

- text_field:

  Nome da coluna que contem o texto, para arquivos tabulares (`.xlsx`,
  `.xls`, `.csv`). Obrigatorio nesses formatos.

- lang_ocr:

  Lingua para OCR em imagens e PDFs escaneados. Padrao: `'por'`
  (portugues). Use
  [`tesseract::tesseract_info()`](https://docs.ropensci.org/tesseract/reference/tesseract.html)
  para ver linguas instaladas.

- id_from:

  Como gerar os IDs dos documentos. `'filename'` (padrao) usa o nome do
  arquivo sem extensao. `'rownum'` usa numeros sequenciais. Ou um vetor
  de strings com os IDs desejados.

- ...:

  Argumentos adicionais passados para
  [`readtext::readtext()`](https://readtext.quanteda.io/reference/readtext.html).

## Value

Um objeto `ac_corpus` pronto para uso com todas as funcoes do acR.

## Details

O `ac_import()` detecta automaticamente o formato pelo extension e
aciona o parser correto:

- **PDF com texto selecionavel**: `readtext` + `pdftools`

- **PDF escaneado / imagem**: `tesseract` (OCR)

- **Word** (`.doc`, `.docx`): `readtext`

- **Excel** (`.xlsx`, `.xls`): `readtext` (requer `text_field`)

- **CSV**: `readtext` (requer `text_field`)

- **TXT / JSON**: `readtext`

- **Pasta inteira / glob**: todos os arquivos compativeis de uma vez

**Dependencias opcionais**: `readtext` e `tesseract` nao sao importados
automaticamente — o `ac_import()` verifica se estao instalados e orienta
a instalacao caso necessario.

## References

Benoit, K., et al. (2018). readtext: Import and Handling for Plain and
Formatted Text Files. R package.
<https://CRAN.R-project.org/package=readtext>

Ooms, J. (2024). tesseract: Open Source OCR Engine. R package.
<https://CRAN.R-project.org/package=tesseract>

## See also

[`ac_corpus()`](https://andersonheri.github.io/acR/reference/ac_corpus.md),
[`ac_clean()`](https://andersonheri.github.io/acR/reference/ac_clean.md),
[`ac_tokenize()`](https://andersonheri.github.io/acR/reference/ac_tokenize.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# PDF com texto selecionavel
corpus <- ac_import('relatorio.pdf')

# Pasta inteira de Word
corpus <- ac_import('proposicoes/*.docx')

# Excel — indicar a coluna de texto
corpus <- ac_import('respostas.xlsx', text_field = 'resposta')

# PDF escaneado (OCR em portugues)
corpus <- ac_import('ata_manuscrita.pdf', lang_ocr = 'por')

# Imagem (OCR)
corpus <- ac_import('captura.png')

# Pasta mista (PDF + DOCX + TXT)
corpus <- ac_import('dados/*')
} # }
```
