# Criar um codebook para análise de conteúdo qualitativa

`ac_qual_codebook()` cria um livro de códigos estruturado para
classificação de textos via LLM. Suporta três modos:

- **`"manual"`** (padrão): o pesquisador fornece definições, exemplos e
  referências diretamente.

- **`"induced"`**: a LLM induz categorias automaticamente a partir de
  uma amostra do corpus, sugerindo nomes, definições e exemplos.

- **`"literature"`**: a LLM busca definições na literatura acadêmica,
  gerando um banco estruturado com trecho original, tradução, autor,
  ano, revista e link. O pesquisador revisa e aprova interativamente.

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
  check_overlap = FALSE,
  ...
)
```

## Arguments

- name:

  Nome identificador do codebook (string).

- instructions:

  Instrução geral para a LLM.

- categories:

  Lista nomeada de categorias. Cada elemento pode conter:

  - `definition`: definição operacional da categoria (obrigatório).

  - `examples_pos`: vetor de exemplos positivos (recomendado).

  - `examples_neg`: vetor de exemplos negativos (recomendado).

  - `references`: vetor de referências bibliográficas (opcional).

  - `weight`: número entre 0 e 1 indicando a importância relativa da
    categoria para a LLM (padrão: `1`). Categorias raras ou difíceis
    podem receber peso maior para instrução extra.

- corpus:

  Objeto `ac_corpus`. Obrigatório no modo `"induced"`.

- n_categories:

  Inteiro. Número de categorias a induzir. Padrão: `5L`.

- mode:

  `"manual"` (padrão), `"induced"` ou `"literature"`.

- multilabel:

  Lógico. Se `TRUE`, um documento pode pertencer a mais de uma
  categoria. Padrão: `FALSE`.

- lang:

  Idioma do corpus: `"pt"` (padrão) ou `"en"`.

- chat:

  Objeto `Chat` do pacote `ellmer`. Tem prioridade sobre `model`.

- model:

  Modelo LLM. Padrão: `"anthropic/claude-sonnet-4-5"`.

- journals:

  Periódicos para busca de literatura.

- n_refs:

  Número de referências por categoria. Padrão: `5`.

- check_overlap:

  Se `TRUE`, verifica sobreposição semântica entre definições e avisa o
  pesquisador. Requer `chat` ou `model`. Padrão: `FALSE`.

- ...:

  Ignorado.

## Value

Objeto de classe `ac_codebook`.

## References

Krippendorff, K. (2018). *Content Analysis: An Introduction to Its
Methodology* (4th ed.). SAGE.

Sampaio, R. C., & Lycarião, D. (2021). *Análise de conteúdo categorial:
manual de aplicação*. Brasília: ENAP.

## Examples

``` r
cb <- ac_qual_codebook(
  name         = "tom_discurso",
  instructions = "Classifique o tom geral do discurso.",
  categories   = list(
    positivo = list(
      definition   = "Discurso com tom propositivo e colaborativo.",
      examples_pos = c("Proponho que trabalhemos juntos nesta agenda."),
      examples_neg = c("Este governo e um desastre completo."),
      weight       = 1
    ),
    negativo = list(
      definition   = "Discurso com tom critico ou confrontacional.",
      examples_pos = c("Esta proposta vai arruinar o pais."),
      examples_neg = c("Apresento esta emenda para melhorar o texto."),
      weight       = 1
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
#> • Criado em: 20/04/2026 15:26
#> 
#> Instrução geral:
#> Classifique o tom geral do discurso.
#> 
#> Categorias:
#> • "positivo": Discurso com tom propositivo e colaborativo.
#> Ex+: Proponho que trabalhemos juntos nesta agenda.
#> • "negativo": Discurso com tom critico ou confrontacional.
#> Ex+: Esta proposta vai arruinar o pais.
```
