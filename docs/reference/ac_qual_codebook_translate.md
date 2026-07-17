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

## Examples

``` r
if (FALSE) { # \dontrun{
# Requer credenciais da LLM (ANTHROPIC_API_KEY ou GROQ_API_KEY).

cb_pt <- ac_qual_codebook(
  name         = "polaridade",
  instructions = "Classifique a polaridade do texto.",
  categories   = list(
    favor  = list(definition = "Apoia a proposta.",
                  examples_pos = "Sou totalmente a favor desta reforma."),
    contra = list(definition = "Opoe-se a proposta.",
                  examples_pos = "Esta proposta e um retrocesso.")
  )
)

# Traduzir para ingles preservando estrutura e exemplos
cb_en <- ac_qual_codebook_translate(cb_pt, to = "en")
cb_en$lang  # "en"
cb_en$categories$favor$definition
} # }
```
