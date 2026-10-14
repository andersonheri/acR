# Inspecionar e editar stopwords extras do acR

`ac_clean_stopwords()` retorna (e opcionalmente modifica) o vetor de
stopwords adicionais que o pesquisador pode passar a
[`ac_clean()`](https://andersonheri.github.io/acR/reference/ac_clean.md)
via `extra_stopwords`. Funciona como um ponto de partida editável: o
pesquisador inspeciona o vetor, adiciona ou remove termos conforme o
corpus, e passa o resultado para `extra_stopwords`.

## Usage

``` r
ac_clean_stopwords(
  add = NULL,
  remove = NULL,
  preset = c("empty", "pt", "pt-br-extended", "pt-legislativo")
)
```

## Arguments

- add:

  Vetor `character` com termos a adicionar ao vetor padrão.

- remove:

  Vetor `character` com termos a remover do vetor padrão.

- preset:

  String indicando o ponto de partida: `"empty"` (padrão), `"pt"`,
  `"pt-br-extended"` ou `"pt-legislativo"`.

## Value

Vetor `character` de stopwords pronto para passar a
`ac_clean(..., extra_stopwords = ...)`.

## See also

[`ac_clean()`](https://andersonheri.github.io/acR/reference/ac_clean.md)

## Examples

``` r
# Ver o vetor padrão vazio e adicionar termos
sw <- ac_clean_stopwords(add = c("nobre", "ilustre", "respeitavel"))
print(sw)
#> [1] "nobre"       "ilustre"     "respeitavel"

# Partir do preset legislativo e remover termos que interessam ao corpus
sw <- ac_clean_stopwords(
  preset = "pt-legislativo",
  remove = c("lei", "projeto")   # manter: são relevantes para a análise
)

# Usar na limpeza
# ac_clean(corpus, remove_stopwords = "pt", extra_stopwords = sw)
```
