# Exporta resultados de analise de conteudo em multiplos formatos

Exporta data.frames de resultados (corpus codificado, tabelas de
frequencia, metricas de confiabilidade) para CSV, LaTeX, Excel (.xlsx)
ou RDS. Pensada para facilitar a transicao entre o pipeline `acR` e a
escrita academica (tabelas em artigos) ou o compartilhamento de dados
replicaveis.

## Usage

``` r
ac_export(
  x,
  path = NULL,
  format = NULL,
  overwrite = TRUE,
  latex_caption = NULL,
  latex_label = NULL,
  latex_digits = 3L,
  excel_sheet = "acR",
  verbose = TRUE
)
```

## Arguments

- x:

  `data.frame` ou objeto `ac_irr`. Dados a exportar.

- path:

  `character`. Caminho do arquivo de saida, incluindo extensao (ex.:
  `"resultados.csv"`, `"tabela1.tex"`, `"dados.xlsx"`). Se `NULL`, o
  formato e inferido pelo argumento `format` e o arquivo e salvo no
  diretorio de trabalho com nome `"acR_export"`.

- format:

  `character`. Formato de saida: `"csv"`, `"latex"`, `"xlsx"`, `"rds"`.
  Se `NULL` (padrao), inferido pela extensao de `path`.

- overwrite:

  `logical`. Se `TRUE` (padrao), sobrescreve arquivo existente. Se
  `FALSE`, lanca erro se o arquivo ja existir.

- latex_caption:

  `character` ou `NULL`. Legenda da tabela LaTeX.

- latex_label:

  `character` ou `NULL`. Label para `\\ref{}` no LaTeX. Ex.:
  `"tab:resultados"`.

- latex_digits:

  `integer`. Casas decimais para colunas numericas na saida LaTeX.
  Padrao: `3`.

- excel_sheet:

  `character`. Nome da aba no arquivo Excel. Padrao: `"acR"`.

- verbose:

  `logical`. Se `TRUE` (padrao), confirma o caminho salvo.

## Value

Invisivel: o caminho do arquivo salvo (`character`).

## Details

### CSV

Usa [`utils::write.csv()`](https://rdrr.io/r/utils/write.table.html) com
`row.names = FALSE` e encoding UTF-8. Separador: virgula. Adequado para
importacao em Stata, SPSS, Python e R.

### LaTeX

Gera codigo LaTeX via
[`knitr::kable()`](https://rdrr.io/pkg/knitr/man/kable.html) com
`format = "latex"`, empacotado em ambiente `table` com `\\centering`,
`\\caption` e `\\label`. Adicione `\\usepackage{booktabs}` no preambulo
do documento para melhor tipografia.

### Excel

Usa
[`writexl::write_xlsx()`](https://docs.ropensci.org/writexl//reference/write_xlsx.html)
— sem dependencia de Java ou LibreOffice. Cria arquivo `.xlsx`
compativel com Excel 2007+, Google Sheets e LibreOffice Calc.

### RDS

Serializa o objeto R completo via
[`base::saveRDS()`](https://rdrr.io/r/base/readRDS.html). Preserva
tipos, atributos e classes (incluindo objetos `ac_irr`, corpus etc.).
Ideal para replicabilidade interna ao projeto.

## See also

[`ac_qual_irr()`](https://andersonheri.github.io/acR/reference/ac_qual_irr.md),
[`ac_qual_code()`](https://andersonheri.github.io/acR/reference/ac_qual_code.md)

## Examples

``` r
if (FALSE) { # \dontrun{
resultados <- data.frame(
  id_discurso  = c("d1", "d2", "d3"),
  nome_deputado = c("Dep. A", "Dep. B", "Dep. C"),
  categoria    = c("progressista", "conservador", "tecnocratico"),
  confianca    = c(0.94, 0.91, 0.87)
)

# CSV
ac_export(resultados, "resultados_discursos.csv")

# LaTeX (para incluir em artigo)
ac_export(
  resultados,
  "tabela_resultados.tex",
  latex_caption = "Classificacao do tom dos discursos por LLM",
  latex_label   = "tab:tom_discursos"
)

# Excel
ac_export(resultados, "resultados.xlsx", excel_sheet = "Classificacao")

# RDS (replicabilidade)
ac_export(resultados, "resultados.rds")

# Objeto ac_irr
irr_result <- ac_qual_irr(gold, predicted, verbose = FALSE)
ac_export(irr_result, "confiabilidade.csv")
} # }
```
