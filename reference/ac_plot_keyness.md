# Plotar estatísticas de keyness

`ac_plot_keyness()` cria um grafico de barras com as estatísticas de
keyness calculadas por
[`ac_keyness()`](https://ahenriquecp.com/acR/reference/ac_keyness.md),
destacando os termos mais caracteristicos do grupo alvo e do grupo de
referência.

A função usa
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
  contendo, no mínimo, as colunas `token`, `keyness` e `direction`.

- n:

  Número de termos a exibir por direcao. Se `NULL` (padrao), usa todas
  as linhas de `x`. Se informado, seleciona os top `n` termos com
  `keyness` positivo e os top `n` com `keyness` negativo. Empates na
  última posição são desfeitos em ordem alfabética.

- style:

  Estilo grafico. Pode ser `"default"` (padrao) ou `"ipea"`. Quando
  `"ipea"`, a função tenta aplicar
  [`ipeaplot::theme_ipea()`](https://rdrr.io/pkg/ipeaplot/man/theme_ipea.html).

- flip:

  Lógico. Se `TRUE` (padrao), usa barras horizontais com
  [`ggplot2::coord_flip()`](https://ggplot2.tidyverse.org/reference/coord_flip.html).

- show_reference:

  Lógico. Se `TRUE` (padrao), mostra termos caracteristicos do grupo
  alvo e do grupo de referência. Se `FALSE`, mostra apenas os termos com
  `keyness` positivo.

## Value

Um objeto `ggplot`.

## See also

[`ac_count()`](https://ahenriquecp.com/acR/reference/ac_count.md),
[`ac_keyness()`](https://ahenriquecp.com/acR/reference/ac_keyness.md)

## Examples

``` r
# 1. Corpus fabricado com duas subamostras (Governo vs Oposicao)
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

# 2. Calcular termos-chave (sobre-representados no grupo alvo)
corp <- ac_corpus(df, text = texto, docid = id, meta = lado)
freq <- ac_count(corp, by = "lado")
key <- ac_keyness(freq, group = "lado", target = "Governo")

# 3. Grafico dos 5 termos com maior chi-quadrado
ac_plot_keyness(key, n = 5)

```
