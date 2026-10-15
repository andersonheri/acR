#' Escalonamento ideológico de documentos pelo método Wordscores
#'
#' @description
#' `ac_wordscores()` posiciona documentos num espectro contínuo (ex.:
#' esquerda-direita, pró/contra uma reforma) a partir só do vocabulário
#' que usam, pelo algoritmo Wordscores de Laver, Benoit & Garry (2003).
#' É um método supervisionado: parte de um pequeno conjunto de
#' documentos de referência com posição conhecida (ex.: manifestos de
#' partidos com posição já estimada por especialistas, ou avaliações de
#' produto com nota conhecida) e estima a posição de todos os outros
#' documentos ("documentos virgens") comparando seu vocabulário ao
#' vocabulário dos documentos de referência.
#'
#' A lógica: cada palavra recebe um "escore de palavra", a média
#' ponderada das posições dos documentos de referência em que ela
#' aparece (ponderada pela frequência relativa da palavra em cada
#' referência). Um documento virgem recebe a média dos escores de suas
#' palavras, ponderada pela frequência relativa delas no próprio
#' documento virgem: só palavras que também aparecem nos documentos de
#' referência contam.
#'
#' Fora da ciência política (onde o método nasceu, aplicado a manifestos
#' partidários), a mesma lógica serve para qualquer escala contínua
#' latente: por exemplo, estimar o quão favorável um conjunto de
#' avaliações de produto é a partir de um pequeno conjunto de avaliações
#' com nota de estrelas conhecida, ou posicionar transcrições de
#' atendimento num espectro de satisfação do cliente.
#'
#' @param corpus Objeto `ac_corpus`.
#' @param scores Vetor numérico nomeado (nomes = `doc_id`) ou tibble com
#'   colunas `doc_id` e `score`, com a posição conhecida dos documentos
#'   de referência. Documentos de `corpus` ausentes de `scores` (ou com
#'   `score = NA`) são tratados como documentos virgens, a serem
#'   estimados.
#' @param rescale Tipo de reescalonamento aplicado aos escores brutos,
#'   para corrigir a compressão em torno da média que o método produz
#'   (palavras comuns a todos os textos puxam todo escore para o centro
#'   da escala):
#'   - `"none"` (padrão): sem reescalonamento, escore bruto.
#'   - `"lbg"`: transformação de Laver, Benoit & Garry (2003, p. 316),
#'     \eqn{S^*_v = (S_v - \bar{S}_v)(DP_r / DP_v) + \bar{S}_v}, em que
#'     \eqn{\bar{S}_v} e \eqn{DP_v} são a média e o desvio-padrão dos
#'     escores brutos dos **documentos virgens** e \eqn{DP_r} o
#'     desvio-padrão dos escores **conhecidos** das referências. Dá aos
#'     virgens a mesma dispersão das referências, mantendo a média
#'     deles. Exige pelo menos 2 virgens e depende de quais virgens
#'     entram: com poucos, fica instável (com exatamente 2, eles caem
#'     sempre a cerca de 0,71 desvio-padrão da média, seja qual for o
#'     texto).
#'   - `"mv"`: transformação de Martin & Vanberg (2008),
#'     \eqn{S^*_v = (S_v - P_1)/(P_2 - P_1) \cdot (A_2 - A_1) + A_1}, em
#'     que \eqn{A_1} e \eqn{A_2} são os escores conhecidos das referências
#'     extremas (menor e maior) e \eqn{P_1}, \eqn{P_2} os escores brutos
#'     que o método atribui a essas mesmas referências. Não depende do
#'     conjunto de virgens: é a opção mais robusta quando há poucos
#'     documentos a estimar.
#'
#'   A mesma transformação é aplicada também às referências (como se
#'   fossem virgens), o que serve de checagem: uma referência bem
#'   recuperada fica perto do seu escore conhecido.
#' @param drop_punct Lógico, encaminhado para [ac_count()]. Padrão:
#'   `TRUE`.
#'
#' @return Tibble com colunas `doc_id`, `score` (escore estimado, já
#'   reescalonado conforme `rescale`), `score_raw` (escore bruto, antes
#'   do reescalonamento) e `is_reference` (`TRUE` para os documentos
#'   usados como referência).
#'
#' @references
#' Laver, M.; Benoit, K.; Garry, J. (2003). Extracting Policy Positions
#' from Political Texts Using Words as Data. *American Political
#' Science Review*, 97(2), 311-331.
#'
#' Martin, L. W.; Vanberg, G. (2008). A Robust Transformation Procedure
#' for Interpreting Political Text. *Political Analysis*, 16(1), 93-100.
#'
#' @examples
#' # Avaliações de produto com nota conhecida (referência) e sem nota
#' # (a estimar), usadas como escala continua de satisfacao
#' df <- data.frame(
#'   id = paste0("r", 1:6),
#'   texto = c(
#'     "produto excelente, superou expectativas, recomendo muito",
#'     "muito bom, chegou rápido e funciona perfeitamente",
#'     "produto regular, cumpre o básico",
#'     "não funcionou bem, qualidade ruim, não recomendo",
#'     "péssimo, quebrado e com defeito, decepcao total",
#'     "produto ok, nada de especial mas atende"
#'   ),
#'   stringsAsFactors = FALSE
#' )
#' corpus <- ac_corpus(df, text = texto, docid = id)
#'
#' # r1, r2, r4, r5 com nota conhecida (1-5); r3 e r6 sao "virgens"
#' notas <- c(r1 = 5, r2 = 4, r4 = 2, r5 = 1)
#'
#' ac_wordscores(corpus, notas)
#'
#' @seealso [ac_count()], [ac_ca()]
#' @concept quantitative
#' @export
ac_wordscores <- function(corpus,
                           scores,
                           rescale = c("none", "lbg", "mv"),
                           drop_punct = TRUE) {
  rescale <- match.arg(rescale)

  if (!is_ac_corpus(corpus)) {
    cli::cli_abort(c(
      "{.arg corpus} deve ser um objeto {.cls ac_corpus}.",
      "i" = "Crie com {.fun ac_corpus}."
    ))
  }

  scores <- .ac_wordscores_as_tibble(scores)

  counts <- ac_count(corpus, drop_punct = drop_punct, sort = FALSE)
  if (nrow(counts) == 0L) {
    cli::cli_abort("{.arg corpus} n\u00e3o produziu nenhum token.")
  }

  wide <- tidyr::pivot_wider(
    counts,
    id_cols     = "doc_id",
    names_from  = "token",
    values_from = "n",
    values_fill = 0
  )
  # ac_count()/pivot_wider() nao preservam a ordem original dos documentos;
  # reordenar para a ordem do corpus evita que a saida pareca embaralhada.
  wide <- wide[match(corpus$doc_id, wide$doc_id), , drop = FALSE]
  wide <- wide[!is.na(wide$doc_id), , drop = FALSE]

  doc_ids <- wide$doc_id
  mat <- as.matrix(wide[, setdiff(names(wide), "doc_id"), drop = FALSE])
  rownames(mat) <- doc_ids

  ref_idx <- match(scores$doc_id, doc_ids)
  if (all(is.na(ref_idx))) {
    cli::cli_abort("Nenhum {.field doc_id} de {.arg scores} foi encontrado em {.arg corpus}.")
  }
  if (anyNA(ref_idx)) {
    faltantes <- scores$doc_id[is.na(ref_idx)]
    cli::cli_warn("Documentos de refer\u00eancia ausentes do corpus (ignorados): {.val {faltantes}}")
    scores  <- scores[!is.na(ref_idx), , drop = FALSE]
    ref_idx <- ref_idx[!is.na(ref_idx)]
  }
  if (nrow(scores) < 2L) {
    cli::cli_abort("{.arg scores} precisa ter pelo menos 2 documentos de refer\u00eancia validos.")
  }

  ref_mat <- mat[ref_idx, , drop = FALSE]
  rowsum_ref <- rowSums(ref_mat)
  if (any(rowsum_ref == 0)) {
    cli::cli_abort("Algum documento de refer\u00eancia n\u00e3o tem nenhum token (ap\u00f3s remover pontua\u00e7\u00e3o).")
  }
  f_wr <- ref_mat / rowsum_ref

  vocab_ref <- colnames(ref_mat)[colSums(ref_mat) > 0]
  f_wr <- f_wr[, vocab_ref, drop = FALSE]

  col_sum <- colSums(f_wr)
  p_wr <- sweep(f_wr, 2, col_sum, "/")

  word_score <- as.vector(scores$score %*% p_wr)
  names(word_score) <- vocab_ref

  score_raw <- vapply(seq_len(nrow(mat)), function(i) {
    freqs <- mat[i, vocab_ref]
    denom <- sum(freqs)
    if (denom == 0) return(NA_real_)
    sum((freqs / denom) * word_score)
  }, numeric(1))

  out <- tibble::tibble(
    doc_id       = doc_ids,
    score_raw    = score_raw,
    is_reference = doc_ids %in% scores$doc_id
  )

  if (rescale != "none") {
    sr_hat   <- out$score_raw[out$is_reference]
    sr_known <- scores$score[match(out$doc_id[out$is_reference], scores$doc_id)]
    out$score <- switch(
      rescale,
      lbg = {
        # Laver, Benoit & Garry (2003, p. 316): media e DP dos VIRGENS,
        # DP dos escores CONHECIDOS das referencias. (A versao anterior
        # usava media/DP das referencias reestimadas, o que nao e LBG.)
        sv <- out$score_raw[!out$is_reference & !is.na(out$score_raw)]
        if (length(sv) < 2L) {
          cli::cli_abort(c(
            "{.val lbg} precisa de pelo menos 2 documentos virgens com escore.",
            "i" = "Use {.code rescale = \"mv\"}, que n\u00e3o depende dos virgens."
          ))
        }
        sd_v <- stats::sd(sv)
        if (!is.finite(sd_v) || sd_v == 0) {
          cli::cli_abort("Desvio-padr\u00e3o dos escores brutos dos virgens \u00e9 zero; n\u00e3o \u00e9 poss\u00edvel reescalonar com {.val lbg}.")
        }
        if (length(sv) < 5L) {
          cli::cli_warn(c(
            "{.val lbg} com s\u00f3 {length(sv)} documentos virgens: a transforma\u00e7\u00e3o depende do conjunto de virgens e fica inst\u00e1vel.",
            "i" = "Considere {.code rescale = \"mv\"} (Martin & Vanberg, 2008)."
          ))
        }
        (out$score_raw - mean(sv)) * (stats::sd(sr_known) / sd_v) + mean(sv)
      },
      mv = {
        # Martin & Vanberg (2008): ancora nas referencias extremas (menor e
        # maior escore conhecido). Com empate no extremo, usa a media dos
        # escores brutos das referencias empatadas.
        a1 <- min(sr_known)
        a2 <- max(sr_known)
        p1 <- mean(sr_hat[sr_known == a1])
        p2 <- mean(sr_hat[sr_known == a2])
        if (a1 == a2 || p1 == p2) {
          cli::cli_abort("As refer\u00eancias extremas t\u00eam o mesmo escore (conhecido ou bruto); n\u00e3o \u00e9 poss\u00edvel reescalonar com {.val mv}.")
        }
        (out$score_raw - p1) / (p2 - p1) * (a2 - a1) + a1
      }
    )
  } else {
    out$score <- out$score_raw
  }

  out[, c("doc_id", "score", "score_raw", "is_reference")]
}

.ac_wordscores_as_tibble <- function(scores) {
  if (is.data.frame(scores)) {
    if (!all(c("doc_id", "score") %in% names(scores))) {
      cli::cli_abort("{.arg scores} como tibble deve ter as colunas {.field doc_id} e {.field score}.")
    }
    out <- tibble::tibble(doc_id = as.character(scores$doc_id), score = as.numeric(scores$score))
  } else {
    if (is.null(names(scores)) || any(names(scores) == "")) {
      cli::cli_abort("{.arg scores} como vetor deve ser nomeado (nomes = doc_id).")
    }
    out <- tibble::tibble(doc_id = names(scores), score = as.numeric(scores))
  }
  out <- out[!is.na(out$score), , drop = FALSE]
  out
}

#' Visualizar escores Wordscores por documento
#'
#' @description
#' `ac_plot_wordscores()` plota os escores estimados por
#' [ac_wordscores()] num eixo único, destacando quais documentos foram
#' usados como referência.
#'
#' @param wordscores_tbl Tibble retornado por [ac_wordscores()].
#' @param title Título do grafico. Padrao: `NULL` (título automático).
#'
#' @return Objeto `ggplot`.
#'
#' @examples
#' df <- data.frame(
#'   id = paste0("r", 1:4),
#'   texto = c(
#'     "excelente, recomendo muito",
#'     "bom, atende bem",
#'     "ruim, não gostei",
#'     "péssimo, decepcao"
#'   ),
#'   stringsAsFactors = FALSE
#' )
#' corpus <- ac_corpus(df, text = texto, docid = id)
#' notas <- c(r1 = 5, r3 = 2, r4 = 1)
#' out <- ac_wordscores(corpus, notas)
#' if (requireNamespace("ggplot2", quietly = TRUE)) {
#'   ac_plot_wordscores(out)
#' }
#'
#' @seealso [ac_wordscores()]
#' @concept quantitative
#' @export
ac_plot_wordscores <- function(wordscores_tbl, title = NULL) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    cli::cli_abort(c(
      "O pacote {.pkg ggplot2} \u00e9 necess\u00e1rio para {.fn ac_plot_wordscores}.",
      "i" = "Instale com {.code install.packages(\"ggplot2\")}."
    ))
  }
  if (!all(c("doc_id", "score", "is_reference") %in% names(wordscores_tbl))) {
    cli::cli_abort("{.arg wordscores_tbl} deve ser a sa\u00edda de {.fn ac_wordscores}.")
  }

  df <- wordscores_tbl
  df$doc_id <- factor(df$doc_id, levels = df$doc_id[order(df$score)])

  ggplot2::ggplot(df, ggplot2::aes(x = score, y = doc_id, color = is_reference)) +
    ggplot2::geom_point(size = 3) +
    ggplot2::scale_color_manual(
      values = c(`TRUE` = "#1b7837", `FALSE` = "#737373"),
      labels = c(`TRUE` = "Referencia", `FALSE` = "Estimado (virgem)"),
      name = NULL
    ) +
    ggplot2::labs(
      title    = title %||% "Escores Wordscores por documento",
      subtitle = "Posicao estimada no espectro a partir do vocabulario",
      x        = "Escore",
      y        = NULL,
      caption  = "acR \u2022 Laver, Benoit & Garry (2003)"
    ) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      plot.title    = ggplot2::element_text(face = "bold"),
      plot.subtitle = ggplot2::element_text(color = "grey40"),
      plot.caption  = ggplot2::element_text(color = "grey50")
    )
}
