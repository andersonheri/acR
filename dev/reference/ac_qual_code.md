# Classificar textos com LLM usando um codebook

`ac_qual_code()` classifica os textos de um `ac_corpus` de acordo com um
`ac_codebook`, usando um modelo de linguagem via `ellmer`. Retorna um
tibble com a classificacao, grau de certeza (via self-consistency) e
raciocinio da LLM para cada documento.

E o **motor de classificacao** do pipeline qualitativo do `acR`. Assume
que o codebook ja foi construido com
[`ac_qual_codebook()`](https://andersonheri.github.io/acR/dev/reference/ac_qual_codebook.md)
e (idealmente) testado numa amostra piloto. A saida e sempre validada
com
[`ac_qual_reliability()`](https://andersonheri.github.io/acR/dev/reference/ac_qual_reliability.md)
contra uma amostra codificada por humano – nenhuma analise categorial
publicavel dispensa essa etapa.

Tres parametros determinam qualidade e custo:

- `k_consistency`: numero de rodadas de *self-consistency* (Wang et al.,
  2023). O mesmo texto e classificado k vezes com pequena variacao de
  temperatura, e a categoria final e a moda. O `confidence_score` sai
  dessa concordancia – 1,0 significa que todas as k rodadas concordaram.
  Padrao `k = 3` custa 3x mais tokens que uma rodada unica, e e a
  configuracao minima para reportar confianca de forma defensavel.

- `reasoning`: pede raciocinio estruturado. Melhora a qualidade em casos
  ambiguos mas praticamente dobra o custo por documento. Use `"short"`
  como padrao e `"detailed"` so quando planeja auditar decisoes
  individuais.

- `live`: tira a classificacao do modo "caixa-preta" mostrando cada
  documento em tempo real. Numa rodada de 500 discursos, voce percebe
  nos primeiros 10 se o codebook esta funcionando – antes de gastar todo
  o orcamento de tokens.

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
  main_temperature = 0,
  reasoning_extras = FALSE,
  live = c("off", "terminal", "progress", "shiny"),
  max_retries = 2L,
  checkpoint_dir = NULL,
  ...
)
```

## Arguments

- corpus:

  Objeto `ac_corpus`.

- codebook:

  Objeto `ac_codebook`, saida de
  [`ac_qual_codebook()`](https://andersonheri.github.io/acR/dev/reference/ac_qual_codebook.md).

- model:

  Modelo LLM a usar. Aceita string no formato `"provedor/modelo"` (ex:
  `"anthropic/claude-sonnet-4-5"`, `"openai/gpt-4.1"`), objeto `Chat` do
  pacote `ellmer` pre-configurado, ou funcao fabrica
  `function(temperature, system_prompt) Chat` para controle total sobre
  a construcao do chat a cada rodada. Quando `chat` e fornecido, `model`
  e ignorado.

- chat:

  Objeto `Chat` do pacote `ellmer` (ex:
  [`chat_google_gemini()`](https://ellmer.tidyverse.org/reference/chat_google_gemini.html),
  [`chat_openai()`](https://ellmer.tidyverse.org/reference/chat_openai.html),
  [`chat_ollama()`](https://ellmer.tidyverse.org/reference/chat_ollama.html)).
  Quando fornecido, tem prioridade sobre `model`. Permite usar qualquer
  provedor suportado pelo `ellmer`.

- confidence:

  Como calcular certeza:

  - `"total"` (padrao): uma coluna `confidence_score` com a proporcao de
    rodadas de self-consistency que concordaram com a categoria
    vencedora (moda);

  - `"by_variable"`: uma coluna `<categoria>_confidence` por categoria
    do codebook, com a proporcao de rodadas que escolheram *aquela*
    categoria especificamente (nao so a vencedora) – util para montar
    uma matriz de confianca por tema/categoria;

  - `"both"`: as colunas por categoria + `confidence_score` (a da
    vencedora);

  - `"none"`: nao calcula certeza (mais rapido, menor custo).

- k_consistency:

  Numero de rodadas para self-consistency. Padrao: `3`. Ignorado se
  `confidence = "none"`.

- temperature:

  Temperatura das rodadas de consistency. Padrao: `0.3`.

- reasoning:

  Logico. Se `TRUE` (padrao), inclui coluna `raciocinio` com
  justificativa da classificacao.

- reasoning_length:

  Tamanho do raciocinio: `"short"` (1 frase, padrao), `"medium"` (3
  frases), `"detailed"` (paragrafo).

- main_temperature:

  Temperatura da rodada principal (a que gera `categoria`,
  `categoria_label` e `raciocinio` no resultado final). Padrao `0`
  (deterministica). Separado de `temperature` (usado so nas rodadas
  extras de self-consistency) porque os dois cumprem papeis diferentes:
  a rodada principal deve ser reprodutivel, as extras devem variar para
  medir concordancia.

- reasoning_extras:

  Logico. Se `TRUE`, pede raciocinio tambem nas rodadas extras de
  self-consistency (mais caro, nao usado no resultado final). Padrao
  `FALSE`.

- live:

  Visualizacao em tempo real da classificacao:

  - `"off"` (padrao): sem live view;

  - `"terminal"`: barra de progresso com doc atual, categoria, confianca
    e inicio do raciocinio a cada iteracao;

  - `"progress"`: barra de progresso enxuta (doc atual e status), sem
    ecoar categoria/raciocinio – util para rodadas grandes onde o
    terminal ficaria poluido;

  - `"shiny"`: abre janela Shiny em background com tabela atualizando
    conforme documentos sao classificados (requer `shiny` e `callr`).

- max_retries:

  Numero maximo de novas tentativas por rodada quando a chamada ao LLM
  falha (erro de rede, timeout, resposta invalida). Padrao `2`. Espera
  exponencial entre tentativas (ate 30s). Quando o erro e classificado
  como `"estouro_contexto"`, nao ha nova tentativa (repetir nao
  resolve). Se mais da metade dos ultimos 5+ documentos falhar, a
  execucao e abortada com sugestao de usar `checkpoint_dir`.

- checkpoint_dir:

  Diretorio para salvar o resultado de cada documento assim que
  classificado. Se ja existir um checkpoint valido para um `doc_id`
  (mesmos `codebook`, `model`, `k_consistency` e `temperature`), o
  documento e pulado e o resultado salvo e reutilizado – permite retomar
  uma rodada interrompida sem reclassificar tudo. `NULL` (padrao): sem
  checkpoint.

- ...:

  Argumentos adicionais passados a
  [`ellmer::chat()`](https://ellmer.tidyverse.org/reference/chat-any.html).
  Permite uso de APIs OpenAI-compatible self-hosted via `base_url`.

## Value

Tibble com colunas:

- `doc_id`: identificador do documento;

- Metadados originais do corpus;

- `categoria`: slug interno da categoria (chave da lista `categories` no
  codebook). Em `multilabel = TRUE`, string pipe-separada sem espaco
  (`"tecnica|politica"`).

- `categoria_label`: rotulo humano correspondente, vindo do campo
  `label` de cada categoria (se ausente, repete o slug). Em multilabel,
  unidos por `" | "` (espaco dos dois lados).

- `confidence_score`: grau de certeza da categoria vencedora (0-1).
  Presente quando `confidence` e `"total"` ou `"both"`.

- `confidence_level`: `"alta"`, `"media"`, `"baixa"` – interpretacao de
  `confidence_score` (Landis & Koch, 1977). Acompanha
  `confidence_score`.

- `<categoria>_confidence`: uma coluna por categoria do codebook (ex.:
  `positivo_confidence`, `negativo_confidence`), com a proporcao de
  rodadas de self-consistency que escolheram aquela categoria. Presentes
  quando `confidence` e `"by_variable"` ou `"both"`.

- `raciocinio`: justificativa da classificacao (se `reasoning = TRUE`).

- `status`: resultado da rodada principal: `"ok"`, `"resposta_invalida"`
  (JSON nao parseavel), `"estouro_contexto"`, `"timeout"` ou
  `"erro_servidor"`.

- `n_tentativas`: numero de tentativas ate obter `status = "ok"` (ou ate
  esgotar `max_retries`).

- `tokens_entrada`, `tokens_saida`: tokens de entrada/saida da rodada
  principal, via `chat$get_tokens()` (`NA` se o provedor nao expoe).

- `segundos`: tempo total da rodada principal, incluindo novas
  tentativas.

- `tokens_por_segundo`: `tokens_saida / segundos`.

O resultado carrega tambem um atributo `run_info` (ver
[`attributes()`](https://rdrr.io/r/base/attributes.html)) com metadados
da execucao: versoes de `acR` e `ellmer`, modelo, `base_url`, parametros
efetivos aplicados ao provedor, temperaturas pedidas, `k_consistency`,
hash do codebook e timestamps de inicio/fim.

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
chat_groq <- ellmer::chat_groq(model = "openai/gpt-oss-120b", echo = "none")
coded <- ac_qual_code(corpus, cb, chat = chat_groq)

# Ollama (modelos locais, sem envio de dados externos)
chat_local <- ellmer::chat_ollama(model = "llama3.2", echo = "none")
coded <- ac_qual_code(corpus, cb, chat = chat_local)

# confidence = "both": alem de confidence_score (categoria vencedora),
# ganha uma coluna <categoria>_confidence por categoria do codebook --
# util para montar uma matriz de confianca por tema entre documentos
# ou comparar modelos na mesma tarefa.
coded_both <- ac_qual_code(corpus, cb, model = "anthropic/claude-sonnet-4-5",
                            confidence = "both")
coded_both[, c("doc_id", "categoria", "confidence_score",
               "positivo_confidence", "negativo_confidence")]
} # }
```
