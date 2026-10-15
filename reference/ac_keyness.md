# Calcular estatísticas de keyness entre dois grupos

`ac_keyness()` calcula estatísticas de "keyness" para comparar a
distribuicao de termos entre dois grupos. O criterio que define os
grupos e do pesquisador: partido, periodo, tema, regiao, autor, condicao
experimental ou qualquer variável categorica no corpus. A função e
inspirada em `quanteda.textstats::textstat_keyness()` e utiliza tabelas
2x2 por termo.

A entrada típica e uma tabela de frequências gerada por
[`ac_count()`](https://ahenriquecp.com/acR/reference/ac_count.md),
agregada por uma coluna de grupo:

- `ac_count(corp, by = "grupo")` seguido de

- `ac_keyness(freq, group = "grupo", target = "A")`.

## Usage

``` r
ac_keyness(x, group, target, measure = c("chi2", "ll"), sort = TRUE)
```

## Arguments

- x:

  Um `data.frame` ou
  [`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
  contendo, no mínimo, as colunas `token`, `n` e uma coluna de grupo.

- group:

  Nome da coluna em `x` que identifica os grupos (string). Essa coluna
  deve possuir exatamente dois valores distintos.

- target:

  Valor de `group` que sera considerado o grupo alvo (por exemplo,
  `"Governo"`). O outro valor sera tratado como grupo de referência.

- measure:

  Estatística de keyness a ser usada. Pode ser `"chi2"` (padrao) para
  qui-quadrado com 1 grau de liberdade, ou `"ll"` para log-likelihood
  (G^2).

- sort:

  Lógico. Se `TRUE` (padrao), ordena a saida por `keyness` em ordem
  decrescente (termos mais caracteristicos do grupo alvo no topo).

## Value

Um
[`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
com uma linha por termo, contendo:

- `token`

- `group` (nome da coluna de grupo, repetido para referência)

- `target`, `reference`

- `n_target`, `n_reference`

- `total_target`, `total_reference`

- `keyness` (estatística assinada, positiva quando o termo e mais
  frequente no grupo alvo, negativa quando e mais frequente no grupo de
  referência)

- `direction` (nome do grupo em que o termo e relativamente mais
  frequente)

## Details

Para cada termo, a função constroi uma tabela 2x2:

- `a = n_target` (frequência do termo no grupo alvo)

- `b = n_reference` (frequência do termo no grupo de referência)

- `c = total_target - a`

- `d = total_reference - b`

Em seguida, calcula:

- qui-quadrado com 1 g.l. na opcao `measure = "chi2"`;

- log-likelihood ratio (G^2) na opcao `measure = "ll"`.

Em ambos os casos, a estatística e multiplicada pelo sinal da diferenca
de frequências relativas `(a / total_target - b / total_reference)`, de
forma que valores positivos indiquem termos mais caracteristicos do
grupo alvo e valores negativos termos mais caracteristicos do grupo de
referência.

## See also

[`ac_count()`](https://ahenriquecp.com/acR/reference/ac_count.md),
[`ac_top_terms()`](https://ahenriquecp.com/acR/reference/ac_top_terms.md),
[`ac_tf_idf()`](https://ahenriquecp.com/acR/reference/ac_tf_idf.md)

## Examples

``` r
# Comparar vocabulário entre dois grupos (aqui, dois temas legislativos).
# O criterio de grupo e do pesquisador: partido, periodo, regiao, tema...
df <- data.frame(
  id    = paste0("d", 1:8),
  texto = c(
    "reforma tributária simplifica sistema impostos empresas",
    "IVA dual substitui PIS COFINS ICMS federal",
    "aliquotas excecoes tributárias setores economicos",
    "reforma tributária unifica impostos indiretos",
    "programa habitacional amplia recursos moradia popular",
    "deficit habitacional afeta familias baixa renda",
    "urbanizacao favelas regularizacao fundiária municipios",
    "moradia digna direito social constituicao"
  ),
  tema  = rep(c("tributário", "habitacao"), each = 4),
  stringsAsFactors = FALSE
)

corp <- ac_corpus(df, text = texto, docid = id)
freq <- ac_count(corp, by = "tema")

# Termos-chave do grupo "tributário" versus o resto
key <- ac_keyness(freq, group = "tema", target = "tributário")
head(key)
#> # A tibble: 6 × 10
#>   token group target reference n_target n_reference total_target total_reference
#>   <chr> <chr> <chr>  <chr>        <dbl>       <dbl>        <dbl>           <dbl>
#> 1 impo… tema  tribu… habitacao        2           0           23              22
#> 2 refo… tema  tribu… habitacao        2           0           23              22
#> 3 trib… tema  tribu… habitacao        2           0           23              22
#> 4 COFI… tema  tribu… habitacao        1           0           23              22
#> 5 ICMS  tema  tribu… habitacao        1           0           23              22
#> 6 IVA   tema  tribu… habitacao        1           0           23              22
#> # ℹ 2 more variables: keyness <dbl>, direction <chr>
```
