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

  String no formato `"provedor/modelo"` (ex:
  `"anthropic/claude-sonnet-4-5"`). Ignorado quando `chat` e fornecido.

- n_refs:

  Inteiro. Numero de referencias a retornar. Padrao: `5`.

- journals:

  Periodicos a considerar. Opcoes:

  - `"default"`: lista curada de periodicos de referencia em CP/CS/AP;

  - `"all"`: sem restricao de periodico;

  - Vetor de strings: lista customizada (ex: `c("default", "RBCS")`).

- lang:

  Idioma das definicoes sintetizadas. Padrao: `"pt"` (portugues). Use
  `"en"` para ingles.

- min_citations:

  Inteiro. Numero minimo de citacoes para incluir uma referencia.
  Padrao: `0` (sem filtro). Util para focar em trabalhos consolidados
  (ex: `min_citations = 50`).

- ...:

  Argumentos adicionais passados a
  [`ellmer::chat()`](https://ellmer.tidyverse.org/reference/chat-any.html).

## Value

Tibble com colunas:

- `conceito`: conceito buscado;

- `autor`: autores da referencia (formato "Sobrenome, N.; ...");

- `ano`: ano de publicacao;

- `revista`: nome do periodico;

- `n_citacoes`: numero de citacoes no OpenAlex;

- `trecho_original`: trecho mais relevante do abstract em ingles;

- `definicao_pt`: definicao sintetizada pela LLM em portugues;

- `abstract_original`: abstract completo em ingles;

- `link`: DOI ou URL da referencia.

## References

Priem, J. et al. (2022). OpenAlex: A fully-open index of the global
research system. *arXiv*, 2205.01833.

Gilardi, F.; Alizadeh, M.; Kubli, M. (2023). ChatGPT Outperforms Crowd
Workers for Text-Annotation Tasks. *PNAS*, 120(30).

## Examples

``` r
if (FALSE) { # \dontrun{
# Busca basica com modelo padrao
lit <- ac_qual_search_literature(
  concept = "democratic backsliding",
  n_refs  = 5,
  model   = "anthropic/claude-sonnet-4-5"
)

# Com objeto Chat do ellmer (recomendado)
chat_obj <- ellmer::chat_google_gemini(
  model = "gemini-2.5-flash",
  echo  = "none"
)
lit <- ac_qual_search_literature(
  concept = "state capacity",
  n_refs  = 10,
  chat    = chat_obj
)

# Focar em trabalhos consolidados de periodicos brasileiros
lit <- ac_qual_search_literature(
  concept       = "capacidade estatal",
  n_refs        = 5,
  journals      = c("default", "RBCS", "DADOS"),
  min_citations = 20,
  chat          = chat_obj
)
} # }
```
