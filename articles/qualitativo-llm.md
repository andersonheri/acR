# Análise de Conteúdo Qualitativa com LLMs

## Visão geral

O módulo qualitativo do **acR** implementa um pipeline completo de
análise de conteúdo assistida por modelos de linguagem (LLMs), seguindo
as diretrizes metodológicas de Krippendorff (2018) e as recomendações
empíricas de Gilardi, Alizadeh e Kubli (2023), que mostraram que LLMs
modernas superam trabalhadores de plataformas em várias tarefas de
anotação de textos políticos — **desde que guiadas por um codebook bem
construído e validadas por revisão humana**.

O pipeline tem sete etapas encadeadas:

    ac_fetch_camara() / ac_fetch_senado()        ← coleta
             ↓
    ac_corpus()                                  ← estruturação
             ↓
    ac_qual_codebook() + funções de gestão       ← codebook
             ↓
    as_prompt()                                  ← system prompt (opcional)
             ↓
    ac_qual_code()                               ← classificação com LLM
             ↓
    ac_qual_sample() + ac_qual_reliability()     ← validação humana
             ↓
    ac_qual_report()                             ← relatório reprodutível

A função
[`ac_qual_code()`](https://andersonheri.github.io/acR/reference/ac_qual_code.md)
aceita o argumento `chat =`, que recebe qualquer objeto `Chat` do pacote
**ellmer** (Wickham et al., 2025). Isso permite usar qualquer provedor —
Groq, OpenAI, Anthropic, Google Gemini, Ollama, Mistral, DeepSeek,
OpenRouter — sem alterar a lógica de análise. Também suporta modelos
locais via Ollama para pesquisas com dados sensíveis.

> **Por que um codebook explícito?** A alternativa naïve seria pedir
> para o modelo “classificar o texto como positivo ou negativo”. Isso
> funciona mal porque cada LLM tem prior próprio sobre o que essas
> palavras significam. Um codebook transforma a classificação em
> **operacionalização reproduzível**: outro pesquisador (humano ou LLM)
> chega aos mesmos rótulos aplicando as mesmas definições e exemplos.

## Quando usar LLM (e quando **não** usar)

Antes de acender API, vale escolher a técnica certa para a pergunta. LLM
não é o melhor caminho para todo problema de análise de conteúdo — é
caro, tem variabilidade estocástica e depende de um provedor externo. A
tabela abaixo resume quando **cada** abordagem do `acR` faz sentido:

| Você quer… | Use |
|----|----|
| Rotular textos com **categorias teóricas pré-definidas** (populismo, framing) | LLM + codebook — esta vignette |
| Medir **valência afetiva** (positivo/negativo/neutro) em português | [`ac_sentiment()`](https://andersonheri.github.io/acR/reference/ac_sentiment.md) (léxico OpLexicon) — mais rápido, determinístico, sem chave de API |
| Descobrir **tópicos emergentes** sem categorias a priori | [`ac_lda()`](https://andersonheri.github.io/acR/reference/ac_lda.md) — modelo probabilístico não supervisionado |
| Detectar **tipologias latentes** para amostragem estratificada | [`ac_cluster_documents()`](https://andersonheri.github.io/acR/reference/ac_cluster_documents.md) — hard clustering; veja a [`vignette("cluster")`](https://andersonheri.github.io/acR/articles/cluster.md) |
| **Comparar** vocabulário entre dois ou mais grupos | [`ac_keyness()`](https://andersonheri.github.io/acR/reference/ac_keyness.md) — teste estatístico, sem LLM |
| **Explorar** vocabulário distintivo dentro de cada documento | [`ac_tf_idf()`](https://andersonheri.github.io/acR/reference/ac_tf_idf.md) |

Regra prática: **se a categoria pode ser detectada por palavras-chave,
use léxico ou keyness — é mais barato, reprodutível e defensável.** LLM
brilha quando a categoria depende de **contexto, ironia, referência
implícita ou raciocínio sobre argumento** — populismo, framing,
posicionamento, tom, estilo retórico.

### Custo real de um estudo com LLM

Para calibrar expectativas, estimativa em dólares para um corpus típico
brasileiro (500 discursos parlamentares, ~800 tokens cada) com
`k_consistency = 3` e `reasoning = TRUE, reasoning_length = "medium"`:

| Modelo                         | Custo estimado | Tempo estimado   |
|--------------------------------|----------------|------------------|
| `groq/llama-3.3-70b-versatile` | US\$ 0,50 – 1  | ~10 min          |
| `openai/gpt-4o-mini`           | US\$ 3 – 5     | ~15 min          |
| `anthropic/claude-sonnet-4-5`  | US\$ 10 – 20   | ~25 min          |
| `anthropic/claude-opus-4-7`    | US\$ 40 – 80   | ~40 min          |
| `ollama/llama3.1:70b` (local)  | US\$ 0 (GPU)   | ~2 h em RTX 4090 |

[`ac_qual_recommend_model()`](https://andersonheri.github.io/acR/reference/ac_qual_recommend_model.md)
(chamado a seguir) sugere o modelo mais custo-efetivo para o tamanho e a
dificuldade da sua tarefa.

------------------------------------------------------------------------

## Instalação e configuração

Antes de começar, garanta que o `ellmer` está instalado e que a chave da
API do seu provedor está no ambiente (`.Renviron` é o local usual —
nunca no código versionado):

``` r

# Instalar acR
remotes::install_github("andersonheri/acR")

# Instalar ellmer
install.packages("ellmer")

# Configurar chave de API (exemplo: Anthropic)
Sys.setenv(ANTHROPIC_API_KEY = "sk-ant-...")
```

Se você não sabe qual provedor escolher, use
[`ac_qual_recommend_model()`](https://andersonheri.github.io/acR/reference/ac_qual_recommend_model.md)
— a função consulta um banco interno com custo, contexto e qualidade
estimada por tipo de tarefa, sem precisar de rede.

------------------------------------------------------------------------

## Etapa 1 — Criar o codebook

O codebook é o instrumento central da análise de conteúdo. Ele define as
**categorias analíticas**, suas **definições operacionais**,
**exemplos** positivos (o que É a categoria) e negativos (o que NÃO é,
para desambiguar categorias vizinhas), e **pesos** relativos que
orientam a LLM em fronteiras difíceis.

> **Dica metodológica:** exemplos negativos são frequentemente
> subestimados. Um exemplo negativo para “populista” — como “Apresento
> esta emenda técnica” — ajuda muito mais que dois positivos adicionais.
> Eles servem de contraste, reduzindo confusões entre categorias
> similares.

``` r

library(acR)

cb <- ac_qual_codebook(
  name         = "tom_discurso",
  instructions = "Classifique o tom geral do discurso parlamentar.",
  categories   = list(
    positivo = list(
      definition   = "Discurso com tom propositivo e colaborativo.",
      examples_pos = c("Proponho que trabalhemos juntos nesta agenda."),
      examples_neg = c("Este governo é um desastre completo."),
      weight       = 1
    ),
    negativo = list(
      definition   = "Discurso com tom crítico ou confrontacional.",
      examples_pos = c("Esta proposta vai arruinar o país."),
      examples_neg = c("Apresento esta emenda para melhorar o texto."),
      weight       = 1.5  # categoria mais difícil: peso maior no prompt
    ),
    neutro = list(
      definition   = "Discurso descritivo, sem posicionamento claro.",
      examples_pos = c("O projeto foi apresentado na sessão de hoje."),
      weight       = 1
    )
  ),
  multilabel = FALSE,   # cada doc recebe UMA categoria
  lang       = "pt"
)
#> ! Categoria "neutro": sem exemplos negativos (examples_neg).
#> ℹ Exemplos negativos reduzem confusão entre categorias similares.

print(cb)
#> 
#> ── Codebook acR: "tom_discurso" ────────────────────────────────────────────────
#> • Modo: "manual"
#> • Categorias (3): "positivo", "negativo", and "neutro"
#> • Multilabel: FALSE
#> • Idioma: "pt"
#> • Criado em: 17/07/2026 22:12
#> 
#> Instrução geral:
#> Classifique o tom geral do discurso parlamentar.
#> 
#> Categorias:
#> • "positivo": Discurso com tom propositivo e colaborativo.
#> Ex+: Proponho que trabalhemos juntos nesta agenda.
#> • "negativo" [peso: 1.5]: Discurso com tom crítico ou confrontacional.
#> Ex+: Esta proposta vai arruinar o país.
#> • "neutro": Discurso descritivo, sem posicionamento claro.
#> Ex+: O projeto foi apresentado na sessão de hoje.
```

### Adicionar e remover categorias

Codebooks quase nunca ficam corretos na primeira tentativa. As funções
[`ac_qual_codebook_add()`](https://andersonheri.github.io/acR/reference/ac_qual_codebook_add.md)
e
[`ac_qual_codebook_remove()`](https://andersonheri.github.io/acR/reference/ac_qual_codebook_remove.md)
permitem **refinamento iterativo** — comum quando você roda o codebook
numa amostra piloto e percebe que faltou uma categoria (“técnico”) ou
que duas se sobrepõem.

Todas as modificações ficam registradas em `codebook$history` para
reprodutibilidade metodológica.

``` r

# Adicionar categoria iterativamente
cb <- ac_qual_codebook_add(cb,
  tecnico = list(
    definition   = "Discurso com linguagem técnica e referências normativas.",
    examples_pos = c("Conforme o art. 37 da CF, a administração pública..."),
    weight       = 1
  )
)

# Remover se necessário
cb <- ac_qual_codebook_remove(cb, "tecnico")
```

------------------------------------------------------------------------

## Etapa 2 — Enriquecer o codebook com literatura

Definir categorias apenas com base no conhecimento do pesquisador
funciona, mas ancorar as definições em literatura publicada aumenta a
**validade de construto**. O `acR` oferece dois modos automatizados:

- **Híbrido** (`ac_qual_codebook_hybrid`): parte do seu codebook manual
  e **enriquece** cada categoria com citações teóricas relevantes, sem
  alterar os exemplos que você já validou.
- **Literature** (`mode = "literature"`): constrói o codebook **do
  zero** a partir da literatura sobre um conceito. Útil quando você tem
  clareza do conceito teórico mas quer que o pacote extraia as dimensões
  operacionais.

### Modo híbrido: definições ancoradas em referências

[`ac_qual_codebook_hybrid()`](https://andersonheri.github.io/acR/reference/ac_qual_codebook_hybrid.md)
re-ancora as definições manuais em referências bibliográficas buscadas
via LLM, preservando os exemplos originais:

``` r

cb_hybrid <- ac_qual_codebook_hybrid(
  codebook = cb,
  model    = "anthropic/claude-sonnet-4-5",
  journals = "default",  # periódicos de CP/CS brasileiros e internacionais
  n_refs   = 3L,
  lang     = "pt"
)

# Ver definição enriquecida da categoria "negativo"
cat(cb_hybrid$categories$negativo$definition)
cat("\nReferências:\n")
print(cb_hybrid$categories$negativo$references)
```

### Modo literature: construção inteiramente baseada em literatura

Aqui você fornece o **conceito** que quer capturar (em inglês, para
melhor recall na base OpenAlex) e o pacote gera categoria, definição e
exemplos.

``` r

cb_lit <- ac_qual_codebook(
  name         = "frames_politicos",
  instructions = "Identifique o frame predominante no discurso.",
  categories   = list(
    conflito    = list(definition = "", concept = "conflict framing politics"),
    consenso    = list(definition = "", concept = "consensus framing politics"),
    moralidade  = list(definition = "", concept = "moral framing political discourse")
  ),
  mode  = "literature",
  model = "anthropic/claude-sonnet-4-5",
  lang  = "pt"
)
```

------------------------------------------------------------------------

## Etapa 3 — Fundir e traduzir codebooks

Análises multidimensionais frequentemente combinam duas ou mais
tipologias (tom + estilo, posicionamento + tema, etc.).
[`ac_qual_codebook_merge()`](https://andersonheri.github.io/acR/reference/ac_qual_codebook_merge.md)
faz essa combinação, com controle de conflitos entre categorias de mesmo
nome.

Traduzir codebooks é útil para: **replicabilidade internacional**
(publicar versão em inglês do instrumento), **corpora bilíngues**, ou
apenas para checar se as definições sobrevivem sem ambiguidade em outra
língua.

### Fundir dois codebooks

``` r

cb_estilo <- ac_qual_codebook(
  name         = "estilo_retórico",
  instructions = "Classifique o estilo retórico dominante.",
  categories   = list(
    pathos  = list(definition = "Apelo emocional predominante."),
    logos   = list(definition = "Apelo racional/argumentativo predominante."),
    ethos   = list(definition = "Apelo à autoridade ou credibilidade do orador.")
  )
)

# Fundir: tom + estilo retórico em um único codebook
cb_completo <- ac_qual_codebook_merge(
  cb1          = cb_hybrid,
  cb2          = cb_estilo,
  name         = "discurso_parlamentar",
  on_conflict  = "rename_second",
  instructions = "Classifique o tom e o estilo retórico do discurso."
)
```

### Traduzir para inglês

``` r

cb_en <- ac_qual_codebook_translate(
  codebook           = cb_completo,
  to                 = "en",
  model              = "anthropic/claude-sonnet-4-5",
  translate_examples = TRUE
)
```

------------------------------------------------------------------------

## Etapa 4 — Inspecionar histórico e gerar system prompt

Todo codebook mantém um `history` das modificações — quem alterou,
quando e o quê. Isso é essencial para publicação: o revisor pode auditar
exatamente como o instrumento foi construído.

O
[`as_prompt()`](https://andersonheri.github.io/acR/reference/as_prompt.md)
converte o objeto `ac_codebook` em uma string de **system prompt**
formatada, pronta para ser injetada num objeto `Chat` do `ellmer`. Você
pode usar essa string diretamente se quiser rodar a classificação com
sua própria lógica de retry/paralelismo.

``` r

# Ver todas as modificações feitas no codebook
ac_qual_codebook_history(cb_completo)
```

``` r

# Gerar system prompt para uso direto com ellmer
prompt <- as_prompt(
  cb_completo,
  reasoning        = TRUE,           # pede raciocinio estruturado
  reasoning_length = "medium"        # "short" | "medium" | "detailed"
)

# O prompt pode ser passado diretamente a um objeto Chat:
# chat$set_system_prompt(prompt)
```

> **Sobre `reasoning`:** pedir raciocínio *aumenta* a qualidade da
> classificação em casos difíceis (o modelo “pensa antes de responder”),
> mas **dobra o custo** por documento (mais tokens gerados). Use
> `"short"` como padrão; `"detailed"` só quando você planeja auditar
> decisões individualmente.

------------------------------------------------------------------------

## Etapa 5 — Classificar o corpus

Com codebook pronto e corpus estruturado,
[`ac_qual_code()`](https://andersonheri.github.io/acR/reference/ac_qual_code.md)
faz a classificação em lotes. Três parâmetros são chave:

- `k_consistency`: número de repetições de *self-consistency* (Wang et
  al., 2022). O mesmo texto é classificado k× (padrão 3) com pequena
  variação de temperatura, e a categoria final é a moda. O
  `confidence_score` sai daí — 1.0 = todas as k rodadas concordaram;
  0.67 = 2 de 3.
- `reasoning`: pede raciocínio estruturado em JSON.
- `live`: **visualização em tempo real** da classificação, tirando o
  processo do “caixa-preta”. Ver blockquote abaixo.

``` r

library(ellmer)

# Coletar e estruturar corpus
discursos <- ac_fetch_camara(
  id_deputado = 204379,
  data_inicio = "2023-01-01",
  data_fim    = "2023-06-30"
)
corpus <- ac_corpus(discursos, text_col = "transcricao", id_col = "id")
```

``` r

# Classificar
chat <- chat_anthropic(model = "claude-sonnet-4-5")

resultado <- ac_qual_code(
  corpus        = corpus,
  codebook      = cb_completo,
  chat          = chat,
  k_consistency = 3,               # self-consistency
  live          = "terminal"       # ver a maquina classificando ao vivo
)

head(resultado)
```

O tibble de saída traz: `doc_id`, `categoria`, `confidence_score` (via
*self-consistency*), `reasoning` (raciocínio do modelo, se pedido) e os
metadados originais do corpus.

### Live view: tirando o LLM do caixa-preta

O argumento `live` de
[`ac_qual_code()`](https://andersonheri.github.io/acR/reference/ac_qual_code.md)
mostra a máquina classificando em tempo real. Três modos:

- `live = "off"` (padrão) — sem visualização.
- `live = "terminal"` — barra de progresso `cli` com doc atual,
  categoria, confiança e início do raciocínio. Zero dependências, roda
  em qualquer setup (batch, CI, servidor sem interface gráfica).
- `live = "shiny"` — janela Shiny em background com tabela atualizando a
  cada 500 ms, destaque para casos de baixa confiança. Requer `shiny` e
  `callr`. Ideal para apresentações e demonstrações.

``` r

resultado <- ac_qual_code(
  corpus, cb_completo, chat = chat,
  live = "terminal"
)
# 42/120 | ============>              35% | ETA 2m10s
#   doc_042 -> populista  (conf 1.00) "Apela ao povo contra elite..."
```

> **Por que isso importa?** Numa rodada de 500 documentos, sem `live`
> você não sabe se o modelo travou, se está devolvendo lixo, ou se está
> indo bem — só descobre no fim, depois de gastar todo o orçamento de
> tokens. Com `live = "terminal"`, você vê nos primeiros 10 docs se o
> raciocínio faz sentido e a distribuição de categorias está plausível.
> Se algo estiver errado, `Ctrl+C` e ajusta.

------------------------------------------------------------------------

## Etapa 6 — Salvar e carregar

Codebook e resultados devem ser **serializados** para replicabilidade.
YAML foi escolhido por ser legível por humanos e versionável em Git.

``` r

# Salvar em YAML para replicabilidade
ac_qual_save_codebook(cb_completo, path = "codebook_discurso.yaml")

# Carregar em outra sessão
cb_recarregado <- ac_qual_load_codebook("codebook_discurso.yaml")
```

------------------------------------------------------------------------

## Etapa 7 — Validação e confiabilidade

**Sem validação humana, não há análise de conteúdo publicável.** LLM é
uma ferramenta poderosa, mas nenhuma referência metodológica aceita hoje
um estudo de análise categorial sem um subconjunto codificado por humano
e métricas de concordância entre codificadores.

O fluxo mínimo:

1.  [`ac_qual_sample()`](https://andersonheri.github.io/acR/reference/ac_qual_sample.md):
    seleciona uma amostra representativa (estratificada, ou priorizando
    casos incertos via `strategy = "uncertainty"`).
2.  [`ac_qual_export_for_review()`](https://andersonheri.github.io/acR/reference/ac_qual_export_for_review.md):
    exporta para `.xlsx` com a coluna `categoria_humano` em branco para
    o revisor preencher.
3.  [`ac_qual_import_human()`](https://andersonheri.github.io/acR/reference/ac_qual_import_human.md):
    reimporta o Excel preenchido.
4.  [`ac_qual_reliability()`](https://andersonheri.github.io/acR/reference/ac_qual_reliability.md):
    calcula percent agreement, *alpha* de Krippendorff, AC1 de Gwet e F1
    macro, com IC 95% via *bootstrap*.

> **Quanto amostrar?** Regra prática (Krippendorff 2018): pelo menos 10%
> do corpus, no mínimo 30 documentos, priorizando os casos com
> `confidence_score < 0.8` (é onde o modelo mais tende a errar).

``` r

# Amostrar 30 documentos priorizando os incertos
amostra <- ac_qual_sample(resultado, n = 30, strategy = "uncertainty")
ac_qual_export_for_review(amostra, path = "revisao.xlsx", corpus = corpus)

# Após preenchimento manual, calcular IRR
revisado <- ac_qual_import_human("revisao_preenchida.xlsx")
irr      <- ac_qual_reliability(llm = resultado, human = revisado)
print(irr)
```

Interpretação (Landis & Koch, 1977 / Gwet, 2014):

| Alpha/Kappa | Interpretação      |
|:-----------:|:-------------------|
|   \< 0.20   | Baixa concordância |
| 0.21 – 0.40 | Razoável           |
| 0.41 – 0.60 | Moderada           |
| 0.61 – 0.80 | Substancial        |
|   \> 0.80   | Quase perfeita     |

Para análises publicáveis, valores acima de **0.67** (Krippendorff) ou
**0.61** (Landis-Koch) são geralmente aceitos, com discussão dos casos
divergentes na seção de método.

------------------------------------------------------------------------

## Diagnosticando problemas comuns

Antes de partir para o relatório final, vale conhecer os quatro modos de
falha mais frequentes de uma rodada com LLM — e o que cada um pede.

### 1. Categorias com concordância baixa entre `k_consistency`

**Sintoma:** `confidence_score` mediano abaixo de 0,80.

**Causa provável:** definições ambíguas ou exemplos negativos ausentes.
A LLM está literalmente hesitando entre categorias em cada repetição.

**Fix:** rodar `ac_qual_codebook(check_overlap = TRUE)` para detectar
definições semanticamente próximas; adicionar exemplos negativos
cruzados (o que uma categoria **não** é, especialmente perto das
vizinhas); revisar manualmente 5–10 documentos com
`confidence_score < 0.67` e verificar se o problema está no texto
(documento genuinamente ambíguo) ou no codebook.

### 2. LLM devolve categoria fora do codebook

**Sintoma:** categoria como “misto”, “outro” ou uma variante da sua
(“populismo_forte”) que **não está** no `codebook$categories`.

**Causa:** o modelo entendeu a tarefa mas achou a categoria correta
insuficiente.

**Fix:** ou você acrescenta a categoria emergente (via
[`ac_qual_codebook_add()`](https://andersonheri.github.io/acR/reference/ac_qual_codebook_add.md)),
ou reforça no prompt que **só as categorias listadas** são válidas. A
segunda geralmente é preferível — categorias emergentes indicam
refinamento metodológico, não desvio da LLM.

### 3. Distribuição colapsada em uma categoria

**Sintoma:** 90%+ dos documentos vão para o mesmo rótulo.

**Causa:** categoria com definição muito abrangente ou peso
implicitamente alto (mais exemplos positivos que as outras).

**Fix:** equilibrar o número de exemplos positivos por categoria; usar o
argumento `weight` para dar peso extra às categorias mais raras;
considerar `multilabel = TRUE` se os documentos genuinamente cobrem mais
de um tema.

### 4. IRR humana × LLM inaceitável

**Sintoma:**
[`ac_qual_reliability()`](https://andersonheri.github.io/acR/reference/ac_qual_reliability.md)
retorna α \< 0,60.

**Causa:** três possibilidades, em ordem de frequência: (i) codebook não
está claro nem para humanos (peça a **outro** humano codificar; se dois
humanos discordam, a LLM não vai salvar), (ii) modelo escolhido é
pequeno demais para a tarefa (troque para um tier acima), (iii) o
próprio conceito teórico é contestado — reformule a pergunta.

> **Regra de ouro:** se a IRR entre dois humanos está abaixo de 0,70, o
> problema é do codebook, não da LLM. Nenhum modelo vai ter mais
> concordância consigo mesmo do que humanos treinados têm entre si.

## Etapa 8 — Replicabilidade e transparência

Análises com LLM têm um risco de comunicação: **o revisor ou leitor não
consegue reproduzir a rodada** sem saber exatamente que modelo, que
codebook, que parâmetros e que amostra foram usados.
[`ac_qual_report()`](https://andersonheri.github.io/acR/reference/ac_qual_report.md)
gera um documento estruturado com **todas essas decisões**, pronto para
anexar como material suplementar de um artigo ou como apêndice
metodológico.

O relatório cobre oito seções:

1.  **Metadados** — data, versão do `acR`, autor(es), método
2.  **Codebook completo** — categorias, definições, exemplos ± e pesos
3.  **Histórico de modificações** — auditoria das alterações no codebook
4.  **Configuração da LLM** — provedor, modelo, temperatura, k,
    reasoning
5.  **Resultados** — distribuição por categoria, quartis de
    `confidence_score`, contagem de casos com confiança \< 0.80
6.  **Confiabilidade inter-codificador** — se
    [`ac_qual_reliability()`](https://andersonheri.github.io/acR/reference/ac_qual_reliability.md)
    foi rodado, tabela completa com IC 95%
7.  **Referências metodológicas** — Krippendorff, Landis-Koch, Gilardi,
    Wang, Gwet
8.  **Sugestão de citação** — formatada em ABNT (PT) ou APA (EN)

Uso mínimo:

``` r

# Apos ter o resultado da classificacao
ac_qual_report(
  coded     = resultado,
  codebook  = cb_completo,
  chat      = chat,                     # opcional: extrai provedor/modelo
  author    = "Anderson Henrique",
  path      = "relatorio_metodo.md"
)
```

Uso completo (com IRR e HTML autocontido):

``` r

irr <- ac_qual_reliability(llm = resultado, human = revisado)

ac_qual_report(
  coded       = resultado,
  codebook    = cb_completo,
  reliability = irr,
  chat        = chat,
  title       = "Codificação do posicionamento parlamentar - 57ª legislatura",
  author      = "Silva, A.; Souza, B.",
  method      = "Discursos coletados via API da Câmara (jan-jun/2023, n=847).",
  format      = "html",
  path        = "metodo_apendice.html",
  lang        = "pt"       # ou "en" para submissao internacional
)
```

O arquivo gerado é **autocontido** (HTML embute todos os estilos; MD é
Markdown puro versionável em Git). Pode ser anexado como material
suplementar do artigo, incluído como apêndice, ou publicado num
repositório de dados junto com o codebook em YAML
([`ac_qual_save_codebook()`](https://andersonheri.github.io/acR/reference/ac_qual_save_codebook.md))
e a saída bruta da LLM.

> **Nota metodológica.** A prática de publicar codebook + rodada da
> LLM + métricas IRR num único documento é a **transparência mínima**
> para análise assistida por LLM em ciências sociais. Sem isso, o leitor
> tem que confiar no autor — algo que a tradição de análise de conteúdo
> (Krippendorff, 2018) sempre rejeitou. O
> [`ac_qual_report()`](https://andersonheri.github.io/acR/reference/ac_qual_report.md)
> empacota essa transparência num único comando.

------------------------------------------------------------------------

## Referências

Gilardi, F., Alizadeh, M., & Kubli, M. (2023). ChatGPT outperforms crowd
workers for text-annotation tasks. *PNAS*, 120(30).
<https://doi.org/10.1073/pnas.2305016120>

Gwet, K. L. (2014). *Handbook of Inter-Rater Reliability* (4th ed.).
Advanced Analytics.

Krippendorff, K. (2018). *Content Analysis: An Introduction to Its
Methodology* (4th ed.). SAGE.

Landis, J. R., & Koch, G. G. (1977). The measurement of observer
agreement for categorical data. *Biometrics*, 33(1), 159-174.

Maerz, S., & Benoit, K. (2025). *quallmer: Qualitative Analysis with
Large Language Models in R*. GitHub.
<https://github.com/quallmer/quallmer>

Sampaio, R. C., & Lycarião, D. (2021). *Análise de conteúdo categorial:
manual de aplicação*. Brasília: ENAP.

Wickham, H., et al. (2025). *ellmer: Chat with Large Language Models*. R
package. <https://ellmer.tidyverse.org>
