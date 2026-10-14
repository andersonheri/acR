# Calcular diversidade lexical (riqueza de vocabulário)

`ac_lexical_diversity()` mede quão variado é o vocabulário dos
documentos de um `ac_corpus` — uma pergunta recorrente em linguística
computacional (textos de falantes nativos vs. aprendizes de uma língua),
análise de redações escolares, estudos de estilo autoral, ou comparação
de roteiros/transcrições por gênero ou locutor.

Calcula três métricas, cada uma respondendo à mesma pergunta de forma
diferente — e cada uma com um ponto fraco diferente:

- **TTR** (*Type-Token Ratio*): proporção simples `tipos / tokens`.
  Fácil de entender, mas extremamente sensível ao tamanho do texto —
  textos mais longos quase sempre têm TTR menor, então **não compare TTR
  entre documentos de tamanhos muito diferentes**.

- **C de Herdan** (Herdan, 1960): `log(tipos) / log(tokens)`. Mais
  estável que TTR frente a variação de tamanho, mas ainda não é
  totalmente independente do comprimento do texto.

- **MTLD** (*Measure of Textual Lexical Diversity*; McCarthy & Jarvis,
  2010): percorre o texto token a token acumulando um "fator" sempre que
  a TTR local cai abaixo de 0,72, e usa a média de fatores nos sentidos
  direto e reverso. É a métrica recomendada quando os documentos
  comparados têm tamanhos desiguais.

## Usage

``` r
ac_lexical_diversity(corpus, by = NULL, case_sensitive = FALSE)
```

## Arguments

- corpus:

  Objeto `ac_corpus`.

- by:

  Coluna(s) de agrupamento para agregar a diversidade lexical além do
  documento (ex.: `"autor"`, `"genero"`). Padrão: `NULL` (uma linha por
  documento).

- case_sensitive:

  Lógico. Se `FALSE` (padrão), trata `"Casa"` e `"casa"` como o mesmo
  tipo lexical.

## Value

Tibble com colunas:

- `doc_id` (ou as colunas de `by`, se informado);

- `n_tokens`, `n_types`: contagens de tokens e tipos (palavras únicas);

- `ttr`, `herdan_c`, `mtld`: as três métricas descritas acima.

## References

Herdan, G. (1960). *Type-Token Mathematics: A Textbook of Mathematical
Linguistics*. Mouton.

McCarthy, P. M.; Jarvis, S. (2010). MTLD, vocd-D, and HD-D: A validation
study of sophisticated approaches to lexical diversity assessment.
*Behavior Research Methods*, 42(2), 381-392.

## See also

[`ac_readability()`](https://ahenriquecp.com/acR/reference/ac_readability.md)

## Examples

``` r
# Transcricoes de dois narradores com estilos de vocabulario distintos
df <- data.frame(
  id = paste0("t", 1:4),
  texto = c(
    "o gato subiu no muro e desceu depois correu e subiu de novo",
    paste(
      "o felino ascendeu ao parapeito, permaneceu imovel por instantes,",
      "descendeu com cautela e retornou ao ponto de partida original"
    ),
    "ela correu muito rapido e muito rapido e muito rapido ainda",
    paste(
      "a atleta acelerou vertiginosamente, superando marcas anteriores",
      "com uma performance notavel e consistente ao longo do percurso"
    )
  ),
  narrador = c("simples", "rebuscado", "simples", "rebuscado"),
  stringsAsFactors = FALSE
)
corpus <- ac_corpus(df, text = texto, docid = id, meta = narrador)

ac_lexical_diversity(corpus)
#> # A tibble: 4 × 6
#>   doc_id n_tokens n_types   ttr herdan_c  mtld
#>   <chr>     <int>   <int> <dbl>    <dbl> <dbl>
#> 1 t1           13      11 0.846    0.935  23.7
#> 2 t2           19      18 0.947    0.982 101. 
#> 3 t3           11       6 0.545    0.747  11  
#> 4 t4           17      17 1        1      17  

# Comparar riqueza de vocabulario entre os dois estilos narrativos
ac_lexical_diversity(corpus, by = "narrador")
#> # A tibble: 2 × 6
#>   narrador  n_tokens n_types   ttr herdan_c  mtld
#>   <chr>        <int>   <int> <dbl>    <dbl> <dbl>
#> 1 rebuscado       36      32 0.889    0.967  90.7
#> 2 simples         24      15 0.625    0.852  18.7
```
