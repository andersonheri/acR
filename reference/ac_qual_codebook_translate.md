# Traduzir codebook para outro idioma via LLM

`ac_qual_codebook_translate()` traduz as instruções, definições e
exemplos de um `ac_codebook` para o idioma alvo usando uma LLM,
preservando a estrutura e os metadados do objeto.

## Usage

``` r
ac_qual_codebook_translate(
  codebook,
  to = c("en", "pt"),
  chat = NULL,
  model = "anthropic/claude-sonnet-4-5",
  translate_examples = TRUE
)
```

## Arguments

- codebook:

  Objeto `ac_codebook`.

- to:

  Idioma alvo: `"en"` (padrão) ou `"pt"`.

- chat:

  Objeto `Chat` do pacote `ellmer`. Tem prioridade sobre `model`.

- model:

  Modelo LLM. Padrão: `"anthropic/claude-sonnet-4-5"`.

- translate_examples:

  Se `TRUE` (padrão), traduz também os exemplos.

## Value

Objeto `ac_codebook` traduzido.
