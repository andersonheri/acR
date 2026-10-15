# Validar um dicionário contra codificação humana

`ac_dictionary_validate()` compara a classificação por dicionário (saída
de
[`ac_dictionary()`](https://andersonheri.github.io/acR/reference/ac_dictionary.md),
[`ac_emotion()`](https://andersonheri.github.io/acR/reference/ac_emotion.md)
ou
[`ac_sentiment()`](https://andersonheri.github.io/acR/reference/ac_sentiment.md)
com categorias binarizadas) contra uma codificação de referência humana,
categoria por categoria: a mesma lógica de validação que
[`ac_qual_reliability()`](https://andersonheri.github.io/acR/reference/ac_qual_reliability.md)
aplica à classificação por LLM (com `by_variable = TRUE`), agora para o
método de dicionário.

Nenhum dicionário deveria ser usado numa análise publicável sem essa
etapa (Grimmer & Stewart, 2013): um dicionário construído à mão pode
parecer razoável e ainda assim ter baixa precisão ou recall numa
categoria específica: só a comparação com uma amostra codificada por
humano revela isso.

## Usage

``` r
ac_dictionary_validate(scored, human, cat_col = "categoria", threshold = 0)
```

## Arguments

- scored:

  Tibble retornado por
  [`ac_dictionary()`](https://andersonheri.github.io/acR/reference/ac_dictionary.md)
  ou
  [`ac_emotion()`](https://andersonheri.github.io/acR/reference/ac_emotion.md)
  (com colunas `doc_id` e `<categoria>_n` por categoria).

- human:

  Tibble com colunas `doc_id` e uma coluna de categoria (ver `cat_col`):
  a codificação humana de referência, no mesmo formato aceito por
  [`ac_qual_reliability()`](https://andersonheri.github.io/acR/reference/ac_qual_reliability.md)
  (multilabel como string separada por `"|"`).

- cat_col:

  Nome da coluna de categoria em `human`. Padrão: `"categoria"`.

- threshold:

  Contagem mínima em `<categoria>_n` para o dicionário considerar a
  categoria presente no documento. Padrão: `0` (qualquer palavra da
  categoria presente já conta).

## Value

Tibble com uma linha por categoria do dicionário e colunas `categoria`,
`n`, `vp`, `fp`, `fn`, `vn`, `concordância`, `precisao`, `recall`, `f1`,
`gwet_ac1`, `krippendorff_alfa`: as mesmas colunas de
`attr(ac_qual_reliability(...), "by_variable")`. Denominadores
indefinidos (ex.: uma categoria que nenhum dos dois lados marcou) geram
`NA`, nunca `0` ou `1` artificiais.

## References

Grimmer, J.; Stewart, B. M. (2013). Text as Data: The Promise and
Pitfalls of Automatic Content Analysis Methods for Political Texts.
*Political Analysis*, 21(3), 267-297.

## See also

[`ac_dictionary()`](https://andersonheri.github.io/acR/reference/ac_dictionary.md),
[`ac_qual_reliability()`](https://andersonheri.github.io/acR/reference/ac_qual_reliability.md)

## Examples

``` r
df <- data.frame(
  id = paste0("d", 1:4),
  texto = c(
    "a entrega atrasou muito",
    "o produto chegou com defeito",
    "cobraram duas vezes no cartao",
    "entrega rápida e produto perfeito"
  ),
  stringsAsFactors = FALSE
)
corpus <- ac_corpus(df, text = texto, docid = id)
dict <- ac_build_dictionary(
  entrega = c("entrega", "atrasou", "rápida"),
  produto = c("defeito", "perfeito")
)
scored <- ac_dictionary(corpus, dict)

# Codificacao humana de referência (simulada para o exemplo)
human <- tibble::tibble(
  doc_id    = paste0("d", 1:4),
  categoria = c("entrega", "produto", NA, "entrega|produto")
)

ac_dictionary_validate(scored, human)
#> # A tibble: 2 × 12
#>   categoria     n    vp    fp    fn    vn concordancia precisao recall    f1
#>   <chr>     <int> <int> <int> <int> <int>        <dbl>    <dbl>  <dbl> <dbl>
#> 1 entrega       3     2     0     0     1            1        1      1     1
#> 2 produto       3     2     0     0     1            1        1      1     1
#> # ℹ 2 more variables: gwet_ac1 <dbl>, krippendorff_alfa <dbl>
```
