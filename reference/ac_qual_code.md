# Classificar textos com LLM usando um codebook

`ac_qual_code()` classifica os textos de um `ac_corpus` de acordo com um
`ac_codebook`, usando um modelo de linguagem via `ellmer`. Retorna um
tibble com a classificação, grau de certeza (via self-consistency) e
raciocínio da LLM para cada documento.

## Usage

``` r
ac_qual_code(
  corpus,
  codebook,
  model = "anthropic/claude-sonnet-4-5",
  confidence = c("total", "by_variable", "both", "none"),
  k_consistency = 3L,
  temperature = 0.3,
  reasoning = TRUE,
  reasoning_length = c("short", "medium", "detailed"),
  ...
)
```

## Arguments

- corpus:

  Objeto `ac_corpus`.

- codebook:

  Objeto `ac_codebook`, saída de
  [`ac_qual_codebook()`](https://andersonheri.github.io/acR/reference/ac_qual_codebook.md).

- model:

  Modelo LLM a usar. Aceita:

  - **String** no formato `"provedor/modelo"` (ex:
    `"anthropic/claude-sonnet-4-5"`, `"openai/gpt-4.1"`). Argumentos
    adicionais como `base_url` e `api_key` podem ser passados via `...`;

  - **Objeto `Chat`** do pacote `ellmer` pre-configurado (ex:
    `ellmer::chat_openai_compatible(base_url = ...)`), para provedores
    institucionais, Ollama, Azure, OAuth, etc.

- confidence:

  Como calcular certeza:

  - `"total"` (padrão): uma coluna `confidence_score` com média de todas
    as variáveis;

  - `"by_variable"`: uma coluna `<variavel>_confidence` por categoria;

  - `"both"`: colunas por variável + coluna `confidence_score` (média).

  - `"none"`: não calcula certeza (mais rápido, menor custo).

- k_consistency:

  Número de rodadas para self-consistency. Padrão: `3`. Ignorado se
  `confidence = "none"`.

- temperature:

  Temperatura das rodadas de consistency. Padrão: `0.3`.

- reasoning:

  Lógico. Se `TRUE` (padrão), inclui coluna `raciocinio` com
  justificativa da classificação.

- reasoning_length:

  Tamanho do raciocínio: `"short"` (1 frase, padrão), `"medium"` (3
  frases), `"detailed"` (parágrafo).

- ...:

  Argumentos adicionais passados a
  [`ellmer::chat()`](https://ellmer.tidyverse.org/reference/chat-any.html).
  Permite uso de APIs OpenAI-compatible self-hosted via `base_url`.

## Value

Tibble com colunas:

- `doc_id`: identificador do documento;

- Metadados originais do corpus;

- Uma coluna por categoria com a classificação;

- `confidence_score`: grau de certeza (0-1);

- `confidence_level`: `"alta"`, `"media"`, `"baixa"`;

- `raciocinio`: justificativa da classificação (se `reasoning = TRUE`).

## Details

### Grau de certeza (self-consistency)

A certeza é calculada rodando o modelo `k_consistency` vezes com
`temperature > 0` e medindo a proporção de concordância entre as
rodadas. Valores próximos de 1.0 indicam alta consistência; valores
próximos de 0.5 indicam incerteza elevada.

Interpretação baseada em Landis & Koch (1977):

- ≥ 0.80: quase perfeita (*almost perfect*)

- 0.61–0.79: substancial (*substantial*)

- 0.41–0.60: moderada (*moderate*)

- \< 0.41: fraca (*fair to slight*)

### Raciocínio

Quando `reasoning = TRUE`, a LLM fornece uma justificativa curta (1-3
frases) para cada classificação, armazenada na coluna `raciocinio`.

## References

Wang, X. et al. (2023). Self-Consistency Improves Chain of Thought
Reasoning in Language Models. *EMNLP*.

Landis, J. R.; Koch, G. G. (1977). The Measurement of Observer Agreement
for Categorical Data. *Biometrics*, 33(1), 159-174.

Gilardi, F.; Alizadeh, M.; Kubli, M. (2023). ChatGPT Outperforms Crowd
Workers for Text-Annotation Tasks. *PNAS*, 120(30).

## Examples

``` r
if (FALSE) { # \dontrun{
cb <- ac_qual_codebook(
  name         = "tom",
  instructions = "Classifique o tom do discurso.",
  categories   = list(
    positivo = list(definition = "Tom propositivo e colaborativo."),
    negativo = list(definition = "Tom critico e confrontacional.")
  )
)

df <- data.frame(
  id    = c("d1", "d2"),
  texto = c("Proponho cooperacao.", "Este governo e um fracasso.")
)
corpus <- ac_corpus(df, text = texto, docid = id)
coded  <- ac_qual_code(corpus, cb, model = "anthropic/claude-sonnet-4-5")
coded
} # }
```
