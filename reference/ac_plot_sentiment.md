# Visualizar sentimento ao longo dos documentos

`ac_plot_sentiment()` gera visualizações de sentimento: barras por
documento, linha temporal, ou distribuição de scores.

## Usage

``` r
ac_plot_sentiment(
  sentiment_tbl,
  type = c("bar", "line", "density"),
  x_col = "doc_id",
  fill_col = "sentiment",
  title = NULL,
  ...
)
```

## Arguments

- sentiment_tbl:

  Tibble retornado por
  [`ac_sentiment()`](https://andersonheri.github.io/acR/reference/ac_sentiment.md).

- type:

  Tipo de visualização: `"bar"` (padrão), `"line"`, `"density"`.

- x_col:

  Coluna do eixo X. Padrão: `"doc_id"`. Pode ser uma coluna de data para
  `type = "line"`.

- fill_col:

  Coluna para preenchimento/cor. Padrão: `"sentiment"`.

- title:

  Título do gráfico. Padrão: `NULL`.

- ...:

  Ignorado.

## Value

Objeto `ggplot`.

## See also

[`ac_sentiment()`](https://andersonheri.github.io/acR/reference/ac_sentiment.md)

## Examples

``` r
df <- data.frame(
  id = c("a", "b", "c", "d"),
  texto = c(
    "excelente otimo positivo bom",
    "pessimo terrivel negativo ruim",
    "aprovada proposta reuniao",
    "bom resultado positivo otimo"
  )
)
corpus <- ac_corpus(df, text = texto, docid = id)
sent <- ac_sentiment(corpus)
#> Baixando OpLexicon (primeira execução — será cacheado)...
ac_plot_sentiment(sent)

```
