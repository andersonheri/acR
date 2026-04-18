# Análise de Conteúdo Qualitativa com LLMs via ellmer

## Visão Geral

O pacote **acR** oferece duas funções para análise de conteúdo
qualitativa assistida por modelos de linguagem de grande escala (LLMs):

| Função                                                                                   | O que faz                                                  |
|------------------------------------------------------------------------------------------|------------------------------------------------------------|
| [`ac_qual_code()`](https://andersonheri.github.io/acR/reference/ac_qual_code.md)         | Classifica textos em categorias de um *codebook* existente |
| [`ac_qual_codebook()`](https://andersonheri.github.io/acR/reference/ac_qual_codebook.md) | Induz um *codebook* a partir de um corpus de textos        |

A partir da versão 0.3.0, ambas as funções aceitam o argumento `chat =`,
que recebe qualquer objeto `Chat` do pacote **ellmer**. Isso permite
usar **qualquer provedor suportado pelo ellmer** — OpenAI, Google
Gemini, Groq, Anthropic, Ollama, Mistral, DeepSeek, entre outros — sem
alterar a lógica de análise.

> **Retrocompatibilidade:** quando `chat = NULL` (padrão), as funções
> usam o comportamento anterior baseado em `provider` e `api_key`,
> mantendo compatibilidade total com código existente.

------------------------------------------------------------------------

## Instalação

``` r
# Versão de desenvolvimento
remotes::install_github("andersonheri/acR")

# Dependências necessárias
install.packages(c("ellmer", "dplyr", "tibble"))
```

------------------------------------------------------------------------

## O argumento `chat =`: conceito central

O `ellmer` padroniza a interface com qualquer LLM em um objeto `Chat`
criado pelas funções `chat_*()`. O acR usa esse objeto diretamente,
delegando ao ellmer toda a comunicação com a API.

    Pesquisador
        │
        ▼
    ellmer::chat_*()   ←─── escolha o provedor aqui
        │
        ▼
    acR::ac_qual_code()   /   ac_qual_codebook()
        │
        ▼
    Resultado: data.frame com categorias + justificativas

O fluxo de trabalho padrão tem três passos:

1.  **Configurar** a chave de API via variável de ambiente
    (`.Renviron`).
2.  **Instanciar** o objeto `Chat` com `ellmer::chat_*()`.
3.  **Passar** o objeto para
    [`ac_qual_code()`](https://andersonheri.github.io/acR/reference/ac_qual_code.md)
    ou
    [`ac_qual_codebook()`](https://andersonheri.github.io/acR/reference/ac_qual_codebook.md)
    via `chat =`.

------------------------------------------------------------------------

## Dados de exemplo

Para reproduzir os exemplos abaixo, usamos um corpus de discursos
parlamentares sobre política de saúde e um *codebook* temático simples.

``` r
library(acR)
library(ellmer)

# Corpus: trechos de discursos parlamentares (vetor de caracteres)
corpus <- c(
  "O governo precisa ampliar o financiamento do SUS nas regiões Norte e Nordeste.",
  "A privatização dos serviços hospitalares reduz custos e melhora a eficiência.",
  "Precisamos de mais médicos nas UBSs da periferia, especialmente pediatras.",
  "O Programa Farmácia Popular deve ser expandido para municípios menores.",
  "A subnotificação de doenças tropicais compromete as políticas de vigilância.",
  "Defendo a universalização da cobertura vacinal como prioridade orçamentária.",
  "O modelo de OSS (Organizações Sociais de Saúde) deve ser regulamentado.",
  "É preciso investir em telemedicina para alcançar populações isoladas."
)

# Codebook: categorias temáticas
codebook <- data.frame(
  categoria    = c("Financiamento", "Privatização", "Atenção Básica",
                   "Acesso a Medicamentos", "Vigilância Epidemiológica",
                   "Imunização", "Gestão", "Tecnologia em Saúde"),
  descricao    = c(
    "Referências a orçamento, repasses e financiamento público da saúde",
    "Discussões sobre privatização, concessão ou gestão privada de serviços",
    "Menções a UBS, ESF, atenção primária e médicos de família",
    "Acesso a medicamentos, farmácias populares e assistência farmacêutica",
    "Vigilância sanitária, epidemiológica, subnotificação e doenças endêmicas",
    "Vacinação, campanhas de imunização e cobertura vacinal",
    "Modelos de gestão hospitalar, OSS, eficiência administrativa",
    "Telemedicina, prontuário eletrônico, inovação em saúde"
  ),
  stringsAsFactors = FALSE
)
```

------------------------------------------------------------------------

## Provedores disponíveis via ellmer

### 1. Google Gemini (tier gratuito disponível)

Recomendado para pesquisadores sem orçamento para APIs pagas. O modelo
`gemini-2.5-flash` é rápido e preciso para classificação de textos em
português.

``` r
# 1. Configurar: adicione ao .Renviron
# GOOGLE_API_KEY="sua_chave_aqui"

# 2. Instanciar
chat_gemini <- chat_google_gemini(
  model         = "gemini-2.5-flash",
  system_prompt = "Você é um especialista em análise de conteúdo de discursos políticos brasileiros.",
  echo          = "none"
)

# 3. Classificar com codebook existente
resultado_gemini <- ac_qual_code(
  textos   = corpus,
  codebook = codebook,
  chat     = chat_gemini
)

head(resultado_gemini)

# 4. Ou induzir codebook a partir do corpus
codebook_gemini <- ac_qual_codebook(
  textos = corpus,
  n_cats = 5,
  chat   = chat_gemini
)

print(codebook_gemini)
```

------------------------------------------------------------------------

### 2. OpenAI (GPT-4.1 / GPT-4o)

``` r
# OPENAI_API_KEY="sua_chave_aqui"  # .Renviron

chat_gpt <- chat_openai(
  model         = "gpt-4.1",          # ou "gpt-4o", "gpt-4.1-nano"
  system_prompt = "Você é um especialista em análise de conteúdo de discursos políticos brasileiros.",
  echo          = "none"
)

resultado_openai <- ac_qual_code(
  textos   = corpus,
  codebook = codebook,
  chat     = chat_gpt
)

# Para tarefas em lote com muitos textos, prefira modelos mais baratos:
chat_gpt_nano <- chat_openai(
  model = "gpt-4.1-nano",
  echo  = "none"
)

resultado_nano <- ac_qual_code(
  textos   = corpus,
  codebook = codebook,
  chat     = chat_gpt_nano
)
```

------------------------------------------------------------------------

### 3. Groq (inferência ultrarrápida, plano gratuito)

O Groq é especialmente útil para prototipagem rápida: latência muito
baixa e plano gratuito generoso para modelos como
`llama-3.3-70b-versatile`.

``` r
# GROQ_API_KEY="sua_chave_aqui"  # .Renviron

chat_groq <- chat_groq(
  model         = "llama-3.3-70b-versatile",
  system_prompt = "Você é um especialista em análise de conteúdo de discursos políticos brasileiros.",
  echo          = "none"
)

resultado_groq <- ac_qual_code(
  textos   = corpus,
  codebook = codebook,
  chat     = chat_groq
)

# Para classificação mais econômica:
chat_groq_mini <- chat_groq(
  model = "llama-3.1-8b-instant",
  echo  = "none"
)

resultado_groq_mini <- ac_qual_code(
  textos   = corpus,
  codebook = codebook,
  chat     = chat_groq_mini
)
```

------------------------------------------------------------------------

### 4. Anthropic Claude

``` r
# ANTHROPIC_API_KEY="sua_chave_aqui"  # .Renviron

chat_claude <- chat_anthropic(
  model         = "claude-sonnet-4-20250514",
  system_prompt = "Você é um especialista em análise de conteúdo de discursos políticos brasileiros.",
  echo          = "none"
)

resultado_claude <- ac_qual_code(
  textos   = corpus,
  codebook = codebook,
  chat     = chat_claude
)

codebook_claude <- ac_qual_codebook(
  textos = corpus,
  n_cats = 6,
  chat   = chat_claude
)
```

------------------------------------------------------------------------

### 5. Ollama (modelos locais, 100% privado)

Ideal quando os textos contêm informações sensíveis (entrevistas,
documentos internos de gestão pública) e não podem ser enviados a APIs
externas. Requer [Ollama](https://ollama.com) instalado localmente.

``` r
# Sem chave de API — modelos rodam localmente
# Instale o modelo antes: ollama pull llama3.2

chat_ollama_local <- chat_ollama(
  model         = "llama3.2",          # ou "mistral", "qwen2.5", "gemma3"
  system_prompt = "Você é um especialista em análise de conteúdo de discursos políticos brasileiros.",
  echo          = "none"
)

resultado_ollama <- ac_qual_code(
  textos   = corpus,
  codebook = codebook,
  chat     = chat_ollama_local
)

# Modelos maiores para melhor precisão (requer hardware adequado):
chat_ollama_grande <- chat_ollama(
  model = "llama3.1:70b",
  echo  = "none"
)

resultado_ollama_grande <- ac_qual_code(
  textos   = corpus,
  codebook = codebook,
  chat     = chat_ollama_grande
)
```

------------------------------------------------------------------------

### 6. Mistral

``` r
# MISTRAL_API_KEY="sua_chave_aqui"  # .Renviron

chat_mistral <- chat_mistral(
  model = "mistral-large-latest",
  echo  = "none"
)

resultado_mistral <- ac_qual_code(
  textos   = corpus,
  codebook = codebook,
  chat     = chat_mistral
)
```

------------------------------------------------------------------------

### 7. DeepSeek

``` r
# DEEPSEEK_API_KEY="sua_chave_aqui"  # .Renviron

chat_deepseek <- chat_deepseek(
  model = "deepseek-chat",
  echo  = "none"
)

resultado_deepseek <- ac_qual_code(
  textos   = corpus,
  codebook = codebook,
  chat     = chat_deepseek
)
```

------------------------------------------------------------------------

### 8. OpenRouter (acesso unificado a centenas de modelos)

O OpenRouter permite acessar modelos de múltiplos provedores (Anthropic,
Google, Meta, Mistral etc.) com uma única chave de API, útil para
comparar resultados.

``` r
# OPENROUTER_API_KEY="sua_chave_aqui"  # .Renviron

chat_or_gemini <- chat_openrouter(
  model = "google/gemini-2.5-flash",
  echo  = "none"
)

chat_or_llama <- chat_openrouter(
  model = "meta-llama/llama-3.3-70b-instruct",
  echo  = "none"
)

resultado_or <- ac_qual_code(
  textos   = corpus,
  codebook = codebook,
  chat     = chat_or_gemini
)
```

------------------------------------------------------------------------

## Retrocompatibilidade: uso sem `chat =`

Código escrito com as versões anteriores do acR continua funcionando sem
modificações. Quando `chat = NULL`, as funções usam os argumentos
legados `provider` e `api_key`:

``` r
# Comportamento anterior — ainda funciona
resultado_legado <- ac_qual_code(
  textos   = corpus,
  codebook = codebook,
  provider = "openai",
  api_key  = Sys.getenv("OPENAI_API_KEY"),
  model    = "gpt-4o"
  # chat = NULL  (padrão implícito)
)
```

> **Recomendação:** migre gradualmente para `chat =` em projetos novos,
> pois esse padrão oferece controle mais fino sobre o modelo, o
> `system_prompt` e os parâmetros de geração.

------------------------------------------------------------------------

## Comparação entre provedores

Um uso avançado é comparar a concordância entre diferentes modelos no
mesmo corpus, uma estratégia análoga à avaliação de confiabilidade
intercodificadores (Krippendorff, 2004).

``` r
library(dplyr)
library(irr)  # install.packages("irr")

# Instanciar múltiplos provedores
provedores <- list(
  gemini  = chat_google_gemini(model = "gemini-2.5-flash", echo = "none"),
  groq    = chat_groq(model = "llama-3.3-70b-versatile",   echo = "none"),
  ollama  = chat_ollama(model = "llama3.2",                 echo = "none")
)

# Classificar com cada provedor
resultados <- lapply(names(provedores), function(nome) {
  res <- ac_qual_code(
    textos   = corpus,
    codebook = codebook,
    chat     = provedores[[nome]]
  )
  res$provedor <- nome
  res
})

# Combinar e pivotar para matriz de concordância
df_comp <- bind_rows(resultados)

# Avaliar concordância (kappa de Cohen entre pares)
matriz <- df_comp |>
  select(texto_id, categoria, provedor) |>
  tidyr::pivot_wider(names_from = provedor, values_from = categoria)

kappa2(matriz[, -1])
```

------------------------------------------------------------------------

## Ajuste fino do `system_prompt`

O `system_prompt` é o principal vetor de customização do comportamento
do modelo. Recomendações para análise de conteúdo:

``` r
# Prompt genérico (funciona para qualquer corpus)
prompt_generico <- paste(
  "Você é um assistente especializado em análise de conteúdo qualitativa.",
  "Classifique cada texto na categoria mais adequada do codebook fornecido.",
  "Responda apenas com o nome exato da categoria e uma justificativa de 1-2 frases.",
  "Nunca invente categorias que não estejam no codebook."
)

# Prompt especializado para ciência política brasileira
prompt_cp_br <- paste(
  "Você é um cientista político especializado em políticas públicas brasileiras.",
  "Sua tarefa é classificar trechos de discursos parlamentares nas categorias",
  "temáticas do codebook, com base no conteúdo substantivo do texto.",
  "Priorize o tema central do trecho, não menções secundárias.",
  "Justifique com referência a conceitos e atores políticos quando pertinente."
)

chat_especializado <- chat_google_gemini(
  model         = "gemini-2.5-flash",
  system_prompt = prompt_cp_br,
  echo          = "none"
)

resultado_esp <- ac_qual_code(
  textos   = corpus,
  codebook = codebook,
  chat     = chat_especializado
)
```

------------------------------------------------------------------------

## Configuração de variáveis de ambiente

O método recomendado é armazenar todas as chaves no arquivo `.Renviron`
do usuário, editável com `usethis::edit_r_environ()`:

    # ~/.Renviron
    GOOGLE_API_KEY=AIza...
    OPENAI_API_KEY=sk-...
    GROQ_API_KEY=gsk_...
    ANTHROPIC_API_KEY=sk-ant-...
    MISTRAL_API_KEY=...
    DEEPSEEK_API_KEY=...
    OPENROUTER_API_KEY=sk-or-...

Depois de salvar, reinicie o R. Verifique com
`Sys.getenv("GOOGLE_API_KEY")`.

Nunca inclua chaves diretamente no código-fonte ou em arquivos
versionados.

------------------------------------------------------------------------

## Tabela de referência rápida

| Provedor         | Função ellmer                                                                            | Variável de ambiente | Tier gratuito |
|------------------|------------------------------------------------------------------------------------------|----------------------|---------------|
| Google Gemini    | [`chat_google_gemini()`](https://ellmer.tidyverse.org/reference/chat_google_gemini.html) | `GOOGLE_API_KEY`     | ✅ Sim        |
| Groq             | [`chat_groq()`](https://ellmer.tidyverse.org/reference/chat_groq.html)                   | `GROQ_API_KEY`       | ✅ Sim        |
| Ollama (local)   | [`chat_ollama()`](https://ellmer.tidyverse.org/reference/chat_ollama.html)               | Não necessária       | ✅ Gratuito   |
| OpenAI           | [`chat_openai()`](https://ellmer.tidyverse.org/reference/chat_openai.html)               | `OPENAI_API_KEY`     | ❌ Pago       |
| Anthropic Claude | [`chat_anthropic()`](https://ellmer.tidyverse.org/reference/chat_anthropic.html)         | `ANTHROPIC_API_KEY`  | ❌ Pago       |
| Mistral          | [`chat_mistral()`](https://ellmer.tidyverse.org/reference/chat_mistral.html)             | `MISTRAL_API_KEY`    | ❌ Pago       |
| DeepSeek         | [`chat_deepseek()`](https://ellmer.tidyverse.org/reference/chat_deepseek.html)           | `DEEPSEEK_API_KEY`   | ⚠️ Limitado   |
| OpenRouter       | [`chat_openrouter()`](https://ellmer.tidyverse.org/reference/chat_openrouter.html)       | `OPENROUTER_API_KEY` | ⚠️ Por uso    |

------------------------------------------------------------------------

## Referências

KRIPPENDORFF, K. **Content Analysis: An Introduction to Its
Methodology**. 3. ed. Thousand Oaks: SAGE, 2013.

NEUENDORF, K. A. **The Content Analysis Guidebook**. 2. ed. Thousand
Oaks: SAGE, 2017.

WICKHAM, H. et al. **ellmer: Chat with Large Language Models**. R
package version 0.2.0. Disponível em: <https://ellmer.tidyverse.org>.
Acesso em: abr. 2026.

BAIL, C. A. Breaking the social media prism: How to make our platforms
less polarizing. **American Journal of Sociology**, v. 127, n. 2,
p. 661-663, 2021.
