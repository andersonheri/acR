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
