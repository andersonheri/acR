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
  (ex: `"partido"`, `"data"`): todos os tokens dos documentos do grupo
  entram juntos no cálculo, e a saída tem uma linha por grupo (sem
  `doc_id`). Padrão: `NULL` (uma linha por documento).

- lexicon:

  Léxico a usar. Atualmente apenas `"oplexicon"` (padrão).

- method:

  Método de agregação por documento (ou grupo):

  - `"sum"` (padrão): soma das polaridades (+1/-1). Cresce com o tamanho
    do texto: não compare documentos de tamanhos muito diferentes por
    esse escore.

  - `"mean"`: soma das polaridades dividida pelo **total de tokens**
    (inclusive os que não estão no léxico), ou seja, saldo de sentimento
    por palavra.

  - `"ratio"`: \\(pos - neg)/(pos + neg)\\, entre -1 e 1; usa só as
    palavras com polaridade e por isso independe do tamanho do texto (é
    a forma "relativa" de Lowe et al., 2011, sem a suavização
    logarítmica).

- ...:

  Ignorado.

## Value

Tibble com colunas:

- `doc_id`: identificador do documento;

- Colunas de metadado (se `by` especificado);

- `n_pos`: número de tokens positivos;

- `n_neg`: número de tokens negativos;

- `n_neu`: número de tokens sem polaridade (neutros no léxico **ou**
  ausentes dele);

- `score`: pontuação de sentimento (método escolhido);

- `sentiment`: classificação (`"positivo"`, `"negativo"`, `"neutro"`).

## Details

**Como o léxico é aplicado.** O texto é limpo (minúsculas, sem
pontuação), tokenizado em palavras e cada palavra recebe a polaridade do
OpLexicon (-1, 0, +1); palavras fora do léxico valem 0. Alguns termos
aparecem no OpLexicon mais de uma vez (uma por classe gramatical); nesse
caso usa-se o sinal da soma das polaridades do termo (polaridades
conflitantes, como +1 e -1, viram 0), para que cada token conte uma
única vez.

**Limites do método de dicionário.** A contagem é palavra a palavra: não
trata negação ("não é bom" soma +1), intensificadores ("muito ruim") nem
ironia, e a polaridade de uma palavra depende do domínio (Taboada et
al., 2011; Grimmer & Stewart, 2013). Por isso valide numa amostra
codificada por humano (ver
[`ac_dictionary_validate()`](https://andersonheri.github.io/acR/reference/ac_dictionary_validate.md))
antes de interpretar os escores.

## References

Souza, M.; Vieira, R. (2012). Sentiment Analysis on Twitter Data for
Portuguese Language. *PROPOR*.

Souza, M.; Vieira, R.; Busetti, D.; Chishman, R.; Alves, I. M. (2011).
Construction of a Portuguese Opinion Lexicon from multiple resources.
*STIL/SBC*.

Grimmer, J.; Stewart, B. M. (2013). Text as Data: The Promise and
Pitfalls of Automatic Content Analysis Methods for Political Texts.
*Political Analysis*, 21(3), 267-297.

Lowe, W.; Benoit, K.; Mikhaylov, S.; Laver, M. (2011). Scaling Policy
Preferences from Coded Political Texts. *Legislative Studies Quarterly*,
36(1), 123-155.

Taboada, M.; Brooke, J.; Tofiloski, M.; Voll, K.; Stede, M. (2011).
Lexicon-Based Methods for Sentiment Analysis. *Computational
Linguistics*, 37(2), 267-307.

## See also

[`ac_plot_sentiment()`](https://andersonheri.github.io/acR/reference/ac_plot_sentiment.md)

## Examples

``` r
# Discursos com valência afetiva variada
df <- data.frame(
  id = paste0("d", 1:6),
  texto = c(
    "A reforma tributária e um passo excelente para o pais",
    "Esta proposta e um desastre, um retrocesso terrivel",
    "O relator apresentou o parecer na sessão ordinária",
    "Comemoramos essa vitória histórica com muita alegria",
    "Rejeitamos com veemência essa medida injusta e ilegal",
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
#> 1 d1         2     1     7     1 positivo 
#> 2 d2         0     1     7    -1 negativo 
#> 3 d3         0     1     7    -1 negativo 
#> 4 d4         0     0     7     0 neutro   
#> 5 d5         0     2     6    -2 negativo 
#> 6 d6         0     0     7     0 neutro   

# Agregado por grupo (aqui, por partido)
ac_sentiment(corpus, by = "partido")
#> # A tibble: 2 × 6
#>   partido n_pos n_neg n_neu score sentiment
#>   <chr>   <int> <int> <int> <int> <chr>    
#> 1 A           2     4    20    -2 negativo 
#> 2 B           0     1    21    -1 negativo 

# Metodo alternativo: razao positivos/negativos
ac_sentiment(corpus, method = "ratio")
#> # A tibble: 6 × 6
#>   doc_id n_pos n_neg n_neu  score sentiment
#>   <chr>  <int> <int> <int>  <dbl> <chr>    
#> 1 d1         2     1     7  0.333 positivo 
#> 2 d2         0     1     7 -1     negativo 
#> 3 d3         0     1     7 -1     negativo 
#> 4 d4         0     0     7  0     neutro   
#> 5 d5         0     2     6 -1     negativo 
#> 6 d6         0     0     7  0     neutro   
```
