#' Agrupamento nao supervisionado de documentos
#'
#' @description
#' `ac_cluster_documents()` particiona os documentos de um corpus em grupos
#' "duros" (hard clustering) com base na similaridade de vocabulario. Serve
#' para descobrir tipologias latentes, montar amostras estratificadas de
#' revisao humana ou produzir dendrogramas para relatorios metodologicos.
#'
#' Nao substitui [ac_lda()]: LDA e clustering *soft* (cada documento vira
#' uma mistura de topicos), enquanto esta funcao devolve **uma etiqueta
#' por documento**.
#'
#' @param corpus Objeto `ac_corpus`.
#' @param method Algoritmo. `"hclust"` (padrao) usa agrupamento hierarquico
#'   com ligacao Ward.D2; `"kmeans"` usa k-means com `nstart = 25L`;
#'   `"pam"` usa Partitioning Around Medoids (requer `cluster` em
#'   `Suggests`).
#' @param features Como representar cada documento. `"tfidf"` (padrao) pesa
#'   por TF-IDF; `"count"` usa contagens brutas.
#' @param k Numero de grupos. Se `NULL` (padrao) e `method %in%
#'   c("hclust","kmeans")`, tenta escolher automaticamente por silhouette
#'   entre 2 e 8; requer `cluster`. Se `cluster` nao estiver instalado,
#'   `k = 3` e o fallback.
#' @param distance Metrica de dissimilaridade. `"cosine"` (padrao) e o
#'   classico em textos; `"euclidean"` funciona melhor com vetores
#'   normalizados.
#' @param min_docs Minimo de documentos para nao emitir warning de corpus
#'   pequeno. Padrao: `15L`.
#'
#' @return Objeto de classe `ac_cluster` com:
#'   \describe{
#'     \item{`assignments`}{`tibble` com `doc_id` e `cluster` (integer).}
#'     \item{`fit`}{Objeto bruto do algoritmo (`hclust`, `kmeans` ou `pam`).}
#'     \item{`k`}{Numero final de grupos.}
#'     \item{`method`, `features`, `distance`}{Parametros usados.}
#'     \item{`silhouette`}{Silhueta media (NA se `cluster` nao instalado).}
#'     \item{`dtm`}{Matriz documento-termo usada (para plotagem).}
#'   }
#'
#' @examples
#' # Corpus com dois blocos tematicos
#' df <- data.frame(
#'   id    = paste0("d", 1:8),
#'   texto = c("democracia participacao voto liberdade",
#'             "cidadania direitos participacao democracia",
#'             "voto direitos liberdade cidadania",
#'             "democracia voto participacao popular",
#'             "mercado economia eficiencia privatizacao",
#'             "privatizacao mercado livre eficiencia",
#'             "economia crescimento investimento mercado",
#'             "eficiencia mercado economia livre"),
#'   stringsAsFactors = FALSE
#' )
#' corpus <- ac_corpus(df, text = texto, docid = id)
#' clust  <- ac_cluster_documents(corpus, k = 2)
#' clust$assignments
#'
#' @seealso [ac_lda()], [ac_plot_cluster()]
#' @concept quantitative
#' @export
ac_cluster_documents <- function(corpus,
                                 method   = c("hclust", "kmeans", "pam"),
                                 features = c("tfidf", "count"),
                                 k        = NULL,
                                 distance = c("cosine", "euclidean"),
                                 min_docs = 15L) {

  method   <- match.arg(method)
  features <- match.arg(features)
  distance <- match.arg(distance)

  if (!is_ac_corpus(corpus)) {
    cli::cli_abort("{.arg corpus} deve ser um {.cls ac_corpus}.")
  }

  n_docs <- nrow(corpus)
  if (n_docs < 2L) {
    cli::cli_abort("Corpus tem {n_docs} documento(s); clustering exige >= 2.")
  }
  if (n_docs < min_docs) {
    cli::cli_warn(c(
      "Corpus pequeno: {n_docs} documento(s).",
      "i" = "Cluster analysis em corpus < {min_docs} tende a ser ruidoso.",
      "i" = "Considere revisar as etiquetas com {.fn ac_qual_reliability}."
    ))
  }

  # -- construir matriz documento-termo -------------------------------------
  corpus_clean <- ac_clean(corpus)
  counts <- ac_count(corpus_clean)

  if (features == "tfidf") {
    tfidf <- ac_tf_idf(counts)
    mat   <- .cluster_pivot_matrix(tfidf, value = "tf_idf")
  } else {
    mat <- .cluster_pivot_matrix(counts, value = "n")
  }

  # -- distancias ------------------------------------------------------------
  d <- .cluster_distance(mat, distance)

  # -- escolher k automatico ------------------------------------------------
  if (is.null(k) && method %in% c("hclust", "kmeans")) {
    k <- .cluster_pick_k(mat, d, method)
  } else if (is.null(k)) {
    k <- min(3L, n_docs - 1L)
  }
  k <- as.integer(k)
  if (k < 2L || k > n_docs - 1L) {
    cli::cli_abort(
      "{.arg k} deve estar entre 2 e {n_docs - 1L} (n docs - 1)."
    )
  }

  # -- ajustar modelo -------------------------------------------------------
  fit <- switch(method,
    hclust = stats::hclust(d, method = "ward.D2"),
    kmeans = stats::kmeans(mat, centers = k, nstart = 25L),
    pam    = .cluster_pam(d, k)
  )

  assignments <- switch(method,
    hclust = stats::cutree(fit, k = k),
    kmeans = fit$cluster,
    pam    = fit$clustering
  )

  assignments_tbl <- tibble::tibble(
    doc_id  = rownames(mat),
    cluster = as.integer(assignments)
  )

  # -- silhouette (opcional) ------------------------------------------------
  sil <- .cluster_silhouette(assignments, d)

  structure(
    list(
      assignments = assignments_tbl,
      fit         = fit,
      k           = k,
      method      = method,
      features    = features,
      distance    = distance,
      silhouette  = sil,
      dtm         = mat
    ),
    class = "ac_cluster"
  )
}


#' Imprime resumo de um objeto ac_cluster
#'
#' @param x Objeto `ac_cluster`.
#' @param ... Ignorado.
#' @return `x` (invisivel).
#' @keywords internal
#' @export
print.ac_cluster <- function(x, ...) {
  cli::cli_h2("Cluster de documentos (acR)")
  cli::cli_bullets(c(
    "*" = "Metodo: {.val {x$method}}  |  features: {.val {x$features}}  |
           distancia: {.val {x$distance}}",
    "*" = "k = {x$k}  |  n = {nrow(x$assignments)} documentos",
    "*" = "Silhueta media: {if (is.na(x$silhouette)) 'NA' else sprintf('%.3f', x$silhouette)}"
  ))
  tab <- table(x$assignments$cluster)
  cat("\nDocumentos por cluster:\n")
  print(tab)
  invisible(x)
}


# =============================================================================
# Helpers internos
# =============================================================================

#' @noRd
.cluster_pivot_matrix <- function(x, value) {
  if (!requireNamespace("tidyr", quietly = TRUE)) {
    cli::cli_abort("Pacote {.pkg tidyr} necessario.")
  }
  wide <- tidyr::pivot_wider(
    x,
    id_cols     = "doc_id",
    names_from  = "token",
    values_from = dplyr::all_of(value),
    values_fill = 0
  )
  m <- as.matrix(wide[, -1L])
  rownames(m) <- wide$doc_id
  m
}

#' @noRd
.cluster_distance <- function(mat, distance) {
  if (distance == "euclidean") {
    return(stats::dist(mat, method = "euclidean"))
  }
  # cosine: 1 - cos(theta)
  norm <- sqrt(rowSums(mat * mat))
  norm[norm == 0] <- 1
  mat_n <- mat / norm
  sim   <- mat_n %*% t(mat_n)
  stats::as.dist(1 - sim)
}

#' @noRd
.cluster_pick_k <- function(mat, d, method) {
  if (!requireNamespace("cluster", quietly = TRUE)) {
    return(min(3L, attr(d, "Size") - 1L))
  }
  ks <- 2:min(8L, attr(d, "Size") - 1L)
  sil <- vapply(ks, function(kk) {
    if (method == "hclust") {
      h <- stats::hclust(d, method = "ward.D2")
      cl <- stats::cutree(h, k = kk)
    } else {
      cl <- stats::kmeans(mat, centers = kk, nstart = 10L)$cluster
    }
    mean(cluster::silhouette(cl, d)[, "sil_width"])
  }, numeric(1))
  ks[which.max(sil)]
}

#' @noRd
.cluster_pam <- function(d, k) {
  if (!requireNamespace("cluster", quietly = TRUE)) {
    cli::cli_abort(c(
      "Pacote {.pkg cluster} necessario para {.arg method = 'pam'}.",
      "i" = "Instale com {.code install.packages(\"cluster\")}."
    ))
  }
  cluster::pam(d, k = k)
}

#' @noRd
.cluster_silhouette <- function(assignments, d) {
  if (!requireNamespace("cluster", quietly = TRUE)) return(NA_real_)
  if (length(unique(assignments)) < 2L)             return(NA_real_)
  mean(cluster::silhouette(as.integer(assignments), d)[, "sil_width"])
}
