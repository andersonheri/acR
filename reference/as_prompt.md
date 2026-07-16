# Converter codebook em system prompt para LLM

`as_prompt()` é um genérico S3 que converte um objeto em system prompt
formatado para uso com LLMs. O método `as_prompt.ac_codebook()` gera o
prompt a partir de um `ac_codebook`, incluindo instruções, categorias,
exemplos, pesos e, opcionalmente, raciocínio estruturado.

## Usage

``` r
as_prompt(x, ...)

# Default S3 method
as_prompt(x, ...)

# S3 method for class 'ac_codebook'
as_prompt(
  x,
  reasoning = TRUE,
  reasoning_length = c("short", "medium", "detailed"),
  ...
)
```

## Arguments

- x:

  Objeto a converter (para `as_prompt.ac_codebook`: um `ac_codebook`).

- ...:

  Argumentos adicionais passados ao método.

- reasoning:

  Lógico. Se `TRUE`, inclui campo de raciocínio no JSON de saída.
  Padrão: `TRUE`.

- reasoning_length:

  Extensão do raciocínio: `"short"`, `"medium"` ou `"detailed"`.

## Value

String com o system prompt (invisível).

## Examples

``` r
# Codebook base
cb <- ac_qual_codebook(
  name         = "tom",
  instructions = "Classifique o tom do texto.",
  categories   = list(
    formal   = list(definition = "Linguagem tecnica e impessoal."),
    informal = list(definition = "Linguagem coloquial ou emotiva.")
  )
)
#> ! Categoria "formal": sem exemplos positivos (examples_pos).
#> ℹ Exemplos melhoram a precisão da classificação (Sampaio & Lycarião, 2021).
#> ! Categoria "formal": sem exemplos negativos (examples_neg).
#> ℹ Exemplos negativos reduzem confusão entre categorias similares.
#> ! Categoria "informal": sem exemplos positivos (examples_pos).
#> ℹ Exemplos melhoram a precisão da classificação (Sampaio & Lycarião, 2021).
#> ! Categoria "informal": sem exemplos negativos (examples_neg).
#> ℹ Exemplos negativos reduzem confusão entre categorias similares.

# Gerar o system prompt para uso direto com objetos Chat do ellmer
prompt <- as_prompt(cb, reasoning = TRUE, reasoning_length = "short")
#> 
#> ── System prompt: "tom" ────────────────────────────────────────────────────────
#> (347 caracteres)
#> ────────────────────────────────────────────────────────────────────────────────
#> Você é assistente de análise de conteúdo qualitativa.
#> 
#> Classifique o tom do texto.
#> 
#> Cada texto deve ser classificado em EXATAMENTE UMA categoria.
#> 
#> CATEGORIAS:
#> - formal: Linguagem tecnica e impessoal.
#> 
#> - informal: Linguagem coloquial ou emotiva.
#> 
#> Responda SEMPRE em JSON válido:
#> {
#>   "categoria": "formal|informal"
#>   "raciocinio": "1 frase curta",
#> } 
#> ────────────────────────────────────────────────────────────────────────────────
substr(prompt, 1, 200)  # inspecionar o comeco do prompt
#> [1] "Você é assistente de análise de conteúdo qualitativa.\n\nClassifique o tom do texto.\n\nCada texto deve ser classificado em EXATAMENTE UMA categoria.\n\nCATEGORIAS:\n- formal: Linguagem tecnica e impessoal.\n"
```
