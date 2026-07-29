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
  [`ac_lda()`](https://ahenriquecp.com/acR/reference/ac_lda.md).

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

[`ac_lda()`](https://ahenriquecp.com/acR/reference/ac_lda.md)

## Examples

``` r
# \donttest{
# Corpus sintetico com dois blocos tematicos
df <- data.frame(
  id = paste0("d", 1:8),
  texto = c(
    "democracia participacao voto cidadania",
    "cidadania direitos participacao democracia",
    "voto direitos liberdade cidadania",
    "democracia voto participacao popular",
    "mercado economia eficiencia privatizacao",
    "privatizacao mercado livre eficiencia",
    "economia crescimento investimento mercado",
    "eficiencia mercado economia livre"
  ),
  stringsAsFactors = FALSE
)
corpus <- ac_corpus(df, text = texto, docid = id)
lda    <- ac_lda(corpus, k = 2)
#> Ajustando LDA com k = 2 tópicos...

# Grafico com os 5 termos mais probabilisticos por topico
ac_plot_lda_topics(lda, top_n = 5)

# }
```
