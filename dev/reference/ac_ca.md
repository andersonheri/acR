# Análise de correspondência (CA) entre documentos/grupos e termos

`ac_ca()` reduz uma tabela de contingência documento/grupo x termo a
poucas dimensões, posicionando unidades e termos no mesmo espaço
geométrico de modo que unidades e termos próximos no gráfico tendem a
co-ocorrer mais do que o esperado pelo acaso (Greenacre, 2007). É uma
alternativa simples e determinística à Alocação de Dirichlet Latente
(LDA, já disponível em
[`ac_lda()`](https://ahenriquecp.com/acR/dev/reference/ac_lda.md)) para
visualizar associações entre vocabulário e grupos em duas dimensões —
sem assumir um número de tópicos latentes, e com uma interpretação
geométrica direta (distâncias no biplot ~ dissimilaridade de perfis de
frequência).

É útil, por exemplo, para visualizar como o vocabulário difere entre
categorias de atendimento ao cliente, entre seções de um conjunto de
notícias, ou entre partidos/períodos legislativos — qualquer situação em
que se queira um "mapa" conjunto de grupos e das palavras que os
caracterizam.

Implementação: SVD ([`base::svd()`](https://rdrr.io/r/base/svd.html))
sobre os resíduos padronizados de Pearson da tabela de contingência
normalizada, no espírito do algoritmo clássico de Análise de
Correspondência (Greenacre, 2007). Os sinais de cada dimensão são
normalizados (a unidade com maior coordenada em valor absoluto é sempre
positiva), para que o resultado seja determinístico entre execuções.

## Usage

``` r
ac_ca(
  corpus,
  by = NULL,
  top_n = 50L,
  min_count = 5L,
  n_dim = 2L,
  drop_punct = TRUE
)
```

## Arguments

- corpus:

  Objeto `ac_corpus`.

- by:

  Nome de uma coluna de metadados em `corpus` para definir os grupos
  (linhas da tabela de contingência). Se `NULL` (padrão), cada documento
  é uma linha.

- top_n:

  Número máximo de termos (colunas) a manter, pelos mais frequentes no
  total. Padrão: `50`.

- min_count:

  Frequência total mínima de um termo para ele ser mantido. Padrão: `5`.

- n_dim:

  Número de dimensões a retornar. Padrão: `2`.

- drop_punct:

  Lógico, encaminhado para
  [`ac_count()`](https://ahenriquecp.com/acR/dev/reference/ac_count.md).
  Padrão: `TRUE`.

## Value

Lista de classe `ac_ca` com:

- `row_coords`: tibble com `unit`, `dim1`, `dim2`, ..., `mass`
  (massa/peso relativo da linha).

- `col_coords`: tibble com `term`, `dim1`, `dim2`, ..., `mass`.

- `eigenvalues`: autovalores (inércia) de cada dimensão.

- `variance_explained`: proporção da inércia total explicada por cada
  dimensão.

## References

Greenacre, M. (2007). *Correspondence Analysis in Practice* (2nd ed.).
Chapman and Hall/CRC.

## See also

[`ac_count()`](https://ahenriquecp.com/acR/dev/reference/ac_count.md),
[`ac_lda()`](https://ahenriquecp.com/acR/dev/reference/ac_lda.md),
[`ac_plot_ca()`](https://ahenriquecp.com/acR/dev/reference/ac_plot_ca.md)

## Examples

``` r
df <- data.frame(
  id = paste0("d", 1:6),
  texto = c(
    "entrega atrasada rastreio sumiu",
    "pedido atrasou muito, rastreio nao atualiza",
    "produto com defeito, chegou quebrado",
    "veio quebrado, qualidade pessima",
    "atendimento excelente, resolveram rapido",
    "suporte educado e rapido, resolveu tudo"
  ),
  categoria = c("entrega", "entrega", "produto", "produto",
                 "atendimento", "atendimento"),
  stringsAsFactors = FALSE
)
corpus <- ac_corpus(df, text = texto, docid = id, meta = categoria)

ca <- ac_ca(corpus, by = "categoria", min_count = 1)
ca$variance_explained
#> [1] 0.5 0.5
```
