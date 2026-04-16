# Visualizar curva de seleção de k (perplexidade)

`ac_plot_lda_tune()` gera um gráfico de linha da perplexidade (ou outras
métricas) em função do número de tópicos k, auxiliando na escolha do k
ideal para o modelo LDA.

## Usage

``` r
ac_plot_lda_tune(tune_result, title = NULL, ...)
```

## Arguments

- tune_result:

  Tibble retornado por
  [`ac_lda_tune()`](https://andersonheri.github.io/acR/reference/ac_lda_tune.md).

- title:

  Título. Padrão: `NULL`.

- ...:

  Ignorado.

## Value

Objeto `ggplot`.

## See also

[`ac_lda_tune()`](https://andersonheri.github.io/acR/reference/ac_lda_tune.md)

## Examples

``` r
if (FALSE) { # \dontrun{
tune <- ac_lda_tune(corpus, k_range = 2:10)
ac_plot_lda_tune(tune)
} # }
```
