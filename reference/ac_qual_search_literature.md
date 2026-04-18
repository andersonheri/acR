# Buscar literatura acadêmica para um conceito

`ac_qual_search_literature()` usa uma LLM para buscar definições de um
conceito na literatura acadêmica, retornando um tibble estruturado com
trecho original, tradução, autor, ano, revista e link.

`ac_qual_search_literature()` usa um modelo de linguagem via `ellmer`
para buscar e sintetizar referencias bibliograficas sobre um conceito
teorico, retornando um tibble com autores, ano, trechos originais,
definicoes em portugues, revista e link.

## Usage

``` r
ac_qual_search_literature(
  concept,
  chat = NULL,
  model = "anthropic/claude-sonnet-4-5",
  n_refs = 5L,
  journals = "default",
  lang = "pt",
  ...
)

ac_qual_search_literature(
  concept,
  chat = NULL,
  model = "anthropic/claude-sonnet-4-5",
  n_refs = 5L,
  journals = "default",
  lang = "pt",
  ...
)
```

## Arguments

- concept:

  String. Conceito ou termo teorico a buscar (ex:
  `"democratic backsliding"`, `"state capacity"`).

- chat:

  Objeto `Chat` do pacote `ellmer` (ex: `chat_google_gemini()`,
  `chat_openai()`, `chat_ollama()`). Quando fornecido, tem prioridade
  sobre `model`. Permite usar qualquer provedor suportado pelo `ellmer`.

- model:

  String no formato `"provedor/modelo"` (ex:
  `"anthropic/claude-sonnet-4-5"`). Ignorado quando `chat` e fornecido.

- n_refs:

  Inteiro. Numero de referencias a retornar. Padrao: `5`.

- journals:

  Periódicos a considerar. Opcoes:

  - `"default"`: lista curada de periodicos de referencia em CP/CS;

  - `"all"`: sem restricao de periodico (NULL interno);

  - Vetor de strings: lista customizada (ex: `c("default", "RBCS")`).

- lang:

  Idioma das definicoes retornadas. Padrao: `"pt"` (portugues). Use
  `"en"` para ingles.

- ...:

  Argumentos adicionais passados a
  [`ellmer::chat()`](https://ellmer.tidyverse.org/reference/chat-any.html).

## Value

Tibble com colunas: `conceito`, `autor`, `ano`, `trecho_original`,
`definicao_pt`, `revista`, `link`.

Tibble com colunas:

- `conceito`: conceito buscado;

- `autor`: autores da referencia;

- `ano`: ano de publicacao;

- `trecho_original`: trecho relevante em ingles;

- `definicao_pt`: definicao sintetizada em portugues;

- `revista`: nome do periodico;

- `link`: DOI ou URL da referencia.

## Note

ATENCAO: as referencias sao geradas por LLM com base no conhecimento de
treinamento. Verifique todas as referencias antes de citar. Use
`ac_qual_verify_references()` (disponivel em versao futura) para
checagem automatica.

## References

Gilardi, F.; Alizadeh, M.; Kubli, M. (2023). ChatGPT Outperforms Crowd
Workers for Text-Annotation Tasks. *PNAS*, 120(30).

## Examples

``` r
if (FALSE) { # \dontrun{
# Usando string de modelo
lit <- ac_qual_search_literature(
  concept = "democratic backsliding",
  n_refs  = 3,
  model   = "anthropic/claude-sonnet-4-5"
)

# Usando objeto Chat do ellmer
chat_obj <- ellmer::chat_google_gemini(model = "gemini-2.5-flash", echo = "none")
lit <- ac_qual_search_literature(
  concept = "state capacity",
  n_refs  = 5,
  chat    = chat_obj
)
} # }
```
