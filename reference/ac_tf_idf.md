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
# Corpus com discursos sobre tres agendas distintas.
# TF-IDF vai destacar o vocabulario proprio de cada texto,
# nao os termos comuns a todos (que a frequencia bruta mostraria).
df <- data.frame(
  id    = paste0("d", 1:6),
  texto = c(
    "reforma tributaria simplifica sistema impostos empresas",
    "IVA dual substitui PIS COFINS ICMS federal",
    "programa habitacional amplia recursos moradia popular urbana",
    "deficit habitacional afeta familias baixa renda cidades",
    "educacao basica recebe recursos Fundeb Congresso",
    "alfabetizacao idade certa meta Plano Nacional Educacao"
  ),
  tema  = rep(c("tributario", "habitacao", "educacao"), each = 2),
  stringsAsFactors = FALSE
)

corp <- ac_corpus(df, text = texto, docid = id)

# TF-IDF por documento
freq  <- ac_count(corp)
tfidf <- ac_tf_idf(freq)
head(tfidf)
#> # A tibble: 6 × 6
#>   doc_id token          n    tf   idf tf_idf
#>   <chr>  <chr>      <int> <dbl> <dbl>  <dbl>
#> 1 d1     empresas       1 0.167  1.79  0.299
#> 2 d1     impostos       1 0.167  1.79  0.299
#> 3 d1     reforma        1 0.167  1.79  0.299
#> 4 d1     simplifica     1 0.167  1.79  0.299
#> 5 d1     sistema        1 0.167  1.79  0.299
#> 6 d1     tributaria     1 0.167  1.79  0.299

# TF-IDF por tema (cada tema tratado como "documento agregado")
freq_by  <- ac_count(corp, by = "tema")
tfidf_by <- ac_tf_idf(freq_by, by = "tema")
head(tfidf_by)
#> # A tibble: 6 × 6
#>   tema      token            n     tf   idf tf_idf
#>   <chr>     <chr>        <int>  <dbl> <dbl>  <dbl>
#> 1 habitacao habitacional     2 0.143   1.10 0.157 
#> 2 educacao  Congresso        1 0.0769  1.10 0.0845
#> 3 educacao  Educacao         1 0.0769  1.10 0.0845
#> 4 educacao  Fundeb           1 0.0769  1.10 0.0845
#> 5 educacao  Nacional         1 0.0769  1.10 0.0845
#> 6 educacao  Plano            1 0.0769  1.10 0.0845
```
