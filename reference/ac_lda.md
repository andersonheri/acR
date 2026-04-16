# Ajustar modelo LDA (Latent Dirichlet Allocation)

`ac_lda()` ajusta um modelo de tópicos LDA sobre um `ac_corpus`,
retornando um objeto com os resultados do modelo e tibbles tidy de
termos por tópico e prevalência por documento.

## Usage

``` r
ac_lda(corpus, k = 10L, seed = 42L, method = c("VEM", "Gibbs"), ...)
```

## Arguments

- corpus:

  Objeto `ac_corpus`.

- k:

  Número de tópicos. Padrão: `10`.

- seed:

  Semente para reprodutibilidade. Padrão: `42`.

- method:

  Método de estimação: `"VEM"` (padrão) ou `"Gibbs"`.

- ...:

  Argumentos adicionais passados a
  [`topicmodels::LDA()`](https://rdrr.io/pkg/topicmodels/man/lda.html).

## Value

Lista de classe `ac_lda` com:

- `model`: objeto `LDA` do pacote `topicmodels`;

- `terms`: tibble com beta (probabilidade de cada termo por tópico);

- `documents`: tibble com gamma (prevalência de cada tópico por
  documento);

- `k`: número de tópicos;

- `params`: parâmetros usados.

## References

Blei, D. M.; Ng, A. Y.; Jordan, M. I. (2003). Latent Dirichlet
Allocation. *Journal of Machine Learning Research*, 3, 993-1022.

## See also

[`ac_lda_tune()`](https://andersonheri.github.io/acR/reference/ac_lda_tune.md),
[`ac_plot_lda_topics()`](https://andersonheri.github.io/acR/reference/ac_plot_lda_topics.md)

## Examples

``` r
if (FALSE) { # \dontrun{
df <- data.frame(
  id = paste0("d", 1:10),
  texto = c(
    "democracia participacao cidadania direitos politica",
    "mercado economia privatizacao crescimento fiscal",
    "saude hospital medico doenca tratamento",
    "educacao escola professor ensino aprendizagem",
    "democracia eleicao voto politica partido",
    "economia inflacao juros fiscal orcamento",
    "saude sus medico hospital remedio",
    "educacao universidade pesquisa ciencia",
    "participacao social cidadania direitos igualdade",
    "mercado trabalho emprego salario industria"
  )
)
corpus <- ac_corpus(df, text = texto, docid = id)
lda <- ac_lda(corpus, k = 3)
lda
} # }
```
