# Visualizar legibilidade por grupo

`ac_plot_readability()` compara a distribuição do Índice de Flesch (ver
[`ac_readability()`](https://andersonheri.github.io/acR/reference/ac_readability.md))
entre grupos, com boxplots — a forma usual de reportar legibilidade
comparada na literatura de linguística computacional e comunicação.

## Usage

``` r
ac_plot_readability(
  readability_tbl,
  group_col = NULL,
  type = c("box", "bar"),
  title = NULL
)
```

## Arguments

- readability_tbl:

  Tibble retornado por `ac_readability(corpus, by = NULL)` (uma linha
  por documento) com uma coluna adicional de grupo já presente (ex.:
  junte com os metadados do corpus antes de chamar, ou calcule com `by`
  e use `type = "bar"`).

- group_col:

  Nome da coluna de agrupamento no eixo X.

- type:

  Tipo de gráfico: `"box"` (padrão, exige uma linha por documento) ou
  `"bar"` (uma barra por grupo; use quando `readability_tbl` já vier
  agregado por `ac_readability(by = ...)`).

- title:

  Título do gráfico. Padrão: `NULL`.

## Value

Objeto `ggplot`.

## See also

[`ac_readability()`](https://andersonheri.github.io/acR/reference/ac_readability.md)

## Examples

``` r
df <- data.frame(
  id = paste0("r", 1:6),
  texto = c(
    "Bom. Gostei. Rapido.",
    "Facil de montar e usar no dia a dia.",
    paste(
      "A configuracao inicial demanda familiaridade com conceitos",
      "de rede que extrapolam o publico leigo habitual."
    ),
    "Perfeito, superou expectativas.",
    paste(
      "A ausencia de documentacao tecnica compromete a integracao",
      "com sistemas legados preexistentes na infraestrutura corporativa."
    ),
    "Simples e direto, recomendo."
  ),
  categoria = rep(c("facil", "dificil"), 3),
  stringsAsFactors = FALSE
)
corpus <- ac_corpus(df, text = texto, docid = id, meta = categoria)
leg <- ac_readability(corpus)
leg$categoria <- corpus$categoria
ac_plot_readability(leg, group_col = "categoria")

```
