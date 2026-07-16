# Exportar amostra para revisão humana em Excel

`ac_qual_export_for_review()` exporta uma amostra de documentos
classificados para um arquivo Excel, com colunas para o codificador
humano preencher.

## Usage

``` r
ac_qual_export_for_review(
  sample,
  path = "validacao_humana.xlsx",
  corpus = NULL,
  ...
)
```

## Arguments

- sample:

  Tibble, saída de
  [`ac_qual_sample()`](https://andersonheri.github.io/acR/reference/ac_qual_sample.md).

- path:

  Caminho do arquivo `.xlsx`. Padrão: `"validacao_humana.xlsx"`.

- corpus:

  Objeto `ac_corpus` original (opcional). Se fornecido, inclui o texto
  completo de cada documento na planilha.

- ...:

  Ignorado.

## Value

Invisível: caminho do arquivo gerado.

## Examples

``` r
if (requireNamespace("openxlsx", quietly = TRUE)) {
  # Amostra de documentos ja classificados pela LLM
  coded <- tibble::tibble(
    doc_id           = paste0("doc_", 1:5),
    categoria        = c("favor", "contra", "favor", "contra", "favor"),
    confidence_score = c(0.6, 0.9, 0.8, 0.7, 0.55)
  )
  amostra <- ac_qual_sample(coded, n = 3, strategy = "uncertainty")

  # Exportar para revisao humana em arquivo temporario
  arquivo <- tempfile(fileext = ".xlsx")
  ac_qual_export_for_review(amostra, path = arquivo)
  file.exists(arquivo)
}
#> ℹ Amostra de 3 documentos selecionada (estratégia: "uncertainty").
#> ℹ Use `ac_qual_export_for_review()` para exportar para Excel.
#> ✅ Planilha exportada: /tmp/RtmpMBoJEA/file1b6f303890f9.xlsx
#> ℹ Preencha a coluna "categoria_humano" com a classificação.
#> ℹ Use `ac_qual_import_human()` para importar após preenchimento.
#> [1] TRUE
```
