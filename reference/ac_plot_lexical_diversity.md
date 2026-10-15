# Visualizar diversidade lexical por grupo

`ac_plot_lexical_diversity()` compara MTLD (ou outra métrica de
[`ac_lexical_diversity()`](https://ahenriquecp.com/acR/reference/ac_lexical_diversity.md))
entre grupos.

## Usage

``` r
ac_plot_lexical_diversity(
  diversity_tbl,
  group_col = NULL,
  metric = c("mtld", "ttr", "herdan_c"),
  type = c("box", "bar"),
  title = NULL
)
```

## Arguments

- diversity_tbl:

  Tibble retornado por `ac_lexical_diversity(corpus, by = NULL)` com uma
  coluna de grupo adicional já presente, ou por
  `ac_lexical_diversity(corpus, by = ...)`.

- group_col:

  Nome da coluna de agrupamento no eixo X.

- metric:

  Métrica a visualizar: `"mtld"` (padrão), `"ttr"` ou `"herdan_c"`.

- type:

  Tipo de gráfico: `"box"` (padrão) ou `"bar"`.

- title:

  Título do gráfico. Padrão: `NULL`.

## Value

Objeto `ggplot`.

## See also

[`ac_lexical_diversity()`](https://ahenriquecp.com/acR/reference/ac_lexical_diversity.md)

## Examples

``` r
df <- data.frame(
  id = paste0("t", 1:4),
  texto = c(
    "o gato subiu no muro e desceu depois correu e subiu de novo",
    "o felino ascendeu ao parapeito e descendeu com cautela depois",
    "ela correu muito rápido e muito rápido e muito rápido ainda",
    "a atleta acelerou vertiginosamente superando marcas anteriores"
  ),
  narrador = c("simples", "rebuscado", "simples", "rebuscado"),
  stringsAsFactors = FALSE
)
corpus <- ac_corpus(df, text = texto, docid = id, meta = narrador)
div <- ac_lexical_diversity(corpus)
div$narrador <- corpus$narrador
ac_plot_lexical_diversity(div, group_col = "narrador")

```
