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
df <- data.frame(
  id = c("a", "b", "c"),
  texto = c(
    "governo excelente otimo resultado positivo",
    "pessima gestao corrupta fracasso terrivel",
    "aprovada proposta reuniao assembleia"
  )
)
corpus <- ac_corpus(df, text = texto, docid = id)
ac_sentiment(corpus)
#> # A tibble: 3 × 6
#>   doc_id n_pos n_neg n_neu score sentiment
#>   <chr>  <int> <int> <int> <int> <chr>    
#> 1 a          2     0     3     2 positivo 
#> 2 b          0     1     4    -1 negativo 
#> 3 c          1     0     3     1 positivo 
```
