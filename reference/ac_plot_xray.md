# Gráfico X-ray — dispersão lexical de termos no corpus

`ac_plot_xray()` exibe a posição de ocorrência de um ou mais termos ao
longo do texto de cada documento, como marcações verticais numa linha
horizontal. Útil para visualizar padrões de uso ao longo de discursos,
capítulos ou documentos longos.

## Usage

``` r
ac_plot_xray(
  corpus,
  terms,
  ignore_case = TRUE,
  colors = NULL,
  title = NULL,
  ...
)
```

## Arguments

- corpus:

  Objeto `ac_corpus`.

- terms:

  Vetor de termos a rastrear (após limpeza e tokenização).

- ignore_case:

  Se `TRUE` (padrão), ignora diferenças de capitalização.

- colors:

  Vetor de cores para os termos. Se `NULL`, usa paleta padrão.

- title:

  Título do gráfico. Padrão: `NULL`.

- ...:

  Ignorado.

## Value

Objeto `ggplot`.

## See also

[`ac_corpus()`](https://andersonheri.github.io/acR/reference/ac_corpus.md)

## Examples

``` r
df <- data.frame(
  id = c("d1", "d2"),
  texto = c(
    "democracia liberdade igualdade democracia direitos democracia",
    "mercado liberdade privatizacao mercado eficiencia mercado"
  )
)
corpus <- ac_corpus(df, text = texto, docid = id)
ac_plot_xray(corpus, terms = c("democracia", "mercado", "liberdade"))

```
