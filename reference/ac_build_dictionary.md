# Construir um dicionário multi-categoria

`ac_build_dictionary()` monta um dicionário no formato esperado por
[`ac_dictionary()`](https://ahenriquecp.com/acR/reference/ac_dictionary.md)
a partir de argumentos nomeados: cada argumento é uma categoria, e seu
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

[`ac_dictionary()`](https://ahenriquecp.com/acR/reference/ac_dictionary.md),
[`ac_dictionary_import()`](https://ahenriquecp.com/acR/reference/ac_dictionary_import.md),
[`ac_dictionary_save()`](https://ahenriquecp.com/acR/reference/ac_dictionary_save.md)

## Examples

``` r
dict <- ac_build_dictionary(
  positivo = c("bom", "ótimo", "excelente"),
  negativo = c("mau", "péssimo", "horrivel")
)
dict
#> $positivo
#> [1] "bom"       "ótimo"     "excelente"
#> 
#> $negativo
#> [1] "mau"      "péssimo"  "horrivel"
#> 
```
