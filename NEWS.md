# acR 0.1.0

Primeira versão estável do pacote. Pipeline quantitativo completo e
módulo qualitativo via LLM implementados e testados.

## Pipeline quantitativo

- `ac_corpus()`: construtor de corpus com suporte a data.frame, vetor e
  quanteda::corpus
- `ac_clean()`: limpeza com 3 presets de stopwords PT-BR (`"pt"`,
  `"pt-br-extended"`, `"pt-legislativo"`), proteção de termos e
  normalização coloquial
- `ac_tokenize()`: tokenização tidy (doc_id, token_id, token)
- `ac_count()`: frequências e n-gramas
- `ac_top_terms()`: top termos por grupo
- `ac_tf_idf()`: TF-IDF com agrupamento por metadados
- `ac_keyness()`: keyness com chi², log-likelihood e outras métricas
- `ac_cooccurrence()`: co-ocorrência por janela deslizante ou documento,
  com PMI e Dice
- `ac_sentiment()`: análise de sentimento via OpLexicon (Souza & Vieira,
  2012) com cache local
- `ac_lda()` + `ac_lda_tune()`: LDA via topicmodels com seleção de k
  por perplexidade
- Visualizações correspondentes: `ac_plot_top_terms()`,
  `ac_plot_tf_idf()`, `ac_plot_keyness()`, `ac_plot_cooccurrence()`,
  `ac_plot_wordcloud()`, `ac_plot_wordcloud_comparative()`,
  `ac_plot_xray()`, `ac_plot_sentiment()`, `ac_plot_lda_topics()`,
  `ac_plot_lda_tune()`

## Pipeline qualitativo (LLM)

- `ac_qual_codebook()`: criação de codebook com modo manual e modo
  literatura (busca definições em periódicos nacionais e internacionais)
- `ac_qual_search_literature()`: banco estruturado de referências com
  trecho original, tradução PT, autor, ano, revista e link
- `ac_qual_code()`: classificação de textos via LLM com self-consistency
  (k = 3, Wang et al., 2023), grau de certeza por variável ou total, e
  coluna de raciocínio. Suporta qualquer provedor via ellmer (Anthropic,
  OpenAI, Google, Groq, Ollama, Azure, endpoints institucionais)
- `ac_qual_reliability()`: Krippendorff alpha, Gwet AC1 (implementação
  própria, sem dependência de irrCAC), F1 macro, com IC bootstrap
  (Landis & Koch, 1977; Gwet, 2014)
- `ac_qual_sample()`: amostragem por incerteza, estratificada, aleatória
  ou por discordância de self-consistency
- `ac_qual_export_for_review()`: exportação para Excel para validação
  humana
- `ac_qual_import_human()`: importação de codificação humana do Excel
- `ac_qual_save_codebook()` / `ac_qual_load_codebook()`: persistência de
  codebooks em YAML
- `ac_qual_list_models()`: banco curado de 25 modelos em 7 provedores
  com custo, janela de contexto e suporte ao português
- `ac_qual_recommend_model()`: recomendação baseada em tarefa, orçamento
  e idioma (Gilardi et al., 2023; Törnberg, 2023)

## Infraestrutura

- 327+ testes automatizados (0 falhas)
- CI em 5 ambientes (Ubuntu, macOS, Windows × R 4.3/release/devel)
- Site pkgdown em https://andersonheri.github.io/acR/
- ADR documentado em `inst/docs/adr/`

