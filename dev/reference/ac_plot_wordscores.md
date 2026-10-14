# Visualizar escores Wordscores por documento

`ac_plot_wordscores()` plota os escores estimados por
[`ac_wordscores()`](https://ahenriquecp.com/acR/dev/reference/ac_wordscores.md)
num eixo unico, destacando quais documentos foram usados como
referência.

## Usage

``` r
ac_plot_wordscores(wordscores_tbl, title = NULL)
```

## Arguments

- wordscores_tbl:

  Tibble retornado por
  [`ac_wordscores()`](https://ahenriquecp.com/acR/dev/reference/ac_wordscores.md).

- title:

  Titulo do grafico. Padrao: `NULL` (titulo automatico).

## Value

Objeto `ggplot`.

## See also

[`ac_wordscores()`](https://ahenriquecp.com/acR/dev/reference/ac_wordscores.md)

## Examples

``` r
df <- data.frame(
  id = paste0("r", 1:4),
  texto = c(
    "excelente, recomendo muito",
    "bom, atende bem",
    "ruim, nao gostei",
    "pessimo, decepcao"
  ),
  stringsAsFactors = FALSE
)
corpus <- ac_corpus(df, text = texto, docid = id)
notas <- c(r1 = 5, r3 = 2, r4 = 1)
out <- ac_wordscores(corpus, notas)
if (requireNamespace("ggplot2", quietly = TRUE)) {
  ac_plot_wordscores(out)
}
#> Warning: Removed 1 row containing missing values or values outside the scale range
#> (`geom_point()`).

```
