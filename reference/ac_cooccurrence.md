# Calcular co-ocorrências de termos

`ac_cooccurrence()` calcula pares de termos que co-ocorrem dentro de
janelas deslizantes ou dentro do mesmo documento, retornando frequências
e medidas de associação (PMI, Dice).

## Usage

``` r
ac_cooccurrence(
  corpus,
  window = 5L,
  unit = c("window", "document"),
  measure = c("count", "pmi", "dice"),
  min_count = 2L,
  ...
)
```

## Arguments

- corpus:

  Objeto `ac_corpus` ou tibble com colunas `doc_id` e `token` (saída de
  [`ac_tokenize()`](https://ahenriquecp.com/acR/reference/ac_tokenize.md)).

- window:

  Tamanho da janela deslizante (número de tokens de cada lado). Padrão:
  `5`. Ignorado se `unit = "document"`.

- unit:

  Unidade de co-ocorrência: `"window"` (padrão) ou `"document"`.

- measure:

  Medidas de associação a calcular. Um ou mais de: `"count"` (frequência
  conjunta), `"pmi"` (pointwise mutual information), `"dice"`
  (coeficiente Dice). Padrão: as três.

- min_count:

  Frequência mínima de co-ocorrência para incluir o par. Padrão: `2`.

- ...:

  Ignorado.

## Value

Tibble com colunas:

- `word1`, `word2`: par de termos (ordenado alfabeticamente);

- `cooc`: frequência de co-ocorrência. Com `unit = "window"`, é o número
  de vezes em que os dois termos aparecem a até `window` tokens um do
  outro (cada encontro conta **uma** vez); com `unit = "document"`, é o
  número de documentos que contêm os dois;

- `pmi` (se solicitado): pointwise mutual information, em bits;

- `dice` (se solicitado): coeficiente Dice.

## Details

**PMI** (Church & Hanks, 1990) compara a probabilidade conjunta com a
esperada sob independência: \\\log_2 \[P(x,y) / (P(x)P(y))\]\\. Zero
indica que o par aparece junto tanto quanto o acaso preveria; valores
positivos, mais que o acaso. PMI superestima pares raros (Evert, 2005),
por isso use `min_count` para descartá-los.

**Dice** (Smadja, McKeown & Hatzivassiloglou, 1996) é \\2 f(x,y) /
(f(x) + f(y))\\, entre 0 e 1.

As probabilidades usam a mesma unidade da contagem conjunta: com
`unit = "window"`, frequências de token e o total de tokens do corpus
(aproximação usual de Church & Hanks); com `unit = "document"`,
frequência documental (em quantos documentos o termo aparece) e o número
de documentos. Pares de um termo com ele mesmo são ignorados.

## References

Church, K. W.; Hanks, P. (1990). Word association norms, mutual
information, and lexicography. *Computational Linguistics*, 16(1),
22-29.

Evert, S. (2005). *The Statistics of Word Cooccurrences: Word Pairs and
Collocations*. Tese (Doutorado), Universität Stuttgart.

Smadja, F.; McKeown, K. R.; Hatzivassiloglou, V. (1996). Translating
collocations for bilingual lexicons: A statistical approach.
*Computational Linguistics*, 22(1), 1-38.

## See also

[`ac_tokenize()`](https://ahenriquecp.com/acR/reference/ac_tokenize.md),
[`ac_plot_cooccurrence()`](https://ahenriquecp.com/acR/reference/ac_plot_cooccurrence.md)

## Examples

``` r
# Corpus tematico: coocorrência revela associações conceituais
# (que palavras "andam juntas" no discurso).
df <- data.frame(
  id = paste0("d", 1:6),
  texto = c(
    "democracia participacao voto liberdade cidadania popular",
    "cidadania direitos participacao democracia representacao politica",
    "voto direitos liberdade cidadania soberania popular",
    "mercado economia eficiência privatizacao competicao livre",
    "privatizacao mercado livre eficiência produtividade lucro",
    "economia crescimento investimento mercado capital juros"
  ),
  stringsAsFactors = FALSE
)

corpus <- ac_corpus(df, text = texto, docid = id) |>
  ac_clean()
tokens <- ac_tokenize(corpus)

# Janela de 3 tokens, sem filtro de frequência mínima
# (em corpora reais use min_count >= 5 para reduzir ruido)
cooc <- ac_cooccurrence(tokens, window = 3L, min_count = 1L)
head(cooc)
#> # A tibble: 6 × 5
#>   word1      word2         cooc   pmi  dice
#>   <chr>      <chr>        <int> <dbl> <dbl>
#> 1 cidadania  direitos         2  3.58 0.2  
#> 2 cidadania  liberdade        2  3.58 0.182
#> 3 cidadania  participacao     2  3.58 0.190
#> 4 cidadania  popular          2  3.58 0.222
#> 5 cidadania  voto             2  3.58 0.2  
#> 6 democracia participacao     2  4.17 0.235

# Coocorrência com PMI (associação normalizada por acaso)
cooc_pmi <- ac_cooccurrence(tokens, window = 3L, measure = "pmi",
                            min_count = 1L)
head(cooc_pmi)
#> # A tibble: 6 × 4
#>   word1      word2         cooc   pmi
#>   <chr>      <chr>        <int> <dbl>
#> 1 cidadania  direitos         2  3.58
#> 2 cidadania  liberdade        2  3.58
#> 3 cidadania  participacao     2  3.58
#> 4 cidadania  popular          2  3.58
#> 5 cidadania  voto             2  3.58
#> 6 democracia participacao     2  4.17
```
