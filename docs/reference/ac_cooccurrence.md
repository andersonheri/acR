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
# Corpus tematico: coocorrencia revela associacoes conceituais
# (que palavras "andam juntas" no discurso).
df <- data.frame(
  id = paste0("d", 1:6),
  texto = c(
    "democracia participacao voto liberdade cidadania popular",
    "cidadania direitos participacao democracia representacao politica",
    "voto direitos liberdade cidadania soberania popular",
    "mercado economia eficiencia privatizacao competicao livre",
    "privatizacao mercado livre eficiencia produtividade lucro",
    "economia crescimento investimento mercado capital juros"
  ),
  stringsAsFactors = FALSE
)

corpus <- ac_corpus(df, text = texto, docid = id) |>
  ac_clean()
tokens <- ac_tokenize(corpus)

# Janela de 3 tokens, sem filtro de frequencia minima
# (em corpora reais use min_count >= 5 para reduzir ruido)
cooc <- ac_cooccurrence(tokens, window = 3L, min_count = 1L)
head(cooc)
#> # A tibble: 6 × 5
#>   word1      word2         cooc   pmi  dice
#>   <chr>      <chr>        <int> <dbl> <dbl>
#> 1 cidadania  direitos         4  4.58     1
#> 2 cidadania  liberdade        4  4.58     1
#> 3 cidadania  participacao     4  4.58     1
#> 4 cidadania  popular          4  4.58     1
#> 5 cidadania  voto             4  4.58     1
#> 6 democracia participacao     4  5.17     1

# Coocorrencia com PMI (associacao normalizada por acaso)
cooc_pmi <- ac_cooccurrence(tokens, window = 3L, measure = "pmi",
                            min_count = 1L)
head(cooc_pmi)
#> # A tibble: 6 × 4
#>   word1      word2         cooc   pmi
#>   <chr>      <chr>        <int> <dbl>
#> 1 cidadania  direitos         4  4.58
#> 2 cidadania  liberdade        4  4.58
#> 3 cidadania  participacao     4  4.58
#> 4 cidadania  popular          4  4.58
#> 5 cidadania  voto             4  4.58
#> 6 democracia participacao     4  5.17
```
