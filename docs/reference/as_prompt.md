# Converter codebook em system prompt para LLM

`as_prompt()` é um genérico S3 que converte um objeto em system prompt
formatado para uso com LLMs. O método `as_prompt.ac_codebook()` gera o
prompt a partir de um `ac_codebook`, incluindo instruções, categorias,
exemplos, pesos e, opcionalmente, raciocínio estruturado.

## Usage

``` r
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
