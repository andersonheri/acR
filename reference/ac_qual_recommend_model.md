# Recomendar modelo LLM para análise de conteúdo qualitativa

`ac_qual_recommend_model()` sugere o(s) modelo(s) mais adequado(s) para
uma tarefa específica de análise de conteúdo qualitativa, considerando
custo, desempenho em português e tipo de tarefa.

As recomendações são baseadas em benchmarks de classificação de texto em
Ciências Sociais (Gilardi et al., 2023; Törnberg, 2023; Alizadeh et al.,
2023) e na experiência prática com corpora em português brasileiro.

## Usage

``` r
ac_qual_recommend_model(
  task = c("coding", "literature", "both"),
  budget = c("medium", "low", "high", "free"),
  lang = "pt",
  local = FALSE,
  n = 3L,
  ...
)
```

## Arguments

- task:

  Tipo de tarefa:

  - `"coding"` (padrão): classificação de textos com codebook existente;

  - `"literature"`: geração de definições e busca de referências;

  - `"both"`: ambas as tarefas.

- budget:

  Orçamento disponível:

  - `"free"`: apenas modelos gratuitos ou locais;

  - `"low"`: até USD 1/1M tokens de entrada;

  - `"medium"`: até USD 5/1M tokens (padrão);

  - `"high"`: sem restrição de custo.

- lang:

  Idioma predominante do corpus: `"pt"` (padrão) ou `"en"`.

- local:

  Lógico. Se `TRUE`, prioriza modelos locais (Ollama). Padrão: `FALSE`.

- n:

  Número de recomendações a retornar. Padrão: `3`.

- ...:

  Ignorado.

## Value

Tibble com as colunas de
[`ac_qual_list_models()`](https://andersonheri.github.io/acR/reference/ac_qual_list_models.md)
mais:

- `rank`: posição na recomendação;

- `score`: pontuação composta (0-100);

- `justificativa`: texto explicando por que o modelo foi recomendado.

## References

Gilardi, F.; Alizadeh, M.; Kubli, M. (2023). ChatGPT Outperforms Crowd
Workers for Text-Annotation Tasks. *PNAS*, 120(30).

Tornberg, P. (2023). ChatGPT-4 Outperforms Experts and Crowd Workers in
Annotating Political Twitter Messages with Zero-Shot Learning. *PLOS
ONE*, 18(4).

Alizadeh, M. et al. (2023). Open-Source LLMs for Text Annotation: A
Practical Guide for Model Setting and Fine-Tuning. *arXiv*, 2307.02179.

## See also

[`ac_qual_list_models()`](https://andersonheri.github.io/acR/reference/ac_qual_list_models.md),
[`ac_qual_code()`](https://andersonheri.github.io/acR/reference/ac_qual_code.md)

## Examples

``` r
# Recomendação padrão para classificacao em PT com orcamento medio
ac_qual_recommend_model()
#> 
#> ── Recomendacoes de modelo acR ─────────────────────────────────────────────────
#> ℹ Tarefa: "coding" | Budget: "medium" | Idioma: "pt"
#> ℹ Baseado em Gilardi et al. (2023, PNAS) e Tornberg (2023, PLOS ONE).
#> # A tibble: 3 × 12
#>    rank provider model_id           name  tier  context_k cost_input cost_output
#>   <int> <chr>    <chr>              <chr> <chr>     <dbl>      <dbl>       <dbl>
#> 1     1 google   google/gemini-2.0… Gemi… fast       1000       0.1          0.4
#> 2     2 google   google/gemini-2.5… Gemi… fron…      1000       1.25        10  
#> 3     3 openai   openai/o4-mini     o4-m… bala…       200       1.1          4.4
#> # ℹ 4 more variables: pt_support <chr>, score <dbl>, justificativa <chr>,
#> #   acr_string <chr>

# Opcao gratuita para explorar
ac_qual_recommend_model(budget = "free")
#> 
#> ── Recomendacoes de modelo acR ─────────────────────────────────────────────────
#> ℹ Tarefa: "coding" | Budget: "free" | Idioma: "pt"
#> ℹ Baseado em Gilardi et al. (2023, PNAS) e Tornberg (2023, PLOS ONE).
#> # A tibble: 3 × 12
#>    rank provider model_id           name  tier  context_k cost_input cost_output
#>   <int> <chr>    <chr>              <chr> <chr>     <dbl>      <dbl>       <dbl>
#> 1     1 ollama   ollama/qwen2.5:72b Qwen… local       128         NA          NA
#> 2     2 ollama   ollama/llama3.3:7… Llam… local       128         NA          NA
#> 3     3 ollama   ollama/gemma3:27b  Gemm… local       128         NA          NA
#> # ℹ 4 more variables: pt_support <chr>, score <dbl>, justificativa <chr>,
#> #   acr_string <chr>

# Local (Ollama) para dados sigilosos
ac_qual_recommend_model(local = TRUE)
#> 
#> ── Recomendacoes de modelo acR ─────────────────────────────────────────────────
#> ℹ Tarefa: "coding" | Budget: "medium" | Idioma: "pt"
#> ℹ Baseado em Gilardi et al. (2023, PNAS) e Tornberg (2023, PLOS ONE).
#> # A tibble: 3 × 12
#>    rank provider model_id           name  tier  context_k cost_input cost_output
#>   <int> <chr>    <chr>              <chr> <chr>     <dbl>      <dbl>       <dbl>
#> 1     1 ollama   ollama/qwen2.5:72b Qwen… local       128         NA          NA
#> 2     2 ollama   ollama/llama3.3:7… Llam… local       128         NA          NA
#> 3     3 ollama   ollama/gemma3:27b  Gemm… local       128         NA          NA
#> # ℹ 4 more variables: pt_support <chr>, score <dbl>, justificativa <chr>,
#> #   acr_string <chr>
```
