make_corpus_count <- function(texts, ids = NULL) {
  if (is.null(ids)) {
    ids <- paste0("d", seq_along(texts))
  }
  
  if (length(ids) != length(texts)) {
    stop("length(ids) deve ser igual a length(texts).", call. = FALSE)
  }
  
  df <- data.frame(
    id    = ids,
    texto = texts,
    stringsAsFactors = FALSE
  )
  
  ac_corpus(df, text = texto, docid = id)
}
