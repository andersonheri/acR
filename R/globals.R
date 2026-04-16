utils::globalVariables(c(
  # ac_count / ac_tokenize
  "doc_id", "token", "n", "token_id",
  # ac_tf_idf
  "total", "df", "tf", "idf",
  # ac_keyness
  "n_target", "n_reference", "keyness",
  # ac_plot_*
  ".data", "direction", "tf_idf",
  # ac_cooccurrence
  "word1", "word2", "cooc", "pmi", "freq",
  # ac_plot_cooccurrence (igraph/ggraph)
  "w", "degree", "name",
  # ac_lda
  "beta", "gamma", "topic", "term",
  "grp", "x_jitter", "y_jitter", "size_norm",
  # ac_sentiment
  "score", "sentiment", "freq1", "freq2",
  "polaridade", "n_pos", "n_neg", "n_neu",
  # ac_plot_xray
  "pos_rel", "n_total", "term_label",
  # ac_lda_tune
  "k", "perplexity",
  # ac_qual_*
  "categoria", "raciocinio", "confidence_score", "confidence_level",
  "llm_cat", "human_cat", "sample_reason", "categoria_humano",
  "notas_humano", "coeff.val", "text",
  # ac_qual_models
  "rank", "justificativa", "model_id", "input", "output"
))
