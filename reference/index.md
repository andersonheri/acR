# Package index

## Coleta de dados

Importacao de textos de fontes abertas brasileiras.

- [`ac_fetch_camara()`](https://andersonheri.github.io/acR/reference/ac_fetch_camara.md)
  : Busca discursos de deputados federais via API da C^amara dos
  Deputados
- [`ac_fetch_senado()`](https://andersonheri.github.io/acR/reference/ac_fetch_senado.md)
  : Busca discursos de senadores federais via senatebR

## Corpus e pre-processamento

Criacao, limpeza e tokenizacao de corpus em portugues.

- [`ac_corpus()`](https://andersonheri.github.io/acR/reference/ac_corpus.md)
  : Construir um corpus para análise de conteúdo

- [`ac_clean()`](https://andersonheri.github.io/acR/reference/ac_clean.md)
  : Limpar e normalizar texto de um corpus

- [`ac_tokenize()`](https://andersonheri.github.io/acR/reference/ac_tokenize.md)
  : Tokenizar textos de um corpus acR

- [`is_ac_corpus()`](https://andersonheri.github.io/acR/reference/is_ac_corpus.md)
  :

  Verificar se um objeto é um corpus do `acR`

## Analise quantitativa

Frequencias, associacoes e modelagem estatistica de textos.

- [`ac_count()`](https://andersonheri.github.io/acR/reference/ac_count.md)
  : Contar frequencias de tokens ou n-gramas em um corpus
- [`ac_top_terms()`](https://andersonheri.github.io/acR/reference/ac_top_terms.md)
  : Selecionar os termos mais frequentes
- [`ac_tf_idf()`](https://andersonheri.github.io/acR/reference/ac_tf_idf.md)
  : Calcular tf-idf para termos em documentos ou grupos
- [`ac_keyness()`](https://andersonheri.github.io/acR/reference/ac_keyness.md)
  : Calcular estatisticas de keyness entre dois grupos
- [`ac_cooccurrence()`](https://andersonheri.github.io/acR/reference/ac_cooccurrence.md)
  : Calcular co-ocorrências de termos
- [`ac_sentiment()`](https://andersonheri.github.io/acR/reference/ac_sentiment.md)
  : Análise de sentimento com OpLexicon
- [`ac_lda()`](https://andersonheri.github.io/acR/reference/ac_lda.md) :
  Ajustar modelo LDA (Latent Dirichlet Allocation)
- [`ac_lda_tune()`](https://andersonheri.github.io/acR/reference/ac_lda_tune.md)
  : Ajustar múltiplos modelos LDA para selecionar k

## Codificacao qualitativa via LLM

Pipeline de analise de conteudo qualitativa assistida por LLMs.

- [`ac_qual_codebook()`](https://andersonheri.github.io/acR/reference/ac_qual_codebook.md)
  : Criar um codebook para análise de conteúdo qualitativa
- [`ac_qual_search_literature()`](https://andersonheri.github.io/acR/reference/ac_qual_search_literature.md)
  : Buscar literatura acadêmica para um conceito
- [`ac_qual_code()`](https://andersonheri.github.io/acR/reference/ac_qual_code.md)
  : Classificar textos com LLM usando um codebook
- [`ac_qual_save_codebook()`](https://andersonheri.github.io/acR/reference/ac_qual_save_codebook.md)
  : Salvar codebook em arquivo YAML
- [`ac_qual_load_codebook()`](https://andersonheri.github.io/acR/reference/ac_qual_load_codebook.md)
  : Carregar codebook de arquivo YAML

## Validacao e confiabilidade

Amostragem, concordancia inter-codificador e importacao/exportacao.

- [`ac_qual_irr()`](https://andersonheri.github.io/acR/reference/ac_qual_irr.md)
  : Calcula metricas de confiabilidade inter-anotador
- [`ac_qual_reliability()`](https://andersonheri.github.io/acR/reference/ac_qual_reliability.md)
  : Calcular confiabilidade entre codificação LLM e humana
- [`ac_qual_sample()`](https://andersonheri.github.io/acR/reference/ac_qual_sample.md)
  : Amostrar documentos para validação humana
- [`ac_qual_export_for_review()`](https://andersonheri.github.io/acR/reference/ac_qual_export_for_review.md)
  : Exportar amostra para revisão humana em Excel
- [`ac_qual_import_human()`](https://andersonheri.github.io/acR/reference/ac_qual_import_human.md)
  : Importar classificação humana de Excel

## Selecao de modelos LLM

Listagem e recomendacao de modelos LLM.

- [`ac_qual_list_models()`](https://andersonheri.github.io/acR/reference/ac_qual_list_models.md)
  : Listar modelos LLM disponíveis para análise de conteúdo
- [`ac_qual_recommend_model()`](https://andersonheri.github.io/acR/reference/ac_qual_recommend_model.md)
  : Recomendar modelo LLM para análise de conteúdo qualitativa

## Visualizacao

Graficos modernos baseados em ggplot2.

- [`ac_plot_cooccurrence()`](https://andersonheri.github.io/acR/reference/ac_plot_cooccurrence.md)
  : Visualizar rede de co-ocorrência de termos
- [`ac_plot_keyness()`](https://andersonheri.github.io/acR/reference/ac_plot_keyness.md)
  : Plotar estatisticas de keyness
- [`ac_plot_lda_topics()`](https://andersonheri.github.io/acR/reference/ac_plot_lda_topics.md)
  : Visualizar top termos por tópico
- [`ac_plot_lda_tune()`](https://andersonheri.github.io/acR/reference/ac_plot_lda_tune.md)
  : Visualizar curva de seleção de k (perplexidade)
- [`ac_plot_sentiment()`](https://andersonheri.github.io/acR/reference/ac_plot_sentiment.md)
  : Visualizar sentimento ao longo dos documentos
- [`ac_plot_tf_idf()`](https://andersonheri.github.io/acR/reference/ac_plot_tf_idf.md)
  : Plotar termos mais caracteristicos por tf-idf
- [`ac_plot_top_terms()`](https://andersonheri.github.io/acR/reference/ac_plot_top_terms.md)
  : Plotar termos mais frequentes
- [`ac_plot_wordcloud_comparative()`](https://andersonheri.github.io/acR/reference/ac_plot_wordcloud_comparative.md)
  : Nuvem de palavras comparativa entre grupos
- [`ac_plot_xray()`](https://andersonheri.github.io/acR/reference/ac_plot_xray.md)
  : Gráfico X-ray — dispersão lexical de termos no corpus
- [`ac_wordcloud()`](https://andersonheri.github.io/acR/reference/ac_wordcloud.md)
  : Criar nuvem de palavras

## Exportacao

Exporta resultados para CSV, LaTeX, Excel e RDS.

- [`ac_export()`](https://andersonheri.github.io/acR/reference/ac_export.md)
  : Exporta resultados de analise de conteudo em multiplos formatos
