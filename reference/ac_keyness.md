# Calcular estatisticas de keyness entre dois grupos

`ac_keyness()` calcula estatisticas de "keyness" para comparar a
distribuicao de termos entre dois grupos (por exemplo, governo vs
oposicao, partidos, periodos). A funcao e inspirada em
[`quanteda.textstats::textstat_keyness()`](https://quanteda.io/reference/textstat_keyness.html)
e utiliza tabelas 2x2 por termo.

A entrada tipica e uma tabela de frequencias gerada por
[`ac_count()`](https://andersonheri.github.io/acR/reference/ac_count.md),
agregada por uma coluna de grupo:

- `ac_count(corp, by = "lado")` seguido de

- `ac_keyness(freq, group = "lado", target = "Governo")`.

## Usage

``` r
ac_keyness(x, group, target, measure = c("chi2", "ll"), sort = TRUE)
```

## Arguments

- x:

  Um `data.frame` ou
  [`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
  contendo, no minimo, as colunas `token`, `n` e uma coluna de grupo.

- group:

  Nome da coluna em `x` que identifica os grupos (string). Essa coluna
  deve possuir exatamente dois valores distintos.

- target:

  Valor de `group` que sera considerado o grupo alvo (por exemplo,
  `"Governo"`). O outro valor sera tratado como grupo de referencia.

- measure:

  Estatistica de keyness a ser usada. Pode ser `"chi2"` (padrao) para
  qui-quadrado com 1 grau de liberdade, ou `"ll"` para log-likelihood
  (G^2).

- sort:

  Logico. Se `TRUE` (padrao), ordena a saida por `keyness` em ordem
  decrescente (termos mais caracteristicos do grupo alvo no topo).

## Value

Um
[`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
com uma linha por termo, contendo:

- `token`

- `group` (nome da coluna de grupo, repetido para referencia)

- `target`, `reference`

- `n_target`, `n_reference`

- `total_target`, `total_reference`

- `keyness` (estatistica assinada, positiva quando o termo e mais
  frequente no grupo alvo, negativa quando e mais frequente no grupo de
  referencia)

- `direction` (nome do grupo em que o termo e relativamente mais
  frequente)

## Details

Para cada termo, a funcao constroi uma tabela 2x2:

- `a = n_target` (frequencia do termo no grupo alvo)

- `b = n_reference` (frequencia do termo no grupo de referencia)

- `c = total_target - a`

- `d = total_reference - b`

Em seguida, calcula:

- qui-quadrado com 1 g.l. na opcao `measure = "chi2"`;

- log-likelihood ratio (G^2) na opcao `measure = "ll"`.

Em ambos os casos, a estatistica e multiplicada pelo sinal da diferenca
de frequencias relativas `(a / total_target - b / total_reference)`, de
forma que valores positivos indiquem termos mais caracteristicos do
grupo alvo e valores negativos termos mais caracteristicos do grupo de
referencia.

## See also

[`ac_count()`](https://andersonheri.github.io/acR/reference/ac_count.md),
[`ac_top_terms()`](https://andersonheri.github.io/acR/reference/ac_top_terms.md),
[`ac_tf_idf()`](https://andersonheri.github.io/acR/reference/ac_tf_idf.md)

## Examples

``` r
df <- data.frame(
  id    = c("d1", "d2", "d3", "d4"),
  texto = c(
    "A A A B",
    "A B",
    "A B B B",
    "B B C"
  ),
  lado  = c("Governo", "Governo", "Oposicao", "Oposicao"),
  stringsAsFactors = FALSE
)

corp <- ac_corpus(df, text = texto, docid = id, meta = lado)
freq <- ac_count(corp, by = "lado")

key <- ac_keyness(freq, group = "lado", target = "Governo")
```
