# Agregar uma métrica por período de tempo

`ac_temporal()` agrega qualquer métrica por documento (sentimento,
frequência de um termo, legibilidade, confiança de classificação...) em
janelas de tempo, para análise diacrônica — a pergunta "isso mudou ao
longo do tempo?" aparece em quase todo estudo de conteúdo com timestamp:
cobertura de imprensa sobre um tema, reclamações de clientes por mês,
evolução do tom de comunicados de uma empresa, posts de redes sociais
durante uma crise.

A função é deliberadamente genérica: não importa se o valor vem de
[`ac_sentiment()`](https://ahenriquecp.com/acR/dev/reference/ac_sentiment.md),
[`ac_readability()`](https://ahenriquecp.com/acR/dev/reference/ac_readability.md),
[`ac_count()`](https://ahenriquecp.com/acR/dev/reference/ac_count.md)
filtrado para um termo específico, ou da saída de
[`ac_qual_code()`](https://ahenriquecp.com/acR/dev/reference/ac_qual_code.md)
— qualquer tibble com uma coluna de data e uma coluna numérica serve de
entrada.

## Usage

``` r
ac_temporal(
  data,
  date_col,
  value_col,
  unit = c("month", "day", "week", "year"),
  stat = c("mean", "sum", "n")
)
```

## Arguments

- data:

  Tibble (ou `data.frame`) com, no mínimo, uma coluna de data e uma
  coluna numérica a agregar — tipicamente o resultado de uma das funções
  de análise do pacote, unido aos metadados do corpus (ex.:
  [`dplyr::left_join()`](https://dplyr.tidyverse.org/reference/mutate-joins.html)
  de
  [`ac_sentiment()`](https://ahenriquecp.com/acR/dev/reference/ac_sentiment.md)
  com a data de cada documento).

- date_col:

  Nome da coluna de data em `data`. Convertida com
  [`as.Date()`](https://rdrr.io/r/base/as.Date.html) se ainda não for
  `Date`.

- value_col:

  Nome da coluna numérica a agregar por período.

- unit:

  Unidade temporal da agregação: `"day"`, `"week"`, `"month"` (padrão)
  ou `"year"`.

- stat:

  Estatística de agregação dentro de cada período: `"mean"` (padrão),
  `"sum"` ou `"n"` (contagem de documentos, ignorando `value_col`).

## Value

Tibble com colunas `period` (`Date`, início do período), `value`
(estatística agregada) e `n_docs` (documentos naquele período).

## References

Welbers, K.; Van Atteveldt, W.; Benoit, K. (2017). Text Analysis in R.
*Communication Methods and Measures*, 11(4), 245-265.

## See also

[`ac_plot_temporal()`](https://ahenriquecp.com/acR/dev/reference/ac_plot_temporal.md),
[`ac_sentiment()`](https://ahenriquecp.com/acR/dev/reference/ac_sentiment.md)

## Examples

``` r
# Reclamacoes de clientes ao longo de alguns meses, com score de
# sentimento ja calculado por documento (ex.: saida de ac_sentiment())
df <- data.frame(
  doc_id = paste0("d", 1:6),
  data   = as.Date(c("2024-01-05", "2024-01-20", "2024-02-02",
                     "2024-02-15", "2024-03-01", "2024-03-10")),
  score  = c(-2, -1, 0, 1, 2, 1)
)

ac_temporal(df, date_col = "data", value_col = "score", unit = "month")
#> # A tibble: 3 × 3
#>   period     value n_docs
#>   <date>     <dbl>  <int>
#> 1 2024-01-01  -1.5      2
#> 2 2024-02-01   0.5      2
#> 3 2024-03-01   1.5      2
```
