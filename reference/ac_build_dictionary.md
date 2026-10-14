# Construir um dicionário multi-categoria

`ac_build_dictionary()` monta um dicionário no formato esperado por
[`ac_dictionary()`](https://andersonheri.github.io/acR/reference/ac_dictionary.md)
a partir de argumentos nomeados — cada argumento é uma categoria, e seu
valor é o vetor de palavras daquela categoria.

## Usage

``` r
ac_build_dictionary(...)
```

## Arguments

- ...:

  Argumentos nomeados, cada um um vetor de caracteres.

## Value

Lista nomeada de vetores de caracteres (um dicionário).

## See also

[`ac_dictionary()`](https://andersonheri.github.io/acR/reference/ac_dictionary.md),
[`ac_dictionary_import()`](https://andersonheri.github.io/acR/reference/ac_dictionary_import.md),
[`ac_dictionary_save()`](https://andersonheri.github.io/acR/reference/ac_dictionary_save.md)

## Examples

``` r
dict <- ac_build_dictionary(
  positivo = c("bom", "otimo", "excelente"),
  negativo = c("mau", "pessimo", "horrivel")
)
dict
#> $positivo
#> [1] "bom"       "otimo"     "excelente"
#> 
#> $negativo
#> [1] "mau"      "pessimo"  "horrivel"
#> 
```
