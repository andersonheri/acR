# Criar nuvem de palavras

`ac_wordcloud()` cria uma nuvem de palavras a partir de uma tabela de
frequências, tipicamente gerada por
[`ac_count()`](https://andersonheri.github.io/acR/reference/ac_count.md).

Por padrão prefere `ggwordcloud` (retorna `ggplot`, layout mais
agradável, tipografia melhor); cai para `wordcloud` clássico se o
primeiro não estiver instalado.

## Usage

``` r
ac_wordcloud(
  x,
  max_words = 100,
  min_n = 1,
  colors = NULL,
  backend = c("auto", "ggwordcloud", "wordcloud"),
  title = NULL,
  ...
)
```

## Arguments

- x:

  Um `data.frame` ou tibble contendo, no mínimo, as colunas `token` e
  `n`.

- max_words:

  Número máximo de palavras a desenhar. Padrão: `100`.

- min_n:

  Frequência mínima para incluir um termo. Padrão: `1`.

- colors:

  Vetor de cores usado no gráfico. Padrão: paleta
  [`ac_palette()`](https://andersonheri.github.io/acR/reference/ac_palette.md).

- backend:

  Motor a usar: `"auto"` (padrão, prefere `ggwordcloud`),
  `"ggwordcloud"` ou `"wordcloud"`.

- title:

  Título opcional (apenas em modo `ggwordcloud`).

- ...:

  Argumentos adicionais encaminhados para o motor escolhido
  ([`ggwordcloud::geom_text_wordcloud`](https://lepennec.github.io/ggwordcloud/reference/geom_text_wordcloud.html)
  ou
  [`wordcloud::wordcloud`](https://rdrr.io/pkg/wordcloud/man/wordcloud.html)).

## Value

Um objeto `ggplot` (backend `ggwordcloud`) ou, invisivelmente, o
`data.frame` filtrado (backend `wordcloud`).

## See also

[`ac_count()`](https://andersonheri.github.io/acR/reference/ac_count.md),
[`ac_top_terms()`](https://andersonheri.github.io/acR/reference/ac_top_terms.md),
[`ac_palette()`](https://andersonheri.github.io/acR/reference/ac_palette.md)

## Examples

``` r
# Corpus pequeno para demonstrar
df <- data.frame(
  id    = paste0("d", 1:8),
  texto = c(
    "reforma tributaria simplifica sistema empresas",
    "reforma reduz distorcoes fiscais brasileiras",
    "sistema tributario complexo prejudica empresas",
    "reforma modernizacao arrecadacao federal",
    "IVA substitui impostos indiretos federais",
    "reforma tributaria arrecadacao IVA aliquotas",
    "simplificacao impostos aliquotas empresas",
    "reforma federal moderniza sistema tributario"
  ),
  stringsAsFactors = FALSE
)
corp <- ac_corpus(df, text = texto, docid = id) |>
  ac_clean(remove_stopwords = "pt")
freq <- ac_count(corp)

# Motor ggplot moderno (recomendado)
if (requireNamespace("ggwordcloud", quietly = TRUE)) {
  ac_wordcloud(freq, max_words = 30, title = "Termos frequentes")
}
#> Warning: Some words could not fit on page. They have been removed.


# Motor classico (fallback)
if (requireNamespace("wordcloud", quietly = TRUE)) {
  ac_wordcloud(freq, max_words = 30, backend = "wordcloud")
}
#> Warning: federal could not be fit on page. It will not be plotted.
#> Warning: federal could not be fit on page. It will not be plotted.
#> Warning: impostos could not be fit on page. It will not be plotted.
#> Warning: impostos could not be fit on page. It will not be plotted.
#> Warning: indiretos could not be fit on page. It will not be plotted.
#> Warning: moderniza could not be fit on page. It will not be plotted.
#> Warning: prejudica could not be fit on page. It will not be plotted.

#> Warning: reforma could not be fit on page. It will not be plotted.
#> Warning: reforma could not be fit on page. It will not be plotted.
#> Warning: reforma could not be fit on page. It will not be plotted.
#> Warning: reforma could not be fit on page. It will not be plotted.
#> Warning: reforma could not be fit on page. It will not be plotted.
#> Warning: simplifica could not be fit on page. It will not be plotted.
#> Warning: simplificacao could not be fit on page. It will not be plotted.
```
