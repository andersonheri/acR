# Plotar termos mais caracteristicos por tf-idf

`ac_plot_tf_idf()` cria um grafico de barras com os termos mais
caracteristicos a partir de uma tabela com a coluna `tf_idf`,
tipicamente gerada por
[`ac_tf_idf()`](https://andersonheri.github.io/acR/reference/ac_tf_idf.md).

A funcao usa `ggplot2` como base e pode, opcionalmente, aplicar o estilo
editorial do pacote `ipeaplot`.

## Usage

``` r
ac_plot_tf_idf(
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
  contendo, no minimo, as colunas `token` e `tf_idf`.

- by:

  Vetor de nomes de colunas em `x` a serem usados como grupos de
  facetas. Se `NULL` (padrao), produz um unico grafico. Se nao for
  `NULL`, cria facetas por combinacao das colunas informadas.

- n:

  Numero de termos a exibir. Se `NULL` (padrao), usa todas as linhas de
  `x`. Se informado, seleciona os top `n` termos por `tf_idf` no geral
  ou em cada grupo definido por `by`.

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
[`ac_tf_idf()`](https://andersonheri.github.io/acR/reference/ac_tf_idf.md),
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
tfidf <- ac_tf_idf(freq)
ac_plot_tf_idf(tfidf, n = 10)


freq_by <- ac_count(corp, by = "partido")
tfidf_by <- ac_tf_idf(freq_by, by = "partido")
ac_plot_tf_idf(tfidf_by, by = "partido", n = 5)

```
