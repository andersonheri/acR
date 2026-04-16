# Visualizar top termos por tópico

`ac_plot_lda_topics()` gera um gráfico de barras com os termos de maior
probabilidade (beta) para cada tópico do modelo LDA.

## Usage

``` r
ac_plot_lda_topics(lda_result, top_n = 10L, ncol = NULL, title = NULL, ...)
```

## Arguments

- lda_result:

  Objeto `ac_lda`, saída de
  [`ac_lda()`](https://andersonheri.github.io/acR/reference/ac_lda.md).

- top_n:

  Número de termos por tópico. Padrão: `10`.

- ncol:

  Número de colunas nos facets. Padrão: `NULL` (automático).

- title:

  Título. Padrão: `NULL`.

- ...:

  Ignorado.

## Value

Objeto `ggplot`.

## See also

[`ac_lda()`](https://andersonheri.github.io/acR/reference/ac_lda.md)

## Examples

``` r
if (FALSE) { # \dontrun{
lda <- ac_lda(corpus, k = 3)
ac_plot_lda_topics(lda, top_n = 8)
} # }
```
