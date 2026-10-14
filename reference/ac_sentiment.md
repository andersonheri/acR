# Análise de sentimento com OpLexicon

`ac_sentiment()` calcula a polaridade de sentimento dos documentos de um
`ac_corpus` usando o OpLexicon (Souza & Vieira, 2012), retornando
pontuações por documento e, opcionalmente, por grupo ou janela temporal.

## Usage

``` r
ac_sentiment(
  corpus,
  by = NULL,
  lexicon = c("oplexicon"),
  method = c("sum", "mean", "ratio"),
  ...
)
```

## Arguments

- corpus:

  Objeto `ac_corpus`.

- by:

  Coluna(s) de agrupamento para agregar o sentimento além do documento
  (ex: `"partido"`, `"data"`). Padrão: `NULL` (por documento).

- lexicon:

  Léxico a usar. Atualmente apenas `"oplexicon"` (padrão).

- method:

  Método de agregação por documento:

  - `"sum"` (padrão): soma das polaridades.

  - `"mean"`: média das polaridades.

  - `"ratio"`: razão entre positivos e negativos.

- ...:

  Ignorado.

## Value

Tibble com colunas:

- `doc_id`: identificador do documento;

- Colunas de metadado (se `by` especificado);

- `n_pos`: número de tokens positivos;

- `n_neg`: número de tokens negativos;

- `n_neu`: número de tokens neutros;

- `score`: pontuação de sentimento (método escolhido);

- `sentiment`: classificação (`"positivo"`, `"negativo"`, `"neutro"`).

## References

Souza, M.; Vieira, R. (2012). Sentiment Analysis on Twitter Data for
Portuguese Language. *PROPOR*.

Souza, M.; Vieira, R.; Busetti, D.; Chishman, R.; Alves, I. M. (2011).
Construction of a Portuguese Opinion Lexicon from multiple resources.
*STIL/SBC*.

## See also

[`ac_plot_sentiment()`](https://andersonheri.github.io/acR/reference/ac_plot_sentiment.md)

## Examples

``` r
# Discursos com valencia afetiva variada
df <- data.frame(
  id = paste0("d", 1:6),
  texto = c(
    "A reforma tributaria e um passo excelente para o pais",
    "Esta proposta e um desastre, um retrocesso terrivel",
    "O relator apresentou o parecer na sessao ordinaria",
    "Comemoramos essa vitoria historica com muita alegria",
    "Rejeitamos com veemencia essa medida injusta e ilegal",
    "A comissao encerra os trabalhos as 18h"
  ),
  partido = rep(c("A", "B"), 3),
  stringsAsFactors = FALSE
)
corpus <- ac_corpus(df, text = texto, docid = id)

# Polaridade agregada por documento (soma de scores OpLexicon)
ac_sentiment(corpus)
#> # A tibble: 6 × 6
#>   doc_id n_pos n_neg n_neu score sentiment
#>   <chr>  <int> <int> <int> <int> <chr>    
#> 1 d1         1     1     8     0 neutro   
#> 2 d2         0     1     7    -1 negativo 
#> 3 d3         0     0     8     0 neutro   
#> 4 d4         0     0     7     0 neutro   
#> 5 d5         0     2     6    -2 negativo 
#> 6 d6         0     0     7     0 neutro   

# Agregado por grupo (aqui, por partido)
ac_sentiment(corpus, by = "partido")
#> # A tibble: 6 × 7
#>   doc_id partido n_pos n_neg n_neu score sentiment
#>   <chr>  <chr>   <int> <int> <int> <int> <chr>    
#> 1 d1     A           1     1     8     0 neutro   
#> 2 d2     B           0     1     7    -1 negativo 
#> 3 d3     A           0     0     8     0 neutro   
#> 4 d4     B           0     0     7     0 neutro   
#> 5 d5     A           0     2     6    -2 negativo 
#> 6 d6     B           0     0     7     0 neutro   

# Metodo alternativo: razao positivos/negativos
ac_sentiment(corpus, method = "ratio")
#> # A tibble: 6 × 6
#>   doc_id n_pos n_neg n_neu score sentiment
#>   <chr>  <int> <int> <int> <dbl> <chr>    
#> 1 d1         1     1     8     0 neutro   
#> 2 d2         0     1     7    -1 negativo 
#> 3 d3         0     0     8     0 neutro   
#> 4 d4         0     0     7     0 neutro   
#> 5 d5         0     2     6    -1 negativo 
#> 6 d6         0     0     7     0 neutro   
```
