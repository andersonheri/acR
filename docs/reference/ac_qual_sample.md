# Amostrar documentos para validação humana

`ac_qual_sample()` seleciona uma amostra de documentos classificados
pela LLM para validação por um codificador humano, usando diferentes
estratégias para maximizar a eficiência da validação.

## Usage

``` r
ac_qual_sample(
  coded,
  n = 50L,
  strategy = c("uncertainty", "stratified", "random", "disagreement"),
  seed = 42L,
  ...
)
```

## Arguments

- coded:

  Tibble com classificação LLM, saída de
  [`ac_qual_code()`](https://andersonheri.github.io/acR/reference/ac_qual_code.md).

- n:

  Número de documentos a amostrar. Padrão: `50`.

- strategy:

  Estratégia de amostragem:

  - `"uncertainty"`: prioriza documentos com menor `confidence_score`
    (maior incerteza da LLM);

  - `"stratified"`: garante representação proporcional de todas as
    categorias;

  - `"random"`: amostra aleatória simples;

  - `"disagreement"`: prioriza documentos onde rodadas de
    self-consistency divergiram (requer `confidence_score < 1`).

- seed:

  Semente para reprodutibilidade. Padrão: `42`.

- ...:

  Ignorado.

## Value

Tibble com os documentos selecionados, incluindo uma coluna
`sample_reason` indicando por que cada documento foi selecionado.

## Examples

``` r
# Simular saida de ac_qual_code() com 20 documentos ja classificados
set.seed(1)
coded <- tibble::tibble(
  doc_id           = paste0("doc_", 1:20),
  categoria        = sample(c("favor", "contra"), 20, replace = TRUE),
  confidence_score = runif(20, 0.5, 1.0)
)

# Priorizar casos mais incertos para revisao humana
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
