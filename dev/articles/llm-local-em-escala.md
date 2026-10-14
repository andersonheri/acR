# Classificação com LLM Local em Escala

## Visão geral

Esta vignette cobre o fluxo de
[`ac_qual_code()`](https://andersonheri.github.io/acR/dev/reference/ac_qual_code.md)
quando o modelo roda **localmente** (LM Studio, llama.cpp, vLLM, Ollama
em modo OpenAI) em vez de um provedor em nuvem — o cenário mais comum
quando os documentos não podem sair do ambiente do pesquisador (dados
sensíveis, acordos de confidencialidade institucional) ou quando o
volume de documentos tornaria o custo por token de um provedor pago
proibitivo. A orientação aqui vem de uso em produção classificando atos
normativos administrativos, com documentos de até 1,4 milhão de
caracteres e rodadas de milhares de documentos.

Classificar localmente troca custo monetário e risco de vazamento de
dados por gerência própria de infraestrutura: tamanho de contexto,
throughput e estabilidade do servidor passam a ser problema do
pesquisador, não do provedor. As seções abaixo cobrem exatamente os
pontos onde isso dá errado na prática.

## 1. Conectando a um servidor local

\[ac_chat_local()\] cria um `Chat` do `ellmer` apontando para qualquer
servidor compatível com a API da OpenAI, sem exigir uma chave de API
real:

``` r

library(acR)

# LM Studio, servindo um modelo na porta padrao (1234)
chat_local <- ac_chat_local(model = "qwen2.5-14b-instruct")

# llama.cpp (llama-server), porta customizada
chat_llama <- ac_chat_local(
  model    = "modelo-local",
  base_url = "http://localhost:8080/v1"
)
```

Use `chat = chat_local` em \[ac_qual_code()\] exatamente como usaria
qualquer outro `Chat` do `ellmer`:

``` r

coded <- ac_qual_code(corpus, codebook, chat = chat_local)
```

## 2. Dimensionando o contexto antes de gastar uma chamada

Servidores locais costumam ter janelas de contexto menores que
provedores em nuvem (4k–32k tokens é comum, contra 128k+ de modelos de
ponta). Antes de rodar um corpus inteiro, estime quantos tokens cada
documento vai consumir:

``` r

tamanhos <- ac_estimate_tokens(corpus$text)
summary(tamanhos)

# Quantos documentos provavelmente excedem uma janela de 8k tokens?
sum(tamanhos > 8000)
```

[`ac_estimate_tokens()`](https://andersonheri.github.io/acR/dev/reference/ac_estimate_tokens.md)
é uma heurística (caracteres por token) — não faz nenhuma chamada de
rede. Para uma estimativa calibrada contra o modelo e tokenizador real,
rode
[`ac_calibrate_tokens()`](https://andersonheri.github.io/acR/dev/reference/ac_calibrate_tokens.md)
numa amostra pequena antes da rodada completa:

``` r

chat_factory <- function(temperature, system_prompt) {
  ac_chat_local(model = "qwen2.5-14b-instruct",
               temperature = temperature, system_prompt = system_prompt)
}

razao <- ac_calibrate_tokens(chat_factory, sample(corpus$text, 10))
tamanhos_calibrados <- ac_estimate_tokens(corpus$text, chars_per_token = razao)
```

Documentos que excedem a janela de contexto do servidor não devem ser
enviados como estão — considere dividir manualmente em partes menores
antes de montar o
[`ac_corpus()`](https://andersonheri.github.io/acR/dev/reference/ac_corpus.md),
ou reduzir `reasoning_length` para liberar espaço para a resposta.

## 3. Rodando em lotes com checkpoint

Uma rodada de milhares de documentos contra um servidor local pode levar
horas, e qualquer interrupção (queda de energia, servidor reiniciado,
notebook suspenso) sem checkpoint significa reclassificar tudo. Use
`checkpoint_dir`:

``` r

coded <- ac_qual_code(
  corpus, codebook,
  chat           = chat_local,
  checkpoint_dir = "checkpoints/rodada_2026_10",
  max_retries    = 2L,
  live           = "progress"
)
```

Cada documento é salvo (gravação atômica) assim que classificado. Se a
rodada for interrompida, rodar o mesmo comando de novo pula os
documentos já concluídos e continua de onde parou. `live = "progress"`
mostra uma barra enxuta (documento atual + status) em vez de ecoar
categoria e raciocínio a cada uma das `k_consistency` rodadas —
importante para não poluir o console numa rodada de milhares de
documentos.

Se os parâmetros da rodada mudarem (codebook revisado, modelo diferente,
`k_consistency` diferente), o `checkpoint_dir` é invalidado e recomeça
do zero automaticamente — com aviso — para nunca misturar classificações
de codebooks diferentes sem que o pesquisador perceba.

## 4. Lidando com falhas técnicas

Servidores locais sob carga sustentada falham de formas que provedores
em nuvem bem estabelecidos raramente mostram: timeout por sobrecarga de
memória, resposta truncada, conexão recusada depois de muitas horas
rodando. A coluna `status` do resultado diferencia os tipos de falha:

``` r

table(coded$status)
# ok                 -- classificado normalmente
# resposta_invalida  -- o servidor respondeu, mas nao em JSON valido
# estouro_contexto   -- documento excedeu a janela de contexto
# timeout            -- servidor nao respondeu a tempo
# erro_servidor      -- outro erro de rede/servidor
```

`max_retries` tenta de novo (com espera exponencial) para `timeout` e
`erro_servidor`, mas não para `estouro_contexto` — repetir a mesma
chamada com o mesmo texto não vai resolver um documento que simplesmente
não cabe na janela do modelo. Se mais da metade dos últimos documentos
falhar, a rodada é interrompida automaticamente — sinal de que o
servidor está instável e insistir só desperdiçaria tempo.

## 5. Validação humana por categoria (multilabel)

Quando o codebook é `multilabel = TRUE`, a métrica agregada de
\[ac_qual_reliability()\] mistura decisões binárias independentes num
único número — uma concordância “boa” pode esconder uma categoria
específica indo mal. Use `by_variable = TRUE`:

``` r

rel <- ac_qual_reliability(
  llm    = coded,
  human  = humano_df,
  by_variable    = TRUE,
  exclude_status = c("estouro_contexto", "timeout", "erro_servidor")
)

attr(rel, "by_variable")
```

`exclude_status` remove da comparação documentos cuja rodada principal
falhou — uma categoria vinda de uma resposta inválida ou um timeout não
é um dado confiável sobre concordância, e misturá-la nas métricas por
variável distorceria o diagnóstico.

Para montar a amostra de validação humana de forma representativa da
população (não só de cada categoria igualmente, como
`strategy = "stratified"` faz), use `strategy = "proportional"`:

``` r

amostra <- ac_qual_sample(
  coded, n = 100,
  strategy = "proportional", strata = "especie_normativa"
)
```

A amostra ganha `peso_amostral`, útil se você for agregar a validação
numa estimativa populacional ponderada.

## 6. Auditando a configuração da execução

Toda chamada de \[ac_qual_code()\] anexa um atributo `run_info` ao
resultado, com a configuração efetiva da rodada:

``` r

info <- attr(coded, "run_info")
info$model
info$params_efetivos$temperature   # a temperatura que o PROVEDOR confirmou
info$temperatura_pedida            # a temperatura que voce PEDIU
info$codebook_hash
```

Compare `params_efetivos$temperature` com `temperatura_pedida` antes de
reportar `confidence_score` num artigo: se um `Chat` pré-configurado não
confirmar a temperatura pedida,
[`ac_qual_code()`](https://andersonheri.github.io/acR/dev/reference/ac_qual_code.md)
já emite um aviso explícito no momento da rodada — mas `run_info`
permite auditar isso depois, inclusive em rodadas de terceiros.

## Referências

Wang, X. et al. (2023). Self-Consistency Improves Chain of Thought
Reasoning in Language Models. *EMNLP*.

Gilardi, F.; Alizadeh, M.; Kubli, M. (2023). ChatGPT Outperforms Crowd
Workers for Text-Annotation Tasks. *PNAS*, 120(30).

Gwet, K. L. (2014). *Handbook of Inter-Rater Reliability* (4th ed.).
Advanced Analytics.
