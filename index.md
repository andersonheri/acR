# acR

> **Analise de Conteudo em R**: pipeline integrado qualitativo (LLMs) e
> quantitativo, com visualizacoes modernas e foco em corpora
> brasileiros.

## Visao geral

O `acR` oferece um pipeline completo de analise de conteudo textual para
pesquisadores em ciencias sociais. O pacote integra dois modulos
principais: um **modulo qualitativo** baseado em LLMs (qwen3.6, GPT-4o,
Claude, Groq) para codificacao automatica com validacao humana, e um
**modulo quantitativo** para frequencias, TF-IDF, keyness, sentimento e
modelagem de topicos (LDA). Todas as funcoes foram projetadas para
corpora em portugues e seguem as convencoes metodologicas de Bardin
(2011) e Krippendorff (2018).

## Instalacao

``` r
# Versao de desenvolvimento (GitHub)
# install.packages("remotes")
remotes::install_github("andersonheri/acR")
```

## Exemplo minimo

### Modulo qualitativo — codificacao com LLM

``` r
library(acR)

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

# 3. Codificar com qwen3.6 via Ollama
resultado <- ac_qual_code(
  corpus      = corpus,
  codebook    = codebook,
  provider    = "ollama",
  model       = "qwen3.6:latest",
  api_key     = Sys.getenv("OLLAMA_API_KEY"),
  temperature = 0
)

# 4. Exportar
ac_export(resultado, formato = "csv", arquivo = "codificacao.csv")
```

### Modulo quantitativo — frequencias e sentimento

``` r
# Tokenizar e calcular frequencias
tokens   <- ac_tokenize(ac_clean(corpus), remover_stopwords = TRUE)
contagem <- ac_count(tokens)
ac_plot_top_terms(ac_top_terms(contagem, n = 10))

# Sentimento
sent <- ac_sentiment(corpus, lexico = "oplexicon")
ac_plot_sentiment(sent)
```

## Funcoes por modulo

### Corpus e pre-processamento

| Funcao                                                                           | Descricao                                    |
|----------------------------------------------------------------------------------|----------------------------------------------|
| [`ac_corpus()`](https://andersonheri.github.io/acR/reference/ac_corpus.md)       | Criar objeto corpus                          |
| `ac_import()`                                                                    | Importar corpus de arquivo externo           |
| [`ac_clean()`](https://andersonheri.github.io/acR/reference/ac_clean.md)         | Limpar texto (lowercase, pontuacao, numeros) |
| [`is_ac_corpus()`](https://andersonheri.github.io/acR/reference/is_ac_corpus.md) | Verificar se objeto e um corpus acR          |
| [`ac_tokenize()`](https://andersonheri.github.io/acR/reference/ac_tokenize.md)   | Tokenizar com remocao de stopwords           |

### Analise quantitativa

| Funcao                                                                                 | Descricao                            |
|----------------------------------------------------------------------------------------|--------------------------------------|
| [`ac_count()`](https://andersonheri.github.io/acR/reference/ac_count.md)               | Frequencia de termos                 |
| [`ac_top_terms()`](https://andersonheri.github.io/acR/reference/ac_top_terms.md)       | Top N termos                         |
| [`ac_tf_idf()`](https://andersonheri.github.io/acR/reference/ac_tf_idf.md)             | TF-IDF por documento                 |
| [`ac_keyness()`](https://andersonheri.github.io/acR/reference/ac_keyness.md)           | Vocabulario distintivo entre grupos  |
| [`ac_cooccurrence()`](https://andersonheri.github.io/acR/reference/ac_cooccurrence.md) | Rede de co-ocorrencia                |
| [`ac_sentiment()`](https://andersonheri.github.io/acR/reference/ac_sentiment.md)       | Sentimento (OpLexicon / SentiLex-PT) |
| [`ac_lda()`](https://andersonheri.github.io/acR/reference/ac_lda.md)                   | Modelagem de topicos LDA             |
| [`ac_lda_tune()`](https://andersonheri.github.io/acR/reference/ac_lda_tune.md)         | Selecao otima de K topicos           |

### TF-IDF — termos característicos por partido

``` r
library(acR)

# Corpus com proposicoes de deputados de diferentes partidos
df <- data.frame(
  id      = paste0("prop_", 1:6),
  texto   = c(
    "Esta proposta garante direitos trabalhistas e protecao social.",
    "O projeto amplia o seguro-desemprego para trabalhadores informais.",
    "Propomos reducao de impostos para estimular o crescimento economico.",
    "A desburocratizacao e essencial para a competitividade do Brasil.",
    "O texto fortalece o SUS e o acesso universal a saude publica.",
    "Defendemos a expansao de politicas de assistencia social."
  ),
  partido = c("PT", "PT", "PL", "PL", "PSOL", "PSOL"),
  stringsAsFactors = FALSE
)

# 1. Criar corpus
corpus <- ac_corpus(df, text = texto, docid = id, meta = partido)

# 2. Tokenizar (remove stopwords PT-BR automaticamente)
tokens <- ac_tokenize(ac_clean(corpus), remover_stopwords = TRUE)

# 3. Contar frequencias por partido
freq <- ac_count(tokens, by = "partido")

# 4. Calcular TF-IDF (cada partido como documento)
tfidf <- ac_tf_idf(freq, by = "partido")

# 5. Top 5 termos mais caracteristicos por partido
tfidf |>
  dplyr::group_by(partido) |>
  dplyr::slice_max(tf_idf, n = 5) |>
  dplyr::select(partido, token, tf_idf)

# 6. Visualizar
ac_plot_tf_idf(tfidf, by = "partido", n = 5)
```

### Analise qualitativa com LLMs

| Funcao                                                                                                     | Descricao                              |
|------------------------------------------------------------------------------------------------------------|----------------------------------------|
| [`ac_qual_codebook()`](https://andersonheri.github.io/acR/reference/ac_qual_codebook.md)                   | Construir codebook estruturado         |
| [`ac_qual_code()`](https://andersonheri.github.io/acR/reference/ac_qual_code.md)                           | Codificar corpus via LLM               |
| [`ac_qual_list_models()`](https://andersonheri.github.io/acR/reference/ac_qual_list_models.md)             | Listar modelos disponiveis             |
| [`ac_qual_recommend_model()`](https://andersonheri.github.io/acR/reference/ac_qual_recommend_model.md)     | Recomendacao automatica de modelo      |
| [`ac_qual_sample()`](https://andersonheri.github.io/acR/reference/ac_qual_sample.md)                       | Amostrar para validacao humana         |
| [`ac_qual_export_for_review()`](https://andersonheri.github.io/acR/reference/ac_qual_export_for_review.md) | Exportar para revisao em .xlsx         |
| [`ac_qual_import_human()`](https://andersonheri.github.io/acR/reference/ac_qual_import_human.md)           | Importar revisao humana                |
| [`ac_qual_irr()`](https://andersonheri.github.io/acR/reference/ac_qual_irr.md)                             | Concordancia inter-codificador (kappa) |
| [`ac_qual_reliability()`](https://andersonheri.github.io/acR/reference/ac_qual_reliability.md)             | Validar threshold de confiabilidade    |
| [`ac_qual_search_literature()`](https://andersonheri.github.io/acR/reference/ac_qual_search_literature.md) | Buscar literatura de apoio             |
| [`ac_qual_save_codebook()`](https://andersonheri.github.io/acR/reference/ac_qual_save_codebook.md)         | Salvar codebook em JSON                |
| [`ac_qual_load_codebook()`](https://andersonheri.github.io/acR/reference/ac_qual_load_codebook.md)         | Carregar codebook salvo                |

### Visualizacao

| Funcao                                                                                                             | Descricao                       |
|--------------------------------------------------------------------------------------------------------------------|---------------------------------|
| [`ac_plot_top_terms()`](https://andersonheri.github.io/acR/reference/ac_plot_top_terms.md)                         | Barras de frequencia            |
| [`ac_plot_tf_idf()`](https://andersonheri.github.io/acR/reference/ac_plot_tf_idf.md)                               | TF-IDF por grupo                |
| [`ac_plot_keyness()`](https://andersonheri.github.io/acR/reference/ac_plot_keyness.md)                             | Keyness por grupo de referencia |
| [`ac_plot_sentiment()`](https://andersonheri.github.io/acR/reference/ac_plot_sentiment.md)                         | Distribuicao de sentimento      |
| [`ac_plot_xray()`](https://andersonheri.github.io/acR/reference/ac_plot_xray.md)                                   | Evolucao de sentimento no texto |
| [`ac_plot_lda_topics()`](https://andersonheri.github.io/acR/reference/ac_plot_lda_topics.md)                       | Termos por topico LDA           |
| [`ac_plot_lda_tune()`](https://andersonheri.github.io/acR/reference/ac_plot_lda_tune.md)                           | Curva de selecao de K           |
| [`ac_plot_cooccurrence()`](https://andersonheri.github.io/acR/reference/ac_plot_cooccurrence.md)                   | Rede de co-ocorrencia           |
| [`ac_wordcloud()`](https://andersonheri.github.io/acR/reference/ac_wordcloud.md)                                   | Nuvem de palavras               |
| [`ac_plot_wordcloud_comparative()`](https://andersonheri.github.io/acR/reference/ac_plot_wordcloud_comparative.md) | Nuvem comparativa por topico    |

### Exportacao

| Funcao                                                                                 | Formatos                               |
|----------------------------------------------------------------------------------------|----------------------------------------|
| [`ac_export()`](https://andersonheri.github.io/acR/reference/ac_export.md)             | `csv`, `xlsx`, `latex`, `rds`          |
| [`ac_fetch_camara()`](https://andersonheri.github.io/acR/reference/ac_fetch_camara.md) | Coleta via API da Camara dos Deputados |
| [`ac_fetch_senado()`](https://andersonheri.github.io/acR/reference/ac_fetch_senado.md) | Coleta via API do Senado Federal       |

## Provedores LLM suportados

| Provedor                       | `provider`              | Modelo recomendado     | Portugues |
|--------------------------------|-------------------------|------------------------|-----------|
| Ollama nuvem                   | `"ollama"`              | `qwen3.6:latest`       | Excelente |
| OpenAI                         | `"openai"`              | `gpt-4o-mini`          | Excelente |
| Anthropic                      | `"anthropic"`           | `claude-3-5-sonnet`    | Excelente |
| Groq                           | `"groq"`                | `llama3-8b-8192`       | Bom       |
| Together AI                    | `"openai"`              | `Qwen/Qwen3-235B-A22B` | Excelente |
| Qualquer API OpenAI-compativel | `"openai"` + `base_url` | —                      | Variavel  |

## Documentacao

- **Site completo**: <https://andersonheri.github.io/acR/>
- **Vignettes**:
  - [Introducao ao
    acR](https://andersonheri.github.io/acR/articles/introducao-acR.html)
  - [Codificacao qualitativa com
    LLMs](https://andersonheri.github.io/acR/articles/qualitativo-llm.html)
  - [Analise de proposicoes
    legislativas](https://andersonheri.github.io/acR/articles/analise-proposicoes.html)
  - [Analise
    quantitativa](https://andersonheri.github.io/acR/articles/quantitativo.html)
  - [Analise de
    sentimento](https://andersonheri.github.io/acR/articles/sentimento.html)
  - [Modelagem de topicos
    LDA](https://andersonheri.github.io/acR/articles/lda.html)

## Como citar

``` r
citation("acR")
```

    Henrique, A. (2025). acR: Analise de Conteudo em R.
    R package version 0.1.0.
    Centro de Estudos da Metropole (CEM-Cepid) — Universidade de Sao Paulo.
    https://andersonheri.github.io/acR/

## Referencias

Bardin, L. (2011). *Analise de conteudo*. Edicoes 70.

Benoit, K., et al. (2018). quanteda. *JOSS*, 3(30), 774.
<doi:10.21105/joss.00774>

Blei, D. M., Ng, A. Y., & Jordan, M. I. (2003). Latent Dirichlet
Allocation. *JMLR*, 3, 993-1022.

Krippendorff, K. (2018). *Content Analysis* (4a ed.). SAGE.

Landis, J. R., & Koch, G. G. (1977). *Biometrics*, 33(1), 159-174.

Laver, M., Benoit, K., & Garry, J. (2003). *APSR*, 97(2), 311-331.

Maerz, S., & Benoit, K. (2025). *quallmer*. — inspiracao para o workflow
LLM.

Sampaio, R. C., & Lycariao, D. (2021). *Analise de conteudo categorial*.
Enap.

Souza, M., & Vieira, R. (2012). OpLexicon. *WASSA*. PUCRS.

Wickham, H., et al. (2025). *ellmer*. Posit.
<https://ellmer.tidyverse.org/>

## Licenca

MIT © Anderson Henrique — Centro de Estudos da Metropole (CEM-Cepid),
Universidade de Sao Paulo.
