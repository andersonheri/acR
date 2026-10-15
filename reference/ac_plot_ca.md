# Visualizar um biplot de análise de correspondência

`ac_plot_ca()` plota um biplot com as duas primeiras dimensões da saída
de [`ac_ca()`](https://andersonheri.github.io/acR/reference/ac_ca.md):
pontos de unidades (documentos/grupos) e de termos no mesmo espaço, com
os eixos rotulados pela proporção de inércia explicada.

## Usage

``` r
ac_plot_ca(ca, top_terms = 20L, title = NULL)
```

## Arguments

- ca:

  Objeto de classe `ac_ca`, saída de
  [`ac_ca()`](https://andersonheri.github.io/acR/reference/ac_ca.md).

- top_terms:

  Número máximo de termos a rotular, pelos de maior distância da origem
  (mais distintivos). Padrão: `20`.

- title:

  Título do gráfico. Padrão: `NULL` (título automático).

## Value

Objeto `ggplot`.

## See also

[`ac_ca()`](https://andersonheri.github.io/acR/reference/ac_ca.md)

## Examples

``` r
df <- data.frame(
  id = paste0("d", 1:6),
  texto = c(
    "entrega atrasada rastreio sumiu",
    "pedido atrasou muito, rastreio não atualiza",
    "produto com defeito, chegou quebrado",
    "veio quebrado, qualidade péssima",
    "atendimento excelente, resolveram rápido",
    "suporte educado e rápido, resolveu tudo"
  ),
  categoria = c("entrega", "entrega", "produto", "produto",
                 "atendimento", "atendimento"),
  stringsAsFactors = FALSE
)
corpus <- ac_corpus(df, text = texto, docid = id, meta = categoria)
ca <- ac_ca(corpus, by = "categoria", min_count = 1)
if (requireNamespace("ggplot2", quietly = TRUE)) {
  ac_plot_ca(ca)
}

```
