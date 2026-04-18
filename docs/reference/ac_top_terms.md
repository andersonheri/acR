# Selecionar os termos mais frequentes

`ac_top_terms()` seleciona os `n` termos mais frequentes a partir de uma
tabela de frequencias (tipicamente o resultado de
[`ac_count()`](https://andersonheri.github.io/acR/reference/ac_count.md)).

Pode operar em dois modos:

- sem grupos (`by = NULL`): retorna os `n` termos mais frequentes no
  geral;

- com grupos (`by = c("partido", ...)`): retorna os `n` termos mais
  frequentes em cada combinacao de metadados.

## Usage

``` r
ac_top_terms(x, n = 20L, by = NULL, sort = TRUE)
```

## Arguments

- x:

  Um `data.frame` ou
  [`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
  contendo, no minimo, as colunas `token` e `n`. Em geral, o resultado
  de
  [`ac_count()`](https://andersonheri.github.io/acR/reference/ac_count.md).

- n:

  Numero de termos a selecionar. Valor inteiro \>= 1.

- by:

  Vetor de nomes de colunas em `x` a serem usados como grupos de
  agregacao. Se `NULL` (padrao), a selecao e feita no conjunto total. Se
  nao for `NULL`, os `n` termos mais frequentes sao selecionados dentro
  de cada combinacao de `by`.

- sort:

  Logico. Se `TRUE` (padrao), ordena a saida em ordem decrescente de
  frequencia (`n`). Se `FALSE`, preserva a ordem retornada pela operacao
  interna de selecao, apenas garantindo que os grupos (quando houver)
  venham juntos.

## Value

Um
[`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
com as mesmas colunas de `x`, mas restrito aos `n` termos mais
frequentes (no geral ou por grupo).

## See also

[`ac_count()`](https://andersonheri.github.io/acR/reference/ac_count.md),
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

# Top 10 termos no corpus inteiro
freq <- ac_count(corp)
ac_top_terms(freq, n = 10)
#> # A tibble: 20 × 3
#>    doc_id token          n
#>    <chr>  <chr>      <int>
#>  1 d1     CCJ.           1
#>  2 d3     CCJ.           1
#>  3 d1     O              1
#>  4 d2     O              1
#>  5 d3     O              1
#>  6 d2     PL             1
#>  7 d1     PT             1
#>  8 d3     PT             1
#>  9 d1     deputado       1
#> 10 d2     deputado       1
#> 11 d1     do             1
#> 12 d2     do             1
#> 13 d3     do             1
#> 14 d1     falou          1
#> 15 d2     falou          1
#> 16 d3     falou          1
#> 17 d1     na             1
#> 18 d3     na             1
#> 19 d2     novamente.     1
#> 20 d3     senador        1

# Top 5 termos por partido
freq_by <- ac_count(corp, by = "partido")
ac_top_terms(freq_by, n = 5, by = "partido")
#> # A tibble: 12 × 3
#>    partido token          n
#>    <chr>   <chr>      <int>
#>  1 PL      O              1
#>  2 PL      PL             1
#>  3 PL      deputado       1
#>  4 PL      do             1
#>  5 PL      falou          1
#>  6 PL      novamente.     1
#>  7 PT      CCJ.           2
#>  8 PT      O              2
#>  9 PT      PT             2
#> 10 PT      do             2
#> 11 PT      falou          2
#> 12 PT      na             2
```
