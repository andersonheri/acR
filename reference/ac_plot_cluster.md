# Visualiza um objeto ac_cluster

Tres formas complementares de olhar para o mesmo cluster:

- `"dendrogram"` (padrao para `method = "hclust"`): arvore de fusoes com
  cortes coloridos por grupo.

- `"scatter"`: projecao 2D via PCA sobre a matriz documento-termo, com
  pontos coloridos por cluster.

- `"heatmap"`: mapa de calor da matriz de dissimilaridade, ordenado pelo
  dendrograma.

## Usage

``` r
ac_plot_cluster(
  x,
  kind = c("auto", "dendrogram", "scatter", "heatmap"),
  title = NULL,
  palette = NULL
)
```

## Arguments

- x:

  Objeto `ac_cluster` (saida de
  [`ac_cluster_documents()`](https://andersonheri.github.io/acR/reference/ac_cluster_documents.md)).

- kind:

  Tipo de grafico. `"auto"` (padrao) escolhe conforme o metodo
  (dendrograma para `hclust`, scatter para `kmeans`/`pam`).

- title:

  Titulo do grafico.

- palette:

  Vetor de cores para os clusters. Padrao:
  [`ac_palette()`](https://andersonheri.github.io/acR/reference/ac_palette.md).

## Value

Objeto `ggplot`.

## See also

[`ac_cluster_documents()`](https://andersonheri.github.io/acR/reference/ac_cluster_documents.md)

## Examples

``` r
df <- data.frame(
  id = paste0("d", 1:8),
  texto = c("democracia participacao voto",
            "cidadania direitos participacao",
            "voto direitos liberdade",
            "democracia voto participacao",
            "mercado economia eficiencia",
            "privatizacao mercado livre",
            "economia crescimento mercado",
            "eficiencia mercado livre")
)
corpus <- ac_corpus(df, text = texto, docid = id)
clust  <- ac_cluster_documents(corpus, k = 2)
#> Warning: Corpus pequeno: 8 documento(s).
#> ℹ Cluster analysis em corpus < 15 tende a ser ruidoso.
#> ℹ Considere revisar as etiquetas com `ac_qual_reliability()`.
ac_plot_cluster(clust)

```
