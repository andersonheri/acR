# Plotar termos mais frequentes

`ac_plot_top_terms()` cria um grafico de barras com os termos mais
frequentes a partir de uma tabela de frequencias, tipicamente gerada por
[`ac_count()`](https://andersonheri.github.io/acR/reference/ac_count.md)
ou filtrada por
[`ac_top_terms()`](https://andersonheri.github.io/acR/reference/ac_top_terms.md).

A funcao usa
[ggplot2](https://ggplot2.tidyverse.org/reference/ggplot2-package.html)
como base e pode, opcionalmente, aplicar o estilo editorial do pacote
`ipeaplot`.

## Usage

``` r
ac_plot_top_terms(
  x,
  by = NULL,
  n = NULL,
  style = c("default", "ipea"),
  flip = TRUE
)
```

## Arguments

- x:

  Um `data.frame` ou
  [`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
  contendo, no minimo, as colunas `token` e `n`.

- by:

  Vetor de nomes de colunas em `x` a serem usados como grupos de
  facetas. Se `NULL` (padrao), produz um unico grafico. Se nao for
  `NULL`, cria facetas por combinacao das colunas informadas.

- n:

  Numero de termos a exibir. Se `NULL` (padrao), usa todas as linhas de
  `x`. Se informado, seleciona os top `n` termos no geral ou em cada
  grupo definido por `by`.

- style:

  Estilo grafico. Pode ser `"default"` (padrao) ou `"ipea"`. Quando
  `"ipea"`, a funcao tenta aplicar
  [`ipeaplot::theme_ipea()`](https://rdrr.io/pkg/ipeaplot/man/theme_ipea.html).

- flip:

  Logico. Se `TRUE` (padrao), usa barras horizontais com
  [`ggplot2::coord_flip()`](https://ggplot2.tidyverse.org/reference/coord_flip.html).

## Value

Um objeto `ggplot`.

## See also

[`ac_count()`](https://andersonheri.github.io/acR/reference/ac_count.md),
[`ac_top_terms()`](https://andersonheri.github.io/acR/reference/ac_top_terms.md)

## Examples

``` r
df <- data.frame(
  id      = c("d1", "d2", "d3"),
  texto   = c(
    "O deputado do PT falou na CCJ.",
    "O deputado do PL falou novamente.",
    "O senador do PT falou na CCJ."
  ),
  partido = c("PT", "PL", "PT"),
  stringsAsFactors = FALSE
)

corp <- ac_corpus(df, text = texto, docid = id, meta = partido)

freq <- ac_count(corp)
ac_plot_top_terms(freq, n = 10)


freq_by <- ac_count(corp, by = "partido")
ac_plot_top_terms(freq_by, by = "partido", n = 5)

```
