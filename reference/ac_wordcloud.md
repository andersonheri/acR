# Criar nuvem de palavras

`ac_wordcloud()` cria uma nuvem de palavras a partir de uma tabela de
frequencias, tipicamente gerada por
[`ac_count()`](https://andersonheri.github.io/acR/reference/ac_count.md).

A funcao usa o pacote `wordcloud` para desenhar a nuvem e trabalha com
as colunas `token` e `n`.

## Usage

``` r
ac_wordcloud(
  x,
  max_words = 100,
  min_n = 1,
  scale = c(4, 0.8),
  random_order = FALSE,
  colors = c("#2C7FB8", "#7FCDBB", "#EDF8B1", "#253494"),
  ...
)
```

## Arguments

- x:

  Um `data.frame` ou
  [`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
  contendo, no minimo, as colunas `token` e `n`.

- max_words:

  Numero maximo de palavras a desenhar. Padrao: `100`.

- min_n:

  Frequencia minima para incluir um termo. Padrao: `1`.

- scale:

  Vetor numerico de comprimento 2 indicando o intervalo de tamanhos das
  palavras. Padrao: `c(4, 0.8)`.

- random_order:

  Logico. Se `TRUE`, plota em ordem aleatoria. Se `FALSE` (padrao), as
  palavras mais frequentes tendem a aparecer mais ao centro.

- colors:

  Vetor de cores usado no grafico. Padrao:
  `c("#2C7FB8", "#7FCDBB", "#EDF8B1", "#253494")`.

- ...:

  Argumentos adicionais encaminhados para
  [`wordcloud::wordcloud()`](https://rdrr.io/pkg/wordcloud/man/wordcloud.html).

## Value

Invisivelmente, o `data.frame` filtrado usado para desenhar a nuvem de
palavras.

## Details

Como
[`wordcloud::wordcloud()`](https://rdrr.io/pkg/wordcloud/man/wordcloud.html)
desenha diretamente no dispositivo grafico ativo, esta funcao nao
retorna um objeto `ggplot`. Em vez disso, produz o grafico como efeito
colateral e retorna invisivelmente a tabela usada no desenho.

## See also

[`ac_count()`](https://andersonheri.github.io/acR/reference/ac_count.md),
[`ac_top_terms()`](https://andersonheri.github.io/acR/reference/ac_top_terms.md)

## Examples

``` r
df <- data.frame(
  id    = c("d1", "d2", "d3"),
  texto = c("A A B", "B C", "A C"),
  stringsAsFactors = FALSE
)

corp <- ac_corpus(df, text = texto, docid = id)
freq <- ac_count(corp)

if (requireNamespace("wordcloud", quietly = TRUE)) {
  ac_wordcloud(freq, max_words = 20)
}

```
