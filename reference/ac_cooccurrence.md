# Calcular co-ocorrências de termos

`ac_cooccurrence()` calcula pares de termos que co-ocorrem dentro de
janelas deslizantes ou dentro do mesmo documento, retornando frequências
e medidas de associação (PMI, Dice).

## Usage

``` r
ac_cooccurrence(
  corpus,
  window = 5L,
  unit = c("window", "document"),
  measure = c("count", "pmi", "dice"),
  min_count = 2L,
  ...
)
```

## Arguments

- corpus:

  Objeto `ac_corpus` ou tibble com colunas `doc_id` e `token` (saída de
  [`ac_tokenize()`](https://andersonheri.github.io/acR/reference/ac_tokenize.md)).

- window:

  Tamanho da janela deslizante (número de tokens de cada lado). Padrão:
  `5`. Ignorado se `unit = "document"`.

- unit:

  Unidade de co-ocorrência: `"window"` (padrão) ou `"document"`.

- measure:

  Medidas de associação a calcular. Um ou mais de: `"count"` (frequência
  conjunta), `"pmi"` (pointwise mutual information), `"dice"`
  (coeficiente Dice). Padrão: `c("count", "pmi")`.

- min_count:

  Frequência mínima de co-ocorrência para incluir o par. Padrão: `2`.

- ...:

  Ignorado.

## Value

Tibble com colunas:

- `word1`, `word2`: par de termos (ordenado alfabeticamente);

- `cooc`: frequência de co-ocorrência;

- `pmi` (se solicitado): pointwise mutual information;

- `dice` (se solicitado): coeficiente Dice.

## See also

[`ac_tokenize()`](https://andersonheri.github.io/acR/reference/ac_tokenize.md),
[`ac_plot_cooccurrence()`](https://andersonheri.github.io/acR/reference/ac_plot_cooccurrence.md)

## Examples

``` r
df <- data.frame(
  id = c("d1", "d2", "d3"),
  texto = c(
    "democracia participacao cidadania",
    "participacao politica democracia",
    "cidadania direitos participacao"
  )
)
corpus <- ac_corpus(df, text = texto, docid = id) |>
  ac_clean()
tokens <- ac_tokenize(corpus)
ac_cooccurrence(tokens, window = 3, min_count = 1)
#> # A tibble: 7 × 5
#>   word1        word2         cooc   pmi  dice
#>   <chr>        <chr>        <int> <dbl> <dbl>
#> 1 cidadania    participacao     4  2.58     1
#> 2 democracia   participacao     4  2.58     1
#> 3 cidadania    democracia       2  2.17     1
#> 4 cidadania    direitos         2  3.17     1
#> 5 democracia   politica         2  3.17     1
#> 6 direitos     participacao     2  2.58     1
#> 7 participacao politica         2  2.58     1
```
