# Plotar estatisticas de keyness

`ac_plot_keyness()` cria um grafico de barras com as estatisticas de
keyness calculadas por
[`ac_keyness()`](https://andersonheri.github.io/acR/reference/ac_keyness.md),
destacando os termos mais caracteristicos do grupo alvo e do grupo de
referencia.

A funcao usa
[ggplot2](https://ggplot2.tidyverse.org/reference/ggplot2-package.html)
como base e pode, opcionalmente, aplicar o estilo editorial do pacote
`ipeaplot`.

## Usage

``` r
ac_plot_keyness(
  x,
  n = NULL,
  style = c("default", "ipea"),
  flip = TRUE,
  show_reference = TRUE
)
```

## Arguments

- x:

  Um `data.frame` ou
  [`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
  contendo, no minimo, as colunas `token`, `keyness` e `direction`.

- n:

  Numero de termos a exibir por direcao. Se `NULL` (padrao), usa todas
  as linhas de `x`. Se informado, seleciona os top `n` termos com
  `keyness` positivo e os top `n` com `keyness` negativo.

- style:

  Estilo grafico. Pode ser `"default"` (padrao) ou `"ipea"`. Quando
  `"ipea"`, a funcao tenta aplicar
  [`ipeaplot::theme_ipea()`](https://rdrr.io/pkg/ipeaplot/man/theme_ipea.html).

- flip:

  Logico. Se `TRUE` (padrao), usa barras horizontais com
  [`ggplot2::coord_flip()`](https://ggplot2.tidyverse.org/reference/coord_flip.html).

- show_reference:

  Logico. Se `TRUE` (padrao), mostra termos caracteristicos do grupo
  alvo e do grupo de referencia. Se `FALSE`, mostra apenas os termos com
  `keyness` positivo.

## Value

Um objeto `ggplot`.

## See also

[`ac_count()`](https://andersonheri.github.io/acR/reference/ac_count.md),
[`ac_keyness()`](https://andersonheri.github.io/acR/reference/ac_keyness.md)

## Examples

``` r
df <- data.frame(
  id    = c("d1", "d2", "d3", "d4"),
  texto = c(
    "A A A B",
    "A B",
    "A B B B",
    "B B C"
  ),
  lado  = c("Governo", "Governo", "Oposicao", "Oposicao"),
  stringsAsFactors = FALSE
)

corp <- ac_corpus(df, text = texto, docid = id, meta = lado)
freq <- ac_count(corp, by = "lado")
key <- ac_keyness(freq, group = "lado", target = "Governo")

ac_plot_keyness(key, n = 5)

```
