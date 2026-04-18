# Buscar literatura acadêmica para um conceito

`ac_qual_search_literature()` usa uma LLM para buscar definições de um
conceito na literatura acadêmica, retornando um tibble estruturado com
trecho original, tradução, autor, ano, revista e link.

## Usage

``` r
ac_qual_search_literature(
  concept,
  model = "anthropic/claude-sonnet-4-5",
  journals = "default",
  n_refs = 5L,
  lang = "pt",
  ...
)
```

## Arguments

- concept:

  String com o conceito a buscar (preferencialmente em inglês).

- model:

  Modelo LLM. Padrão: `"anthropic/claude-sonnet-4-5"`.

- journals:

  Periódicos a incluir. Padrão: `"default"`.

- n_refs:

  Número de referências. Padrão: `5`.

- lang:

  Idioma da tradução. Padrão: `"pt"`.

- ...:

  Ignorado.

- chat:

  Objeto `Chat` do pacote `ellmer` (ex: `chat_google_gemini()`,
  `chat_openai()`, `chat_ollama()`). Quando fornecido, tem prioridade
  sobre `model`. Permite usar qualquer provedor suportado pelo `ellmer`.

## Value

Tibble com colunas: `conceito`, `autor`, `ano`, `trecho_original`,
`definicao_pt`, `revista`, `link`.

## Note

ATENCAO: as referencias sao geradas por LLM com base no conhecimento de
treinamento. Verifique todas as referencias antes de citar. Use
`ac_qual_verify_references()` (disponivel em versao futura) para
checagem automatica.
