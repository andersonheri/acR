# Visualizar curva de seleção de k (perplexidade)

`ac_plot_lda_tune()` gera um gráfico de linha da perplexidade (ou outras
métricas) em função do número de tópicos k, auxiliando na escolha do k
ideal para o modelo LDA.

## Usage

``` r
ac_plot_lda_tune(tune_result, title = NULL, ...)
```

## Arguments

- tune_result:

  Tibble retornado por
  [`ac_lda_tune()`](https://ahenriquecp.com/acR/reference/ac_lda_tune.md).

- title:

  Título. Padrão: `NULL`.

- ...:

  Ignorado.

## Value

Objeto `ggplot`.

## See also

[`ac_lda_tune()`](https://ahenriquecp.com/acR/reference/ac_lda_tune.md)

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

# Testar k de 2 a 4 e visualizar a curva de perplexidade
# (ponto de inflexao/"cotovelo" sugere um bom k)
tune <- ac_lda_tune(corpus, k_range = 2:4)
#> Testando k = 2 a 4...
ac_plot_lda_tune(tune)

# }
```
