# Package index

## Comece aqui — funcoes principais

Os seis pontos de entrada mais usados do pacote. Se voce esta comecando,
aprenda estas primeiro; o resto do pipeline se conecta em torno delas.

- [`ac_import()`](https://andersonheri.github.io/acR/reference/ac_import.md)
  : Importar arquivos para um corpus acR
- [`ac_corpus()`](https://andersonheri.github.io/acR/reference/ac_corpus.md)
  : Construir um corpus para análise de conteúdo
- [`ac_count()`](https://andersonheri.github.io/acR/reference/ac_count.md)
  : Contar frequências de tokens ou n-gramas em um corpus
- [`ac_qual_codebook()`](https://andersonheri.github.io/acR/reference/ac_qual_codebook.md)
  : Criar um codebook para análise de conteúdo qualitativa
- [`ac_qual_code()`](https://andersonheri.github.io/acR/reference/ac_qual_code.md)
  : Classificar textos com LLM usando um codebook
- [`ac_qual_reliability()`](https://andersonheri.github.io/acR/reference/ac_qual_reliability.md)
  : Calcular confiabilidade entre codificação LLM e humana

## Coleta de dados

Importacao de textos de fontes abertas brasileiras.

- [`ac_fetch_camara()`](https://andersonheri.github.io/acR/reference/ac_fetch_camara.md)
  : Busca discursos de deputados federais via API da Camara dos
  Deputados
- [`ac_fetch_senado()`](https://andersonheri.github.io/acR/reference/ac_fetch_senado.md)
  : Busca discursos de senadores federais via senatebR

## Corpus e pre-processamento

Criacao, limpeza e tokenizacao de corpus em portugues.

- [`ac_corpus()`](https://andersonheri.github.io/acR/reference/ac_corpus.md)
  : Construir um corpus para análise de conteúdo

- [`ac_import()`](https://andersonheri.github.io/acR/reference/ac_import.md)
  : Importar arquivos para um corpus acR

- [`ac_clean()`](https://andersonheri.github.io/acR/reference/ac_clean.md)
  : Limpar e normalizar texto de um corpus

- [`ac_clean_stopwords()`](https://andersonheri.github.io/acR/reference/ac_clean_stopwords.md)
  : Inspecionar e editar stopwords extras do acR

- [`ac_tokenize()`](https://andersonheri.github.io/acR/reference/ac_tokenize.md)
  : Tokenizar textos de um corpus acR

- [`is_ac_corpus()`](https://andersonheri.github.io/acR/reference/is_ac_corpus.md)
  :

  Verificar se um objeto é um corpus do `acR`

## Analise quantitativa

Frequencias, associacoes e modelagem estatistica de textos.

- [`ac_count()`](https://andersonheri.github.io/acR/reference/ac_count.md)
  : Contar frequências de tokens ou n-gramas em um corpus
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
- [`ac_cluster_documents()`](https://andersonheri.github.io/acR/reference/ac_cluster_documents.md)
  : Agrupamento nao supervisionado de documentos
- [`ac_readability()`](https://andersonheri.github.io/acR/reference/ac_readability.md)
  : Calcular legibilidade textual (Índice de Flesch adaptado ao
  português)
- [`ac_lexical_diversity()`](https://andersonheri.github.io/acR/reference/ac_lexical_diversity.md)
  : Calcular diversidade lexical (riqueza de vocabulário)
- [`ac_kwic()`](https://andersonheri.github.io/acR/reference/ac_kwic.md)
  : Concordância (keyword-in-context, KWIC)
- [`ac_collocations()`](https://andersonheri.github.io/acR/reference/ac_collocations.md)
  : Identificar colocações com medidas de associação estatística
- [`ac_temporal()`](https://andersonheri.github.io/acR/reference/ac_temporal.md)
  : Agregar uma métrica por período de tempo
- [`ac_wordscores()`](https://andersonheri.github.io/acR/reference/ac_wordscores.md)
  : Escalonamento ideológico de documentos pelo método Wordscores
- [`ac_ca()`](https://andersonheri.github.io/acR/reference/ac_ca.md) :
  Análise de correspondência (CA) entre documentos/grupos e termos
- [`ac_dictionary()`](https://andersonheri.github.io/acR/reference/ac_dictionary.md)
  : Classificar conteúdo com um dicionário multi-categoria
- [`ac_build_dictionary()`](https://andersonheri.github.io/acR/reference/ac_build_dictionary.md)
  : Construir um dicionário multi-categoria
- [`ac_dictionary_save()`](https://andersonheri.github.io/acR/reference/ac_dictionary_save.md)
  [`ac_dictionary_load()`](https://andersonheri.github.io/acR/reference/ac_dictionary_save.md)
  : Salvar ou carregar um dicionário em YAML
- [`ac_dictionary_import()`](https://andersonheri.github.io/acR/reference/ac_dictionary_import.md)
  : Importar um dicionário de uma tabela em formato longo
- [`ac_emotion()`](https://andersonheri.github.io/acR/reference/ac_emotion.md)
  : Classificar emoções com um léxico de palavra-emoção

## Codificacao qualitativa via LLM

Pipeline de analise de conteudo qualitativa assistida por LLMs: criacao
e gestao de codebooks, enriquecimento com literatura, traducao, fusao e
geracao de system prompts.

- [`ac_qual_codebook()`](https://andersonheri.github.io/acR/reference/ac_qual_codebook.md)
  : Criar um codebook para análise de conteúdo qualitativa
- [`ac_qual_codebook_add()`](https://andersonheri.github.io/acR/reference/ac_qual_codebook_add.md)
  : Adicionar categoria a um codebook existente
- [`ac_qual_codebook_remove()`](https://andersonheri.github.io/acR/reference/ac_qual_codebook_remove.md)
  : Remover categoria de um codebook existente
- [`ac_qual_codebook_hybrid()`](https://andersonheri.github.io/acR/reference/ac_qual_codebook_hybrid.md)
  : Enriquecer codebook com literatura via LLM (modo híbrido)
- [`ac_qual_codebook_merge()`](https://andersonheri.github.io/acR/reference/ac_qual_codebook_merge.md)
  : Fundir dois codebooks em um
- [`ac_qual_codebook_translate()`](https://andersonheri.github.io/acR/reference/ac_qual_codebook_translate.md)
  : Traduzir codebook para outro idioma via LLM
- [`ac_qual_codebook_history()`](https://andersonheri.github.io/acR/reference/ac_qual_codebook_history.md)
  : Exibir histórico de modificações de um codebook
- [`as_prompt()`](https://andersonheri.github.io/acR/reference/as_prompt.md)
  : Converter codebook em system prompt para LLM
- [`ac_qual_search_literature()`](https://andersonheri.github.io/acR/reference/ac_qual_search_literature.md)
  : Buscar referencias bibliograficas sobre um conceito via OpenAlex e
  LLM
- [`ac_qual_code()`](https://andersonheri.github.io/acR/reference/ac_qual_code.md)
  : Classificar textos com LLM usando um codebook
- [`ac_chat_local()`](https://andersonheri.github.io/acR/reference/ac_chat_local.md)
  : Conectar a um servidor LLM local compativel com OpenAI
- [`ac_estimate_tokens()`](https://andersonheri.github.io/acR/reference/ac_estimate_tokens.md)
  : Estimar numero de tokens de um texto
- [`ac_calibrate_tokens()`](https://andersonheri.github.io/acR/reference/ac_calibrate_tokens.md)
  : Calibrar a razao caracteres/token contra um modelo real
- [`ac_qual_save_codebook()`](https://andersonheri.github.io/acR/reference/ac_qual_save_codebook.md)
  : Salvar codebook em arquivo YAML
- [`ac_qual_load_codebook()`](https://andersonheri.github.io/acR/reference/ac_qual_load_codebook.md)
  : Carregar codebook de arquivo YAML

## Validacao e confiabilidade

Amostragem, concordancia inter-codificador e importacao/exportacao.

- [`ac_qual_irr()`](https://andersonheri.github.io/acR/reference/ac_qual_irr.md)
  : Calcular métricas de confiabilidade inter-anotador
- [`ac_qual_reliability()`](https://andersonheri.github.io/acR/reference/ac_qual_reliability.md)
  : Calcular confiabilidade entre codificação LLM e humana
- [`ac_dictionary_validate()`](https://andersonheri.github.io/acR/reference/ac_dictionary_validate.md)
  : Validar um dicionário contra codificação humana
- [`ac_qual_sample()`](https://andersonheri.github.io/acR/reference/ac_qual_sample.md)
  : Amostrar documentos para validação humana
- [`ac_qual_export_for_review()`](https://andersonheri.github.io/acR/reference/ac_qual_export_for_review.md)
  : Exportar amostra para revisão humana em Excel
- [`ac_qual_import_human()`](https://andersonheri.github.io/acR/reference/ac_qual_import_human.md)
  : Importar classificação humana de Excel

## Replicabilidade

Relatorio automatico das decisoes metodologicas para artigos e
relatorios.

- [`ac_qual_report()`](https://andersonheri.github.io/acR/reference/ac_qual_report.md)
  : Gerar relatório de replicabilidade da análise qualitativa
- [`ac_qual_report_full()`](https://andersonheri.github.io/acR/reference/ac_qual_report_full.md)
  : Gerar relatório consolidado de múltiplas variáveis de conteúdo

## Selecao de modelos LLM

Listagem e recomendacao de modelos LLM.

- [`ac_qual_list_models()`](https://andersonheri.github.io/acR/reference/ac_qual_list_models.md)
  : Listar modelos LLM disponíveis para análise de conteúdo
- [`ac_qual_recommend_model()`](https://andersonheri.github.io/acR/reference/ac_qual_recommend_model.md)
  : Recomendar modelo LLM para análise de conteúdo qualitativa

## Visualizacao

Graficos modernos baseados em ggplot2, com tema e paleta consistentes.

- [`ac_plot_ca()`](https://andersonheri.github.io/acR/reference/ac_plot_ca.md)
  : Visualizar um biplot de análise de correspondência
- [`ac_plot_cluster()`](https://andersonheri.github.io/acR/reference/ac_plot_cluster.md)
  : Visualiza um objeto ac_cluster
- [`ac_plot_cooccurrence()`](https://andersonheri.github.io/acR/reference/ac_plot_cooccurrence.md)
  : Visualizar rede de co-ocorrência de termos
- [`ac_plot_keyness()`](https://andersonheri.github.io/acR/reference/ac_plot_keyness.md)
  : Plotar estatisticas de keyness
- [`ac_plot_lda_topics()`](https://andersonheri.github.io/acR/reference/ac_plot_lda_topics.md)
  : Visualizar top termos por tópico
- [`ac_plot_lda_tune()`](https://andersonheri.github.io/acR/reference/ac_plot_lda_tune.md)
  : Visualizar curva de seleção de k (perplexidade)
- [`ac_plot_lexical_diversity()`](https://andersonheri.github.io/acR/reference/ac_plot_lexical_diversity.md)
  : Visualizar diversidade lexical por grupo
- [`ac_plot_readability()`](https://andersonheri.github.io/acR/reference/ac_plot_readability.md)
  : Visualizar legibilidade por grupo
- [`ac_plot_sentiment()`](https://andersonheri.github.io/acR/reference/ac_plot_sentiment.md)
  : Visualizar sentimento ao longo dos documentos
- [`ac_plot_temporal()`](https://andersonheri.github.io/acR/reference/ac_plot_temporal.md)
  : Visualizar uma série temporal de conteúdo
- [`ac_plot_tf_idf()`](https://andersonheri.github.io/acR/reference/ac_plot_tf_idf.md)
  : Plotar termos mais caracteristicos por tf-idf
- [`ac_plot_top_terms()`](https://andersonheri.github.io/acR/reference/ac_plot_top_terms.md)
  : Plotar termos mais frequentes
- [`ac_plot_wordcloud_comparative()`](https://andersonheri.github.io/acR/reference/ac_plot_wordcloud_comparative.md)
  : Nuvem de palavras comparativa entre grupos
- [`ac_plot_wordscores()`](https://andersonheri.github.io/acR/reference/ac_plot_wordscores.md)
  : Visualizar escores Wordscores por documento
- [`ac_plot_xray()`](https://andersonheri.github.io/acR/reference/ac_plot_xray.md)
  : Gráfico X-ray — dispersão lexical de termos no corpus
- [`ac_plot_zipf()`](https://andersonheri.github.io/acR/reference/ac_plot_zipf.md)
  : Visualizar a Lei de Zipf (frequência × posto)
- [`ac_wordcloud()`](https://andersonheri.github.io/acR/reference/ac_wordcloud.md)
  : Criar nuvem de palavras
- [`theme_ac()`](https://andersonheri.github.io/acR/reference/theme_ac.md)
  : Tema visual consistente do acR
- [`ac_palette()`](https://andersonheri.github.io/acR/reference/ac_palette.md)
  : Paleta categórica do acR

## Exportacao

Exporta resultados para CSV, LaTeX, Excel e RDS.

- [`ac_export()`](https://andersonheri.github.io/acR/reference/ac_export.md)
  : Exporta resultados de analise de conteudo em multiplos formatos
