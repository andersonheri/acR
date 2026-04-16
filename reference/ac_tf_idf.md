# Calcular tf-idf para termos em documentos ou grupos

`ac_tf_idf()` calcula a frequencia de termos (`tf`), a frequencia
inversa de documentos (`idf`) e o produto `tf_idf` a partir de uma
tabela de frequencias de termos (tipicamente o resultado de
[`ac_count()`](https://andersonheri.github.io/acR/reference/ac_count.md)).

A funcao segue a mesma logica de
[`tidytext::bind_tf_idf()`](https://juliasilge.github.io/tidytext/reference/bind_tf_idf.html),
mas adaptada para o fluxo de trabalho do pacote:

- sem grupos (`by = NULL`): cada `doc_id` e tratado como um documento;

- com grupos (`by = c("partido", ...)`): cada combinacao de metadados e
  tratada como um "documento" no calculo de `idf`.

## Usage

``` r
ac_tf_idf(x, by = NULL)
```

## Arguments

- x:

  Um `data.frame` ou
  [`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
  contendo, no minimo, as colunas `token` e `n`. Em geral, o resultado
  de
  [`ac_count()`](https://andersonheri.github.io/acR/reference/ac_count.md).

- by:

  Vetor de nomes de colunas em `x` que identificam documentos ou grupos.
  Se `NULL` (padrao), usa `doc_id` (que deve existir em `x`). Se nao for
  `NULL`, cada combinacao de `by` e tratada como um documento no calculo
  de `idf`.

## Value

Um
[`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
com as colunas originais de `x` mais tres colunas numeric as:

- `tf`: frequencia do termo no documento/grupo;

- `idf`: frequencia inversa de documentos;

- `tf_idf`: produto `tf * idf`.

## Details

A definicao de `tf`, `idf` e `tf_idf` segue a literatura padrao de
tf-idf em mineracao de texto:

- `tf` e a frequencia relativa do termo no documento;

- `idf` e log(N / df), em que N e o numero de documentos e df e o numero
  de documentos que contem o termo;

- `tf_idf` e o produto `tf * idf`.

A tabela de entrada deve ter exatamente uma linha por combinacao de
documento/grupo e termo (isto e, uma linha por termo-em-documento).

## See also

[`ac_count()`](https://andersonheri.github.io/acR/reference/ac_count.md),
[`ac_top_terms()`](https://andersonheri.github.io/acR/reference/ac_top_terms.md),
[`tidytext::bind_tf_idf()`](https://juliasilge.github.io/tidytext/reference/bind_tf_idf.html)

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

freq <- ac_count(corp)
tfidf <- ac_tf_idf(freq)

# tf-idf por partido (tratando cada partido como "documento")
freq_by <- ac_count(corp, by = "partido")
tfidf_by <- ac_tf_idf(freq_by, by = "partido")
```
