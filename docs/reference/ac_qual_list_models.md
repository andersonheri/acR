# Listar modelos LLM disponíveis para análise de conteúdo

`ac_qual_list_models()` retorna um tibble com os modelos LLM disponíveis
para uso com
[`ac_qual_code()`](https://andersonheri.github.io/acR/reference/ac_qual_code.md),
incluindo informações de custo, janela de contexto e compatibilidade com
análise de conteúdo qualitativa em Ciências Sociais.

Dois modos de operação:

- **`live = FALSE`** (padrão): usa banco interno curado, funciona
  offline.

- **`live = TRUE`**: consulta a API do provedor via `ellmer::models_*()`
  para obter a lista mais atualizada. Requer chave de API configurada.

## Usage

``` r
ac_qual_list_models(
  provider = "all",
  filter = NULL,
  sort_by = c("cost", "name", "context"),
  live = FALSE,
  ...
)
```

## Arguments

- provider:

  Provedor(es) a listar. Pode ser `"all"` (padrão) ou um ou mais de:
  `"anthropic"`, `"openai"`, `"google"`, `"groq"`, `"deepseek"`,
  `"mistral"`, `"ollama"`.

- filter:

  String para filtrar modelos por nome ou ID (ex: `"claude"`,
  `"gpt-4"`). Padrão: `NULL` (sem filtro).

- sort_by:

  Como ordenar os resultados: `"cost"` (padrão, menor custo primeiro),
  `"name"`, `"context"` (maior janela de contexto primeiro).

- live:

  Lógico. Se `TRUE`, consulta a API do provedor ao vivo via
  `ellmer::models_*()`. Requer chave de API. Padrão: `FALSE`.

- ...:

  Ignorado.

## Value

Tibble com colunas:

- `provider`: nome do provedor;

- `model_id`: identificador do modelo para uso em
  [`ac_qual_code()`](https://andersonheri.github.io/acR/reference/ac_qual_code.md);

- `name`: nome legível;

- `context_k`: janela de contexto em milhares de tokens;

- `cost_input`: custo por 1M tokens de entrada (USD), `NA` se
  gratuito/local;

- `cost_output`: custo por 1M tokens de saída (USD);

- `tier`: categoria (`"frontier"`, `"balanced"`, `"fast"`, `"free"`,
  `"local"`);

- `pt_support`: suporte estimado ao português (`"alto"`, `"medio"`,
  `"baixo"`);

- `acr_string`: string pronta para uso em `model = ...` no `acR`.

## See also

[`ac_qual_recommend_model()`](https://andersonheri.github.io/acR/reference/ac_qual_recommend_model.md),
[`ac_qual_code()`](https://andersonheri.github.io/acR/reference/ac_qual_code.md)

## Examples

``` r
# Listar todos os modelos do banco interno
ac_qual_list_models()
#> # A tibble: 25 × 9
#>    provider model_id     name  context_k cost_input cost_output tier  pt_support
#>    <chr>    <chr>        <chr>     <dbl>      <dbl>       <dbl> <chr> <chr>     
#>  1 groq     groq/llama-… Llam…       128      0.05         0.08 fast  baixo     
#>  2 google   google/gemi… Gemi…      1000      0.075        0.3  fast  medio     
#>  3 openai   openai/gpt-… GPT-…       128      0.1          0.4  fast  medio     
#>  4 google   google/gemi… Gemi…      1000      0.1          0.4  fast  alto      
#>  5 mistral  mistral/mis… Mist…        32      0.1          0.3  fast  medio     
#>  6 groq     groq/gemma2… Gemm…         8      0.2          0.2  fast  medio     
#>  7 deepseek deepseek/de… Deep…        64      0.27         1.1  bala… medio     
#>  8 openai   openai/gpt-… GPT-…       128      0.4          1.6  fast  alto      
#>  9 deepseek deepseek/de… Deep…        64      0.55         2.19 bala… medio     
#> 10 groq     groq/llama-… Llam…       128      0.59         0.79 bala… medio     
#> # ℹ 15 more rows
#> # ℹ 1 more variable: acr_string <chr>

# Só modelos Anthropic
ac_qual_list_models(provider = "anthropic")
#> # A tibble: 5 × 9
#>   provider  model_id     name  context_k cost_input cost_output tier  pt_support
#>   <chr>     <chr>        <chr>     <dbl>      <dbl>       <dbl> <chr> <chr>     
#> 1 anthropic anthropic/c… Clau…       200        0.8           4 fast  alto      
#> 2 anthropic anthropic/c… Clau…       200        0.8           4 fast  alto      
#> 3 anthropic anthropic/c… Clau…       200        3            15 bala… alto      
#> 4 anthropic anthropic/c… Clau…       200        3            15 bala… alto      
#> 5 anthropic anthropic/c… Clau…       200       15            75 fron… alto      
#> # ℹ 1 more variable: acr_string <chr>

# Modelos baratos com suporte a PT
ac_qual_list_models(sort_by = "cost") |>
  dplyr::filter(pt_support == "alto", cost_input < 1)
#> # A tibble: 4 × 9
#>   provider  model_id     name  context_k cost_input cost_output tier  pt_support
#>   <chr>     <chr>        <chr>     <dbl>      <dbl>       <dbl> <chr> <chr>     
#> 1 google    google/gemi… Gemi…      1000        0.1         0.4 fast  alto      
#> 2 openai    openai/gpt-… GPT-…       128        0.4         1.6 fast  alto      
#> 3 anthropic anthropic/c… Clau…       200        0.8         4   fast  alto      
#> 4 anthropic anthropic/c… Clau…       200        0.8         4   fast  alto      
#> # ℹ 1 more variable: acr_string <chr>
```
