# Ajustar múltiplos modelos LDA para selecionar k

`ac_lda_tune()` ajusta modelos LDA para diferentes valores de k e
calcula métricas de qualidade para auxiliar na seleção do número ideal
de tópicos.

## Usage

``` r
ac_lda_tune(
  corpus,
  k_range = 5:20,
  seed = 42L,
  method = c("VEM", "Gibbs"),
  ...
)
```

## Arguments

- corpus:

  Objeto `ac_corpus`.

- k_range:

  Vetor de valores de k a testar. Padrão: `5:20`.

- seed:

  Semente. Padrão: `42`.

- method:

  Método de estimação. Padrão: `"VEM"`.

- ...:

  Ignorado.

## Value

Tibble com colunas `k`, `perplexity` e, se disponível, métricas do
pacote `ldatuning`.

## See also

[`ac_lda()`](https://andersonheri.github.io/acR/reference/ac_lda.md),
[`ac_plot_lda_tune()`](https://andersonheri.github.io/acR/reference/ac_plot_lda_tune.md)

## Examples

``` r
if (FALSE) { # \dontrun{
df <- data.frame(
  id = paste0("d", 1:10),
  texto = c(
    "democracia participacao politica voto eleicao",
    "mercado economia fiscal privatizacao",
    "saude hospital medico doenca sus",
    "educacao escola professor universidade",
    "democracia cidadania direitos igualdade",
    "economia inflacao juros orcamento",
    "saude medico remedio tratamento",
    "educacao pesquisa ciencia tecnologia",
    "participacao social democracia cidadania",
    "mercado trabalho emprego salario"
  )
)
corpus <- ac_corpus(df, text = texto, docid = id)
tune <- ac_lda_tune(corpus, k_range = 2:5)
tune
} # }
```
