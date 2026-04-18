# Nuvem de palavras comparativa entre grupos

`ac_plot_wordcloud_comparative()` gera uma nuvem de palavras comparativa
entre dois grupos de documentos, posicionando termos mais associados a
cada grupo em lados opostos. Usa TF-IDF para identificar os termos mais
distintivos de cada grupo.

## Usage

``` r
ac_plot_wordcloud_comparative(
  corpus,
  group,
  max_words = 50L,
  colors = c("#0072B2", "#D55E00"),
  title = NULL,
  ...
)
```

## Arguments

- corpus:

  Objeto `ac_corpus` com coluna de metadado de grupo.

- group:

  Coluna de agrupamento (nome sem aspas ou string).

- max_words:

  Número máximo de palavras por grupo. Padrão: `50`.

- colors:

  Vetor com duas cores (uma por grupo). Padrão: paleta acessível
  Okabe-Ito.

- title:

  Título do gráfico. Padrão: `NULL`.

- ...:

  Ignorado.

## Value

Objeto `ggplot`.

## See also

[`ac_tf_idf()`](https://andersonheri.github.io/acR/reference/ac_tf_idf.md)

## Examples

``` r
df <- data.frame(
  id     = paste0("d", 1:6),
  texto  = c(
    "democracia participacao popular voto",
    "direitos cidadania liberdade democracia",
    "participacao popular igualdade direitos",
    "mercado economia privatizacao eficiencia",
    "privatizacao mercado livre eficiencia",
    "economia crescimento mercado investimento"
  ),
  grupo = c("A","A","A","B","B","B")
)
corpus <- ac_corpus(df, text = texto, docid = id)
ac_plot_wordcloud_comparative(corpus, group = grupo)

```
