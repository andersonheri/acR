# Classificar textos com LLM usando um codebook

`ac_qual_code()` classifica os textos de um `ac_corpus` de acordo com um
`ac_codebook`, usando um modelo de linguagem via `ellmer`. Retorna um
tibble com a classificação, grau de certeza (via self-consistency) e
raciocinio da LLM para cada documento.

E o **motor de classificação** do pipeline qualitativo do `acR`. Assume
que o codebook já foi construido com
[`ac_qual_codebook()`](https://ahenriquecp.com/acR/reference/ac_qual_codebook.md)
e (idealmente) testado numa amostra piloto. A saida e sempre validada
com
[`ac_qual_reliability()`](https://ahenriquecp.com/acR/reference/ac_qual_reliability.md)
contra uma amostra codificada por humano – nenhuma análise categorial
publicável dispensa essa etapa.

Tres parametros determinam qualidade e custo:

- `k_consistency`: número de rodadas de *self-consistency* (Wang et al.,
  2023). O mesmo texto e classificado k vezes com pequena variacao de
  temperatura, e a categoria final e a moda. O `confidence_score` sai
  dessa concordância – 1,0 significa que todas as k rodadas concordaram.
  Padrao `k = 3` custa 3x mais tokens que uma rodada única, e e a
  configuracao mínima para reportar confianca de forma defensavel.

- `reasoning`: pede raciocinio estruturado. Melhora a qualidade em casos
  ambiguos mas praticamente dobra o custo por documento. Use `"short"`
  como padrao e `"detailed"` so quando planeja auditar decisoes
  individuais.

- `live`: tira a classificação do modo "caixa-preta" mostrando cada
  documento em tempo real. Numa rodada de 500 discursos, você percebe
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
  [`ac_qual_codebook()`](https://ahenriquecp.com/acR/reference/ac_qual_codebook.md).

- model:

  Modelo LLM a usar. Aceita string no formato `"provedor/modelo"` (ex:
  `"anthropic/claude-sonnet-4-5"`, `"openai/gpt-4.1"`), objeto `Chat` do
  pacote `ellmer` pre-configurado, ou função fabrica
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

  - `"total"` (padrao): uma coluna `confidence_score` com a proporção de
    rodadas de self-consistency que concordaram com a categoria
    vencedora (moda);

  - `"by_variable"`: uma coluna `<categoria>_confidence` por categoria
    do codebook, com a proporção de rodadas que escolheram *aquela*
    categoria especificamente (não so a vencedora) – util para montar
    uma matriz de confianca por tema/categoria;

  - `"both"`: as colunas por categoria + `confidence_score` (a da
    vencedora);

  - `"none"`: não calcula certeza (mais rápido, menor custo).

- k_consistency:

  Número de rodadas para self-consistency. Padrao: `3`. Ignorado se
  `confidence = "none"`.

- temperature:

  Temperatura das rodadas de consistency. Padrao: `0.3`.

- reasoning:

  Lógico. Se `TRUE` (padrao), inclui coluna `raciocinio` com
  justificativa da classificação.

- reasoning_length:

  Tamanho do raciocinio: `"short"` (1 frase, padrao), `"medium"` (3
  frases), `"detailed"` (paragrafo).

- main_temperature:

  Temperatura da rodada principal (a que gera `categoria`,
  `categoria_label` e `raciocinio` no resultado final). Padrao `0`
  (deterministica). Separado de `temperature` (usado so nas rodadas
  extras de self-consistency) porque os dois cumprem papeis diferentes:
  a rodada principal deve ser reprodutível, as extras devem variar para
  medir concordância.

- reasoning_extras:

  Lógico. Se `TRUE`, pede raciocinio também nas rodadas extras de
  self-consistency (mais caro, não usado no resultado final). Padrao
  `FALSE`.

- live:

  Visualizacao em tempo real da classificação:

  - `"off"` (padrao): sem live view;

  - `"terminal"`: barra de progresso com doc atual, categoria, confianca
    e inicio do raciocinio a cada iteracao;

  - `"progress"`: barra de progresso enxuta (doc atual e status), sem
    ecoar categoria/raciocinio – util para rodadas grandes onde o
    terminal ficaria poluido;

  - `"shiny"`: abre janela Shiny em background com tabela atualizando
    conforme documentos sao classificados (requer `shiny` e `callr`).

- max_retries:

  Número máximo de novas tentativas por rodada quando a chamada ao LLM
  falha (erro de rede, timeout, resposta invalida). Padrao `2`. Espera
  exponencial entre tentativas (até 30s). Quando o erro e classificado
  como `"estouro_contexto"`, não ha nova tentativa (repetir não
  resolve). Se mais da metade dos últimos 5+ documentos falhar, a
  execucao e abortada com sugestao de usar `checkpoint_dir`.

- checkpoint_dir:

  Diretório para salvar o resultado de cada documento assim que
  classificado. Se já existir um checkpoint valido para um `doc_id`
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
  (`"técnica|politica"`).

- `categoria_label`: rotulo humano correspondente, vindo do campo
  `label` de cada categoria (se ausente, repete o slug). Em multilabel,
  unidos por `" | "` (espaco dos dois lados).

- `confidence_score`: grau de certeza da categoria vencedora (0-1).
  Presente quando `confidence` e `"total"` ou `"both"`.

- `confidence_level`: `"alta"` (`>= 0,80`), `"média"` (`>= 0,61`) ou
  `"baixa"` – faixas **convencionadas pelo pacote** para resumir
  `confidence_score`. Não vêm da literatura de confiabilidade: as faixas
  de Landis & Koch (1977) são para kappa, não para proporção de rodadas
  concordantes. A ideia de usar a concordância entre amostras como sinal
  de incerteza vem de Wang et al. (2023) e Xiong et al. (2024), que
  mostram que ela se correlaciona com acerto, mas não propõem cortes
  universais. Com `k_consistency = 3`, os valores possíveis são só 1/3,
  2/3 e 1. Acompanha `confidence_score`.

- `<categoria>_confidence`: uma coluna por categoria do codebook (ex.:
  `positivo_confidence`, `negativo_confidence`), com a proporção de
  rodadas de self-consistency que escolheram aquela categoria. Presentes
  quando `confidence` e `"by_variable"` ou `"both"`.

- `raciocinio`: justificativa da classificação (se `reasoning = TRUE`).

- `status`: resultado da rodada principal: `"ok"`, `"resposta_invalida"`
  (JSON não parseavel), `"estouro_contexto"`, `"timeout"` ou
  `"erro_servidor"`.

- `n_tentativas`: número de tentativas até obter `status = "ok"` (ou até
  esgotar `max_retries`).

- `tokens_entrada`, `tokens_saida`: tokens de entrada/saida da rodada
  principal, via `chat$get_tokens()` (`NA` se o provedor não expoe).

- `segundos`: tempo total da rodada principal, incluindo novas
  tentativas.

- `tokens_por_segundo`: `tokens_saida / segundos`.

O resultado carrega também um atributo `run_info` (ver
[`attributes()`](https://rdrr.io/r/base/attributes.html)) com metadados
da execucao: versoes de `acR` e `ellmer`, modelo, `base_url`, parametros
efetivos aplicados ao provedor, temperaturas pedidas, `k_consistency`,
hash do codebook e timestamps de inicio/fim.

## References

Wang, X. et al. (2023). Self-Consistency Improves Chain of Thought
Reasoning in Language Models. *International Conference on Learning
Representations (ICLR)*.

Xiong, M. et al. (2024). Can LLMs Express Their Uncertainty? An
Empirical Evaluation of Confidence Elicitation in LLMs. *International
Conference on Learning Representations (ICLR)*.

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
    negativo = list(definition = "Tom crítico e confrontacional.")
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

# Groq (inferência rápida, plano gratuito)
chat_groq <- ellmer::chat_groq(model = "openai/gpt-oss-120b", echo = "none")
coded <- ac_qual_code(corpus, cb, chat = chat_groq)

# Ollama (modelos locais, sem envio de dados externos)
chat_local <- ellmer::chat_ollama(model = "llama3.2", echo = "none")
coded <- ac_qual_code(corpus, cb, chat = chat_local)

# confidence = "both": além de confidence_score (categoria vencedora),
# ganha uma coluna <categoria>_confidence por categoria do codebook --
# util para montar uma matriz de confianca por tema entre documentos
# ou comparar modelos na mesma tarefa.
coded_both <- ac_qual_code(corpus, cb, model = "anthropic/claude-sonnet-4-5",
                            confidence = "both")
coded_both[, c("doc_id", "categoria", "confidence_score",
               "positivo_confidence", "negativo_confidence")]
} # }
```
