# Análise de Conteúdo Qualitativa com LLMs

## Visão geral

O módulo qualitativo do **acR** implementa um pipeline completo de
análise de conteúdo assistida por modelos de linguagem (LLMs), seguindo
as diretrizes metodológicas de Krippendorff (2018) e as recomendações
empíricas de Gilardi, Alizadeh e Kubli (2023), que mostraram que LLMs
modernas superam trabalhadores de plataformas em várias tarefas de
anotação de textos políticos, desde que guiadas por um codebook bem
construído e validadas por revisão humana.

O pipeline tem cinco etapas encadeadas:

    ac_fetch_camara() / ac_fetch_senado()        ← coleta
             ↓
    ac_corpus()                                  ← estruturação
             ↓
    ac_qual_codebook() + funções de gestão       ← codebook
             ↓
    as_prompt()                                  ← system prompt
             ↓
    ac_qual_code()                               ← classificação com LLM

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

print(cb)
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
faz a classificação em lotes. Dois parâmetros são chave:

- `n_rep`: número de repetições de *self-consistency*. O mesmo texto é
  classificado 3× (padrão) com pequena variação de temperatura, e a
  categoria final é a moda. O `confidence_score` sai daí — 1.0 = todas
  as 3 rodadas concordaram; 0.67 = 2 de 3.
- `batch`: quantos documentos vão por requisição. Depende do modelo —
  10–20 é seguro para corpora legislativos.

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
  corpus   = corpus,
  codebook = cb_completo,
  chat     = chat,
  n_rep    = 3,       # self-consistency
  batch    = 10,      # documentos por lote
  verbose  = TRUE
)

head(resultado)
```

O tibble de saída traz: `doc_id`, `categoria`, `confidence_score` (via
*self-consistency*), `reasoning` (raciocínio do modelo, se pedido) e os
metadados originais do corpus.

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
