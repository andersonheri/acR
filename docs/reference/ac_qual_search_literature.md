# Buscar referencias bibliograficas sobre um conceito via OpenAlex e LLM

`ac_qual_search_literature()` busca referencias academicas reais na API
do OpenAlex e usa um modelo de linguagem via `ellmer` para sintetizar os
abstracts em portugues. Retorna um tibble com metadados bibliograficos
verificados e definicoes sintetizadas pela LLM.

A arquitetura e: OpenAlex recupera registros reais (autor, ano, DOI,
abstract, revista, numero de citacoes); a LLM sintetiza o abstract em
portugues e extrai o trecho mais relevante. Isso evita alucinacoes
bibliograficas comuns quando a LLM opera sem fonte externa.

## Usage

``` r
ac_qual_search_literature(
  concept,
  chat = NULL,
  model = "anthropic/claude-sonnet-4-5",
  n_refs = 5L,
  journals = "default",
  lang = "pt",
  min_citations = 0L,
  ...
)
```

## Arguments

- concept:

  String. Conceito ou termo teorico a buscar (ex:
  `"democratic backsliding"`, `"state capacity"`).

- chat:

  Objeto `Chat` do pacote `ellmer` (ex:
  [`chat_google_gemini()`](https://ellmer.tidyverse.org/reference/chat_google_gemini.html),
  [`chat_openai()`](https://ellmer.tidyverse.org/reference/chat_openai.html),
  [`chat_ollama()`](https://ellmer.tidyverse.org/reference/chat_ollama.html)).
  Quando fornecido, tem prioridade sobre `model`.

- model:

  String no formato `"provedor/modelo"`. Ignorado quando `chat` e
  fornecido.

- n_refs:

  Inteiro. Numero de referencias a retornar. Padrao: `5`.

- journals:

  Periodicos a considerar. Opcoes:

  - `"default"`: lista curada de periodicos de referencia em CP/CS/AP;

  - `"all"`: sem restricao de periodico;

  - Vetor de strings: lista customizada (ex: `c("default", "RBCS")`).

- lang:

  Idioma das definicoes sintetizadas. Padrao: `"pt"`.

- min_citations:

  Inteiro. Numero minimo de citacoes. Padrao: `0`.

- ...:

  Argumentos adicionais passados a
  [`ellmer::chat()`](https://ellmer.tidyverse.org/reference/chat-any.html).

## Value

Tibble com colunas: `conceito`, `autor`, `ano`, `revista`, `n_citacoes`,
`trecho_original`, `definicao_pt`, `abstract_original`, `link`.

## References

Priem, J. et al. (2022). OpenAlex: A fully-open index of the global
research system. *arXiv*, 2205.01833.

Gilardi, F.; Alizadeh, M.; Kubli, M. (2023). ChatGPT Outperforms Crowd
Workers for Text-Annotation Tasks. *PNAS*, 120(30).

## Examples

``` r
if (FALSE) { # \dontrun{
chat_obj <- ellmer::chat_groq(model = "llama-3.3-70b-versatile", echo = "none")

lit <- ac_qual_search_literature(
  concept       = "democratic backsliding",
  n_refs        = 5,
  min_citations = 50,
  chat          = chat_obj
)
print(lit[, c("autor", "ano", "revista", "n_citacoes", "definicao_pt")])
} # }
```
