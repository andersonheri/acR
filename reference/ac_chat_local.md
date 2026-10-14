# Conectar a um servidor LLM local compativel com OpenAI

`ac_chat_local()` cria um `Chat` do `ellmer` apontando para um servidor
local compativel com a API da OpenAI – LM Studio, llama.cpp
(`llama-server`), vLLM, Ollama em modo OpenAI, etc. – sem exigir uma
chave de API real.

Classificar com um modelo local (via
[`ac_qual_code()`](https://ahenriquecp.com/acR/reference/ac_qual_code.md))
elimina o custo por token e mantem os documentos fora de qualquer rede
externa, ao preco de gerencia propria do servidor: tamanho de contexto,
tempo de resposta e throughput passam a depender do hardware local. Use
junto com `checkpoint_dir` e `max_retries` em
[`ac_qual_code()`](https://ahenriquecp.com/acR/reference/ac_qual_code.md)
para rodadas longas, e
[`ac_estimate_tokens()`](https://ahenriquecp.com/acR/reference/ac_estimate_tokens.md)
para evitar estouro de contexto.

## Usage

``` r
ac_chat_local(
  model,
  base_url = "http://localhost:1234/v1",
  api = c("chat_completions", "responses"),
  temperature = NULL,
  system_prompt = NULL,
  ...
)
```

## Arguments

- model:

  Nome/identificador do modelo como o servidor local o reconhece (ex.: o
  nome exibido pelo LM Studio, ou o `--model` passado ao
  `llama-server`).

- base_url:

  URL base do servidor OpenAI-compatible. Padrao:
  `"http://localhost:1234/v1"` (porta padrao do LM Studio).

- api:

  Qual API o servidor expoe: `"chat_completions"` (padrao – a maioria
  dos servidores locais: LM Studio, llama.cpp, vLLM) ou `"responses"`
  (servidores que implementam a API Responses da OpenAI).

- temperature:

  Temperatura padrao do chat. `NULL` (padrao): usa o padrao do servidor.

- system_prompt:

  Prompt de sistema inicial. `NULL` (padrao).

- ...:

  Argumentos adicionais passados a
  [`ellmer::chat_openai()`](https://ellmer.tidyverse.org/reference/chat_openai.html)
  ou
  [`ellmer::chat_openai_compatible()`](https://ellmer.tidyverse.org/reference/chat_openai_compatible.html).

## Value

Objeto `Chat` do `ellmer`, pronto para uso em
[`ac_qual_code()`](https://ahenriquecp.com/acR/reference/ac_qual_code.md)
(via `chat = ac_chat_local(...)`).

## Examples

``` r
if (FALSE) { # \dontrun{
# LM Studio rodando localmente, servindo um modelo na porta padrao
chat_local <- ac_chat_local(model = "qwen2.5-14b-instruct")

cb <- ac_qual_codebook(
  name = "tom", instructions = "Classifique o tom.",
  categories = list(
    positivo = list(definition = "Tom propositivo."),
    negativo = list(definition = "Tom critico.")
  )
)
df <- data.frame(id = "d1", texto = "Proponho cooperacao.")
corpus <- ac_corpus(df, text = texto, docid = id)
coded <- ac_qual_code(corpus, cb, chat = chat_local,
                      checkpoint_dir = "checkpoints/")
} # }
```
