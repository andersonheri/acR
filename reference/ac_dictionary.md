# Classificar conteúdo com um dicionário multi-categoria

`ac_dictionary()` conta, para cada documento de um `ac_corpus`, quantas
palavras caem em cada categoria de um dicionário — generalização do
método que
[`ac_sentiment()`](https://ahenriquecp.com/acR/reference/ac_sentiment.md)
já aplica só para polaridade (positivo/negativo). Um dicionário aqui é
qualquer lista nomeada de listas de palavras: temas ("economia",
"saúde"), enquadramentos ("ameaça", "oportunidade"), categorias de
produto, ou qualquer taxonomia definida a priori pelo pesquisador.

Métodos de dicionário são o método mais antigo e mais transparente de
análise de conteúdo assistida por computador (Stone et al., 1966, *The
General Inquirer*; revisado em Grimmer & Stewart, 2013): toda decisão de
classificação é auditável — basta olhar a lista de palavras. O preço é a
falta de sensibilidade a contexto: a palavra "não" imediatamente antes
de um termo do dicionário não inverte a contagem, e sarcasmo ou negação
sofisticada passam batido. Para esses casos, o pipeline de LLM
([`ac_qual_code()`](https://ahenriquecp.com/acR/reference/ac_qual_code.md))
é a alternativa — mais caro, menos transparente, mas sensível a
contexto.

## Usage

``` r
ac_dictionary(corpus, dictionary, by = NULL, case_insensitive = TRUE)
```

## Arguments

- corpus:

  Objeto `ac_corpus`.

- dictionary:

  Lista nomeada de vetores de caracteres — uma entrada por categoria,
  cada uma com as palavras daquela categoria (ver
  [`ac_build_dictionary()`](https://ahenriquecp.com/acR/reference/ac_build_dictionary.md)).
  Palavras são comparadas a tokens individuais (correspondência exata,
  não substring).

- by:

  Coluna(s) de agrupamento para agregar além do documento (ex.:
  `"categoria_produto"`). Padrão: `NULL` (uma linha por documento).

- case_insensitive:

  Lógico. Se `TRUE` (padrão), ignora diferenças de maiúsculas/minúsculas
  na comparação.

## Value

Tibble com uma linha por documento (ou grupo), contendo `total_tokens`
e, para cada categoria do dicionário, duas colunas: `<categoria>_n`
(contagem de palavras daquela categoria) e `<categoria>_prop` (proporção
sobre `total_tokens`).

## References

Stone, P. J.; Dunphy, D. C.; Smith, M. S.; Ogilvie, D. M. (1966). *The
General Inquirer: A Computer Approach to Content Analysis*. MIT Press.

Grimmer, J.; Stewart, B. M. (2013). Text as Data: The Promise and
Pitfalls of Automatic Content Analysis Methods for Political Texts.
*Political Analysis*, 21(3), 267-297.

## See also

[`ac_build_dictionary()`](https://ahenriquecp.com/acR/reference/ac_build_dictionary.md),
[`ac_sentiment()`](https://ahenriquecp.com/acR/reference/ac_sentiment.md),
[`ac_qual_code()`](https://ahenriquecp.com/acR/reference/ac_qual_code.md)

## Examples

``` r
# Reclamacoes de clientes, categorizadas por tema do problema
df <- data.frame(
  id = paste0("c", 1:4),
  texto = c(
    "a entrega atrasou muito e o rastreio nao funcionava",
    "o produto chegou com defeito e quebrado na caixa",
    "cobraram duas vezes no cartao e o reembolso demorou",
    "entrega rapida mas o produto tinha um defeito de fabrica"
  ),
  stringsAsFactors = FALSE
)
corpus <- ac_corpus(df, text = texto, docid = id)

dict <- ac_build_dictionary(
  entrega    = c("entrega", "atrasou", "rastreio", "rapida"),
  produto    = c("defeito", "quebrado", "fabrica"),
  financeiro = c("cobraram", "cartao", "reembolso")
)

ac_dictionary(corpus, dict)
#> # A tibble: 4 × 8
#>   doc_id total_tokens entrega_n produto_n financeiro_n entrega_prop produto_prop
#>   <chr>         <int>     <int>     <int>        <int>        <dbl>        <dbl>
#> 1 c1                9         3         0            0        0.333        0    
#> 2 c2                9         0         2            0        0            0.222
#> 3 c3                9         0         0            3        0            0    
#> 4 c4               10         2         2            0        0.2          0.2  
#> # ℹ 1 more variable: financeiro_prop <dbl>
```
