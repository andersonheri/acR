# Importar classificação humana de Excel

`ac_qual_import_human()` importa um arquivo Excel preenchido por um
codificador humano, retornando um tibble compatível com
[`ac_qual_reliability()`](https://andersonheri.github.io/acR/reference/ac_qual_reliability.md).

## Usage

``` r
ac_qual_import_human(
  path,
  cat_col = "categoria_humano",
  id_col = "doc_id",
  ...
)
```

## Arguments

- path:

  Caminho do arquivo `.xlsx`.

- cat_col:

  Nome da coluna com a classificação humana. Padrão:
  `"categoria_humano"`.

- id_col:

  Nome da coluna de identificador. Padrão: `"doc_id"`.

- ...:

  Ignorado.

## Value

Tibble com colunas `doc_id` e `categoria`.
