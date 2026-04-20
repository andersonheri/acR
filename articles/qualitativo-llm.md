# Análise de Conteúdo Qualitativa com LLMs

## Visão geral

O módulo qualitativo do **acR** implementa um pipeline completo de
análise de conteúdo assistida por modelos de linguagem (LLMs), seguindo
as diretrizes metodológicas de Krippendorff (2018) e as recomendações
empíricas de Gilardi, Alizadeh e Kubli (2023) sobre uso de LLMs para
anotação de textos políticos.

O pipeline tem cinco etapas:

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
OpenRouter — sem alterar a lógica de análise.

------------------------------------------------------------------------

## Instalação e configuração

``` r
# Instalar acR
remotes::install_github("andersonheri/acR")

# Instalar ellmer
install.packages("ellmer")

# Configurar chave de API (exemplo: Anthropic)
Sys.setenv(ANTHROPIC_API_KEY = "sk-ant-...")
```

------------------------------------------------------------------------

## Etapa 1 — Criar o codebook

O codebook é o instrumento central da análise de conteúdo. Ele define as
categorias analíticas, suas definições operacionais, exemplos positivos
e negativos, e pesos relativos para instrução da LLM.

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
      weight       = 1.5  # categoria mais difícil: peso maior
    ),
    neutro = list(
      definition   = "Discurso descritivo, sem posicionamento claro.",
      examples_pos = c("O projeto foi apresentado na sessão de hoje."),
      weight       = 1
    )
  ),
  multilabel = FALSE,
  lang       = "pt"
)

print(cb)
```

### Adicionar e remover categorias

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

# Fundir: tom + estilo retórico em um único codebook multilabel
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
  codebook          = cb_completo,
  to                = "en",
  model             = "anthropic/claude-sonnet-4-5",
  translate_examples = TRUE
)
```

------------------------------------------------------------------------

## Etapa 4 — Inspecionar histórico e gerar system prompt

``` r
# Ver todas as modificações feitas no codebook
ac_qual_codebook_history(cb_completo)
```

``` r
# Gerar system prompt para uso direto com ellmer
prompt <- as_prompt(
  cb_completo,
  reasoning        = TRUE,
  reasoning_length = "medium"  # "short" | "medium" | "detailed"
)

# O prompt pode ser passado diretamente a um objeto Chat:
# chat$set_system_prompt(prompt)
```

------------------------------------------------------------------------

## Etapa 5 — Classificar o corpus

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

------------------------------------------------------------------------

## Etapa 6 — Salvar e carregar

``` r
# Salvar em YAML para replicabilidade
ac_qual_save_codebook(cb_completo, path = "codebook_discurso.yaml")

# Carregar em outra sessão
cb_recarregado <- ac_qual_load_codebook("codebook_discurso.yaml")
```

------------------------------------------------------------------------

## Etapa 7 — Validação e confiabilidade

``` r
# Amostrar 30 documentos para revisão humana (amostragem estratificada)
amostra <- ac_qual_sample(resultado, n = 30, method = "stratified")
ac_qual_export_for_review(amostra, path = "revisao.xlsx")

# Após preenchimento manual, calcular IRR
revisado <- ac_qual_import_human("revisao_preenchida.xlsx")
irr      <- ac_qual_irr(resultado, revisado)
print(irr)
```

------------------------------------------------------------------------

## Referências

Gilardi, F., Alizadeh, M., & Kubli, M. (2023). ChatGPT outperforms crowd
workers for text-annotation tasks. *PNAS*, 120(30).
<https://doi.org/10.1073/pnas.2305016120>

Krippendorff, K. (2018). *Content Analysis: An Introduction to Its
Methodology* (4th ed.). SAGE.

Maerz, S., & Benoit, K. (2025). *quallmer: Qualitative Analysis with
Large Language Models in R*. GitHub.
<https://github.com/SFB1472/quallmer>

Sampaio, R. C., & Lycarião, D. (2021). *Análise de conteúdo categorial:
manual de aplicação*. Brasília: ENAP.

Wickham, H., et al. (2025). *ellmer: Chat with Large Language Models*. R
package. <https://ellmer.tidyverse.org>
