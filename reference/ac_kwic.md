# Concordância (keyword-in-context, KWIC)

`ac_kwic()` localiza todas as ocorrências de um termo (ou padrão) nos
documentos de um `ac_corpus` e devolve cada ocorrência com uma janela de
palavras antes e depois — a técnica de concordância usada desde os
primórdios da linguística de corpus (Sinclair, 1991) para entender
*como* uma palavra é usada, não só *com que frequência*.

É o complemento natural de uma análise de frequência ou keyness: saber
que "liberdade" é um termo-chave de um grupo não diz nada sobre como o
termo é empregado — a concordância mostra se aparece ao lado de
"econômica", "de expressão" ou "individual", revelando o enquadramento
(framing) real do termo em cada contexto. Funciona em qualquer corpus
com linguagem natural: reviews de produto, letras de música,
transcrições de atendimento, posts em redes sociais.

## Usage

``` r
ac_kwic(corpus, pattern, window = 5L, regex = FALSE, case_insensitive = TRUE)
```

## Arguments

- corpus:

  Objeto `ac_corpus`.

- pattern:

  Termo ou expressão regular a localizar (string única).

- window:

  Número de palavras de contexto a mostrar antes e depois de cada
  ocorrência. Padrão: `5`.

- regex:

  Lógico. Se `FALSE` (padrão), `pattern` é tratado como uma palavra
  exata (comparação literal, após normalização de caixa). Se `TRUE`,
  `pattern` é tratado como expressão regular (POSIX) aplicada a cada
  token.

- case_insensitive:

  Lógico. Se `TRUE` (padrão), ignora diferenças de maiúsculas/minúsculas
  na busca.

## Value

Tibble com uma linha por ocorrência, colunas:

- `doc_id`: documento onde a ocorrência foi encontrada;

- `position`: posição do token correspondente no documento;

- `before`: até `window` palavras imediatamente antes;

- `keyword`: o token que casou com `pattern`, como aparece no texto;

- `after`: até `window` palavras imediatamente depois.

## References

Sinclair, J. (1991). *Corpus, Concordance, Collocation*. Oxford
University Press.

## See also

[`ac_plot_xray()`](https://andersonheri.github.io/acR/reference/ac_plot_xray.md),
[`ac_count()`](https://andersonheri.github.io/acR/reference/ac_count.md)

## Examples

``` r
# Avaliacoes de atendimento ao cliente
df <- data.frame(
  id = paste0("a", 1:4),
  texto = c(
    "o atendimento foi rapido e a atendente foi muito educada comigo",
    "fiquei esperando muito tempo e o atendimento foi frio e distante",
    "atendimento excelente, resolveram meu problema na hora",
    "o atendimento automatico nao entendeu minha solicitacao"
  ),
  stringsAsFactors = FALSE
)
corpus <- ac_corpus(df, text = texto, docid = id)

ac_kwic(corpus, pattern = "atendimento", window = 3)
#> # A tibble: 4 × 5
#>   doc_id position before      keyword     after                    
#>   <chr>     <int> <chr>       <chr>       <chr>                    
#> 1 a1            2 "o"         atendimento foi rapido e             
#> 2 a2            7 "tempo e o" atendimento foi frio e               
#> 3 a3            1 ""          atendimento excelente, resolveram meu
#> 4 a4            2 "o"         atendimento automatico nao entendeu  
```
