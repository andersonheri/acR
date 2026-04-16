# Contar frequencias de tokens ou n-gramas em um corpus

`ac_count()` calcula frequencias de tokens ou n-gramas a partir de um
objeto
[`ac_corpus()`](https://andersonheri.github.io/acR/reference/ac_corpus.md),
usando internamente
[`ac_tokenize()`](https://andersonheri.github.io/acR/reference/ac_tokenize.md)
seguido de uma agregacao com
[`dplyr::count()`](https://dplyr.tidyverse.org/reference/count.html).

Pode operar em dois niveis:

- por documento (`by = NULL`): contagens por `doc_id` e `token`;

- por metadados (`by = c("partido", ...)`): contagens por variaveis de
  agrupamento e `token` (agregando varios documentos).

## Usage

``` r
ac_count(corpus, n = 1L, drop_punct = FALSE, by = NULL, sort = TRUE, ...)
```

## Arguments

- corpus:

  Objeto de classe
  [`ac_corpus()`](https://andersonheri.github.io/acR/reference/ac_corpus.md).

- n:

  Tamanho do n-grama a ser tokenizado. Encaminhado para
  [`ac_tokenize()`](https://andersonheri.github.io/acR/reference/ac_tokenize.md).
  Veja
  [`?ac_tokenize`](https://andersonheri.github.io/acR/reference/ac_tokenize.md)
  para detalhes.

- drop_punct:

  Logico. Se `TRUE`, remove tokens compostos apenas por pontuacao antes
  de calcular as frequencias (via `drop_punct = TRUE` em
  [`ac_tokenize()`](https://andersonheri.github.io/acR/reference/ac_tokenize.md)).

- by:

  Vetor de nomes de colunas de metadados em `corpus` a serem usados como
  grupos de agregacao. Se `NULL` (padrao), as contagens sao feitas por
  documento (`doc_id`). Se nao for `NULL`, as colunas indicadas sao
  usadas como grupos e `doc_id` nao entra no resultado.

- sort:

  Logico. Se `TRUE` (padrao), ordena a saida em ordem decrescente de
  frequencia (`n`).

- ...:

  Argumentos adicionais encaminhados para
  [`ac_tokenize()`](https://andersonheri.github.io/acR/reference/ac_tokenize.md)
  (por exemplo, `keep_empty`).

## Value

Um
[`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html):

- Se `by = NULL`: colunas `doc_id`, `token`, `n`;

- Se `by` nao nulo: colunas `by`, `token`, `n`.

## See also

[`ac_corpus()`](https://andersonheri.github.io/acR/reference/ac_corpus.md),
[`ac_clean()`](https://andersonheri.github.io/acR/reference/ac_clean.md),
[`ac_tokenize()`](https://andersonheri.github.io/acR/reference/ac_tokenize.md)

## Examples

``` r
df <- data.frame(
  id      = c("d1", "d2", "d3"),
  texto   = c(
    "O deputado do PT falou na CCJ.",
    "O deputado do PL falou novamente.",
    "O senador do PT falou na CCJ."
  ),
  partido = c("PT", "PL", "PT"),
  stringsAsFactors = FALSE
)

corp <- ac_corpus(df, text = texto, docid = id, meta = partido)

# Frequencia de palavras (unigramas) por documento
ac_count(corp)
#> # A tibble: 20 × 3
#>    doc_id token          n
#>    <chr>  <chr>      <int>
#>  1 d1     CCJ.           1
#>  2 d1     O              1
#>  3 d1     PT             1
#>  4 d1     deputado       1
#>  5 d1     do             1
#>  6 d1     falou          1
#>  7 d1     na             1
#>  8 d2     O              1
#>  9 d2     PL             1
#> 10 d2     deputado       1
#> 11 d2     do             1
#> 12 d2     falou          1
#> 13 d2     novamente.     1
#> 14 d3     CCJ.           1
#> 15 d3     O              1
#> 16 d3     PT             1
#> 17 d3     do             1
#> 18 d3     falou          1
#> 19 d3     na             1
#> 20 d3     senador        1

# Frequencia de palavras por partido
ac_count(corp, by = "partido")
#> # A tibble: 14 × 3
#>    partido token          n
#>    <chr>   <chr>      <int>
#>  1 PT      CCJ.           2
#>  2 PT      O              2
#>  3 PT      PT             2
#>  4 PT      do             2
#>  5 PT      falou          2
#>  6 PT      na             2
#>  7 PL      O              1
#>  8 PL      PL             1
#>  9 PL      deputado       1
#> 10 PL      do             1
#> 11 PL      falou          1
#> 12 PL      novamente.     1
#> 13 PT      deputado       1
#> 14 PT      senador        1

# Frequencia de bigramas por partido, removendo apenas pontuacao
ac_count(corp, n = 2, drop_punct = TRUE, by = "partido")
#> # A tibble: 13 × 3
#>    partido token                n
#>    <chr>   <chr>            <int>
#>  1 PT      PT falou             2
#>  2 PT      do PT                2
#>  3 PT      falou na             2
#>  4 PT      na CCJ.              2
#>  5 PL      O deputado           1
#>  6 PL      PL falou             1
#>  7 PL      deputado do          1
#>  8 PL      do PL                1
#>  9 PL      falou novamente.     1
#> 10 PT      O deputado           1
#> 11 PT      O senador            1
#> 12 PT      deputado do          1
#> 13 PT      senador do           1
```
