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
