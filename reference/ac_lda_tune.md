# Ajustar múltiplos modelos LDA para selecionar k

`ac_lda_tune()` ajusta modelos LDA para diferentes valores de k e
calcula a **perplexidade fora da amostra** por validação cruzada, para
auxiliar na seleção do número de tópicos.

Por que fora da amostra: a perplexidade calculada nos mesmos documentos
usados para ajustar o modelo cai quase sempre à medida que k cresce,
porque mais tópicos = mais parâmetros para memorizar o corpus. Blei, Ng
& Jordan (2003) e Wallach et al. (2009) avaliam a perplexidade em
documentos **não vistos** no ajuste; Zhao et al. (2015) usam validação
cruzada em 5 partes, como faz esta função por padrão. A versão de treino
continua disponível na coluna `perplexity_train`, só para comparação.

Perplexidade é um critério de ajuste preditivo, não de qualidade
substantiva: Chang et al. (2009) mostram que modelos com melhor
perplexidade podem produzir tópicos **menos** interpretáveis para
humanos. Use a curva para delimitar uma faixa de k e decida dentro dela
lendo os tópicos.

## Usage

``` r
ac_lda_tune(
  corpus,
  k_range = 5:20,
  seed = 42L,
  method = c("VEM", "Gibbs"),
  folds = 5L,
  ...
)
```

## Arguments

- corpus:

  Objeto `ac_corpus`.

- k_range:

  Vetor de valores de k a testar. Padrão: `5:20`.

- seed:

  Semente (ajuste dos modelos e sorteio das partes da validação
  cruzada). Padrão: `42`.

- method:

  Método de estimação. Padrão: `"VEM"`.

- folds:

  Número de partes da validação cruzada. Padrão: `5` (limitado ao número
  de documentos). Use `1` para pular a validação cruzada e calcular só a
  perplexidade de treino (não recomendado).

- ...:

  Use `control = list(...)` para repassar parâmetros de controle a
  [`topicmodels::LDA()`](https://rdrr.io/pkg/topicmodels/man/lda.html)
  (ex.: `control = list(alpha = 0.1, iter = 2000)` com
  `method = "Gibbs"`). A `seed` é incluída automaticamente se `control`
  não tiver uma.

## Value

Tibble com colunas `k`, `perplexity` (média da perplexidade nas partes
de teste da validação cruzada), `perplexity_sd` (desvio padrão entre as
partes) e `perplexity_train` (perplexidade no corpus inteiro usado no
ajuste).

## References

Blei, D. M.; Ng, A. Y.; Jordan, M. I. (2003). Latent Dirichlet
Allocation. *Journal of Machine Learning Research*, 3, 993-1022.

Chang, J.; Gerrish, S.; Wang, C.; Boyd-Graber, J.; Blei, D. M. (2009).
Reading tea leaves: How humans interpret topic models. *Advances in
Neural Information Processing Systems*, 22, 288-296.

Wallach, H. M.; Murray, I.; Salakhutdinov, R.; Mimno, D. (2009).
Evaluation methods for topic models. *Proceedings of the 26th
International Conference on Machine Learning*, 1105-1112.

Zhao, W. et al. (2015). A heuristic approach to determine an appropriate
number of topics in topic modeling. *BMC Bioinformatics*, 16(Suppl 13),
S8.

## See also

[`ac_lda()`](https://ahenriquecp.com/acR/reference/ac_lda.md),
[`ac_plot_lda_tune()`](https://ahenriquecp.com/acR/reference/ac_plot_lda_tune.md)

## Examples

``` r
# \donttest{
# 1. Corpus sintético (mesmos temas de ac_lda(), palavras diferentes)
df <- data.frame(
  id = paste0("d", 1:10),
  texto = c(
    "democracia participacao politica voto eleicao",
    "mercado economia fiscal privatizacao",
    "saude hospital medico doenca sus",
    "educacao escola professor universidade",
    "democracia cidadania direitos igualdade",
    "economia inflacao juros orcamento",
    "saude medico remedio tratamento",
    "educacao pesquisa ciência tecnologia",
    "participacao social democracia cidadania",
    "mercado trabalho emprego salário"
  )
)
corpus <- ac_corpus(df, text = texto, docid = id)

# 2. Testar k de 2 a 5: perplexidade fora da amostra (validacao cruzada)
tune <- ac_lda_tune(corpus, k_range = 2:5)
#> Testando k = 2 a 5...
#> ℹ Perplexidade fora da amostra: validação cruzada em 5 partes.
tune
#> # A tibble: 4 × 4
#>       k perplexity perplexity_sd perplexity_train
#>   <int>      <dbl>         <dbl>            <dbl>
#> 1     2        NaN            NA             31.0
#> 2     3        NaN            NA             31.0
#> 3     4        NaN            NA             13.8
#> 4     5        NaN            NA             12.6
# }
```
