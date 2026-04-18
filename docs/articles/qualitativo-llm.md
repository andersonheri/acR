# Análise de Conteúdo Qualitativa com LLMs

## Visão geral

O módulo qualitativo do **acR** implementa um pipeline completo de
análise de conteúdo assistida por modelos de linguagem (LLMs), seguindo
as diretrizes metodológicas de Krippendorff (2018) e as recomendações
empíricas de Gilardi, Alizadeh e Kubli (2023) sobre uso de LLMs para
anotação de textos políticos.

O pipeline tem quatro etapas:

    ac_fetch_camara() / ac_fetch_senado()   ← coleta
             ↓
    ac_corpus()                             ← estruturação
             ↓
    ac_qual_codebook()                      ← codebook
             ↓
    ac_qual_code()                          ← classificação com LLM

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
```

As chaves de API devem ser armazenadas no `.Renviron`, **nunca** no
código-fonte. Edite com:

``` r
usethis::edit_r_environ()
```

Adicione as linhas correspondentes ao(s) provedor(es) que vai usar:

    GROQ_API_KEY=sua_chave
    OPENAI_API_KEY=sua_chave
    ANTHROPIC_API_KEY=sua_chave
    GOOGLE_API_KEY=sua_chave
    MISTRAL_API_KEY=sua_chave
    DEEPSEEK_API_KEY=sua_chave
    OPENROUTER_API_KEY=sua_chave

Reinicie o R após salvar. Verifique com `Sys.getenv("GROQ_API_KEY")`.

------------------------------------------------------------------------

## Exemplo completo: discursos parlamentares

### Etapa 1 — Coletar corpus via API da Câmara

``` r
library(acR)
library(ellmer)
library(dplyr)

# Coletar discursos plenários — março de 2024
corpus_raw <- ac_fetch_camara(
  data_inicio   = "2024-03-11",
  data_fim      = "2024-03-15",
  tipo_discurso = "plenario",
  n_max         = 30L
)

# Estrutura do resultado
glimpse(corpus_raw)
```

A função retorna um `data.frame` com as colunas `id_discurso`,
`nome_deputado`, `partido`, `uf`, `data`, `tipo_discurso`, `sumario` e
`texto` (transcrição integral quando disponível).

### Etapa 2 — Criar corpus

``` r
corpus <- ac_corpus(
  corpus_raw,
  text  = texto,
  docid = id_discurso
)

print(corpus)
```

### Etapa 3 — Definir codebook

O codebook estrutura as categorias analíticas, suas definições e
instruções de classificação. Para discursos parlamentares temáticos, um
codebook de cinco categorias cobre a maior parte do conteúdo do
plenário:

``` r
codebook <- ac_qual_codebook(
  name         = "temas_plenario",
  instructions = "Classifique o tema principal do discurso parlamentar.",
  categories   = list(
    seguranca_publica  = list(
      definition = "Discursos sobre violência, polícia, crime e segurança pública."
    ),
    economia_fiscal    = list(
      definition = "Discursos sobre impostos, orçamento, gastos públicos e política fiscal."
    ),
    politica_social    = list(
      definition = "Discursos sobre saúde, educação, assistência social e combate à pobreza."
    ),
    orientacao_votacao = list(
      definition = "Orientação de bancada para votação de projetos de lei."
    ),
    outros             = list(
      definition = "Discursos que não se encaixam nas categorias anteriores."
    )
  ),
  mode = "manual"
)

print(codebook)
```

### Etapa 4 — Classificar com LLM

O argumento `chat =` recebe qualquer objeto `Chat` do **ellmer**. Abaixo
usamos o Groq com `llama-3.3-70b-versatile`, que oferece plano gratuito
e latência baixa:

``` r
# Instanciar provedor — chave lida do .Renviron automaticamente
chat_obj <- chat_groq(
  model = "llama-3.3-70b-versatile",
  echo  = "none"
)

# Classificar corpus completo
resultado <- ac_qual_code(
  corpus           = corpus,
  codebook         = codebook,
  chat             = chat_obj,
  confidence       = "total",    # self-consistency em k rodadas
  k_consistency    = 3L,
  reasoning        = TRUE,       # inclui justificativa por documento
  reasoning_length = "short"
)
```

O argumento `confidence = "total"` ativa o cálculo de certeza via
*self-consistency* (Wang et al., 2023): o modelo classifica cada
documento `k_consistency` vezes com temperatura \> 0 e a confiança é a
proporção de concordância entre as rodadas. Valores ≥ 0.80 indicam alta
consistência (Landis & Koch, 1977).

------------------------------------------------------------------------

## Resultados

Os resultados obtidos com 30 discursos do plenário de março/2024:

``` r
# Distribuição de categorias
resultado |>
  count(categoria, sort = TRUE) |>
  mutate(pct = round(n / sum(n) * 100, 1))
```

    ## # A tibble: 5 × 3
    ##   categoria              n   pct
    ##   <chr>              <int> <dbl>
    ## 1 orientacao_votacao    15  50
    ## 2 politica_social        6  20
    ## 3 economia_fiscal        4  13.3
    ## 4 outros                 4  13.3
    ## 5 seguranca_publica      1   3.3

``` r
# Confiança média e distribuição
mean(resultado$confidence_score, na.rm = TRUE)
resultado |> count(confidence_level, sort = TRUE)
```

    ## [1] 0.9111111
    ##
    ## # A tibble: 2 × 2
    ##   confidence_level     n
    ##   <chr>            <int>
    ## 1 alta                22
    ## 2 media                8

Confiança média de **0.91** com 22/30 documentos na faixa “alta” (≥
0.80) indica classificação estável e reproduzível. A dominância de
`orientacao_votacao` (50%) é consistente com o padrão de votações
intensas no plenário no período.

``` r
# Amostra de classificações com raciocínio
resultado |>
  select(nome_deputado, partido, categoria, confidence_score, raciocinio) |>
  slice_head(n = 5)
```

    ## # A tibble: 5 × 5
    ##   nome_deputado   partido categoria          confidence_score raciocinio
    ##   <chr>           <chr>   <chr>                         <dbl> <chr>
    ## 1 Acácio Favacho  MDB     seguranca_publica             1     O discurso aborda os índices de
    ## 2 Adriana Ventura NOVO    orientacao_votacao            1     O texto expressa a orientação
    ## 3 Adriana Ventura NOVO    economia_fiscal               0.667 O texto foi classificado nesta
    ## 4 Adriana Ventura NOVO    orientacao_votacao            1     O texto é uma orientação de voto
    ## 5 Adriana Ventura NOVO    orientacao_votacao            1     O texto apresenta uma orientação

------------------------------------------------------------------------

## Provedores disponíveis

Qualquer provedor suportado pelo **ellmer** funciona via `chat =`. A
escolha depende de custo, privacidade e qualidade para português:

``` r
# Groq — gratuito, rápido, bom para prototipagem
chat_obj <- chat_groq(model = "llama-3.3-70b-versatile", echo = "none")

# Google Gemini — tier gratuito generoso
chat_obj <- chat_google_gemini(model = "gemini-2.5-flash", echo = "none")

# Ollama — local, sem envio de dados (ideal para dados sensíveis)
chat_obj <- chat_ollama(model = "llama3.2", echo = "none")

# OpenAI
chat_obj <- chat_openai(model = "gpt-4.1", echo = "none")

# Anthropic Claude
chat_obj <- chat_anthropic(model = "claude-sonnet-4-20250514", echo = "none")

# Mistral
chat_obj <- chat_mistral(model = "mistral-large-latest", echo = "none")

# DeepSeek
chat_obj <- chat_deepseek(model = "deepseek-chat", echo = "none")

# OpenRouter (acesso a centenas de modelos com uma chave)
chat_obj <- chat_openrouter(model = "google/gemini-2.5-flash", echo = "none")
```

| Provedor | Função | Variável de ambiente | Tier gratuito |
|----|----|----|----|
| Groq | [`chat_groq()`](https://ellmer.tidyverse.org/reference/chat_groq.html) | `GROQ_API_KEY` | Sim |
| Google Gemini | [`chat_google_gemini()`](https://ellmer.tidyverse.org/reference/chat_google_gemini.html) | `GOOGLE_API_KEY` | Sim |
| Ollama | [`chat_ollama()`](https://ellmer.tidyverse.org/reference/chat_ollama.html) | não necessária | Gratuito |
| OpenAI | [`chat_openai()`](https://ellmer.tidyverse.org/reference/chat_openai.html) | `OPENAI_API_KEY` | Não |
| Anthropic | [`chat_anthropic()`](https://ellmer.tidyverse.org/reference/chat_anthropic.html) | `ANTHROPIC_API_KEY` | Não |
| Mistral | [`chat_mistral()`](https://ellmer.tidyverse.org/reference/chat_mistral.html) | `MISTRAL_API_KEY` | Não |
| DeepSeek | [`chat_deepseek()`](https://ellmer.tidyverse.org/reference/chat_deepseek.html) | `DEEPSEEK_API_KEY` | Limitado |
| OpenRouter | [`chat_openrouter()`](https://ellmer.tidyverse.org/reference/chat_openrouter.html) | `OPENROUTER_API_KEY` | Por uso |

------------------------------------------------------------------------

## Busca de literatura via OpenAlex

[`ac_qual_search_literature()`](https://andersonheri.github.io/acR/reference/ac_qual_search_literature.md)
busca referências reais na API do OpenAlex (Priem et al., 2022) e usa a
LLM para sintetizar os abstracts em português. Isso evita alucinações
bibliográficas comuns quando a LLM opera sem fonte externa.

``` r
lit <- ac_qual_search_literature(
  concept       = "democratic backsliding",
  n_refs        = 5,
  min_citations = 50,
  chat          = chat_obj
)

# Resultado: tibble com autor, ano, revista, n_citacoes,
# trecho_original, definicao_pt, abstract_original, link
print(lit)
```

------------------------------------------------------------------------

## Validação: confiabilidade intercodificadores

Após a classificação automática, recomenda-se validar uma amostra com
codificadores humanos usando
[`ac_qual_irr()`](https://andersonheri.github.io/acR/reference/ac_qual_irr.md):

``` r
# Exportar amostra para revisão humana
ac_qual_export_for_review(
  resultado,
  n        = 20,
  path     = "revisao_humana.xlsx",
  strategy = "uncertainty"   # prioriza documentos com menor confiança
)

# Após preenchimento manual, importar e calcular concordância
humano <- ac_qual_import_human("revisao_humana.xlsx")

concordancia <- ac_qual_irr(
  coded  = resultado,
  human  = humano,
  method = c("kappa", "alpha")
)

print(concordancia)
```

Interpretação do kappa de Cohen baseada em Landis e Koch (1977): ≥ 0.80
indica concordância quase perfeita; 0.61–0.79, substancial; 0.41–0.60,
moderada; \< 0.41, fraca.

------------------------------------------------------------------------

## Referências

GILARDI, F.; ALIZADEH, M.; KUBLI, M. ChatGPT outperforms crowd workers
for text-annotation tasks. **PNAS**, v. 120, n. 30, 2023.

KRIPPENDORFF, K. **Content Analysis: An Introduction to Its
Methodology**. 4. ed. Thousand Oaks: SAGE, 2018.

LANDIS, J. R.; KOCH, G. G. The measurement of observer agreement for
categorical data. **Biometrics**, v. 33, n. 1, p. 159–174, 1977.

PRIEM, J. et al. OpenAlex: A fully-open index of the global research
system. **arXiv**, 2205.01833, 2022.

WANG, X. et al. Self-consistency improves chain of thought reasoning in
language models. **EMNLP**, 2023.

WICKHAM, H. et al. **ellmer: Chat with Large Language Models**. Posit,
2025. Disponível em: <https://ellmer.tidyverse.org>.
