# Classificar textos com LLM usando um codebook

`ac_qual_code()` classifica os textos de um `ac_corpus` de acordo com um
`ac_codebook`, usando um modelo de linguagem via `ellmer`. Retorna um
tibble com a classificação, grau de certeza (via self-consistency) e
raciocínio da LLM para cada documento.

É o **motor de classificação** do pipeline qualitativo do `acR`. Assume
que o codebook já foi construído com
[`ac_qual_codebook()`](https://andersonheri.github.io/acR/reference/ac_qual_codebook.md)
e (idealmente) testado numa amostra piloto. A saída é sempre validada
com
[`ac_qual_reliability()`](https://andersonheri.github.io/acR/reference/ac_qual_reliability.md)
contra uma amostra codificada por humano — nenhuma análise categorial
publicável dispensa essa etapa.

Três parâmetros determinam qualidade e custo:

- `k_consistency`: número de rodadas de *self-consistency* (Wang et al.,
  2023). O mesmo texto é classificado k vezes com pequena variação de
  temperatura, e a categoria final é a moda. O `confidence_score` sai
  dessa concordância — 1,0 significa que todas as k rodadas concordaram.
  Padrão `k = 3` custa 3x mais tokens que uma rodada única, e é a
  configuração mínima para reportar confiança de forma defensável.

- `reasoning`: pede raciocínio estruturado. Melhora a qualidade em casos
  ambíguos mas praticamente dobra o custo por documento. Use `"short"`
  como padrão e `"detailed"` só quando planeja auditar decisões
  individuais.

- `live`: tira a classificação do modo "caixa-preta" mostrando cada
  documento em tempo real. Numa rodada de 500 discursos, você percebe
  nos primeiros 10 se o codebook está funcionando — antes de gastar todo
  o orçamento de tokens.

## Usage

``` r
ac_qual_code(
  corpus,
  codebook,
  model = "anthropic/claude-sonnet-4-5",
  chat = NULL,
  confidence = c("total", "by_variable", "both", "none"),
  k_consistency = 3L,
  temperature = 0.3,
  reasoning = TRUE,
  reasoning_length = c("short", "medium", "detailed"),
  live = c("off", "terminal", "shiny"),
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

  Modelo LLM a usar. Aceita string no formato `"provedor/modelo"` (ex:
  `"anthropic/claude-sonnet-4-5"`, `"openai/gpt-4.1"`) ou objeto `Chat`
  do pacote `ellmer` pré-configurado. Quando `chat` é fornecido, `model`
  é ignorado.

- chat:

  Objeto `Chat` do pacote `ellmer` (ex:
  [`chat_google_gemini()`](https://ellmer.tidyverse.org/reference/chat_google_gemini.html),
  [`chat_openai()`](https://ellmer.tidyverse.org/reference/chat_openai.html),
  [`chat_ollama()`](https://ellmer.tidyverse.org/reference/chat_ollama.html)).
  Quando fornecido, tem prioridade sobre `model`. Permite usar qualquer
  provedor suportado pelo `ellmer`.

- confidence:

  Como calcular certeza:

  - `"total"` (padrão): uma coluna `confidence_score` com média de todas
    as variáveis;

  - `"by_variable"`: uma coluna `<variavel>_confidence` por categoria;

  - `"both"`: colunas por variável + coluna `confidence_score` (média);

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

- live:

  Visualização em tempo real da classificação:

  - `"off"` (padrão): sem live view;

  - `"terminal"`: barra de progresso com doc atual, categoria, confiança
    e início do raciocínio a cada iteração;

  - `"shiny"`: abre janela Shiny em background com tabela atualizando
    conforme documentos são classificados (requer `shiny` e `callr`).

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

# Usando string de modelo (comportamento padrao)
coded <- ac_qual_code(corpus, cb, model = "anthropic/claude-sonnet-4-5")

# Usando objeto Chat do ellmer (recomendado para controle fino)
chat_obj <- ellmer::chat_google_gemini(model = "gemini-2.5-flash", echo = "none")
coded <- ac_qual_code(corpus, cb, chat = chat_obj)

# Groq (inferencia rapida, plano gratuito)
chat_groq <- ellmer::chat_groq(model = "llama-3.3-70b-versatile", echo = "none")
coded <- ac_qual_code(corpus, cb, chat = chat_groq)

# Ollama (modelos locais, sem envio de dados externos)
chat_local <- ellmer::chat_ollama(model = "llama3.2", echo = "none")
coded <- ac_qual_code(corpus, cb, chat = chat_local)
} # }
```
