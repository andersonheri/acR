# Amostrar documentos para validação humana

`ac_qual_sample()` seleciona uma amostra de documentos classificados
pela LLM para validação por um codificador humano.

**Duas finalidades diferentes, duas estratégias diferentes.**

1.  *Estimar a confiabilidade* que vai para o artigo
    ([`ac_qual_reliability()`](https://ahenriquecp.com/acR/reference/ac_qual_reliability.md)):
    a amostra precisa ser **representativa** do corpus. Krippendorff
    (2018, cap. 12) exige que os dados de confiabilidade sejam
    amostrados da mesma população que os dados analisados; uma amostra
    enviesada para casos difíceis subestima a concordância real, e uma
    enviesada para casos fáceis a superestima. Use `"random"` (padrão)
    ou `"proportional"`.

2.  *Diagnosticar erros* e refinar o codebook: aí vale concentrar o
    esforço humano onde a LLM mais erra, como em amostragem por
    incerteza de *active learning* (Settles, 2012). Use `"uncertainty"`
    ou `"disagreement"`, mas **não** reporte a concordância calculada
    nessa amostra como confiabilidade do corpus.

Sobre o tamanho: Neuendorf (2017) sugere uma subamostra de
confiabilidade de 10% a 20% do corpus, raramente menos de 50 unidades;
Krippendorff (2018, sec. 12.3) oferece um cálculo formal a partir do
alfa mínimo aceitável e da frequência da categoria mais rara.

## Usage

``` r
ac_qual_sample(
  coded,
  n = 50L,
  strategy = c("random", "uncertainty", "stratified", "disagreement", "proportional"),
  strata = NULL,
  min_per_stratum = 1L,
  min_stratum_size = 10L,
  exclude_ids = NULL,
  seed = 42L,
  ...
)
```

## Arguments

- coded:

  Tibble com classificação LLM, saída de
  [`ac_qual_code()`](https://ahenriquecp.com/acR/reference/ac_qual_code.md).

- n:

  Número de documentos a amostrar. Padrão: `50`.

- strategy:

  Estratégia de amostragem:

  - `"random"` (padrão): amostra aleatória simples. Representativa: use
    para estimar a confiabilidade que vai para o artigo;

  - `"uncertainty"`: prioriza documentos com menor `confidence_score`
    (maior incerteza da LLM). Serve para diagnóstico de erros, **não**
    para estimar confiabilidade (amostra enviesada para casos difíceis);

  - `"stratified"`: divide `n` igualmente entre as categorias atribuídas
    pela LLM (sobre-representa categorias raras; não é representativa);

  - `"disagreement"`: prioriza documentos onde rodadas de
    self-consistency divergiram (requer `confidence_score < 1`);

  - `"proportional"`: amostragem estratificada com alocação proporcional
    ao tamanho de cada estrato (método do maior resto), respeitando um
    mínimo por estrato. Diferente de `"stratified"` (que divide `n`
    igualmente entre categorias), preserva a distribuição original de
    `strata` na amostra: a escolha correta quando a amostra alimenta uma
    estimativa populacional (ex.:
    [`ac_qual_reliability()`](https://ahenriquecp.com/acR/reference/ac_qual_reliability.md)
    ponderada), não só uma checagem qualitativa de cada categoria.

- strata:

  Nome da coluna usada para estratificar quando
  `strategy = "proportional"`. Obrigatório nesse caso.

- min_per_stratum:

  Mínimo de documentos por estrato na amostra proporcional, mesmo que a
  alocação exata dê menos. Padrão `1`.

- min_stratum_size:

  Estratos da população com menos documentos que isso são agrupados em
  `"Outras"` antes de alocar: evita alocar uma fração ínfima da amostra
  a uma categoria com 2 documentos na população inteira. Padrão `10`.

- exclude_ids:

  Vetor de `doc_id` a excluir do universo amostrado (ex.: documentos já
  validados em uma rodada anterior). Padrão `NULL`.

- seed:

  Semente para reprodutibilidade. Padrão: `42`.

- ...:

  Ignorado.

## Value

Tibble com os documentos selecionados, incluindo uma coluna
`sample_reason` indicando por que cada documento foi selecionado. Com
`strategy = "proportional"`, ganha também `peso_amostral`
(`n_populacao_estrato / n_amostra_estrato`) para uso em estimativas
ponderadas.

## References

Krippendorff, K. (2018). *Content Analysis: An Introduction to Its
Methodology* (4th ed.). SAGE.

Neuendorf, K. A. (2017). *The Content Analysis Guidebook* (2nd ed.).
SAGE.

Settles, B. (2012). *Active Learning*. Morgan & Claypool.

## Examples

``` r
# Simular saida de ac_qual_code() com 20 documentos já classificados
set.seed(1)
coded <- tibble::tibble(
  doc_id           = paste0("doc_", 1:20),
  categoria        = sample(c("favor", "contra"), 20, replace = TRUE),
  confidence_score = runif(20, 0.5, 1.0)
)

# Amostra representativa (padrao): para estimar a confiabilidade
ac_qual_sample(coded, n = 5)
#> ℹ Amostra de 5 documentos selecionada (estratégia: "random").
#> ℹ Use `ac_qual_export_for_review()` para exportar para Excel.
#> # A tibble: 5 × 4
#>   doc_id categoria confidence_score sample_reason
#>   <chr>  <chr>                <dbl> <chr>        
#> 1 doc_17 contra               0.897 random       
#> 2 doc_5  contra               0.634 random       
#> 3 doc_1  favor                0.967 random       
#> 4 doc_10 contra               0.670 random       
#> 5 doc_4  favor                0.563 random       

# Priorizar casos mais incertos: diagnostico de erros, nao confiabilidade
ac_qual_sample(coded, n = 5, strategy = "uncertainty")
#> ℹ Amostra de 5 documentos selecionada (estratégia: "uncertainty").
#> ℹ Use `ac_qual_export_for_review()` para exportar para Excel.
#> # A tibble: 5 × 4
#>   doc_id categoria confidence_score sample_reason                
#>   <chr>  <chr>                <dbl> <chr>                        
#> 1 doc_7  favor                0.507 uncertainty (confidence=0.51)
#> 2 doc_18 contra               0.554 uncertainty (confidence=0.55)
#> 3 doc_4  favor                0.563 uncertainty (confidence=0.56)
#> 4 doc_14 favor                0.593 uncertainty (confidence=0.59)
#> 5 doc_2  contra               0.606 uncertainty (confidence=0.61)

# Garantir cobertura proporcional das duas categorias
ac_qual_sample(coded, n = 6, strategy = "stratified")
#> ℹ Amostra de 6 documentos selecionada (estratégia: "stratified").
#> ℹ Use `ac_qual_export_for_review()` para exportar para Excel.
#> # A tibble: 6 × 4
#>   doc_id categoria confidence_score sample_reason          
#>   <chr>  <chr>                <dbl> <chr>                  
#> 1 doc_16 contra               0.834 stratified (cat=contra)
#> 2 doc_6  favor                0.693 stratified (cat=favor) 
#> 3 doc_2  contra               0.606 stratified (cat=contra)
#> 4 doc_19 contra               0.862 stratified (cat=contra)
#> 5 doc_14 favor                0.593 stratified (cat=favor) 
#> 6 doc_13 favor                0.747 stratified (cat=favor) 
```
