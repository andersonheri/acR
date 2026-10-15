# Salvar ou carregar um dicionário em YAML

`ac_dictionary_save()` grava um dicionário (ver
[`ac_build_dictionary()`](https://andersonheri.github.io/acR/reference/ac_build_dictionary.md))
em um arquivo YAML legível por humanos, para versionar, compartilhar
entre pesquisadores ou editar fora do R. `ac_dictionary_load()` faz o
caminho inverso.

## Usage

``` r
ac_dictionary_save(dictionary, path)

ac_dictionary_load(path)
```

## Arguments

- dictionary:

  Lista nomeada de vetores de caracteres.

- path:

  Caminho do arquivo `.yaml`.

## Value

`ac_dictionary_save()`: o caminho do arquivo, de forma invisível.
`ac_dictionary_load()`: o dicionário (lista nomeada de vetores de
caracteres).

## See also

[`ac_build_dictionary()`](https://andersonheri.github.io/acR/reference/ac_build_dictionary.md),
[`ac_dictionary_import()`](https://andersonheri.github.io/acR/reference/ac_dictionary_import.md)

## Examples

``` r
dict <- ac_build_dictionary(
  positivo = c("bom", "ótimo"),
  negativo = c("mau", "péssimo")
)
arquivo <- tempfile(fileext = ".yaml")
ac_dictionary_save(dict, arquivo)

dict2 <- ac_dictionary_load(arquivo)
identical(dict, dict2)
#> [1] TRUE
```
