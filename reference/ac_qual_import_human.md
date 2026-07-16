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

## Examples

``` r
if (requireNamespace("openxlsx", quietly = TRUE)) {
  # Simular uma planilha ja preenchida pelo codificador humano
  arquivo <- tempfile(fileext = ".xlsx")
  openxlsx::write.xlsx(
    data.frame(
      doc_id           = paste0("doc_", 1:3),
      categoria_humano = c("favor", "contra", "favor")
    ),
    arquivo
  )

  # Importar de volta para o R para uso com ac_qual_reliability()
  humano <- ac_qual_import_human(arquivo)
  humano
}
#> ✅ 3 classificações humanas importadas de /tmp/RtmpGH7g9k/file1b7619839690.xlsx
#> # A tibble: 3 × 2
#>   doc_id categoria
#>   <chr>  <chr>    
#> 1 doc_1  favor    
#> 2 doc_2  contra   
#> 3 doc_3  favor    
```
