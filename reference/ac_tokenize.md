# Tokenizar textos de um corpus acR

`ac_tokenize()` recebe um objeto
[`ac_corpus()`](https://andersonheri.github.io/acR/reference/ac_corpus.md)
e retorna um `tibble` em formato *tidy*, com um token por linha, no
estilo usado em analises de texto no ecossistema tidy.

A funcao implementa tokenizacao em palavras (n = 1) ou n-gramas de
tamanho arbitrario (n \> 1), usando janelas contiguas de tokens dentro
de cada documento.

## Usage

``` r
ac_tokenize(
  corpus,
  token = c("word"),
  n = 1L,
  keep_empty = FALSE,
  drop_punct = FALSE,
  ...
)
```

## Arguments

- corpus:

  Objeto de classe
  [`ac_corpus()`](https://andersonheri.github.io/acR/reference/ac_corpus.md).

- token:

  Tipo de tokenizacao desejada. Atualmente apenas `"word"` e suportado
  (padrao), reservado para futura expansao.

- n:

  Tamanho do n-grama. Deve ser um inteiro maior ou igual a 1. Para
  `n = 1`, o resultado sao tokens individuais; para `n = 2`, bigramas
  (`"A B"`), para `n = 3`, trigramas etc.

- keep_empty:

  Logico. Se `FALSE` (padrao), documentos que resultarem em texto vazio
  apos a limpeza nao geram linhas na saida. Se `TRUE`, cada documento
  vazio gera uma linha com `token = NA` quando `n = 1`.

- drop_punct:

  Logico. Se `TRUE`, remove da sequencia tokens que consistem apenas de
  pontuacao (por exemplo `"!"`, `"..."`) antes de construir n-gramas.
  Tokens que misturam letras e pontuacao (por exemplo `"ola,"`) sao
  mantidos.

- ...:

  Ignorado, reservado para argumentos futuros.

## Value

Um
[`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
com colunas:

- `doc_id`: identificador do documento (herdado de `ac_corpus`);

- `token_id`: posicao (1, 2, 3, ...) do token ou n-grama no documento;

- `token`: texto do token ou n-grama.

## See also

[`ac_corpus()`](https://andersonheri.github.io/acR/reference/ac_corpus.md),
[`ac_clean()`](https://andersonheri.github.io/acR/reference/ac_clean.md)

## Examples

``` r
df <- data.frame(
  id    = c("d1", "d2"),
  texto = c(
    "O deputado do PT falou na CCJ.",
    "Votar pra valer, agora!"
  )
)

corp <- ac_corpus(df, text = texto, docid = id)

# Tokenizacao simples em palavras
tokens <- ac_tokenize(corp)
tokens
#> # A tibble: 11 × 3
#>    doc_id token_id token   
#>    <chr>     <int> <chr>   
#>  1 d1            1 O       
#>  2 d1            2 deputado
#>  3 d1            3 do      
#>  4 d1            4 PT      
#>  5 d1            5 falou   
#>  6 d1            6 na      
#>  7 d1            7 CCJ.    
#>  8 d2            1 Votar   
#>  9 d2            2 pra     
#> 10 d2            3 valer,  
#> 11 d2            4 agora!  

# Removendo tokens que sao apenas pontuacao
df2 <- data.frame(
  id    = "d1",
  texto = "Ola, mundo ! ..."
)
corp2   <- ac_corpus(df2, text = texto, docid = id)
tokens2 <- ac_tokenize(corp2, drop_punct = TRUE)
tokens2
#> # A tibble: 2 × 3
#>   doc_id token_id token
#>   <chr>     <int> <chr>
#> 1 d1            1 Ola, 
#> 2 d1            2 mundo

# Bigramas
ac_tokenize(corp, n = 2)
#> # A tibble: 9 × 3
#>   doc_id token_id token        
#>   <chr>     <int> <chr>        
#> 1 d1            1 O deputado   
#> 2 d1            2 deputado do  
#> 3 d1            3 do PT        
#> 4 d1            4 PT falou     
#> 5 d1            5 falou na     
#> 6 d1            6 na CCJ.      
#> 7 d2            1 Votar pra    
#> 8 d2            2 pra valer,   
#> 9 d2            3 valer, agora!
```
