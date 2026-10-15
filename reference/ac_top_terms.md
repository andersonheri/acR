# Selecionar os termos mais frequentes

`ac_top_terms()` seleciona os `n` termos mais frequentes a partir de uma
tabela de frequências (tipicamente o resultado de
[`ac_count()`](https://ahenriquecp.com/acR/reference/ac_count.md)).

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
  contendo, no mínimo, as colunas `token` e `n`. Em geral, o resultado
  de [`ac_count()`](https://ahenriquecp.com/acR/reference/ac_count.md).

- n:

  Número de termos a selecionar. Valor inteiro \>= 1.

- by:

  Vetor de nomes de colunas em `x` a serem usados como grupos de
  agregacao. Se `NULL` (padrao), a selecao e feita no conjunto total. Se
  não for `NULL`, os `n` termos mais frequentes sao selecionados dentro
  de cada combinacao de `by`.

- sort:

  Lógico. Se `TRUE` (padrão), ordena a saída em ordem decrescente de
  frequência (`n`). Se `FALSE`, ordena os termos selecionados
  alfabeticamente (dentro de cada grupo, quando houver).

## Value

Um
[`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
com as colunas `token` e `n` (mais as colunas de `by`, se houver), com
exatamente `n` termos (ou menos, se o vocabulário for menor) no geral ou
por grupo. A frequência de cada termo é **somada** sobre os documentos
(ou dentro de cada grupo), de modo que uma tabela por documento, saída
padrão de
[`ac_count()`](https://ahenriquecp.com/acR/reference/ac_count.md), dá o
total do corpus. Empates na última posição são desfeitos em ordem
alfabética.

## See also

[`ac_count()`](https://ahenriquecp.com/acR/reference/ac_count.md),
[`ac_tokenize()`](https://ahenriquecp.com/acR/reference/ac_tokenize.md)

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
#> # A tibble: 10 × 2
#>    token          n
#>    <chr>      <int>
#>  1 O              3
#>  2 do             3
#>  3 falou          3
#>  4 CCJ.           2
#>  5 PT             2
#>  6 deputado       2
#>  7 na             2
#>  8 PL             1
#>  9 novamente.     1
#> 10 senador        1

# Top 5 termos por partido
freq_by <- ac_count(corp, by = "partido")
ac_top_terms(freq_by, n = 5, by = "partido")
#> # A tibble: 10 × 3
#>    partido token        n
#>    <chr>   <chr>    <int>
#>  1 PL      O            1
#>  2 PL      PL           1
#>  3 PL      deputado     1
#>  4 PL      do           1
#>  5 PL      falou        1
#>  6 PT      CCJ.         2
#>  7 PT      O            2
#>  8 PT      PT           2
#>  9 PT      do           2
#> 10 PT      falou        2
```
