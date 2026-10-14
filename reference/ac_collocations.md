# Identificar colocações com medidas de associação estatística

`ac_collocations()` identifica pares (ou trincas) de palavras que
aparecem juntas com mais frequência do que o esperado pelo acaso —
colocações como "reforma tributária", "não recomendo" ou "atendimento ao
cliente" — usando medidas de associação estatística em vez de frequência
bruta de bigramas/trigramas.

A diferença importa: bigramas puramente frequentes tendem a ser
dominados por combinações de palavras funcionais comuns ("de o", "que
a"), que são frequentes mas não informativas. As medidas de associação
penalizam esse efeito, destacando combinações que ocorrem juntas mais do
que a frequência individual de cada palavra sugeriria — o uso típico é
alimentar um dicionário customizado (ver
[`ac_build_dictionary()`](https://andersonheri.github.io/acR/reference/ac_build_dictionary.md))
ou simplesmente explorar expressões compostas específicas de um domínio
(jurídico, médico, técnico) antes de uma análise de frequência ou nuvem
de palavras.

## Usage

``` r
ac_collocations(
  corpus,
  n = 2L,
  measure = c("pmi", "ll", "chi2"),
  min_count = 5L,
  drop_punct = TRUE
)
```

## Arguments

- corpus:

  Objeto `ac_corpus`.

- n:

  Tamanho do n-grama: `2` (padrão, bigramas) ou `3` (trigramas).

- measure:

  Medida de associação:

  - `"pmi"` (padrão): *Pointwise Mutual Information* (Church &
    Hanks, 1990) — quanto mais alto, mais a coocorrência surpreende em
    relação ao esperado pelo acaso. Tende a favorecer pares raros.

  - `"ll"`: log-likelihood ratio (Dunning, 1993) — mais robusta que PMI
    para colocações de baixa frequência; é a medida padrão do
    `quanteda.textstats::textstat_collocations()`.

  - `"chi2"`: qui-quadrado de associação, mesma lógica de
    [`ac_keyness()`](https://andersonheri.github.io/acR/reference/ac_keyness.md)
    aplicada a pares de palavras adjacentes em vez de grupos de
    documentos.

- min_count:

  Frequência mínima do n-grama para ser considerado. Padrão: `5`.
  Medidas de associação são instáveis para n-gramas muito raros.

- drop_punct:

  Lógico. Se `TRUE` (padrão), ignora n-gramas que incluem tokens de
  pontuação pura.

## Value

Tibble ordenado por associação decrescente, com colunas:

- `collocation`: o n-grama (palavras separadas por espaço);

- `count`: frequência absoluta do n-grama no corpus;

- `association`: valor da medida escolhida em `measure`.

## References

Church, K. W.; Hanks, P. (1990). Word association norms, mutual
information, and lexicography. *Computational Linguistics*, 16(1),
22-29.

Dunning, T. (1993). Accurate methods for the statistics of surprise and
coincidence. *Computational Linguistics*, 19(1), 61-74.

## See also

[`ac_keyness()`](https://andersonheri.github.io/acR/reference/ac_keyness.md),
[`ac_count()`](https://andersonheri.github.io/acR/reference/ac_count.md)

## Examples

``` r
# Reviews de um restaurante com expressoes compostas recorrentes
df <- data.frame(
  id = paste0("r", 1:6),
  texto = c(
    "atendimento ao cliente impecavel, super recomendo o lugar",
    "o atendimento ao cliente deixou a desejar dessa vez",
    "comida boa mas atendimento ao cliente lento",
    "nao recomendo, atendimento ao cliente horrivel",
    "ambiente agradavel e atendimento ao cliente rapido",
    "preco justo, atendimento ao cliente cordial sempre"
  ),
  stringsAsFactors = FALSE
)
corpus <- ac_corpus(df, text = texto, docid = id)

ac_collocations(corpus, min_count = 2)
#> # A tibble: 2 × 3
#>   collocation    count association
#>   <chr>          <int>       <dbl>
#> 1 ao cliente         6        2.87
#> 2 atendimento ao     6        2.87
```
