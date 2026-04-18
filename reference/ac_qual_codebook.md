# Criar um codebook para análise de conteúdo qualitativa

`ac_qual_codebook()` cria um livro de códigos estruturado para
classificação de textos via LLM. Suporta três modos:

- **`"manual"`** (padrão): o pesquisador fornece definições, exemplos e
  referências diretamente.

- **`"induced"`**: a LLM induz categorias automaticamente a partir de
  uma amostra do corpus, sugerindo nomes, definições e exemplos. Útil
  quando o pesquisador ainda não tem categorias pré-definidas.

- **`"literature"`**: a LLM busca definições na literatura acadêmica
  (periódicos nacionais e internacionais de alto impacto), gerando um
  banco estruturado com trecho original, tradução, autor, ano, revista e
  link. O pesquisador revisa e aprova interativamente antes de usar.

## Usage

``` r
ac_qual_codebook(
  name,
  instructions,
  categories = list(),
  corpus = NULL,
  n_categories = 5L,
  mode = c("manual", "induced", "literature"),
  multilabel = FALSE,
  lang = "pt",
  chat = NULL,
  model = "anthropic/claude-sonnet-4-5",
  journals = "default",
  n_refs = 5L,
  ...
)
```

## Arguments

- name:

  Nome identificador do codebook (string).

- instructions:

  Instrução geral para a LLM (o que ela deve fazer com o texto). Ex:
  `"Classifique o discurso quanto ao conteúdo iliberal."`.

- categories:

  Lista nomeada de categorias. Cada elemento pode ser:

  - **Modo manual**: lista com `definition`, `examples_pos`,
    `examples_neg`.

  - **Modo literature**: lista com `concept` (string de busca em
    inglês).

  - **Modo induced**: ignorado — as categorias são geradas pela LLM.

- corpus:

  Objeto `ac_corpus`. Obrigatório no modo `"induced"`. A LLM analisa uma
  amostra de até 20 documentos para induzir as categorias.

- n_categories:

  Inteiro. Número de categorias a induzir no modo `"induced"`. Padrão:
  `5L`. Ignorado nos modos `"manual"` e `"literature"`.

- mode:

  `"manual"` (padrão), `"induced"` ou `"literature"`.

- multilabel:

  Lógico. Se `TRUE`, um documento pode pertencer a mais de uma
  categoria. Padrão: `FALSE`.

- lang:

  Idioma do corpus: `"pt"` (padrão) ou `"en"`.

- chat:

  Objeto `Chat` do pacote `ellmer` (ex:
  [`chat_google_gemini()`](https://ellmer.tidyverse.org/reference/chat_google_gemini.html),
  [`chat_openai()`](https://ellmer.tidyverse.org/reference/chat_openai.html),
  [`chat_ollama()`](https://ellmer.tidyverse.org/reference/chat_ollama.html)).
  Quando fornecido, tem prioridade sobre `model`. Permite usar qualquer
  provedor suportado pelo `ellmer`.

- model:

  Modelo LLM a usar nos modos `"induced"` e `"literature"`. Padrão:
  `"anthropic/claude-sonnet-4-5"`.

- journals:

  Periódicos a incluir na busca de literatura. Pode ser:

  - `"default"`: lista padrão de periódicos nacionais e internacionais;

  - `"all"`: sem restrição de periódico;

  - vetor character: `c("default", "RBCS", "Cadernos Gestão Pública")`.

- n_refs:

  Número de referências a buscar por categoria. Padrão: `5`.

- ...:

  Ignorado.

## Value

Objeto de classe `ac_codebook`.

## References

Krippendorff, K. (2018). *Content Analysis: An Introduction to Its
Methodology* (4th ed.). SAGE.

Mayring, P. (2022). *Qualitative Content Analysis: A Step-by-Step
Guide*. SAGE.

## Examples

``` r
# Modo manual
cb <- ac_qual_codebook(
  name         = "tom_discurso",
  instructions = "Classifique o tom geral do discurso.",
  categories   = list(
    positivo = list(
      definition   = "Discurso com tom propositivo e colaborativo.",
      examples_pos = c("Proponho que trabalhemos juntos nesta agenda."),
      examples_neg = c("Este governo e um desastre completo.")
    ),
    negativo = list(
      definition   = "Discurso com tom critico, confrontacional ou pessimista.",
      examples_pos = c("Esta proposta vai arruinar o pais."),
      examples_neg = c("Apresento esta emenda para melhorar o texto.")
    )
  )
)
cb
#> 
#> ── Codebook acR: "tom_discurso" ────────────────────────────────────────────────
#> • Modo: "manual"
#> • Categorias (2): "positivo" and "negativo"
#> • Multilabel: FALSE
#> • Idioma: "pt"
#> • Criado em: 18/04/2026 18:26
#> 
#> Instrução geral:
#> Classifique o tom geral do discurso.
#> 
#> Categorias:
#> • "positivo": Discurso com tom propositivo e colaborativo.
#> • "negativo": Discurso com tom critico, confrontacional ou pessimista.

if (FALSE) { # \dontrun{
# Modo induced — categorias sugeridas automaticamente pela LLM
corpus <- ac_corpus(
  data.frame(id = c("d1","d2","d3"),
             texto = c("Texto A", "Texto B", "Texto C")),
  text = texto, docid = id
)
chat_obj <- ellmer::chat_groq(model = "llama-3.3-70b-versatile", echo = "none")
cb_ind <- ac_qual_codebook(
  name         = "temas_induzidos",
  instructions = "Classifique o tema principal do discurso.",
  categories   = list(),
  corpus       = corpus,
  n_categories = 5L,
  mode         = "induced",
  chat         = chat_obj
)
print(cb_ind)
} # }
```
