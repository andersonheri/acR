# Visualizar escores Wordscores por documento

`ac_plot_wordscores()` plota os escores estimados por
[`ac_wordscores()`](https://andersonheri.github.io/acR/reference/ac_wordscores.md)
num eixo único, destacando quais documentos foram usados como
referência.

## Usage

``` r
ac_plot_wordscores(wordscores_tbl, title = NULL)
```

## Arguments

- wordscores_tbl:

  Tibble retornado por
  [`ac_wordscores()`](https://andersonheri.github.io/acR/reference/ac_wordscores.md).

- title:

  Título do grafico. Padrao: `NULL` (título automático).

## Value

Objeto `ggplot`.

## See also

[`ac_wordscores()`](https://andersonheri.github.io/acR/reference/ac_wordscores.md)

## Examples

``` r
df <- data.frame(
  id = paste0("r", 1:4),
  texto = c(
    "excelente, recomendo muito",
    "bom, atende bem",
    "ruim, não gostei",
    "péssimo, decepcao"
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
