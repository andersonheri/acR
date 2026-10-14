# Visualizar uma série temporal de conteúdo

`ac_plot_temporal()` traça a evolução de uma métrica agregada por
período, saída de
[`ac_temporal()`](https://andersonheri.github.io/acR/dev/reference/ac_temporal.md),
com uma linha de tendência suavizada opcional.

## Usage

``` r
ac_plot_temporal(temporal_tbl, smooth = TRUE, title = NULL, ylab = "Valor")
```

## Arguments

- temporal_tbl:

  Tibble retornado por
  [`ac_temporal()`](https://andersonheri.github.io/acR/dev/reference/ac_temporal.md).

- smooth:

  Lógico. Se `TRUE` (padrão), adiciona uma curva de tendência (LOESS)
  sobre os pontos observados.

- title:

  Título do gráfico. Padrão: `NULL`.

- ylab:

  Rótulo do eixo Y. Padrão: `"Valor"`.

## Value

Objeto `ggplot`.

## See also

[`ac_temporal()`](https://andersonheri.github.io/acR/dev/reference/ac_temporal.md)

## Examples

``` r
df <- data.frame(
  doc_id = paste0("d", 1:6),
  data   = as.Date(c("2024-01-05", "2024-01-20", "2024-02-02",
                     "2024-02-15", "2024-03-01", "2024-03-10")),
  score  = c(-2, -1, 0, 1, 2, 1)
)
temporal <- ac_temporal(df, date_col = "data", value_col = "score")
ac_plot_temporal(temporal, ylab = "Sentimento medio")

```
