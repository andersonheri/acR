# acR

> **Análise de Conteúdo em R**: pipeline integrado qualitativo (LLMs) e
> quantitativo, com visualizações modernas e foco em corpora
> brasileiros.

## Visao geral

O `acR` oferece um pipeline completo de análise de conteúdo textual para
pesquisadores em ciências sociais. O pacote integra dois módulos
principais: um **módulo qualitativo** baseado em LLMs para codificação
automática com validação humana, e um **módulo quantitativo** para
frequencias, TF-IDF, keyness, sentimento e modelagem de tópicos (LDA).
Todas as funções foram projetadas para corpora em portugues e seguem as
convencoes metodologicas de Bardin (2011) e Krippendorff (2018).

A partir da versão 0.1.0, o módulo qualitativo usa o pacote
[ellmer](https://ellmer.tidyverse.org/) como backend unificado,
permitindo usar qualquer provedor de LLM — OpenAI, Google Gemini, Groq,
Anthropic, Ollama, Mistral, DeepSeek, OpenRouter e outros — via o
argumento `chat=`.

## Instalacao

``` r
# Versão de desenvolvimento (GitHub)
# install.packages("remotes")
remotes::install_github("andersonheri/acR")
```

## Exemplo minimo

### Módulo qualitativo — codificação com LLM

``` r
library(acR)
library(ellmer)

# 1. Corpus
corpus <- ac_corpus(
  c("Esta reforma beneficia os trabalhadores.",
    "O projeto gerara desemprego em massa.",
    "O artigo 3o estabelece prazo de 180 dias."),
  id = c("doc_1", "doc_2", "doc_3")
)

# 2. Codebook
codebook <- ac_qual_codebook(
  name         = "posicionamento",
  instructions = "Classifique o posicionamento do texto.",
  categories   = c("Favoravel", "Contrario", "Neutro/Tecnico"),
  mode         = "manual"
)

# 3. Instanciar provedor via ellmer (qualquer um suportado)
chat_obj <- chat_google_gemini(model = "gemini-2.5-flash", echo = "none")
# ou: chat_obj <- chat_groq(model = "llama-3.3-70b-versatile", echo = "none")
# ou: chat_obj <- chat_ollama(model = "llama3.2", echo = "none")

# 4. Codificar
resultado <- ac_qual_code(
  corpus   = corpus,
  codebook = codebook,
  chat     = chat_obj
)

# 5. Exportar
ac_export(resultado, formato = "csv", arquivo = "codificação.csv")
```

### Módulo quantitativo — frequencias e sentimento

``` r
# Tokenizar e calcular frequencias
tokens   <- ac_tokenize(ac_clean(corpus), remover_stopwords = TRUE)
contagem <- ac_count(tokens)
ac_plot_top_terms(ac_top_terms(contagem, n = 10))

# Sentimento
sent <- ac_sentiment(corpus, lexico = "oplexicon")
ac_plot_sentiment(sent)
```

### TF-IDF — termos caracteristicos por grupo

``` r
library(acR)

df <- data.frame(
  id      = paste0("prop_", 1:6),
  texto   = c(
    "Esta proposta amplia direitos trabalhistas e proteção social.",
    "O projeto garante seguro-desemprego para trabalhadores informais.",
    "Propomos redução de impostos para estimular o mercado.",
    "A desburocratização e essencial para a competitividade.",
    "O texto fortalece o SUS e o acesso a saúde pública.",
    "Defendemos a expansão de políticas de assistência social."
  ),
  partido = c("PT", "PT", "PL", "PL", "PSOL", "PSOL"),
  stringsAsFactors = FALSE
)

corpus <- ac_corpus(df, text = texto, docid = id, meta = partido)
tokens  <- ac_tokenize(ac_clean(corpus), remover_stopwords = TRUE)
freq    <- ac_count(tokens, by = "partido")
tfidf   <- ac_tf_idf(freq, by = "partido")

tfidf |>
  dplyr::group_by(partido) |>
  dplyr::slice_max(tf_idf, n = 5) |>
  dplyr::select(partido, token, tf_idf)

ac_plot_tf_idf(tfidf, by = "partido", n = 5)
```

## Funções por módulo

### Corpus e pre-processamento

| Funcao | Descrição |
|----|----|
| [`ac_corpus()`](https://andersonheri.github.io/acR/reference/ac_corpus.md) | Criar objeto corpus |
| [`ac_import()`](https://andersonheri.github.io/acR/reference/ac_import.md) | Importar corpus de arquivo externo |
| [`ac_clean()`](https://andersonheri.github.io/acR/reference/ac_clean.md) | Limpar texto (lowercase, pontuacao, numeros) |
| [`is_ac_corpus()`](https://andersonheri.github.io/acR/reference/is_ac_corpus.md) | Verificar se objeto e um corpus acR |
| [`ac_tokenize()`](https://andersonheri.github.io/acR/reference/ac_tokenize.md) | Tokenizar com remoção de stopwords |

### Análise quantitativa

| Funcao | Descrição |
|----|----|
| [`ac_count()`](https://andersonheri.github.io/acR/reference/ac_count.md) | Frequência de termos |
| [`ac_top_terms()`](https://andersonheri.github.io/acR/reference/ac_top_terms.md) | Top N termos |
| [`ac_tf_idf()`](https://andersonheri.github.io/acR/reference/ac_tf_idf.md) | TF-IDF por documento |
| [`ac_keyness()`](https://andersonheri.github.io/acR/reference/ac_keyness.md) | Vocabulario distintivo entre grupos |
| [`ac_cooccurrence()`](https://andersonheri.github.io/acR/reference/ac_cooccurrence.md) | Rede de co-ocorrencia |
| [`ac_sentiment()`](https://andersonheri.github.io/acR/reference/ac_sentiment.md) | Sentimento (OpLexicon / SentiLex-PT) |
| [`ac_lda()`](https://andersonheri.github.io/acR/reference/ac_lda.md) | Modelagem de tópicos LDA |
| [`ac_lda_tune()`](https://andersonheri.github.io/acR/reference/ac_lda_tune.md) | Seleção ótima de K tópicos |

### Análise qualitativa com LLMs

| Funcao | Descrição |
|----|----|
| [`ac_qual_codebook()`](https://andersonheri.github.io/acR/reference/ac_qual_codebook.md) | Construir codebook estruturado |
| [`ac_qual_code()`](https://andersonheri.github.io/acR/reference/ac_qual_code.md) | Codificar corpus via LLM |
| [`ac_qual_search_literature()`](https://andersonheri.github.io/acR/reference/ac_qual_search_literature.md) | Buscar literatura via OpenAlex + LLM |
| [`ac_qual_list_models()`](https://andersonheri.github.io/acR/reference/ac_qual_list_models.md) | Listar modelos disponiveis |
| [`ac_qual_recommend_model()`](https://andersonheri.github.io/acR/reference/ac_qual_recommend_model.md) | Recomendação automática de modelo |
| [`ac_qual_sample()`](https://andersonheri.github.io/acR/reference/ac_qual_sample.md) | Amostrar para validação humana |
| [`ac_qual_export_for_review()`](https://andersonheri.github.io/acR/reference/ac_qual_export_for_review.md) | Exportar para revisao em .xlsx |
| [`ac_qual_import_human()`](https://andersonheri.github.io/acR/reference/ac_qual_import_human.md) | Importar revisao humana |
| [`ac_qual_irr()`](https://andersonheri.github.io/acR/reference/ac_qual_irr.md) | Concordância inter-codificador (kappa) |
| [`ac_qual_reliability()`](https://andersonheri.github.io/acR/reference/ac_qual_reliability.md) | Validar threshold de confiabilidade |
| [`ac_qual_save_codebook()`](https://andersonheri.github.io/acR/reference/ac_qual_save_codebook.md) | Salvar codebook em YAML |
| [`ac_qual_load_codebook()`](https://andersonheri.github.io/acR/reference/ac_qual_load_codebook.md) | Carregar codebook salvo |

### Visualização

| Funcao | Descrição |
|----|----|
| [`ac_plot_top_terms()`](https://andersonheri.github.io/acR/reference/ac_plot_top_terms.md) | Barras de frequencia |
| [`ac_plot_tf_idf()`](https://andersonheri.github.io/acR/reference/ac_plot_tf_idf.md) | TF-IDF por grupo |
| [`ac_plot_keyness()`](https://andersonheri.github.io/acR/reference/ac_plot_keyness.md) | Keyness por grupo de referencia |
| [`ac_plot_sentiment()`](https://andersonheri.github.io/acR/reference/ac_plot_sentiment.md) | Distribuição de sentimento |
| [`ac_plot_xray()`](https://andersonheri.github.io/acR/reference/ac_plot_xray.md) | Evolução de sentimento no texto |
| [`ac_plot_lda_topics()`](https://andersonheri.github.io/acR/reference/ac_plot_lda_topics.md) | Termos por tópico LDA |
| [`ac_plot_lda_tune()`](https://andersonheri.github.io/acR/reference/ac_plot_lda_tune.md) | Curva de selecao de K |
| [`ac_plot_cooccurrence()`](https://andersonheri.github.io/acR/reference/ac_plot_cooccurrence.md) | Rede de co-ocorrencia |
| [`ac_wordcloud()`](https://andersonheri.github.io/acR/reference/ac_wordcloud.md) | Nuvem de palavras |
| [`ac_plot_wordcloud_comparative()`](https://andersonheri.github.io/acR/reference/ac_plot_wordcloud_comparative.md) | Nuvem comparativa por tópico |

### Exportação e coleta

| Funcao | Descrição |
|----|----|
| [`ac_export()`](https://andersonheri.github.io/acR/reference/ac_export.md) | Exportar resultados (`csv`, `xlsx`, `latex`, `rds`) |
| [`ac_fetch_camara()`](https://andersonheri.github.io/acR/reference/ac_fetch_camara.md) | Coleta via API da Camara dos Deputados |
| [`ac_fetch_senado()`](https://andersonheri.github.io/acR/reference/ac_fetch_senado.md) | Coleta via API do Senado Federal |

## Provedores LLM suportados

O `acR` usa o pacote [ellmer](https://ellmer.tidyverse.org/) como
backend. Qualquer provedor suportado pelo ellmer funciona via o
argumento `chat=`.

``` r
library(ellmer)

# Google Gemini — tier gratuito disponivel
chat_obj <- chat_google_gemini(model = "gemini-2.5-flash", echo = "none")

# Groq — inferência rápida, plano gratuito
chat_obj <- chat_groq(model = "llama-3.3-70b-versatile", echo = "none")

# Ollama — modelos locais, sem envio de dados
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

| Provedor | Função ellmer | Variável de ambiente | Tier gratuito |
|----|----|----|----|
| Google Gemini | [`chat_google_gemini()`](https://ellmer.tidyverse.org/reference/chat_google_gemini.html) | `GOOGLE_API_KEY` | Sim |
| Groq | [`chat_groq()`](https://ellmer.tidyverse.org/reference/chat_groq.html) | `GROQ_API_KEY` | Sim |
| Ollama (local) | [`chat_ollama()`](https://ellmer.tidyverse.org/reference/chat_ollama.html) | não necessária | Gratuito |
| OpenAI | [`chat_openai()`](https://ellmer.tidyverse.org/reference/chat_openai.html) | `OPENAI_API_KEY` | Nao |
| Anthropic | [`chat_anthropic()`](https://ellmer.tidyverse.org/reference/chat_anthropic.html) | `ANTHROPIC_API_KEY` | Nao |
| Mistral | [`chat_mistral()`](https://ellmer.tidyverse.org/reference/chat_mistral.html) | `MISTRAL_API_KEY` | Nao |
| DeepSeek | [`chat_deepseek()`](https://ellmer.tidyverse.org/reference/chat_deepseek.html) | `DEEPSEEK_API_KEY` | Limitado |
| OpenRouter | [`chat_openrouter()`](https://ellmer.tidyverse.org/reference/chat_openrouter.html) | `OPENROUTER_API_KEY` | Por uso |

Configure as chaves no `.Renviron` (edite com
[`usethis::edit_r_environ()`](https://usethis.r-lib.org/reference/edit.html)):

    GOOGLE_API_KEY=sua_chave
    GROQ_API_KEY=sua_chave
    OPENAI_API_KEY=sua_chave
    ANTHROPIC_API_KEY=sua_chave

## Busca de literatura com OpenAlex

[`ac_qual_search_literature()`](https://andersonheri.github.io/acR/reference/ac_qual_search_literature.md)
busca referências acadêmicas reais na API do
[OpenAlex](https://openalex.org/) (gratuita, sem chave) e usa a LLM para
sintetizar os abstracts em portugues. Isso evita alucinações
bibliográficas comuns quando a LLM opera sem fonte externa.

``` r
library(ellmer)

chat_obj <- chat_google_gemini(model = "gemini-2.5-flash", echo = "none")

# Buscar referências sobre um conceito
lit <- ac_qual_search_literature(
  concept = "democratic backsliding",
  n_refs  = 5,
  chat    = chat_obj
)

# Com filtro de citacoes minimas (trabalhos consolidados)
lit <- ac_qual_search_literature(
  concept       = "state capacity",
  n_refs        = 10,
  min_citations = 50,
  chat          = chat_obj
)

# Resultado: tibble com autor, ano, revista, n_citacoes,
# trecho_original, definicao_pt, abstract_original, link
print(lit)
```

## Documentacao

- **Site completo**: <https://andersonheri.github.io/acR/>
- **Vignettes**:
  - [Introdução ao
    acR](https://andersonheri.github.io/acR/articles/introducao-acR.html)
  - [Codificação qualitativa com
    LLMs](https://andersonheri.github.io/acR/articles/qualitativo-llm.html)
  - [Análise de proposições
    legislativas](https://andersonheri.github.io/acR/articles/analise-proposicoes.html)
  - [Análise
    quantitativa](https://andersonheri.github.io/acR/articles/quantitativo.html)
  - [Análise de
    sentimento](https://andersonheri.github.io/acR/articles/sentimento.html)
  - [Modelagem de tópicos
    LDA](https://andersonheri.github.io/acR/articles/lda.html)

## Como citar

``` r
citation("acR")
```

    Henrique, A. (2025). acR: Análise de Conteúdo em R.
    R package version 0.1.0.
    Centro de Estudos da Metrópole (CEM-Cepid) — Universidade de São Paulo.
    https://andersonheri.github.io/acR/

## Referências

Bardin, L. (2011). *Análise de conteúdo*. Edições 70.

Benoit, K., et al. (2018). quanteda. *JOSS*, 3(30), 774.
<doi:10.21105/joss.00774>

Blei, D. M., Ng, A. Y., & Jordan, M. I. (2003). Latent Dirichlet
Allocation. *JMLR*, 3, 993-1022.

Gilardi, F., Alizadeh, M., & Kubli, M. (2023). ChatGPT Outperforms Crowd
Workers for Text-Annotation Tasks. *PNAS*, 120(30).

Krippendorff, K. (2018). *Content Analysis* (4a ed.). SAGE.

Landis, J. R., & Koch, G. G. (1977). *Biometrics*, 33(1), 159-174.

Priem, J., et al. (2022). OpenAlex: A fully-open index of the global
research system. *arXiv*, 2205.01833.

Sampaio, R. C., & Lycariao, D. (2021). *Análise de conteúdo categorial*.
Enap.

Souza, M., & Vieira, R. (2012). OpLexicon. *WASSA*. PUCRS.

Wickham, H., et al. (2025). *ellmer*. Posit.
<https://ellmer.tidyverse.org/>

## Licença

MIT © Anderson Henrique — Centro de Estudos da Metrópole (CEM-Cepid),
Universidade de São Paulo.
