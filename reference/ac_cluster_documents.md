# Agrupamento nao supervisionado de documentos

`ac_cluster_documents()` particiona os documentos de um corpus em grupos
"duros" (hard clustering) com base na similaridade de vocabulario. Serve
para descobrir tipologias latentes, montar amostras estratificadas de
revisao humana ou produzir dendrogramas para relatorios metodologicos.

Nao substitui
[`ac_lda()`](https://andersonheri.github.io/acR/reference/ac_lda.md):
LDA e clustering *soft* (cada documento vira uma mistura de topicos),
enquanto esta funcao devolve **uma etiqueta por documento**.

## Usage

``` r
ac_cluster_documents(
  corpus,
  method = c("hclust", "kmeans", "pam"),
  features = c("tfidf", "count"),
  k = NULL,
  distance = c("cosine", "euclidean"),
  min_docs = 15L
)
```

## Arguments

- corpus:

  Objeto `ac_corpus`.

- method:

  Algoritmo. `"hclust"` (padrao) usa agrupamento hierarquico com ligacao
  Ward.D2; `"kmeans"` usa k-means com `nstart = 25L`; `"pam"` usa
  Partitioning Around Medoids (requer `cluster` em `Suggests`).

- features:

  Como representar cada documento. `"tfidf"` (padrao) pesa por TF-IDF;
  `"count"` usa contagens brutas.

- k:

  Numero de grupos. Se `NULL` (padrao) e
  `method %in% c("hclust","kmeans")`, tenta escolher automaticamente por
  silhouette entre 2 e 8; requer `cluster`. Se `cluster` nao estiver
  instalado, `k = 3` e o fallback.

- distance:

  Metrica de dissimilaridade. `"cosine"` (padrao) e o classico em
  textos; `"euclidean"` funciona melhor com vetores normalizados.

- min_docs:

  Minimo de documentos para nao emitir warning de corpus pequeno.
  Padrao: `15L`.

## Value

Objeto de classe `ac_cluster` com:

- `assignments`:

  `tibble` com `doc_id` e `cluster` (integer).

- `fit`:

  Objeto bruto do algoritmo (`hclust`, `kmeans` ou `pam`).

- `k`:

  Numero final de grupos.

- `method`, `features`, `distance`:

  Parametros usados.

- `silhouette`:

  Silhueta media (NA se `cluster` nao instalado).

- `dtm`:

  Matriz documento-termo usada (para plotagem).

## See also

[`ac_lda()`](https://andersonheri.github.io/acR/reference/ac_lda.md),
[`ac_plot_cluster()`](https://andersonheri.github.io/acR/reference/ac_plot_cluster.md)

## Examples

``` r
# Corpus com dois blocos tematicos
df <- data.frame(
  id    = paste0("d", 1:8),
  texto = c("democracia participacao voto liberdade",
            "cidadania direitos participacao democracia",
            "voto direitos liberdade cidadania",
            "democracia voto participacao popular",
            "mercado economia eficiencia privatizacao",
            "privatizacao mercado livre eficiencia",
            "economia crescimento investimento mercado",
            "eficiencia mercado economia livre"),
  stringsAsFactors = FALSE
)
corpus <- ac_corpus(df, text = texto, docid = id)
clust  <- ac_cluster_documents(corpus, k = 2)
#> Warning: Corpus pequeno: 8 documento(s).
#> ℹ Cluster analysis em corpus < 15 tende a ser ruidoso.
#> ℹ Considere revisar as etiquetas com `ac_qual_reliability()`.
clust$assignments
#> # A tibble: 8 × 2
#>   doc_id cluster
#>   <chr>    <int>
#> 1 d1           1
#> 2 d2           1
#> 3 d3           1
#> 4 d4           1
#> 5 d5           2
#> 6 d6           2
#> 7 d7           2
#> 8 d8           2
```
