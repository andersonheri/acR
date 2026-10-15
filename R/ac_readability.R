#' Calcular legibilidade textual (Índice de Flesch adaptado ao português)
#'
#' @description
#' `ac_readability()` estima a legibilidade (facilidade de leitura) dos
#' documentos de um `ac_corpus`, usando o Índice de Legibilidade de Flesch
#' adaptado ao português por Martins et al. (1996) a partir da fórmula
#' original de Flesch (1948).
#'
#' É uma ferramenta de diagnóstico, não de julgamento de qualidade: um
#' texto "difícil" pelo índice pode ser exatamente o esperado: uma
#' decisão judicial, um artigo técnico, uma bula de remédio. O uso típico
#' é **comparativo**: saber se o manual de instruções do produto A é mais
#' acessível que o do produto B, se a imprensa simplificou a linguagem de
#' comunicados oficiais ao longo do tempo, ou se avaliações de um produto
#' em um site de e-commerce variam em complexidade por categoria.
#'
#' A fórmula depende da contagem de sílabas por palavra, que a função
#' estima contando grupos de vogais (heurística comum em legibilidade
#' automática, já que não há dicionário de sílabas open-source completo
#' para português). Isso introduz algum erro em palavras com hiatos,
#' ditongos ou dígrafos vocálicos, mas a estimativa costuma ficar próxima
#' da contagem manual para fins comparativos.
#'
#' @param corpus Objeto `ac_corpus`.
#' @param by Coluna(s) de agrupamento para agregar a legibilidade além do
#'   documento (ex.: `"categoria"`, `"fonte"`, `"ano"`). Padrão: `NULL`
#'   (uma linha por documento).
#'
#' @return Tibble com colunas:
#'   * `doc_id` (ou as colunas de `by`, se informado);
#'   * `n_palavras`, `n_frases`, `n_silabas`: contagens usadas na fórmula;
#'   * `flesch`: Índice de Legibilidade de Flesch adaptado ao português
#'     (0-100; valores mais altos = texto mais fácil de ler);
#'   * `nivel`: interpretação categórica do índice (ver `@details`).
#'
#' @details
#' A fórmula (Martins et al., 1996) é:
#' \deqn{ILF = 248{,}835 - 1{,}015 \times \frac{palavras}{frases} - 84{,}6 \times \frac{sílabas}{palavras}}
#'
#' Faixas de interpretação (adaptadas da literatura educacional
#' brasileira que usa o ILF):
#' * `>= 75`: muito fácil (ensino fundamental inicial);
#' * `50-74,9`: fácil a médio (ensino fundamental/médio);
#' * `25-49,9`: difícil (ensino superior);
#' * `< 25`: muito difícil (especializado/técnico).
#'
#' @references
#' Flesch, R. (1948). A New Readability Yardstick. *Journal of Applied
#' Psychology*, 32(3), 221-233.
#'
#' Martins, T. B. F., Ghiraldelo, C. M., Nunes, M. G. V., Oliveira Jr.,
#' O. N. (1996). Readability formulas applied to textbooks in Brazilian
#' Portuguese. *ICMSC Technical Report*, 28.
#'
#' @examples
#' # Avaliações de produtos em um e-commerce, com nivel de complexidade variado
#' df <- data.frame(
#'   id = paste0("r", 1:4),
#'   texto = c(
#'     "Bom. Gostei. Chegou rápido.",
#'     paste(
#'       "A ergonomia do dispositivo privilegia uma distribuicao",
#'       "assimetrica de peso, o que compromete substancialmente a",
#'       "usabilidade prolongada em cenários de utilizacao intensiva."
#'     ),
#'     "Fácil de usar e bonito.",
#'     "O manual e confuso e a instalacao exige conhecimento técnico avancado."
#'   ),
#'   categoria = c("eletronico", "eletronico", "casa", "eletronico"),
#'   stringsAsFactors = FALSE
#' )
#' corpus <- ac_corpus(df, text = texto, docid = id)
#'
#' ac_readability(corpus)
#'
#' # Comparando legibilidade média por categoria de produto
#' ac_readability(corpus, by = "categoria")
#'
#' @seealso [ac_lexical_diversity()]
#' @concept quantitative
#' @export
ac_readability <- function(corpus, by = NULL) {
  if (!is_ac_corpus(corpus)) {
    cli::cli_abort("{.arg corpus} deve ser um {.cls ac_corpus}.")
  }
  if (!requireNamespace("stringr", quietly = TRUE)) {
    cli::cli_abort("O pacote {.pkg stringr} \u00e9 necess\u00e1rio.")
  }

  txt <- corpus$text
  txt[is.na(txt)] <- ""

  n_frases <- .ac_count_sentences(txt)
  palavras_por_doc <- stringr::str_extract_all(txt, "[\\p{L}]+")
  n_palavras <- vapply(palavras_por_doc, length, integer(1))
  n_silabas <- vapply(palavras_por_doc, function(ws) {
    sum(.ac_count_syllables_pt(ws))
  }, numeric(1))

  flesch <- rep(NA_real_, length(txt))
  tem_conteudo <- n_frases > 0 & n_palavras > 0
  flesch[tem_conteudo] <- 248.835 -
    1.015 * (n_palavras[tem_conteudo] / n_frases[tem_conteudo]) -
    84.6  * (n_silabas[tem_conteudo]  / n_palavras[tem_conteudo])

  out <- tibble::tibble(
    doc_id     = corpus$doc_id,
    n_palavras = n_palavras,
    n_frases   = n_frases,
    n_silabas  = n_silabas,
    flesch     = flesch,
    nivel      = .ac_flesch_nivel(flesch)
  )

  if (is.null(by)) return(out)

  if (!requireNamespace("dplyr", quietly = TRUE)) {
    cli::cli_abort("O pacote {.pkg dplyr} \u00e9 necess\u00e1rio.")
  }
  if (!all(by %in% names(corpus))) {
    cli::cli_abort(c(
      "{.arg by} cont\u00e9m nomes que n\u00e3o existem em {.arg corpus}.",
      "x" = "Nomes ausentes: {.val {setdiff(by, names(corpus))}}"
    ))
  }

  meta <- tibble::as_tibble(corpus)[, c("doc_id", by), drop = FALSE]
  out |>
    dplyr::left_join(meta, by = "doc_id") |>
    dplyr::group_by(dplyr::across(dplyr::all_of(by))) |>
    dplyr::summarise(
      n_palavras = sum(n_palavras),
      n_frases   = sum(n_frases),
      n_silabas  = sum(n_silabas),
      flesch     = 248.835 -
        1.015 * (sum(n_palavras) / sum(n_frases)) -
        84.6  * (sum(n_silabas)  / sum(n_palavras)),
      .groups = "drop"
    ) |>
    dplyr::mutate(nivel = .ac_flesch_nivel(flesch))
}


#' @keywords internal
#' @noRd
# Conta frases dividindo o texto em pontuacao terminal (./!/?), tratando
# sequencias repetidas ("..." ou "?!") como um unico limite de frase.
.ac_count_sentences <- function(txt) {
  partes <- strsplit(txt, "[.!?]+")
  vapply(partes, function(p) {
    sum(nzchar(trimws(p)))
  }, integer(1))
}


#' @keywords internal
#' @noRd
# Estimativa de silabas por contagem de grupos de vogais (heuristica
# padrao em legibilidade automatica). Cada sequencia contigua de vogais
# (incluindo semivogais y/w em emprestimos) conta como uma silaba; toda
# palavra tem no minimo 1 silaba.
.ac_count_syllables_pt <- function(words) {
  if (length(words) == 0L) return(numeric(0))
  grupos <- stringr::str_extract_all(
    tolower(words),
    "[aeiou\u00e1\u00e9\u00ed\u00f3\u00fa\u00e2\u00ea\u00f4\u00e3\u00f5\u00e0\u00fc]+"
  )
  n <- vapply(grupos, length, integer(1))
  pmax(n, 1L)
}


#' @keywords internal
#' @noRd
.ac_flesch_nivel <- function(score) {
  dplyr::case_when(
    is.na(score)   ~ NA_character_,
    score >= 75    ~ "muito facil",
    score >= 50    ~ "facil",
    score >= 25    ~ "dificil",
    TRUE           ~ "muito dificil"
  )
}


#' Visualizar legibilidade por grupo
#'
#' @description
#' `ac_plot_readability()` compara a distribuição do Índice de Flesch
#' (ver [ac_readability()]) entre grupos, com boxplots: a forma usual
#' de reportar legibilidade comparada na literatura de linguística
#' computacional e comunicação.
#'
#' @param readability_tbl Tibble retornado por `ac_readability(corpus, by
#'   = NULL)` (uma linha por documento) com uma coluna adicional de grupo
#'   já presente (ex.: junte com os metadados do corpus antes de chamar,
#'   ou calcule com `by` e use `type = "bar"`).
#' @param group_col Nome da coluna de agrupamento no eixo X.
#' @param type Tipo de gráfico: `"box"` (padrão, exige uma linha por
#'   documento) ou `"bar"` (uma barra por grupo; use quando
#'   `readability_tbl` já vier agregado por `ac_readability(by = ...)`).
#' @param title Título do gráfico. Padrão: `NULL`.
#'
#' @return Objeto `ggplot`.
#'
#' @examples
#' df <- data.frame(
#'   id = paste0("r", 1:6),
#'   texto = c(
#'     "Bom. Gostei. Rápido.",
#'     "Fácil de montar e usar no dia a dia.",
#'     paste(
#'       "A configuracao inicial demanda familiaridade com conceitos",
#'       "de rede que extrapolam o público leigo habitual."
#'     ),
#'     "Perfeito, superou expectativas.",
#'     paste(
#'       "A ausência de documentacao técnica compromete a integracao",
#'       "com sistemas legados preexistentes na infraestrutura corporativa."
#'     ),
#'     "Simples e direto, recomendo."
#'   ),
#'   categoria = rep(c("fácil", "difícil"), 3),
#'   stringsAsFactors = FALSE
#' )
#' corpus <- ac_corpus(df, text = texto, docid = id, meta = categoria)
#' leg <- ac_readability(corpus)
#' leg$categoria <- corpus$categoria
#' ac_plot_readability(leg, group_col = "categoria")
#'
#' @seealso [ac_readability()]
#' @concept visualization
#' @export
ac_plot_readability <- function(readability_tbl,
                                 group_col = NULL,
                                 type = c("box", "bar"),
                                 title = NULL) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    cli::cli_abort("O pacote {.pkg ggplot2} \u00e9 necess\u00e1rio.")
  }
  type <- match.arg(type)

  if (type == "box") {
    if (is.null(group_col) || !group_col %in% names(readability_tbl)) {
      cli::cli_abort("{.arg group_col} deve ser uma coluna existente em {.arg readability_tbl}.")
    }
    p <- ggplot2::ggplot(
      readability_tbl,
      ggplot2::aes(x = .data[[group_col]], y = flesch)
    ) +
      ggplot2::geom_boxplot(fill = "#2C7FB8", alpha = 0.6, outlier.alpha = 0.4) +
      ggplot2::labs(x = NULL, y = "\u00cdndice de Flesch (adaptado PT)")
  } else {
    p <- ggplot2::ggplot(
      readability_tbl,
      ggplot2::aes(x = .data[[group_col]], y = flesch)
    ) +
      ggplot2::geom_col(fill = "#2C7FB8") +
      ggplot2::labs(x = NULL, y = "\u00cdndice de Flesch (adaptado PT)")
  }

  p +
    ggplot2::geom_hline(yintercept = c(25, 50, 75), linetype = "dashed",
                        color = "grey60", linewidth = 0.3) +
    ggplot2::labs(
      title    = title,
      subtitle = "Maior = texto mais facil de ler",
      caption  = "acR \u2022 Flesch (1948), adaptado ao PT por Martins et al. (1996)"
    ) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      plot.title    = ggplot2::element_text(face = "bold"),
      plot.subtitle = ggplot2::element_text(color = "grey40", size = 9),
      plot.caption  = ggplot2::element_text(color = "grey60", size = 8, hjust = 1),
      panel.grid.minor = ggplot2::element_blank()
    )
}
