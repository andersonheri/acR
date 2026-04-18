# Changelog

## acR 0.1.0

Primeira versão estável do pacote. Pipeline quantitativo completo e
módulo qualitativo via LLM implementados e testados.

### Pipeline quantitativo

- [`ac_corpus()`](https://andersonheri.github.io/acR/reference/ac_corpus.md):
  construtor de corpus com suporte a data.frame, vetor e
  quanteda::corpus
- [`ac_clean()`](https://andersonheri.github.io/acR/reference/ac_clean.md):
  limpeza com 3 presets de stopwords PT-BR (`"pt"`, `"pt-br-extended"`,
  `"pt-legislativo"`), proteção de termos e normalização coloquial
- [`ac_tokenize()`](https://andersonheri.github.io/acR/reference/ac_tokenize.md):
  tokenização tidy (doc_id, token_id, token)
- [`ac_count()`](https://andersonheri.github.io/acR/reference/ac_count.md):
  frequências e n-gramas
- [`ac_top_terms()`](https://andersonheri.github.io/acR/reference/ac_top_terms.md):
  top termos por grupo
- [`ac_tf_idf()`](https://andersonheri.github.io/acR/reference/ac_tf_idf.md):
  TF-IDF com agrupamento por metadados
- [`ac_keyness()`](https://andersonheri.github.io/acR/reference/ac_keyness.md):
  keyness com chi², log-likelihood e outras métricas
- [`ac_cooccurrence()`](https://andersonheri.github.io/acR/reference/ac_cooccurrence.md):
  co-ocorrência por janela deslizante ou documento, com PMI e Dice
- [`ac_sentiment()`](https://andersonheri.github.io/acR/reference/ac_sentiment.md):
  análise de sentimento via OpLexicon (Souza & Vieira,
  2012. com cache local
- [`ac_lda()`](https://andersonheri.github.io/acR/reference/ac_lda.md) +
  [`ac_lda_tune()`](https://andersonheri.github.io/acR/reference/ac_lda_tune.md):
  LDA via topicmodels com seleção de k por perplexidade
- Visualizações correspondentes:
  [`ac_plot_top_terms()`](https://andersonheri.github.io/acR/reference/ac_plot_top_terms.md),
  [`ac_plot_tf_idf()`](https://andersonheri.github.io/acR/reference/ac_plot_tf_idf.md),
  [`ac_plot_keyness()`](https://andersonheri.github.io/acR/reference/ac_plot_keyness.md),
  [`ac_plot_cooccurrence()`](https://andersonheri.github.io/acR/reference/ac_plot_cooccurrence.md),
  `ac_plot_wordcloud()`,
  [`ac_plot_wordcloud_comparative()`](https://andersonheri.github.io/acR/reference/ac_plot_wordcloud_comparative.md),
  [`ac_plot_xray()`](https://andersonheri.github.io/acR/reference/ac_plot_xray.md),
  [`ac_plot_sentiment()`](https://andersonheri.github.io/acR/reference/ac_plot_sentiment.md),
  [`ac_plot_lda_topics()`](https://andersonheri.github.io/acR/reference/ac_plot_lda_topics.md),
  [`ac_plot_lda_tune()`](https://andersonheri.github.io/acR/reference/ac_plot_lda_tune.md)

### Pipeline qualitativo (LLM)

- [`ac_qual_codebook()`](https://andersonheri.github.io/acR/reference/ac_qual_codebook.md):
  criação de codebook com modo manual e modo literatura (busca
  definições em periódicos nacionais e internacionais)
- [`ac_qual_search_literature()`](https://andersonheri.github.io/acR/reference/ac_qual_search_literature.md):
  banco estruturado de referências com trecho original, tradução PT,
  autor, ano, revista e link
- [`ac_qual_code()`](https://andersonheri.github.io/acR/reference/ac_qual_code.md):
  classificação de textos via LLM com self-consistency (k = 3, Wang et
  al., 2023), grau de certeza por variável ou total, e coluna de
  raciocínio. Suporta qualquer provedor via ellmer (Anthropic, OpenAI,
  Google, Groq, Ollama, Azure, endpoints institucionais)
- [`ac_qual_reliability()`](https://andersonheri.github.io/acR/reference/ac_qual_reliability.md):
  Krippendorff alpha, Gwet AC1 (implementação própria, sem dependência
  de irrCAC), F1 macro, com IC bootstrap (Landis & Koch, 1977; Gwet,
  2014)
- [`ac_qual_sample()`](https://andersonheri.github.io/acR/reference/ac_qual_sample.md):
  amostragem por incerteza, estratificada, aleatória ou por discordância
  de self-consistency
- [`ac_qual_export_for_review()`](https://andersonheri.github.io/acR/reference/ac_qual_export_for_review.md):
  exportação para Excel para validação humana
- [`ac_qual_import_human()`](https://andersonheri.github.io/acR/reference/ac_qual_import_human.md):
  importação de codificação humana do Excel
- [`ac_qual_save_codebook()`](https://andersonheri.github.io/acR/reference/ac_qual_save_codebook.md)
  /
  [`ac_qual_load_codebook()`](https://andersonheri.github.io/acR/reference/ac_qual_load_codebook.md):
  persistência de codebooks em YAML
- [`ac_qual_list_models()`](https://andersonheri.github.io/acR/reference/ac_qual_list_models.md):
  banco curado de 25 modelos em 7 provedores com custo, janela de
  contexto e suporte ao português
- [`ac_qual_recommend_model()`](https://andersonheri.github.io/acR/reference/ac_qual_recommend_model.md):
  recomendação baseada em tarefa, orçamento e idioma (Gilardi et al.,
  2023; Törnberg, 2023)

### Infraestrutura

- 327+ testes automatizados (0 falhas)
- CI em 5 ambientes (Ubuntu, macOS, Windows × R 4.3/release/devel)
- Site pkgdown em <https://andersonheri.github.io/acR/>
- ADR documentado em `inst/docs/adr/`

## acR 0.2.0

### Correções

- [`ac_qual_search_literature()`](https://andersonheri.github.io/acR/reference/ac_qual_search_literature.md):
  removidas aspas literais da query OpenAlex (API não suporta phrase
  search via aspas no parâmetro `search`)
- [`ac_qual_search_literature()`](https://andersonheri.github.io/acR/reference/ac_qual_search_literature.md):
  adicionado fallback automático sem filtro de venue quando busca com
  periódicos selecionados retorna zero resultados

### Testes

- Testes de integração com OpenAlex + LLM agora usam `skip_on_cran()`,
  verificação prévia da API e `skip_if(!api_ok)` para evitar falhas em
  ambientes sem conectividade ou com API instável
- `test-ac_qual_codebook.R`: adicionado `skip_if(GROQ_API_KEY == 0)` e
  `chat_obj` explícito no teste de integração
