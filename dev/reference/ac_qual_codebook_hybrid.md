# Enriquecer codebook com literatura via LLM (modo híbrido)

`ac_qual_codebook_hybrid()` re-ancora as definições de um `ac_codebook`
existente em referências bibliográficas buscadas via LLM, combinando
definições manuais com fundamento teórico induzido da literatura.

## Usage

``` r
ac_qual_codebook_hybrid(
  codebook,
  chat = NULL,
  model = "anthropic/claude-sonnet-4-5",
  concepts = NULL,
  journals = "default",
  n_refs = 3L,
  lang = "pt"
)
```

## Arguments

- codebook:

  Objeto `ac_codebook`.

- chat:

  Objeto `Chat` do pacote `ellmer`. Tem prioridade sobre `model`.

- model:

  Modelo LLM. Padrão: `"anthropic/claude-sonnet-4-5"`.

- concepts:

  Lista nomeada com conceitos por categoria (opcional).

- journals:

  Periódicos para busca. Padrão: `"default"`.

- n_refs:

  Número de referências por categoria. Padrão: `3L`.

- lang:

  Idioma: `"pt"` (padrão) ou `"en"`.

## Value

Objeto `ac_codebook` com definições atualizadas e literatura anexada.

## Examples

``` r
if (FALSE) { # \dontrun{
# Requer conexao com a internet + credenciais da LLM (ANTHROPIC_API_KEY).

# 1. Codebook manual como ponto de partida
cb <- ac_qual_codebook(
  name         = "populismo",
  instructions = "Identifique tom populista no discurso.",
  categories   = list(
    populista     = list(definition = "Apela ao povo contra a elite."),
    nao_populista = list(definition = "Discurso tecnico ou institucional.")
  )
)

# 2. Enriquecer com literatura: busca 3 refs por categoria e reescreve
#    as definicoes com base na literatura recuperada
cb_ancorado <- ac_qual_codebook_hybrid(
  codebook = cb,
  n_refs   = 3L,
  lang     = "pt"
)

# 3. Inspecionar as referencias anexadas a cada categoria
cb_ancorado$categories$populista$references
} # }
```
