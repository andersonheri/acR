# Verificar se um objeto é um corpus do `acR`

Função auxiliar para testar se um objeto pertence à classe `ac_corpus`.
Útil para validação de argumentos em funções do pipeline.

## Usage

``` r
is_ac_corpus(x)
```

## Arguments

- x:

  Objeto qualquer a ser testado.

## Value

`TRUE` se `x` é um objeto de classe `ac_corpus`, `FALSE` caso contrário.

## Examples

``` r
corpus <- ac_corpus(c("Texto um.", "Texto dois."))
is_ac_corpus(corpus)         # TRUE
#> [1] TRUE
is_ac_corpus(data.frame())   # FALSE
#> [1] FALSE
is_ac_corpus("texto solto")  # FALSE
#> [1] FALSE
```
