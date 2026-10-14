#' Análise de correspondência (CA) entre documentos/grupos e termos
#'
#' @description
#' `ac_ca()` reduz uma tabela de contingência documento/grupo x termo a
#' poucas dimensões, posicionando unidades e termos no mesmo espaço
#' geométrico de modo que unidades e termos próximos no gráfico tendem
#' a co-ocorrer mais do que o esperado pelo acaso (Greenacre, 2007). É
#' uma alternativa simples e determinística à Alocação de Dirichlet
#' Latente (LDA, já disponível em [ac_lda()]) para visualizar
#' associações entre vocabulário e grupos em duas dimensões — sem
#' assumir um número de tópicos latentes, e com uma interpretação
#' geométrica direta (distâncias no biplot ~ dissimilaridade de perfis
#' de frequência).
#'
#' É útil, por exemplo, para visualizar como o vocabulário difere entre
#' categorias de atendimento ao cliente, entre seções de um conjunto de
#' notícias, ou entre partidos/períodos legislativos — qualquer
#' situação em que se queira um "mapa" conjunto de grupos e das
#' palavras que os caracterizam.
#'
#' Implementação: SVD (`base::svd()`) sobre os resíduos padronizados de
#' Pearson da tabela de contingência normalizada, no espírito do
#' algoritmo clássico de Análise de Correspondência (Greenacre, 2007).
#' Os sinais de cada dimensão são normalizados (a unidade com maior
#' coordenada em valor absoluto é sempre positiva), para que o
#' resultado seja determinístico entre execuções.
#'
#' @param corpus Objeto `ac_corpus`.
#' @param by Nome de uma coluna de metadados em `corpus` para definir
#'   os grupos (linhas da tabela de contingência). Se `NULL` (padrão),
#'   cada documento é uma linha.
#' @param top_n Número máximo de termos (colunas) a manter, pelos mais
#'   frequentes no total. Padrão: `50`.
#' @param min_count Frequência total mínima de um termo para ele ser
#'   mantido. Padrão: `5`.
#' @param n_dim Número de dimensões a retornar. Padrão: `2`.
#' @param drop_punct Lógico, encaminhado para [ac_count()]. Padrão:
#'   `TRUE`.
#'
#' @return Lista de classe `ac_ca` com:
#' - `row_coords`: tibble com `unit`, `dim1`, `dim2`, ..., `mass`
#'   (massa/peso relativo da linha).
#' - `col_coords`: tibble com `term`, `dim1`, `dim2`, ..., `mass`.
#' - `eigenvalues`: autovalores (inércia) de cada dimensão.
#' - `variance_explained`: proporção da inércia total explicada por
#'   cada dimensão.
#'
#' @references
#' Greenacre, M. (2007). *Correspondence Analysis in Practice* (2nd
#' ed.). Chapman and Hall/CRC.
#'
#' @examples
#' df <- data.frame(
#'   id = paste0("d", 1:6),
#'   texto = c(
#'     "entrega atrasada rastreio sumiu",
#'     "pedido atrasou muito, rastreio nao atualiza",
#'     "produto com defeito, chegou quebrado",
#'     "veio quebrado, qualidade pessima",
#'     "atendimento excelente, resolveram rapido",
#'     "suporte educado e rapido, resolveu tudo"
#'   ),
#'   categoria = c("entrega", "entrega", "produto", "produto",
#'                  "atendimento", "atendimento"),
#'   stringsAsFactors = FALSE
#' )
#' corpus <- ac_corpus(df, text = texto, docid = id, meta = categoria)
#'
#' ca <- ac_ca(corpus, by = "categoria", min_count = 1)
#' ca$variance_explained
#'
#' @seealso [ac_count()], [ac_lda()], [ac_plot_ca()]
#' @concept quantitative
#' @export
ac_ca <- function(corpus,
                   by = NULL,
                   top_n = 50L,
                   min_count = 5L,
                   n_dim = 2L,
                   drop_punct = TRUE) {
  if (!is_ac_corpus(corpus)) {
    cli::cli_abort(c(
      "{.arg corpus} deve ser um objeto {.cls ac_corpus}.",
      "i" = "Crie com {.fun ac_corpus}."
    ))
  }
  if (!is.null(by) && (!is.character(by) || length(by) != 1L)) {
    cli::cli_abort("{.arg by} deve ser {.val NULL} ou uma unica coluna (character de tamanho 1).")
  }

  counts <- ac_count(corpus, by = by, drop_punct = drop_punct)
  unit_col <- if (is.null(by)) "doc_id" else by

  totais_termo <- stats::aggregate(
    n ~ token,
    data = counts[, c("token", "n")],
    FUN  = sum
  )
  totais_termo <- totais_termo[totais_termo$n >= min_count, , drop = FALSE]
  totais_termo <- totais_termo[order(-totais_termo$n), , drop = FALSE]
  termos_mantidos <- utils::head(totais_termo$token, top_n)

  if (length(termos_mantidos) < 2L) {
    cli::cli_abort("Menos de 2 termos restantes depois de {.arg min_count}/{.arg top_n}; afrouxe os filtros.")
  }

  counts <- counts[counts$token %in% termos_mantidos, , drop = FALSE]

  wide <- tidyr::pivot_wider(
    counts,
    id_cols     = dplyr::all_of(unit_col),
    names_from  = "token",
    values_from = "n",
    values_fill = 0
  )

  unit_ids <- wide[[unit_col]]
  mat <- as.matrix(wide[, setdiff(names(wide), unit_col), drop = FALSE])
  rownames(mat) <- unit_ids

  mat <- mat[rowSums(mat) > 0, colSums(mat) > 0, drop = FALSE]
  if (nrow(mat) < 2L || ncol(mat) < 2L) {
    cli::cli_abort("Tabela de contingencia resultante tem menos de 2 linhas ou colunas validas.")
  }

  n_dim <- min(n_dim, nrow(mat) - 1L, ncol(mat) - 1L)
  if (n_dim < 1L) {
    cli::cli_abort("Nao ha dimensoes suficientes para a analise de correspondencia (linhas/colunas insuficientes).")
  }

  resultado <- .ac_ca_svd(mat, n_dim)

  structure(
    list(
      row_coords         = resultado$row_coords,
      col_coords          = resultado$col_coords,
      eigenvalues         = resultado$eigenvalues,
      variance_explained  = resultado$variance_explained,
      unit_col            = unit_col
    ),
    class = "ac_ca"
  )
}

.ac_ca_svd <- function(mat, n_dim) {
  N <- sum(mat)
  p <- mat / N
  r <- rowSums(p)
  k <- colSums(p)

  esperado <- outer(r, k)
  residuo  <- (p - esperado) / sqrt(outer(r, k))

  dec <- svd(residuo)
  rank_total <- length(dec$d)
  n_dim <- min(n_dim, rank_total)

  d <- dec$d[seq_len(n_dim)]
  U <- dec$u[, seq_len(n_dim), drop = FALSE]
  V <- dec$v[, seq_len(n_dim), drop = FALSE]

  F_row <- sweep(U, 1, 1 / sqrt(r), "*") %*% diag(d, nrow = n_dim)
  G_col <- sweep(V, 1, 1 / sqrt(k), "*") %*% diag(d, nrow = n_dim)

  for (dim_i in seq_len(n_dim)) {
    idx <- which.max(abs(F_row[, dim_i]))
    if (F_row[idx, dim_i] < 0) {
      F_row[, dim_i] <- -F_row[, dim_i]
      G_col[, dim_i] <- -G_col[, dim_i]
    }
  }

  eig_all <- dec$d^2
  eigenvalues <- eig_all[seq_len(n_dim)]
  variance_explained <- eigenvalues / sum(eig_all)

  dim_names <- paste0("dim", seq_len(n_dim))
  colnames(F_row) <- dim_names
  colnames(G_col) <- dim_names

  row_coords <- tibble::as_tibble(F_row)
  row_coords$unit <- rownames(mat)
  row_coords$mass <- as.numeric(r)
  row_coords <- row_coords[, c("unit", dim_names, "mass")]

  col_coords <- tibble::as_tibble(G_col)
  col_coords$term <- colnames(mat)
  col_coords$mass <- as.numeric(k)
  col_coords <- col_coords[, c("term", dim_names, "mass")]

  list(
    row_coords         = row_coords,
    col_coords         = col_coords,
    eigenvalues        = eigenvalues,
    variance_explained = variance_explained
  )
}

#' Visualizar um biplot de análise de correspondência
#'
#' @description
#' `ac_plot_ca()` plota um biplot com as duas primeiras dimensões da
#' saída de [ac_ca()]: pontos de unidades (documentos/grupos) e de
#' termos no mesmo espaço, com os eixos rotulados pela proporção de
#' inércia explicada.
#'
#' @param ca Objeto de classe `ac_ca`, saída de [ac_ca()].
#' @param top_terms Número máximo de termos a rotular, pelos de maior
#'   distância da origem (mais distintivos). Padrão: `20`.
#' @param title Título do gráfico. Padrão: `NULL` (título automático).
#'
#' @return Objeto `ggplot`.
#'
#' @examples
#' df <- data.frame(
#'   id = paste0("d", 1:6),
#'   texto = c(
#'     "entrega atrasada rastreio sumiu",
#'     "pedido atrasou muito, rastreio nao atualiza",
#'     "produto com defeito, chegou quebrado",
#'     "veio quebrado, qualidade pessima",
#'     "atendimento excelente, resolveram rapido",
#'     "suporte educado e rapido, resolveu tudo"
#'   ),
#'   categoria = c("entrega", "entrega", "produto", "produto",
#'                  "atendimento", "atendimento"),
#'   stringsAsFactors = FALSE
#' )
#' corpus <- ac_corpus(df, text = texto, docid = id, meta = categoria)
#' ca <- ac_ca(corpus, by = "categoria", min_count = 1)
#' if (requireNamespace("ggplot2", quietly = TRUE)) {
#'   ac_plot_ca(ca)
#' }
#'
#' @seealso [ac_ca()]
#' @concept quantitative
#' @export
ac_plot_ca <- function(ca, top_terms = 20L, title = NULL) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    cli::cli_abort(c(
      "O pacote {.pkg ggplot2} \u00e9 necess\u00e1rio para {.fn ac_plot_ca}.",
      "i" = "Instale com {.code install.packages(\"ggplot2\")}."
    ))
  }
  if (!inherits(ca, "ac_ca")) {
    cli::cli_abort("{.arg ca} deve ser um objeto {.cls ac_ca}, sa\u00edda de {.fn ac_ca}.")
  }

  rows <- ca$row_coords
  cols <- ca$col_coords
  cols$dist <- sqrt(cols$dim1^2 + cols$dim2^2)
  cols <- cols[order(-cols$dist), , drop = FALSE]
  cols <- utils::head(cols, top_terms)

  var_exp <- ca$variance_explained
  eixo_x <- sprintf("Dim 1 (%.1f%%)", var_exp[1] * 100)
  eixo_y <- if (length(var_exp) >= 2) sprintf("Dim 2 (%.1f%%)", var_exp[2] * 100) else "Dim 2"

  ggplot2::ggplot() +
    ggplot2::geom_hline(yintercept = 0, color = "grey80") +
    ggplot2::geom_vline(xintercept = 0, color = "grey80") +
    ggplot2::geom_point(
      data = rows, ggplot2::aes(x = dim1, y = dim2),
      color = "#1b7837", size = 3
    ) +
    ggplot2::geom_text(
      data = rows, ggplot2::aes(x = dim1, y = dim2, label = unit),
      color = "#1b7837", vjust = -0.8, fontface = "bold"
    ) +
    ggplot2::geom_point(
      data = cols, ggplot2::aes(x = dim1, y = dim2),
      color = "#762a83", size = 1.5, shape = 17
    ) +
    ggplot2::geom_text(
      data = cols, ggplot2::aes(x = dim1, y = dim2, label = term),
      color = "#762a83", size = 3, vjust = 1.3
    ) +
    ggplot2::labs(
      title    = title %||% "Analise de correspondencia",
      subtitle = "Unidades (verde) e termos (roxo) no mesmo espaco",
      x        = eixo_x,
      y        = eixo_y,
      caption  = "acR \u2022 Greenacre (2007)"
    ) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      plot.title    = ggplot2::element_text(face = "bold"),
      plot.subtitle = ggplot2::element_text(color = "grey40"),
      plot.caption  = ggplot2::element_text(color = "grey50")
    )
}
