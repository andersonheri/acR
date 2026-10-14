# Importar um dicionário de uma tabela em formato longo

`ac_dictionary_import()` constrói um dicionário (ver
[`ac_build_dictionary()`](https://andersonheri.github.io/acR/reference/ac_build_dictionary.md))
a partir de uma tabela em formato longo — uma linha por par
palavra-categoria — o formato em que léxicos costumam ser distribuídos
(CSV, planilha). Útil para importar listas de palavras construídas fora
do R, ou léxicos de terceiros já traduzidos/adaptados para português (o
pacote não distribui nenhum léxico de categorias além do OpLexicon usado
em
[`ac_sentiment()`](https://andersonheri.github.io/acR/reference/ac_sentiment.md)
— veja `vignette("dicionarios")` para onde encontrar léxicos de
terceiros e como adaptá-los a este formato).

## Usage

``` r
ac_dictionary_import(data, term_col = "termo", category_col = "categoria", ...)
```

## Arguments

- data:

  Um `data.frame`/tibble em formato longo, ou o caminho de um arquivo
  `.csv` nesse formato.

- term_col:

  Nome da coluna com a palavra. Padrão: `"termo"`.

- category_col:

  Nome da coluna com a categoria. Padrão: `"categoria"`.

- ...:

  Argumentos adicionais passados a
  [`utils::read.csv()`](https://rdrr.io/r/utils/read.table.html) quando
  `data` é um caminho de arquivo (ex.: `sep`, `fileEncoding`).

## Value

Lista nomeada de vetores de caracteres (um dicionário), uma entrada por
valor distinto de `category_col`.

## See also

[`ac_build_dictionary()`](https://andersonheri.github.io/acR/reference/ac_build_dictionary.md),
[`ac_dictionary_save()`](https://andersonheri.github.io/acR/reference/ac_dictionary_save.md)

## Examples

``` r
lexico <- data.frame(
  termo     = c("bom", "otimo", "mau", "pessimo"),
  categoria = c("positivo", "positivo", "negativo", "negativo"),
  stringsAsFactors = FALSE
)
ac_dictionary_import(lexico)
#> $negativo
#> [1] "mau"     "pessimo"
#> 
#> $positivo
#> [1] "bom"   "otimo"
#> 
```
